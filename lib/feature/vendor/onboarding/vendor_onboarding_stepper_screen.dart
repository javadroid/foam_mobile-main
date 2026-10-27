import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/services/upload_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_pending_verification_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/app_fullscreen_loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class VendorOnboardingStepperScreen extends StatefulWidget {
  static const String id = '/vendor_onboarding_stepper';

  const VendorOnboardingStepperScreen({super.key});

  @override
  State<VendorOnboardingStepperScreen> createState() =>
      _VendorOnboardingStepperScreenState();
}

class _VendorOnboardingStepperScreenState
    extends State<VendorOnboardingStepperScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  int _currentStep = 0; // 0: Business Info, 1: Documents, 2: Payout Bank

  // Step 1 Controllers
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggedIn = false;

  // Step 2 Document Pickers
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingDoc = false;

  // Step 3 Bank Details
  PaystackBankModel? _selectedBank;
  final _accountNumberController = TextEditingController();
  bool _isResolvingAccount = false;
  String _resolvedAccountName = '';
  String? _resolveError;
  bool _isAgreed = false;

  bool _isSavingDraft = false;
  String? _stepError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDraft());
  }

  Future<void> _initDraft() async {
    final token = HiveClass.getToken();
    _isLoggedIn = token.isNotEmpty;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final vendor = Provider.of<VendorProvider>(context, listen: false);

    // Fetch fresh profile & saved draft from backend
    if (_isLoggedIn) {
      await vendor.fetchVendorProfile();
    }

    if (!mounted) return;

    // Prefill fields
    if (vendor.draftBusinessName.isNotEmpty) {
      _businessNameController.text = vendor.draftBusinessName;
    } else if (auth.businessName.isNotEmpty) {
      _businessNameController.text = auth.businessName;
    }

    if (vendor.draftOwnerName.isNotEmpty) {
      _ownerNameController.text = vendor.draftOwnerName;
    } else if (auth.firstName.isNotEmpty || auth.lastName.isNotEmpty) {
      _ownerNameController.text = '${auth.firstName} ${auth.lastName}'.trim();
    }

    if (vendor.draftPhone.isNotEmpty) {
      _phoneController.text = vendor.draftPhone;
    } else if (auth.phoneNumber.isNotEmpty) {
      _phoneController.text = auth.phoneNumber;
    }

    if (vendor.draftEmail.isNotEmpty) {
      _emailController.text = vendor.draftEmail;
    } else if (auth.email.isNotEmpty) {
      _emailController.text = auth.email;
    }

    // Step 3 prefill
    if (vendor.kycStatus.accountNumber.isNotEmpty) {
      _accountNumberController.text = vendor.kycStatus.accountNumber;
      _resolvedAccountName = vendor.kycStatus.accountName;
    }

    // Load banks for step 3
    final banks = await vendor.fetchPaystackBanks();
    if (mounted && banks.isNotEmpty) {
      if (vendor.kycStatus.bankCode.isNotEmpty) {
        _selectedBank = banks.firstWhere(
          (b) => b.code == vendor.kycStatus.bankCode,
          orElse: () => banks.first,
        );
      } else {
        _selectedBank = banks.firstWhere(
          (b) => b.name.toLowerCase().contains('guaranty') || b.code == '058',
          orElse: () => banks.first,
        );
      }
    }

    // Resume at appropriate step
    setState(() {
      _currentStep = vendor.onboardingStep;
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  String _parseApiError(http.Response res, {String fallback = 'An unexpected error occurred'}) {
    try {
      if (res.body.trim().isEmpty) {
        if (res.statusCode == 401) return 'Session expired. Please log in again.';
        if (res.statusCode == 403) return 'You do not have permission to perform this action.';
        if (res.statusCode == 404) return 'The requested endpoint was not found.';
        if (res.statusCode >= 500) return 'Server error (${res.statusCode}). Please try again shortly.';
        return fallback;
      }

      final body = res.body.trim();
      if (body.startsWith('<html') || body.startsWith('<!DOCTYPE')) {
        return 'Server error (${res.statusCode}). Please try again shortly.';
      }

      final dynamic data = jsonDecode(body);
      if (data is Map) {
        if (data['errors'] != null) {
          if (data['errors'] is List) {
            final list = (data['errors'] as List)
                .map((e) => e is Map ? (e['message'] ?? e['msg'] ?? e['error'] ?? '').toString() : e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
            if (list.isNotEmpty) return list.join('\n');
          } else if (data['errors'] is String) {
            return data['errors'].toString();
          }
        }
        if (data['error'] != null) {
          if (data['error'] is String && (data['error'] as String).trim().isNotEmpty) {
            return data['error'] as String;
          } else if (data['error'] is Map && data['error']['message'] != null) {
            return data['error']['message'].toString();
          }
        }
        if (data['message'] != null) {
          if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
            return data['message'] as String;
          } else if (data['message'] is List) {
            final list = (data['message'] as List)
                .map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
            if (list.isNotEmpty) return list.join('\n');
          }
        }
        if (data['msg'] != null && data['msg'].toString().trim().isNotEmpty) {
          return data['msg'].toString();
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    } catch (_) {}
    if (res.statusCode == 401) return 'Session expired. Please log in again.';
    if (res.statusCode >= 500) return 'Server error (${res.statusCode}). Please try again shortly.';
    return fallback;
  }

  String _parseException(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') || str.contains('network is unreachable') || str.contains('failed host lookup')) {
      return 'Unable to reach the server. Please check your internet connection.';
    }
    if (str.contains('timeoutexception') || str.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }
    if (str.contains('formatexception')) {
      return 'Received an invalid response from the server.';
    }
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  void _showSnack(String msg, {bool isError = false}) {
    final messenger = _scaffoldKey.currentState ?? ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline_rounded,
                color: Color(0xFFDC2626), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _stepError = null),
            child: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF991B1B)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraftAndExit() async {
    setState(() => _isSavingDraft = true);
    final vendor = Provider.of<VendorProvider>(context, listen: false);

    if (_isLoggedIn) {
      final success = await vendor.saveOnboardingDraft(
        businessName: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        isFinalSubmit: false,
      );
      if (!mounted) return;
      setState(() => _isSavingDraft = false);
      if (success) {
        _showSnack('Draft saved successfully.');
      } else {
        _showSnack(
          vendor.lastError ?? 'Draft saved locally.',
          isError: false,
        );
      }
    } else {
      if (!mounted) return;
      setState(() => _isSavingDraft = false);
      _showSnack('Draft saved. You can continue onboarding anytime.');
    }

    Navigator.pop(context);
  }

  // --- Step 1 Action ---
  Future<void> _handleStep1Submit() async {
    final businessName = _businessNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (businessName.isEmpty) {
      const err = 'Please enter your business name';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }
    if (ownerName.isEmpty) {
      const err = "Please enter the owner's full name";
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }
    if (phone.isEmpty) {
      const err = 'Please enter your phone number';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }

    if (!_isLoggedIn) {
      if (email.isEmpty || !email.contains('@')) {
        const err = 'Please enter a valid email address';
        setState(() => _stepError = err);
        _showSnack(err, isError: true);
        return;
      }
      if (password.length < 6) {
        const err = 'Password must be at least 6 characters';
        setState(() => _stepError = err);
        _showSnack(err, isError: true);
        return;
      }

      // Register new vendor account
      AppFullScreenLoader.show(
        context,
        message: 'Creating vendor account...',
        subtitle: 'Setting up your profile',
      );

      try {
        final names = ownerName.split(' ');
        final firstName = names.first;
        final lastName =
            names.length > 1 ? names.sublist(1).join(' ') : 'Vendor';

        final res = await http.post(
          Uri.parse('${Constants.url}/api/auth/register'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'phone': phone.startsWith('+234')
                ? phone
                : phone.startsWith('0')
                    ? '+234${phone.substring(1)}'
                    : '+234$phone',
            'password': password,
            'businessName': businessName,
            'role': 'VENDOR',
          }),
        );

        if (!mounted) return;
        AppFullScreenLoader.hide(context);

        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(res.body);
          if (data['token'] != null) {
            HiveClass.insertToken(data['token']);
            _isLoggedIn = true;
          }

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.fillAuth(
            firstName,
            lastName,
            '',
            email,
            phone,
            role: 'VENDOR',
            businessName: businessName,
            vendorStatus: 'PENDING',
          );

          setState(() {
            _stepError = null;
            _currentStep = 1;
          });
          _showSnack('Account created! Now upload verification documents.');
        } else {
          final errorMsg = _parseApiError(res, fallback: 'Registration failed. Please check your details.');
          setState(() => _stepError = errorMsg);
          _showSnack(errorMsg, isError: true);
        }
      } catch (e) {
        if (!mounted) return;
        AppFullScreenLoader.hide(context);
        final errorMsg = _parseException(e);
        setState(() => _stepError = errorMsg);
        _showSnack(errorMsg, isError: true);
      }
    } else {
      // Existing logged in user: save draft & advance to documents with error check
      AppFullScreenLoader.show(
        context,
        message: 'Saving business details...',
        subtitle: 'Updating your vendor draft',
      );

      final vendor = Provider.of<VendorProvider>(context, listen: false);
      final success = await vendor.saveOnboardingDraft(
        businessName: businessName,
        ownerName: ownerName,
        phone: phone,
      );

      if (!mounted) return;
      AppFullScreenLoader.hide(context);

      if (success) {
        setState(() {
          _stepError = null;
          _currentStep = 1;
        });
        _showSnack('Business details saved.');
      } else {
        final errorMsg = vendor.lastError ?? 'Failed to save business details. Please try again.';
        setState(() => _stepError = errorMsg);
        _showSnack(errorMsg, isError: true);
      }
    }
  }

  // --- Step 2 Action ---
  Future<void> _pickAndUploadDoc(String docType) async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() {
        _isUploadingDoc = true;
        _stepError = null;
      });

      final uploadUrl = await UploadService.uploadImage(File(file.path));

      if (!mounted) return;

      if (uploadUrl == null || uploadUrl.isEmpty) {
        setState(() => _isUploadingDoc = false);
        final err = 'Failed to upload ${file.name}. Please ensure file is valid and try again.';
        setState(() => _stepError = err);
        _showSnack(err, isError: true);
        return;
      }

      final vendor = Provider.of<VendorProvider>(context, listen: false);
      vendor.setKycDocument(docType, file.name, url: uploadUrl);

      // Save document link to backend draft
      final draftSaved = await vendor.saveOnboardingDraft();

      setState(() => _isUploadingDoc = false);
      if (draftSaved) {
        _showSnack('${file.name} uploaded and saved successfully');
      } else {
        _showSnack(
          'Document uploaded, but failed to sync: ${vendor.lastError ?? "Network error"}',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingDoc = false;
          _stepError = _parseException(e);
        });
      }
      _showSnack('Upload failed: ${_parseException(e)}', isError: true);
    }
  }

  void _handleStep2Submit() {
    final vendor = Provider.of<VendorProvider>(context, listen: false);
    final kyc = vendor.kycStatus;

    if (!kyc.cacUploaded &&
        !kyc.ownerIdUploaded &&
        !kyc.proofOfAddressUploaded) {
      const err = 'Please upload at least one document to proceed';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }

    setState(() {
      _stepError = null;
      _currentStep = 2;
    });
  }

  // --- Step 3 Action ---
  void _onAccountNumberChanged(String val) {
    if (_stepError != null) {
      setState(() => _stepError = null);
    }
    final clean = val.replaceAll(' ', '');
    if (clean.length == 10 && _selectedBank != null) {
      _resolveAccount(clean, _selectedBank!.code);
    } else {
      if (_resolvedAccountName.isNotEmpty ||
          _isResolvingAccount ||
          _resolveError != null) {
        setState(() {
          _isResolvingAccount = false;
          _resolvedAccountName = '';
          _resolveError = null;
        });
      }
    }
  }

  Future<void> _resolveAccount(String accNumber, String bankCode) async {
    setState(() {
      _isResolvingAccount = true;
      _resolvedAccountName = '';
      _resolveError = null;
    });

    final vendor = Provider.of<VendorProvider>(context, listen: false);
    final name = await vendor.resolvePaystackAccount(
      accountNumber: accNumber,
      bankCode: bankCode,
    );

    if (!mounted) return;

    if (name != null && name.isNotEmpty) {
      setState(() {
        _isResolvingAccount = false;
        _resolvedAccountName = name;
        _resolveError = null;
      });
    } else {
      final err = vendor.lastResolveError ?? 'Could not verify account details with Paystack. Please check the account number.';
      setState(() {
        _isResolvingAccount = false;
        _resolvedAccountName = '';
        _resolveError = err;
      });
    }
  }

  Future<void> _handleStep3Submit() async {
    final cleanAcc = _accountNumberController.text.replaceAll(' ', '');
    if (_selectedBank == null) {
      const err = 'Please select your payout bank';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }
    if (cleanAcc.length != 10) {
      const err = 'Please enter a valid 10-digit account number';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }
    if (_resolveError != null && _resolvedAccountName.isEmpty) {
      final err = _resolveError ?? 'Please verify your bank account details before submitting';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }
    if (!_isAgreed) {
      const err = 'Please agree to the vendor terms to proceed';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }

    AppFullScreenLoader.show(
      context,
      message: 'Submitting application...',
      subtitle: 'Sending your documents & bank details for verification',
    );

    final vendor = Provider.of<VendorProvider>(context, listen: false);
    final accountName = _resolvedAccountName.isNotEmpty
        ? _resolvedAccountName
        : 'Verified Account';

    vendor.setKycBank(
      bankName: _selectedBank!.name,
      accountNumber: cleanAcc,
      accountName: accountName,
    );
    vendor.kycStatus.bankCode = _selectedBank!.code;

    final success = await vendor.saveOnboardingDraft(
      isFinalSubmit: true,
    );

    if (!mounted) return;
    AppFullScreenLoader.hide(context);

    if (success) {
      _showSnack('Application submitted for review!');
      Navigator.pushReplacementNamed(
        context,
        VendorPendingVerificationScreen.id,
      );
    } else {
      final err = vendor.lastError ?? 'Submission failed. Please check your network and try again.';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
    }
  }

  void _showBankPickerSheet(List<PaystackBankModel> banks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BankPickerSheet(
        banks: banks,
        selectedBank: _selectedBank,
        onBankSelected: (bank) {
          setState(() => _selectedBank = bank);
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
    final vendor = Provider.of<VendorProvider>(context);

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: VendorColors.textMain, size: 20),
            onPressed: () {
              if (_currentStep > 0) {
                setState(() {
                  _stepError = null;
                  _currentStep--;
                });
              } else {
                _saveDraftAndExit();
              }
            },
          ),
          title: Text(
            'Vendor Onboarding',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: VendorColors.textMain,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSavingDraft ? null : _saveDraftAndExit,
              child: Text(
                'Save Draft',
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.primary,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Stepper Header
              _buildStepperHeader(),
              const Divider(height: 1, color: VendorColors.border),

              // Active Step Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_stepError != null) _buildErrorBanner(_stepError!),
                      _currentStep == 0
                          ? _buildStep1BusinessInfo()
                          : _currentStep == 1
                              ? _buildStep2Documents(vendor)
                              : _buildStep3PayoutBank(vendor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildStepIndicator(
                  stepIndex: 0,
                  title: 'Business Info',
                  isDone: _currentStep > 0),
              _buildStepConnector(isFilled: _currentStep > 0),
              _buildStepIndicator(
                  stepIndex: 1, title: 'Documents', isDone: _currentStep > 1),
              _buildStepConnector(isFilled: _currentStep > 1),
              _buildStepIndicator(
                  stepIndex: 2, title: 'Payout Bank', isDone: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepIndex,
    required String title,
    required bool isDone,
  }) {
    final isCurrent = _currentStep == stepIndex;
    return InkWell(
      onTap: () {
        // Allow going back to previous steps
        if (stepIndex < _currentStep) {
          setState(() {
            _stepError = null;
            _currentStep = stepIndex;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone
                  ? VendorColors.liveBg
                  : isCurrent
                      ? VendorColors.primary
                      : VendorColors.lightBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone
                    ? VendorColors.liveText
                    : isCurrent
                        ? VendorColors.primary
                        : VendorColors.border,
                width: 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check,
                      size: 16, color: VendorColors.liveText)
                  : Text(
                      '${stepIndex + 1}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            isCurrent ? Colors.white : VendorColors.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? VendorColors.textMain : VendorColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isFilled}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 18),
        color: isFilled ? VendorColors.primary : VendorColors.border,
      ),
    );
  }

  // ==========================================
  // STEP 1: BUSINESS & OWNER INFO
  // ==========================================
  Widget _buildStep1BusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your business',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: VendorColors.textMain,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isLoggedIn
              ? 'Your account details are linked. Update your business information below to continue.'
              : 'Create your vendor account to partner with Foam and list your laundry business.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: VendorColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        _buildTextField(
          controller: _businessNameController,
          label: 'Business Name',
          hint: 'e.g. CleanWave Laundromat',
          icon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _ownerNameController,
          label: "Owner's Full Name",
          hint: 'e.g. John Doe',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+234 801 234 5678',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Email: LOCKED if already logged in / continuing draft
        _buildTextField(
          controller: _emailController,
          label: _isLoggedIn
              ? 'Email Address (Locked to account)'
              : 'Email Address',
          hint: 'vendor@example.com',
          icon: Icons.email_outlined,
          readOnly: _isLoggedIn,
          suffixIcon: _isLoggedIn
              ? const Tooltip(
                  message: 'Email cannot be changed once linked to account',
                  child: Icon(Icons.lock_outline,
                      size: 18, color: VendorColors.textMuted),
                )
              : null,
          helperText:
              _isLoggedIn ? 'Your account email cannot be changed' : null,
        ),
        const SizedBox(height: 16),

        // Password: ONLY shown for brand new signup
        if (!_isLoggedIn) ...[
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: VendorColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: VendorColors.lightBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VendorColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded,
                    size: 18, color: VendorColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Logged in as an active Foam customer. Password is verified.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      color: VendorColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        VendorButton(
          text: 'Continue to Documents',
          onPressed: _handleStep1Submit,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: _saveDraftAndExit,
            icon: const Icon(Icons.bookmark_outline,
                size: 17, color: VendorColors.textMuted),
            label: Text(
              'Save as Draft & Finish Later',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VendorColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: BUSINESS DOCUMENTS (KYC)
  // ==========================================
  Widget _buildStep2Documents(VendorProvider vendor) {
    final kyc = vendor.kycStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Verification Documents',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: VendorColors.textMain,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Foam reviews every vendor for safety and compliance. Documents are safely saved to your draft.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: VendorColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildDocUploadCard(
          title: 'CAC Registration',
          subtitle: 'Company or business name certificate',
          isUploaded: kyc.cacUploaded,
          fileName: kyc.cacFileName,
          onUpload: () => _pickAndUploadDoc('CAC'),
        ),
        const SizedBox(height: 16),
        _buildDocUploadCard(
          title: "Owner's Valid ID",
          subtitle: 'NIN slip, Driver’s license, or Int’l passport',
          isUploaded: kyc.ownerIdUploaded,
          fileName: kyc.ownerIdFileName,
          onUpload: () => _pickAndUploadDoc('OWNER_ID'),
        ),
        const SizedBox(height: 16),
        _buildDocUploadCard(
          title: 'Proof of Business Address',
          subtitle: 'Recent utility bill or tenancy agreement',
          isUploaded: kyc.proofOfAddressUploaded,
          fileName: kyc.proofOfAddressFileName,
          onUpload: () => _pickAndUploadDoc('ADDRESS'),
        ),
        const SizedBox(height: 28),
        if (_isUploadingDoc)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Uploading document to Cloudinary...'),
                ],
              ),
            ),
          ),
        VendorButton(
          text: 'Continue to Payout Bank',
          onPressed: _isUploadingDoc ? null : _handleStep2Submit,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: _saveDraftAndExit,
            icon: const Icon(Icons.bookmark_outline,
                size: 17, color: VendorColors.textMuted),
            label: Text(
              'Save as Draft & Finish Later',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VendorColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocUploadCard({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required String fileName,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: VendorColors.lightBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUploaded
              ? VendorColors.primary.withValues(alpha: 0.4)
              : VendorColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUploaded
                  ? VendorColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUploaded ? VendorColors.primary : VendorColors.border,
              ),
            ),
            child: Icon(
              isUploaded
                  ? Icons.check_circle_rounded
                  : Icons.cloud_upload_outlined,
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
                    fontSize: 14.5,
                    color: VendorColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded && fileName.isNotEmpty ? fileName : subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color: isUploaded
                        ? VendorColors.primary
                        : VendorColors.textMuted,
                    fontWeight:
                        isUploaded ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUpload,
            child: Text(
              isUploaded ? 'Replace' : 'Upload',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: VendorColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: PAYOUT BANK DETAILS
  // ==========================================
  Widget _buildStep3PayoutBank(VendorProvider vendor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Up Payout Bank',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: VendorColors.textMain,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your earnings will be automatically transferred to this verified account.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: VendorColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        InkWell(
          onTap: () async {
            if (vendor.paystackBanks.isEmpty) {
              _showSnack('Loading banks...', isError: false);
              final fresh = await vendor.fetchPaystackBanks();
              if (!mounted) return;
              if (fresh.isEmpty) {
                _showSnack(
                  'Unable to load bank list. Please check your network and try again.',
                  isError: true,
                );
                return;
              }
              _showBankPickerSheet(fresh);
            } else {
              _showBankPickerSheet(vendor.paystackBanks);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: VendorColors.lightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VendorColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_outlined,
                    color: VendorColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Bank',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: VendorColors.textMuted,
                        ),
                      ),
                      Text(
                        _selectedBank?.name ?? 'Select Bank',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: VendorColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    color: VendorColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Account Number
        _buildTextField(
          controller: _accountNumberController,
          label: 'Account Number',
          hint: '0123456789',
          icon: Icons.numbers_outlined,
          keyboardType: TextInputType.number,
          onChanged: _onAccountNumberChanged,
        ),
        const SizedBox(height: 12),

        // Resolution Feedback
        if (_isResolvingAccount)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Verifying account with Paystack...'),
              ],
            ),
          )
        else if (_resolvedAccountName.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: VendorColors.liveBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: VendorColors.liveText.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: VendorColors.liveText, size: 18),
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
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _resolveError!,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Terms Agreement
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _isAgreed,
              onChanged: (val) => setState(() => _isAgreed = val ?? false),
              activeColor: VendorColors.primary,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'I agree to the Foam Vendor Terms of Service and acknowledge payout transfers are subject to platform review.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color: VendorColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        VendorButton(
          text: 'Submit Application for Review',
          onPressed: _handleStep3Submit,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: _saveDraftAndExit,
            icon: const Icon(Icons.bookmark_outline,
                size: 17, color: VendorColors.textMuted),
            label: Text(
              'Save as Draft & Finish Later',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VendorColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? helperText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: VendorColors.textMain,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF8FAFC) : VendorColors.lightBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: readOnly ? const Color(0xFFE2E8F0) : VendorColors.border,
            ),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: (val) {
              if (_stepError != null) {
                setState(() => _stepError = null);
              }
              onChanged?.call(val);
            },
            style: GoogleFonts.dmSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: readOnly ? const Color(0xFF64748B) : VendorColors.textMain,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                fontSize: 14,
                color: VendorColors.textMuted,
              ),
              prefixIcon: Icon(icon,
                  size: 20,
                  color: readOnly
                      ? const Color(0xFF94A3B8)
                      : VendorColors.textMuted),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: GoogleFonts.dmSans(
              fontSize: 11.5,
              color: VendorColors.textMuted,
            ),
          ),
        ],
      ],
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
  final _searchController = TextEditingController();
  List<PaystackBankModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.banks;
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = widget.banks
          .where((b) => b.name.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search Nigerian banks...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: VendorColors.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, idx) {
                final bank = _filtered[idx];
                final isSelected = widget.selectedBank?.code == bank.code;
                return ListTile(
                  title: Text(
                    bank.name,
                    style: GoogleFonts.dmSans(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? VendorColors.primary
                          : VendorColors.textMain,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: VendorColors.primary)
                      : null,
                  onTap: () {
                    widget.onBankSelected(bank);
                    Navigator.pop(context);
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
