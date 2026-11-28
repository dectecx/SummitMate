import 'package:material_ui/material_ui.dart';

import '../../shared/brand/illustrations.dart';

/// Static help: short answers to the questions people actually have, grouped by what they are doing.
/// Not an interactive tutorial.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const topics = <({String section, String question, String answer})>[
    (
      section: '開始使用',
      question: '沒有訊號也能用嗎？',
      answer: '行程、裝備、餐食和已下載的魯地圖都存在手機裡，沒有訊號也能查看與修改。有網路時會自動同步；沒有登入就只存在這支手機。山岳資料與用品店第一次需要網路載入，之後離線也看得到。',
    ),
    (
      section: '開始使用',
      question: '訪客和登入有什麼差別？',
      answer: '訪客可以使用行程、裝備、餐食和地圖，資料只存在這支手機。登入後會自動備份、跨手機同步，也能邀請隊友、加好友、參加與建立揪團、分享裝備組合。',
    ),
    (
      section: '行程與裝備',
      question: '主要山頭有什麼用？',
      answer: '行程可以設定一座主要山頭。設定後，行程頁會顯示每天的天氣，並提醒你下載魯地圖離線地圖，新增節點時也會推薦你以前在同一座山用過的節點名稱。',
    ),
    (
      section: '行程與裝備',
      question: '天氣是怎麼顯示的？',
      answer: '行程頁會顯示你選的那一天的天氣，地點是當天行程中最高、而且有填座標的節點（那裡最冷、風最大）；當天沒有座標時，沿用前一天或主要山頭。預報最多約 16 天，太遠的日子會告訴你何時可以查看。',
    ),
    (
      section: '行程與裝備',
      question: '怎麼匯入或匯出 GPX？',
      answer: '「首頁」右上角的「匯入 GPX」可以選一個 GPX 檔建立行程，會自動產生節點和海拔剖面圖。進入行程後，右上角選單的「匯出 GPX」可以把行程分享給其他 App 或朋友。',
    ),
    (
      section: '行程與裝備',
      question: '常用清單、範本和雲端分享是什麼？',
      answer: '新增裝備或餐食時，名稱會自動記進「常用清單」，下次輸入名稱就能直接選。行程右上角選單的「存成範本」可以把整份裝備與餐食存起來，「套用範本」加到別的行程。登入後打開一份範本按「分享到雲端」（公開、需要 Key 或只有自己），也能在「雲端裝備組合」找別人分享的組合。這些都在「我 → 裝備與範本」。',
    ),
    (
      section: '地圖',
      question: '魯地圖怎麼用？',
      answer: '到「地圖 → 離線地圖」下載魯地圖（約 410 MB，建議用 Wi-Fi，切到背景也會繼續）。下載完成後，在地圖右上角的圖層選單選魯地圖，就能在沒有訊號的山上看地圖。',
    ),
    (
      section: '一起出發',
      question: '隊友可以做什麼？',
      answer: '團長和嚮導可以編輯行程；隊員可以查看，並管理自己的裝備與餐食。團長可以在成員選單把團長交給其他人（需要網路）。',
    ),
    (
      section: '一起出發',
      question: '怎麼加好友？',
      answer: '「我 → 好友」輸入對方的 Email 送出邀請，對方接受後才會成為好友。在揪團頁也能直接對主辦人或留言的人加好友。邀請隊友時可以直接從好友挑選，不用再記 Email。',
    ),
    (
      section: '一起出發',
      question: '留言、投票和收藏怎麼用？',
      answer: '行程裡的「討論」分段有留言板和投票：成員都能留言、回覆、投票，離線也能用，連線後同步；團長和嚮導可以建立投票、刪除留言。在「探索」或山岳頁點愛心就能收藏山岳，揪團用書籤收藏，「我 → 我的收藏」會列出全部。',
    ),
    (
      section: '一起出發',
      question: '揪團是什麼？怎麼參加？',
      answer: '在「揪團」頁的「找團」可以看別人發起的活動，「我的團」是你參加和主辦的；主辦的團有人申請時會顯示待審核數量。登入後可以申請加入、留言、按讚，也能自己建立揪團。通過申請後才看得到主辦人寫的隊員專屬留言；若主辦人連結了行程，通過的人會自動加入行程成員。揪團需要網路。',
    ),
    (
      section: '探索',
      question: '用品店資料可靠嗎？',
      answer: '「探索 → 用品店」只收錄 Google 評價 4.0 星以上的店家，每筆都標有檢查日期。營業時間和電話可能變動，出發前請先確認；可以直接點「地圖」或撥電話。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = <String>[];
    for (final t in topics) {
      if (!sections.contains(t.section)) sections.add(t.section);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('使用說明')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Center(child: IllustrationView(Illustration.help, width: 150)),
          const SizedBox(height: 4),
          Center(child: Text('常見問題', style: theme.textTheme.titleMedium)),
          const SizedBox(height: 4),
          Center(child: Text('點一下問題看答案', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              child: Text(section, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1)),
            ),
            Card(
              child: Column(
                children: [
                  for (final t in topics.where((t) => t.section == section))
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: ValueKey('help-${t.question}'),
                        title: Text(t.question, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        shape: const RoundedRectangleBorder(),
                        collapsedShape: const RoundedRectangleBorder(),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(t.answer, style: theme.textTheme.bodyMedium?.copyWith(height: 1.55, color: theme.colorScheme.onSurfaceVariant))],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
