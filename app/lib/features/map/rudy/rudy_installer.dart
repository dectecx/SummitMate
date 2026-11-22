import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:background_downloader/background_downloader.dart';

import 'rudy_client.dart';
import 'rudy_constants.dart';
import 'rudy_models.dart';
import '../data/download_updates.dart';
import 'rudy_paths.dart';

/// Pinned fonts release (not a Rudy file; about 62 MB).
final rudyFontsUrl = Uri.parse('https://github.com/openmaptiles/fonts/releases/download/v2.0/noto-sans.zip');

enum RudyInstallPhase { idle, probing, downloadingMap, downloadingFonts, unpacking, done, failed, unavailable }

class RudyInstallState {
  const RudyInstallState(this.phase, {this.progress = 0, this.bytesDone = 0, this.bytesTotal = 0, this.error});

  final RudyInstallPhase phase;

  /// Overall 0..1: map ~82%, fonts ~14%, unpack ~4%.
  final double progress;
  final int bytesDone;
  final int bytesTotal;

  /// User-facing message (Traditional Chinese) for failed / unavailable.
  final String? error;
}

abstract interface class RudyInstaller {
  RudyInstallState get state;
  Stream<RudyInstallState> get states;
  Future<void> start();
  Future<void> cancel();
  Future<void> remove();
}

// ---------------------------------------------------------------- fetcher

class FetchProgress {
  const FetchProgress(this.bytesDone, this.bytesTotal);
  final int bytesDone;

  /// 0 when unknown.
  final int bytesTotal;
}

class RudyFetchException implements Exception {
  RudyFetchException(this.message);
  final String message;
  @override
  String toString() => 'RudyFetchException: $message';
}

/// Thrown by a fetch that was ended by [RudyFileFetcher.cancel].
class RudyFetchCanceled implements Exception {
  const RudyFetchCanceled();
}

/// The network layer of the installer. The stream completes when [target] is fully written and
/// errors with [RudyFetchException] or [RudyFetchCanceled].
abstract interface class RudyFileFetcher {
  Stream<FetchProgress> fetch({
    required Uri url,
    required File target,
    required Map<String, String> headers,
    int? expectedBytes,
    bool resume = true,
  });

  /// Stops the running fetch. With [keepPartial] the partial data is kept so a later [fetch] resumes it.
  Future<void> cancel({bool keepPartial = false});

  Future<bool> hasRunningTask();
}

/// background_downloader based fetcher: keeps going while the app is in the background and resumes
/// (re-attaches) after a restart. Expects [target] to be under `applicationSupport/<relativeDirectory>`.
class BackgroundRudyFileFetcher implements RudyFileFetcher {
  BackgroundRudyFileFetcher({this.relativeDirectory = RudyPaths.relativeDirectory});

  static const group = 'rudy';
  final String relativeDirectory;
  Completer<void>? _active;

  @override
  Stream<FetchProgress> fetch({
    required Uri url,
    required File target,
    required Map<String, String> headers,
    int? expectedBytes,
    bool resume = true,
  }) {
    final out = StreamController<FetchProgress>();
    unawaited(_run(out, url, target, headers, expectedBytes, resume));
    return out.stream;
  }

  Future<void> _run(
    StreamController<FetchProgress> out,
    Uri url,
    File target,
    Map<String, String> headers,
    int? expectedBytes,
    bool resume,
  ) async {
    final dl = FileDownloader();
    final name = target.uri.pathSegments.last;
    final task = DownloadTask(
      taskId: 'rudy/$name',
      url: url.toString(),
      headers: headers,
      baseDirectory: BaseDirectory.applicationSupport,
      directory: relativeDirectory,
      filename: name,
      group: group,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 2,
    );
    final finished = Completer<void>();
    _active = finished;
    final sub = DownloadUpdates.stream.listen((u) {
      if (u.task.taskId != task.taskId || finished.isCompleted) return;
      if (u is TaskProgressUpdate && u.progress >= 0) {
        final total = u.hasExpectedFileSize ? u.expectedFileSize : (expectedBytes ?? 0);
        if (!out.isClosed) out.add(FetchProgress((u.progress * total).round(), total));
      } else if (u is TaskStatusUpdate) {
        switch (u.status) {
          case TaskStatus.complete:
            finished.complete();
          case TaskStatus.canceled:
            finished.completeError(const RudyFetchCanceled());
          case TaskStatus.failed || TaskStatus.notFound:
            finished.completeError(RudyFetchException('download ${u.status.name}: ${u.exception ?? ''}'));
          default:
            break;
        }
      }
    });
    try {
      // Paused partial -> resume; already queued/running -> just attach; otherwise enqueue.
      final resumed = resume && await dl.resume(task);
      if (!resumed) {
        final all = await dl.allTasks(group: group);
        final known = all.any((t) => t.taskId == task.taskId);
        if (!known) {
          final ok = await dl.enqueue(task);
          if (!ok) throw RudyFetchException('enqueue failed');
        }
      }
      await finished.future;
    } catch (e, st) {
      if (!out.isClosed) out.addError(e, st);
    } finally {
      await sub.cancel();
      if (_active == finished) _active = null;
      if (!out.isClosed) await out.close();
    }
  }

  @override
  Future<void> cancel({bool keepPartial = false}) async {
    final dl = FileDownloader();
    final tasks = await dl.allTasks(group: group);
    if (keepPartial) {
      for (final t in tasks) {
        if (t is DownloadTask) await dl.pause(t);
      }
    } else {
      await dl.cancelTasksWithIds([for (final t in tasks) t.taskId]);
    }
    final a = _active;
    if (a != null && !a.isCompleted) a.completeError(const RudyFetchCanceled());
  }

  @override
  Future<bool> hasRunningTask() async => (await FileDownloader().allTasks(group: group)).isNotEmpty;
}

// -------------------------------------------------------------- installer

const _mapWeight = 0.82;
const _fontsWeight = 0.14; // unpack takes the remaining 0.04

class BackgroundRudyInstaller implements RudyInstaller {
  BackgroundRudyInstaller(
    this._paths,
    this._client, {
    this.debugMapUrlOverride,
    Uri? fontsUrl,
    RudyFileFetcher? fetcher,
    DateTime Function()? now,
  }) : fontsUrl = fontsUrl ?? rudyFontsUrl,
       _fetcher = fetcher ?? BackgroundRudyFileFetcher(),
       _now = now ?? DateTime.now;

  final RudyPaths _paths;
  final RudyClient _client;
  final RudyFileFetcher _fetcher;
  final DateTime Function() _now;
  final Uri fontsUrl;

  /// DEVELOPMENT ONLY (set from a dart-define in debug builds, never in release): when non-null the map is
  /// downloaded from this URL and the Rudy HEAD probe is skipped, so no request hits rudymap.tw or its mirrors.
  final String? debugMapUrlOverride;

  final _controller = StreamController<RudyInstallState>.broadcast();
  RudyInstallState _state = const RudyInstallState(RudyInstallPhase.idle);
  bool _running = false;
  bool _cancelled = false;

  @override
  RudyInstallState get state => _state;

  @override
  Stream<RudyInstallState> get states => _controller.stream;

  void _emit(RudyInstallState s) {
    _state = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  void dispose() => _controller.close();

  /// True when a different map file is published than the installed one. False when nothing is installed,
  /// or the server is unreachable / has no file.
  Future<bool> isUpdateAvailable() async {
    final installed = _paths.installedFingerprint;
    if (installed == null) return false;
    final probe = await _client.probe(rudyPmtilesFile);
    final file = probe.file;
    if (probe.availability != RudyAvailability.available || file == null) return false;
    return _client.needsUpdate(installed, file);
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _cancelled = false;
    try {
      await _install();
    } on RudyFetchCanceled {
      _emit(const RudyInstallState(RudyInstallPhase.idle));
    } catch (e) {
      _emit(
        _cancelled
            ? const RudyInstallState(RudyInstallPhase.idle)
            : RudyInstallState(RudyInstallPhase.failed, error: _message(e)),
      );
    } finally {
      _running = false;
    }
  }

  String _message(Object e) => e is FileSystemException
      ? '儲存空間不足或無法寫入，請清出空間後再試'
      : e is RudyFetchException
      ? '下載失敗，請檢查網路後再試'
      : '安裝魯地圖時發生錯誤，請再試一次';

  Future<void> _install() async {
    _emit(const RudyInstallState(RudyInstallPhase.probing));
    await _paths.root.create(recursive: true);

    final (url, fingerprint, size) = await _resolveMap() ?? (null, '', null);
    if (url == null) return; // state already set (unavailable / failed)
    if (_cancelled) throw const RudyFetchCanceled();

    // Map file.
    var info = await _readSource();
    final sameSource = info != null && info['fingerprint'] == fingerprint;
    if (!sameSource) {
      await _fetcher.cancel(); // a partial of an older file is useless
      info = {'url': url.toString(), 'fingerprint': fingerprint, 'mapComplete': false};
      await _writeSource(info);
    }
    if (info['mapComplete'] != true || !_paths.pmtiles.existsSync()) {
      final resolved = Uri.parse(info['url'] as String); // resume against the stored mirror URL
      await _fetchStep(
        RudyInstallPhase.downloadingMap,
        resolved,
        _paths.pmtiles,
        size,
        base: 0,
        weight: _mapWeight,
      );
      info['mapComplete'] = true;
      await _writeSource(info);
    }

    // Fonts (skipped when the glyph folders are already there, e.g. on a map update).
    if (!_glyphsComplete(_paths.glyphs)) {
      if (!_paths.fontsZip.existsSync()) {
        await _fetchStep(
          RudyInstallPhase.downloadingFonts,
          fontsUrl,
          _paths.fontsZip,
          null,
          base: _mapWeight,
          weight: _fontsWeight,
        );
      }
      if (_cancelled) throw const RudyFetchCanceled();
      _emit(const RudyInstallState(RudyInstallPhase.unpacking, progress: _mapWeight + _fontsWeight));
      await unpackFonts(_paths.fontsZip, _paths.glyphs);
      await _paths.fontsZip.delete();
    }

    final marker = {
      'fingerprint': fingerprint,
      'installedAt': _now().toUtc().toIso8601String(),
      'pmtilesBytes': _paths.pmtiles.lengthSync(),
      'glyphsBytes': _dirBytes(_paths.glyphs),
    };
    await _paths.readyMarker.writeAsString(jsonEncode(marker)); // last
    _emit(RudyInstallState(RudyInstallPhase.done, progress: 1, bytesDone: marker['pmtilesBytes'] as int));
  }

  /// Returns (url, fingerprint, size) or null after emitting unavailable / failed.
  Future<(Uri?, String, int?)?> _resolveMap() async {
    final override = debugMapUrlOverride;
    if (override != null && override.isNotEmpty) {
      return (Uri.parse(override), 'debug|$override', null);
    }
    final probe = await _client.probe(rudyPmtilesFile);
    switch (probe.availability) {
      case RudyAvailability.notAvailable:
        _emit(const RudyInstallState(RudyInstallPhase.unavailable, error: '魯地圖檔案目前還沒有開放下載'));
        return (null, '', null);
      case RudyAvailability.unreachable:
        _emit(const RudyInstallState(RudyInstallPhase.failed, error: '無法連線到魯地圖伺服器，請檢查網路後再試'));
        return (null, '', null);
      case RudyAvailability.available:
        final f = probe.file!;
        return (f.resolvedUrl, f.fingerprint, f.contentLength);
    }
  }

  Future<void> _fetchStep(
    RudyInstallPhase phase,
    Uri url,
    File target,
    int? expected, {
    required double base,
    required double weight,
  }) async {
    _emit(RudyInstallState(phase, progress: base, bytesTotal: expected ?? 0));
    await for (final p in _fetcher.fetch(
      url: url,
      target: target,
      headers: _client.downloadHeaders(),
      expectedBytes: expected,
    )) {
      final total = p.bytesTotal > 0 ? p.bytesTotal : (expected ?? 0);
      final frac = total > 0 ? (p.bytesDone / total).clamp(0.0, 1.0) : 0.0;
      _emit(RudyInstallState(phase, progress: base + weight * frac, bytesDone: p.bytesDone, bytesTotal: total));
    }
    if (_cancelled) throw const RudyFetchCanceled();
    if (!target.existsSync()) throw RudyFetchException('missing ${target.path}');
  }

  Future<Map<String, dynamic>?> _readSource() async {
    try {
      final j = jsonDecode(await _paths.sourceInfo.readAsString());
      return j is Map<String, dynamic> ? j : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSource(Map<String, dynamic> info) => _paths.sourceInfo.writeAsString(jsonEncode(info));

  static bool _glyphsComplete(Directory glyphs) =>
      RudyPaths.fontFolders.every((f) => Directory('${glyphs.path}/$f').existsSync());

  static int _dirBytes(Directory d) {
    var n = 0;
    for (final e in d.listSync(recursive: true)) {
      if (e is File) n += e.lengthSync();
    }
    return n;
  }

  /// Streams the zip from disk and writes only the three font folders into [glyphs] (via a temp folder,
  /// so a crash never leaves a half-filled glyphs folder).
  static Future<void> unpackFonts(File zip, Directory glyphs) async {
    final tmp = Directory('${glyphs.path}.tmp');
    if (tmp.existsSync()) await tmp.delete(recursive: true);
    await tmp.create(recursive: true);
    final input = InputFileStream(zip.path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      var n = 0;
      for (final f in archive.files) {
        if (!f.isFile) continue;
        final parts = f.name.split('/').where((s) => s.isNotEmpty && s != '.').toList();
        if (parts.length != 2 || !RudyPaths.fontFolders.contains(parts[0]) || !parts[1].endsWith('.pbf')) continue;
        final dir = Directory('${tmp.path}/${parts[0]}')..createSync(recursive: true);
        final out = OutputFileStream('${dir.path}/${parts[1]}');
        try {
          f.writeContent(out);
        } finally {
          await out.close();
        }
        if (++n % 64 == 0) await Future<void>.delayed(Duration.zero);
      }
    } finally {
      await input.close();
    }
    if (!_glyphsComplete(tmp)) {
      await tmp.delete(recursive: true);
      throw const FormatException('fonts zip is missing font folders');
    }
    if (glyphs.existsSync()) await glyphs.delete(recursive: true);
    await tmp.rename(glyphs.path);
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    // Only the map file is worth resuming; a fonts partial is dropped.
    await _fetcher.cancel(keepPartial: _state.phase == RudyInstallPhase.downloadingMap);
    if (!_running) _emit(const RudyInstallState(RudyInstallPhase.idle));
  }

  @override
  Future<void> remove() async {
    _cancelled = true;
    await _fetcher.cancel();
    await _paths.deleteAll();
    _emit(const RudyInstallState(RudyInstallPhase.idle));
  }
}
