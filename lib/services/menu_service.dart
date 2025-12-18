import '../database/database_helper.dart';
import '../models/menu_item.dart';

class MenuService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Mekanın menüsünü getir
  Future<List<MenuItem>> getMenuByMekanId(int mekanId) async {
    final db = await _db.database;
    final result = await db.query(
      'menu_items',
      where: 'mekan_id = ?',
      whereArgs: [mekanId],
      orderBy: 'category, name',
    );
    return result.map((map) => MenuItem.fromMap(map)).toList();
  }

  /// Mekanın menü kategorilerini getir
  Future<List<String>> getMenuCategories(int mekanId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM menu_items WHERE mekan_id = ? ORDER BY category',
      [mekanId],
    );
    return result.map((map) => map['category'] as String).toList();
  }

  /// Kategoriye göre menü öğelerini getir
  Future<List<MenuItem>> getMenuByCategory(int mekanId, String category) async {
    final db = await _db.database;
    final result = await db.query(
      'menu_items',
      where: 'mekan_id = ? AND category = ?',
      whereArgs: [mekanId, category],
      orderBy: 'name',
    );
    return result.map((map) => MenuItem.fromMap(map)).toList();
  }

  /// Menü öğesi ekle
  Future<int> addMenuItem(MenuItem item) async {
    final db = await _db.database;
    return await db.insert('menu_items', item.toMap());
  }

  /// Menü öğesi sil
  Future<int> deleteMenuItem(int id) async {
    final db = await _db.database;
    return await db.delete(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mekanın menü öğesi sayısını getir
  Future<int> getMenuItemCount(int mekanId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM menu_items WHERE mekan_id = ?',
      [mekanId],
    );
    return result.first['count'] as int;
  }
}
