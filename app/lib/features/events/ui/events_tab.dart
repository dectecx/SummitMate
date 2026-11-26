import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/page_accents.dart';
import '../../../shared/page_bar.dart';
import '../data/events_api.dart';
import '../providers.dart';
import 'event_widgets.dart';
import 'events_view.dart';

enum _Segment { find, mine }

/// The "揪團" tab: events to join, and the ones the person joined or hosts.
class EventsTab extends ConsumerStatefulWidget {
  const EventsTab({super.key});

  @override
  ConsumerState<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<EventsTab> {
  _Segment _segment = _Segment.find;

  /// "我的團" is only built once opened; after that both sides keep their search and filter.
  bool _mineOpened = false;

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingApplicationsProvider).value ?? 0;
    return PageAccents(child: Scaffold(
      appBar: pageBar(context, '揪團'),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('events-create'),
        onPressed: () => openCreateEvent(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('建立揪團'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<_Segment>(
              key: const ValueKey('events-segment'),
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(value: _Segment.find, label: Text('找團')),
                ButtonSegment(
                  value: _Segment.mine,
                  label: Badge.count(count: pending, isLabelVisible: pending > 0, offset: const Offset(16, -6), child: const Text('我的團')),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() {
                _segment = s.first;
                if (_segment == _Segment.mine) _mineOpened = true;
              }),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _segment.index,
              sizing: StackFit.expand,
              children: [
                EventsView(scopes: const [EventScope.all, EventScope.upcoming, EventScope.popular], active: _segment == _Segment.find),
                if (_mineOpened)
                  EventsView(
                    scopes: const [EventScope.joined, EventScope.hosting],
                    initialScope: pending > 0 ? EventScope.hosting : EventScope.joined,
                    active: _segment == _Segment.mine,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
