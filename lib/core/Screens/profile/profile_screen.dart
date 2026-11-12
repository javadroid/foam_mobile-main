import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/services/upload_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/change_password_model.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/core/Screens/profile/customer_address_screen.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:foam_mobile/widgets/safe_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/core/Screens/billing/billing_screen.dart';
import 'package:foam_mobile/feature/wallet/controller/wallet_provider.dart';
import 'package:foam_mobile/widgets/partner_selection_modal.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? toHome;

  const ProfileScreen({
    this.toHome,
    super.key,
  });

  static const String id = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isPasswordChanging = false;
  bool _isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Profile Photo',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Upload a clear photo of yourself',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      color: AppColors.primaryAccentColor),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      color: AppColors.primaryAccentColor),
                ),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final uploadUrl = await UploadService.uploadImage(File(image.path));
      if (!mounted) return;

      if (uploadUrl != null && uploadUrl.isNotEmpty) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        auth.updateAvatarUrl(uploadUrl);

        // Sync with vendor provider if user is also a vendor
        if (auth.role == 'VENDOR' || auth.businessName.isNotEmpty) {
          try {
            final vendor = Provider.of<VendorProvider>(context, listen: false);
            await vendor.updateVendorProfileImage(uploadUrl);
          } catch (_) {}
        }

        // Persist to user profile on backend
        try {
          await http.put(
            Uri.parse('${Constants.url}/api/user/profile'),
            headers: {
              'Authorization': 'Bearer ${HiveClass.getToken()}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'avatarUrl': uploadUrl}),
          );
        } catch (e) {
          debugPrint('Error updating user avatar: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile photo updated successfully!',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload photo. Please try again.',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error selecting image: $e',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> fetchAddress() async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/user/address"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );
      if (!mounted) return;
      var response = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        var authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (response["address"] != null &&
            (response["address"] as List).isNotEmpty) {
          var address = response["address"][0];
          authProvider.fillAddress(
            address["street"] ?? '',
            address["city"] ?? '',
            address["postalCode"] ?? '',
            address["country"] ?? 'Nigeria',
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching address: $e");
    }
  }

  void _showEditProfileModal(AuthProvider auth) {
    final TextEditingController firstNameCtrl =
        TextEditingController(text: auth.firstName);
    final TextEditingController lastNameCtrl =
        TextEditingController(text: auth.lastName);
    final TextEditingController phoneCtrl =
        TextEditingController(text: auth.phoneNumber);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: firstNameCtrl,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        labelStyle:
                            GoogleFonts.dmSans(color: const Color(0xFF64748B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.secondaryBackgroundColor,
                              width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: lastNameCtrl,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        labelStyle:
                            GoogleFonts.dmSans(color: const Color(0xFF64748B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.secondaryBackgroundColor,
                              width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle:
                            GoogleFonts.dmSans(color: const Color(0xFF64748B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppColors.secondaryBackgroundColor,
                              width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final fName = firstNameCtrl.text.trim();
                                final lName = lastNameCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();

                                if (fName.isEmpty || lName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please enter your first and last name'),
                                      backgroundColor: Color(0xFFEF4444),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                auth.fillAuth(
                                  fName,
                                  lName,
                                  null,
                                  auth.email,
                                  phone,
                                );

                                // Persist changes to backend
                                try {
                                  await http.put(
                                    Uri.parse(
                                        '${Constants.url}/api/user/profile'),
                                    headers: {
                                      'Authorization':
                                          'Bearer ${HiveClass.getToken()}',
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'firstName': fName,
                                      'lastName': lName,
                                      'phone': phone,
                                    }),
                                  );
                                } catch (e) {
                                  debugPrint(
                                      'Error updating profile on backend: $e');
                                }

                                if (!modalCtx.mounted || !mounted) return;
                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Profile updated successfully',
                                      style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                );
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordModal() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change Password',
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    Text(
                      'Update your password to keep your account safe.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    MyTextField(
                      controller: oldPasswordController,
                      labelText: 'Current Password',
                      hinText: 'Enter current password',
                      obscureText: true,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    MyTextField(
                      controller: newPasswordController,
                      labelText: 'New Password',
                      hinText: 'At least 6 characters',
                      obscureText: true,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    MyTextField(
                      controller: confirmPasswordController,
                      labelText: 'Confirm New Password',
                      hinText: 'Re-enter new password',
                      obscureText: true,
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Update Password',
                      isLoading: _isPasswordChanging,
                      onPressed: () async {
                        final String oldPass =
                            oldPasswordController.text.trim();
                        final String newPass =
                            newPasswordController.text.trim();
                        final String confirmPass =
                            confirmPasswordController.text.trim();

                        if (oldPass.isEmpty ||
                            newPass.isEmpty ||
                            confirmPass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please fill all password fields')),
                          );
                          return;
                        }

                        if (newPass.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'New password must be at least 6 characters')),
                          );
                          return;
                        }

                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('New passwords do not match')),
                          );
                          return;
                        }

                        setModalState(() => _isPasswordChanging = true);
                        await ChangePasswordModel.changePassword(
                          context,
                          scaffoldKey,
                          oldPass,
                          newPass,
                        );
                        setModalState(() => _isPasswordChanging = false);

                        if (!modalContext.mounted) return;
                        Navigator.pop(modalContext);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Log Out',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to log out of your account?',
            style: GoogleFonts.dmSans(color: const Color(0xFF64748B)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                LogoutClass.logOut(context, scaffoldKey);
              },
              child: Text(
                'Log Out',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 8),
              Text(
                'Delete Account',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
            style:
                GoogleFonts.dmSans(color: const Color(0xFF64748B), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                LogoutClass.logOut2(context);
              },
              child: Text(
                'Delete Permanently',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchAddress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WalletProvider>(context, listen: false).fetchWallet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: () {
              if (widget.toHome != null) {
                widget.toHome!();
              } else {
                Navigator.pushReplacementNamed(context, MainScreen.id);
              }
            },
          ),
          title: Text(
            'Profile & Settings',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Log Out',
              onPressed: _showLogoutConfirmation,
            ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final String firstName = authProvider.firstName;
            final String lastName = authProvider.lastName;
            final String phone = authProvider.phoneNumber;
            final String email = authProvider.email;
            final String address = authProvider.addressStreet;
            final String city = authProvider.addressCity;
            final bool isVendor = authProvider.role == 'VENDOR' ||
                authProvider.businessName.isNotEmpty;
            final riderProvider = Provider.of<RiderProvider>(context);
            final bool isRiderApproved = riderProvider.isApproved ||
                (authProvider.role == 'RIDER' && authProvider.isRiderVerified);

            final String initials =
                (firstName.isNotEmpty && lastName.isNotEmpty)
                    ? '${firstName[0]}${lastName[0]}'.toUpperCase()
                    : (firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U');

            final String displayName =
                (firstName.isNotEmpty || lastName.isNotEmpty)
                    ? '$firstName $lastName'.trim()
                    : 'Foam Member';

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              children: [
                // 1. Natural Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 24.0, horizontal: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryAccentColor
                                        .withValues(alpha: 0.22),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _isUploadingPhoto
                                    ? const Center(
                                        child: SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : SafeNetworkImage(
                                        imageUrl: authProvider.avatarUrl,
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                        shape: BoxShape.circle,
                                        fallbackBuilder: (_) => Center(
                                          child: Text(
                                            initials,
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 30,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: GoogleFonts.dmSans(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _showEditProfileModal(authProvider),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 17,
                                color: AppColors.primaryAccentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.dmSans(
                            fontSize: 13.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // If user is also a vendor, show quick switch card
                if (isVendor) ...[
                  InkWell(
                    onTap: () {
                      Provider.of<VendorProvider>(context, listen: false)
                          .checkAndNavigateToVendor(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vendor Dashboard',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage stores, pricing, orders & payouts',
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Switch',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white, size: 11),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // If user is also an approved rider, show rider quick switch card
                if (isRiderApproved) ...[
                  InkWell(
                    onTap: () {
                      Provider.of<RiderProvider>(context, listen: false)
                          .checkAndNavigateToRider(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF064E3B).withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.two_wheeler_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rider Dashboard',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Accept rides, track dispatches & view wallet',
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFFA7F3D0),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Switch',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white, size: 11),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 2. Personal Information Section
                _buildSectionHeader('Personal Details'),
                const SizedBox(height: 8),
                _buildSectionCard([
                  _buildDetailTile(
                    icon: Icons.person_rounded,
                    title: 'Full Name',
                    value: displayName,
                    onTap: () => _showEditProfileModal(authProvider),
                  ),
                  _buildCardDivider(),
                  _buildDetailTile(
                    icon: Icons.phone_rounded,
                    title: 'Phone Number',
                    value: phone.isNotEmpty ? phone : 'Add phone number',
                    onTap: () => _showEditProfileModal(authProvider),
                  ),
                  _buildCardDivider(),
                  _buildDetailTile(
                    icon: Icons.mail_rounded,
                    title: 'Email Address',
                    value: email.isNotEmpty ? email : 'Add email address',
                  ),
                ]),

                const SizedBox(height: 20),

                // Subscriptions & Plans Section
                _buildSectionHeader('Subscriptions & Membership'),
                const SizedBox(height: 8),
                _buildSectionCard([
                  _buildDetailTile(
                    icon: Icons.card_membership_rounded,
                    title: 'Billing & Subscriptions',
                    value: 'Manage monthly laundry plans & billing history',
                    trailingWidget: _buildThemedPill('Manage'),
                    onTap: () => Navigator.pushNamed(context, BillingScreen.id),
                  ),
                ]),

                const SizedBox(height: 20),

                // Partner Programs Section
                _buildSectionHeader('Partner Programs'),
                const SizedBox(height: 8),
                _buildSectionCard([
                  _buildDetailTile(
                    icon: Icons.handshake_outlined,
                    title: 'Partner with Foam',
                    value: 'List your laundry store or deliver with us',
                    trailingWidget: _buildThemedPill('Explore'),
                    onTap: () => PartnerSelectionModal.show(context),
                  ),
                ]),

                const SizedBox(height: 20),

                // 3. Saved Address Section
                _buildSectionHeader('Saved Address'),
                const SizedBox(height: 8),
                _buildSectionCard([
                  _buildDetailTile(
                    icon: Icons.location_on_rounded,
                    title: 'Default Pickup Address',
                    value: address.isNotEmpty
                        ? (city.isNotEmpty ? '$address, $city' : address)
                        : 'No pickup address saved yet',
                    trailingWidget: _buildThemedPill('Change'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerAddressScreen(),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                // 4. Security & Preferences
                _buildSectionHeader('Security & Preferences'),
                const SizedBox(height: 8),
                _buildSectionCard([
                  _buildDetailTile(
                    icon: Icons.lock_rounded,
                    title: 'Account Password',
                    value: '••••••••••••',
                    trailingWidget: _buildThemedPill('Update'),
                    onTap: _showChangePasswordModal,
                  ),
                ]),

                const SizedBox(height: 28),

                // 5. Account Actions / Logout Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showLogoutConfirmation,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: Color(0xFFEF4444), size: 19),
                          const SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: GoogleFonts.dmSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Center(
                  child: TextButton(
                    onPressed: _showDeleteAccountConfirmation,
                    child: Text(
                      'Delete Account Permanently',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475569),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildCardDivider() {
    return const Divider(
      height: 1,
      thickness: 0.6,
      color: Color(0xFFF1F5F9),
      indent: 62,
      endIndent: 16,
    );
  }

  Widget _buildThemedPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryAccentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryAccentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryAccentColor,
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    Color? iconBgColor,
    Color? iconColor,
    required String title,
    required String value,
    VoidCallback? onTap,
    Widget? trailingWidget,
  }) {
    final bg =
        iconBgColor ?? AppColors.primaryAccentColor.withValues(alpha: 0.1);
    final fg = iconColor ?? AppColors.primaryAccentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget
              else if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
