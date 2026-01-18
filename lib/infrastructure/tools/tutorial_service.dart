import 'dart:async';
import 'package:flutter/material.dart';
import 'package:summitmate/presentation/widgets/tutorial_overlay.dart';
import 'package:summitmate/presentation/utils/tutorial_keys.dart';

/// 教學主題
enum TutorialTopic {
  itinerary, // 行程管理
  gear, // 裝備檢查
  interaction, // 互動功能
  info, // 實用資訊
  groupEvent, // 揪團功能
  all, // 完整教學
}

/// TutorialTopic 的擴展方法
extension TutorialTopicExtension on TutorialTopic {
  String get displayName {
    switch (this) {
      case TutorialTopic.itinerary:
        return '📅 行程管理';
      case TutorialTopic.gear:
        return '🎒 裝備檢查';
      case TutorialTopic.interaction:
        return '💬 互動功能';
      case TutorialTopic.info:
        return 'ℹ️ 實用資訊';
      case TutorialTopic.groupEvent:
        return '👥 揪團功能';
      case TutorialTopic.all:
        return '📖 完整教學';
    }
  }

  String get description {
    switch (this) {
      case TutorialTopic.itinerary:
        return '行程表瀏覽、編輯、上傳、成員管理';
      case TutorialTopic.gear:
        return '裝備清單使用方式';
      case TutorialTopic.interaction:
        return '留言板、投票、同步功能';
      case TutorialTopic.info:
        return '高度圖、路程圖';
      case TutorialTopic.groupEvent:
        return '建立揪團、報名、審核';
      case TutorialTopic.all:
        return '包含所有主題';
    }
  }
}

/// 使用教學服務 (Global State Manager)
class TutorialService {
  /// 當前教學目標列表 (Notifier)
  static final ValueNotifier<List<TutorialTarget>?> tutorialState = ValueNotifier(null);
  
  /// 教學完成 Completer
  static Completer<void>? _activeTutorialCompleter;

  /// 啟動教學 (回傳 Future 等待結束)
  static Future<void> start({
    TutorialTopic? topic,
    // Callbacks for Navigation
    Future<void> Function()? onSwitchToItinerary,
    Future<void> Function()? onSwitchToMessage,
    Future<void> Function()? onSwitchToGear,
    Future<void> Function()? onSwitchToInfo,
    Future<void> Function()? onFocusUpload,
    Future<void> Function()? onFocusSync,
    Future<void> Function()? onFocusElevation,
    Future<void> Function()? onFocusTimeMap,
    Future<void> Function()? onFocusCopyUserId,
    Future<void> Function()? onFocusSettings,
    Future<void> Function()? onFocusDrawer,
    Future<void> Function()? onFocusManageTrips,
    Future<void> Function()? onFocusTripListMember,
    Future<void> Function()? onFocusMemberFab,
    Future<void> Function()? onFocusMemberSearch,
    Future<void> Function()? onFocusMemberResult,
  }) {
    // 若已有教學進行中，先結束它
    if (_activeTutorialCompleter != null && !_activeTutorialCompleter!.isCompleted) {
      stop();
    }
    
    _activeTutorialCompleter = Completer<void>();
    
    final targets = _createTargets(
      topic: topic,
      onSwitchToItinerary: onSwitchToItinerary,
      onSwitchToMessage: onSwitchToMessage,
      onSwitchToGear: onSwitchToGear,
      onSwitchToInfo: onSwitchToInfo,
      onFocusUpload: onFocusUpload,
      onFocusSync: onFocusSync,
      onFocusElevation: onFocusElevation,
      onFocusTimeMap: onFocusTimeMap,
      onFocusCopyUserId: onFocusCopyUserId,
      onFocusSettings: onFocusSettings,
      onFocusDrawer: onFocusDrawer,
      onFocusManageTrips: onFocusManageTrips,
      onFocusTripListMember: onFocusTripListMember,
      onFocusMemberFab: onFocusMemberFab,
      onFocusMemberSearch: onFocusMemberSearch,
      onFocusMemberResult: onFocusMemberResult,
    );
    tutorialState.value = targets;
    
    return _activeTutorialCompleter!.future;
  }

  /// 停止教學
  static void stop() {
    tutorialState.value = null;
    if (_activeTutorialCompleter != null && !_activeTutorialCompleter!.isCompleted) {
      _activeTutorialCompleter!.complete();
      _activeTutorialCompleter = null;
    }
  }

  /// 簡單延遲等待 UI 渲染
  static Future<void> _waitUI() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// 內部產生教學目標
  static List<TutorialTarget> _createTargets({
    TutorialTopic? topic,
    Future<void> Function()? onSwitchToItinerary,
    Future<void> Function()? onSwitchToMessage,
    Future<void> Function()? onSwitchToGear,
    Future<void> Function()? onSwitchToInfo,
    Future<void> Function()? onFocusUpload,
    Future<void> Function()? onFocusSync,
    Future<void> Function()? onFocusElevation,
    Future<void> Function()? onFocusTimeMap,
    Future<void> Function()? onFocusCopyUserId,
    Future<void> Function()? onFocusSettings,
    Future<void> Function()? onFocusDrawer,
    Future<void> Function()? onFocusManageTrips,
    Future<void> Function()? onFocusTripListMember,
    Future<void> Function()? onFocusMemberFab,
    Future<void> Function()? onFocusMemberSearch,
    Future<void> Function()? onFocusMemberResult,
  }) {
    List<TutorialTarget> allTargets = [];

    // ===== 行程管理 (itinerary) =====
    allTargets.add(
      TutorialTarget(
        identify: "Target Itinerary",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.tabItinerary,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "📅 行程表\n查看這次的行程安排",
        onFocus: onSwitchToItinerary ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target Edit",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.btnEdit,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "✒️ 編輯行程\n點這裡調整行程\n（建議由領隊統一維護）",
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target Upload",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.btnUpload,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "☁️ 上傳雲端\n編輯完記得上傳到雲端\n（會覆蓋雲端原本的資料）",
        onFocus: onFocusUpload ?? _waitUI,
      ),
    );

    // Settings Flow
    allTargets.add(
      TutorialTarget(
        identify: "Target SettingsEntry",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.mainSettings,
        alignSkip: Alignment.bottomRight,
        align: ContentAlign.top,
        content: "⚙️ 設定\n點擊這裡開啟設定選單",
        onFocus: onFocusSettings ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target CopyUserId",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.settingsCopyId,
        alignSkip: Alignment.centerLeft,
        align: ContentAlign.bottom,
        content: "📋 複製 ID\n\n這是你的專屬 ID\n點擊複製並分享給團長\n只有團長才能將你加入行程",
        onFocus: onFocusCopyUserId ?? _waitUI,
      ),
    );

    // Member Management
    allTargets.add(
      TutorialTarget(
        identify: "Target DrawerEntry",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.mainDrawerMenu,
        alignSkip: Alignment.bottomRight,
        align: ContentAlign.top,
        content: "☰ 選單\n\n要管理成員，請先開啟側邊選單",
        onFocus: onFocusDrawer ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target DrawerManageTrips",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.drawerManageTrips,
        alignSkip: Alignment.centerRight,
        align: ContentAlign.center,
        content: "📂 管理行程\n\n進入行程列表來管理成員",
        onFocus: onFocusManageTrips ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target TripListMember",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.tripListActiveMemberBtn,
        alignSkip: Alignment.topRight,
        align: ContentAlign.bottom,
        content: "👥 成員按鈕\n\n找到你的行程，點擊「成員」\n進入成員管理畫面",
        onFocus: onFocusTripListMember ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target MemberListFab",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.memberFab,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.top,
        content: "➕ 新增成員\n\n點擊右下角按鈕\n準備輸入隊友的 ID",
        onFocus: onFocusMemberFab ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target MemberSearchInput",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.memberSearchInput,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "🔍 輸入 ID\n\n在此貼上隊友分享給你的 ID",
        onFocus: onFocusMemberSearch ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target MemberSearchAction",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.memberSearchBtn,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.top,
        content: "🔎 開始搜尋\n\n系統將尋找對應的使用者",
        onFocus: onFocusMemberSearch ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target MemberConfirm",
        topic: TutorialTopic.itinerary,
        keyTarget: TutorialKeys.memberConfirmBtn,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.top,
        content: "✅ 確認加入\n\n確認資料無誤後\n點擊加入成員",
        onFocus: onFocusMemberResult ?? _waitUI,
      ),
    );

    // ===== 裝備檢查 (gear) =====
    allTargets.add(
      TutorialTarget(
        identify: "Target Gear",
        topic: TutorialTopic.gear,
        keyTarget: TutorialKeys.tabGear,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "裝備檢查 🎒\n把裝備和糧食都輸入進來\n幫你算好總重量，出發前輔助檢查",
        onFocus: onSwitchToGear ?? _waitUI,
      ),
    );

    // ===== 互動功能 (interaction) =====
    allTargets.add(
      TutorialTarget(
        identify: "Target Message",
        topic: TutorialTopic.interaction,
        keyTarget: TutorialKeys.tabMessage,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "互動專區 💬\n有什麼話想對隊友說？\n這裡有留言板和投票活動",
        onFocus: onSwitchToMessage ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target Sync",
        topic: TutorialTopic.interaction,
        keyTarget: TutorialKeys.btnSync,
        align: ContentAlign.bottom,
        content: "同步更新 🔄\n把雲端最新的行程、留言和投票下載下來\n(⚠️將會覆蓋掉你手機裡的資料)",
        onFocus: onFocusSync ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target Polls",
        topic: TutorialTopic.interaction,
        keyTarget: TutorialKeys.tabPolls,
        align: ContentAlign.bottom,
        content: "投票活動 🗳️\n晚餐吃什麼？何時集合？\n都可以在這裡發起投票表決",
      ),
    );

    // ===== 實用資訊 (info) =====
    allTargets.add(
      TutorialTarget(
        identify: "Target Info",
        topic: TutorialTopic.info,
        keyTarget: TutorialKeys.tabInfo,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.top,
        content: "實用資訊 ℹ️\n這裡有一些好用的步道資訊\n像是天氣預報和入山證連結",
        onFocus: onSwitchToInfo ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target Elevation",
        topic: TutorialTopic.info,
        keyTarget: TutorialKeys.expandedElevation,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.bottom,
        content: "⛰️ 海拔高度\n高度的爬升變化一目了然",
        onFocus: onFocusElevation ?? _waitUI,
      ),
    );

    allTargets.add(
      TutorialTarget(
        identify: "Target TimeMap",
        topic: TutorialTopic.info,
        keyTarget: TutorialKeys.expandedTimeMap,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.bottom,
        content: "⏱️ 路程時間\n查看各段路程需要的時間",
        onFocus: onFocusTimeMap ?? _waitUI,
      ),
    );

    // ===== 揪團功能 (groupEvent) =====
    allTargets.add(
      TutorialTarget(
        identify: "Target GroupEvent",
        topic: TutorialTopic.groupEvent,
        keyTarget: null,
        align: ContentAlign.center,
        content: "揪團功能 👥\n想找隊友一起爬山？\n點擊左上角選單 → 「揪團」\n可以發起或參加揪團活動！",
      ),
    );

    // ===== 完成畫面 (通用) =====
    allTargets.add(
      TutorialTarget(
        identify: "Target Complete",
        topic: TutorialTopic.all,
        keyTarget: null,
        align: ContentAlign.center,
        content: "🎉 教學完成！\n點擊畫面開始你的旅程",
      ),
    );

    // 根據 topic 過濾
    if (topic == null || topic == TutorialTopic.all) {
      return allTargets;
    } else {
      return allTargets.where((t) => t.topic == topic || t.topic == TutorialTopic.all).toList();
    }
  }

  /// 獲取下一個不同主題的索引
  static int? getNextTopicIndex(List<TutorialTarget> targets, int currentIndex) {
    if (currentIndex >= targets.length - 1) return null;
    final currentTopic = targets[currentIndex].topic;
    for (int i = currentIndex + 1; i < targets.length; i++) {
      if (targets[i].topic != currentTopic) {
        return i;
      }
    }
    return null;
  }
}
