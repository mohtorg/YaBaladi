// widgets/rating_stars.dart
// عنصر عرض النجوم مع إمكانية التفاعل (للتقييم)

import 'package:flutter/material.dart';

class RatingStars extends StatefulWidget {
  final double rating;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: widget.interactive
              ? () {
                  setState(() {
                    _rating = index + 1.0;
                    if (widget.onRatingChanged != null) {
                      widget.onRatingChanged!(_rating);
                    }
                  });
                }
              : null,
          child: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        );
      }),
    );
  }
}