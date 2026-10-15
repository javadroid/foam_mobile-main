import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/services/upload_service.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
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
  bool _isUploading = false;
  bool _isSubmitting = false;

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool _isDocUploaded(VendorKycStatus kyc, String docType) {
    if (docType == 'CAC') return kyc.cacUploaded && kyc.cacFileName.isNotEmpty;
    if (docType == 'OWNER_ID') return kyc.ownerIdUploaded && kyc.ownerIdFileName.isNotEmpty;
    if (docType == 'ADDRESS') return kyc.proofOfAddressUploaded && kyc.proofOfAddressFileName.isNotEmpty;
    return false;
  }

  Future<void> _executePick(String docType, ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _isUploading = true;
        });

        final length = await file.length();
        final sizeStr = _formatFileSize(length);
        final displayName = sizeStr.isNotEmpty ? '${file.name} · $sizeStr' : file.name;

        // Upload to backend Cloudinary service
        final uploadUrl = await UploadService.uploadImage(File(file.path));

        if (!mounted) return;
        final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
        vendorProvider.setKycDocument(docType, displayName, url: uploadUrl);

        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadUrl != null
                  ? '$displayName uploaded successfully'
                  : '$displayName attached',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: uploadUrl != null ? const Color(0xFF10B981) : Colors.black87,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking or uploading file: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to process file: $e',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showDocumentOptions(String docType, String docTitle) {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final isUploaded = _isDocUploaded(vendorProvider.kycStatus, docType);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  isUploaded ? 'Update $docTitle' : 'Upload $docTitle',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: VendorColors.textMain,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: VendorColors.primary),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: VendorColors.textMain,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _executePick(docType, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: VendorColors.primary),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: VendorColors.textMain,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _executePick(docType, ImageSource.camera);
                },
              ),
              if (isUploaded)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text(
                    'Remove Document',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    vendorProvider.removeKycDocument(docType);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final kyc = vendorProvider.kycStatus;

    final hasCac = kyc.cacUploaded && kyc.cacFileName.isNotEmpty;
    final hasOwnerId = kyc.ownerIdUploaded && kyc.ownerIdFileName.isNotEmpty;
    final hasAddress = kyc.proofOfAddressUploaded && kyc.proofOfAddressFileName.isNotEmpty;

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
                subtitle: hasCac
                    ? kyc.cacFileName
                    : 'Company registration certificate',
                isUploaded: hasCac,
                onAction: () => _showDocumentOptions('CAC', 'CAC Registration'),
              ),
              const SizedBox(height: 16),

              // Owner's ID
              _buildDocItem(
                title: "Owner's ID",
                subtitle: hasOwnerId
                    ? kyc.ownerIdFileName
                    : 'National ID, Driver’s license, or Passport',
                isUploaded: hasOwnerId,
                onAction: () => _showDocumentOptions('OWNER_ID', "Owner's ID"),
              ),
              const SizedBox(height: 16),

              // Proof of address
              _buildDocItem(
                title: 'Proof of address',
                subtitle: hasAddress
                    ? kyc.proofOfAddressFileName
                    : 'Utility bill or tenancy, last 3 months',
                isUploaded: hasAddress,
                onAction: () => _showDocumentOptions('ADDRESS', 'Proof of Address'),
              ),

              const Spacer(),

              VendorButton(
                text: 'Continue',
                isLoading: _isSubmitting || _isUploading,
                onPressed: (_isSubmitting || _isUploading)
                    ? null
                    : () async {
                        if (!hasCac || !hasOwnerId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please upload your CAC registration and Owner\'s ID to proceed',
                                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isSubmitting = true;
                        });

                        final success = await vendorProvider.submitKyc();

                        if (!mounted) return;
                        setState(() {
                          _isSubmitting = false;
                        });

                        if (!context.mounted) return;

                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to submit documents. Please verify your connection and try again.',
                                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          return;
                        }

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
          color: isUploaded ? VendorColors.primary.withValues(alpha: 0.3) : VendorColors.border,
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
                    color: isUploaded ? VendorColors.primary : VendorColors.textMuted,
                    fontWeight: isUploaded ? FontWeight.w500 : FontWeight.normal,
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
