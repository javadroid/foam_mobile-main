import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/wallet/vendor_withdrawal_sent_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorWithdrawScreen extends StatefulWidget {
  const VendorWithdrawScreen({super.key});

  @override
  State<VendorWithdrawScreen> createState() => _VendorWithdrawScreenState();
}

class _VendorWithdrawScreenState extends State<VendorWithdrawScreen> {
  final TextEditingController _amountController = TextEditingController(text: '100000');
  final currencyFormatter = NumberFormat('#,###');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleWithdraw() {
    final provider = Provider.of<VendorProvider>(context, listen: false);
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    if (amount < 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal is ₦5,000')),
      );
      return;
    }

    if (amount > provider.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds available balance')),
      );
      return;
    }

    final ref = 'TRF_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final ok = provider.withdraw(amount, ref);

    if (ok) {
      final bankName = provider.kycStatus.bankName.isNotEmpty
          ? provider.kycStatus.bankName
          : 'GTBank';
      final acc = provider.kycStatus.accountNumber.isNotEmpty
          ? provider.kycStatus.accountNumber
          : '4821';
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
    final bankName = kyc.bankName.isNotEmpty ? kyc.bankName : 'GTBank';
    final acc = kyc.accountNumber.isNotEmpty ? kyc.accountNumber : '4821';
    final last4 = acc.length >= 4 ? acc.substring(acc.length - 4) : acc;
    final accName = kyc.accountName.isNotEmpty ? kyc.accountName : 'BRIGHT WASH LIMITED';

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
          'Withdraw',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: VendorColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 8),

              // Amount input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VendorColors.border),
                ),
                child: Row(
                  children: [
                    const Text(
                      '₦',
                      style: TextStyle(
                        fontSize: 22,
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
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: VendorColors.textMain,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available: ₦${currencyFormatter.format(available.toInt())}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: VendorColors.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _amountController.text = available.toInt().toString();
                    },
                    child: Text(
                      'Withdraw all',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Destination Bank Account
              Text(
                'To bank account',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 8),

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
                          bankName.length >= 2 ? bankName.substring(0, 2).toUpperCase() : 'GT',
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
                              fontSize: 12,
                              color: VendorColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Policy Details
              _buildInfoRow('Transfer fee', '₦50'),
              const Divider(height: 16, color: VendorColors.border),
              _buildInfoRow('Arrives', 'Within minutes'),
              const Divider(height: 16, color: VendorColors.border),
              _buildInfoRow('Minimum withdrawal', '₦5,000'),

              const Spacer(),

              VendorButton(
                text: 'Withdraw ₦${currencyFormatter.format(double.tryParse(_amountController.text) ?? 100000)}',
                onPressed: _handleWithdraw,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: VendorColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: VendorColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}
