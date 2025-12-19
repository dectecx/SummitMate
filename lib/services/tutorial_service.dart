import 'package:flutter/material.dart';
import 'package:summitmate/presentation/widgets/tutorial_overlay.dart';

class TutorialService {
  static List<TutorialTarget> initTargets({
    required GlobalKey keyTabItinerary,
    required GlobalKey keyTabMessage,
    required GlobalKey keyTabGear,
    required GlobalKey keyTabInfo,
    required GlobalKey keyBtnEdit,
    required GlobalKey keyBtnSync,
    required Future<void> Function() onSwitchToItinerary,
    required Future<void> Function() onSwitchToMessage,
    required Future<void> Function() onSwitchToGear,
    required Future<void> Function() onSwitchToInfo,
  }) {
    List<TutorialTarget> targets = [];

    // 1. 行程頁籤
    targets.add(
      TutorialTarget(
        identify: "Target 1",
        keyTarget: keyTabItinerary,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "這是您的行程表\n安排登山計畫的核心",
        onFocus: onSwitchToItinerary,
      ),
    );

    // 2. 編輯按鈕
    targets.add(
      TutorialTarget(
        identify: "Target 2",
        keyTarget: keyBtnEdit,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "點擊筆形圖示\n開啟編輯模式以新增行程",
      ),
    );

    // 3. 同步按鈕
    targets.add(
      TutorialTarget(
        identify: "Target 3",
        keyTarget: keyBtnSync,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "雲端同步按鈕\n備份您的重要資料",
      ),
    );

    // 4. 留言板頁籤 (需切換)
    targets.add(
      TutorialTarget(
        identify: "Target 4",
        keyTarget: keyTabMessage,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "團隊留言板\n與隊友交流資訊",
        onFocus: onSwitchToMessage,
      ),
    );

    // 5. 分類篩選 (Target 5 已移除)

    // 6. 裝備頁籤 (需切換)
    targets.add(
      TutorialTarget(
        identify: "Target 6",
        keyTarget: keyTabGear,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "裝備清單\n管理您的登山裝備與重量",
        onFocus: onSwitchToGear,
      ),
    );

    // 7. 資訊頁籤 (需切換)
    targets.add(
      TutorialTarget(
        identify: "Target 7",
        keyTarget: keyTabInfo,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.top,
        content: "步道資訊整合\n天氣、路況與入山證",
        onFocus: onSwitchToInfo,
      ),
    );

    return targets;
  }
}
