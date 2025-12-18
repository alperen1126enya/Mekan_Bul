import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mekan.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/mekan_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/mekan_card.dart';
import '../widgets/page_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn) {
      final userId = authProvider.currentUser!.id!;
      context.read<FavoritesProvider>().loadFavorites(userId);
      context.read<MekanProvider>().loadRecentlyViewed(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final mekanProvider = context.watch<MekanProvider>();

    if (!authProvider.isLoggedIn) {
      return PageWrapper(
        showBackButton: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 80, color: AppColors.textMuted),
              const SizedBox(height: 24),
              const Text('Giriş Yapın', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              const Text('Profilinizi görmek için giriş yapın', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Giriş Yap',
                onPressed: () => Navigator.pushNamed(context, AppConstants.loginRoute),
                width: 200,
              ),
            ],
          ),
        ),
      );
    }

    final user = authProvider.currentUser!;

    return PageWrapper(
      showBackButton: false,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Header
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
          Text(user.username, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(user.email, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.favorite_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Favoriler (${favoritesProvider.count})'),
                ])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.history_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Son (${mekanProvider.recentlyViewed.length})'),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMekanList(favoritesProvider.favorites, favoritesProvider.isLoading, 'Henüz favori mekan yok'),
                _buildMekanList(mekanProvider.recentlyViewed, false, 'Henüz mekan görüntülemediniz'),
              ],
            ),
          ),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  favoritesProvider.clear();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppConstants.loginRoute, (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.2),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMekanList(List<Mekan> mekanlar, bool isLoading, String emptyMessage) {
    final authProvider = context.read<AuthProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();

    if (isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 3,
        itemBuilder: (context, index) => const MekanCardSkeleton(),
      );
    }

    if (mekanlar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: mekanlar.length,
      itemBuilder: (context, index) {
        final mekan = mekanlar[index];
        return MekanCard(
          mekan: mekan,
          onTap: () {
            context.read<MekanProvider>().selectMekan(mekan.id!, userId: authProvider.currentUser?.id);
            Navigator.pushNamed(context, AppConstants.mekanDetailRoute);
          },
          onFavoriteToggle: () async {
            await favoritesProvider.toggleFavorite(authProvider.currentUser!.id!, mekan);
            setState(() {});
          },
        );
      },
    );
  }
}
