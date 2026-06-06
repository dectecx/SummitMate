import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/infrastructure/tools/toast_service.dart';

void main() {
  group('ToastService', () {
    test('Given ToastService, When executing, Then messengerKey should be GlobalKey', () {
      expect(ToastService.messengerKey, isA<GlobalKey<ScaffoldMessengerState>>());
    });

    test('Given ToastService, When executing, Then messengerKey should be static singleton', () {
      final key1 = ToastService.messengerKey;
      final key2 = ToastService.messengerKey;
      expect(identical(key1, key2), true);
    });
  });
}
