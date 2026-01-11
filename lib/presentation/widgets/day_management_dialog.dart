import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/itinerary/itinerary_cubit.dart';
import '../cubits/itinerary/itinerary_state.dart';
import '../../infrastructure/tools/toast_service.dart';

class DayManagementDialog extends StatefulWidget {
  const DayManagementDialog({super.key});

  @override
  State<DayManagementDialog> createState() => _DayManagementDialogState();
}

class _DayManagementDialogState extends State<DayManagementDialog> {
  // Local state for reordering to avoid flickering and rebuilds during drag
  List<String> _localDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final state = context.read<ItineraryCubit>().state;
    if (state is ItineraryLoaded) {
      _localDays = List.from(state.dayNames);
    }
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    // We use BlocListener only for error handling or external events if needed,
    // but for reordering, we rely on local state to prevent UI freeze/lag.
    return BlocListener<ItineraryCubit, ItineraryState>(
      listener: (context, state) {
        if (state is ItineraryError) {
          ToastService.error(state.message);
        }
      },
      child: AlertDialog(
        title: const Text('管理行程天數'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const Text('長按拖曳可調整順序', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ReorderableListView(
                        onReorder: _onReorder,
                        children: [
                          for (int i = 0; i < _localDays.length; i++)
                            ListTile(
                              key: ValueKey(_localDays[i]),
                              leading: const Icon(Icons.drag_handle, color: Colors.grey),
                              title: Text(_localDays[i]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showRenameDialog(context, i),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _confirmDelete(context, i),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.blue),
                      title: const Text('新增天數', style: TextStyle(color: Colors.blue)),
                      onTap: () => _showAddDialog(context),
                    ),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉'))],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _localDays.removeAt(oldIndex);
      _localDays.insert(newIndex, item);
    });

    // Save to Cubit (Fire and forget, or await without rebuilding UI dependency)
    await context.read<ItineraryCubit>().reorderDays(_localDays);
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增天數'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '名稱', hintText: 'e.g. D3, 撤退日'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('新增')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      if (_localDays.contains(result)) {
        ToastService.error('名稱已存在');
        return;
      }

      setState(() {
        _localDays.add(result);
      });

      await context.read<ItineraryCubit>().addDay(result);
    }
  }

  Future<void> _showRenameDialog(BuildContext context, int index) async {
    final oldName = _localDays[index];
    final controller = TextEditingController(text: oldName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重新命名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '名稱'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('確定')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != oldName && mounted) {
      if (_localDays.contains(result)) {
        ToastService.error('名稱已存在');
        return;
      }

      setState(() {
        _localDays[index] = result;
      });

      await context.read<ItineraryCubit>().renameDay(oldName, result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final name = _localDays[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除天數'),
        content: Text('確定要刪除 "$name" 嗎？\n請確認該天已無行程項目，否則無法刪除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // 樂觀更新 (Optimistic Update): 先從本地列表移除以提供即時的 UI 回饋。
      // 接著呼叫 Cubit 執行實際刪除。
      // 若刪除失敗 (例如該天數下仍有行程)，Cubit 會拋出錯誤，
      // 此時 catch 區塊會捕捉錯誤並呼叫 _initData() 還原本地列表。
      setState(() {
        _localDays.removeAt(index);
      });

      try {
        await context.read<ItineraryCubit>().removeDay(name);
      } catch (e) {
        // 發生錯誤時還原資料
        _initData();
        setState(() {});
      }
    }
  }
}
