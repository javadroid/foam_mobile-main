import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorBankSettingsScreen extends StatefulWidget {
  static const String id = '/vendor_bank_settings';

  const VendorBankSettingsScreen({super.key});

  @override
  State<VendorBankSettingsScreen> createState() =>
      _VendorBankSettingsScreenState();
}

class _VendorBankSettingsScreenState extends State<VendorBankSettingsScreen> {
  PaystackBankModel? _selectedBank;
  final TextEditingController _accountNumberController =
      TextEditingController();
  bool _isResolving = false;
  String _resolvedAccountName = '';
  String? _resolveError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VendorProvider>(context, listen: false);
      provider.fetchPaystackBanks().then((banks) {
        if (!mounted || banks.isEmpty) return;

        final kyc = provider.kycStatus;
        if (kyc.bankName.isNotEmpty) {
          final matched = banks.firstWhere(
            (b) =>
                b.name.toLowerCase() == kyc.bankName.toLowerCase() ||
                (kyc.bankCode.isNotEmpty && b.code == kyc.bankCode),
            orElse: () => banks.first,
          );
          setState(() {
            _selectedBank = matched;
          });
        } else {
          // Default to GTBank or first bank
          final gtBank = banks.firstWhere(
            (b) =>
                b.name.toLowerCase().contains('guaranty') || b.code == '058',
            orElse: () => banks.first,
          );
          setState(() {
            _selectedBank = gtBank;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  void _onAccountNumberChanged(String val) {
    final clean = val.replaceAll(' ', '');
    if (clean.length == 10 && _selectedBank != null) {
      _resolveAccount(clean, _selectedBank!.code);
    } else {
      if (_resolvedAccountName.isNotEmpty ||
          _isResolving ||
          _resolveError != null) {
        setState(() {
          _isResolving = false;
          _resolvedAccountName = '';
          _resolveError = null;
        });
      }
    }
  }

  Future<void> _resolveAccount(String accountNumber, String bankCode) async {
    setState(() {
      _isResolving = true;
      _resolvedAccountName = '';
      _resolveError = null;
    });

    final provider = Provider.of<VendorProvider>(context, listen: false);
    final accountName = await provider.resolvePaystackAccount(
      accountNumber: accountNumber,
      bankCode: bankCode,
    );

    if (!mounted) return;

    if (accountName != null && accountName.isNotEmpty) {
      setState(() {
        _isResolving = false;
        _resolvedAccountName = accountName;
        _resolveError = null;
      });
    } else {
      setState(() {
        _isResolving = false;
        _resolvedAccountName = '';
        _resolveError =
            'Could not verify account details. Please check the account number and selected bank.';
      });
    }
  }

  void _showBankPicker(BuildContext context, List<PaystackBankModel> banks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BankPickerSheet(
        banks: banks,
        selectedBank: _selectedBank,
        onBankSelected: (bank) {
          setState(() {
            _selectedBank = bank;
          });
          final clean = _accountNumberController.text.replaceAll(' ', '');
          if (clean.length == 10) {
            _resolveAccount(clean, bank.code);
          }
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    final cleanAcc = _accountNumberController.text.replaceAll(' ', '').trim();
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your bank from the list',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (cleanAcc.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid 10-digit NUBAN account number',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_resolvedAccountName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait for account name verification to complete',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<VendorProvider>(context, listen: false);

    final success = await provider.savePayoutBank(
      bankName: _selectedBank!.name,
      bankCode: _selectedBank!.code,
      accountNumber: cleanAcc,
      accountName: _resolvedAccountName,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payout bank account updated successfully!',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.lastError ??
                'Failed to update payout bank. Please try again.',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorProvider>(context);
    final banks = provider.paystackBanks;
    final kyc = provider.kycStatus;
    final bool hasExistingBank =
        kyc.bankName.isNotEmpty && kyc.accountNumber.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VendorColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payout Bank Account',
          style: GoogleFonts.dmSans(
            color: VendorColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Current Verified Bank Card (if configured)
              if (hasExistingBank) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: VendorColors.primary.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VendorColors.primary.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  VendorColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: VendorColors.primary,
                              size: 22,
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
                                        kyc.bankName,
                                        style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: VendorColors.textMain,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFDCFCE7)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons.check_circle_rounded,
                                              size: 11,
                                              color: Color(0xFF16A34A)),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Active',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF15803D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '•••• ${kyc.accountNumber.length >= 4 ? kyc.accountNumber.substring(kyc.accountNumber.length - 4) : kyc.accountNumber}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: VendorColors.textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (kyc.accountName.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(
                            height: 1,
                            thickness: 0.6,
                            color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: VendorColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                kyc.accountName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: VendorColors.textMain,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 2. Form Section Header
              Text(
                hasExistingBank
                    ? 'Update Payout Bank'
                    : 'Link Your Payout Bank',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter your verified Nigerian bank details. Your wallet withdrawals will be sent directly to this account.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: VendorColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Bank Selector
              Text(
                'Select Bank',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: provider.isLoadingBanks
                    ? null
                    : () => _showBankPicker(context, banks),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VendorColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: VendorColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          size: 18,
                          color: VendorColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedBank?.name ??
                              (provider.isLoadingBanks
                                  ? 'Loading bank directory...'
                                  : 'Select Bank'),
                          style: GoogleFonts.dmSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _selectedBank != null
                                ? VendorColors.textMain
                                : VendorColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: VendorColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 10-Digit Account Number
              Text(
                'NUBAN Account Number',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _resolveError != null
                        ? Colors.redAccent.withValues(alpha: 0.6)
                        : VendorColors.border,
                  ),
                ),
                child: TextField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  onChanged: _onAccountNumberChanged,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: VendorColors.textMain,
                  ),
                  decoration: InputDecoration(
                    hintText: '0123456789',
                    hintStyle: GoogleFonts.dmSans(
                      color: VendorColors.textMuted.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Paystack Live Verification Status
              if (_isResolving)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: VendorColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: VendorColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VendorColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Verifying account via Paystack...',
                        style: GoogleFonts.dmSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: VendorColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_resolvedAccountName.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Account Holder',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _resolvedAccountName,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (_resolveError != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _resolveError!,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: const Color(0xFFB91C1C),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Save Action Button
              VendorButton(
                text: hasExistingBank
                    ? 'Update Bank Details'
                    : 'Save Payout Bank',
                isLoading: _isSaving,
                onPressed: _isResolving ||
                        _resolvedAccountName.isEmpty ||
                        _accountNumberController.text.trim().length != 10
                    ? null
                    : _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankPickerSheet extends StatefulWidget {
  final List<PaystackBankModel> banks;
  final PaystackBankModel? selectedBank;
  final ValueChanged<PaystackBankModel> onBankSelected;

  const _BankPickerSheet({
    required this.banks,
    required this.selectedBank,
    required this.onBankSelected,
  });

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<PaystackBankModel> _filteredBanks = [];

  @override
  void initState() {
    super.initState();
    _filteredBanks = widget.banks;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = widget.banks;
      } else {
        _filteredBanks = widget.banks
            .where((b) => b.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Bank',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: VendorColors.textMain,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: VendorColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VendorColors.border),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search,
                      size: 20, color: VendorColors.textMuted),
                  hintText: 'Search Nigerian banks...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: VendorColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredBanks.isEmpty
                ? Center(
                    child: Text(
                      'No matching banks found',
                      style: GoogleFonts.dmSans(
                        color: VendorColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredBanks.length,
                    itemBuilder: (ctx, i) {
                      final bank = _filteredBanks[i];
                      final isSelected = widget.selectedBank?.code == bank.code;

                      return ListTile(
                        onTap: () {
                          widget.onBankSelected(bank);
                          Navigator.pop(context);
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? VendorColors.primary
                                : VendorColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            size: 16,
                            color:
                                isSelected ? Colors.white : VendorColors.primary,
                          ),
                        ),
                        title: Text(
                          bank.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? VendorColors.primary
                                : VendorColors.textMain,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: VendorColors.primary, size: 20)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
