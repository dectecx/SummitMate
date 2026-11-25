import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth/auth_state.dart';
import '../core/providers.dart';
import '../features/trips/providers.dart';
import 'dev_config.dart';
import 'dev_data.dart';

/// Wraps the app with a draggable floating button that opens the developer panel.
/// [navigatorKey] is the app's own navigator, used to show the panel above the current screen.
class DevToolsOverlay extends StatefulWidget {
  const DevToolsOverlay({
    super.key,
    required this.child,
    required this.navigatorKey,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<DevToolsOverlay> createState() => _DevToolsOverlayState();
}

class _DevToolsOverlayState extends State<DevToolsOverlay> {
  Offset _position = const Offset(0, 430); // low on the left edge, away from titles and buttons
  bool _open = false;

  Future<void> _showPanel() async {
    final context = widget.navigatorKey.currentContext;
    if (context == null || _open) return;
    setState(() => _open = true); // the button hides while the panel is up
    // The trip the person has open (a /trips/<id> screen), so the panel adds gear and meals to it.
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final openTrip = RegExp(r'^/trips/([^/]+)').firstMatch(path)?.group(1);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors
          .black12, // keep the screen behind visible: the changes show up there
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      builder: (_) => DevPanel(openTripId: openTrip),
    );
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        widget.child,
        if (!_open) Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (d) => setState(() {
              _position = Offset(
                (_position.dx + d.delta.dx).clamp(0, size.width - 44),
                (_position.dy + d.delta.dy).clamp(0, size.height - 44),
              );
            }),
            child: Material(
              color: Colors.deepPurple.withValues(alpha: 0.75),
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                key: const ValueKey('dev-tools-button'),
                customBorder: const CircleBorder(),
                onTap: _showPanel,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.developer_mode, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The developer panel: test account, random trips / gear / meals, random group events.
class DevPanel extends ConsumerStatefulWidget {
  const DevPanel({super.key, this.openTripId});

  /// The trip screen that was open when the panel was opened, if any.
  final String? openTripId;

  @override
  ConsumerState<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends ConsumerState<DevPanel> {
  String? _message;
  bool _busy = false;
  String? _tripId; // chosen in the list; null means follow the open trip

  Future<void> _run(String label, Future<String?> Function() job) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    String text;
    try {
      text = await job() ?? '$label：完成';
    } catch (e) {
      text = '$label失敗：$e';
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _message = text;
      });
    }
  }

  Future<String?> _signIn() async {
    final auth = ref.read(authRepositoryProvider);
    try {
      await auth.login(email: devAccountEmail, password: devAccountPassword);
      return '已登入 $devAccountEmail';
    } catch (_) {
      // No such account yet (or it is unverified): create it and verify with the development code.
      try {
        await auth.register(
          email: devAccountEmail,
          password: devAccountPassword,
          displayName: devAccountName,
        );
      } catch (_) {
        // Already registered but not verified: carry on to verification.
      }
      await auth.verifyEmail(email: devAccountEmail, code: devVerificationCode);
      return '已建立並登入 $devAccountEmail';
    }
  }

  Future<String?> _signOut() async {
    await ref.read(authRepositoryProvider).logout(force: true);
    return '已登出';
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) setState(() => _message = '已複製$what');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final factory = ref.watch(devDataFactoryProvider);
    final signedIn = ref.watch(accountIdProvider) != null;
    final authState = ref.watch(authStateProvider).value;
    final trips = ref.watch(tripsProvider).value ?? const [];
    // Gear and meals go to the trip chosen in the list, else the trip that is open, else nowhere (buttons stay off).
    final tripId = [_tripId, widget.openTripId].firstWhere(
      (id) => id != null && trips.any((t) => t.id == id),
      orElse: () => null,
    );
    final who = switch (authState) {
      SignedIn(:final user) => '已登入：${user.email}',
      NeedsReauth(:final user) => '需要重新登入：${user.email}',
      _ => '訪客',
    };
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title, style: theme.textTheme.titleSmall),
    );
    // Compact buttons: the app's own buttons are tall and full width, which would fill this small panel.
    final compact = theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
    return Theme(
      data: compact,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            shrinkWrap: true,
            children: [
              Text('開發面板', style: theme.textTheme.titleLarge),
              Text('只在開發版出現。$who', style: theme.textTheme.bodySmall),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_message!, key: const ValueKey('dev-message')),
                ),
              section('測試帳號（驗證碼 $devVerificationCode）'),
              SelectableText('$devAccountEmail  /  $devAccountPassword'),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    key: const ValueKey('dev-sign-in'),
                    onPressed: _busy ? null : () => _run('登入', _signIn),
                    child: const Text('登入（沒有帳號就先建立）'),
                  ),
                  OutlinedButton(
                    onPressed: () => _copy(devAccountEmail, '帳號'),
                    child: const Text('複製帳號'),
                  ),
                  OutlinedButton(
                    onPressed: () => _copy(devAccountPassword, '密碼'),
                    child: const Text('複製密碼'),
                  ),
                  if (signedIn)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _run('登出', _signOut),
                      child: const Text('登出（捨棄未同步）'),
                    ),
                ],
              ),
              section('本機資料'),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    key: const ValueKey('dev-random-trip'),
                    onPressed: _busy
                        ? null
                        : () => _run('新增隨機行程', () async {
                            final made = await factory.randomTrip();
                            _tripId = made.id; // the new trip becomes the target of "加隨機裝備／餐食"
                            return '已新增${made.summary}。下面的裝備與餐食會加到它';
                          }),
                    child: const Text('新增隨機行程（含節點、裝備、餐食）'),
                  ),
                ],
              ),
              if (trips.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('還沒有行程。先新增行程，才能加裝備或餐食。'),
                )
              else ...[
                const SizedBox(height: 8),
                Text(
                  tripId == null
                      ? '請先選一個行程（目前沒有打開行程頁）'
                      : (tripId == widget.openTripId && _tripId == null
                            ? '加到目前打開的行程：'
                            : '加到這個行程：'),
                  style: theme.textTheme.bodySmall,
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('選擇行程'),
                  value: tripId,
                  items: [
                    for (final t in trips)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _tripId = v),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      key: const ValueKey('dev-random-gear'),
                      onPressed: _busy || tripId == null
                          ? null
                          : () => _run('加入隨機裝備', () async {
                              final names = await factory.randomGear(tripId);
                              return '已加入 ${names.length} 件裝備：${names.join('、')}';
                            }),
                      child: const Text('加隨機裝備'),
                    ),
                    OutlinedButton(
                      key: const ValueKey('dev-random-meals'),
                      onPressed: _busy || tripId == null
                          ? null
                          : () => _run('加入隨機餐食', () async {
                              final names = await factory.randomMeals(
                                tripId,
                                days: 2,
                              );
                              return '已加入前兩天的 ${names.length} 份餐食：${names.join('、')}';
                            }),
                      child: const Text('加隨機餐食'),
                    ),
                  ],
                ),
              ],
              section('線上資料（需要登入與連線）'),
              FilledButton.tonal(
                key: const ValueKey('dev-random-event'),
                onPressed: _busy || !signedIn
                    ? null
                    : () => _run(
                        '建立隨機揪團',
                        () async =>
                            '已建立揪團「${(await factory.randomEvent()).title}」',
                      ),
                child: Text(signedIn ? '建立隨機揪團' : '建立隨機揪團（請先登入）'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
