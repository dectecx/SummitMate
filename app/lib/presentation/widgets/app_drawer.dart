import 'package:flutter/material.dart';
import 'app_drawer_content.dart';

/// 應用程式側邊欄 (Drawer) - 薄包裝器，用於 Mobile/Tablet
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      backgroundColor: Colors.transparent,
      child: AppDrawerContent(isSidebar: false),
    );
  }
}
