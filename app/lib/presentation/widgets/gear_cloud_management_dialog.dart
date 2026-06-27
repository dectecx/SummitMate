import 'package:flutter/material.dart';
import '../../core/error/result.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import 'package:summitmate/presentation/widgets/gear_preview_dialog.dart';
import 'package:summitmate/presentation/widgets/buttons/summit_destructive_button.dart';

class GearCloudManagementDialog extends StatefulWidget {
  final IGearSetRepository repository;
  final List<GearItem> currentItems;
  final List<DailyMealPlan> currentMeals;
  final String username;
  final Function(List<GearItem>) onImport;
  final Function(List<GearItem>) onAddToLibrary;
  final Function(List<DailyMealPlan>) onImportMeals;

  const GearCloudManagementDialog({
    super.key,
    required this.repository,
    required this.currentItems,
    required this.currentMeals,
    required this.username,
    required this.onImport,
    required this.onAddToLibrary,
    required this.onImportMeals,
  });

  @override
  State<GearCloudManagementDialog> createState() => _GearCloudManagementDialogState();
}

class _GearCloudManagementDialogState extends State<GearCloudManagementDialog> {
  List<GearSet> _mySets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMySets();
  }

  Future<void> _fetchMySets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.repository.getGearSets(myUploadedOnly: true);

    if (!mounted) return;

    if (result is Success<List<GearSet>, Exception>) {
      setState(() {
        _mySets = result.value;
        _isLoading = false;
      });
    } else if (result is Failure<List<GearSet>, Exception>) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.exception.toString();
      });
    }
  }

  Future<void> _onOverwrite(GearSet gearSet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 確認覆蓋'),
        content: Text('確定要將目前的裝備與糧食計畫上傳並覆蓋「${gearSet.title}」嗎？\n此操作將會完全取代雲端原有的內容。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('確認覆蓋')),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await widget.repository.updateGearSet(
      id: gearSet.id,
      title: gearSet.title,
      author: widget.username,
      visibility: gearSet.visibility,
      items: widget.currentItems,
      meals: widget.currentMeals,
      key: null, // Keep existing key if not changed, or we might need a way to pass it
    );

    if (result is Success<GearSet, Exception>) {
      ToastService.success('覆蓋成功');
      _fetchMySets();
    } else if (result is Failure<GearSet, Exception>) {
      ToastService.error(result.exception.toString());
    }
  }

  Future<void> _onEditKey(GearSet gearSet) async {
    final controller = TextEditingController();
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('修改 4 位數 Key'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(hintText: '____', counterText: '', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('儲存')),
          ],
        ),
      );

      if (result != null && result.length == 4) {
        final updateResult = await widget.repository.updateGearSet(
          id: gearSet.id,
          title: gearSet.title,
          author: gearSet.author,
          visibility: GearSetVisibility.protected,
          items: gearSet.items ?? [],
          meals: gearSet.meals,
          key: result,
        );

        if (updateResult is Success<GearSet, Exception>) {
          ToastService.success('Key 已修改');
          _fetchMySets();
        } else if (updateResult is Failure<GearSet, Exception>) {
          ToastService.error(updateResult.exception.toString());
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _onDownload(GearSet gearSet) async {
    final result = await widget.repository.downloadGearSet(gearSet.id);
    if (result is Success<GearSet, Exception>) {
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => GearPreviewDialog(
            gearSet: result.value,
            onAddToLibrary: (items) async {
              widget.onAddToLibrary(items);
            },
          ),
        );

        if (confirmed == true && mounted) {
          final items = result.value.items ?? [];
          widget.onImport(items);
          if (result.value.meals != null && result.value.meals!.isNotEmpty) {
            widget.onImportMeals(result.value.meals!);
          }
          Navigator.pop(context); // Close management dialog too
        }
      }
    }
  }

  Future<void> _onDelete(GearSet gearSet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 確認刪除'),
        content: Text('確定要從雲端刪除「${gearSet.title}」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          SummitDestructiveButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await widget.repository.deleteGearSet(gearSet.id);
      if (result is Success<bool, Exception>) {
        ToastService.success('已刪除');
        _fetchMySets();
      } else {
        ToastService.error('刪除失敗');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📦 管理我的雲端裝備與糧食'),
      content: SizedBox(width: 600, height: 400, child: _buildBody()),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉'))],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_mySets.isEmpty) {
      return const Center(
        child: Text('目前沒有任何雲端備份', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _mySets.length,
      itemBuilder: (context, index) {
        final gs = _mySets[index];
        return Card(
          child: ListTile(
            leading: Text(gs.visibilityIcon, style: const TextStyle(fontSize: 24)),
            title: Text(gs.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('最後更新: ${gs.updatedAt.toString().split('.')[0]}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'overwrite':
                    _onOverwrite(gs);
                    break;
                  case 'download':
                    _onDownload(gs);
                    break;
                  case 'edit_key':
                    _onEditKey(gs);
                    break;
                  case 'delete':
                    _onDelete(gs);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'overwrite',
                  child: Row(children: [Icon(Icons.upload, size: 18), SizedBox(width: 8), Text('上傳至此 (覆蓋)')]),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(children: [Icon(Icons.download, size: 18), SizedBox(width: 8), Text('下載此筆')]),
                ),
                const PopupMenuItem(
                  value: 'edit_key',
                  child: Row(children: [Icon(Icons.key, size: 18), SizedBox(width: 8), Text('修改 Key')]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('刪除', style: TextStyle(color: Colors.red)),
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
}
