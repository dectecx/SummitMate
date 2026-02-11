import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';

class SummitAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;
  final double? elevation;

  const SummitAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle,
    this.elevation,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final themeType = settingsState is SettingsLoaded ? settingsState.settings.theme : AppThemeType.nature;

    final strategy = AppTheme.getStrategy(themeType);

    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      bottom: bottom,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: elevation ?? 0,
      scrolledUnderElevation: elevation ?? 0, // Prevent Material 3 color change on scroll
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          gradient: strategy.appBarGradient,
        ),
      ),
    );
  }
}
