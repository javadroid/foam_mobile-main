import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';
import 'package:foam_mobile/utils/values.dart';

class FoamPaymentSheet extends StatefulWidget {
  final String title;
  final String itemTitle;
  final String? itemSubtitle;
  final double amount;
  final String? cycleLabel; // e.g. "/ month"
  final FoamPaymentPurpose purpose;
  final dynamic plan;
  final bool noFolding;
  final String? storeId;
  final String? pickupAddress;
  final String? deliveryAddress;
  final DateTime? pickupDate;
  final String? pickupTime;
  final DateTime? deliveryDate;
  final String? deliveryTime;
  final Future<PaymentProcessResult> Function(FoamPaymentMethod method)?
      onProcessPayment;

  const FoamPaymentSheet({
    super.key,
    required this.title,
    required this.itemTitle,
    this.itemSubtitle,
    required this.amount,
    this.cycleLabel,
    required this.purpose,
    this.plan,
    this.noFolding = false,
    this.storeId,
    this.pickupAddress,
    this.deliveryAddress,
    this.pickupDate,
    this.pickupTime,
    this.deliveryDate,
    this.deliveryTime,
    this.onProcessPayment,
  });

  static Future<PaymentProcessResult?> show({
    required BuildContext context,
    required String title,
    required String itemTitle,
    String? itemSubtitle,
    required double amount,
    String? cycleLabel,
    required FoamPaymentPurpose purpose,
    dynamic plan,
    bool noFolding = false,
    String? storeId,
    String? pickupAddress,
    String? deliveryAddress,
    DateTime? pickupDate,
    String? pickupTime,
    DateTime? deliveryDate,
    String? deliveryTime,
    Future<PaymentProcessResult> Function(FoamPaymentMethod method)?
        onProcessPayment,
  }) {
    return showModalBottomSheet<PaymentProcessResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoamPaymentSheet(
        title: title,
        itemTitle: itemTitle,
        itemSubtitle: itemSubtitle,
        amount: amount,
        cycleLabel: cycleLabel,
        purpose: purpose,
        plan: plan,
        noFolding: noFolding,
        storeId: storeId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        pickupDate: pickupDate,
        pickupTime: pickupTime,
        deliveryDate: deliveryDate,
        deliveryTime: deliveryTime,
        onProcessPayment: onProcessPayment,
      ),
    );
  }

  @override
  State<FoamPaymentSheet> createState() => _FoamPaymentSheetState();
}

class _FoamPaymentSheetState extends State<FoamPaymentSheet> {
  late FoamPaymentMethod _selectedMethod;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Default smart selection based on platform: Google Pay on Android/default, Apple Pay on iOS
    _selectedMethod = Platform.isIOS
        ? FoamPaymentMethod.applePay
        : FoamPaymentMethod.googlePay;
  }

  String _getMethodName(FoamPaymentMethod method) {
    switch (method) {
      case FoamPaymentMethod.wallet:
        return 'Foam Wallet';
      case FoamPaymentMethod.paystack:
        return 'Paystack';
      case FoamPaymentMethod.googlePay:
        return 'Google Pay';
      case FoamPaymentMethod.applePay:
        return 'Apple Pay';
    }
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    PaymentProcessResult result;

    try {
      if (widget.onProcessPayment != null) {
        result = await widget.onProcessPayment!(_selectedMethod);
      } else if (widget.purpose == FoamPaymentPurpose.subscription) {
        result = await FoamPaymentService.processSubscription(
          context: context,
          plan: widget.plan,
          method: _selectedMethod,
        );
      } else if (widget.purpose == FoamPaymentPurpose.order) {
        result = await FoamPaymentService.processOrderPayment(
          context: context,
          noFolding: widget.noFolding,
          totalPrice: widget.amount,
          storeId: widget.storeId,
          method: _selectedMethod,
          pickupAddress: widget.pickupAddress,
          deliveryAddress: widget.deliveryAddress,
          pickupDate: widget.pickupDate,
          pickupTime: widget.pickupTime,
          deliveryDate: widget.deliveryDate,
          deliveryTime: widget.deliveryTime,
        );
      } else {
        result = await FoamPaymentService.processWalletDeposit(
          context: context,
          amount: widget.amount,
          method: _selectedMethod,
        );
      }
    } catch (e) {
      result = PaymentProcessResult(
          success: false, message: 'Payment processing error: $e');
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      // if (widget.itemTitle.isNotEmpty) ...[
                      //   const SizedBox(height: 4),
                      //   Text(
                      //     widget.itemTitle,
                      //     style: const TextStyle(
                      //       fontSize: 14,
                      //       fontWeight: FontWeight.w500,
                      //       color: Color(0xFF0098A6),
                      //     ),
                      //   ),
                      // ],
                      // if (widget.itemSubtitle != null) ...[
                      //   const SizedBox(height: 2),
                      //   Text(
                      //     widget.itemSubtitle!,
                      //     style: TextStyle(
                      //       fontSize: 12,
                      //       color: Colors.grey.shade600,
                      //     ),
                      //   ),
                      // ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed:
                      _isProcessing ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Price banner
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFF8FAFC),
            //     borderRadius: BorderRadius.circular(16),
            //     border: Border.all(color: const Color(0xFFE2E8F0)),
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       const Text(
            //         'Total Payable',
            //         style: TextStyle(
            //           fontSize: 14,
            //           fontWeight: FontWeight.w500,
            //           color: Color(0xFF64748B),
            //         ),
            //       ),
            //       Flexible(
            //         child: Row(
            //           mainAxisSize: MainAxisSize.min,
            //           crossAxisAlignment: CrossAxisAlignment.baseline,
            //           textBaseline: TextBaseline.alphabetic,
            //           children: [
            //             Flexible(
            //               child: Text(
            //                 '₦${widget.amount.toStringAsFixed(0)}',
            //                 style: const TextStyle(
            //                   fontSize: 22,
            //                   fontWeight: FontWeight.w800,
            //                   color: Color(0xFF0F172A),
            //                 ),
            //                 overflow: TextOverflow.ellipsis,
            //               ),
            //             ),
            //             if (widget.cycleLabel != null)
            //               Text(
            //                 ' ${widget.cycleLabel}',
            //                 style: const TextStyle(
            //                   fontSize: 13,
            //                   fontWeight: FontWeight.w500,
            //                   color: Color(0xFF64748B),
            //                 ),
            //               ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 20),

            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 12),

            // 1. Google Pay (highlighted on Android with official Google Pay Mark)
            _buildPaymentOptionTile(
              method: FoamPaymentMethod.googlePay,
              title: 'Google Pay',
              subtitle: 'Fast 1-tap checkout via Google Wallet',
              customIcon: SvgPicture.asset(
                'assets/images/google_pay_mark.svg',
                width: 54,
                height: 29,
                fit: BoxFit.contain,
              ),
              iconColor: Colors.transparent,
              iconBgColor: Colors.transparent,
            ),

            // 2. Apple Pay (highlighted on iOS)
            _buildPaymentOptionTile(
              method: FoamPaymentMethod.applePay,
              title: 'Apple Pay',
              subtitle: 'Instant authorization with Touch ID / Face ID',
              icon: Icons.apple,
              iconColor: Colors.black,
              iconBgColor: Colors.grey.shade200,
              badgeText: 'Pay',
              badgeColor: Colors.black87,
              badgeBgColor: Colors.grey.shade200,
            ),

            // 3. Paystack Checkout
            _buildPaymentOptionTile(
              method: FoamPaymentMethod.paystack,
              title: 'Paystack Checkout',
              subtitle: 'Debit Cards (Visa, Verve, Mastercard), Bank & USSD',
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFE0F2FE),
              badgeText: 'Cards/Bank',
              badgeColor: const Color(0xFF0369A1),
              badgeBgColor: const Color(0xFFE0F2FE),
            ),

            // 4. Foam Wallet (for orders and subscriptions)
            // if (widget.purpose != FoamPaymentPurpose.walletDeposit)
            //   _buildPaymentOptionTile(
            //     method: FoamPaymentMethod.wallet,
            //     title: 'Foam Wallet',
            //     subtitle: 'Instant deduction from your in-app wallet balance',
            //     icon: Icons.account_balance_wallet_rounded,
            //     iconColor: const Color(0xFF16A34A),
            //     iconBgColor: const Color(0xFFDCFCE7),
            //     badgeText: 'Instant',
            //     badgeColor: const Color(0xFF15803D),
            //     badgeBgColor: const Color(0xFFDCFCE7),
            //   ),

            const SizedBox(height: 22),

            // Dynamic CTA Action Button matching selected provider
            _buildCtaButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaButton() {
    final formattedAmount = NumberFormat('#,###').format(widget.amount);

    if (_selectedMethod == FoamPaymentMethod.googlePay) {
      // Official Google Pay pill button strictly complying with Google Pay Brand Guidelines
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          onPressed: _isProcessing ? null : _handlePayment,
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pay with ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SvgPicture.asset(
                      'assets/images/google.svg',
                      width: 19,
                      height: 19,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Pay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    if (_selectedMethod == FoamPaymentMethod.applePay) {
      // Official Apple Pay pill button
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          onPressed: _isProcessing ? null : _handlePayment,
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pay with ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.apple, color: Colors.white, size: 20),
                    SizedBox(width: 2),
                    Text(
                      'Pay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    // Paystack / Wallet
    final isWallet = _selectedMethod == FoamPaymentMethod.wallet;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isWallet ? const Color(0xFF16A34A) : AppColors.navyBlueAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isProcessing ? null : _handlePayment,
        child: _isProcessing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isWallet
                        ? Icons.account_balance_wallet_rounded
                        : Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Pay ₦$formattedAmount with ${_getMethodName(_selectedMethod)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required FoamPaymentMethod method,
    required String title,
    required String subtitle,
    IconData? icon,
    Widget? customIcon,
    required Color iconColor,
    required Color iconBgColor,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBgColor,
  }) {
    final isSelected = _selectedMethod == method;
    final isGooglePay = method == FoamPaymentMethod.googlePay;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isProcessing
            ? null
            : () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isGooglePay ? 54 : 42,
                height: isGooglePay ? 29 : 42,
                decoration: BoxDecoration(
                  color: isGooglePay ? Colors.transparent : iconBgColor,
                  shape: isGooglePay ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isGooglePay ? BorderRadius.circular(4) : null,
                ),
                child: Center(
                  child: customIcon ?? Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: badgeBgColor ?? const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: badgeColor ?? const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // const SizedBox(height: 3),
                    // Text(
                    //   subtitle,
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     color: Colors.grey.shade600,
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF16A34A)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  color:
                      isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
