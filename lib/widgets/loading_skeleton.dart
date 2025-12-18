import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                AppColors.surfaceLight,
                AppColors.border,
                AppColors.surfaceLight,
              ],
            ),
          ),
        );
      },
    );
  }
}

class MekanCardSkeleton extends StatelessWidget {
  const MekanCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LoadingSkeleton(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 20,
                    ),
                    const SizedBox(height: 8),
                    const LoadingSkeleton(
                      width: 100,
                      height: 14,
                    ),
                  ],
                ),
              ),
              const LoadingSkeleton(
                width: 50,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LoadingSkeleton(height: 14),
          const SizedBox(height: 8),
          const LoadingSkeleton(width: 200, height: 14),
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const LoadingSkeleton(
            width: 100,
            height: 100,
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
          const SizedBox(height: 16),
          const LoadingSkeleton(width: 150, height: 24),
          const SizedBox(height: 8),
          const LoadingSkeleton(width: 200, height: 16),
          const SizedBox(height: 32),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LoadingSkeleton(
                height: 60,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
