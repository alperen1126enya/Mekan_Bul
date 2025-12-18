import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mekan.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/mekan_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/mekan_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn) {
      context.read<FavoritesProvider>().loadFavorites(authProvider.currentUser!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, AppColors.backgroundSecondary],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Favorilerim',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${favoritesProvider.count} mekan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Content
            Expanded(
              child: !authProvider.isLoggedIn
                  ? _buildLoginPrompt()
                  : favoritesProvider.isLoading
                      ? _buildLoadingState()
                      : favoritesProvider.favorites.isEmpty
                          ? _buildEmptyState()
                          : _buildFavoritesList(favoritesProvider.favorites, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 50,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Giriş Yapın',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Favori mekanlarınızı görmek için giriş yapın',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: 3,
      itemBuilder: (context, index) => const MekanCardSkeleton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 50,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz Favori Yok',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Beğendiğiniz mekanları favorilere ekleyin\nve buradan kolayca erişin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<Mekan> favorites, AuthProvider authProvider) {
    final favoritesProvider = context.read<FavoritesProvider>();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final mekan = favorites[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: MekanCard(
            mekan: mekan,
            onTap: () {
              context.read<MekanProvider>().selectMekan(
                mekan.id!,
                userId: authProvider.currentUser?.id,
              );
              Navigator.pushNamed(context, AppConstants.mekanDetailRoute);
            },
            onFavoriteToggle: () async {
              await favoritesProvider.toggleFavorite(
                authProvider.currentUser!.id!,
                mekan,
              );
              setState(() {});
            },
          ),
        );
      },
    );
  }
}
