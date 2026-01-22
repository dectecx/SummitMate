import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/core/theme.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';

class ThemeSelectionSheet extends StatelessWidget {
  const ThemeSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('選擇主題', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  AppThemeType currentTheme = AppThemeType.morandi;
                  if (state is SettingsLoaded) {
                    currentTheme = state.settings.theme;
                  }

                  return Column(
                    children: AppThemeType.values.map((type) {
                      final strategy = AppTheme.getStrategy(type);
                      final isSelected = currentTheme == type;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: strategy.themeData.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                          ),
                          child: type == AppThemeType.creative
                              ? Center(child: Icon(Icons.bolt, color: Colors.white, size: 20))
                              : null,
                        ),
                        title: Text(strategy.name),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32)) // Use safe green
                            : const Icon(Icons.circle_outlined, color: Colors.grey),
                        onTap: () {
                          context.read<SettingsCubit>().updateTheme(type);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
