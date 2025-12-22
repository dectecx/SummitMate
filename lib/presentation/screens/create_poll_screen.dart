import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/poll_provider.dart';
import '../../services/log_service.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];

  DateTime? _deadline;
  bool _allowMultipleVotes = false;
  bool _allowAddOption = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 options
    _addOption();
    _addOption();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('至少需要兩個選項')));
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (var c in _optionControllers) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 59));

      if (time != null && mounted) {
        setState(() {
          _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請設定截止時間')));
      return;
    }

    // Filter empty options
    final options = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('至少需要兩個有效選項')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<PollProvider>();
      await provider.createPoll(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        deadline: _deadline!,
        initialOptions: options,
        allowMultipleVotes: _allowMultipleVotes,
        isAllowAddOption: _allowAddOption,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('投票建立成功！')));
        Navigator.pop(context);
      }
    } catch (e) {
      LogService.error('Create poll failed: $e', source: 'CreatePollScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('建立失敗: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('發起投票')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '投票標題', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? '請輸入標題' : null,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: '描述 (選填)', border: OutlineInputBorder()),
              maxLines: 3,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),

            // Deadline
            ListTile(
              title: const Text('截止時間'),
              subtitle: Text(
                _deadline == null
                    ? '點擊設定'
                    : '${_deadline!.year}/${_deadline!.month}/${_deadline!.day} ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}',
              ),
              leading: const Icon(Icons.event),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: _isSubmitting ? null : _pickDate,
            ),
            const SizedBox(height: 16),

            // Settings
                  SwitchListTile(
                    title: const Text('允許新增'),
                    subtitle: const Text('允許其他成員新增選項'),
                    value: _allowAddOption,
                    onChanged: _isSubmitting ? null : (val) => setState(() => _allowAddOption = val),
                  ),
                  SwitchListTile(
                    title: const Text('多選'),
                    subtitle: const Text('允許成員選擇多個選項'),
                    value: _allowMultipleVotes,
                    onChanged: _isSubmitting ? null : (val) => setState(() => _allowMultipleVotes = val),
                  ),
            const Divider(),

            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('選項 (${_optionControllers.length})', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  onPressed: _isSubmitting ? null : _addOption,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '新增選項',
                ),
              ],
            ),
            ...List.generate(_optionControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: '選項 ${index + 1}',
                          prefixIcon: const Icon(Icons.circle_outlined, size: 16),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? '請輸入選項內容' : null,
                        enabled: !_isSubmitting,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: _isSubmitting ? null : () => _removeOption(index),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),

            // Submit
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: const Text('發佈投票'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
