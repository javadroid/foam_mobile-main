import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/orders/vendor_active_order_screen.dart';
import 'package:foam_mobile/feature/vendor/orders/vendor_new_order_screen.dart';
import 'package:foam_mobile/feature/vendor/stores/vendor_store_switcher_sheet.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  int _selectedTab = 0; // 0: New, 1: Active, 2: Done

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final provider = Provider.of<VendorProvider>(context);
    final currentStore = provider.currentStore;

    final newOrders = provider.newOrders;
    final activeOrders = provider.activeOrders;
    final doneOrders = provider.doneOrders;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: VendorColors.darkBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'BW',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => VendorStoreSwitcherSheet.show(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentStore.name,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: VendorColors.textMain,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: VendorColors.textMain,
                                ),
                              ],
                            ),
                            Text(
                              'Bright Wash · ${provider.stores.length} stores',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: VendorColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  VendorStatusPill(status: currentStore.status),
                ],
              ),
            ),

            // Summary Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VendorColors.lightBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VendorColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's net",
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: VendorColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₦${currencyFormatter.format(provider.todayNetEarnings.toInt())}',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: VendorColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VendorColors.lightBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VendorColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'In progress',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: VendorColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${provider.inProgressOrdersCount} orders',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: VendorColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tabs: New, Active, Done
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab(0, 'New (${newOrders.length})'),
                    _buildTab(1, 'Active · ${activeOrders.length}'),
                    _buildTab(2, 'Done (${doneOrders.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Orders List
            Expanded(
              child: _buildOrdersList(
                _selectedTab == 0
                    ? newOrders
                    : _selectedTab == 1
                        ? activeOrders
                        : doneOrders,
                isNewTab: _selectedTab == 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? VendorColors.textMain : VendorColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<VendorOrder> orders, {bool isNewTab = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: VendorColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No orders in this queue',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: VendorColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final currencyFormatter = NumberFormat('#,###');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VendorColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (order.isNew) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorNewOrderScreen(order: order),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorActiveOrderScreen(order: order),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.id,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: VendorColors.textMain,
                        ),
                      ),
                      if (order.isNew)
                        VendorCountdownBadge(
                          countdownText: order.formattedCountdown,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: VendorColors.lightBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.status,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: VendorColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.serviceType,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.pickupSlot,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: VendorColors.textMuted,
                        ),
                      ),
                      Text(
                        '₦${currencyFormatter.format(order.vendorEarnings)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: VendorColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
