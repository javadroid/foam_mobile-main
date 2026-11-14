import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/app_skeleton_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class VendorPricingItemsScreen extends StatefulWidget {
  final String serviceType;
  final String foldType;
  final String storeId;

  const VendorPricingItemsScreen({
    super.key,
    required this.storeId,
    required this.serviceType,
    this.foldType = 'Folding',
  });

  @override
  State<VendorPricingItemsScreen> createState() =>
      _VendorPricingItemsScreenState();
}

class _VendorPricingItemsScreenState extends State<VendorPricingItemsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _itemFolding = {};
  final List<String> _items = [];
  final Set<String> _removedItems = {};
  bool _isSaving = false;
  bool _isLoading = false;

  final List<String> _defaultLaundryItems = [
    'Shirt',
    'T-shirt',
    'Trouser',
    'Jeans',
    'Bedsheet',
    'Duvet',
    'Towel',
    'Native (agbada)',
  ];

  final List<String> _defaultDryCleaningItems = [
    'Suit (2-piece)',
    'Suit (3-piece)',
    'Blazer / Jacket',
    'Dress / Gown',
    'Evening Gown',
    'Winter Coat',
    'Silk / Delicate Top',
    'Agbada Complete',
  ];

  @override
  void initState() {
    super.initState();
    _initLocalItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPricingData();
    });
  }

  void _initLocalItems() {
    final provider = Provider.of<VendorProvider>(context, listen: false);
    final storeId = widget.storeId;

    final defaults = widget.serviceType == 'Dry cleaning'
        ? _defaultDryCleaningItems
        : _defaultLaundryItems;

    final removed = provider.getRemovedItems(storeId, widget.serviceType);
    _removedItems.addAll(removed);

    // Load custom items added previously
    final customItems = provider.getCustomItems(storeId, widget.serviceType);

    _items.clear();
    for (final def in defaults) {
      if (!_removedItems.contains(def)) {
        _items.add(def);
      }
    }
    for (final ci in customItems) {
      if (!_items.contains(ci) && !_removedItems.contains(ci)) {
        _items.add(ci);
      }
    }

    final existingPrices = provider.getItemPrices(
      storeId,
      widget.serviceType,
      widget.foldType,
    );

    for (final item in existingPrices.keys) {
      if (!_items.contains(item) && !_removedItems.contains(item)) {
        _items.add(item);
      }
    }

    for (final item in _items) {
      final price = existingPrices[item];
      _controllers[item] = TextEditingController(
        text: price != null ? price.toInt().toString() : '',
      );
      // By default folding is turned ON for each item unless explicitly toggled off
      _itemFolding[item] = provider.isItemFoldingIncluded(
        storeId,
        widget.serviceType,
        item,
      );
    }
  }

  Future<void> _loadPricingData() async {
    if (!mounted) return;
    final provider = Provider.of<VendorProvider>(context, listen: false);
    final targetStoreId = widget.storeId;
    debugPrint('Target store ID: ${targetStoreId}');

    setState(() => _isLoading = true);

    try {
      await provider.fetchFoamCommission();

      // 1. Fetch store catalog from /api/customer/stores/$targetStoreId
      List<dynamic> rawCatalogItems = [];
      try {
        final uriPrimary =
            Uri.parse('${Constants.url}/api/customer/stores/$targetStoreId');
        var res = await http.get(
          uriPrimary,
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['store'] != null && data['store']['items'] is List) {
            rawCatalogItems = data['store']['items'] as List;
          }
        }
      } catch (e) {
        debugPrint('Error fetching store customer catalog: $e');
        // Fallback to direct local port 8545
      }

      if (!mounted) return;

      final isDryCleaning = widget.serviceType == 'Dry cleaning';
      final defaults =
          isDryCleaning ? _defaultDryCleaningItems : _defaultLaundryItems;

      // Filter catalog items matching this screen's serviceType
      final matchingItems = <Map<String, dynamic>>[];
      final seenNames = <String>{};

      for (final raw in rawCatalogItems) {
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          final cat = (map['category'] ?? '').toString().toLowerCase();
          final matchesService = isDryCleaning
              ? (cat.contains('dry') || cat.contains('clean'))
              : (cat.contains('laundry') ||
                  (!cat.contains('dry') && !cat.contains('clean')));

          final name = (map['name'] ?? map['itemName'] ?? '').toString().trim();
          if (matchesService && name.isNotEmpty) {
            final lower = name.toLowerCase();
            // Deduplicate: if duplicate name exists, keep the first
            if (!seenNames.contains(lower)) {
              seenNames.add(lower);
              matchingItems.add(map);
            }
          }
        }
      }

      // IF EMPTY, SHOW THE DEFAULT
      if (matchingItems.isEmpty) {
        final removed =
            provider.getRemovedItems(targetStoreId, widget.serviceType);
        final activeDefaults =
            defaults.where((d) => !removed.contains(d)).toList();

        final existingPrices = provider.getItemPrices(
          targetStoreId,
          widget.serviceType,
          widget.foldType,
        );

        setState(() {
          _items.clear();
          _items.addAll(activeDefaults);

          for (final item in _items) {
            final price = existingPrices[item];
            if (_controllers.containsKey(item)) {
              if (_controllers[item]!.text.trim().isEmpty && price != null) {
                _controllers[item]!.text = price.toInt().toString();
              }
            } else {
              _controllers[item] = TextEditingController(
                text: price != null ? price.toInt().toString() : '',
              );
            }
            _itemFolding[item] = provider.isItemFoldingIncluded(
              targetStoreId,
              widget.serviceType,
              item,
            );
          }
        });
      } else {
        // USE THE FETCHED ITEMS FROM /api/customer/stores/$targetStoreId
        final newItems = <String>[];
        final newPrices = <String, double>{};
        final newFolding = <String, bool>{};

        for (final itemMap in matchingItems) {
          final name =
              (itemMap['name'] ?? itemMap['itemName'] ?? '').toString().trim();
          final priceNum = itemMap['price'];
          final price = (priceNum is num) ? priceNum.toDouble() : 0.0;
          final foldRaw = (itemMap['foldType'] ?? 'Folding').toString();
          final isFold = !foldRaw.toUpperCase().contains('NON') &&
              (foldRaw.toUpperCase().contains('FOLD') || foldRaw == 'Standard');

          newItems.add(name);
          newPrices[name] = price;
          newFolding[name] = isFold;

          // Update provider caches as well
          provider.setItemPrice(
              targetStoreId, widget.serviceType, 'Folding', name, price);
          provider.setItemPrice(
              targetStoreId, widget.serviceType, 'Non-folding', name, price);
          provider.setItemPrice(
              targetStoreId, widget.serviceType, 'Standard', name, price);
          provider.setItemFoldingIncluded(
              targetStoreId, widget.serviceType, name, isFold);
          if (!defaults.contains(name)) {
            provider.addCustomItem(targetStoreId, widget.serviceType, name);
          }
        }

        setState(() {
          _items.clear();
          _items.addAll(newItems);

          for (final item in _items) {
            final p = newPrices[item];
            final priceStr = (p != null && p > 0) ? p.toInt().toString() : '';
            if (_controllers.containsKey(item)) {
              _controllers[item]!.text = priceStr;
            } else {
              _controllers[item] = TextEditingController(text: priceStr);
            }
            _itemFolding[item] = newFolding[item] ?? true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading vendor pricing from customer store: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        .where((c) =>
            c.text.trim().isNotEmpty && double.tryParse(c.text.trim()) != null)
        .length;
  }

  bool _isDefaultItem(String item) {
    final defaults = widget.serviceType == 'Dry cleaning'
        ? _defaultDryCleaningItems
        : _defaultLaundryItems;
    return defaults.contains(item);
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    bool includeFolding = true; // Default ON as requested

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: VendorColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add Item with Price',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: VendorColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item Name',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: VendorColors.textMain,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Curtains, King Bedsheet, Hoodie',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: VendorColors.textMuted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: VendorColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: VendorColors.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Price per item (₦)',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Text(
                            '₦',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: VendorColors.textMuted,
                            ),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: '0',
                        hintStyle:
                            GoogleFonts.dmSans(color: VendorColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: VendorColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: VendorColors.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: includeFolding
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: includeFolding
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            includeFolding
                                ? Icons.checkroom_rounded
                                : Icons.checkroom_outlined,
                            color: includeFolding
                                ? const Color(0xFF16A34A)
                                : VendorColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Folding Service',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: VendorColors.textMain,
                                  ),
                                ),
                                Text(
                                  includeFolding
                                      ? 'Included without extra cost'
                                      : 'Optional for customer at checkout',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: includeFolding
                                        ? const Color(0xFF15803D)
                                        : VendorColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: includeFolding,
                            activeThumbColor: const Color(0xFF16A34A),
                            onChanged: (val) {
                              setDialogState(() {
                                includeFolding = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmSans(color: VendorColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VendorColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = priceController.text.trim();
                    if (name.isEmpty) return;

                    final provider =
                        Provider.of<VendorProvider>(context, listen: false);
                    final storeId = widget.storeId;

                    setState(() {
                      _removedItems.remove(name);
                      if (!_items.contains(name)) {
                        _items.add(name);
                      }
                      _controllers[name] = TextEditingController(text: price);
                      _itemFolding[name] = includeFolding;
                    });

                    provider.addCustomItem(storeId, widget.serviceType, name);
                    provider.setItemFoldingIncluded(
                        storeId, widget.serviceType, name, includeFolding);
                    if (price.isNotEmpty && double.tryParse(price) != null) {
                      provider.setItemPrice(
                        storeId,
                        widget.serviceType,
                        widget.foldType,
                        name,
                        double.parse(price),
                      );
                    }

                    Navigator.pop(dialogCtx);
                  },
                  child: Text(
                    'Add Item',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeItem(String item) {
    final provider = Provider.of<VendorProvider>(context, listen: false);
    final storeId = widget.storeId;

    setState(() {
      _items.remove(item);
      _controllers[item]?.dispose();
      _controllers.remove(item);
      _itemFolding.remove(item);
      _removedItems.add(item);
    });

    provider.removeStoreItem(storeId, widget.serviceType, item);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$item removed',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF00AABC),
          onPressed: () {
            setState(() {
              _removedItems.remove(item);
              if (!_items.contains(item)) {
                _items.add(item);
                _controllers[item] = TextEditingController();
                _itemFolding[item] = true;
              }
            });
            provider.unmarkItemRemoved(storeId, widget.serviceType, item);
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _restoreDefaults() {
    final provider = Provider.of<VendorProvider>(context, listen: false);
    final storeId = widget.storeId;
    final defaults = widget.serviceType == 'Dry cleaning'
        ? _defaultDryCleaningItems
        : _defaultLaundryItems;

    setState(() {
      for (final def in defaults) {
        _removedItems.remove(def);
        provider.unmarkItemRemoved(storeId, widget.serviceType, def);
        if (!_items.contains(def)) {
          _items.add(def);
          _controllers[def] = TextEditingController();
          _itemFolding[def] = true;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Default items restored',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCopyFromStoreDialog(VendorProvider vendor) {
    final otherStores =
        vendor.stores.where((s) => s.id != vendor.currentStore.id).toList();

    if (otherStores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need at least 2 store branches to copy items between stores.',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    String selectedStoreId = otherStores.first.id;
    bool isCopying = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: VendorColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Copy ${widget.serviceType} Prices',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: VendorColors.textMain,
                          ),
                        ),
                        Text(
                          'From another branch',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: VendorColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a branch to copy all ${widget.serviceType.toLowerCase()} items, prices, and folding settings to "${vendor.currentStore.name}":',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: VendorColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...otherStores.map((store) {
                      final isSelected = selectedStoreId == store.id;
                      final count = vendor
                          .getItemPrices(
                              store.id, widget.serviceType, widget.foldType)
                          .length;

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedStoreId = store.id;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? const Color(0xFF16A34A)
                                    : VendorColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.name,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: VendorColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      '${store.address.isNotEmpty ? store.address : "Store branch"} · ${count > 0 ? "$count priced items" : "Configured items"}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11.5,
                                        color: VendorColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCopying ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dmSans(color: VendorColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VendorColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isCopying
                      ? null
                      : () async {
                          setDialogState(() => isCopying = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final dialogNavigator = Navigator.of(dialogCtx);
                          final sourceStore = otherStores
                              .firstWhere((s) => s.id == selectedStoreId);

                          // Ensure source store pricing is loaded
                          await vendor.fetchStorePricing(
                            storeId: sourceStore.id,
                            serviceType: widget.serviceType,
                            silent: true,
                          );

                          if (!mounted) return;

                          final sourcePrices = vendor.getItemPrices(
                            sourceStore.id,
                            widget.serviceType,
                            widget.foldType,
                          );
                          final sourceCustom = vendor.getCustomItems(
                            sourceStore.id,
                            widget.serviceType,
                          );

                          final newItems = <String>[];
                          for (final k in sourcePrices.keys) {
                            if (!newItems.contains(k)) newItems.add(k);
                          }
                          for (final ci in sourceCustom) {
                            if (!newItems.contains(ci)) newItems.add(ci);
                          }

                          if (newItems.isEmpty) {
                            setDialogState(() => isCopying = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${sourceStore.name} has no pricing configured for ${widget.serviceType} yet.',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            dialogNavigator.pop();
                            return;
                          }

                          if (!mounted) return;

                          setState(() {
                            _removedItems.clear();
                            for (final c in _controllers.values) {
                              c.dispose();
                            }
                            _controllers.clear();
                            _itemFolding.clear();
                            _items.clear();
                            _items.addAll(newItems);

                            for (final item in _items) {
                              final price = sourcePrices[item];
                              _controllers[item] = TextEditingController(
                                text: price != null
                                    ? price.toInt().toString()
                                    : '',
                              );
                              _itemFolding[item] = vendor.isItemFoldingIncluded(
                                sourceStore.id,
                                widget.serviceType,
                                item,
                              );
                            }
                          });

                          dialogNavigator.pop();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Copied ${newItems.length} items from ${sourceStore.name}! Tap "Save prices" to save.',
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                  child: isCopying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Copy Items',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _savePrices() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<VendorProvider>(context, listen: false);
    final storeId = widget.storeId;

    final pricesMap = <String, double>{};
    for (final entry in _controllers.entries) {
      final p = double.tryParse(entry.value.text.trim());
      if (p != null) {
        pricesMap[entry.key] = p;
      }
    }

    await provider.saveStorePricing(
      storeId: storeId,
      serviceType: widget.serviceType,
      itemPrices: pricesMap,
      itemFolding: _itemFolding,
      deletedItems: _removedItems.toList(),
    );

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.serviceType} prices and folding options saved!',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vendor = Provider.of<VendorProvider>(context);
    final commission = vendor.foamCommissionPercentage;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.serviceType,
                          style: GoogleFonts.dmSans(
                            color: VendorColors.textMain,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.admin_panel_settings_outlined,
                                size: 13, color: VendorColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Foam: ${commission % 1 == 0 ? commission.toInt() : commission}% fee',
                              style: GoogleFonts.dmSans(
                                color: VendorColors.textMain,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.serviceType} · price per item & folding options',
                    style: GoogleFonts.dmSans(
                      color: VendorColors.textMuted,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info & Guidance banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: VendorColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Folding is enabled by default (no extra cost). Toggle off if you want folding to be an optional add-on for customers.',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              color: VendorColors.textMuted,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (vendor.stores.length > 1) ...[
                        InkWell(
                          onTap: () => _showCopyFromStoreDialog(vendor),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy_rounded,
                                    size: 14, color: VendorColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  'Copy from store',
                                  style: GoogleFonts.dmSans(
                                    color: VendorColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      InkWell(
                        onTap: _showAddItemDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add,
                                  size: 15, color: VendorColors.primary),
                              const SizedBox(width: 2),
                              Text(
                                'Add item',
                                style: GoogleFonts.dmSans(
                                  color: VendorColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: VendorColors.border),

            // Item cards list
            Expanded(
              child: (_isLoading &&
                      !vendor.hasPricingLoaded(
                          vendor.currentStore.id, widget.serviceType))
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 10.0),
                      itemCount: 6,
                      itemBuilder: (ctx, i) =>
                          AppSkeletonLoader.pricingItemCard(),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: VendorColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No items in this list',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: VendorColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'You removed all items. Add custom items or restore the default catalog.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: VendorColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _restoreDefaults,
                                      icon: const Icon(Icons.refresh_rounded,
                                          size: 16),
                                      label: const Text('Restore defaults'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: VendorColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: _showAddItemDialog,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add item'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: VendorColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 10.0),
                          itemCount: _items.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final item = _items[i];
                            final isCustom = !_isDefaultItem(item);
                            final isFolding = _itemFolding[item] ?? true;
                            final hasPrice =
                                _controllers[item]?.text.trim().isNotEmpty ==
                                        true &&
                                    double.tryParse(
                                            _controllers[item]?.text.trim() ??
                                                '') !=
                                        null;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasPrice
                                      ? VendorColors.primary
                                          .withValues(alpha: 0.35)
                                      : VendorColors.border,
                                  width: hasPrice ? 1.4 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row 1: Item Name & Price Input
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: VendorColors.textMain,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isCustom) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Custom',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        VendorColors.textMuted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(width: 4),
                                            // Delete icon button for ALL items (defaults & custom)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Color(0xFFEF4444),
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              tooltip: 'Remove item',
                                              onPressed: () =>
                                                  _removeItem(item),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 120,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: VendorColors.lightBg,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: hasPrice
                                                ? VendorColors.primary
                                                : VendorColors.border,
                                            width: hasPrice ? 1.4 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8.0),
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
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.right,
                                                onChanged: (val) =>
                                                    setState(() {}),
                                                style: GoogleFonts.dmSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                  color: VendorColors.textMain,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: '0',
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          right: 10, bottom: 8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),
                                  const Divider(
                                      height: 1, color: Color(0xFFF1F5F9)),
                                  const SizedBox(height: 6),

                                  // Row 2: Smaller compact Folding Service toggle
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              isFolding
                                                  ? Icons.check_circle_rounded
                                                  : Icons
                                                      .radio_button_unchecked_rounded,
                                              size: 13,
                                              color: isFolding
                                                  ? const Color(0xFF16A34A)
                                                  : VendorColors.textMuted,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isFolding
                                                  ? 'Folding included'
                                                  : 'Folding optional',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                fontWeight: isFolding
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isFolding
                                                    ? const Color(0xFF15803D)
                                                    : VendorColors.textMuted,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                isFolding
                                                    ? '· Included at no extra cost'
                                                    : '· Customer chooses at checkout',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 10,
                                                  color: VendorColors.textMuted,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        height: 18,
                                        width: 32,
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: Switch(
                                            value: isFolding,
                                            activeThumbColor:
                                                const Color(0xFF16A34A),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            onChanged: (val) {
                                              setState(() {
                                                _itemFolding[item] = val;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
              child: VendorButton(
                text: 'Save prices',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _savePrices,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
