import 'package:dio/dio.dart';

import 'rudy_constants.dart';
import 'rudy_models.dart';

/// Probes Rudy Map files with HEAD. Never throws on network problems.
class RudyClient {
  RudyClient(this._dio, {required String appVersion, required String contactUrl})
    : _userAgent = rudyUserAgent(appVersion: appVersion, contactUrl: contactUrl);

  final Dio _dio;
  final String _userAgent;

  /// One HEAD to the rudymap.tw route; redirects are followed by Dio.
  Future<RudyProbe> probe(String fileName) async {
    final Response<dynamic> res;
    try {
      res = await _dio.head<dynamic>(
        '$rudyDownloadBase$fileName',
        options: Options(
          headers: downloadHeaders(),
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (_) => true,
        ),
      );
    } catch (_) {
      return const RudyProbe(RudyAvailability.unreachable);
    }
    final code = res.statusCode ?? 0;
    if (code == 404 || code == 410) return const RudyProbe(RudyAvailability.notAvailable);
    if (code < 200 || code >= 300) return const RudyProbe(RudyAvailability.unreachable);
    return RudyProbe(
      RudyAvailability.available,
      RudyRemoteFile(
        name: fileName,
        resolvedUrl: res.realUri,
        contentLength: int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? ''),
        lastModified: res.headers.value('last-modified'),
        acceptsRanges: (res.headers.value('accept-ranges') ?? '').toLowerCase().contains('bytes'),
      ),
    );
  }

  /// True when nothing is installed or the installed fingerprint differs.
  bool needsUpdate(String? installedFingerprint, RudyRemoteFile remote) =>
      installedFingerprint == null || installedFingerprint != remote.fingerprint;

  /// Headers for the background downloader; the caller adds `Range` on resume.
  Map<String, String> downloadHeaders() => {'User-Agent': _userAgent};
}
