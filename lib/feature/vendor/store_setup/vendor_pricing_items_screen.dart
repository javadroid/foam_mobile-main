import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorPricingItemsScreen extends StatefulWidget {
  final String serviceType;
  final String foldType;

  const VendorPricingItemsScreen({
    super.key,
    required this.serviceType,
    this.foldType = 'Folding',
  });

  @override
  State<VendorPricingItemsScreen> createState() => _VendorPricingItemsScreenState();
}

class _VendorPricingItemsScreenState extends State<VendorPricingItemsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  late bool _includeFolding;

  final List<String> _laundryItems = [
    'Shirt',
    'T-shirt',
    'Trouser',
    'Jeans',
    'Bedsheet',
    'Duvet',
    'Towel',
    'Native (agbada)',
  ];

  final List<String> _dryCleaningItems = [
    'Suit (2-piece)',
    'Suit (3-piece)',
    'Blazer / Jacket',
    'Dress / Gown',
    'Evening Gown',
    'Winter Coat',
    'Silk / Delicate Top',
    'Agbada Complete',
  ];

  List<String> get _items =>
      widget.serviceType == 'Dry cleaning' ? _dryCleaningItems : _laundryItems;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<VendorProvider>(context, listen: false);
    _includeFolding = provider.getStoreIncludeFolding(provider.currentStore.id);

    final existingPrices = provider.getItemPrices(
      provider.currentStore.id,
      widget.serviceType,
      widget.foldType,
    );

    for (final item in _items) {
      final price = existingPrices[item];
      _controllers[item] = TextEditingController(
        text: price != null ? price.toInt().toString() : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _pricedCount {
    return _controllers.values
        .where((c) => c.text.trim().isNotEmpty && double.tryParse(c.text.trim()) != null)
        .length;
  }

  void _savePrices() {
    final provider = Provider.of<VendorProvider>(context, listen: false);
    final storeId = provider.currentStore.id;

    for (final entry in _controllers.entries) {
      final p = double.tryParse(entry.value.text.trim());
      if (p != null) {
        // Save price uniformly under the service
        provider.setItemPrice(
          storeId,
          widget.serviceType,
          'Folding',
          entry.key,
          p,
        );
        provider.setItemPrice(
          storeId,
          widget.serviceType,
          'Non-folding',
          entry.key,
          p,
        );
        provider.setItemPrice(
          storeId,
          widget.serviceType,
          widget.foldType,
          entry.key,
          p,
        );
      }
    }

    if (widget.serviceType == 'Laundry') {
      provider.setStoreIncludeFolding(storeId, _includeFolding);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLaundry = widget.serviceType == 'Laundry';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VendorColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceType,
                    style: GoogleFonts.dmSans(
                      color: VendorColors.textMain,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.serviceType} · price per item',
                    style: GoogleFonts.dmSans(
                      color: VendorColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Folding Service Setting Switch
                  if (isLaundry) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _includeFolding ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _includeFolding ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _includeFolding ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.checkroom_rounded,
                              color: _includeFolding ? const Color(0xFF16A34A) : Colors.grey,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Include Folding Service',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Fold items in packaging (customers can opt out at checkout)',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _includeFolding,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (val) {
                              setState(() {
                                _includeFolding = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_pricedCount of ${_items.length} priced',
                        style: GoogleFonts.dmSans(
                          color: VendorColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: VendorColors.lightBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Foam takes 15% commission',
                          style: GoogleFonts.dmSans(
                            color: VendorColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: VendorColors.border),

            // Item inputs list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                itemCount: _items.length,
                separatorBuilder: (ctx, i) => const Divider(
                  height: 16,
                  color: VendorColors.border,
                ),
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: VendorColors.textMain,
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 42,
                          decoration: BoxDecoration(
                            color: VendorColors.lightBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: VendorColors.border),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '₦',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: VendorColors.textMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controllers[item],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  onChanged: (val) => setState(() {}),
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: VendorColors.textMain,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '—',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.only(right: 10, bottom: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: VendorButton(
                text: 'Save prices',
                onPressed: _savePrices,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
