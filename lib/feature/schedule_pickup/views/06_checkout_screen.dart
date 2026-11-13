import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/view/pickup_address_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/03_nearby_stores_screen.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/07_order_placed_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ScheduleCheckoutScreen extends StatefulWidget {
  static const String id = '/schedule_pickup/checkout';

  const ScheduleCheckoutScreen({super.key});

  @override
  State<ScheduleCheckoutScreen> createState() => _ScheduleCheckoutScreenState();
}

class _ScheduleCheckoutScreenState extends State<ScheduleCheckoutScreen> {
  bool _isProcessingPayment = false;

  Future<void> _handlePaystackPayment(SchedulePickupProvider provider) async {
    setState(() => _isProcessingPayment = true);

    try {
      final ref = 'fm_pay_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Process Paystack Order with backend
      final success = await provider.processPaystackOrder(paystackRef: ref);

      if (success) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, ScheduleOrderPlacedScreen.id);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not complete Paystack order. Please try again.',
                style: GoogleFonts.dmSans(),
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Paystack checkout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paystack transaction error: $e',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  void _showPickupSlotPicker(
      BuildContext context, SchedulePickupProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final slots = [
          'Today, 3:00 – 4:00 PM',
          'Today, 5:00 – 6:00 PM',
          'Tomorrow, 9:00 – 10:00 AM',
          'Tomorrow, 2:00 – 3:00 PM',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Pickup Slot',
                  style: GoogleFonts.dmSans(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...slots.map(
                  (s) => ListTile(
                    title: Text(s, style: GoogleFonts.dmSans(fontSize: 15)),
                    trailing: provider.pickupSlot == s
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF00AABC))
                        : null,
                    onTap: () {
                      provider.setPickupSlot(s);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final currencyFormatter = NumberFormat('#,###');
    final store = provider.currentStore;
    final tier = provider.currentTier;
    final items = provider.items.where((i) => i.quantity > 0).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF212828), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Basket',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212828),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matched Store Card matching Figma Screen 06
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Matched store · ${tier.title}',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5E5E5E),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${store.name} · ${store.area}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF212828),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '★ ${store.rating.toStringAsFixed(1)} · ${store.turnaroundText}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5E5E5E),
                            ),
                          ),
                          if (provider.selectedTurnaroundOption != null) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00AABC)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${provider.selectedTurnaroundOption!.name} · ${provider.selectedTurnaroundDays}d',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF007A87),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, NearbyStoresScreen.id);
                      },
                      child: Text(
                        'Change',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00AABC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Items breakdown list
              ...items.map(
                (item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.quantity} × ${item.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF212828),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (item.storeIncludesFolding)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F7F8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle,
                                          size: 11, color: Color(0xFF00AABC)),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          'Folding included (Free)',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF00AABC),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (store.hasFoldingFee)
                                InkWell(
                                  onTap: () =>
                                      provider.toggleItemFolding(item.id),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.userWantsFolding
                                          ? const Color(0xFF00AABC)
                                              .withValues(alpha: 0.12)
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: item.userWantsFolding
                                            ? const Color(0xFF00AABC)
                                            : const Color(0xFFE5E7EB),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.userWantsFolding
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 13,
                                          color: item.userWantsFolding
                                              ? const Color(0xFF00AABC)
                                              : const Color(0xFF6B7280),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            item.userWantsFolding
                                                ? 'Folding (+₦${store.foldingPrice.round()})'
                                                : '+ Add folding (+₦${store.foldingPrice.round()})',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: item.userWantsFolding
                                                  ? const Color(0xFF00AABC)
                                                  : const Color(0xFF4B5563),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₦${currencyFormatter.format(provider.getItemPrice(item) * item.quantity)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF212828),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Price Calculation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE4E4E4), width: 0.8),
                ),
                child: Column(
                  children: [
                    _buildCalcRow('Item subtotal',
                        '₦${currencyFormatter.format(provider.itemSubtotal)}'),
                    const SizedBox(height: 10),
                    if (provider.selectedTurnaroundOption != null) ...[
                      _buildCalcRow(
                        'Turnaround speed',
                        '${provider.selectedTurnaroundOption!.name} (${provider.selectedTurnaroundDays}d${provider.selectedTurnaroundOption!.surchargePercent > 0 ? " +${provider.selectedTurnaroundOption!.surchargePercent}%" : ""})',
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (provider.items.any((i) =>
                        i.quantity > 0 &&
                        (i.storeIncludesFolding ||
                            (i.userWantsFolding && store.hasFoldingFee)))) ...[
                      _buildCalcRow(
                        'Store folding care',
                        store.hasFoldingFee && provider.storeFoldingTotal > 0
                            ? '₦${currencyFormatter.format(provider.storeFoldingTotal)} (₦${store.foldingPrice.round()}/item)'
                            : 'Included (Free)',
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildCalcRow('Delivery fee',
                        '₦${currencyFormatter.format(provider.deliveryFee)}'),
                    const SizedBox(height: 10),
                    _buildCalcRow('Service fee',
                        '₦${currencyFormatter.format(provider.serviceFee)}'),
                    const Divider(height: 20, color: Color(0xFFE4E4E4)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Total',
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212828),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '₦${currencyFormatter.format(provider.grandTotal)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212828),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 12),

              // Pay button opens pickup address screen
              Container(
                width: double.infinity,
                height: 53,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00AABC), Color(0xFFC5EFF3)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: provider.isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PickupAddressScreen(
                                totalAmount: provider.grandTotal,
                                isSchedulePickup: true,
                              ),
                            ),
                          );
                        },
                  child: Text(
                    'Pay ₦${currencyFormatter.format(provider.grandTotal)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5E5E5E),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF212828),
            ),
          ),
        ),
      ],
    );
  }
}
