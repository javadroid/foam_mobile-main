import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';

enum PaymentSheetStep {
  methods,
  summary,
}

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
  final PaymentSheetStep initialStep;

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
    this.initialStep = PaymentSheetStep.methods,
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
    PaymentSheetStep initialStep = PaymentSheetStep.methods,
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
        initialStep: initialStep,
      ),
    );
  }

  @override
  State<FoamPaymentSheet> createState() => _FoamPaymentSheetState();
}

class _FoamPaymentSheetState extends State<FoamPaymentSheet> {
  late PaymentSheetStep _currentStep;
  late FoamPaymentMethod _selectedMethod;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
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
        return 'Paystack Checkout';
      case FoamPaymentMethod.googlePay:
        return 'Google Pay';
      case FoamPaymentMethod.applePay:
        return 'Apple Pay';
    }
  }

  Future<void> _handlePaymentFor(FoamPaymentMethod method) async {
    if (_isProcessing) return;
    setState(() {
      _selectedMethod = method;
      _isProcessing = true;
    });

    PaymentProcessResult result;

    try {
      if (widget.onProcessPayment != null) {
        result = await widget.onProcessPayment!(method);
      } else if (widget.purpose == FoamPaymentPurpose.subscription) {
        result = await FoamPaymentService.processSubscription(
          context: context,
          plan: widget.plan,
          method: method,
        );
      } else if (widget.purpose == FoamPaymentPurpose.order) {
        result = await FoamPaymentService.processOrderPayment(
          context: context,
          noFolding: widget.noFolding,
          totalPrice: widget.amount,
          storeId: widget.storeId,
          method: method,
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
          method: method,
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
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _currentStep == PaymentSheetStep.methods
              ? _buildMethodsView()
              : _buildSummaryView(),
        ),
      ),
    );
  }

  /// Screen 1: Payment Method Selection Screen (Clean, compliant with Google Brand Guidelines)
  Widget _buildMethodsView() {
    return Column(
      key: const ValueKey('methods_view'),
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

        // Header: "Choose Payment Method" + close button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Choose Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 1. Google Pay (highlighted with official Google Pay Mark badge, height matched to other brand marks)
        _buildMethodTile(
          method: FoamPaymentMethod.googlePay,
          title: 'Google Pay',
          customIcon: SvgPicture.asset(
            'assets/images/google_pay_mark.svg',
            width: 72,
            height: 38,
            fit: BoxFit.contain,
          ),
          onTap: () {
            setState(() {
              _selectedMethod = FoamPaymentMethod.googlePay;
              _currentStep = PaymentSheetStep.summary;
            });
          },
        ),

        // 2. Apple Pay
        _buildMethodTile(
          method: FoamPaymentMethod.applePay,
          title: 'Apple Pay',
          customIcon: Container(
            width: 52,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.apple, color: Colors.black, size: 24),
            ),
          ),
          onTap: () {
            setState(() {
              _selectedMethod = FoamPaymentMethod.applePay;
              _currentStep = PaymentSheetStep.summary;
            });
          },
        ),

        // 3. Paystack Checkout
        _buildMethodTile(
          method: FoamPaymentMethod.paystack,
          title: 'Paystack Checkout',
          customIcon: Container(
            width: 52,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.credit_card_rounded,
                  color: Color(0xFF0284C7), size: 24),
            ),
          ),
          onTap: () {
            setState(() {
              _selectedMethod = FoamPaymentMethod.paystack;
              _currentStep = PaymentSheetStep.summary;
            });
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMethodTile({
    required FoamPaymentMethod method,
    required String title,
    required Widget customIcon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isProcessing ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              customIcon,
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Screen 2: Pre-Purchase / Order Summary Screen (Matches Google Guidelines "Your Order" diagram)
  Widget _buildSummaryView() {
    final formattedAmount = NumberFormat('#,###').format(widget.amount);
    final rawFeatures =
        (widget.plan is Map ? widget.plan['features'] : null) as List? ?? [];
    final features = rawFeatures.map((e) => e.toString()).toList();

    return Column(
      key: const ValueKey('summary_view'),
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

        // Header: Back button + "Order Summary" + close button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Color(0xFF0F172A)),
              onPressed: _isProcessing
                  ? null
                  : () => setState(
                      () => _currentStep = PaymentSheetStep.methods),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Order details card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.itemTitle.isNotEmpty) ...[
                Text(
                  widget.itemTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
              if (widget.itemSubtitle != null &&
                  widget.itemSubtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  widget.itemSubtitle!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (features.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                ...features.take(3).map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: Color(0xFF00AABC),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Total Payable',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            '₦$formattedAmount',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
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
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Selected Payment Method with CHANGE button (matches Google Brand Guidelines example)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _buildSelectedMethodIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getMethodName(_selectedMethod),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: _isProcessing
                    ? null
                    : () =>
                        setState(() => _currentStep = PaymentSheetStep.methods),
                child: const Text(
                  'CHANGE',
                  style: TextStyle(
                    color: Color(0xFF00AABC),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // CTA Button
        _buildCtaButton(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSelectedMethodIcon() {
    switch (_selectedMethod) {
      case FoamPaymentMethod.googlePay:
        return SvgPicture.asset(
          'assets/images/google_pay_mark.svg',
          width: 60,
          height: 32,
          fit: BoxFit.contain,
        );
      case FoamPaymentMethod.applePay:
        return Container(
          width: 44,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.apple, color: Colors.black, size: 20),
          ),
        );
      case FoamPaymentMethod.paystack:
      case FoamPaymentMethod.wallet:
        return Container(
          width: 44,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.credit_card_rounded,
                color: Color(0xFF0284C7), size: 20),
          ),
        );
    }
  }

  Widget _buildCtaButton() {
    final formattedAmount = NumberFormat('#,###').format(widget.amount);

    if (_selectedMethod == FoamPaymentMethod.googlePay) {
      // Official Google Pay button complying strictly with Google Pay Brand Guidelines
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          onPressed: _isProcessing
              ? null
              : () => _handlePaymentFor(FoamPaymentMethod.googlePay),
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
                      'assets/images/google_pay_button_lockup.svg',
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
        ),
      );
    }

    if (_selectedMethod == FoamPaymentMethod.applePay) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          onPressed: _isProcessing
              ? null
              : () => _handlePaymentFor(FoamPaymentMethod.applePay),
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
                    Icon(Icons.apple, color: Colors.white, size: 22),
                    Text(
                      'Pay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    // Paystack Button
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00AABC),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _isProcessing
            ? null
            : () => _handlePaymentFor(FoamPaymentMethod.paystack),
        child: _isProcessing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Pay ₦$formattedAmount',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
