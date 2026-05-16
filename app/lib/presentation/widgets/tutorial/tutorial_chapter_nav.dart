import 'package:flutter/material.dart';
import '../../../domain/entities/tutorial_step.dart';

class TutorialChapterNav extends StatelessWidget {
  final TutorialChapter activeChapter;
  final ValueChanged<TutorialChapter> onChapterSelected;

  const TutorialChapterNav({super.key, required this.activeChapter, required this.onChapterSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: TutorialChapter.values.map((chapter) {
          final isSelected = chapter == activeChapter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text(chapter.emoji), const SizedBox(width: 4), Text(chapter.displayName)],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChapterSelected(chapter);
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
    );
  }
}
