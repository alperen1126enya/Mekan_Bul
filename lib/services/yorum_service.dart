import '../database/database_helper.dart';
import '../models/yorum.dart';
import 'mekan_service.dart';

class YorumService {
  final DatabaseHelper _db = DatabaseHelper();
  final MekanService _mekanService = MekanService();

  /// Add a new comment/rating
  Future<Yorum?> addComment({
    required int userId,
    required int mekanId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Puan 1 ile 5 arasında olmalıdır');
      }

      // Validate comment
      if (comment.trim().isEmpty) {
        throw Exception('Yorum boş olamaz');
      }

      final yorum = Yorum(
        mekanId: mekanId,
        userId: userId,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      );

      final id = await _db.insert('yorumlar', yorum.toMap());

      // Update mekan's average rating
      await _mekanService.updateMekanRating(mekanId);

      return yorum.copyWith(id: id);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all comments for a mekan
  Future<List<Yorum>> getComments(int mekanId) async {
    try {
      final results = await _db.rawQuery('''
        SELECT y.*, u.username 
        FROM yorumlar y
        INNER JOIN users u ON y.user_id = u.id
        WHERE y.mekan_id = ?
        ORDER BY y.created_at DESC
      ''', [mekanId]);

      return results.map((map) => Yorum.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get comment count for a mekan
  Future<int> getCommentCount(int mekanId) async {
    try {
      final results = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM yorumlar WHERE mekan_id = ?',
        [mekanId],
      );

      if (results.isNotEmpty) {
        return results.first['count'] as int;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a comment (only by the owner)
  Future<bool> deleteComment(int yorumId, int userId) async {
    try {
      // First get the mekan_id before deleting
      final yorumlar = await _db.query(
        'yorumlar',
        where: 'id = ? AND user_id = ?',
        whereArgs: [yorumId, userId],
      );

      if (yorumlar.isEmpty) {
        return false;
      }

      final mekanId = yorumlar.first['mekan_id'] as int;

      final count = await _db.delete(
        'yorumlar',
        where: 'id = ? AND user_id = ?',
        whereArgs: [yorumId, userId],
      );

      if (count > 0) {
        // Update mekan's average rating after deletion
        await _mekanService.updateMekanRating(mekanId);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get user's comments
  Future<List<Yorum>> getUserComments(int userId) async {
    try {
      final results = await _db.query(
        'yorumlar',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => Yorum.fromMap(map)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has already commented on a mekan
  Future<bool> hasUserCommented(int userId, int mekanId) async {
    try {
      final results = await _db.query(
        'yorumlar',
        where: 'user_id = ? AND mekan_id = ?',
        whereArgs: [userId, mekanId],
      );
      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
