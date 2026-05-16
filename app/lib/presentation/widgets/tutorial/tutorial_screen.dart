import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/tutorial_step.dart';
import '../../../infrastructure/tools/tutorial_content.dart';
import '../../cubits/tutorial/tutorial_cubit.dart';
import '../../cubits/tutorial/tutorial_state.dart';
import 'tutorial_step_card.dart';
import 'tutorial_chapter_nav.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(
      context,
    ).push(PageRouteBuilder(opaque: false, pageBuilder: (context, _, __) => const TutorialScreen()));
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  TutorialChapter _currentChapter = TutorialChapter.itinerary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutorialCubit>().startTutorial(chapterId: _currentChapter.name);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onChapterSelected(TutorialChapter chapter) {
    setState(() {
      _currentChapter = chapter;
    });
    context.read<TutorialCubit>().startTutorial(chapterId: chapter.name);
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TutorialCubit, TutorialState>(
      listenWhen: (previous, current) => current is TutorialInitial || current is TutorialActive,
      listener: (context, state) {
        if (state is TutorialInitial && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state is! TutorialActive || state.isQuickTour) {
          return const Scaffold(backgroundColor: Colors.transparent);
        }

        final steps = TutorialContent.stepsForChapter(_currentChapter);

        // Listen to TutorialCubit step changes to animate PageView
        if (_pageController.hasClients) {
          final page = _pageController.page?.round() ?? 0;
          if (page != state.currentStepIndex) {
            _pageController.animateToPage(
              state.currentStepIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }

        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.4), // Semi-transparent background
          body: SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            '互動教學',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              context.read<TutorialCubit>().endTutorial();
                            },
                          ),
                        ],
                      ),
                      TutorialChapterNav(activeChapter: _currentChapter, onChapterSelected: _onChapterSelected),
                    ],
                  ),
                ),

                // Spacer to allow user to see the mock data behind, plus optional mock overlays
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Stack(
                      children: [
                        Container(color: Colors.transparent),
                        Positioned.fill(child: _buildMockOverlay(context, state)),
                      ],
                    ),
                  ),
                ),

                // Tutorial Cards (Steps)
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: steps.length,
                    onPageChanged: (index) {
                      context.read<TutorialCubit>().goToStep(index);
                    },
                    itemBuilder: (context, index) {
                      return TutorialStepCard(step: steps[index]);
                    },
                  ),
                ),

                // Card Controls
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                    border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (state.currentStepIndex > 0)
                        ElevatedButton.icon(
                          onPressed: () => context.read<TutorialCubit>().previousStep(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('上一步'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                          ),
                        )
                      else
                        const SizedBox(width: 110),

                      // Page Indicators
                      Row(
                        children: List.generate(
                          steps.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == state.currentStepIndex ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == state.currentStepIndex
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      if (state.currentStepIndex < steps.length - 1)
                        FilledButton.icon(
                          onPressed: () => context.read<TutorialCubit>().nextStep(),
                          label: const Text('下一步'),
                          icon: const Icon(Icons.arrow_forward),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () {
                            // Find next chapter index
                            final chapters = TutorialChapter.values;
                            final currentIndex = chapters.indexOf(_currentChapter);
                            if (currentIndex < chapters.length - 1) {
                              _onChapterSelected(chapters[currentIndex + 1]);
                            } else {
                              context.read<TutorialCubit>().endTutorial();
                            }
                          },
                          label: Text(_currentChapter == TutorialChapter.values.last ? '完成' : '下一章'),
                          icon: Icon(
                            _currentChapter == TutorialChapter.values.last ? Icons.check : Icons.arrow_forward,
                          ),
                          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 根據當前的教學章節與步驟，繪製假的對應畫面（Mock UI Overlay）
  Widget _buildMockOverlay(BuildContext context, TutorialActive state) {
    if (state.isQuickTour) return const SizedBox.shrink();

    final chapter = state.chapterId;
    final step = state.currentStepIndex;

    Widget? overlayContent;

    if (chapter == 'itinerary' && step == 2) {
      // 你的帳號 ID
      overlayContent = _buildMockDialog(
        context,
        title: '設定',
        icon: Icons.settings,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withAlpha(50), shape: BoxShape.circle),
                child: const Text('🐻', style: TextStyle(fontSize: 32)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: '暱稱',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            enabled: false,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.fingerprint, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ID: tutorial-mock-user-1234',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
                ),
              ),
              IconButton(icon: const Icon(Icons.copy, size: 16, color: Colors.grey), onPressed: () {}),
            ],
          ),
        ],
      );
    } else if (chapter == 'itinerary' && step == 3) {
      // 管理成員
      overlayContent = _buildMockDialog(
        context,
        title: '管理成員',
        icon: Icons.people,
        children: [
          const ListTile(
            leading: CircleAvatar(child: Text('🐻')),
            title: Text('你'),
            subtitle: Text('領隊'),
            trailing: Icon(Icons.more_vert),
          ),
          ListTile(
            leading: const CircleAvatar(child: Text('🦊')),
            title: const Text('山友 A'),
            subtitle: const Text('隊員'),
            trailing: OutlinedButton(onPressed: () {}, child: const Text('設定')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add),
              label: const Text('邀請新成員'),
            ),
          ),
        ],
      );
    } else if (chapter == 'groupEvent' && step == 1) {
      // 發起活動
      overlayContent = _buildMockDialog(
        context,
        title: '發布為公開活動',
        icon: Icons.public,
        children: [
          const TextField(
            decoration: InputDecoration(labelText: '活動名稱', hintText: '週末郊山輕鬆走', border: OutlineInputBorder()),
            enabled: false,
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: '活動對象', hintText: '所有山友', border: OutlineInputBorder()),
            enabled: false,
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: '人數上限', hintText: '10', border: OutlineInputBorder()),
            enabled: false,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () {}, child: const Text('確認發布')),
          ),
        ],
      );
    } else if (chapter == 'cloud' && step == 1) {
      // 離線模式
      overlayContent = _buildMockDialog(
        context,
        title: '設定',
        icon: Icons.settings,
        children: [
          SwitchListTile(
            title: const Text('離線模式', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('暫停所有自動連線與同步，以節省電力。'),
            value: true,
            onChanged: (v) {},
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('清除所有本地資料', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }

    if (overlayContent == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
        ),
        child: overlayContent,
      ),
    );
  }

  Widget _buildMockDialog(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.close, size: 20, color: Colors.grey),
          ],
        ),
        const Divider(height: 24),
        ...children,
      ],
    );
  }
}
