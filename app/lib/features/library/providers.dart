import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/providers.dart';
import '../gear/providers.dart';
import '../meals/providers.dart';
import 'data/library_repository.dart';
import 'data/template_repository.dart';

final libraryRepositoryProvider = Provider((ref) => LibraryRepository(ref.watch(appDatabaseProvider), ref.watch(outboxWriterProvider)));

final templateRepositoryProvider = Provider(
  (ref) => TemplateRepository(ref.watch(appDatabaseProvider), ref.watch(outboxWriterProvider), ref.watch(gearRepositoryProvider), ref.watch(mealRepositoryProvider)),
);

/// The library items of one kind ('gear' or 'meal'), by name.
final libraryItemsProvider = StreamProvider.family<List<LibraryItem>, String>((ref, kind) => ref.watch(libraryRepositoryProvider).watch(kind));

final templatesProvider = StreamProvider<List<Template>>((ref) => ref.watch(templateRepositoryProvider).watchAll());

final templateProvider = StreamProvider.family<Template?, String>((ref, id) => ref.watch(templateRepositoryProvider).watch(id));
