import 'package:flutter/material.dart';
import '../../../domain/entities/tutorial_step.dart';

class TutorialChapterNav extends StatefulWidget {
  final TutorialChapter activeChapter;
  final ValueChanged<TutorialChapter> onChapterSelected;

  const TutorialChapterNav({super.key, required this.activeChapter, required this.onChapterSelected});

  @override
  State<TutorialChapterNav> createState() => _TutorialChapterNavState();
}

class _TutorialChapterNavState extends State<TutorialChapterNav> {
  final ScrollController _scrollController = ScrollController();
  final Map<TutorialChapter, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    for (final chapter in TutorialChapter.values) {
      _keys[chapter] = GlobalKey();
    }
    // Initial scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveChapter();
    });
  }

  @override
  void didUpdateWidget(TutorialChapterNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeChapter != widget.activeChapter) {
      _scrollToActiveChapter();
    }
  }

  void _scrollToActiveChapter() {
    final key = _keys[widget.activeChapter];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5, // Center the selected item
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64, // Provide a fixed height for the scroll area
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.05, 0.95, 1.0], // Fade at the edges (5% each side)
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: TutorialChapter.values.map((chapter) {
              final isSelected = chapter == widget.activeChapter;
              return Padding(
                key: _keys[chapter],
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(chapter.emoji), const SizedBox(width: 4), Text(chapter.displayName)],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      widget.onChapterSelected(chapter);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
