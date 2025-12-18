import 'package:flutter/foundation.dart';
import '../models/mekan.dart';
import '../services/mekan_service.dart';

class MekanProvider with ChangeNotifier {
  final MekanService _mekanService = MekanService();

  List<Mekan> _mekanlar = [];
  List<Mekan> _recentlyViewed = [];
  Mekan? _selectedMekan;
  bool _isLoading = false;
  String? _error;

  // Filter state
  int? _selectedAge;
  List<String> _selectedCategories = [];

  List<Mekan> get mekanlar => _mekanlar;
  List<Mekan> get recentlyViewed => _recentlyViewed;
  Mekan? get selectedMekan => _selectedMekan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedAge => _selectedAge;
  List<String> get selectedCategories => _selectedCategories;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setPreferences({required int age, required List<String> categories}) {
    _selectedAge = age;
    _selectedCategories = categories;
    notifyListeners();
  }

  Future<void> loadMekanlarByPreferences({
    required int age,
    required List<String> categories,
    int? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedAge = age;
      _selectedCategories = categories;
      
      _mekanlar = await _mekanService.getByPreferences(
        age: age,
        categories: categories,
      );

      // Check favorites if user is logged in
      if (userId != null) {
        for (var i = 0; i < _mekanlar.length; i++) {
          final isFav = await _mekanService.isFavorite(userId, _mekanlar[i].id!);
          _mekanlar[i].isFavorite = isFav;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllMekanlar({int? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mekanlar = await _mekanService.getAllMekanlar();

      // Check favorites if user is logged in
      if (userId != null) {
        for (var i = 0; i < _mekanlar.length; i++) {
          final isFav = await _mekanService.isFavorite(userId, _mekanlar[i].id!);
          _mekanlar[i].isFavorite = isFav;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByCategory(String category, {int? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mekanlar = await _mekanService.getByCategory(category);

      // Check favorites if user is logged in
      if (userId != null) {
        for (var i = 0; i < _mekanlar.length; i++) {
          final isFav = await _mekanService.isFavorite(userId, _mekanlar[i].id!);
          _mekanlar[i].isFavorite = isFav;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchMekanlar(String query, {int? userId}) async {
    if (query.isEmpty) {
      await loadAllMekanlar(userId: userId);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mekanlar = await _mekanService.searchMekanlar(query);

      // Check favorites if user is logged in
      if (userId != null) {
        for (var i = 0; i < _mekanlar.length; i++) {
          final isFav = await _mekanService.isFavorite(userId, _mekanlar[i].id!);
          _mekanlar[i].isFavorite = isFav;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTopRated({int? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mekanlar = await _mekanService.getTopRated();

      // Check favorites if user is logged in
      if (userId != null) {
        for (var i = 0; i < _mekanlar.length; i++) {
          final isFav = await _mekanService.isFavorite(userId, _mekanlar[i].id!);
          _mekanlar[i].isFavorite = isFav;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectMekan(int mekanId, {int? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedMekan = await _mekanService.getMekanById(mekanId);

      if (_selectedMekan != null && userId != null) {
        _selectedMekan!.isFavorite = await _mekanService.isFavorite(
          userId,
          mekanId,
        );
        await _mekanService.addToRecentlyViewed(userId, mekanId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedMekan() {
    _selectedMekan = null;
    notifyListeners();
  }

  Future<void> loadRecentlyViewed(int userId) async {
    try {
      _recentlyViewed = await _mekanService.getRecentlyViewed(userId);
      notifyListeners();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> refreshMekan(int mekanId, {int? userId}) async {
    try {
      final mekan = await _mekanService.getMekanById(mekanId);
      if (mekan != null) {
        if (userId != null) {
          mekan.isFavorite = await _mekanService.isFavorite(userId, mekanId);
        }
        _selectedMekan = mekan;
        
        // Also update in list
        final index = _mekanlar.indexWhere((m) => m.id == mekanId);
        if (index != -1) {
          _mekanlar[index] = mekan;
        }
        
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }
}
