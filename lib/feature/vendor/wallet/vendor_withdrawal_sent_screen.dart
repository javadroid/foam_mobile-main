import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class VendorWithdrawalSentScreen extends StatelessWidget {
  final double amount;
  final String reference;
  final double newBalance;
  final String bankName;
  final String last4;

  const VendorWithdrawalSentScreen({
    super.key,
    required this.amount,
    required this.reference,
    required this.newBalance,
    required this.bankName,
    required this.last4,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
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
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '₦${currencyFormatter.format(amount.toInt())} is on its way',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sent to $bankName •••• $last4. Most transfers arrive within minutes.',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Receipt Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VendorColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reference',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: VendorColors.textMuted,
                          ),
                        ),
                        Text(
                          reference,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: VendorColors.textMain,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: VendorColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New balance',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: VendorColors.textMuted,
                          ),
                        ),
                        Text(
                          '₦${currencyFormatter.format(newBalance.toInt())}',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: VendorColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              VendorButton(
                text: 'Back to wallet',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
