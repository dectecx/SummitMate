import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/tutorial/tutorial_cubit.dart';
import '../../cubits/tutorial/tutorial_state.dart';
import 'package:summitmate/presentation/screens/main_navigation/dialogs/trip_selection_dialog.dart';

/// 快速導覽 BottomSheet
class QuickTourSheet extends StatelessWidget {
  const QuickTourSheet({super.key});

  /// 顯示快速導覽，並在開啟時切換到教學模式
  static void show(BuildContext context) {
    // 啟動教學模式 (Quick Tour)
    context.read<TutorialCubit>().startTutorial(chapterId: 'quick_tour', isQuickTour: true);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false, // 避免使用者不小心滑掉
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickTourSheet(),
    ).then((_) {
      // 關閉時結束教學模式
      if (context.mounted) {
         context.read<TutorialCubit>().endTutorial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TutorialCubit, TutorialState>(
      builder: (context, state) {
        if (state is! TutorialActive || !state.isQuickTour) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, state.currentStepIndex),
                  const SizedBox(height: 24),
                  _buildContent(context, state.currentStepIndex),
                  const SizedBox(height: 32),
                  _buildControls(context, state.currentStepIndex),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int stepIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '💡 快速導覽',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          '${stepIndex + 1} / 4',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, int stepIndex) {
    // TODO: 後續可抽離到 TutorialContent
    switch (stepIndex) {
      case 0:
        return const _TourCard(
          icon: Icons.map_outlined,
          title: '探索行程',
          description: '我們為您準備了一個「嘉明湖」的示範行程。\n您可以看到預排的路線、時間與距離資訊。',
        );
      case 1:
        return const _TourCard(
          icon: Icons.backpack_outlined,
          title: '準備裝備',
          description: '裝備清單已經自動幫您分類好，\n可以直接在上面勾選確認，並了解整體重量。',
        );
      case 2:
        return const _TourCard(
          icon: Icons.restaurant_menu_outlined,
          title: '糧食計畫',
          description: '按天數規劃您的三餐與行動糧，\n確保熱量充足且不會背得太重。',
        );
      case 3:
        return const _TourCard(
          icon: Icons.cloud_sync_outlined,
          title: '隨時同步',
          description: '一切準備就緒後，您的資料會自動同步，\n即使在山上沒有網路，也能離線查看。',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildControls(BuildContext context, int stepIndex) {
    final isLastStep = stepIndex == 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (stepIndex > 0)
          TextButton(
            onPressed: () => context.read<TutorialCubit>().previousStep(),
            child: const Text('上一步'),
          )
        else
          const SizedBox(width: 80), // 佔位
        
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                TripSelectionDialog.show(context);
              },
              child: const Text('略過'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (isLastStep) {
                  Navigator.pop(context); // 關閉 Sheet 會自動觸發 endTutorial
                  TripSelectionDialog.show(context); // 導覽結束後，顯示行程選擇
                } else {
                  context.read<TutorialCubit>().nextStep();
                }
              },
              child: Text(isLastStep ? '開始使用' : '下一步'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TourCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TourCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
