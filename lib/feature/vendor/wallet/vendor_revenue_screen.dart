import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorRevenueScreen extends StatefulWidget {
  const VendorRevenueScreen({super.key});

  @override
  State<VendorRevenueScreen> createState() => _VendorRevenueScreenState();
}

class _VendorRevenueScreenState extends State<VendorRevenueScreen> {
  int _selectedPeriod = 1; // 0: This week, 1: This month
  final String _selectedStoreFilter = 'All stores';

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final provider = Provider.of<VendorProvider>(context);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);

    final netPayable = provider.availableBalance;
    const commissionRate = 0.15;
    final gross = netPayable > 0 ? (netPayable / (1 - commissionRate)) : 0.0;
    final commission = gross - netPayable;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Revenue',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: VendorColors.textMain,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period & Filter Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: VendorColors.lightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildPeriodTab(0, 'This week'),
                        _buildPeriodTab(1, 'This month'),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: VendorColors.lightBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: VendorColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedStoreFilter,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: VendorColors.textMain,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18, color: VendorColors.textMuted),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Net Payable Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: VendorColors.darkBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net payable · $monthName',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₦${currencyFormatter.format(netPayable.toInt())}',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gross revenue',
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦${currencyFormatter.format(gross.toInt())}',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Foam commission (15%)',
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '−₦${currencyFormatter.format(commission.toInt())}',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFFFCA5A5),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // By store section
              Text(
                'By store',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 14),

              if (provider.stores.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Text(
                    'No stores configured yet',
                    style: GoogleFonts.dmSans(color: VendorColors.textMuted, fontSize: 14),
                  ),
                )
              else
                ...provider.stores.map((store) {
                  final storeOrders = provider.doneOrders.where((o) => o.storeId == store.id).toList();
                  final storeNet = storeOrders.fold(0.0, (sum, o) => sum + o.vendorEarnings);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildStoreRevenueCard(
                      storeName: store.name,
                      ordersCount: store.isLive
                          ? '${storeOrders.length} ${storeOrders.length == 1 ? "order" : "orders"}'
                          : 'Not live yet',
                      netAmount: '₦${currencyFormatter.format(storeNet.toInt())}',
                      isLive: store.isLive,
                    ),
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(int index, String label) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? VendorColors.textMain : VendorColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildStoreRevenueCard({
    required String storeName,
    required String ordersCount,
    required String netAmount,
    required bool isLive,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                ordersCount,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: VendorColors.textMuted,
                ),
              ),
            ],
          ),
          Text(
            netAmount,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isLive ? VendorColors.textMain : VendorColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
