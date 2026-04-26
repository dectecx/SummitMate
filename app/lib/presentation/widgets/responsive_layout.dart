import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// 響應式佈局包裝器
/// 依據螢幕寬度自動切換 Mobile, Tablet, Desktop 視圖
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({super.key, required this.mobile, this.tablet, required this.desktop});

  /// 靜態方法用於在 build 中判斷目前裝置類型
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.mobile &&
      MediaQuery.of(context).size.width < AppBreakpoints.desktop;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.desktop) {
          return desktop;
        }
        if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return tablet ?? desktop; // 若未提供 tablet 則 fallback 至 desktop
        }
        return mobile;
      },
    );
  }
}
