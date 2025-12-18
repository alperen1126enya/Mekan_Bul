import '../database/database_helper.dart';
import '../models/mekan.dart';

class MekanService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Get mekanlar filtered by age and categories
  /// Returns max 6 results, sorted by rating (highest first)
  Future<List<Mekan>> getByPreferences({
    required int age,
    required List<String> categories,
  }) async {
    try {
      if (categories.isEmpty) {
        return [];
      }

      final placeholders = List.filled(categories.length, '?').join(', ');
      final sql = '''
        SELECT * FROM mekanlar 
        WHERE age_min <= ? AND age_max >= ? 
        AND category IN ($placeholders)
        ORDER BY rating DESC 
        LIMIT 6
      ''';

      final args = [age, age, ...categories];
      final results = await _db.rawQuery(sql, args);

      return results.map((map) => Mekan.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get top rated mekanlar
  Future<List<Mekan>> getTopRated({int limit = 6}) async {
    try {
      final results = await _db.query(
        'mekanlar',
        orderBy: 'rating DESC',
        limit: limit,
      );

      return results.map((map) => Mekan.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get all mekanlar
  Future<List<Mekan>> getAllMekanlar() async {
    try {
      final results = await _db.query('mekanlar', orderBy: 'rating DESC');
      return results.map((map) => Mekan.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search mekanlar by name
  Future<List<Mekan>> searchMekanlar(String query) async {
    try {
      final results = await _db.rawQuery(
        "SELECT * FROM mekanlar WHERE name LIKE ? ORDER BY rating DESC",
        ['%$query%'],
      );
      return results.map((map) => Mekan.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get mekan by ID
  Future<Mekan?> getMekanById(int id) async {
    try {
      final results = await _db.query(
        'mekanlar',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) return null;
      return Mekan.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }

  /// Update mekan rating based on average of all yorumlar
  Future<void> updateMekanRating(int mekanId) async {
    try {
      final results = await _db.rawQuery(
        'SELECT AVG(rating) as avg_rating FROM yorumlar WHERE mekan_id = ?',
        [mekanId],
      );

      if (results.isNotEmpty && results.first['avg_rating'] != null) {
        final avgRating = (results.first['avg_rating'] as num).toDouble();
        await _db.update(
          'mekanlar',
          {'rating': avgRating},
          where: 'id = ?',
          whereArgs: [mekanId],
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add mekan to favorites
  Future<bool> addToFavorites(int userId, int mekanId) async {
    try {
      await _db.insert('favorites', {
        'user_id': userId,
        'mekan_id': mekanId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove mekan from favorites
  Future<bool> removeFromFavorites(int userId, int mekanId) async {
    try {
      final count = await _db.delete(
        'favorites',
        where: 'user_id = ? AND mekan_id = ?',
        whereArgs: [userId, mekanId],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get user's favorite mekanlar
  Future<List<Mekan>> getFavorites(int userId) async {
    try {
      final results = await _db.rawQuery('''
        SELECT m.* FROM mekanlar m
        INNER JOIN favorites f ON m.id = f.mekan_id
        WHERE f.user_id = ?
        ORDER BY f.created_at DESC
      ''', [userId]);

      return results.map((map) {
        final mekan = Mekan.fromMap(map);
        mekan.isFavorite = true;
        return mekan;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if mekan is in favorites
  Future<bool> isFavorite(int userId, int mekanId) async {
    try {
      final results = await _db.query(
        'favorites',
        where: 'user_id = ? AND mekan_id = ?',
        whereArgs: [userId, mekanId],
      );
      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Add to recently viewed
  Future<void> addToRecentlyViewed(int userId, int mekanId) async {
    try {
      // Remove existing entry if any
      await _db.delete(
        'recently_viewed',
        where: 'user_id = ? AND mekan_id = ?',
        whereArgs: [userId, mekanId],
      );

      // Add new entry
      await _db.insert('recently_viewed', {
        'user_id': userId,
        'mekan_id': mekanId,
        'viewed_at': DateTime.now().toIso8601String(),
      });

      // Keep only last 10 entries
      await _db.rawQuery('''
        DELETE FROM recently_viewed 
        WHERE user_id = ? AND id NOT IN (
          SELECT id FROM recently_viewed 
          WHERE user_id = ? 
          ORDER BY viewed_at DESC 
          LIMIT 10
        )
      ''', [userId, userId]);
    } catch (e) {
      // Silent fail for recently viewed
    }
  }

  /// Get recently viewed mekanlar
  Future<List<Mekan>> getRecentlyViewed(int userId, {int limit = 10}) async {
    try {
      final results = await _db.rawQuery('''
        SELECT m.* FROM mekanlar m
        INNER JOIN recently_viewed rv ON m.id = rv.mekan_id
        WHERE rv.user_id = ?
        ORDER BY rv.viewed_at DESC
        LIMIT ?
      ''', [userId, limit]);

      return results.map((map) {
        final mekan = Mekan.fromMap(map);
        mekan.isRecentlyViewed = true;
        return mekan;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get mekanlar by category
  Future<List<Mekan>> getByCategory(String category) async {
    try {
      final results = await _db.query(
        'mekanlar',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'rating DESC',
      );

      return results.map((map) => Mekan.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
