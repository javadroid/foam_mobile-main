import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
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
        : (vendorProvider.currentStore.name.isNotEmpty
            ? vendorProvider.currentStore.name
            : 'Bright Wash');

    final bankName = vendorProvider.kycStatus.bankName.isNotEmpty
        ? vendorProvider.kycStatus.bankName
        : 'GTBank';

    final accNum = vendorProvider.kycStatus.accountNumber;
    final last4 =
        accNum.length >= 4 ? accNum.substring(accNum.length - 4) : '4821';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 36.0, 16.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 88px Teal Check Circle
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFF00AABC),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '✓',
                  style: GoogleFonts.dmSans(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                '$businessName is verified',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF212828),
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Your wallet is ready and payouts go to $bankName •••• $last4. Next, set up your first branch so customers can find you.',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF5E5E5E),
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),

              // 3 Steps (#E5F7F8 container)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildStepRow(
                      number: '1',
                      title: 'Add branch address & hours',
                      hasDivider: true,
                    ),
                    _buildStepRow(
                      number: '2',
                      title: 'Set your prices',
                      hasDivider: true,
                    ),
                    _buildStepRow(
                      number: '3',
                      title: 'Go live',
                      hasDivider: false,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Gradient CTA: Create your first branch
              Container(
                width: double.infinity,
                height: 53,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00AABC),
                      Color(0xFFC5EFF3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const VendorStoreDetailsScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        'Create your first branch',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.44,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required bool hasDivider,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        border: hasDivider
            ? const Border(
                bottom: BorderSide(
                  color: Color(0xFFC5EFF3),
                  width: 0.8,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Text(
            number,
            style: GoogleFonts.dmMono(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF00AABC),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF212828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
