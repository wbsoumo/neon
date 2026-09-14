import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  static Widget productCardSkeleton() {
    return Container(
      width: 125,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLoader(width: double.infinity, height: 85, borderRadius: 8),
          SizedBox(height: 8),
          SkeletonLoader(width: 90, height: 12, borderRadius: 4),
          SizedBox(height: 4),
          SkeletonLoader(width: 60, height: 10, borderRadius: 4),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 40, height: 14, borderRadius: 4),
              SkeletonLoader(width: 50, height: 24, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }

  static Widget searchTileSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SkeletonLoader(width: 80, height: 80, borderRadius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLoader(width: 60, height: 10, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonLoader(width: 160, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 10, borderRadius: 4),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLoader(width: 50, height: 16, borderRadius: 4),
                    SkeletonLoader(width: 65, height: 26, borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
