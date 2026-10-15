import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorNewOrderScreen extends StatelessWidget {
  final VendorOrder order;

  const VendorNewOrderScreen({super.key, required this.order});

  void _showDeclineSheet(BuildContext context) {
    String selectedReason = 'Capacity full';
    final reasons = [
      'Capacity full / at maximum load',
      'Store closing early today',
      'Machine maintenance / power issue',
      'Out of required detergents / packaging',
      'Item cannot be serviced',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Decline order reason',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: VendorColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Foam will immediately reroute this order to the next closest vendor.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: VendorColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<String>(
                    groupValue: selectedReason,
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedReason = val);
                    },
                    child: Column(
                      children: reasons.map((r) {
                        return RadioListTile<String>(
                          value: r,
                          activeColor: VendorColors.primary,
                          title: Text(
                            r,
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  VendorButton(
                    text: 'Confirm Decline',
                    color: VendorColors.urgentText,
                    onPressed: () {
                      final provider = Provider.of<VendorProvider>(context, listen: false);
                      provider.declineOrder(order.id, selectedReason);
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VendorColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          order.id,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: VendorColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Accept countdown banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: VendorColors.urgentBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, color: VendorColors.urgentText, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Accept within ${order.formattedCountdown}',
                    style: GoogleFonts.dmSans(
                      color: VendorColors.urgentText,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.serviceType,
                      style: GoogleFonts.dmSans(
                        color: VendorColors.textMain,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.pickupSlot,
                      style: GoogleFonts.dmSans(
                        color: VendorColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Items card
                    Text(
                      'Items',
                      style: GoogleFonts.dmSans(
                        color: VendorColors.textMain,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VendorColors.lightBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VendorColors.border),
                      ),
                      child: Column(
                        children: order.items.map((it) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${it.name} × ${it.quantity}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: VendorColors.textMain,
                                  ),
                                ),
                                Text(
                                  '₦${currencyFormatter.format(it.totalPrice)}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: VendorColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Price Breakdown
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: VendorColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Item subtotal',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: VendorColors.textMuted,
                                ),
                              ),
                              Text(
                                '₦${currencyFormatter.format(order.subtotal)}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: VendorColors.textMain,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Foam commission (15%)',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: VendorColors.textMuted,
                                ),
                              ),
                              Text(
                                '−₦${currencyFormatter.format(order.commission)}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: VendorColors.urgentText,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: VendorColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'You earn',
                                style: GoogleFonts.dmSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: VendorColors.textMain,
                                ),
                              ),
                              Text(
                                '₦${currencyFormatter.format(order.vendorEarnings)}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: VendorColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions: Decline / Accept
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: VendorButton(
                      text: 'Decline',
                      isSecondary: true,
                      onPressed: () => _showDeclineSheet(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: VendorButton(
                      text: 'Accept order',
                      onPressed: () {
                        final provider = Provider.of<VendorProvider>(context, listen: false);
                        provider.acceptOrder(order.id);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
