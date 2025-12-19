import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialService {
  static List<TargetFocus> initTargets({
    required GlobalKey keyTabItinerary,
    required GlobalKey keyTabMessage,
    required GlobalKey keyTabGear,
    required GlobalKey keyTabInfo,
    required GlobalKey keyBtnEdit,
    required GlobalKey keyBtnSync,
  }) {
    List<TargetFocus> targets = [];

    // 1. 行程頁籤
    targets.add(
      TargetFocus(
        identify: "Target 1",
        keyTarget: keyTabItinerary,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "行程管理",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("這裡是您的登山行程表。\n可以查看每日計畫與高度圖。", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 2. 編輯按鈕
    targets.add(
      TargetFocus(
        identify: "Target 2",
        keyTarget: keyBtnEdit,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "編輯行程",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("點擊這裡可以開始規劃或修改您的行程。", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 3. 同步按鈕
    targets.add(
      TargetFocus(
        identify: "Target 3",
        keyTarget: keyBtnSync,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    "雲端同步",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("將您的資料備份到雲端，\n同時接收隊伍的最新更新。", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 4. 留言板頁籤 (需切換)
    targets.add(
      TargetFocus(
        identify: "Target 4",
        keyTarget: keyTabMessage,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "隊伍留言板",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("查看重要公告、隊伍閒聊與問題討論。", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 6. 裝備頁籤 (需切換)
    targets.add(
      TargetFocus(
        identify: "Target 6",
        keyTarget: keyTabGear,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "個人裝備",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("建立您的裝備檢查清單，\n自動計算重量，輕量化您的背包。", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 7. 資訊頁籤 (需切換)
    targets.add(
      TargetFocus(
        identify: "Target 7",
        keyTarget: keyTabInfo,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "離線資訊",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("查看離線地圖與步道詳情，\n無網路時也能使用。", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }
}
