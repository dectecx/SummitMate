import 'package:flutter/material.dart';

/// 裝備列表檢視模式
enum GearListMode { view, edit, sort }

/// 裝備模式切換器
///
/// 允許使用者在檢視、編輯、排序模式間切換
class GearModeSelector extends StatelessWidget {
  /// 當前選中的模式
  final GearListMode selectedMode;

  /// 模式變更回調函數
  final ValueChanged<GearListMode> onModeChanged;

  const GearModeSelector({super.key, required this.selectedMode, required this.onModeChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<GearListMode>(
          segments: const [
            ButtonSegment(value: GearListMode.view, icon: Icon(Icons.visibility_outlined), label: Text('檢視')),
            ButtonSegment(value: GearListMode.edit, icon: Icon(Icons.edit_outlined), label: Text('編輯')),
            ButtonSegment(value: GearListMode.sort, icon: Icon(Icons.sort), label: Text('排序')),
          ],
          selected: {selectedMode},
          onSelectionChanged: (Set<GearListMode> newSelection) {
            onModeChanged(newSelection.first);
          },
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
