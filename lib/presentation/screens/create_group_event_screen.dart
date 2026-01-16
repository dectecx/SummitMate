import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubits/group_event/group_event_cubit.dart';
import '../../infrastructure/tools/toast_service.dart';

/// 建立揪團畫面
class CreateGroupEventScreen extends StatefulWidget {
  const CreateGroupEventScreen({super.key});

  @override
  State<CreateGroupEventScreen> createState() => _CreateGroupEventScreenState();
}

class _CreateGroupEventScreenState extends State<CreateGroupEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '6');
  final _privateMessageController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _endDate;
  bool _approvalRequired = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxMembersController.dispose();
    _privateMessageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : (_endDate ?? _startDate);
    final firstDate = isStart ? DateTime.now() : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if before start
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final cubit = context.read<GroupEventCubit>();
    final success = await cubit.createEvent(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      maxMembers: int.tryParse(_maxMembersController.text) ?? 6,
      approvalRequired: _approvalRequired,
      privateMessage: _privateMessageController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ToastService.success('揪團建立成功！');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('建立揪團'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('發布'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 活動名稱
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '活動名稱 *',
                hintText: '例如：嘉明湖三天兩夜',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入活動名稱';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 活動日期
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '開始日期 *', border: OutlineInputBorder()),
                      child: Text(DateFormat('yyyy/MM/dd').format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('~'),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: '結束日期', border: OutlineInputBorder()),
                      child: Text(_endDate != null ? DateFormat('yyyy/MM/dd').format(_endDate!) : '同日'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 地點
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: '地點', hintText: '例如：向陽登山口', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // 招募人數
            TextFormField(
              controller: _maxMembersController,
              decoration: const InputDecoration(labelText: '招募人數 *', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                final num = int.tryParse(value ?? '');
                if (num == null || num < 1) {
                  return '請輸入有效人數';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 活動說明
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '活動說明',
                hintText: '描述行程內容、難度、注意事項等...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // 進階設定
            Text('進階設定', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('需審核報名'),
                    subtitle: const Text('開啟後需手動審核報名申請'),
                    value: _approvalRequired,
                    onChanged: (value) => setState(() => _approvalRequired = value),
                  ),
                  if (_approvalRequired) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _privateMessageController,
                        decoration: const InputDecoration(
                          labelText: '報名成功訊息',
                          hintText: '審核通過後報名者才能看見此訊息 (例如：集合地點)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
