import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_payout_bank_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class VendorDocumentsScreen extends StatefulWidget {
  static const String id = '/vendor_documents';

  const VendorDocumentsScreen({super.key});

  @override
  State<VendorDocumentsScreen> createState() => _VendorDocumentsScreenState();
}

class _VendorDocumentsScreenState extends State<VendorDocumentsScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDocument(String docType) async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null && mounted) {
        final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
        vendorProvider.setKycDocument(docType, file.name);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final kyc = vendorProvider.kycStatus;

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
              // Progress indicator: Step 1 of 2
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
                        color: VendorColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Step 1 of 2',
                style: GoogleFonts.dmSans(
                  color: VendorColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Verify your business',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMain,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload clear photos or PDFs. Foam reviews every vendor for safety.',
                style: GoogleFonts.dmSans(
                  color: VendorColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // CAC Registration
              _buildDocItem(
                title: 'CAC registration',
                subtitle: kyc.cacUploaded
                    ? (kyc.cacFileName.isNotEmpty
                        ? kyc.cacFileName
                        : 'cac-certificate.pdf · 1.2 MB')
                    : 'Company registration certificate',
                isUploaded: kyc.cacUploaded,
                onAction: () => _pickDocument('CAC'),
              ),
              const SizedBox(height: 16),

              // Owner's ID
              _buildDocItem(
                title: "Owner's ID",
                subtitle: kyc.ownerIdUploaded
                    ? (kyc.ownerIdFileName.isNotEmpty
                        ? kyc.ownerIdFileName
                        : 'NIN slip · front.jpg')
                    : 'National ID, Driver’s license, or Passport',
                isUploaded: kyc.ownerIdUploaded,
                onAction: () => _pickDocument('OWNER_ID'),
              ),
              const SizedBox(height: 16),

              // Proof of address
              _buildDocItem(
                title: 'Proof of address',
                subtitle: kyc.proofOfAddressUploaded
                    ? (kyc.proofOfAddressFileName.isNotEmpty
                        ? kyc.proofOfAddressFileName
                        : 'utility-bill.pdf · 850 KB')
                    : 'Utility bill or tenancy, last 3 months',
                isUploaded: kyc.proofOfAddressUploaded,
                onAction: () => _pickDocument('ADDRESS'),
              ),

              const Spacer(),

              VendorButton(
                text: 'Continue',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorPayoutBankScreen(),
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

  Widget _buildDocItem({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: VendorColors.lightBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUploaded ? VendorColors.primary.withOpacity(0.3) : VendorColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFFE0F7F6) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUploaded ? VendorColors.primary : VendorColors.border,
              ),
            ),
            child: Icon(
              isUploaded ? Icons.check : Icons.add,
              color: isUploaded ? VendorColors.primary : VendorColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: VendorColors.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: VendorColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              isUploaded ? 'Replace' : 'Upload',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: VendorColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
