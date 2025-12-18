import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/mekan_provider.dart';
import '../utils/constants.dart';
import '../widgets/page_wrapper.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with SingleTickerProviderStateMixin {
  final _ageController = TextEditingController();
  final Set<String> _selectedCategories = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  Future<void> _search() async {
    final age = int.tryParse(_ageController.text);
    if (age == null || age < 5 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir yaş girin (5-100)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir kategori seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final mekanProvider = context.read<MekanProvider>();

    mekanProvider.setPreferences(
      age: age,
      categories: _selectedCategories.toList(),
    );

    await mekanProvider.loadMekanlarByPreferences(
      age: age,
      categories: _selectedCategories.toList(),
      userId: authProvider.currentUser?.id,
    );

    if (!mounted) return;
    Navigator.pushNamed(context, AppConstants.mekanListRoute);
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      showBackButton: false,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, size: 20),
          ),
          onPressed: () {
            Navigator.pushNamed(context, AppConstants.profileRoute);
          },
        ),
        const SizedBox(width: 8),
      ],
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              FadeTransition(
                opacity: _animationController,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba! 👋',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Size en uygun mekanları bulmak için bilgilerinizi girin',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Age Input
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
                )),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.cardGradientStart,
                        AppColors.cardGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            color: AppColors.accent,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Yaşınız',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '25',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Categories
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
                )),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.cardGradientStart,
                        AppColors.cardGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Kategoriler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'İlgilendiğiniz kategorileri seçin',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: AppConstants.categories.map((category) {
                          final isSelected = _selectedCategories
                              .contains(category['id'] as String);
                          return GestureDetector(
                            onTap: () =>
                                _toggleCategory(category['id'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.accent,
                                        ],
                                      )
                                    : null,
                                color:
                                    isSelected ? null : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    category['emoji'] as String,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category['name'] as String,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Search Button
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.5, 1.0),
                ),
                child: GradientButton(
                  text: 'Mekan Ara',
                  onPressed: _search,
                  icon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
