import 'package:flutter/material.dart';
import 'package:opengo/src/features/themes/app_theme.dart';

class AppStarRating extends StatefulWidget {
  final int rating;
  final ValueChanged<int>? onRatingChanged;

  const AppStarRating({super.key, required this.rating, this.onRatingChanged})
    : assert(rating >= 0 && rating <= 5, 'Rating must be between 0 and 5');

  @override
  State<AppStarRating> createState() => _AppStarRatingState();
}

class _AppStarRatingState extends State<AppStarRating> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.rating;
  }

  @override
  void didUpdateWidget(covariant AppStarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rating != oldWidget.rating) {
      _rating = widget.rating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: index < _rating
                ? Theme.of(context).extension<AppTheme>()?.highlightDarkestColor
                : Theme.of(context).extension<AppTheme>()?.backgroundWeakColor,
            size: 24,
          ),
          onPressed: widget.onRatingChanged != null
              ? () {
                  final newRating = index + 1 == _rating ? index : index + 1;
                  _rating = newRating;
                  widget.onRatingChanged!(newRating);
                }
              : null,
        );
      }),
    );
  }
}
