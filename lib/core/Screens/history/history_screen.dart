import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/controllers/remote_services.dart';
import 'package:foam_mobile/core/Screens/history/model/order.dart';
import 'package:foam_mobile/core/Screens/history/order_details_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/08_pickup_leg_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/app_skeleton_loader.dart';
import 'package:foam_mobile/widgets/history_widget.dart';

class HistoryScreen extends StatefulWidget {
  static const String id = '/history_page';
  final VoidCallback? toHome;

  const HistoryScreen({super.key, this.toHome});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedHistory = "Ongoing";
  final List<String> differentHistory = [
    "Ongoing",
    "Completed",
    "Cancelled",
  ];
  List<Order> orders = [];
  bool isLoading = true;
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final fetchedOrders = await ServicesClass.getOrders(scaffoldKey);
    if (!mounted) return;
    if (fetchedOrders != null) {
      setState(() {
        orders = fetchedOrders;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Order> getFilteredOrders() {
    switch (selectedHistory) {
      case "Pending":
      case "Ongoing":
        return orders.where((order) {
          final s = order.status.toUpperCase();
          final vs = (order.vendorStatus ?? '').toUpperCase();
          final isCompleted =
              s == "COMPLETED" || s == "DELIVERED" || vs == "COMPLETED";
          final isCancelled = s == "CANCELLED" || vs == "DECLINED";
          // Include all active orders (including PENDING, NEW, ACCEPTED, IN_PROGRESS, ONGOING, etc.)
          return !isCompleted && !isCancelled;
        }).toList();
      case "Completed":
        return orders.where((order) {
          final s = order.status.toUpperCase();
          final vs = (order.vendorStatus ?? '').toUpperCase();
          return s == "COMPLETED" || s == "DELIVERED" || vs == "COMPLETED";
        }).toList();
      case "Cancelled":
        return orders.where((order) {
          final s = order.status.toUpperCase();
          final vs = (order.vendorStatus ?? '').toUpperCase();
          return s == "CANCELLED" || vs == "DECLINED";
        }).toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = getFilteredOrders();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else if (widget.toHome != null) {
          widget.toHome!();
        } else {
          Navigator.pushReplacementNamed(context, MainScreen.id);
        }
      },
      child: ScaffoldMessenger(
        key: scaffoldKey,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAFAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.blackAccentColor,
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else if (widget.toHome != null) {
                  widget.toHome!();
                } else {
                  Navigator.pushReplacementNamed(context, MainScreen.id);
                }
              },
            ),
            title: Text(
              'Order History',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            centerTitle: true,
          ),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primaryAccentColor,
            onRefresh: fetchOrders,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Segmented Category Tabs
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.0),
                        color: const Color(0xFFF1F5F9),
                      ),
                      child: Row(
                        children: [
                          for (String history in differentHistory)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedHistory = history;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: history == selectedHistory
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: history == selectedHistory
                                        ? [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      history,
                                      style: GoogleFonts.dmSans(
                                        color: history == selectedHistory
                                            ? AppColors.primaryAccentColor
                                            : const Color(0xFF64748B),
                                        fontWeight: history == selectedHistory
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (isLoading)
                    AppSkeletonLoader.list(
                      count: 4,
                      padding: EdgeInsets.zero,
                      itemBuilder: (_, __) => AppSkeletonLoader.orderCard(),
                    )
                  else if (filteredOrders.isEmpty)
                    _buildEmptyState(context)
                  else
                    Column(
                      children: filteredOrders.map((order) {
                        return HistoryWidget(
                          order: order,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailsScreen(order: order),
                              ),
                            ).then((_) => fetchOrders());
                          },
                          onTrack: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ScheduleTrackingScreen(orderId: order.id),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    String submessage;
    IconData icon;

    if (selectedHistory == 'Ongoing') {
      message = 'No active orders';
      submessage =
          'When you place an order, track its live pickup and laundry progress here.';
      icon = Icons.local_laundry_service_outlined;
    } else if (selectedHistory == 'Completed') {
      message = 'No completed orders yet';
      submessage =
          'Your finished laundry orders and receipts will show up here.';
      icon = Icons.check_circle_outline_rounded;
    } else {
      message = 'No cancelled orders';
      submessage = 'You have not cancelled any laundry orders.';
      icon = Icons.cancel_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryAccentColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryAccentColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            submessage,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (selectedHistory == 'Ongoing') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccentColor,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, MainScreen.id);
              },
              child: Text(
                'Schedule Pickup',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
