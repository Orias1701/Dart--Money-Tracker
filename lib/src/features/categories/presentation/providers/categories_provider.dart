import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/category_repository.dart';
import '../../domain/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesListProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(categoryRepositoryProvider).getCategories();
});

final categoriesByTypeProvider =
    FutureProvider.family<List<Category>, String>((ref, type) async {
  return ref.read(categoryRepositoryProvider).getCategories(type: type);
});
