import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Standard shimmer skeleton loading component for the Foam app.
/// Provides consistent skeleton placeholders across lists, cards, and detail pages.
class AppSkeletonLoader extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const AppSkeletonLoader({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  static const Color defaultBase = Color(0xFFF1F5F9); // Slate-100
  static const Color defaultHighlight = Color(0xFFE2E8F0); // Slate-200

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBase,
      highlightColor: highlightColor ?? defaultHighlight,
      child: child,
    );
  }

  /// Generic rectangle placeholder
  static Widget box({
    double? width,
    double? height,
    double borderRadius = 8,
    Color? color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Generic circular placeholder
  static Widget circle({double radius = 20, Color? color}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Skeleton for Vendor & Customer Order Cards
  static Widget orderCard() {
    return AppSkeletonLoader(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    box(width: 80, height: 16, borderRadius: 4),
                    const SizedBox(width: 8),
                    box(width: 60, height: 20, borderRadius: 12),
                  ],
                ),
                box(width: 70, height: 16, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 12),
            box(width: double.infinity, height: 14, borderRadius: 4),
            const SizedBox(height: 8),
            Row(
              children: [
                box(width: 120, height: 12, borderRadius: 4),
                const Spacer(),
                box(width: 80, height: 16, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton for Store Cards
  static Widget storeCard() {
    return AppSkeletonLoader(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                box(width: 140, height: 18, borderRadius: 4),
                box(width: 64, height: 22, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 8),
            box(width: 220, height: 14, borderRadius: 4),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                box(width: 100, height: 14, borderRadius: 4),
                box(width: 80, height: 14, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton for Wallet Transaction Items
  static Widget transactionItem() {
    return AppSkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          children: [
            circle(radius: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(width: 140, height: 15, borderRadius: 4),
                  const SizedBox(height: 6),
                  box(width: 90, height: 12, borderRadius: 4),
                ],
              ),
            ),
            box(width: 70, height: 16, borderRadius: 4),
          ],
        ),
      ),
    );
  }

  /// Skeleton list builder helper
  static Widget list({
    int count = 4,
    required Widget Function(BuildContext context, int index) itemBuilder,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      itemCount: count,
      itemBuilder: itemBuilder,
    );
  }
}
