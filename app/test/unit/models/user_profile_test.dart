import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/constants/role_constants.dart';

void main() {
  group('UserProfile Model Tests', () {
    final testUserJson = {
      'id': 'user-123',
      'email': 'test@example.com',
      'display_name': 'Test User',
      'avatar': '🐻',
      'role': RoleConstants.leader,
      'is_verified': true,
    };

    test('Positive: Should parse from valid JSON', () {
      final user = UserProfile.fromJson(testUserJson);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.avatar, '🐻');
      expect(user.role, RoleConstants.leader);
      expect(user.isVerified, isTrue);
    });

    test('Positive: Should convert to valid JSON', () {
      final user = UserProfile(
        id: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        avatar: '🐻',
        role: RoleConstants.leader,
        isVerified: true,
      );

      final json = user.toJson();

      expect(json['id'], 'user-123');
      expect(json['email'], 'test@example.com');
      expect(json['display_name'], 'Test User');
      expect(json['avatar'], '🐻');
      expect(json['role'], RoleConstants.leader);
      expect(json['is_verified'], isTrue);
    });

    test('Edge: Should use default values for missing optional fields', () {
      final minimalJson = {'id': 'user-456', 'email': 'min@example.com', 'display_name': 'Minimal User'};

      final user = UserProfile.fromJson(minimalJson);

      expect(user.id, 'user-456');
      expect(user.avatar, '🐻'); // Default value in constructor
      expect(user.role, RoleConstants.member); // Default value in constructor
      expect(user.isVerified, isFalse); // Default value in constructor
    });

    test('Negative: Should throw when required "id" is missing', () {
      final legacyJson = {'uuid': 'old-uuid', 'email': 'old@example.com', 'display_name': 'Old User'};

      // Since we removed @JsonKey(name: 'uuid') and id is not present, it should throw or result in error if not handled
      expect(() => UserProfile.fromJson(legacyJson), throwsA(anything));
    });

    test('Exception: Should throw TypeError on invalid field types', () {
      final invalidJson = {
        'id': 'user-123',
        'email': 'test@example.com',
        'display_name': 12345, // Should be String
      };

      expect(() => UserProfile.fromJson(invalidJson), throwsA(isA<TypeError>()));
    });

    test('Method: isLeader and isAdmin', () {
      final admin = UserProfile(id: '1', email: 'a@a.com', displayName: 'A', role: RoleConstants.admin);
      final leader = UserProfile(id: '2', email: 'l@l.com', displayName: 'L', role: RoleConstants.leader);
      final member = UserProfile(id: '3', email: 'm@m.com', displayName: 'M', role: RoleConstants.member);

      expect(admin.isAdmin, isTrue);
      expect(admin.isLeader, isTrue);
      expect(leader.isAdmin, isFalse);
      expect(leader.isLeader, isTrue);
      expect(member.isAdmin, isFalse);
      expect(member.isLeader, isFalse);
    });
  });
}
