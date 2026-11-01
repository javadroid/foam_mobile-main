import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/06_checkout_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ScheduleItemsScreen extends StatelessWidget {
  static const String id = '/schedule_pickup/items';

  const ScheduleItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final currencyFormatter = NumberFormat('#,###');
    final items = provider.items;
    final storeName = provider.currentStore.name;
    final totalCount = provider.totalBasketCount;
    final subtotal = provider.itemSubtotal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212828), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laundry · Folding',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF212828),
              ),
            ),
            Text(
              'Prices from $storeName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5E5E5E),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE4E4E4)),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemRow(context, item, provider, currencyFormatter);
                  },
                ),
              ),

              // Bottom sticky View Basket bar matching Figma Screen 05
              if (totalCount > 0)
                Container(
                  width: double.infinity,
                  height: 53,
                  margin: const EdgeInsets.only(bottom: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, ScheduleCheckoutScreen.id);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'View basket · $totalCount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₦${currencyFormatter.format(subtotal)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    ScheduleItem item,
    SchedulePickupProvider provider,
    NumberFormat formatter,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.checkroom_outlined, color: Color(0xFF00AABC), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₦${formatter.format(provider.getItemPrice(item))}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5E5E5E),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Minus button
              InkWell(
                onTap: item.quantity > 0 ? () => provider.decrementItem(item.id) : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.quantity > 0 ? const Color(0xFF777777) : const Color(0xFFE4E4E4),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '−',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        color: item.quantity > 0 ? const Color(0xFF212828) : const Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    '${item.quantity}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212828),
                    ),
                  ),
                ),
              ),
              // Plus button
              InkWell(
                onTap: () => provider.incrementItem(item.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00AABC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '+',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
