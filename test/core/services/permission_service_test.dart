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

      setUp(() {
         // Default to including the testing user if not specified otherwise
         // Individual tests can override this
         when(() => trip.members).thenReturn([]);
      });

      test('Admin can always edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canEditTrip(trip), isTrue);
      });

      test('User with trip.edit permission AND membership can edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => superMemberUser);
        when(() => trip.members).thenReturn([superMemberUser.id]);
        expect(await permissionService.canEditTrip(trip), isTrue);
      });

      test('User with trip.edit permission BUT NOT membership cannot edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => superMemberUser);
        when(() => trip.members).thenReturn([]); // Not in list
        expect(await permissionService.canEditTrip(trip), isFalse);
      });

      test('User without trip.edit permission cannot edit', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => memberUser);
        when(() => trip.members).thenReturn([memberUser.id]);
        expect(await permissionService.canEditTrip(trip), isFalse);
      });
    });

    group('canDeleteTrip()', () {
      final myTrip = MockTrip();
      final otherTrip = MockTrip();

      setUp(() {
        when(() => myTrip.createdBy).thenReturn('leader-id');
        when(() => otherTrip.createdBy).thenReturn('other-id');
        
        when(() => myTrip.members).thenReturn(['leader-id']);
        when(() => otherTrip.members).thenReturn(['other-id']); 
      });

      test('Admin can always delete', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canDeleteTrip(myTrip), isTrue);
      });

      test('Leader can delete their own trip (is member)', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        // leaderUser.id is 'leader-id', which is in myTrip.members
        expect(await permissionService.canDeleteTrip(myTrip), isTrue);
      });

      test('Leader cannot delete trip if not member (even if createdBy match conceptually, logic checks members)', () async {
         // This scenario assumes membership is sync'd. If removed from members, permission lost.
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        when(() => otherTrip.members).thenReturn([]); // Not a member
        expect(await permissionService.canDeleteTrip(otherTrip), isFalse);
      });

      test('Member cannot delete even if they own it (missing permission)', () async {
        final authorMember = UserProfile(
          id: 'mem-id',
          email: '',
          displayName: '',
          roleCode: RoleConstants.member,
          permissions: [],
        );
        when(() => myTrip.createdBy).thenReturn('mem-id');
        when(() => myTrip.members).thenReturn(['mem-id']);

        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => authorMember);
        expect(await permissionService.canDeleteTrip(myTrip), isFalse);
      });
    });

    group('canManageMembers()', () {
      final myTrip = MockTrip();

      setUp(() {
        when(() => myTrip.members).thenReturn(['leader-id']);
      });

      test('Admin can always manage members', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => adminUser);
        expect(await permissionService.canManageMembers(myTrip), isTrue);
      });

      test('Leader can manage members if valid member', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        expect(await permissionService.canManageMembers(myTrip), isTrue);
      });

      test('Leader cannot manage members if NOT member', () async {
        when(() => mockAuthService.getCachedUserProfile()).thenAnswer((_) async => leaderUser);
        when(() => myTrip.members).thenReturn([]);
        expect(await permissionService.canManageMembers(myTrip), isFalse);
      });
    });
  });
}
