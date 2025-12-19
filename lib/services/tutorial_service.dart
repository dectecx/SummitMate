import 'package:flutter/material.dart';
import 'package:summitmate/presentation/widgets/tutorial_overlay.dart';

class TutorialService {
  static List<TutorialTarget> initTargets({
    required GlobalKey keyTabItinerary,
    required GlobalKey keyTabMessage,
    required GlobalKey keyTabGear,
    required GlobalKey keyTabInfo,
    required GlobalKey keyBtnEdit,
    required GlobalKey keyBtnUpload,
    required GlobalKey keyBtnSync,
    required GlobalKey keyInfoElevation,
    required GlobalKey keyInfoTimeMap,
    required Future<void> Function() onSwitchToItinerary,
    required Future<void> Function() onSwitchToMessage,
    required Future<void> Function() onSwitchToGear,
    required Future<void> Function() onSwitchToInfo,
    required Future<void> Function() onFocusUpload,
    required Future<void> Function() onFocusElevation,
    required Future<void> Function() onFocusTimeMap,
  }) {
    List<TutorialTarget> targets = [];

    // 1. 行程頁籤
    targets.add(
      TutorialTarget(
        identify: "Target Itinerary",
        keyTarget: keyTabItinerary,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "行程表 📅\n這是這次的行程安排\n隊友們隨時都可以查看喔",
        onFocus: onSwitchToItinerary,
      ),
    );

    // 2. 編輯按鈕
    targets.add(
      TutorialTarget(
        identify: "Target Edit",
        keyTarget: keyBtnEdit,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "編輯行程 ✏️\n想調整行程點這裡\n(📣建議由領隊統一維護)",
      ),
    );

    // 3. 上傳按鈕 (需先觸發編輯模式)
    targets.add(
      TutorialTarget(
        identify: "Target Upload",
        keyTarget: keyBtnUpload,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "上傳雲端 ☁️\n編輯完記得按這裡上傳\n(⚠️小心會把雲端原本的資料覆蓋掉)",
        onFocus: onFocusUpload,
      ),
    );

    // 4. 同步按鈕
    targets.add(
      TutorialTarget(
        identify: "Target Sync",
        keyTarget: keyBtnSync,
        alignSkip: Alignment.bottomLeft,
        align: ContentAlign.bottom,
        content: "同步更新 🔄\n把雲端最新的行程和留言抓下來\n(⚠️這也會覆蓋掉你手機裡的舊資料)",
      ),
    );

    // 5. 留言板頁籤
    targets.add(
      TutorialTarget(
        identify: "Target Message",
        keyTarget: keyTabMessage,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "留言板 💬\n有什麼話想對隊友說？\n提醒事項或裝備建議都可以在這留言",
        onFocus: onSwitchToMessage,
      ),
    );

    // 6. 裝備頁籤
    targets.add(
      TutorialTarget(
        identify: "Target Gear",
        keyTarget: keyTabGear,
        alignSkip: Alignment.topRight,
        align: ContentAlign.top,
        content: "裝備檢查 🎒\n把裝備和糧食都輸入進來\n幫你算好總重量，出發前檢查很方便",
        onFocus: onSwitchToGear,
      ),
    );

    // 7. 資訊頁籤
    targets.add(
      TutorialTarget(
        identify: "Target Info",
        keyTarget: keyTabInfo,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.top,
        content: "實用資訊 ℹ️\n這裡有一些好用的步道資訊\n像是天氣預報和入山證連結",
        onFocus: onSwitchToInfo,
      ),
    );

    // 8. 海拔高度圖 (需切換到資訊頁並展開)
    targets.add(
      TutorialTarget(
        identify: "Target Elevation",
        keyTarget: keyInfoElevation,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.bottom, // 上方有圖，顯示在下方比較安全
        content: "海拔高度 ⛰️\n想知道爬升多少？\n點一下這裡就會展開高度圖給你看",
        onFocus: onFocusElevation,
      ),
    );

    // 9. 路程時間圖 (需展開)
    targets.add(
      TutorialTarget(
        identify: "Target TimeMap",
        keyTarget: keyInfoTimeMap,
        alignSkip: Alignment.topLeft,
        align: ContentAlign.bottom,
        content: "路程時間 ⏱️\n還有路程時間圖\n點一下就能參考各路段要走多久",
        onFocus: onFocusTimeMap,
      ),
    );

    return targets;
  }
}
