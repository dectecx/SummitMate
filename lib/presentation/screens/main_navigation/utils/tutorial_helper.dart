import 'package:flutter/material.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'package:summitmate/presentation/screens/trip_list_screen.dart';

class MainNavigationTutorialHelper {
  static void showTutorial({
    required BuildContext context,
    required TutorialTopic topic,
    required Function(int) onTabSwitch,
    required GlobalKey<ScaffoldState> scaffoldKey,
  }) {
    TutorialService.start(
      topic: topic,
      // 1. Navigation Tabs
      onSwitchToItinerary: () async {
        onTabSwitch(0);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onSwitchToGear: () async {
        onTabSwitch(1);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onSwitchToMessage: () async {
        onTabSwitch(2);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onSwitchToInfo: () async {
        onTabSwitch(3);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      // 2. Drawer / Settings
      onFocusDrawer: () async {
        scaffoldKey.currentState?.openDrawer();
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onFocusSettings: () async {
        await Future.delayed(const Duration(milliseconds: 300));
      },
      // 3. Actions that might need context or state
      onFocusUpload: () async {
        onTabSwitch(0);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onFocusSync: () async {
        // Message Tab usually has Sync
        onTabSwitch(2);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      // 4. Member Management Flow
      onFocusManageTrips: () async {
        scaffoldKey.currentState?.openDrawer();
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onFocusTripListMember: () async {
        Navigator.pop(context); // Close Drawer
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripListScreen()));
        await Future.delayed(const Duration(milliseconds: 300));
      },
      onFocusMemberFab: () async {
        await Future.delayed(const Duration(milliseconds: 300));
      },
    );
  }
}
