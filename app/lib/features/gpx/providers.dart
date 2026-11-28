import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import 'data/gpx_library.dart';

/// Where the copies of imported files live. Tests replace it.
final gpxDirectoryProvider = Provider<Future<Directory> Function()>((ref) => () async => Directory('${(await getApplicationSupportDirectory()).path}/gpx'));

final gpxLibraryProvider = Provider((ref) => GpxLibrary(ref.watch(appDatabaseProvider), ref.watch(gpxDirectoryProvider)));

final gpxRoutesProvider = StreamProvider<List<GpxRoute>>((ref) => ref.watch(gpxLibraryProvider).watch());

typedef PickedFile = ({Uint8List bytes, String name});

/// Lets the person choose a file on the phone; null when they cancel. Tests replace it.
final gpxPickerProvider = Provider<Future<PickedFile?> Function()>(
  (ref) => () async {
    final picked = await FilePicker.pickFiles(dialogTitle: '選擇 GPX 檔案');
    if (picked.isEmpty) return null;
    return (bytes: await picked.first.readAsBytes(), name: picked.first.name);
  },
);
