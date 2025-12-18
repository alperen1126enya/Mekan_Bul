import 'package:flutter/material.dart';
import '../models/mekan.dart';
import '../utils/constants.dart';
import 'rating_stars.dart';

class MekanCard extends StatefulWidget {
  final Mekan mekan;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFirst;

  const MekanCard({
    super.key,
    required this.mekan,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFirst = false,
  });

  @override
  State<MekanCard> createState() => _MekanCardState();
}

class _MekanCardState extends State<MekanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restoran':
        return Icons.restaurant_rounded;
      case 'cafe':
        return Icons.coffee_rounded;
      case 'eglence':
        return Icons.celebration_rounded;
      case 'fast_food':
        return Icons.fastfood_rounded;
      case 'bar':
        return Icons.local_bar_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isFirst
                  ? [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.accent.withValues(alpha: 0.2),
                    ]
                  : [
                      AppColors.cardGradientStart,
                      AppColors.cardGradientEnd,
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isFirst
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.3),
              width: widget.isFirst ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: _isPressed ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(widget.mekan.category),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name and Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (widget.isFirst) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.starFilled,
                                        AppColors.accent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '👑 TOP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  widget.mekan.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.mekan.categoryDisplayName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Favorite Button
                    if (widget.onFavoriteToggle != null)
                      GestureDetector(
                        onTap: widget.onFavoriteToggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.mekan.isFavorite
                                ? AppColors.accent.withValues(alpha: 0.2)
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.mekan.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: widget.mekan.isFavorite
                                ? AppColors.accent
                                : AppColors.textMuted,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Address
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.mekan.address,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Rating and Age Range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RatingStars(
                      rating: widget.mekan.rating,
                      size: 18,
                      showValue: true,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.mekan.ageMin}-${widget.mekan.ageMax} yaş',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
