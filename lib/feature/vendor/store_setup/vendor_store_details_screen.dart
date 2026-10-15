import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_pricing_service_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorStoreDetailsScreen extends StatefulWidget {
  static const String id = '/vendor_store_details';

  const VendorStoreDetailsScreen({super.key});

  @override
  State<VendorStoreDetailsScreen> createState() => _VendorStoreDetailsScreenState();
}

class _VendorStoreDetailsScreenState extends State<VendorStoreDetailsScreen> {
  final _storeNameController = TextEditingController(text: 'Bright Wash · Lekki Phase 1');
  final _addressController =
      TextEditingController(text: '14 Admiralty Way, Lekki Phase 1');

  String _hoursMonFri = '7:00 AM – 7:00 PM';
  String _hoursSat = '8:00 AM – 5:00 PM';
  String _hoursSun = 'Closed';

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _editHoursDialog(String dayLabel, String currentVal, Function(String) onSave) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Operating Hours · $dayLabel',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g. 7:00 AM – 7:00 PM or Closed',
              hintStyle: GoogleFonts.dmSans(color: VendorColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(color: VendorColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(ctx);
              },
              child: Text(
                'Save',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Store Details',
          style: GoogleFonts.dmSans(
            color: VendorColors.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Store name & branch',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.border),
                ),
                child: TextField(
                  controller: _storeNameController,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: VendorColors.textMain,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Physical address',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.border),
                ),
                child: TextField(
                  controller: _addressController,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: VendorColors.textMain,
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined, color: VendorColors.primary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Geocoded Map Pin Card
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VendorColors.primary.withOpacity(0.3)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: VendorColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'map · geocoded pin',
                            style: GoogleFonts.dmSans(
                              color: VendorColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Drag the map to adjust pin. Customers see your store if they're within 5 km.",
                          style: GoogleFonts.dmSans(
                            color: VendorColors.textMuted,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Operating Hours Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Operating hours',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: VendorColors.textMain,
                    ),
                  ),
                  Text(
                    'Tap to edit',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildHoursRow(
                day: 'Mon – Fri',
                hours: _hoursMonFri,
                onTap: () => _editHoursDialog('Mon – Fri', _hoursMonFri, (val) {
                  setState(() => _hoursMonFri = val);
                }),
              ),
              const Divider(height: 16, color: VendorColors.border),
              _buildHoursRow(
                day: 'Saturday',
                hours: _hoursSat,
                onTap: () => _editHoursDialog('Saturday', _hoursSat, (val) {
                  setState(() => _hoursSat = val);
                }),
              ),
              const Divider(height: 16, color: VendorColors.border),
              _buildHoursRow(
                day: 'Sunday',
                hours: _hoursSun,
                isClosed: _hoursSun.toLowerCase() == 'closed',
                onTap: () => _editHoursDialog('Sunday', _hoursSun, (val) {
                  setState(() => _hoursSun = val);
                }),
              ),
              const SizedBox(height: 36),

              VendorButton(
                text: 'Save & set prices',
                onPressed: () {
                  final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
                  vendorProvider.updateStoreHours(
                    storeId: vendorProvider.currentStore.id,
                    monFri: _hoursMonFri,
                    sat: _hoursSat,
                    sun: _hoursSun,
                  );
                  vendorProvider.updateStoreAddress(
                    storeId: vendorProvider.currentStore.id,
                    address: _addressController.text,
                    lat: 6.4474,
                    lng: 3.4723,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorPricingServiceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoursRow({
    required String day,
    required String hours,
    bool isClosed = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              day,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: VendorColors.textMain,
              ),
            ),
            Row(
              children: [
                Text(
                  hours,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isClosed ? VendorColors.urgentText : VendorColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: VendorColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
