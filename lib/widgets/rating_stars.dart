import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;
  final ValueChanged<int>? onRatingChanged;
  final bool interactive;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.showValue = true,
    this.onRatingChanged,
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          final isFilled = rating >= starValue;
          final isHalfFilled = rating >= starValue - 0.5 && rating < starValue;

          return GestureDetector(
            onTap: interactive && onRatingChanged != null
                ? () => onRatingChanged!(starValue)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(interactive ? 4 : 1),
              child: Icon(
                isFilled
                    ? Icons.star_rounded
                    : isHalfFilled
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                color: isFilled || isHalfFilled
                    ? AppColors.starFilled
                    : AppColors.starEmpty,
                size: size,
              ),
            ),
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 36,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = _currentRating >= starValue;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starValue;
            });
            widget.onRatingChanged(starValue);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            child: AnimatedScale(
              scale: isFilled ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFilled ? AppColors.starFilled : AppColors.starEmpty,
                size: widget.size,
              ),
            ),
          ),
        );
      }),
    );
  }
}
