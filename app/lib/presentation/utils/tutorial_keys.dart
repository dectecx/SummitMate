import 'package:flutter/material.dart';

class TutorialKeys {
  // HomeScreen / MainNavigation
  static final mainSettings = GlobalKey();
  static final mainDrawerMenu = GlobalKey();

  // Settings Dialog
  static final settingsCopyId = GlobalKey();
  static final settingsClose = GlobalKey();

  // Drawer
  static final drawerManageTrips = GlobalKey();

  // Trip List
  static final tripListActiveMemberBtn = GlobalKey();

  // Member Management
  static final memberFab = GlobalKey();
  static final memberSearchInput = GlobalKey();
  static final memberSearchBtn = GlobalKey();
  static final memberConfirmBtn = GlobalKey();

  // Navigation Tabs
  static final tabItinerary = GlobalKey();
  static final tabGear = GlobalKey();
  static final tabMessage = GlobalKey();
  static final tabInfo = GlobalKey();

  // Itinerary Actions
  static final btnEdit = GlobalKey();
  static final btnUpload = GlobalKey();

  // Interaction Actions
  static final btnSync = GlobalKey();
  static final tabPolls = GlobalKey();

  // Info Actions
  static final infoElevation = GlobalKey();
  static final infoTimeMap = GlobalKey();
  static final expandedElevation = GlobalKey();
  static final expandedTimeMap = GlobalKey();
}
