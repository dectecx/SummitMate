import 'package:summitmate/domain/domain.dart';

/// 所有教學內容的靜態定義
///
/// 集中管理 Quick Tour 卡片與各章節完整教學步驟，
/// 與 UI 解耦，方便日後更新文案。
class TutorialContent {
  TutorialContent._();

  // ─────────────────────────────────────────────
  // Quick Tour（初次登入，5 張卡片）
  // ─────────────────────────────────────────────

  static const List<QuickTourCard> quickTourCards = [
    QuickTourCard(
      emoji: '🏔️',
      title: '歡迎來到 SummitMate',
      description: '你的登山行程協作助手。\n無論是規劃行程、管理裝備，還是找隊友，這裡都搞定。',
      subtitle: '功能快速覽',
    ),
    QuickTourCard(emoji: '📅', title: '行程管理', description: '建立多日行程表，記錄每段路程的時間、海拔與距離。\n支援雲端同步，讓全隊共享最新行程。'),
    QuickTourCard(emoji: '🎒', title: '裝備清單', description: '列出所有隨身裝備與糧食，\n自動計算總重量，出發前不再漏帶東西。'),
    QuickTourCard(emoji: '💬', title: '協作功能', description: '在留言板與隊友討論行前事項，\n用投票決定集合時間或晚餐菜單。'),
    QuickTourCard(emoji: '👥', title: '揪團活動', description: '發起公開活動，讓志同道合的山友加入。\n可設定人數、日期與難度，輕鬆找到理想隊伍。'),
  ];

  // ─────────────────────────────────────────────
  // 完整教學步驟（各章節）
  // ─────────────────────────────────────────────

  static const List<TutorialStep> _itinerarySteps = [
    TutorialStep(
      id: 'itin_01',
      chapter: TutorialChapter.itinerary,
      emoji: '📅',
      title: '行程表總覽',
      description: '首頁的「行程」分頁顯示目前行程的所有天數。\n你可以依照日期（D1、D2…）瀏覽各天的路線與紮營點。',
      mockDataHint: '範例行程：嘉明湖 3 天 2 夜',
    ),
    TutorialStep(
      id: 'itin_02',
      chapter: TutorialChapter.itinerary,
      emoji: '✒️',
      title: '編輯行程',
      description: '點擊右上角的「✏️ 編輯」按鈕進入編輯模式。\n領隊可以新增、刪除或調整行程項目。\n建議由領隊統一維護，避免衝突。',
    ),
    TutorialStep(
      id: 'itin_03',
      chapter: TutorialChapter.itinerary,
      emoji: '👤',
      title: '你的帳號 ID',
      description: '在「設定」中可以複製你的專屬 User ID。\n將 ID 分享給領隊，領隊才能將你加入行程。',
    ),
    TutorialStep(
      id: 'itin_04',
      chapter: TutorialChapter.itinerary,
      emoji: '👥',
      title: '管理成員',
      description: '在行程列表中點擊「成員」，可以查看、新增或移除成員。\n透過 User ID 搜尋隊友並設定其角色（成員 / 嚮導）。',
    ),
  ];

  static const List<TutorialStep> _gearSteps = [
    TutorialStep(
      id: 'gear_01',
      chapter: TutorialChapter.gear,
      emoji: '🎒',
      title: '裝備清單',
      description: '「裝備」分頁讓你建立本次行程的物品清單。\n每件裝備都可記錄名稱、重量與數量。',
      mockDataHint: '範例清單含睡袋、帳篷、炊具等常見登山裝備',
    ),
    TutorialStep(
      id: 'gear_02',
      chapter: TutorialChapter.gear,
      emoji: '⚖️',
      title: '自動計算總重',
      description: '系統會即時加總所有裝備重量，顯示在清單頂部。\n出發前確認背包重量，防止超載受傷。',
    ),
    TutorialStep(
      id: 'gear_03',
      chapter: TutorialChapter.gear,
      emoji: '📦',
      title: '裝備庫',
      description: '常用裝備可以儲存到「裝備庫」，下次建立新行程時直接匯入，省去重複輸入的麻煩。',
    ),
  ];

  static const List<TutorialStep> _collaborationSteps = [
    TutorialStep(
      id: 'collab_01',
      chapter: TutorialChapter.collaboration,
      emoji: '💬',
      title: '留言板',
      description: '在「互動」分頁的留言板，可以與全隊成員即時溝通。\n適合討論行前準備、行程調整等事項。',
      mockDataHint: '範例留言：「集合地點確認？」「記得帶雨衣！」',
    ),
    TutorialStep(
      id: 'collab_02',
      chapter: TutorialChapter.collaboration,
      emoji: '🗳️',
      title: '投票活動',
      description: '發起投票讓全隊表決，例如「幾點集合？」或「晚餐想吃什麼？」。\n設定選項後，成員即可即時投票。',
    ),
    TutorialStep(
      id: 'collab_03',
      chapter: TutorialChapter.collaboration,
      emoji: '🔄',
      title: '同步更新',
      description: '點擊同步按鈕，可以將雲端最新的行程、留言與投票下載到本機。\n⚠️ 注意：同步時會以雲端資料覆蓋本機。',
    ),
  ];

  static const List<TutorialStep> _groupEventSteps = [
    TutorialStep(
      id: 'grp_01',
      chapter: TutorialChapter.groupEvent,
      emoji: '👥',
      title: '揪團活動',
      description: '從側邊選單進入「揪團」，可以瀏覽公開的山行活動，或自己發起一場招募隊友的揪團。',
    ),
    TutorialStep(
      id: 'grp_02',
      chapter: TutorialChapter.groupEvent,
      emoji: '📋',
      title: '發起活動',
      description: '填寫活動名稱、日期、難度、目標山峰與人數上限，\n發布後其他使用者就可以看到並申請加入。',
    ),
    TutorialStep(
      id: 'grp_03',
      chapter: TutorialChapter.groupEvent,
      emoji: '✅',
      title: '審核申請',
      description: '作為活動發起人，你可以在「我的揪團」中查看申請者，\n接受或拒絕他們的加入請求。',
    ),
  ];

  static const List<TutorialStep> _cloudSteps = [
    TutorialStep(
      id: 'cloud_01',
      chapter: TutorialChapter.cloud,
      emoji: '☁️',
      title: '上傳至雲端',
      description: '編輯完行程後，點擊 AppBar 的「⬆️」按鈕，\n將本機行程上傳到雲端，讓其他成員也能看到最新版本。',
    ),
    TutorialStep(
      id: 'cloud_02',
      chapter: TutorialChapter.cloud,
      emoji: '📶',
      title: '離線模式',
      description: '在設定中可開啟「離線模式」，暫停所有自動同步。\n適合在山上無網路時避免連線警告。\n回到有網路的環境後記得關閉離線模式。',
    ),
    TutorialStep(
      id: 'cloud_03',
      chapter: TutorialChapter.cloud,
      emoji: '⚡',
      title: '同步狀態指示器',
      description: 'AppBar 右側的指示燈顯示目前同步狀態：\n🟢 已同步  🟡 離線暫存  🔴 同步失敗\n同步失敗時可手動重試。',
    ),
  ];

  /// 取得指定章節的步驟列表
  static List<TutorialStep> stepsForChapter(TutorialChapter chapter) {
    switch (chapter) {
      case TutorialChapter.itinerary:
        return _itinerarySteps;
      case TutorialChapter.gear:
        return _gearSteps;
      case TutorialChapter.collaboration:
        return _collaborationSteps;
      case TutorialChapter.groupEvent:
        return _groupEventSteps;
      case TutorialChapter.cloud:
        return _cloudSteps;
    }
  }

  /// 取得所有步驟（完整教學）
  static List<TutorialStep> get allSteps => [
    ..._itinerarySteps,
    ..._gearSteps,
    ..._collaborationSteps,
    ..._groupEventSteps,
    ..._cloudSteps,
  ];
}
