import '../entities/category.dart';

/// Persistence contract for categories.
abstract interface class CategoryRepository {
  Stream<List<Category>> watchAll();

  Future<List<Category>> findAll();

  Future<Category?> findById(int id);

  Future<Category> create(String name);

  Future<void> rename(int id, String name);

  /// Rejects deletion when products still reference the category.
  Future<void> delete(int id);
}
