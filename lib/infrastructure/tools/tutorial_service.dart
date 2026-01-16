import 'package:flutter/material.dart';
import 'package:summitmate/presentation/widgets/tutorial_overlay.dart';

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

/// 使用教學服務
///
/// 負責產生與管理 App 內的使用教學指引 (Tutorial Targets)。
/// 針對特定 UI 元件 (Key) 定義對應的說明內容與操作指引。
class TutorialService {
  /// 根據主題初始化教學目標
  ///
  /// [topic] 指定要顯示的主題，若為 null 或 TutorialTopic.all 則顯示所有教學
  static List<TutorialTarget> initTargets({
    required GlobalKey keyTabItinerary,
    required GlobalKey keyTabMessage,
    required GlobalKey keyTabGear,
    required GlobalKey keyTabInfo,
    required GlobalKey keyBtnEdit,
    required GlobalKey keyBtnUpload,
    required GlobalKey keyBtnSync,
    required GlobalKey keyTabPolls,
    required GlobalKey keyInfoElevation,
    required GlobalKey keyInfoTimeMap,
    GlobalKey? keyBtnCopyUserId,
    GlobalKey? keyBtnAddMember,
    GlobalKey? keyTabGroupEvent,
    required Future<void> Function() onSwitchToItinerary,
    required Future<void> Function() onSwitchToMessage,
    required Future<void> Function() onSwitchToGear,
    required Future<void> Function() onSwitchToInfo,
    required Future<void> Function() onFocusUpload,
    required Future<void> Function() onFocusSync,
    required Future<void> Function() onFocusElevation,
    required Future<void> Function() onFocusTimeMap,
    Future<void> Function()? onFocusCopyUserId,
    Future<void> Function()? onFocusAddMember,
    Future<void> Function()? onSwitchToGroupEvent,
    TutorialTopic? topic,
  }) {
    List<TutorialTarget> allTargets = [];

    // ===== 行程管理 (itinerary) =====
    // 1. 行程頁籤
    allTargets.add(
      TutorialTarget(
        identify: "Target Itinerary",
        topic: TutorialTopic.itinerary,
        keyTarget: keyTabItinerary,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "行程表 📅\n這是這次的行程安排\n隊友們隨時都可以查看喔",
        onFocus: onSwitchToItinerary,
      ),
    );

    // 2. 編輯按鈕
    allTargets.add(
      TutorialTarget(
        identify: "Target Edit",
        topic: TutorialTopic.itinerary,
        keyTarget: keyBtnEdit,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "編輯行程 ✏️\n想調整行程點這裡\n(📣建議由領隊統一維護)",
      ),
    );

    // 3. 上傳按鈕 (需先觸發編輯模式)
    allTargets.add(
      TutorialTarget(
        identify: "Target Upload",
        topic: TutorialTopic.itinerary,
        keyTarget: keyBtnUpload,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "上傳雲端 ☁️\n編輯完記得按這裡上傳\n(⚠️小心會把雲端原本的資料覆蓋掉)",
        onFocus: onFocusUpload,
      ),
    );

    // 4. 複製 userId (文字說明，無需 Key)
    allTargets.add(
      TutorialTarget(
        identify: "Target CopyUserId",
        topic: TutorialTopic.itinerary,
        keyTarget: null, // 無 UI 綁定，顯示文字說明
        align: ContentAlign.center,
        content: "複製 ID 📋\n在「設定」中可以查看並複製你的專屬 ID\n分享給隊友，讓他們把你加入行程！",
      ),
    );

    // 5. 加入成員 (文字說明，無需 Key)
    allTargets.add(
      TutorialTarget(
        identify: "Target AddMember",
        topic: TutorialTopic.itinerary,
        keyTarget: null,
        align: ContentAlign.center,
        content: "加入成員 👤\n在行程列表點擊「成員管理」\n輸入隊友的 ID 就能把他們加入！",
      ),
    );

    // ===== 裝備檢查 (gear) =====
    allTargets.add(
      TutorialTarget(
        identify: "Target Gear",
        topic: TutorialTopic.gear,
        keyTarget: keyTabGear,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "裝備檢查 🎒\n把裝備和糧食都輸入進來\n幫你算好總重量，出發前輔助檢查",
        onFocus: onSwitchToGear,
      ),
    );

    // ===== 互動功能 (interaction) =====
    // 留言板頁籤
    allTargets.add(
      TutorialTarget(
        identify: "Target Message",
        topic: TutorialTopic.interaction,
        keyTarget: keyTabMessage,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "互動專區 💬\n有什麼話想對隊友說？\n這裡有留言板和投票活動",
        onFocus: onSwitchToMessage,
      ),
    );

    // 同步按鈕
    allTargets.add(
      TutorialTarget(
        identify: "Target Sync",
        topic: TutorialTopic.interaction,
        keyTarget: keyBtnSync,
        align: ContentAlign.bottom,
        content: "同步更新 🔄\n把雲端最新的行程、留言和投票下載下來\n(⚠️將會覆蓋掉你手機裡的資料)",
        onFocus: onFocusSync,
      ),
    );

    // 投票專區頁籤
    allTargets.add(
      TutorialTarget(
        identify: "Target Polls",
        topic: TutorialTopic.interaction,
        keyTarget: keyTabPolls,
        align: ContentAlign.bottom,
        content: "投票活動 🗳️\n晚餐吃什麼？何時集合？\n都可以在這裡發起投票表決",
      ),
    );

    // ===== 實用資訊 (info) =====
    // 資訊頁籤
    allTargets.add(
      TutorialTarget(
        identify: "Target Info",
        topic: TutorialTopic.info,
        keyTarget: keyTabInfo,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.top,
        content: "實用資訊 ℹ️\n這裡有一些好用的步道資訊\n像是天氣預報和入山證連結",
        onFocus: onSwitchToInfo,
      ),
    );

    // 海拔高度圖
    allTargets.add(
      TutorialTarget(
        identify: "Target Elevation",
        topic: TutorialTopic.info,
        keyTarget: keyInfoElevation,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.bottom,
        content: "海拔高度 ⛰️\n想知道爬升多少？\n點一下這裡就會展開高度圖給你看",
        onFocus: onFocusElevation,
      ),
    );

    // 路程時間圖
    allTargets.add(
      TutorialTarget(
        identify: "Target TimeMap",
        topic: TutorialTopic.info,
        keyTarget: keyInfoTimeMap,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.bottom,
        content: "路程時間 ⏱️\n還有路程時間圖\n點一下就能參考各路段要走多久",
        onFocus: onFocusTimeMap,
      ),
    );

    // ===== 揪團功能 (groupEvent) =====
    // 文字說明，無需 Key
    allTargets.add(
      TutorialTarget(
        identify: "Target GroupEvent",
        topic: TutorialTopic.groupEvent,
        keyTarget: null, // 無 UI 綁定，顯示文字說明
        align: ContentAlign.center,
        content: "揪團功能 👥\n想找隊友一起爬山？\n點擊左上角選單 → 「揪團」\n可以發起或參加揪團活動！",
      ),
    );

    // ===== 完成畫面 (通用) =====
    allTargets.add(
      TutorialTarget(
        identify: "Target Complete",
        topic: TutorialTopic.all, // 完成畫面屬於 all，永遠顯示在最後
        keyTarget: null,
        align: ContentAlign.center,
        content: "教學完成 🎉\n恭喜你已熟悉所有功能\n點擊畫面開始你的旅程吧！",
      ),
    );

    // 根據 topic 過濾
    if (topic == null || topic == TutorialTopic.all) {
      return allTargets;
    } else {
      // 過濾特定主題，但保留完成畫面
      return allTargets.where((t) => t.topic == topic || t.topic == TutorialTopic.all).toList();
    }
  }

  /// 獲取下一個不同主題的索引
  ///
  /// 用於「跳過此主題」功能
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
