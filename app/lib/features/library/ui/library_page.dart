import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../shared/page_accents.dart';
import '../../meals/ui/meal_icons.dart';
import '../../gear/ui/gear_icons.dart';
import '../../../core/db/app_database.dart';
import '../../../shared/brand/illustrations.dart';
import '../../../shared/coming_soon.dart';
import '../../../shared/hint_banner.dart';
import '../../../shared/settings_section.dart';
import '../../gear/domain/gear_logic.dart';
import '../../meals/domain/meal_logic.dart';
import '../providers.dart';
import 'library_item_sheet.dart';

/// "常用清單": the gear and the foods the person uses often. New trip items are added here automatically.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _kind => _tabs.index == 0 ? 'gear' : 'meal';

  @override
  Widget build(BuildContext context) {
    return PageAccents.inner(child: Scaffold(
      appBar: AppBar(
        title: const Text('常用清單'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: '裝備'),
            Tab(text: '餐食'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ItemList(kind: 'gear'),
          _ItemList(kind: 'meal'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('library-add'),
        onPressed: () => showLibraryItemSheet(context, kind: _kind),
        icon: const Icon(Icons.add),
        label: Text(_kind == 'gear' ? '新增裝備' : '新增餐食'),
      ),
    ));
  }
}

class _ItemList extends ConsumerWidget {
  const _ItemList({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(libraryItemsProvider(kind)).value ?? const <LibraryItem>[];
    final isGear = kind == 'gear';
    if (items.isEmpty) {
      return ComingSoon(
        illustration: isGear ? Illustration.gear : Illustration.meal,
        message: isGear ? '還沒有裝備。在行程裡新增裝備時，會自動記在這裡，下次輸入名稱就能直接選。' : '還沒有常用餐食。在行程裡新增餐食時，會自動記在這裡，下次輸入名稱就能直接選。',
      );
    }
    return ListView(
      padding: EdgeInsets.only(bottom: 96 + MediaQuery.paddingOf(context).bottom),
      children: [
        HintBanner(hintId: 'library-$kind', icon: Icons.bookmark_outline, text: '點一下可以修改；新增行程項目時輸入名稱就會出現建議。'),
        SettingsSection(
          children: [
            for (final i in items)
              SettingsTile(
                key: ValueKey('library-${i.id}'),
                icon: isGear ? gearIcon(GearCategory.fromKey(i.category)) : mealIcon(MealType.fromKey(i.category)),
                title: i.name,
                subtitle: isGear
                    ? '${GearCategory.fromKey(i.category).label}  ·  ${formatWeight(i.weight)}'
                    : '${MealType.fromKey(i.category).label}  ·  ${formatWeight(i.weight)}${i.calories > 0 ? '  ·  ${formatKcal(i.calories)}' : ''}',
                onTap: () => showLibraryItemSheet(context, kind: kind, item: i),
              ),
          ],
        ),
      ],
    );
  }
}
