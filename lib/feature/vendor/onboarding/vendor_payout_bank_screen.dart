import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_pending_verification_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorPayoutBankScreen extends StatefulWidget {
  static const String id = '/vendor_payout_bank';

  const VendorPayoutBankScreen({super.key});

  @override
  State<VendorPayoutBankScreen> createState() => _VendorPayoutBankScreenState();
}

class _VendorPayoutBankScreenState extends State<VendorPayoutBankScreen> {
  String _selectedBank = 'GTBank';
  final TextEditingController _accountNumberController =
      TextEditingController(text: '0123 454 821');
  bool _isResolving = false;
  String _resolvedAccountName = 'BRIGHT WASH LIMITED';
  bool _isAgreed = true;

  final List<String> _banks = [
    'GTBank',
    'Access Bank',
    'Zenith Bank',
    'First Bank of Nigeria',
    'UBA',
    'Kuda Bank',
    'Stanbic IBTC',
    'Fidelity Bank',
  ];

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  void _onAccountNumberChanged(String val) {
    if (val.replaceAll(' ', '').length == 10) {
      setState(() {
        _isResolving = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _isResolving = false;
            _resolvedAccountName = 'BRIGHT WASH LIMITED';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // Bank Dropdown
              Text(
                'Select bank',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBank,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: VendorColors.textMuted),
                    items: _banks.map((b) {
                      return DropdownMenuItem<String>(
                        value: b,
                        child: Text(
                          b,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: VendorColors.textMain,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBank = val);
                    },
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
                  border: Border.all(color: VendorColors.border),
                ),
                child: TextField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  onChanged: _onAccountNumberChanged,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0123456789',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Resolved Account Name Card
              if (_isResolving)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Verifying account name...'),
                    ],
                  ),
                )
              else if (_resolvedAccountName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: VendorColors.liveBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VendorColors.liveText.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: VendorColors.liveText, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _resolvedAccountName,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: VendorColors.liveText,
                          letterSpacing: 0.5,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) => setState(() => _isAgreed = v ?? true),
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
                onPressed: () {
                  final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
                  vendorProvider.setKycBank(
                    bankName: _selectedBank,
                    accountNumber: _accountNumberController.text.replaceAll(' ', ''),
                    accountName: _resolvedAccountName,
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorPendingVerificationScreen(),
                    ),
                  );
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
