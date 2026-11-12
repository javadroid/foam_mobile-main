import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/core/services/notification_service.dart';
import 'package:foam_mobile/core/services/socket_service.dart';
import 'package:foam_mobile/core/services/upload_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_documents_screen.dart';
import 'package:foam_mobile/feature/vendor/profile/vendor_bank_settings_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/stores/vendor_stores_list_screen.dart';
import 'package:foam_mobile/feature/vendor/wallet/vendor_wallet_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  'Update Profile / Brand Photo',
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: VendorColors.textMain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: VendorColors.primary),
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: VendorColors.primary),
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
        final vendor = Provider.of<VendorProvider>(context, listen: false);
        auth.updateAvatarUrl(uploadUrl);
        await vendor.updateVendorProfileImage(uploadUrl);

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
                  borderRadius: BorderRadius.circular(10)),
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
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _pickAndUploadPhoto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error selecting photo: $e',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Widget _buildVerifiedPartnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 12.5, color: Color(0xFF16A34A)),
          const SizedBox(width: 4),
          Text(
            'Verified Partner',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Log Out',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: VendorColors.textMain,
            ),
          ),
          content: Text(
            'Are you sure you want to log out of your vendor account?',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF64748B),
              fontSize: 14,
            ),
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
              onPressed: () async {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final navigator = Navigator.of(context);
                Navigator.pop(dialogContext);
                try {
                  await LogoutClass.logOut(context, _scaffoldKey);
                } catch (e) {
                  // Fallback offline clean logout
                  await NotificationService.logoutUser();
                  SocketService.disconnect();
                  HiveClass.clearHive();
                  authProvider.clearAuth();
                  navigator.pushNamedAndRemoveUntil(
                    OnBoardingScreen.id,
                    (route) => false,
                  );
                }
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final vendor = Provider.of<VendorProvider>(context);
    final currentStore = vendor.currentStore;
    final kyc = vendor.kycStatus;

    final businessName = auth.businessName.isNotEmpty
        ? auth.businessName
        : (currentStore.name.isNotEmpty && currentStore.name != 'My Store'
            ? currentStore.name
            : 'Vendor Business');

    final initials = businessName.trim().isNotEmpty
        ? (businessName.trim().split(' ').length > 1
            ? '${businessName.trim().split(' ')[0][0]}${businessName.trim().split(' ')[1][0]}'
                .toUpperCase()
            : businessName
                .substring(0, businessName.length >= 2 ? 2 : 1)
                .toUpperCase())
        : 'VD';

    final email = auth.email.isNotEmpty ? auth.email : 'Not set';
    final phone = auth.phoneNumber.isNotEmpty ? auth.phoneNumber : 'Not set';
    final hasBank = kyc.bankName.isNotEmpty && kyc.accountNumber.isNotEmpty;
    final avatarUrl = auth.avatarUrl.isNotEmpty
        ? auth.avatarUrl
        : (vendor.vendorAvatarUrl ?? (currentStore.photoUrl ?? ''));

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Vendor Profile',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: VendorColors.textMain,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Log Out',
              onPressed: _showLogoutDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            children: [
              // 1. Business Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: VendorColors.primary.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: VendorColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: VendorColors.primary
                                      .withValues(alpha: 0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : (avatarUrl.isNotEmpty
                                      ? Image.network(
                                          avatarUrl,
                                          fit: BoxFit.cover,
                                          width: 64,
                                          height: 64,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              initials,
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            initials,
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        )),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: VendorColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  businessName,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: VendorColors.textMain,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildVerifiedPartnerBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: VendorColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              color: VendorColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader('Manage Branches'),
              const SizedBox(height: 8),
              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.storefront_rounded,
                  iconBgColor: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Manage All Branches (${vendor.stores.length})',
                  subtitle: 'Switch, edit profiles, locations & catalog',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorStoresListScreen(),
                      ),
                    );
                  },
                ),
                _buildCardDivider(),
              ]),
              const SizedBox(height: 20),
              // 2. Payouts & Finance Section
              _buildSectionHeader('Payouts & Finance'),
              const SizedBox(height: 8),

              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.account_balance_rounded,
                  iconBgColor: VendorColors.primary.withValues(alpha: 0.1),
                  iconColor: VendorColors.primary,
                  title: 'Payout Bank Account',
                  subtitle: hasBank
                      ? '${kyc.bankName} •••• ${kyc.accountNumber.length >= 4 ? kyc.accountNumber.substring(kyc.accountNumber.length - 4) : kyc.accountNumber}'
                      : 'Not configured · Add verified bank account',
                  trailingText: hasBank ? 'Edit' : 'Add',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorBankSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildCardDivider(),
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBgColor: VendorColors.primary.withValues(alpha: 0.1),
                  iconColor: VendorColors.primary,
                  title: 'Wallet & Withdrawals',
                  subtitle:
                      'Available: ₦${vendor.availableBalance.toInt().toString()}',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorWalletScreen(),
                      ),
                    );
                  },
                ),
                _buildCardDivider(),
                _buildMenuItem(
                  icon: Icons.description_rounded,
                  iconBgColor: VendorColors.primary.withValues(alpha: 0.1),
                  iconColor: VendorColors.primary,
                  title: 'Business KYC Documents',
                  subtitle: 'CAC registration & identity documents',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorDocumentsScreen(),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // 3. Mode Switch & Account
              _buildSectionHeader('App Mode & Preferences'),
              const SizedBox(height: 8),

              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.swap_horiz_rounded,
                  iconBgColor: VendorColors.primary.withValues(alpha: 0.1),
                  iconColor: VendorColors.primary,
                  title: 'Switch to Customer App',
                  subtitle: 'Browse laundry services as a customer',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, MainScreen.id);
                  },
                ),
              ]),

              const SizedBox(height: 28),

              // 4. Logout Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showLogoutDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? actionText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionText != null) ...[
            const SizedBox(width: 8),
            Text(
              actionText,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: VendorColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
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

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
  }) {
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
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: VendorColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: VendorColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: VendorColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailingText,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: VendorColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
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
