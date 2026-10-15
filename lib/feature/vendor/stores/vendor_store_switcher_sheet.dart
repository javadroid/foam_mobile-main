import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorStoreSwitcherSheet extends StatelessWidget {
  const VendorStoreSwitcherSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const VendorStoreSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final stores = vendorProvider.stores;
    final currentStore = vendorProvider.currentStore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VendorColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Switch store',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: VendorColors.textMain,
            ),
          ),
          const SizedBox(height: 14),

          ...stores.map((store) {
            final isSelected = store.id == currentStore.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? VendorColors.draftBg : VendorColors.lightBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? VendorColors.primary
                      : VendorColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  vendorProvider.switchStore(store.id);
                  Navigator.pop(context);
                },
                title: Text(
                  store.name,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: VendorColors.textMain,
                  ),
                ),
                subtitle: Text(
                  store.isLive
                      ? '2 new · 5 active'
                      : store.isPaused
                          ? '1 active'
                          : 'Pricing incomplete',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: VendorColors.textMuted,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VendorStatusPill(status: store.status),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check, color: VendorColors.primary, size: 20),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VendorStoreDetailsScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: VendorColors.border,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: VendorColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add a store',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: VendorColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
