import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/library/ui/library_page.dart';
import '../features/library/ui/shared_set_detail_page.dart';
import '../features/library/ui/shared_sets_page.dart';
import '../features/library/ui/templates_page.dart';
import '../features/account/help_page.dart';
import '../features/account/account_tab.dart';
import '../features/account/login_page.dart';
import '../features/account/register_page.dart';
import '../features/account/verify_page.dart';
import '../features/explore/explore_tab.dart';
import '../features/explore/ui/mountain_detail_page.dart';
import '../features/map/map_tab.dart';
import '../features/map/ui/offline_maps_page.dart';
import '../features/onboarding/welcome_page.dart';
import '../features/trips/trips_tab.dart';
import '../features/trips/ui/trip_detail_page.dart';
import 'shell.dart';

abstract final class Routes {
  static const welcome = '/welcome';
  static const trips = '/trips';
  static const map = '/map';
  static const offlineMaps = '/map/offline';
  static const explore = '/explore';
  static String mountain(String id) => '/explore/$id';
  static const me = '/me';
  static const help = '/me/help';
  static const library = '/me/library';
  static const templates = '/me/templates';
  static String template(String id) => '/me/templates/$id';
  static const sharedSets = '/me/shared';
  static String sharedSet(String id) => '/me/shared/$id';
  static String trip(String id) => '/trips/$id';
  static const login = '/login';
  static const register = '/register';
  static const verify = '/verify';

  /// Builds a path with query parameters, e.g. `Routes.with_(Routes.login, {'next': Routes.trips})`.
  static String withQuery(String path, Map<String, String> query) => Uri(path: path, queryParameters: query).toString();
}

/// Where the person goes after finishing the sign-in / sign-up flow (query parameter `next`).
String nextOf(GoRouterState state) => state.uri.queryParameters['next'] ?? Routes.me;

GoRouter buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(path: Routes.login, builder: (_, s) => LoginPage(next: nextOf(s), email: s.uri.queryParameters['email'])),
      GoRoute(path: Routes.register, builder: (_, s) => RegisterPage(next: nextOf(s))),
      GoRoute(path: Routes.verify, builder: (_, s) => VerifyPage(email: s.uri.queryParameters['email'] ?? '', next: nextOf(s))),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.trips,
                builder: (_, _) => const TripsTab(),
                routes: [GoRoute(path: ':id', builder: (_, s) => TripDetailPage(tripId: s.pathParameters['id']!))],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.map,
                builder: (_, _) => const MapTab(),
                routes: [GoRoute(path: 'offline', builder: (_, _) => const OfflineMapsPage())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.explore,
                builder: (_, _) => const ExploreTab(),
                routes: [GoRoute(path: ':id', builder: (_, s) => MountainDetailPage(mountainId: s.pathParameters['id']!))],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.me,
                builder: (_, _) => const AccountTab(),
                routes: [
                  GoRoute(path: 'help', builder: (_, _) => const HelpPage()),
                  GoRoute(path: 'library', builder: (_, _) => const LibraryPage()),
                  GoRoute(
                    path: 'shared',
                    builder: (_, _) => const SharedSetsPage(),
                    routes: [GoRoute(path: ':id', builder: (_, s) => SharedSetDetailPage(setId: s.pathParameters['id']!))],
                  ),
                  GoRoute(
                    path: 'templates',
                    builder: (_, _) => const TemplatesPage(),
                    routes: [GoRoute(path: ':id', builder: (_, s) => TemplateDetailPage(templateId: s.pathParameters['id']!))],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(body: Center(child: Text('找不到頁面：${state.uri}'))),
  );
}
