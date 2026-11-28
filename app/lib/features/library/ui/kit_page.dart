import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../shared/settings_section.dart';

/// "裝備與範本": the one way into the saved names, the saved sets and the shared ones, each saying what it is for.
class KitPage extends StatelessWidget {
  const KitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('裝備與範本')),
      body: ListView(
        padding: EdgeInsets.only(bottom: 32 + MediaQuery.paddingOf(context).bottom),
        children: [
          SettingsSection(
            title: '我的',
            children: [
              SettingsTile(icon: Icons.bookmark_outline, title: '常用清單', subtitle: '打過的裝備與餐食名稱，新增時直接選', onTap: () => context.push(Routes.library)),
              SettingsTile(icon: Icons.inventory_2_outlined, title: '我的範本', subtitle: '整份打包清單，套用到別的行程', onTap: () => context.push(Routes.templates)),
            ],
          ),
          SettingsSection(
            title: '大家分享的',
            children: [SettingsTile(icon: Icons.cloud_outlined, title: '雲端裝備組合', subtitle: '看別人的清單，或管理自己分享的', onTap: () => context.push(Routes.sharedSets))],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('怎麼把清單分享給別人', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final (i, step) in const ['打開一個行程，在右上角選「存成範本」', '到「我的範本」打開它', '按「分享到雲端」，選擇誰可以看（需要登入）'].indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 24, child: Text('${i + 1}.', style: theme.textTheme.titleSmall)),
                            Expanded(child: Text(step)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
