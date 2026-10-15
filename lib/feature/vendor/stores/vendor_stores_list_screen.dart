import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/stores/vendor_manage_store_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorStoresListScreen extends StatelessWidget {
  const VendorStoresListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorProvider>(context);
    final stores = provider.stores;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Stores',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: VendorColors.textMain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18, color: VendorColors.primary),
              label: Text(
                'Add',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: VendorColors.primary,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VendorStoreDetailsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          itemCount: stores.length,
          itemBuilder: (ctx, i) {
            final store = stores[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VendorColors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorManageStoreScreen(store: store),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            store.name,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: VendorColors.textMain,
                            ),
                          ),
                          VendorStatusPill(status: store.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        store.isLive
                            ? '${store.address} · Open until 7 PM'
                            : store.isPaused
                                ? '${store.address} · Hidden from customers'
                                : store.address,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: VendorColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (!store.isDraft) ...[
                            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${store.rating} rating',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: VendorColors.textMain,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: VendorColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Text(
                            store.isDraft
                                ? 'Finish pricing (${store.itemsPricedCount} of ${store.totalItems}) →'
                                : '${store.itemsPricedCount} items priced',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: store.isDraft ? VendorColors.primary : VendorColors.textMuted,
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
        ),
      ),
    );
  }
}
