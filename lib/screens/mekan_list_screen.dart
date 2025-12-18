import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mekan.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/mekan_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/mekan_card.dart';

class MekanListScreen extends StatefulWidget {
  const MekanListScreen({super.key});

  @override
  State<MekanListScreen> createState() => _MekanListScreenState();
}

class _MekanListScreenState extends State<MekanListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMekanlar();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMekanlar() {
    final authProvider = context.read<AuthProvider>();
    context.read<MekanProvider>().loadAllMekanlar(
      userId: authProvider.currentUser?.id,
    );
  }

  void _onSearch(String query) {
    final authProvider = context.read<AuthProvider>();
    context.read<MekanProvider>().searchMekanlar(
      query,
      userId: authProvider.currentUser?.id,
    );
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    final authProvider = context.read<AuthProvider>();
    
    if (category == 'all') {
      context.read<MekanProvider>().loadAllMekanlar(
        userId: authProvider.currentUser?.id,
      );
    } else {
      context.read<MekanProvider>().filterByCategory(
        category,
        userId: authProvider.currentUser?.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mekanProvider = context.watch<MekanProvider>();
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                    child: const Icon(Icons.explore_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Keşfet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Mekan ara...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Category Filter
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('all', 'Tümü', Icons.apps_rounded),
                  ...AppConstants.categories.map((cat) => _buildCategoryChip(
                    cat['id'] as String,
                    cat['name'] as String,
                    cat['icon'] as IconData,
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 8),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${mekanProvider.mekanlar.length} sonuç',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Mekan List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadMekanlar(),
                color: AppColors.primary,
                child: mekanProvider.isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemCount: 4,
                        itemBuilder: (context, index) => const MekanCardSkeleton(),
                      )
                    : mekanProvider.mekanlar.isEmpty
                        ? _buildEmptyState()
                        : _buildMekanList(
                            mekanProvider.mekanlar,
                            authProvider,
                            favoritesProvider,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String id, String name, IconData icon) {
    final isSelected = _selectedCategory == id;
    
    return GestureDetector(
      onTap: () => _onCategorySelected(id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [AppColors.primary, AppColors.accent])
              : null,
          color: isSelected ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
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
                Icons.search_off_rounded,
                size: 50,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mekan Bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Farklı arama kriterleri deneyin',
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

  Widget _buildMekanList(
    List<Mekan> mekanlar,
    AuthProvider authProvider,
    FavoritesProvider favoritesProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: mekanlar.length,
      itemBuilder: (context, index) {
        final mekan = mekanlar[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: MekanCard(
            mekan: mekan,
            isFirst: index == 0,
            onTap: () {
              context.read<MekanProvider>().selectMekan(
                mekan.id!,
                userId: authProvider.currentUser?.id,
              );
              Navigator.pushNamed(context, AppConstants.mekanDetailRoute);
            },
            onFavoriteToggle: authProvider.isLoggedIn
                ? () async {
                    final userId = authProvider.currentUser!.id!;
                    final newState = await favoritesProvider.toggleFavorite(userId, mekan);
                    setState(() {
                      mekan.isFavorite = newState;
                    });
                  }
                : null,
          ),
        );
      },
    );
  }
}
