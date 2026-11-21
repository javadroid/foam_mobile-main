import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foam_mobile/core/Screens/history/model/order.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/08_pickup_leg_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  static const String id = '/order_details';

  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  String _getOrdinalDate(DateTime date) {
    int day = date.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
          break;
      }
    }
    return '$day$suffix ${DateFormat('MMMM yyyy').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("order is here: ${order.toJson()}");
    final upperStatus = order.status.toUpperCase();
    final upperVendorStatus = (order.vendorStatus ?? '').toUpperCase();

    // Map order status & vendor status to stage matching 08_pickup_leg_screen
    String stage;
    if (upperStatus == 'COMPLETED' ||
        upperStatus == 'DELIVERED' ||
        upperVendorStatus == 'COMPLETED' ||
        upperVendorStatus == 'DELIVERED') {
      stage = 'DELIVERED';
    } else if (upperStatus == 'OUT_FOR_DELIVERY' ||
        upperVendorStatus == 'OUT_FOR_DELIVERY') {
      stage = 'OUT_FOR_DELIVERY';
    } else if (upperStatus == 'ONGOING' ||
        upperStatus == 'IN_PROGRESS' ||
        upperStatus == 'READY' ||
        upperVendorStatus == 'RECEIVED_AT_STORE' ||
        upperVendorStatus == 'WASHING' ||
        upperVendorStatus == 'READY' ||
        upperVendorStatus == 'AT_STORE') {
      stage = 'AT_STORE';
    } else if (upperVendorStatus == 'PICKED_UP') {
      stage = 'PICKED_UP';
    } else {
      // PENDING, ACCEPTED, NEW, EN_ROUTE_TO_STORE
      stage = 'EN_ROUTE_TO_STORE';
    }

    final storeName = (order.storeName != null && order.storeName!.trim().isNotEmpty)
        ? order.storeName!
        : 'Laundry Store';

    int stagesLeft = 0;
    if (stage == 'EN_ROUTE_TO_STORE') {
      stagesLeft = 3;
    } else if (stage == 'PICKED_UP' || stage == 'AT_STORE') {
      stagesLeft = 2;
    } else if (stage == 'OUT_FOR_DELIVERY') {
      stagesLeft = 1;
    } else if (stage == 'DELIVERED') {
      stagesLeft = 0;
    }

    String headerText = stagesLeft > 0
        ? '$stagesLeft stage${stagesLeft > 1 ? 's' : ''} left'
        : 'Order completed!';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, MainScreen.id);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.blackAccentColor,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, MainScreen.id);
              }
            },
          ),
        title: Text(
          'Order #${order.displayOrderNumber}',
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          if (order.status != 'CANCELLED')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduleTrackingScreen(orderId: order.id),
                    ),
                  );
                },
                icon: Icon(
                  Icons.near_me_outlined,
                  size: 16,
                  color: AppColors.primaryAccentColor,
                ),
                label: Text(
                  'Track',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primaryAccentColor,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.status == 'CANCELLED') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Cancelled',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'This order was cancelled and is not being processed.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                ] else ...[
                  // Progress Stepper Card matching 08_pickup_leg_screen
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Progression',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: stage == 'DELIVERED'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFE5F7F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                headerText,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: stage == 'DELIVERED'
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF00AABC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildStepperStep(
                          title: 'Order Placed',
                          subtitle: 'Order confirmed and registered',
                          isDone: true,
                          isActive: false,
                          trailing: Text(
                            DateFormat('h:mm a').format(order.createdAt),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _buildStepperConnector(
                            isDone: stage != 'EN_ROUTE_TO_STORE'),
                        _buildStepperStep(
                          title: 'Picked Up',
                          subtitle: stage == 'EN_ROUTE_TO_STORE'
                              ? 'Rider heading to pick up laundry'
                              : 'Laundry collected from address',
                          isDone: stage != 'EN_ROUTE_TO_STORE',
                          isActive: stage == 'EN_ROUTE_TO_STORE' ||
                              stage == 'PICKED_UP',
                        ),
                        _buildStepperConnector(
                          isDone: stage == 'AT_STORE' ||
                              stage == 'OUT_FOR_DELIVERY' ||
                              stage == 'DELIVERED',
                        ),
                        _buildStepperStep(
                          title: 'At Store / Washing',
                          subtitle: stage == 'AT_STORE'
                              ? 'Washing & processing at $storeName'
                              : (stage == 'OUT_FOR_DELIVERY' ||
                                      stage == 'DELIVERED'
                                  ? 'Cleaned and packed'
                                  : 'Waiting to arrive at store'),
                          isDone: stage == 'OUT_FOR_DELIVERY' ||
                              stage == 'DELIVERED',
                          isActive: stage == 'AT_STORE',
                        ),
                        _buildStepperConnector(isDone: stage == 'DELIVERED'),
                        _buildStepperStep(
                          title: 'Out for Delivery',
                          subtitle: stage == 'OUT_FOR_DELIVERY'
                              ? 'Rider dispatched with clean clothes'
                              : (stage == 'DELIVERED'
                                  ? 'Delivered to your address'
                                  : 'Live GPS tracking will unlock here'),
                          isDone: stage == 'DELIVERED',
                          isActive: stage == 'OUT_FOR_DELIVERY',
                          isGatedLock: stage != 'OUT_FOR_DELIVERY' &&
                              stage != 'DELIVERED',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Live Tracking Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccentColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleTrackingScreen(orderId: order.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.near_me_outlined,
                          color: Colors.white, size: 18),
                      label: Text(
                        stage == 'DELIVERED'
                            ? 'View Delivery Summary'
                            : (stage == 'OUT_FOR_DELIVERY'
                                ? 'Track Live Delivery'
                                : 'Track Order Progress'),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                ],
                const Divider(),
                AppSpaces.verticalSpace10,

                // Date & Price Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getOrdinalDate(order.createdAt),
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(order.createdAt),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₦${Constants().currencyFormat(order.totalPrice)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryAccentColor,
                      ),
                    ),
                  ],
                ),

                // Delivery & Location Card
                if (order.pickupAddress != null || order.storeName != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.storeName != null &&
                            order.storeName!.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.storefront,
                                  size: 16,
                                  color: AppColors.primaryAccentColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vendor: ${order.storeName}',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (order.pickupAddress != null &&
                            order.pickupAddress!.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pickup: ${order.pickupAddress}',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12.5,
                                      color: const Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.dry_cleaning_outlined,
                                size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(
                              'Service: ${order.noFolding ? "No Folding (Hangers)" : "Standard Folding Included"}',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  color: const Color(0xFF334155)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),
                AppSpaces.verticalSpace10,

                // Items Section
                Text(
                  'Items (${order.items.fold(0, (s, i) => s + i.quantity)})',
                  style: GoogleFonts.dmSans(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 15),
                Column(
                  children: order.items.map((item) {
                    final imgPath = item.displayImageUrl;
                    final isHttp = imgPath.startsWith('http://') ||
                        imgPath.startsWith('https://');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.shadeGreyAccentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Item Image with safe asset / network fallback
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.fadeBlueAccentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isHttp
                                  ? Image.network(
                                      imgPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.local_laundry_service_outlined,
                                        color: Color(0xFF00AABC),
                                        size: 32,
                                      ),
                                    )
                                  : Image.asset(
                                      imgPath.isNotEmpty
                                          ? imgPath
                                          : 'assets/images/folding',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/folding',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.local_laundry_service_outlined,
                                          color: Color(0xFF00AABC),
                                          size: 32,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          AppSpaces.horizontalSpace10,

                          // Item Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayName,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                if (item.displayDescription.isNotEmpty) ...[
                                  AppSpaces.verticalSpace5,
                                  Text(
                                    item.displayDescription,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Quantity & Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '×${item.quantity}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AppSpaces.verticalSpace5,
                              Text(
                                '₦${Constants().currencyFormat((item.displayPrice * item.quantity).round())}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryAccentColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                AppSpaces.verticalSpace20,

                // Bottom Payment summary info
                const Divider(),
                AppSpaces.verticalSpace10,
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Paid'),
                        Text(
                          '₦${Constants().currencyFormat(order.totalPrice)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    AppSpaces.verticalSpace10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Method'),
                        Text(order.paymentType.isNotEmpty
                            ? order.paymentType
                            : 'Online'),
                      ],
                    ),
                    AppSpaces.verticalSpace10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Status'),
                        Text(
                          order.paymentStatus,
                          style: TextStyle(
                            color:
                                order.paymentStatus.toUpperCase() == 'SUCCEEDED'
                                    ? Colors.green
                                    : Colors.amber.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildStepperStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isGatedLock = false,
    Widget? trailing,
  }) {
    Color iconBg;
    Color iconColor;
    IconData icon;

    if (isDone) {
      iconBg = const Color(0xFF00AABC);
      iconColor = Colors.white;
      icon = Icons.check_rounded;
    } else if (isActive) {
      iconBg = const Color(0xFFE5F7F8);
      iconColor = const Color(0xFF00AABC);
      icon = Icons.radio_button_checked_rounded;
    } else if (isGatedLock) {
      iconBg = const Color(0xFFF3F4F6);
      iconColor = const Color(0xFF9CA3AF);
      icon = Icons.lock_outline_rounded;
    } else {
      iconBg = const Color(0xFFF3F4F6);
      iconColor = const Color(0xFF9CA3AF);
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: const Color(0xFF00AABC), width: 2)
                : null,
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight:
                      (isDone || isActive) ? FontWeight.w700 : FontWeight.w500,
                  color: (isDone || isActive)
                      ? const Color(0xFF1F2937)
                      : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildStepperConnector({required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(
        width: 2,
        height: 20,
        color: isDone ? const Color(0xFF00AABC) : const Color(0xFFE5E7EB),
      ),
    );
  }
}
