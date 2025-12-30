import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../../data/models/trip.dart';
import '../../services/toast_service.dart';
import 'trip_cloud_screen.dart';

/// 行程列表畫面
/// 管理多個登山計畫
class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的行程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripCloudScreen())),
            tooltip: '雲端同步',
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateTripDialog(context), tooltip: '新增行程'),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hiking, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('尚無行程', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTripDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('新增行程'),
                  ),
                ],
              ),
            );
          }

          final allTrips = provider.trips;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final ongoingTrips = allTrips.where((t) {
            if (t.endDate == null) return true;
            return !t.endDate!.isBefore(today);
          }).toList();

          final archivedTrips = allTrips.where((t) {
            if (t.endDate == null) return false;
            return t.endDate!.isBefore(today);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 進行中行程
              if (ongoingTrips.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '進行中 / 未來行程',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...ongoingTrips.map(
                  (trip) => _TripCard(
                    trip: trip,
                    isActive: trip.id == provider.activeTripId,
                    onTap: () => _onTripTap(context, provider, trip),
                    onDelete: provider.trips.length > 1 ? () => _confirmDelete(context, provider, trip) : null,
                  ),
                ),
              ],

              // 已封存行程
              if (archivedTrips.isNotEmpty) ...[
                if (ongoingTrips.isNotEmpty) const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '已封存 / 結束行程',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
                ...archivedTrips.map(
                  (trip) => _TripCard(
                    trip: trip,
                    isActive: trip.id == provider.activeTripId,
                    onTap: () => _onTripTap(context, provider, trip),
                    onDelete: provider.trips.length > 1 ? () => _confirmDelete(context, provider, trip) : null,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTripDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTripDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const CreateTripDialog());
  }

  void _onTripTap(BuildContext context, TripProvider provider, Trip trip) async {
    if (trip.id != provider.activeTripId) {
      await provider.setActiveTrip(trip.id);
      if (context.mounted) {
        ToastService.success('已切換到「${trip.name}」');
        Navigator.pop(context); // 返回首頁
      }
    } else {
      // 編輯行程
      _showEditTripDialog(context, trip);
    }
  }

  void _showEditTripDialog(BuildContext context, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => CreateTripDialog(tripToEdit: trip),
    );
  }

  void _confirmDelete(BuildContext context, TripProvider provider, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除行程'),
        content: Text('確定要刪除「${trip.name}」嗎？\n此操作無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteTrip(trip.id);
              if (success) {
                ToastService.success('已刪除「${trip.name}」');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }
}

/// 行程卡片 Widget
class _TripCard extends StatelessWidget {
  final Trip trip;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _TripCard({required this.trip, required this.isActive, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final dateText = trip.endDate != null
        ? '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate!)}'
        : dateFormat.format(trip.startDate);

    return Card(
      elevation: isActive ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 封面圖或圖示
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isActive ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.terrain,
                  size: 32,
                  color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              // 行程資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '當前',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateText, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    if (trip.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        trip.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              // 刪除按鈕
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[300],
                  onPressed: onDelete,
                  tooltip: '刪除行程',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 新增/編輯行程對話框
class CreateTripDialog extends StatefulWidget {
  final Trip? tripToEdit;

  const CreateTripDialog({super.key, this.tripToEdit});

  @override
  State<CreateTripDialog> createState() => _CreateTripDialogState();
}

class _CreateTripDialogState extends State<CreateTripDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  bool get isEditing => widget.tripToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tripToEdit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.tripToEdit?.description ?? '');
    _startDate = widget.tripToEdit?.startDate ?? DateTime.now();
    _endDate = widget.tripToEdit?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? '編輯行程' : '新增行程'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '行程名稱',
                  hintText: '例如：2024 嘉明湖三日',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入行程名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 開始日期
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('開始日期'),
                subtitle: Text(DateFormat('yyyy/MM/dd').format(_startDate)),
                onTap: () => _selectDate(isStartDate: true),
              ),
              // 結束日期
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('結束日期'),
                subtitle: Text(_endDate != null ? DateFormat('yyyy/MM/dd').format(_endDate!) : '未設定 (單日行程)'),
                trailing: _endDate != null
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _endDate = null))
                    : null,
                onTap: () => _selectDate(isStartDate: false),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '備註 (選填)',
                  hintText: '行程描述或備忘',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? '儲存' : '建立'),
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _startDate : (_endDate ?? _startDate);
    final firstDate = isStartDate ? DateTime(2020) : _startDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // 如果結束日期早於開始日期，清除它
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<TripProvider>();

    try {
      if (isEditing) {
        final updatedTrip = Trip(
          id: widget.tripToEdit!.id,
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          isActive: widget.tripToEdit!.isActive,
          createdAt: widget.tripToEdit!.createdAt,
        );
        await provider.updateTrip(updatedTrip);
        if (mounted) {
          ToastService.success('行程已更新');
          Navigator.pop(context);
        }
      } else {
        await provider.addTrip(
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        );
        if (mounted) {
          ToastService.success('行程已建立');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ToastService.error('操作失敗：$e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
