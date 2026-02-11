import 'package:flutter/material.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'tutorial_overlay.dart';

/// 全域教學遮罩包裹器
///
/// 用於包裹 MaterialApp 的內容，確保教學遮罩 (TutorialOverlay)
/// 始終位於最上層，且不影響底層路由導航。
class GlobalTutorialWrapper extends StatelessWidget {
  final Widget child;

  const GlobalTutorialWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<List<TutorialTarget>?>(
          valueListenable: TutorialService.tutorialState,
          builder: (context, targets, _) {
            if (targets == null || targets.isEmpty) {
              return const SizedBox.shrink();
            }

            return Material(
              color: Colors.transparent,
              child: TutorialOverlay(
                targets: targets,
                onFinish: TutorialService.stop,
                onSkip: TutorialService.stop,
                // 暫時將 Skip Topic 行為設定為結束教學，直到 TutorialOverlay 支援外部索引控制
                showSkipTopic: true,
                onSkipTopic: (_) => TutorialService.stop(),
              ),
            );
          },
        ),
      ],
    );
  }
}
