import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/models/customer_schedule_models.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/06_checkout_screen.dart';
import 'package:foam_mobile/widgets/app_skeleton_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ScheduleItemsScreen extends StatefulWidget {
  static const String id = '/schedule_pickup/items';

  const ScheduleItemsScreen({super.key});

  @override
  State<ScheduleItemsScreen> createState() => _ScheduleItemsScreenState();
}

class _ScheduleItemsScreenState extends State<ScheduleItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider =
          Provider.of<SchedulePickupProvider>(context, listen: false);
      final storeId = provider.currentStore.id;
      final hasLoadedBefore = provider.hasCatalogLoaded(storeId);
      provider.loadStoreCatalog(
        storeId: storeId,
        silent: hasLoadedBefore,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulePickupProvider>(context);
    final currencyFormatter = NumberFormat('#,###');
    final items = provider.items;
    final store = provider.currentStore;
    final isInitialLoading = provider.isItemsLoading && items.isEmpty;
    final storeName = store.name;
    final totalCount = provider.totalBasketCount;
    final subtotal = provider.itemSubtotal;
    final turnaroundOptions = store.effectiveTurnaroundOptions;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF212828), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.selectedService == 'Dry cleaning'
                    ? 'Dry cleaning'
                    : 'Laundry',
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
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Turnaround Option Chips
              if (turnaroundOptions.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: turnaroundOptions.map((opt) {
                      final isSelected =
                          provider.selectedTurnaroundDays == opt.days;
                      final multiplierPercent =
                          ((opt.priceMultiplier - 1.0) * 100).round();
                      final markupText = multiplierPercent > 0
                          ? ' (+$multiplierPercent%)'
                          : '';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            '${opt.days}d ${opt.name}$markupText',
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF212828),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF00AABC),
                          backgroundColor: const Color(0xFFF1F5F9),
                          checkmarkColor: Colors.white,
                          onSelected: (_) =>
                              provider.selectTurnaroundDays(opt.days),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 10),

              // Service category tabs (Laundry vs Dry cleaning)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      key: const Key('service_tab_laundry'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => provider.selectService('Laundry'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: provider.selectedService == 'Laundry'
                              ? const Color(0xFF00AABC)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Laundry',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: provider.selectedService == 'Laundry'
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: provider.selectedService == 'Laundry'
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      key: const Key('service_tab_dry_cleaning'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => provider.selectService('Dry cleaning'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: provider.selectedService == 'Dry cleaning'
                              ? const Color(0xFF00AABC)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Dry cleaning',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight:
                                  provider.selectedService == 'Dry cleaning'
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color: provider.selectedService == 'Dry cleaning'
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: isInitialLoading
                    ? ListView.separated(
                        itemCount: 6,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE4E4E4)),
                        itemBuilder: (_, __) => AppSkeletonLoader.itemRow(),
                      )
                    : provider.filteredItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    provider.selectedService == 'Dry cleaning'
                                        ? Icons.dry_cleaning_outlined
                                        : Icons.local_laundry_service_outlined,
                                    size: 48,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No ${provider.selectedService.toLowerCase()} items available',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: provider.filteredItems.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: Color(0xFFE4E4E4)),
                            itemBuilder: (context, index) {
                              final item = provider.filteredItems[index];
                              return _buildItemRow(context, item, provider,
                                  store, currencyFormatter);
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
                        Flexible(
                          child: Text(
                            '₦${currencyFormatter.format(subtotal)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    ScheduleItem item,
    SchedulePickupProvider provider,
    NearbyStore store,
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
            child: Icon(
              provider.isDryCleaningItem(item)
                  ? Icons.dry_cleaning_outlined
                  : Icons.checkroom_outlined,
              color: const Color(0xFF00AABC),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 4),
                if (item.storeIncludesFolding)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            'Folding included',
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
                else
                  InkWell(
                    onTap: () => provider.toggleItemFolding(item.id),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.userWantsFolding
                            ? const Color(0xFF00AABC).withValues(alpha: 0.12)
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
          Row(
            children: [
              // Minus button
              InkWell(
                onTap: item.quantity > 0
                    ? () => provider.decrementItem(item.id)
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.quantity > 0
                          ? const Color(0xFF777777)
                          : const Color(0xFFE4E4E4),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '−',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        color: item.quantity > 0
                            ? const Color(0xFF212828)
                            : const Color(0xFFCCCCCC),
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
