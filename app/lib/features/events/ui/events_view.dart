import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../trips/providers.dart';
import '../data/events_api.dart';
import '../providers.dart';
import 'event_widgets.dart';

/// The "揪團" part of the explore tab: filters, search and the list of group events. Needs a connection.
class EventsView extends ConsumerStatefulWidget {
  const EventsView({super.key});

  @override
  ConsumerState<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends ConsumerState<EventsView> {
  final _search = TextEditingController();
  final _items = <EventSummary>[];
  EventScope _scope = EventScope.all;
  String? _cursor;
  bool _loading = false;
  EventsException? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _locked => _scope.needsLogin && !ref.read(eventsSignedInProvider);

  Future<void> _load({bool reset = false}) async {
    final ticket = ++_request;
    setState(() {
      _error = null;
      if (reset) {
        _items.clear();
        _cursor = null;
      }
    });
    if (_locked) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(eventsApiProvider)
          .list(scope: _scope, q: _search.text, cursor: reset ? null : _cursor);
      if (!mounted || ticket != _request) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _loading = false;
      });
    } on EventsException catch (e) {
      if (!mounted || ticket != _request) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _setScope(EventScope s) {
    if (s == _scope) return;
    setState(() => _scope = s);
    _load(reset: true);
  }

  Future<void> _open(EventSummary e) async {
    await context.push(Routes.event(e.id));
    if (mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    // Signing in or out changes what the lists contain.
    ref.listen(eventsSignedInProvider, (_, _) => _load(reset: true));
    final theme = Theme.of(context);
    final today = () {
      final n = ref.read(clockProvider)();
      return DateTime(n.year, n.month, n.day);
    }();
    final locked = _locked;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            key: const ValueKey('events-search'),
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(reset: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '搜尋揪團標題或地點',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清除',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        _load(reset: true);
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final s in EventScope.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: ValueKey('events-scope-${s.name}'),
                    label: Text(s.label),
                    selected: _scope == s,
                    onSelected: (_) => _setScope(s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                if (locked)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text('登入後使用', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('登入後才看得到你參加和主辦的揪團。', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const ValueKey('events-signin'),
                          onPressed: () => context.push(Routes.withQuery(Routes.login, {'next': Routes.explore})),
                          child: const Text('登入'),
                        ),
                      ],
                    ),
                  )
                else if (_error != null)
                  RetryMessage(
                    text: _error!.text,
                    onRetry: () => _load(reset: _items.isEmpty),
                  )
                else if (!_loading && _items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _search.text.trim().isEmpty ? '目前沒有揪團。' : '沒有符合的揪團。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (!locked)
                  for (final e in _items)
                    EventCard(key: ValueKey('event-${e.id}'), event: e, today: today, onTap: () => _open(e)),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!locked && !_loading && _error == null && _cursor != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                      key: const ValueKey('events-more'),
                      onPressed: () => _load(),
                      child: const Text('載入更多'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
