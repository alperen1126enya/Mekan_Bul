import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/mekan_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'mekan_list_screen.dart';
import 'map_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;
  final NotificationService _notificationService = NotificationService();
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const MekanListScreen(),
    const MapScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeNotifications();
  }

  void _loadInitialData() {
    final authProvider = context.read<AuthProvider>();
    final mekanProvider = context.read<MekanProvider>();
    
    mekanProvider.loadAllMekanlar();
    
    if (authProvider.isLoggedIn) {
      final userId = authProvider.currentUser!.id!;
      context.read<FavoritesProvider>().loadFavorites(userId);
      mekanProvider.loadRecentlyViewed(userId);
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermission();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn) {
      final count = await _notificationService.getUnreadCount(
        authProvider.currentUser!.id!,
      );
      if (mounted) {
        setState(() => _unreadNotifications = count);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                // Notification icon
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: AppColors.textPrimary,
                      onPressed: () {
                        Navigator.pushNamed(context, AppConstants.notificationsRoute).then((_) {
                          _loadUnreadCount();
                        });
                      },
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Ana Sayfa'),
                _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, 'Keşfet'),
                _buildNavItem(2, Icons.map_rounded, Icons.map_outlined, 'Harita'),
                _buildNavItem(3, Icons.favorite_rounded, Icons.favorite_border_rounded, 'Favoriler'),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : AppColors.textMuted,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
