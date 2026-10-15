import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorApprovedScreen extends StatelessWidget {
  static const String id = '/vendor_approved';

  const VendorApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final vendorProvider = Provider.of<VendorProvider>(context);
    final businessName = authProvider.businessName.isNotEmpty
        ? authProvider.businessName
        : 'Your business';
    final bankName = vendorProvider.kycStatus.bankName.isNotEmpty
        ? vendorProvider.kycStatus.bankName
        : 'your payout bank';
    final accNum = vendorProvider.kycStatus.accountNumber;
    final last4 = accNum.length >= 4 ? accNum.substring(accNum.length - 4) : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: VendorColors.liveBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: VendorColors.liveText,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$businessName is verified',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your wallet is ready and payouts go to $bankName${last4.isNotEmpty ? " •••• $last4" : ""}.',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Steps cards
              _buildCheckStep(
                number: '1',
                title: 'Add store address & hours',
                subtitle: 'Pin your physical location for riders and customers',
              ),
              const SizedBox(height: 16),
              _buildCheckStep(
                number: '2',
                title: 'Set your prices',
                subtitle: 'Customize rates for laundry and dry cleaning',
              ),
              const SizedBox(height: 16),
              _buildCheckStep(
                number: '3',
                title: 'Go live',
                subtitle: 'Start receiving incoming orders from nearby customers',
              ),

              const Spacer(),

              VendorButton(
                text: 'Create your first store',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorStoreDetailsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckStep({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorColors.lightBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: VendorColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: VendorColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }
}
