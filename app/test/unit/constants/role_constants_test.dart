import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/constants/role_constants.dart';

void main() {
  group('RoleConstants', () {
    test('isEqual handles casing and whitespace', () {
      expect(RoleConstants.isEqual('ADMIN', 'admin'), isTrue);
      expect(RoleConstants.isEqual(' Leader ', 'leader'), isTrue);
      expect(RoleConstants.isEqual('guide', 'GUIDE'), isTrue);
      expect(RoleConstants.isEqual('member', 'MEMBER'), isTrue);
      expect(RoleConstants.isEqual('member', 'leader'), isFalse);
      expect(RoleConstants.isEqual(null, 'admin'), isFalse);
      expect(RoleConstants.isEqual('admin', null), isFalse);
    });

    test('isAdmin recognizes both lowercase and uppercase admin', () {
      expect(RoleConstants.isAdmin('admin'), isTrue);
      expect(RoleConstants.isAdmin('ADMIN'), isTrue);
      expect(RoleConstants.isAdmin(' Admin '), isTrue);
      expect(RoleConstants.isAdmin('member'), isFalse);
      expect(RoleConstants.isAdmin(null), isFalse);
    });

    test('isLeader recognizes leader variants', () {
      expect(RoleConstants.isLeader('leader'), isTrue);
      expect(RoleConstants.isLeader('LEADER'), isTrue);
      expect(RoleConstants.isLeader('guide'), isFalse);
    });

    test('isGuide recognizes guide variants', () {
      expect(RoleConstants.isGuide('guide'), isTrue);
      expect(RoleConstants.isGuide('GUIDE'), isTrue);
      expect(RoleConstants.isGuide('member'), isFalse);
    });

    test('isMember recognizes member variants', () {
      expect(RoleConstants.isMember('member'), isTrue);
      expect(RoleConstants.isMember('MEMBER'), isTrue);
      expect(RoleConstants.isMember('leader'), isFalse);
    });

    test('getDisplayName returns correct localized string regardless of case', () {
      expect(RoleConstants.getDisplayName('admin'), equals('管理員'));
      expect(RoleConstants.getDisplayName('ADMIN'), equals('管理員'));
      expect(RoleConstants.getDisplayName('leader'), equals('團長'));
      expect(RoleConstants.getDisplayName('LEADER'), equals('團長'));
      expect(RoleConstants.getDisplayName('guide'), equals('嚮導'));
      expect(RoleConstants.getDisplayName('GUIDE'), equals('嚮導'));
      expect(RoleConstants.getDisplayName('member'), equals('成員'));
      expect(RoleConstants.getDisplayName('MEMBER'), equals('成員'));
      expect(RoleConstants.getDisplayName(null), equals('未知'));
      expect(RoleConstants.getDisplayName('CUSTOM_ROLE'), equals('CUSTOM_ROLE'));
    });
  });
}
