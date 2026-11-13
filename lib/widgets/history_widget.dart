import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:foam_mobile/core/Screens/history/model/order.dart';
import 'package:foam_mobile/utils/values.dart';

class HistoryWidget extends StatelessWidget {
  final Order? order;
  final String? date;
  final String? details;
  final VoidCallback onTap;

  const HistoryWidget({
    super.key,
    this.order,
    this.date,
    this.details,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (order != null) {
      return _buildModernOrderCard(context, order!);
    }
    return _buildLegacyRow(context);
  }

  Widget _buildModernOrderCard(BuildContext context, Order o) {
    final status = o.status.toUpperCase();
    final vendorStatus = (o.vendorStatus ?? '').toUpperCase();
    final isCompleted = status == 'COMPLETED' || status == 'DELIVERED' || vendorStatus == 'COMPLETED';
    final isCancelled = status == 'CANCELLED' || vendorStatus == 'DECLINED';
    final isAccepted = status == 'ACCEPTED' || vendorStatus == 'ACCEPTED';
    final isOngoing = status == 'ONGOING' ||
        status == 'IN_PROGRESS' ||
        ['WASHING', 'READY', 'OUT_FOR_DELIVERY'].contains(vendorStatus);

    Color badgeBg;
    Color badgeText;
    String statusLabel;

    if (isCompleted) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
      statusLabel = status == 'DELIVERED' ? 'Delivered' : 'Completed';
    } else if (isCancelled) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFB91C1C);
      statusLabel = vendorStatus == 'DECLINED' ? 'Declined' : 'Cancelled';
    } else if (isAccepted) {
      badgeBg = const Color(0xFFE0F2FE);
      badgeText = const Color(0xFF0369A1);
      statusLabel = 'Accepted';
    } else if (isOngoing) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFB45309);
      statusLabel = vendorStatus == 'WASHING'
          ? 'Washing'
          : (vendorStatus == 'READY'
              ? 'Ready'
              : (vendorStatus == 'OUT_FOR_DELIVERY' ? 'Out for Delivery' : 'In Progress'));
    } else {
      badgeBg = const Color(0xFFF1F5F9);
      badgeText = const Color(0xFF475569);
      statusLabel = 'Pending';
    }

    final totalItems = o.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final itemsCountText = totalItems > 0 ? '$totalItems items' : '${o.items.length} items';
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(o.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Order ID + Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_laundry_service_outlined,
                            size: 16,
                            color: AppColors.primaryAccentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order #FM-${o.id}',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: Store name & date
                if (o.storeName != null && o.storeName!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          o.storeName!,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tags: items count + folding mode
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        itemsCountText,
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: o.noFolding
                            ? const Color(0xFFFFF7ED)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        o.noFolding ? 'No Folding' : 'Folded',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: o.noFolding
                              ? const Color(0xFFC2410C)
                              : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Bottom row: Total amount & View receipt button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₦${Constants().currencyFormat(o.totalPrice)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryAccentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppColors.primaryAccentColor,
                        ),
                      ],
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

  Widget _buildLegacyRow(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date ?? '',
                      style: Constants.subHeadingStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      details ?? '',
                      style: Constants.textStyle.copyWith(
                        color: AppColors.primaryAccentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AppSpaces.verticalSpace5,
                    Text(
                      'View Receipt',
                      style: TextStyle(
                        color: AppColors.primaryAccentColor,
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppSpaces.verticalSpace10,
            const Divider(),
          ],
        ),
      ),
    );
  }
}
