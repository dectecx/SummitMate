import 'package:material_ui/material_ui.dart';

/// Static help: short answers to the questions people actually have. Not an interactive tutorial.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const topics = <({String question, String answer})>[
    (
      question: '沒有訊號也能用嗎？',
      answer: '行程、裝備、糧食和已下載的地圖都存在手機裡，沒有訊號也能查看與修改。有網路時會自動同步，沒有登入就只存在這支手機。',
    ),
    (
      question: '怎麼下載離線地圖？',
      answer: '到「地圖」分頁右上角的下載圖示。選要去的山區按「下載」，可以先排好幾個區域，會一個一個下載，切到背景也會繼續。建議用 Wi-Fi，出發前先下載。',
    ),
    (
      question: '魯地圖怎麼用？',
      answer: '在「地圖 → 離線地圖」下載「魯地圖」（約 410 MB）。之後在地圖右上角的圖層選單選魯地圖。',
    ),
    (
      question: '主要山頭有什麼用？',
      answer: '行程可以設定一座主要山頭。設定後，「成員與天氣」會顯示那座山的天氣，並提醒你下載那一區的離線地圖，新增節點時也會推薦你以前在同一座山用過的節點名稱。',
    ),
    (
      question: '怎麼匯入或匯出 GPX？',
      answer: '「行程」列表右上角的圖示可以選一個 GPX 檔建立行程，會自動產生節點和海拔剖面圖。進入行程後，右上角選單的「匯出 GPX」可以把行程分享給其他 App 或朋友。',
    ),
    (
      question: '裝備庫、範本和雲端分享是什麼？',
      answer: '新增裝備或餐點時，名稱會自動記進「我的裝備庫」，下次輸入名稱就能直接選。行程右上角選單的「存成範本」可以把整份裝備與餐點存起來，「套用範本」加到別的行程。登入後可以在「我的範本」把範本分享到雲端（公開、需要 Key 或只有自己），也能在「雲端裝備組合」找別人分享的組合。',
    ),
    (
      question: '留言、投票和收藏怎麼用？',
      answer: '行程裡的「討論」分段有留言板和投票：成員都能留言、回覆、投票，離線也能用，連線後同步；團長和嚮導可以建立投票、刪除留言。在「探索」或山岳頁點愛心就能收藏山岳，「探索」可以只看已收藏，「我 → 我的收藏」會列出全部。',
    ),
    (
      question: '訪客和登入有什麼差別？',
      answer: '訪客的資料只存在這支手機。登入後會自動備份，換手機也找得回來，還能邀請隊友一起規劃。登入前建立的行程會在登入後一併備份。',
    ),
    (
      question: '隊友可以做什麼？',
      answer: '團長和嚮導可以編輯行程；隊員可以查看。裝備和餐食是每個人自己的清單，只有自己看得到。團長可以在成員選單把團長交給其他人（需要網路）。',
    ),
    (
      question: '揪團是什麼？怎麼參加？',
      answer: '「探索」頁最上方切到「揪團」，可以看別人發起的活動，用標題或地點搜尋。登入後可以申請加入、留言、按讚，也能自己建立揪團。通過申請後才看得到主辦人寫的隊員專屬留言；若主辦人連結了行程，通過的人會自動加入行程成員。揪團需要網路。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用說明')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final t in topics)
            ExpansionTile(
              key: ValueKey('help-${t.question}'),
              title: Text(t.question),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(t.answer)],
            ),
        ],
      ),
    );
  }
}
