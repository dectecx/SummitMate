import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../../data/models/trip.dart';
import '../../cubits/trip/trip_cubit.dart';

/// 新增/編輯行程對話框
///
/// 提供行程名稱、開始/結束日期、備註等欄位的編輯功能。
/// 使用 [TripCubit] 來新增或更新行程資料。
class CreateTripDialog extends StatefulWidget {
  /// 要編輯的行程 (若為 null 則為新增模式)
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

  /// 是否為編輯模式
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colorScheme.surface,
      title: Text(isEditing ? '編輯行程' : '新增行程', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: '行程名稱',
                  hintText: '例如：2024 嘉明湖三日',
                  prefixIcon: const Icon(Icons.terrain),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入行程名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date Selection Row
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerField(
                      context,
                      label: '開始日期',
                      date: _startDate,
                      onTap: () => _selectDate(isStartDate: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePickerField(
                      context,
                      label: '結束日期',
                      date: _endDate,
                      placeholder: '單日',
                      isClearable: _endDate != null,
                      onTap: () => _selectDate(isStartDate: false),
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '備註 (選填)',
                  hintText: '行程描述或備忘',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50],
                ),
                maxLines: 3,
                minLines: 1,
              ),

              if (isEditing) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, size: 16, color: theme.hintColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trip ID', style: TextStyle(fontSize: 10, color: theme.hintColor)),
                            SelectableText(
                              widget.tripToEdit!.id,
                              style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? '儲存變更' : '建立行程'),
        ),
      ],
    );
  }

  /// 建立日期選擇欄位
  Widget _buildDatePickerField(
    BuildContext context, {
    required String label,
    DateTime? date,
    String? placeholder,
    bool isClearable = false,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? DateFormat('yyyy/MM/dd').format(date) : (placeholder ?? '-'),
                    style: TextStyle(
                      color: date != null ? colorScheme.onSurface : theme.hintColor,
                      fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isClearable && onClear != null)
                  InkWell(
                    onTap: onClear,
                    child: Icon(Icons.close, size: 16, color: theme.hintColor),
                  )
                else
                  Icon(Icons.calendar_today, size: 16, color: theme.hintColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 選擇日期
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

  /// 提交表單
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        final updatedTrip = Trip(
          id: widget.tripToEdit!.id,
          userId: widget.tripToEdit!.userId,
          name: _nameController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
          isActive: widget.tripToEdit!.isActive,
          createdAt: widget.tripToEdit!.createdAt,
          createdBy: widget.tripToEdit!.createdBy,
          updatedAt: widget.tripToEdit!.updatedAt,
          updatedBy: widget.tripToEdit!.updatedBy,
        );
        await context.read<TripCubit>().updateTrip(updatedTrip);
        if (mounted) {
          ToastService.success('行程已更新');
          Navigator.pop(context);
        }
      } else {
        await context.read<TripCubit>().addTrip(
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
