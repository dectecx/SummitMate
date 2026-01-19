import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/gear_item.dart';
import '../../../cubits/gear/gear_cubit.dart';

/// 刪除裝備確認對話框
///
/// 提供刪除裝備前的確認提示
class DeleteGearDialog extends StatelessWidget {
  final GearItem item;

  const DeleteGearDialog({super.key, required this.item});

  /// 顯示刪除確認對話框
  static Future<void> show(BuildContext context, GearItem item) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<GearCubit>(),
        child: DeleteGearDialog(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('確認刪除'),
      content: Text('確定要刪除「${item.name}」嗎？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<GearCubit>().deleteItem(item.key);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('刪除'),
        ),
      ],
    );
  }
}
