import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthService {
  final DatabaseHelper _db = DatabaseHelper();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Check if user already exists
      final existingUsers = await _db.query(
        'users',
        where: 'email = ? OR username = ?',
        whereArgs: [email, username],
      );

      if (existingUsers.isNotEmpty) {
        throw Exception('Bu email veya kullanıcı adı zaten kullanılıyor');
      }

      final passwordHash = _hashPassword(password);
      final now = DateTime.now();

      final user = User(
        username: username,
        email: email,
        passwordHash: passwordHash,
        createdAt: now,
      );

      final id = await _db.insert('users', user.toMap());
      return user.copyWith(id: id);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final passwordHash = _hashPassword(password);

      final users = await _db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email, passwordHash],
      );

      if (users.isEmpty) {
        throw Exception('Email veya şifre hatalı');
      }

      return User.fromMap(users.first);
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      final users = await _db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (users.isEmpty) return null;
      return User.fromMap(users.first);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser({
    required int userId,
    String? username,
    String? email,
    String? newPassword,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (username != null) updates['username'] = username;
      if (email != null) updates['email'] = email;
      if (newPassword != null) {
        updates['password_hash'] = _hashPassword(newPassword);
      }

      if (updates.isEmpty) return false;

      final count = await _db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );

      return count > 0;
    } catch (e) {
      return false;
    }
  }
}
