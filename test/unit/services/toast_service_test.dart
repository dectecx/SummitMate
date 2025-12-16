import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/services/toast_service.dart';

void main() {
  group('ToastService', () {
    test('messengerKey should be GlobalKey', () {
      expect(ToastService.messengerKey, isA<GlobalKey<ScaffoldMessengerState>>());
    });

    test('messengerKey should be static singleton', () {
      final key1 = ToastService.messengerKey;
      final key2 = ToastService.messengerKey;
      expect(identical(key1, key2), true);
    });
  });
}
