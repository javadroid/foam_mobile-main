import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_pending_verification_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:foam_mobile/widgets/app_fullscreen_loader.dart';
import 'package:foam_mobile/widgets/app_skeleton_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorPayoutBankScreen extends StatefulWidget {
  static const String id = '/vendor_payout_bank';

  const VendorPayoutBankScreen({super.key});

  @override
  State<VendorPayoutBankScreen> createState() => _VendorPayoutBankScreenState();
}

class _VendorPayoutBankScreenState extends State<VendorPayoutBankScreen> {
  PaystackBankModel? _selectedBank;
  final TextEditingController _accountNumberController =
      TextEditingController();
  bool _isResolving = false;
  String _resolvedAccountName = '';
  String? _resolveError;
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VendorProvider>(context, listen: false);
      provider.fetchPaystackBanks().then((banks) {
        if (mounted && banks.isNotEmpty && _selectedBank == null) {
          // Default to Guaranty Trust Bank or first bank in list
          final gtBank = banks.firstWhere(
            (b) => b.name.toLowerCase().contains('guaranty') || b.code == '058',
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
      if (_resolvedAccountName.isNotEmpty || _isResolving || _resolveError != null) {
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
            'Could not verify account details with Paystack. Please check the account number and selected bank.';
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorProvider>(context);
    final banks = provider.paystackBanks;
    final isLoadingBanks = provider.isLoadingBanks;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VendorColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress: Step 2 of 2 (both filled)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: VendorColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: VendorColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Step 2 of 2',
                style: GoogleFonts.dmSans(
                  color: VendorColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Where should we pay you?',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Your earnings are withdrawn to this account. It must match your business or owner's name.",
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Bank Selector
              Text(
                'Select bank',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              if (isLoadingBanks && banks.isEmpty)
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: VendorColors.lightBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VendorColors.border),
                  ),
                  child: Row(
                    children: [
                      AppSkeletonLoader.box(width: 140, height: 16),
                      const Spacer(),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showBankPicker(context, banks),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: VendorColors.lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VendorColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedBank != null
                                ? _selectedBank!.name
                                : (banks.isNotEmpty ? 'Select a bank' : 'Loading banks...'),
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _selectedBank != null
                                  ? VendorColors.textMain
                                  : VendorColors.textMuted,
                            ),
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
              const SizedBox(height: 16),

              // Account Number Input
              Text(
                'Account number',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0123456789',
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Account Resolution State
              if (_isResolving)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: VendorColors.textMuted,
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
                    color: VendorColors.liveBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: VendorColors.liveText.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: VendorColors.liveText, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resolvedAccountName,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: VendorColors.liveText,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verified by Paystack',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                color: VendorColors.liveText.withValues(alpha: 0.8),
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
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _resolveError!,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Colors.redAccent,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Agreement text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isAgreed,
                    activeColor: VendorColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _isAgreed = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "By submitting, you agree to Foam's vendor terms, including the 15% platform commission on completed orders.",
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: VendorColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              VendorButton(
                text: 'Submit for review',
                onPressed: () async {
                  final cleanAcc =
                      _accountNumberController.text.replaceAll(' ', '');
                  if (_selectedBank == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select a bank from the list',
                          style:
                              GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }
                  if (cleanAcc.length != 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a valid 10-digit account number',
                          style:
                              GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }
                  if (!_isAgreed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please agree to the vendor terms to proceed',
                          style:
                              GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }

                  AppFullScreenLoader.show(
                    context,
                    message: 'Submitting payout bank...',
                    subtitle: 'Saving to your verified vendor profile',
                  );

                  final vendorProvider =
                      Provider.of<VendorProvider>(context, listen: false);

                  final accountName = _resolvedAccountName.isNotEmpty
                      ? _resolvedAccountName
                      : 'Verified Account';

                  final success = await vendorProvider.savePayoutBank(
                    bankName: _selectedBank!.name,
                    bankCode: _selectedBank!.code,
                    accountNumber: cleanAcc,
                    accountName: accountName,
                  );

                  if (!context.mounted) return;
                  AppFullScreenLoader.hide(context);

                  if (success) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const VendorPendingVerificationScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to save payout bank details. Please check your network and try again.',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
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

/// Searchable Bottom Sheet for 290+ Paystack Banks
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredBanks = widget.banks;
      } else {
        _filteredBanks = widget.banks
            .where((b) => b.name.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Bank',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: VendorColors.textMain,
                  ),
                ),
                Text(
                  '${widget.banks.length} Banks',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: VendorColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: VendorColors.lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VendorColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: VendorColors.textMain,
                ),
                decoration: InputDecoration(
                  hintText: 'Search bank name...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: VendorColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: VendorColors.textMuted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          // Bank list
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
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredBanks.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (ctx, i) {
                      final bank = _filteredBanks[i];
                      final isSelected = widget.selectedBank?.code == bank.code;

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        title: Text(
                          bank.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? VendorColors.primary
                                : VendorColors.textMain,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: VendorColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          widget.onBankSelected(bank);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
