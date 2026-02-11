import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:gpx/gpx.dart';

import '../../../core/gpx_utils.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassStreamSubscription;

  MapCubit() : super(const MapLoaded()); // Default to Loaded with empty data

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    _compassStreamSubscription?.cancel();
    return super.close();
  }

  void reset() {
    _positionStreamSubscription?.cancel();
    _compassStreamSubscription?.cancel();
    emit(const MapLoaded());
  }

  /// 初始化定位與羅盤
  Future<void> initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 檢查定位服務是否開啟
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      LogService.warning('Location services are disabled.', source: 'MapCubit');
      return;
    }

    // 2. 檢查權限
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        LogService.warning('Location permissions are denied', source: 'MapCubit');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      LogService.warning('Location permissions are permanently denied.', source: 'MapCubit');
      return;
    }

    // 3. 開始監聽定位
    _startLocationUpdates();

    // 4. 開始監聽羅盤 (Web 不支援 flutter_compass)
    if (!kIsWeb) {
      _startCompassUpdates();
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 每 5 公尺更新一次
    );

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) {
      if (state is MapLoaded) {
        emit((state as MapLoaded).copyWith(currentLocation: position));
      } else {
        emit(MapLoaded(currentLocation: position));
      }
    }, onError: (e) => LogService.error('Location Stream Error: $e', source: 'MapCubit'));
  }

  void _startCompassUpdates() {
    _compassStreamSubscription?.cancel();
    _compassStreamSubscription = FlutterCompass.events?.listen((event) {
      if (state is MapLoaded) {
        emit((state as MapLoaded).copyWith(currentHeading: event.heading));
      }
    });
  }

  /// 讀取並解析 GPX 檔案
  Future<void> loadGpxFile() async {
    try {
      if (state is MapLoaded) {
        emit((state as MapLoaded).copyWith(isLoading: true));
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['gpx']);

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final xmlString = await file.readAsString();

        // 解析 GPX
        final gpx = GpxReader().fromString(xmlString);

        // 提取軌跡點
        final trackPoints = GpxUtils.extractTrackPoints(gpx);

        if (state is MapLoaded) {
          emit((state as MapLoaded).copyWith(gpx: gpx, trackPoints: trackPoints, isLoading: false));
        } else {
          emit(MapLoaded(gpx: gpx, trackPoints: trackPoints));
        }
      } else {
        // Cancelled
        if (state is MapLoaded) {
          emit((state as MapLoaded).copyWith(isLoading: false));
        }
      }
    } catch (e) {
      LogService.error('Error loading GPX file: $e', source: 'MapCubit');
      if (state is MapLoaded) {
        emit((state as MapLoaded).copyWith(isLoading: false));
      }
      // Consider emitting MapError temporarily or handling via listener
    }
  }

  void clearGpx() {
    if (state is MapLoaded) {
      // Re-emit with null gpx and empty points
      // copyWith allows setting nullable?
      // Need to be careful. My MapLoaded structure handles defaults.
      // Ideally copyWith should support nullable setting.
      // In my MapState copyWith: `gpx: gpx ?? this.gpx`. This prevents clearing.
      // I need to emit new state or fix copyWith.
      // Let's just emit new state preserving other fields.
      final current = state as MapLoaded;
      emit(
        MapLoaded(
          currentLocation: current.currentLocation,
          currentHeading: current.currentHeading,
          gpx: null,
          trackPoints: const [],
          isLoading: current.isLoading,
        ),
      );
    }
  }
}
