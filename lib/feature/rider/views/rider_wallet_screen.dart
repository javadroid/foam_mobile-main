import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';

class RiderWalletScreen extends StatefulWidget {
  static const String id = '/rider/wallet';
  const RiderWalletScreen({super.key});

  @override
  State<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends State<RiderWalletScreen> {
  final currencyFormatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RiderProvider>(context, listen: false).fetchWallet();
    });
  }

  void _openWithdrawalBottomSheet(RiderProvider provider) {
    final amountController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();
    String selectedBank = 'Access Bank';
    final banks = [
      'Access Bank',
      'GTBank (Guaranty Trust)',
      'Zenith Bank',
      'United Bank for Africa (UBA)',
      'First Bank of Nigeria',
      'Kuda Microfinance Bank',
      'OPay Digital Services',
      'Moniepoint Microfinance',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Withdraw Earnings',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF212828),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Available Balance: ₦${currencyFormatter.format(provider.walletBalance)}',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF00AABC),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Amount Input
              Text('Withdrawal Amount (₦)', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '5000',
                  prefixText: '₦ ',
                  suffixIcon: TextButton(
                    onPressed: () {
                      setModalState(() {
                        amountController.text = provider.walletBalance.toInt().toString();
                      });
                    },
                    child: Text('MAX', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: const Color(0xFF00AABC))),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),

              // Bank Name Dropdown
              Text('Select Destination Bank', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedBank,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: banks.map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.dmSans()))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedBank = val);
                },
              ),
              const SizedBox(height: 14),

              // Account Number
              Text('Account Number (10 Digits)', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: accountNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '0123456789',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),

              // Account Name
              Text('Account Name', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: accountNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Emeka Okafor',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Payout Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AABC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    final accountNum = accountNumberController.text.trim();
                    final accountName = accountNameController.text.trim();

                    if (amount <= 0 || amount > provider.walletBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount within balance')),
                      );
                      return;
                    }
                    if (accountNum.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid 10-digit account number')),
                      );
                      return;
                    }
                    if (accountName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter account name')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    final ok = await provider.requestWithdrawal(
                      amount: amount,
                      bankName: selectedBank,
                      accountNumber: accountNum,
                      accountName: accountName,
                    );

                    if (!mounted) return;
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Withdrawal request submitted successfully!'),
                          backgroundColor: Color(0xFF21CAAD),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage ?? 'Withdrawal failed'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Confirm Payout Request',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RiderProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Rider Wallet & Payouts',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212828),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212828)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF00AABC),
          onRefresh: () async => provider.fetchWallet(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Wallet Balance Hero Card
                _buildWalletHeroCard(provider),
                const SizedBox(height: 24),

                // 2. Transaction History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaction History',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212828),
                      ),
                    ),
                    Text(
                      '${provider.transactions.length} Records',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (provider.isLoading && provider.transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: Color(0xFF00AABC)),
                    ),
                  )
                else if (provider.transactions.isEmpty)
                  _buildEmptyTransactions()
                else
                  ...provider.transactions.map((tx) => _buildTransactionCard(tx)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletHeroCard(RiderProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00AABC), Color(0xFF007A87)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AABC).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Rider Balance',
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.shield_outlined, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₦${currencyFormatter.format(provider.walletBalance)}',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00AABC),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _openWithdrawalBottomSheet(provider),
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              label: Text(
                'Withdraw to Bank Account',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(RiderTransactionItem tx) {
    final isCredit = tx.type.toUpperCase() == 'CREDIT';
    final formattedDate = DateFormat('MMM dd, yyyy · hh:mm a').format(tx.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFE5FBF7) : const Color(0xFFFFF0F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? const Color(0xFF21CAAD) : Colors.redAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: GoogleFonts.dmSans(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'} ₦${currencyFormatter.format(tx.amount)}',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCredit ? const Color(0xFF21CAAD) : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tx.status == 'COMPLETED'
                      ? const Color(0xFFE5FBF7)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tx.status,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: tx.status == 'COMPLETED'
                        ? const Color(0xFF21CAAD)
                        : const Color(0xFFFFA000),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            'No Transactions Found',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Credits from completed rides and withdrawal payout debits will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
