import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/constants/role_constants.dart';

void main() {
  group('UserProfile Model Tests', () {
    final testUserJson = {
      'id': 'user-123',
      'email': 'test@example.com',
      'displayName': 'Test User',
      'avatar': '🐻',
      'role': RoleConstants.leader,
      'isVerified': true,
    };

    test('Given UserProfile Model Tests, When executing, Then Positive: Should parse from valid JSON', () {
      final user = UserProfile.fromJson(testUserJson);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.avatar, '🐻');
      expect(user.role, RoleConstants.leader);
      expect(user.isVerified, isTrue);
    });

    test('Given UserProfile Model Tests, When executing, Then Positive: Should convert to valid JSON', () {
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
      expect(json['displayName'], 'Test User');
      expect(json['avatar'], '🐻');
      expect(json['role'], RoleConstants.leader);
      expect(json['isVerified'], isTrue);
    });

    test(
      'Given missing optional fields, When calling UserProfile Model Tests, Then Edge: Should use default values',
      () {
        final minimalJson = {'id': 'user-456', 'email': 'min@example.com', 'displayName': 'Minimal User'};

        final user = UserProfile.fromJson(minimalJson);

        expect(user.id, 'user-456');
        expect(user.avatar, '🐻'); // Default value in constructor
        expect(user.role, RoleConstants.member); // Default value in constructor
        expect(user.isVerified, isFalse); // Default value in constructor
      },
    );

    test('Given required "id" is missing, When calling UserProfile Model Tests, Then Negative: Should throw', () {
      final legacyJson = {'uuid': 'old-uuid', 'email': 'old@example.com', 'displayName': 'Old User'};

      // Since we removed @JsonKey(name: 'uuid') and id is not present, it should throw or result in error if not handled
      expect(() => UserProfile.fromJson(legacyJson), throwsA(anything));
    });

    test('Given invalid field types, When calling UserProfile Model Tests, Then Exception: Should throw TypeError', () {
      final invalidJson = {
        'id': 'user-123',
        'email': 'test@example.com',
        'displayName': 12345, // Should be String
      };

      expect(() => UserProfile.fromJson(invalidJson), throwsA(isA<TypeError>()));
    });

    test('Given UserProfile Model Tests, When executing, Then Method: isLeader and isAdmin', () {
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
