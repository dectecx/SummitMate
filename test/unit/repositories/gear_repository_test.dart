import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/repositories/gear_repository.dart';

void main() {
  late Isar isar;
  late GearRepository repository;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    isar = await Isar.open(
      [GearItemSchema],
      directory: '',
      name: 'test_gear_${DateTime.now().millisecondsSinceEpoch}',
    );
    repository = GearRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('GearRepository Tests', () {
    test('should add and retrieve gear item', () async {
      final item = GearItem()
        ..name = '羽絨睡袋'
        ..weight = 800
        ..category = 'Sleep'
        ..isChecked = false;

      await repository.addItem(item);

      final items = await repository.getAllItems();
      expect(items.length, 1);
      expect(items.first.name, '羽絨睡袋');
      expect(items.first.weight, 800);
    });

    test('should get items by category', () async {
      await repository.addItem(GearItem()
        ..name = '睡袋'
        ..weight = 800
        ..category = 'Sleep'
        ..isChecked = false);
      await repository.addItem(GearItem()
        ..name = '鈦杯'
        ..weight = 150
        ..category = 'Cook'
        ..isChecked = false);

      final sleepItems = await repository.getItemsByCategory('Sleep');
      expect(sleepItems.length, 1);
      expect(sleepItems.first.name, '睡袋');
    });

    test('should toggle checked state', () async {
      final item = GearItem()
        ..name = '睡墊'
        ..weight = 400
        ..category = 'Sleep'
        ..isChecked = false;

      final id = await repository.addItem(item);
      await repository.toggleChecked(id);

      final items = await repository.getAllItems();
      expect(items.first.isChecked, isTrue);
    });

    test('should calculate total weight', () async {
      await repository.addItem(GearItem()
        ..name = '睡袋'
        ..weight = 800
        ..category = 'Sleep'
        ..isChecked = true);
      await repository.addItem(GearItem()
        ..name = '睡墊'
        ..weight = 400
        ..category = 'Sleep'
        ..isChecked = true);

      final total = await repository.getTotalWeight();
      expect(total, 1200);
    });

    test('should calculate checked weight only', () async {
      await repository.addItem(GearItem()
        ..name = '睡袋'
        ..weight = 800
        ..category = 'Sleep'
        ..isChecked = true);
      await repository.addItem(GearItem()
        ..name = '未打包裝備'
        ..weight = 500
        ..category = 'Other'
        ..isChecked = false);

      final checkedWeight = await repository.getCheckedWeight();
      expect(checkedWeight, 800);
    });

    test('should delete item', () async {
      final id = await repository.addItem(GearItem()
        ..name = 'To Delete'
        ..weight = 100
        ..category = 'Other'
        ..isChecked = false);

      await repository.deleteItem(id);

      final items = await repository.getAllItems();
      expect(items.isEmpty, isTrue);
    });

    test('should get weight by category', () async {
      await repository.addItem(GearItem()
        ..name = '睡袋'
        ..weight = 800
        ..category = 'Sleep'
        ..isChecked = false);
      await repository.addItem(GearItem()
        ..name = '睡墊'
        ..weight = 400
        ..category = 'Sleep'
        ..isChecked = false);
      await repository.addItem(GearItem()
        ..name = '鈦杯'
        ..weight = 150
        ..category = 'Cook'
        ..isChecked = false);

      final weightByCategory = await repository.getWeightByCategory();
      expect(weightByCategory['Sleep'], 1200);
      expect(weightByCategory['Cook'], 150);
    });
  });
}
