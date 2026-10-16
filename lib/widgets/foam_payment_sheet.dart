import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';
import 'package:foam_mobile/feature/wallet/controller/wallet_provider.dart';
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
  final int? storeId;

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
    int? storeId,
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
    // Default smart selection based on platform
    if (widget.purpose == FoamPaymentPurpose.walletDeposit) {
      _selectedMethod = Platform.isIOS ? FoamPaymentMethod.applePay : (Platform.isAndroid ? FoamPaymentMethod.googlePay : FoamPaymentMethod.paystack);
    } else {
      _selectedMethod = FoamPaymentMethod.wallet;
    }
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
      if (widget.purpose == FoamPaymentPurpose.subscription) {
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
        );
      } else {
        result = await FoamPaymentService.processWalletDeposit(
          context: context,
          amount: widget.amount,
          method: _selectedMethod,
        );
      }
    } catch (e) {
      result = PaymentProcessResult(success: false, message: 'Payment failed: $e');
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      if (result.success) {
        Navigator.pop(context, result);
      } else if (result.insufficientWallet) {
        // Prompt user to switch to Paystack / GPay / Apple Pay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.orange.shade800,
            action: SnackBarAction(
              label: 'Pay via Card',
              textColor: Colors.white,
              onPressed: () {
                setState(() => _selectedMethod = FoamPaymentMethod.paystack);
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final walletBalance = walletProvider.balance;
    final hasSufficientWallet = walletBalance >= widget.amount;
    final shortfall = widget.amount - walletBalance;

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
                    const SizedBox(height: 4),
                    Text(
                      widget.itemTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0098A6),
                      ),
                    ),
                    if (widget.itemSubtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.itemSubtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Price banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₦${widget.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (widget.cycleLabel != null)
                      Text(
                        ' ${widget.cycleLabel}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Choose Payment Method',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),

          // 1. Foam Wallet (not shown for wallet deposit itself)
          if (widget.purpose != FoamPaymentPurpose.walletDeposit)
            _buildPaymentOptionTile(
              method: FoamPaymentMethod.wallet,
              title: 'Foam In-App Wallet',
              subtitle: hasSufficientWallet
                  ? 'Balance: ₦${walletBalance.toStringAsFixed(0)}'
                  : 'Balance: ₦${walletBalance.toStringAsFixed(0)} (Shortfall: ₦${shortfall.toStringAsFixed(0)})',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF0098A6),
              iconBgColor: const Color(0xFFE0F7FA),
              badgeText: hasSufficientWallet ? 'Instant' : 'Low Balance',
              badgeColor: hasSufficientWallet ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
              badgeBgColor: hasSufficientWallet ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
            ),

          // 2. Paystack
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

          // 3. Google Pay (highlighted on Android)
          _buildPaymentOptionTile(
            method: FoamPaymentMethod.googlePay,
            title: 'Google Pay',
            subtitle: 'Fast 1-tap checkout via Google Wallet',
            icon: Icons.g_mobiledata_rounded,
            iconColor: const Color(0xFF1A73E8),
            iconBgColor: const Color(0xFFE8F0FE),
            badgeText: 'Google Pay',
            badgeColor: const Color(0xFF1A73E8),
            badgeBgColor: const Color(0xFFE8F0FE),
          ),

          // 4. Apple Pay (highlighted on iOS)
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

          const SizedBox(height: 22),

          // CTA Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyBlueAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isProcessing ? null : _handlePayment,
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pay ₦${widget.amount.toStringAsFixed(0)} with ${_getMethodName(_selectedMethod)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required FoamPaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
  }) {
    final isSelected = _selectedMethod == method;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isProcessing ? null : () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
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
                    color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
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
