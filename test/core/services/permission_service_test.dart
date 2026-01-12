import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/services/permission_service.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/core/constants/role_constants.dart';

class MockAuthService extends Mock implements IAuthService {}

class MockTrip extends Mock implements Trip {}

void main() {
  late PermissionService permissionService;
  late MockAuthService mockAuthService;

  final adminUser = UserProfile(
    id: 'admin-id',
    email: 'admin@test.com',
    displayName: 'Admin',
    roleCode: RoleConstants.admin,
    permissions: [], // Admin implies all permissions usually, but logic checks roleCode
  );

  final leaderUser = UserProfile(
    id: 'leader-id',
    email: 'leader@test.com',
    displayName: 'Leader',
    roleCode: RoleConstants.leader,
    permissions: ['trip.edit', 'trip.delete', 'member.manage'], // Typical leader perms
  );

  final memberUser = UserProfile(
    id: 'member-id',
    email: 'member@test.com',
    displayName: 'Member',
    roleCode: RoleConstants.member,
    permissions: ['trip.view'],
  );

  final superMemberUser = UserProfile(
    id: 'super-member-id',
    email: 'super@test.com',
    displayName: 'Super Member',
    roleCode: RoleConstants.member,
    permissions: ['trip.view', 'trip.edit'], // Member with extra permission
  );

  setUp(() {
    mockAuthService = MockAuthService();
    permissionService = PermissionService(mockAuthService);
  });

  group('PermissionService', () {
    group('can()', () {
      test('Admin should return true even if permission not in list (via role check)', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);

        // 'random.permission' is not in adminUser.permissions list
        final result = await permissionService.can('random.permission');

        expect(result, isTrue);
      });

      test('Member should return true only if permission is in list', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => memberUser);

        expect(await permissionService.can('trip.view'), isTrue);
        expect(await permissionService.can('trip.edit'), isFalse);
      });

      test('Should return false if user is null', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => null);

        expect(await permissionService.can('any.perm'), isFalse);
      });
    });

    group('canEditTrip()', () {
      final trip = MockTrip();

      test('Admin can always edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canEditTrip(trip), isTrue);
      });

      test('User with trip.edit permission can edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => superMemberUser);
        expect(await permissionService.canEditTrip(trip), isTrue);
      });

      test('User without trip.edit permission cannot edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => memberUser);
        expect(await permissionService.canEditTrip(trip), isFalse);
      });
    });

    group('canDeleteTrip()', () {
      final myTrip = MockTrip();
      final otherTrip = MockTrip();

      setUp(() {
        when(() => myTrip.createdBy).thenReturn('leader-id');
        when(() => otherTrip.createdBy).thenReturn('other-id');
      });

      test('Admin can always delete', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canDeleteTrip(myTrip), isTrue);
      });

      test('Leader can delete their own trip', () async {
        when(
          () => mockAuthService.getCachedUserProfile(),
        ).thenAnswer((_) async => leaderUser); // Leader has trip.delete
        expect(await permissionService.canDeleteTrip(myTrip), isTrue);
      });

      test('Leader can delete others trip (permission-based)', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        expect(await permissionService.canDeleteTrip(otherTrip), isTrue);
      });

      test('Member cannot delete even if they own it (missing permission)', () async {
        // Create a member who somehow authored a trip but has no delete permission
        final authorMember = UserProfile(
          id: 'mem-id',
          email: '',
          displayName: '',
          roleCode: RoleConstants.member,
          permissions: [],
        );
        when(() => myTrip.createdBy).thenReturn('mem-id');

        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => authorMember);
        expect(await permissionService.canDeleteTrip(myTrip), isFalse);
      });
    });

    group('canManageMembers()', () {
      final myTrip = MockTrip();
      final otherTrip = MockTrip();

      setUp(() {
        when(() => myTrip.createdBy).thenReturn('leader-id');
        when(() => otherTrip.createdBy).thenReturn('other-id');
      });

      test('Admin can always manage members', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canManageMembers(myTrip), isTrue);
      });

      test('Leader can manage members of their own trip', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        expect(await permissionService.canManageMembers(myTrip), isTrue);
      });

      test('Leader can manage members of others trip (permission-based)', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        expect(await permissionService.canManageMembers(otherTrip), isTrue);
      });
    });
  });
}
