import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/screens/main_navigation/dialogs/trip_selection_dialog.dart';

/// 初次登入歡迎對話框
///
/// 顯示歡迎訊息，提供快速導覽或直接開始。
class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(context: context, barrierDismissible: false, builder: (context) => const WelcomeDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('🏔️', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text('歡迎來到 SummitMate'),
        ],
      ),
      content: const Text(
        '為了讓您快速上手，我們準備了一個簡短的功能導覽。\n'
        '這只需要大約 30 秒，您隨時也可以在設定中重看。',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<SettingsCubit>().completeOnboarding();
            // 略過導覽後直接顯示匯入行程
            TripSelectionDialog.show(context);
          },
          child: const Text('略過'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            context.read<SettingsCubit>().completeOnboarding();
            // TODO: QuickTourSheet.show(context) 將在 Step 3 實作
            TripSelectionDialog.show(context);
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('快速導覽'),
        ),
      ],
    );
  }
}
