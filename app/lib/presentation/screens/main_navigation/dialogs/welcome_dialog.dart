import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/infrastructure/tools/tutorial_service.dart';
import 'package:summitmate/presentation/screens/main_navigation/dialogs/trip_selection_dialog.dart';

class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(context: context, barrierDismissible: false, builder: (context) => const WelcomeDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('歡迎來到 SummitMate'),
      content: const Text('為了讓您快速上手，我們準備了簡易的教學引導。\n您想要現在觀看嗎？'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // 略過教學：標記完成
            context.read<SettingsCubit>().completeOnboarding();
          },
          child: const Text('直接開始 (略過)'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            // 進入教學 -> 結束後顯示匯入行程
            await TutorialService.start(topic: TutorialTopic.all);
            if (context.mounted) {
              // 教學結束後，自動跳出匯入選單
              TripSelectionDialog.show(context);
            }
          },
          child: const Text('教學引導'),
        ),
      ],
    );
  }
}
