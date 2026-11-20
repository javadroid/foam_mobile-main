import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  static const String id = '/payment/success';

  final String title;
  final String subtitle;
  final String itemTitle;
  final double amount;
  final String? paymentMethod;
  final String? reference;
  final List<MapEntry<String, String>> details;
  final VoidCallback? onPrimaryPressed;
  final String primaryButtonLabel;

  const PaymentSuccessScreen({
    super.key,
    this.title = 'Payment Successful! 🎉',
    this.subtitle = 'Your payment was processed and verified successfully.',
    required this.itemTitle,
    required this.amount,
    this.paymentMethod,
    this.reference,
    this.details = const [],
    this.onPrimaryPressed,
    this.primaryButtonLabel = 'View Subscription',
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = NumberFormat('#,###').format(amount);
    final nowFormatted =
        DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleClose(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 26, color: Color(0xFF64748B)),
                    onPressed: () => _handleClose(context),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Animated success badge
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F7F8),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFC5EFF3), width: 3),
                        ),
                        child: Center(
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00AABC), Color(0xFF0D9488)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Title
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // Receipt Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total Paid Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Amount Paid',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'CONFIRMED',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦$formattedAmount',
                              style: GoogleFonts.dmSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),

                            const Divider(height: 28, color: Color(0xFFE2E8F0)),

                            // Item / Plan Name
                            _buildReceiptRow('Plan / Service', itemTitle),

                            // Payment Method
                            if (paymentMethod != null &&
                                paymentMethod!.isNotEmpty)
                              _buildReceiptRow('Payment Method',
                                  _formatMethod(paymentMethod!)),

                            // Date & Time
                            _buildReceiptRow('Date & Time', nowFormatted),

                            // Reference
                            if (reference != null && reference!.isNotEmpty)
                              _buildReceiptRow('Reference', reference!),

                            // Custom details (quota, turnaround, etc.)
                            for (final detail in details)
                              _buildReceiptRow(detail.key, detail.value),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00AABC),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (onPrimaryPressed != null) {
                            onPrimaryPressed!();
                          } else {
                            _handleClose(context);
                          }
                        },
                        child: Text(
                          primaryButtonLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          MainScreen.id,
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Go to Dashboard',
                        style: GoogleFonts.dmSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleClose(BuildContext context) {
    if (onPrimaryPressed != null) {
      onPrimaryPressed!();
    } else {
      Navigator.pop(context);
    }
  }

  String _formatMethod(String method) {
    final upper = method.toUpperCase();
    if (upper.contains('GOOGLE')) return 'Google Pay';
    if (upper.contains('APPLE')) return 'Apple Pay';
    if (upper.contains('PAYSTACK')) return 'Paystack (Card/Bank)';
    if (upper.contains('WALLET')) return 'Foam Wallet';
    return method;
  }

  Widget _buildReceiptRow(String label, String value) {
    final isGooglePay = value.contains('Google Pay');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGooglePay) ...[
                  SvgPicture.asset(
                    'assets/images/google_pay_mark.svg',
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
