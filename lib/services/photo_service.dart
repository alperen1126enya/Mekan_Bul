import '../database/database_helper.dart';
import '../models/mekan_photo.dart';

class PhotoService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Get all photos for a mekan
  Future<List<MekanPhoto>> getPhotos(int mekanId) async {
    final results = await _db.query(
      'mekan_photos',
      where: 'mekan_id = ?',
      whereArgs: [mekanId],
      orderBy: 'created_at DESC',
    );
    
    return results.map((map) => MekanPhoto.fromMap(map)).toList();
  }

  /// Add a new photo for a mekan
  Future<MekanPhoto> addPhoto({
    required int mekanId,
    required String photoUrl,
    int? uploadedBy,
  }) async {
    final now = DateTime.now();
    
    final photo = MekanPhoto(
      mekanId: mekanId,
      photoUrl: photoUrl,
      uploadedBy: uploadedBy,
      createdAt: now,
    );
    
    final id = await _db.insert('mekan_photos', photo.toMap());
    
    return photo.copyWith(id: id);
  }

  /// Delete a photo (only if user is the uploader or admin)
  Future<bool> deletePhoto(int photoId, int userId) async {
    // Check if user is the uploader
    final results = await _db.query(
      'mekan_photos',
      where: 'id = ? AND uploaded_by = ?',
      whereArgs: [photoId, userId],
    );
    
    if (results.isEmpty) {
      throw Exception('Bu fotoğrafı silme yetkiniz yok');
    }
    
    final deleted = await _db.delete(
      'mekan_photos',
      where: 'id = ?',
      whereArgs: [photoId],
    );
    
    return deleted > 0;
  }

  /// Get photo count for a mekan
  Future<int> getPhotoCount(int mekanId) async {
    final results = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM mekan_photos WHERE mekan_id = ?',
      [mekanId],
    );
    
    return results.first['count'] as int;
  }

  /// Get all photos uploaded by a user
  Future<List<MekanPhoto>> getUserPhotos(int userId) async {
    final results = await _db.query(
      'mekan_photos',
      where: 'uploaded_by = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    
    return results.map((map) => MekanPhoto.fromMap(map)).toList();
  }
}
