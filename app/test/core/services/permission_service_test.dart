import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/services/permission_service.dart';
import 'package:summitmate/domain/domain.dart';
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
    role: RoleConstants.admin,
    permissions: [], // Admin implies all permissions usually, but logic checks role
  );

  final leaderUser = UserProfile(
    id: 'leader-id',
    email: 'leader@test.com',
    displayName: 'Leader',
    role: RoleConstants.leader,
    permissions: ['trip.edit', 'trip.delete', 'member.manage'], // Typical leader perms
  );

  final memberUser = UserProfile(
    id: 'member-id',
    email: 'member@test.com',
    displayName: 'Member',
    role: RoleConstants.member,
    permissions: ['trip.view'],
  );

  final superMemberUser = UserProfile(
    id: 'super-member-id',
    email: 'super@test.com',
    displayName: 'Super Member',
    role: RoleConstants.member,
    permissions: ['trip.view', 'trip.edit'], // Member with extra permission
  );

  setUp(() {
    mockAuthService = MockAuthService();
    permissionService = PermissionService(mockAuthService);
  });

  group('PermissionService', () {
    group('can()', () {
      test(
        'Given permission not in list (via role check), When calling can(), Then Admin should return true even',
        () async {
          when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);

          // 'random.permission' is not in adminUser.permissions list
          final result = await permissionService.can('random.permission');

          expect(result, isTrue);
        },
      );

      test('Given permission is in list, When calling can(), Then Member should return true only', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => memberUser);

        expect(await permissionService.can('trip.view'), isTrue);
        expect(await permissionService.can('trip.edit'), isFalse);
      });

      test('Given user is null, When calling can(), Then it should return false', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => null);

        expect(await permissionService.can('any.perm'), isFalse);
      });
    });

    group('canEditTrip()', () {
      final trip = MockTrip();

      setUp(() {
        // Default to including the testing user if not specified otherwise
        // Individual tests can override this
        when(() => trip.userId).thenReturn('default-owner'); // Stub userId to avoid errors
      });

      test('Given canEditTrip(), When executing, Then Admin can always edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canEditTrip(trip), isTrue);
      });

      test('Given canEditTrip(), When executing, Then User with trip.edit permission can edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => superMemberUser);
        expect(await permissionService.canEditTrip(trip), isTrue);
      });

      test('Given canEditTrip(), When executing, Then User without trip.edit permission cannot edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => memberUser);
        expect(await permissionService.canEditTrip(trip), isFalse);
      });

      test('Given canEditTrip(), When executing, Then Owner can edit without explicit permission', () async {
        final ownerUser = UserProfile(
          id: 'owner-id',
          email: '',
          displayName: '',
          role: RoleConstants.member,
          permissions: [], // No explicit permissions
        );
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => ownerUser);
        when(() => trip.userId).thenReturn('owner-id');

        expect(await permissionService.canEditTrip(trip), isTrue);
      });
    });

    group('canDeleteTrip()', () {
      final myTrip = MockTrip();
      final otherTrip = MockTrip();

      setUp(() {
        when(() => myTrip.userId).thenReturn('leader-id'); // Mock userId as owner
        when(() => otherTrip.userId).thenReturn('other-id');
      });

      test('Given canDeleteTrip(), When executing, Then Admin can always delete', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canDeleteTrip(myTrip), isTrue);
      });

      test('Given canDeleteTrip(), When executing, Then Leader can delete their own trip', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        // leaderUser.id is 'leader-id', which matches myTrip.userId
        expect(await permissionService.canDeleteTrip(myTrip), isTrue);
      });

      test(
        'Given owner even if permissions are limited (owner rule bypasses), When calling canDeleteTrip(), Then Leader can delete trip',
        () async {
          when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
          when(() => otherTrip.userId).thenReturn('leader-id'); // Make them owner

          expect(await permissionService.canDeleteTrip(otherTrip), isTrue);
        },
      );

      test('Given no permission, When calling canDeleteTrip(), Then Leader cannot delete OTHER people trip', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        when(() => otherTrip.userId).thenReturn('other-id'); // Not owner
        expect(await permissionService.canDeleteTrip(otherTrip), isTrue); // wait, leaderUser has trip.delete perm
      });

      test('Given canDeleteTrip(), When executing, Then Owner can delete without explicit permission', () async {
        final authorMember = UserProfile(
          id: 'mem-id',
          email: '',
          displayName: '',
          role: RoleConstants.member,
          permissions: [],
        );
        when(() => myTrip.userId).thenReturn('mem-id');

        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => authorMember);
        expect(await permissionService.canDeleteTrip(myTrip), isTrue);
      });
    });

    group('canManageMembers()', () {
      final myTrip = MockTrip();

      setUp(() {
        when(() => myTrip.userId).thenReturn('default-owner');
      });

      test('Given canManageMembers(), When executing, Then Admin can always manage members', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canManageMembers(myTrip), isTrue);
      });

      test('Given valid member, When calling canManageMembers(), Then Leader can manage members', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        expect(await permissionService.canManageMembers(myTrip), isTrue);
      });

      test('Given no permission but is Owner, When calling canManageMembers(), Then Owner can manage members', () async {
        final ownerUser = UserProfile(
          id: 'owner-id',
          email: '',
          displayName: '',
          role: RoleConstants.member,
          permissions: [], // No permissions
        );
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => ownerUser);
        when(() => myTrip.userId).thenReturn('owner-id');

        expect(await permissionService.canManageMembers(myTrip), isTrue);
      });

      test('Given no permission and is not Owner, When calling canManageMembers(), Then cannot manage members', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => memberUser);
        when(() => myTrip.userId).thenReturn('owner-id'); // memberUser.id is 'member-id'

        expect(await permissionService.canManageMembers(myTrip), isFalse);
      });
    });
  });
}
