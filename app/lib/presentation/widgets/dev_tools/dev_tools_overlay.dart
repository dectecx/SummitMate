import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/core/di/injection.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/gear/gear_cubit.dart';
import 'package:summitmate/presentation/cubits/meal/meal_cubit.dart';
import 'package:summitmate/presentation/cubits/poll/poll_cubit.dart';
import 'package:summitmate/infrastructure/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:summitmate/app.dart';
import 'dart:math';

class DevToolsOverlay extends StatelessWidget {
  final Widget child;
  const DevToolsOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(builder: (context) => child),
        OverlayEntry(builder: (context) => const _DevToolsFloatingButton()),
      ],
    );
  }
}

class _DevToolsFloatingButton extends StatefulWidget {
  const _DevToolsFloatingButton();

  @override
  State<_DevToolsFloatingButton> createState() => _DevToolsFloatingButtonState();
}

class _DevToolsFloatingButtonState extends State<_DevToolsFloatingButton> {
  Offset position = const Offset(0, 100);
  bool isDragging = false;
  static bool _isPanelOpen = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: isDragging ? Duration.zero : const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        onPanEnd: (details) {
          setState(() {
            isDragging = false;
          });
          final size = MediaQuery.of(context).size;
          double targetX = position.dx + details.velocity.pixelsPerSecond.dx * 0.15;
          double targetY = position.dy + details.velocity.pixelsPerSecond.dy * 0.15;

          targetX = targetX > size.width / 2 ? size.width - 56 : 0;
          targetY = targetY.clamp(0.0, size.height - 100);

          setState(() {
            position = Offset(targetX, targetY);
          });
        },
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () async {
          if (_isPanelOpen) return;
          final navContext = SummitMateApp.navigatorKey.currentContext;
          if (navContext != null) {
            _isPanelOpen = true;
            await showModalBottomSheet(
              context: navContext,
              isScrollControlled: true,
              builder: (ctx) => const DevPanelContent(),
            );
            _isPanelOpen = false;
          }
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: const Icon(Icons.developer_mode, color: Colors.white),
        ),
      ),
    );
  }
}

class DevPanelContent extends StatelessWidget {
  const DevPanelContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('開發者工具', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  const Text('快速登入/切換帳號', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAccountButton(context, 'dev1@test.com', 'Dev 1'),
                      _buildAccountButton(context, 'dev2@test.com', 'Dev 2'),
                      _buildAccountButton(context, 'dev3@test.com', 'Dev 3'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('快速新增假資料', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.backpack),
                    label: const Text('新增隨機裝備'),
                    onPressed: () => _addRandomGear(context),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restaurant),
                    label: const Text('新增隨機糧食計畫 (全天)'),
                    onPressed: () => _addRandomMeals(context),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.poll),
                    label: const Text('建立隨機投票'),
                    onPressed: () => _createRandomPoll(context),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('資料庫工具', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.storage),
                    label: const Text('Drift 資料表檢視器'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DriftViewerScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountButton(BuildContext context, String email, String name) {
    return ActionChip(
      avatar: const Icon(Icons.person),
      label: Text(name),
      onPressed: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );
        try {
          final authCubit = context.read<AuthCubit>();
          await authCubit.logout(); // Use AuthCubit to ensure app-wide state changes

          // Reset relevant local Cubit states explicitly
          context.read<MealCubit>().reset();
          context.read<GearCubit>().reset();
          context.read<PollCubit>().reset();

          final authService = getIt<IAuthService>();
          var result = await authService.login(email: email, password: 'password123');
          if (!result.isSuccess) {
            await authService.register(email: email, password: 'password123', displayName: name);
            await authService.login(email: email, password: 'password123');
          }
        } finally {
          Navigator.pop(context); // pop loading
          if (context.mounted) Navigator.pop(context); // pop dev panel
        }
      },
    );
  }

  void _addRandomGear(BuildContext context) {
    final gearCubit = context.read<GearCubit>();
    if (gearCubit.currentTripId != null) {
      final random = Random();
      final categories = ['Sleep', 'Cook', 'Wear', 'Other'];
      gearCubit.addItem(
        name: '測試裝備 ${random.nextInt(1000)}',
        weight: random.nextDouble() * 1000,
        category: categories[random.nextInt(categories.length)],
        quantity: random.nextInt(3) + 1,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已新增隨機裝備')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先進入包含裝備頁面的行程')));
    }
  }

  void _addRandomMeals(BuildContext context) {
    final mealCubit = context.read<MealCubit>();
    final random = Random();
    final days = ['D0', 'D1', 'D2', 'D3'];
    final day = days[random.nextInt(days.length)];
    mealCubit.addMealItem(day, MealType.preBreakfast, '測試早早餐 ${random.nextInt(100)}', 150, 400);
    mealCubit.addMealItem(day, MealType.breakfast, '測試早餐 ${random.nextInt(100)}', 200, 500);
    mealCubit.addMealItem(day, MealType.lunch, '測試午餐 ${random.nextInt(100)}', 300, 600);
    mealCubit.addMealItem(day, MealType.dinner, '測試晚餐 ${random.nextInt(100)}', 400, 800);
    mealCubit.addMealItem(day, MealType.action, '測試行動糧 ${random.nextInt(100)}', 100, 300);
    mealCubit.addMealItem(day, MealType.emergency, '測試緊急糧 ${random.nextInt(100)}', 100, 300);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已在 $day 新增隨機完整餐食')));
  }

  void _createRandomPoll(BuildContext context) {
    final pollCubit = context.read<PollCubit>();
    final random = Random();
    pollCubit.createPoll(title: '測試投票 ${random.nextInt(1000)}', initialOptions: ['選項 A', '選項 B', '選項 C']).then((
      success,
    ) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已建立隨機投票')));
      }
    });
  }
}

class DriftViewerScreen extends StatefulWidget {
  const DriftViewerScreen({super.key});

  @override
  State<DriftViewerScreen> createState() => _DriftViewerScreenState();
}

class _DriftViewerScreenState extends State<DriftViewerScreen> {
  final db = getIt<AppDatabase>();
  List<drift.TableInfo> get _tables => db.allTables.toList();
  drift.TableInfo? _selectedTable;
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_tables.isNotEmpty) {
      _selectedTable = _tables.first;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_selectedTable == null) return;
    setState(() => _isLoading = true);
    try {
      final results = await db.customSelect('SELECT * FROM ${_selectedTable!.actualTableName} LIMIT 100').get();
      setState(() {
        _data = results.map((row) => row.data).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('載入失敗: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drift 資料表檢視器')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<drift.TableInfo>(
              value: _selectedTable,
              items: _tables.map((t) => DropdownMenuItem(value: t, child: Text(t.actualTableName))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedTable = val;
                });
                _loadData();
              },
              decoration: const InputDecoration(labelText: '選擇資料表', border: OutlineInputBorder()),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                ? const Center(child: Text('無資料'))
                : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_data.isEmpty) return const SizedBox();
    final columns = _data.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns
              .map(
                (c) => DataColumn(
                  label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
              .toList(),
          rows: _data
              .map((row) => DataRow(cells: columns.map((c) => DataCell(Text(row[c]?.toString() ?? 'null'))).toList()))
              .toList(),
        ),
      ),
    );
  }
}
