import 'package:flutter/foundation.dart';

/// Rating target type (Store or Rider)
enum RateTargetType {
  store,
  rider,
}

/// Represents an individual rating record
@immutable
class RateModel {
  final String id;
  final String orderId;
  final String? storeId;
  final String? riderId;
  final String targetType; // 'STORE' or 'RIDER'
  final double rating;
  final String? comment;
  final String? customerName;
  final String? customerAvatar;
  final DateTime? createdAt;

  const RateModel({
    required this.id,
    required this.orderId,
    this.storeId,
    this.riderId,
    required this.targetType,
    required this.rating,
    this.comment,
    this.customerName,
    this.customerAvatar,
    this.createdAt,
  });

  bool get isStore => targetType.toUpperCase() == 'STORE';
  bool get isRider => targetType.toUpperCase() == 'RIDER';

  factory RateModel.fromJson(Map<String, dynamic> json) {
    return RateModel(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      storeId: json['storeId']?.toString(),
      riderId: json['riderId']?.toString(),
      targetType: json['targetType']?.toString() ?? 'STORE',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String?,
      customerName: json['customerName'] as String?,
      customerAvatar: json['customerAvatar'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        if (storeId != null) 'storeId': storeId,
        if (riderId != null) 'riderId': riderId,
        'targetType': targetType,
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (customerName != null) 'customerName': customerName,
        if (customerAvatar != null) 'customerAvatar': customerAvatar,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}

/// Aggregate rating summary for store or rider (no dummy 5 stars)
@immutable
class RatingSummary {
  final double averageRating;
  final int ratingCount;
  final bool isNew;
  final String formattedRating;
  final Map<int, int> distribution;

  const RatingSummary({
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.isNew = true,
    this.formattedRating = 'New',
    this.distribution = const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
  });

  bool get hasReviews => ratingCount > 0 && averageRating > 0.0;

  String get displayRating =>
      hasReviews ? averageRating.toStringAsFixed(1) : 'New';

  String get displayWithStar =>
      hasReviews ? '★ ${averageRating.toStringAsFixed(1)}' : 'New';

  String get displayWithCount => hasReviews
      ? '★ ${averageRating.toStringAsFixed(1)} ($ratingCount)'
      : 'New';

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    final count = (json['ratingCount'] as num?)?.toInt() ?? 0;
    final avg = (json['averageRating'] as num?)?.toDouble() ?? 0.0;
    final rawIsNew = (json['isNew'] as bool?) ?? (count == 0 || avg == 0.0);
    final rawDist = json['distribution'];
    final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    if (rawDist is Map) {
      rawDist.forEach((key, value) {
        final k = int.tryParse(key.toString());
        final v = (value as num?)?.toInt() ?? 0;
        if (k != null) dist[k] = v;
      });
    }

    return RatingSummary(
      averageRating: avg,
      ratingCount: count,
      isNew: rawIsNew,
      formattedRating: rawIsNew ? 'New' : avg.toStringAsFixed(1),
      distribution: dist,
    );
  }

  Map<String, dynamic> toJson() => {
        'averageRating': averageRating,
        'ratingCount': ratingCount,
        'isNew': isNew,
        'formattedRating': formattedRating,
        'distribution': distribution,
      };
}
