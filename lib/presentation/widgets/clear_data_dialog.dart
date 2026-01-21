import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/services.dart'; // for SystemNavigator
import 'package:url_launcher/url_launcher.dart';

import '../../core/di.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

/// 顯示清除資料對話框
///
/// 這是 Debug 工具，但在正式版保留以解決極端異常狀況。
/// 允許用戶選擇性清除特定類型的本地 Hive 資料。
void showClearDataDialog(BuildContext context) {
  // 預設選項狀態
  bool clearItinerary = true;
  bool clearMessages = true;
  bool clearGear = true;
  bool clearGearLibrary = true;
  bool clearWeather = true;
  bool clearSettings = false;
  bool clearLogs = false;
  bool clearPolls = true;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (innerContext, setState) => AlertDialog(
        title: const Text('⚠️ 清除本地資料'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('選擇要清除的資料類型：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('行程資料'),
                subtitle: const Text('包含所有行程與內容', style: TextStyle(fontSize: 11)),
                value: clearItinerary,
                onChanged: (v) => setState(() => clearItinerary = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('留言資料'),
                value: clearMessages,
                onChanged: (v) => setState(() => clearMessages = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('裝備清單'),
                subtitle: const Text('公開/標準裝備組合', style: TextStyle(fontSize: 11)),
                value: clearGear,
                onChanged: (v) => setState(() => clearGear = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('個人裝備庫'),
                value: clearGearLibrary,
                onChanged: (v) => setState(() => clearGearLibrary = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('天氣快取'),
                value: clearWeather,
                onChanged: (v) => setState(() => clearWeather = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('設定與身分'),
                subtitle: const Text('清除後需重新設定暱稱', style: TextStyle(fontSize: 11)),
                value: clearSettings,
                onChanged: (v) => setState(() => clearSettings = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('App 日誌'),
                value: clearLogs,
                onChanged: (v) => setState(() => clearLogs = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('投票資料'),
                value: clearPolls,
                onChanged: (v) => setState(() => clearPolls = v ?? false),
              ),
              const Divider(),
              const Text(
                '此操作無法復原！',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // 執行選擇性清除
              await getIt<HiveService>().clearSelectedData(
                clearTrips: clearItinerary,
                clearItinerary: clearItinerary,
                clearMessages: clearMessages,
                clearGear: clearGear,
                clearGearLibrary: clearGearLibrary,
                clearWeather: clearWeather,
                clearSettings: clearSettings,
                clearLogs: clearLogs,
                clearPolls: clearPolls,
              );

              // 顯示重啟提示對話框 (不可取消)
              if (context.mounted) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) => AlertDialog(
                    title: const Text('✅ 清除完成'),
                    content: Text(kIsWeb ? '資料已清除，請重新載入網頁以完成操作。' : '資料已清除，請重新啟動 App 以完成操作。'),
                    actions: [
                      FilledButton(
                        onPressed: () {
                          if (kIsWeb) {
                            // Web: Reload the page
                            launchUrl(Uri.base, webOnlyWindowName: '_self');
                          } else {
                            // Mobile: Close the app
                            SystemNavigator.pop();
                          }
                        },
                        child: Text(kIsWeb ? '重新載入' : '關閉 App'),
                      ),
                    ],
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('確定清除'),
          ),
        ],
      ),
    ),
  );
}
