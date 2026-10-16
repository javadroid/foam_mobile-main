import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_payout_bank_screen.dart';
import 'package:foam_mobile/feature/vendor/wallet/vendor_withdrawal_sent_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorWithdrawScreen extends StatefulWidget {
  const VendorWithdrawScreen({super.key});

  @override
  State<VendorWithdrawScreen> createState() => _VendorWithdrawScreenState();
}

class _VendorWithdrawScreenState extends State<VendorWithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat('#,###');
  bool _isSubmitting = false;

  final List<int> _quickAmounts = [5000, 10000, 20000, 50000];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _enteredAmount {
    final cleaned = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<void> _handleWithdraw() async {
    final provider = Provider.of<VendorProvider>(context, listen: false);
    final kyc = provider.kycStatus;
    final amount = _enteredAmount;

    if (kyc.bankName.isEmpty || kyc.accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add your payout bank account before withdrawing.',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Add Bank',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VendorPayoutBankScreen(),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    if (amount < 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum withdrawal is ₦5,000',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (amount > provider.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount exceeds available balance',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final ref =
        'TRF_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Persist to backend if online
    try {
      final token = HiveClass.getToken();
      if (token.isNotEmpty) {
        await http.post(
          Uri.parse('${Constants.url}/api/vendor/wallet/withdraw'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'amount': amount,
            'reference': ref,
          }),
        ).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Backend withdraw call notice: $e');
    }

    final ok = provider.withdraw(amount, ref);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      final bankName = kyc.bankName.isNotEmpty ? kyc.bankName : 'Bank';
      final acc = kyc.accountNumber;
      final last4 = acc.length >= 4 ? acc.substring(acc.length - 4) : acc;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VendorWithdrawalSentScreen(
            amount: amount,
            reference: ref,
            newBalance: provider.availableBalance,
            bankName: bankName,
            last4: last4,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorProvider>(context);
    final available = provider.availableBalance;
    final kyc = provider.kycStatus;
    final hasBank = kyc.bankName.isNotEmpty && kyc.accountNumber.isNotEmpty;
    final bankName = kyc.bankName;
    final acc = kyc.accountNumber;
    final last4 = acc.length >= 4 ? acc.substring(acc.length - 4) : acc;
    final accName = kyc.accountName;

    final amount = _enteredAmount;
    final bool isValidAmount = amount >= 5000 && amount <= available;
    final double netAmount = amount > 50 ? amount - 50 : 0.0;

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
          'Withdraw Earnings',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: VendorColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available to withdraw',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${_currencyFormatter.format(available.toInt())}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        _amountController.text = available.toInt().toString();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          'Withdraw all',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Amount',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 8),

              // Amount Input
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: amount > available
                        ? const Color(0xFFEF4444)
                        : VendorColors.border,
                    width: amount > available ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '₦',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: VendorColors.textMain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.dmSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: VendorColors.textMain,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '5,000',
                          hintStyle: GoogleFonts.dmSans(
                            color: VendorColors.textMuted.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    if (_amountController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: VendorColors.textMuted,
                        onPressed: () => _amountController.clear(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Quick Amount Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((qAmount) {
                  final isSelected = amount == qAmount;
                  return InkWell(
                    onTap: () {
                      _amountController.text = qAmount.toString();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VendorColors.primary.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? VendorColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '₦${_currencyFormatter.format(qAmount)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? VendorColors.primary
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // Destination Bank Account Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Destination bank account',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.textMain,
                    ),
                  ),
                  if (hasBank)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VendorPayoutBankScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Change',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: VendorColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Bank Account Card
              if (hasBank)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VendorColors.lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VendorColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VendorColors.border),
                        ),
                        child: Center(
                          child: Text(
                            bankName.length >= 2
                                ? bankName.substring(0, 2).toUpperCase()
                                : 'BK',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              color: VendorColors.primary,
                              fontSize: 16,
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
                              '$bankName •••• $last4',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: VendorColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              accName,
                              style: GoogleFonts.dmSans(
                                fontSize: 12.5,
                                color: VendorColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981), size: 20),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorPayoutBankScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_outlined,
                            color: Color(0xFFD97706), size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No Payout Bank Linked',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Add your verified Nigerian bank account to withdraw',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Add Bank',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Fee Breakdown Table
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Transfer fee', '₦50'),
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _buildInfoRow('Settlement speed', 'Within minutes'),
                    const Divider(height: 14, color: Color(0xFFE2E8F0)),
                    _buildInfoRow('Minimum withdrawal', '₦5,000'),
                    if (amount >= 5000) ...[
                      const Divider(height: 14, color: Color(0xFFCBD5E1)),
                      _buildInfoRow(
                        'Net amount to receive',
                        '₦${_currencyFormatter.format(netAmount.toInt())}',
                        isHighlight: true,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              VendorButton(
                text: _isSubmitting
                    ? 'Processing...'
                    : (amount <= 0
                        ? 'Enter an amount'
                        : (amount < 5000
                            ? 'Min. withdrawal is ₦5,000'
                            : (amount > available
                                ? 'Insufficient balance'
                                : 'Withdraw ₦${_currencyFormatter.format(amount.toInt())}'))),
                isLoading: _isSubmitting,
                onPressed: (!hasBank || !isValidAmount || _isSubmitting)
                    ? null
                    : _handleWithdraw,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: isHighlight ? 13.5 : 13,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight ? VendorColors.textMain : VendorColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: isHighlight ? 15 : 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
              color: isHighlight ? VendorColors.primary : VendorColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}
