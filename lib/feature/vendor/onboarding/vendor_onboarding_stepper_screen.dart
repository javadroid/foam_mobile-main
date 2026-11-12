import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/services/upload_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_pending_verification_screen.dart';
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
    try {
      if (Hive.isBoxOpen('foam')) {
        final token = HiveClass.getToken();
        _isLoggedIn = token.isNotEmpty;
      }
    } catch (_) {
      _isLoggedIn = false;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final vendor = Provider.of<VendorProvider>(context, listen: false);

    // Fetch fresh profile & saved draft from backend
    if (_isLoggedIn) {
      await vendor.fetchVendorProfile();
    }

    if (!mounted) return;

    // Prefill fields from draft or auth profile
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

    final phone =
        vendor.draftPhone.isNotEmpty ? vendor.draftPhone : auth.phoneNumber;
    if (phone.isNotEmpty) {
      if (phone.startsWith('+234')) {
        _phoneController.text = phone.substring(4);
      } else if (phone.startsWith('0')) {
        _phoneController.text = phone.substring(1);
      } else {
        _phoneController.text = phone;
      }
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

  String _parseApiError(http.Response res,
      {String fallback = 'An unexpected error occurred'}) {
    try {
      if (res.body.trim().isEmpty) {
        if (res.statusCode == 401) {
          return 'Session expired. Please log in again.';
        }
        if (res.statusCode == 403) {
          return 'You do not have permission to perform this action.';
        }
        if (res.statusCode == 404) {
          return 'The requested endpoint was not found.';
        }
        if (res.statusCode >= 500) {
          return 'Server error (${res.statusCode}). Please try again shortly.';
        }
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
                .map((e) => e is Map
                    ? (e['message'] ?? e['msg'] ?? e['error'] ?? '').toString()
                    : e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
            if (list.isNotEmpty) return list.join('\n');
          } else if (data['errors'] is String) {
            return data['errors'].toString();
          }
        }
        if (data['error'] != null) {
          if (data['error'] is String &&
              (data['error'] as String).trim().isNotEmpty) {
            return data['error'] as String;
          } else if (data['error'] is Map && data['error']['message'] != null) {
            return data['error']['message'].toString();
          }
        }
        if (data['message'] != null) {
          if (data['message'] is String &&
              (data['message'] as String).trim().isNotEmpty) {
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
    if (res.statusCode >= 500) {
      return 'Server error (${res.statusCode}). Please try again shortly.';
    }
    return fallback;
  }

  String _parseException(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('network is unreachable') ||
        str.contains('failed host lookup')) {
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
    final messenger =
        _scaffoldKey.currentState ?? ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
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
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF00AABC),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
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

    final rawPhone = _phoneController.text.trim();
    final formattedPhone = rawPhone.isNotEmpty
        ? (rawPhone.startsWith('+234')
            ? rawPhone
            : rawPhone.startsWith('0')
                ? '+234${rawPhone.substring(1)}'
                : '+234$rawPhone')
        : '';

    if (_isLoggedIn) {
      final success = await vendor.saveOnboardingDraft(
        businessName: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: formattedPhone,
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
    final rawPhone = _phoneController.text.trim();
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
    if (rawPhone.isEmpty) {
      const err = 'Please enter your phone number';
      setState(() => _stepError = err);
      _showSnack(err, isError: true);
      return;
    }

    final phone = rawPhone.startsWith('+234')
        ? rawPhone
        : rawPhone.startsWith('0')
            ? '+234${rawPhone.substring(1)}'
            : '+234$rawPhone';

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
            'phone': phone,
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
          final errorMsg = _parseApiError(res,
              fallback: 'Registration failed. Please check your details.');
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
        final errorMsg = vendor.lastError ??
            'Failed to save business details. Please try again.';
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
        final err =
            'Failed to upload ${file.name}. Please ensure file is valid and try again.';
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
      final err = vendor.lastResolveError ??
          'Could not verify account details with Paystack. Please check the account number.';
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
      final err = _resolveError ??
          'Please verify your bank account details before submitting';
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
      final err = vendor.lastError ??
          'Submission failed. Please check your network and try again.';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          setState(() {
            _stepError = null;
            _currentStep--;
          });
        } else {
          _saveDraftAndExit();
        }
      },
      child: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Top bar with back navigation & Save Draft action
                _buildTopBar(),

                // Active Step Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
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
      ),
    );
  }

  // ==========================================
  // TOP APP BAR
  // ==========================================
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF212828),
              size: 20,
            ),
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
          TextButton(
            onPressed: _isSavingDraft ? null : _saveDraftAndExit,
            child: Text(
              'Save Draft',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00AABC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2-SEGMENT PROGRESS BAR (Steps 1 & 2)
  // ==========================================
  Widget _buildFigmaProgressBar({required int activeStep}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF00AABC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: activeStep >= 2
                  ? const Color(0xFF00AABC)
                  : const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 1: BUSINESS & OWNER INFO (Figma 170:4202)
  // ==========================================
  Widget _buildStep1BusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand tag
        Text(
          'FOAM FOR BUSINESS',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF00AABC),
            letterSpacing: 1.12,
          ),
        ),
        const SizedBox(height: 8),

        // Title
        Text(
          'Create vendor account',
          style: GoogleFonts.dmSans(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212828),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          _isLoggedIn
              ? 'Run your laundry stores on Foam. Update your business information below to continue.'
              : "Run your laundry stores on Foam. We'll verify your business before you go live.",
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF5E5E5E),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Form Fields (56px, rounded 10px, #E4E4E4)
        _buildFigmaField(
          controller: _businessNameController,
          hint: 'Business name',
        ),
        const SizedBox(height: 16),

        _buildFigmaField(
          controller: _ownerNameController,
          hint: "Owner's full name",
        ),
        const SizedBox(height: 16),

        _buildFigmaField(
          controller: _emailController,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
          readOnly: _isLoggedIn,
          suffixIcon: _isLoggedIn
              ? const Tooltip(
                  message: 'Email locked to current account',
                  child: Icon(Icons.lock_outline,
                      size: 20, color: Color(0xFF5E5E5E)),
                )
              : null,
        ),
        const SizedBox(height: 16),

        _buildFigmaPhoneField(),
        const SizedBox(height: 16),

        if (!_isLoggedIn) ...[
          _buildFigmaField(
            controller: _passwordController,
            hint: 'Password',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF5E5E5E),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 28),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: Color(0xFF00AABC)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Logged in with verified Foam account.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF212828),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Continue Button
        _buildGradientButton(
          text: 'Continue',
          onPressed: _handleStep1Submit,
        ),
        const SizedBox(height: 10),

        // Save as Draft
        _buildSaveDraftButton(),

        if (!_isLoggedIn) ...[
          const SizedBox(height: 2),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/log_in'),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: const Color(0xFF212828),
                  ),
                  children: [
                    const TextSpan(text: 'Already a vendor? '),
                    TextSpan(
                      text: 'Log in',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF00AABC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ==========================================
  // STEP 2: BUSINESS DOCUMENTS (Figma 170:3120)
  // ==========================================
  Widget _buildStep2Documents(VendorProvider vendor) {
    final kyc = vendor.kycStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2-segment progress bar
        _buildFigmaProgressBar(activeStep: 1),
        const SizedBox(height: 16),

        // Step tag
        Text(
          'Step 1 of 2',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5E5E5E),
          ),
        ),
        const SizedBox(height: 6),

        // Title
        Text(
          'Verify your business',
          style: GoogleFonts.dmSans(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212828),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Upload clear photos or PDFs. Foam reviews every vendor before approval.',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF5E5E5E),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Doc Cards
        _buildFigmaDocCard(
          title: 'CAC registration',
          subtitle: 'cac-certificate.pdf · 1.2 MB',
          emptySubtitle: 'Company or business name certificate',
          isUploaded: kyc.cacUploaded,
          fileName: kyc.cacFileName,
          onUpload: () => _pickAndUploadDoc('CAC'),
        ),
        const SizedBox(height: 14),

        _buildFigmaDocCard(
          title: "Owner's ID",
          subtitle: 'NIN slip · front.jpg',
          emptySubtitle: 'NIN slip, Driver’s license, or Int’l passport',
          isUploaded: kyc.ownerIdUploaded,
          fileName: kyc.ownerIdFileName,
          onUpload: () => _pickAndUploadDoc('OWNER_ID'),
        ),
        const SizedBox(height: 14),

        _buildFigmaDocCard(
          title: 'Proof of address',
          subtitle: 'Utility bill or tenancy, last 3 months',
          emptySubtitle: 'Utility bill or tenancy, last 3 months',
          isUploaded: kyc.proofOfAddressUploaded,
          fileName: kyc.proofOfAddressFileName,
          onUpload: () => _pickAndUploadDoc('ADDRESS'),
        ),
        const SizedBox(height: 28),

        if (_isUploadingDoc)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00AABC)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Uploading document...',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      color: const Color(0xFF5E5E5E),
                    ),
                  ),
                ],
              ),
            ),
          ),

        _buildGradientButton(
          text: 'Continue',
          onPressed: _isUploadingDoc ? null : _handleStep2Submit,
        ),
        const SizedBox(height: 14),

        _buildSaveDraftButton(),
      ],
    );
  }

  // ==========================================
  // STEP 3: PAYOUT BANK DETAILS (Figma 170:3173)
  // ==========================================
  Widget _buildStep3PayoutBank(VendorProvider vendor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2-segment progress bar
        _buildFigmaProgressBar(activeStep: 2),
        const SizedBox(height: 16),

        // Step tag
        Text(
          'Step 2 of 2',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5E5E5E),
          ),
        ),
        const SizedBox(height: 6),

        // Title
        Text(
          'Where should we pay you?',
          style: GoogleFonts.dmSans(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212828),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          "Your earnings are withdrawn to this account. It must be in your business or owner's name.",
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF5E5E5E),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Bank Selector
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
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedBank?.name ?? 'Select Bank',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: _selectedBank != null
                          ? const Color(0xFF212828)
                          : const Color(0xFF212828).withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF212828),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Account Number
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE4E4E4),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            textAlignVertical: TextAlignVertical.center,
            onChanged: _onAccountNumberChanged,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              letterSpacing: 0.96,
              color: const Color(0xFF212828),
            ),
            decoration: InputDecoration(
              hintText: '0123 454 821',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 16,
                letterSpacing: 0.96,
                color: const Color(0xFF212828).withValues(alpha: 0.8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Resolution Feedback
        if (_isResolvingAccount)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF00AABC)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Verifying account with Paystack...',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF00AABC),
                  ),
                ),
              ],
            ),
          )
        else if (_resolvedAccountName.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00AABC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _resolvedAccountName,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: const Color(0xFF212828),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        else if (_resolveError != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _resolveError!,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Terms Agreement
        InkWell(
          onTap: () => setState(() => _isAgreed = !_isAgreed),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _isAgreed,
                  onChanged: (val) => setState(() => _isAgreed = val ?? false),
                  activeColor: const Color(0xFF00AABC),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      "By submitting, you agree to Foam's vendor terms, including a 15% commission on item subtotals.",
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF5E5E5E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildGradientButton(
          text: 'Submit for review',
          onPressed: _handleStep3Submit,
        ),
        const SizedBox(height: 14),

        _buildSaveDraftButton(),
      ],
    );
  }

  // ==========================================
  // SHARED FIGMA REUSABLE UI BUILDERS
  // ==========================================
  Widget _buildFigmaField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF1F3F3) : const Color(0xFFE4E4E4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (val) {
                if (_stepError != null) {
                  setState(() => _stepError = null);
                }
                onChanged?.call(val);
              },
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: readOnly ? const Color(0xFF5E5E5E) : const Color(0xFF212828),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: const Color(0xFF212828).withValues(alpha: 0.8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: 8),
            suffixIcon,
          ],
        ],
      ),
    );
  }

  Widget _buildFigmaPhoneField() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE4E4E4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            '+234',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 24,
            color: const Color(0xFF777777).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (_) {
                if (_stepError != null) {
                  setState(() => _stepError = null);
                }
              },
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: const Color(0xFF212828),
              ),
              decoration: InputDecoration(
                hintText: 'Phone number',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: const Color(0xFF212828).withValues(alpha: 0.8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaDocCard({
    required String title,
    required String subtitle,
    required String emptySubtitle,
    required bool isUploaded,
    required String fileName,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xFFE5F7F8) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUploaded
              ? const Color(0xFF00AABC).withValues(alpha: 0.25)
              : const Color(0xFFE4E4E4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFF00AABC) : Colors.white,
              shape: BoxShape.circle,
              border: isUploaded
                  ? null
                  : Border.all(color: const Color(0xFF212828), width: 1.5),
            ),
            child: Icon(
              isUploaded ? Icons.check_rounded : Icons.add_rounded,
              color: isUploaded ? Colors.white : const Color(0xFF212828),
              size: 22,
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
                    fontSize: 15.5,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isUploaded && fileName.isNotEmpty
                      ? fileName
                      : (isUploaded ? subtitle : emptySubtitle),
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF5E5E5E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onUpload,
            child: Text(
              isUploaded ? 'Replace' : 'Upload',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: const Color(0xFF00AABC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 53,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00AABC), Color(0xFFC5EFF3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AABC).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.44,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveDraftButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _saveDraftAndExit,
        icon: const Icon(
          Icons.bookmark_outline_rounded,
          size: 17,
          color: Color(0xFF5E5E5E),
        ),
        label: Text(
          'Save as Draft & Finish Later',
          style: GoogleFonts.dmSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5E5E5E),
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
                fillColor: const Color(0xFFE4E4E4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
                          ? const Color(0xFF00AABC)
                          : const Color(0xFF212828),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF00AABC))
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
