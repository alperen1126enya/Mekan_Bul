import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/mekan.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/mekan_provider.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final mekanProvider = context.read<MekanProvider>();
    
    // Tüm mekanları yükle
    mekanProvider.loadAllMekanlar();
    
    if (authProvider.isLoggedIn) {
      final userId = authProvider.currentUser!.id!;
      context.read<FavoritesProvider>().loadFavorites(userId);
      mekanProvider.loadRecentlyViewed(userId);
    }
  }

  void _goToRandomMekan() {
    final mekanProvider = context.read<MekanProvider>();
    final authProvider = context.read<AuthProvider>();
    
    if (mekanProvider.mekanlar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mekan bulunamadı')),
      );
      return;
    }
    
    final random = Random();
    final randomMekan = mekanProvider.mekanlar[random.nextInt(mekanProvider.mekanlar.length)];
    
    mekanProvider.selectMekan(
      randomMekan.id!,
      userId: authProvider.currentUser?.id,
    );
    Navigator.pushNamed(context, AppConstants.mekanDetailRoute);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mekanProvider = context.watch<MekanProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, AppColors.backgroundSecondary],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hoş Geldin${authProvider.isLoggedIn ? ", ${authProvider.currentUser!.username}" : ""}! 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Bugün nereye gitmek istersin?',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              authProvider.isLoggedIn 
                                ? authProvider.currentUser!.username[0].toUpperCase()
                                : '?',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Random Mekan Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: GestureDetector(
                  onTap: _goToRandomMekan,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shuffle_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bugün Nereye Gitsem? 🎲',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rastgele bir mekan öner',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Kategoriler başlığı
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Kategoriler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // Kategoriler Grid
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: AppConstants.categories.length,
                  itemBuilder: (context, index) {
                    final category = AppConstants.categories[index];
                    return _buildCategoryCard(category);
                  },
                ),
              ),
            ),

            // Öne Çıkan Mekanlar başlığı
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Öne Çıkan Mekanlar ⭐',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Öne Çıkan Mekanlar
            SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: mekanProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: mekanProvider.mekanlar.take(5).length,
                        itemBuilder: (context, index) {
                          final mekan = mekanProvider.mekanlar[index];
                          return _buildFeaturedMekanCard(mekan);
                        },
                      ),
              ),
            ),

            // Son Görüntülenenler
            if (authProvider.isLoggedIn && mekanProvider.recentlyViewed.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Son Görüntülenenler 🕒',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mekanProvider.recentlyViewed.take(5).length,
                    itemBuilder: (context, index) {
                      final mekan = mekanProvider.recentlyViewed[index];
                      return _buildFeaturedMekanCard(mekan);
                    },
                  ),
                ),
              ),
            ],

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        final mekanProvider = context.read<MekanProvider>();
        mekanProvider.filterByCategory(category['id']);
        // Navigate to explore tab will be handled by parent
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surfaceLight,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category['emoji'] as String,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedMekanCard(Mekan mekan) {
    return GestureDetector(
      onTap: () {
        final authProvider = context.read<AuthProvider>();
        context.read<MekanProvider>().selectMekan(
          mekan.id!,
          userId: authProvider.currentUser?.id,
        );
        Navigator.pushNamed(context, AppConstants.mekanDetailRoute);
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder with gradient
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.accent.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  _getCategoryEmoji(mekan.category),
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mekan.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.starFilled, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        mekan.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getCategoryName(mekan.category),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(String kategori) {
    final category = AppConstants.categories.firstWhere(
      (c) => c['id'] == kategori,
      orElse: () => {'emoji': '📍'},
    );
    return category['emoji'] as String;
  }

  String _getCategoryName(String kategori) {
    final category = AppConstants.categories.firstWhere(
      (c) => c['id'] == kategori,
      orElse: () => {'name': 'Diğer'},
    );
    return category['name'] as String;
  }
}
