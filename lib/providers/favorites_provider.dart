import 'package:flutter/foundation.dart';
import '../models/mekan.dart';
import '../services/mekan_service.dart';

class FavoritesProvider with ChangeNotifier {
  final MekanService _mekanService = MekanService();

  List<Mekan> _favorites = [];
  bool _isLoading = false;

  List<Mekan> get favorites => _favorites;
  bool get isLoading => _isLoading;
  int get count => _favorites.length;

  Future<void> loadFavorites(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _mekanService.getFavorites(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorite(int userId, Mekan mekan) async {
    try {
      final isFavorite = await _mekanService.isFavorite(userId, mekan.id!);

      if (isFavorite) {
        final success = await _mekanService.removeFromFavorites(userId, mekan.id!);
        if (success) {
          _favorites.removeWhere((m) => m.id == mekan.id);
          notifyListeners();
          return false; // Now not favorite
        }
      } else {
        final success = await _mekanService.addToFavorites(userId, mekan.id!);
        if (success) {
          mekan.isFavorite = true;
          _favorites.insert(0, mekan);
          notifyListeners();
          return true; // Now favorite
        }
      }

      return isFavorite;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isFavorite(int userId, int mekanId) async {
    return await _mekanService.isFavorite(userId, mekanId);
  }

  void clear() {
    _favorites = [];
    notifyListeners();
  }
}
