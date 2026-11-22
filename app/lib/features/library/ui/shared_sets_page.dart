import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../data/shared_sets_api.dart';
import '../providers.dart';

/// "雲端裝備組合": sets other people (or the person) shared. Needs a connection.
class SharedSetsPage extends StatefulWidget {
  const SharedSetsPage({super.key});

  @override
  State<SharedSetsPage> createState() => _SharedSetsPageState();
}

class _SharedSetsPageState extends State<SharedSetsPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('雲端裝備組合'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: '公開'), Tab(text: '我分享的')]),
      ),
      body: TabBarView(controller: _tabs, children: const [_SetList(scope: 'public'), _SetList(scope: 'mine')]),
    );
  }
}

class _SetList extends ConsumerStatefulWidget {
  const _SetList({required this.scope});
  final String scope;

  @override
  ConsumerState<_SetList> createState() => _SetListState();
}

class _SetListState extends ConsumerState<_SetList> with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  final _items = <SharedSetSummary>[];
  String? _cursor;
  bool _loading = true;
  SharedSetsException? _error;

  @override
  bool get wantKeepAlive => true;

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

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _cursor = null;
      }
    });
    try {
      final page = await ref.read(sharedSetsApiProvider).list(scope: widget.scope, q: _search.text, cursor: reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _loading = false;
      });
    } on SharedSetsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        if (widget.scope == 'public')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              key: const ValueKey('shared-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(reset: true),
              decoration: const InputDecoration(hintText: '搜尋標題', prefixIcon: Icon(Icons.search)),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(_error!.text, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: () => _load(reset: true), child: const Text('重試')),
                      ],
                    ),
                  )
                else if (!_loading && _items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(widget.scope == 'mine' ? '你還沒有分享過任何組合。到「我的範本」開啟一份範本，選「分享到雲端」。' : '沒有找到組合。', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  ),
                for (final s in _items)
                  ListTile(
                    key: ValueKey('shared-${s.id}'),
                    leading: Icon(switch (s.visibility) {
                      SharedVisibility.public => Icons.public,
                      SharedVisibility.protected => Icons.lock_outline,
                      SharedVisibility.private => Icons.visibility_off_outlined,
                    }),
                    title: Text(s.title),
                    subtitle: Text('${s.authorName}  ·  ${s.visibility.label}\n${summaryText(s)}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.sharedSet(s.id)),
                  ),
                if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                if (!_loading && _cursor != null) Padding(padding: const EdgeInsets.all(16), child: OutlinedButton(onPressed: () => _load(), child: const Text('載入更多'))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String summaryText(SharedSetSummary s) => '裝備 ${s.gearCount} 件  ·  餐點 ${s.mealCount} 項  ·  ${(s.totalWeight / 1000).toStringAsFixed(1)} kg';
