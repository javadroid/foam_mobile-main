import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/intro_screens/onboarding_screen.dart';
import 'package:foam_mobile/core/services/notification_service.dart';
import 'package:foam_mobile/core/services/socket_service.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_documents_screen.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_payout_bank_screen.dart';
import 'package:foam_mobile/feature/vendor/store_setup/vendor_store_details_screen.dart';
import 'package:foam_mobile/feature/vendor/stores/vendor_stores_list_screen.dart';
import 'package:foam_mobile/feature/vendor/wallet/vendor_wallet_screen.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            ? '${businessName.trim().split(' ')[0][0]}${businessName.trim().split(' ')[1][0]}'.toUpperCase()
            : businessName.substring(0, businessName.length >= 2 ? 2 : 1).toUpperCase())
        : 'VD';

    final email = auth.email.isNotEmpty ? auth.email : 'Not set';
    final phone = auth.phoneNumber.isNotEmpty ? auth.phoneNumber : 'Not set';
    final hasBank = kyc.bankName.isNotEmpty && kyc.accountNumber.isNotEmpty;

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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            children: [
              // 1. Business Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22.0),
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
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF334155)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 21,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                businessName,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: VendorColors.textMain,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                email,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: VendorColors.textMuted,
                                ),
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
                    const SizedBox(height: 18),
                    const Divider(height: 1, thickness: 0.6, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDCFCE7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 5),
                              Text(
                                'Verified Partner',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Store: ${currentStore.name}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: VendorColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Store Branches & Capacity Section
              _buildSectionHeader('Store Branches & Capacity',
                  actionText: '${vendor.stores.length} / ${vendor.maxStores} Branches'),
              const SizedBox(height: 8),

              // Capacity Progress Card
              Container(
                padding: const EdgeInsets.all(18),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.hub_rounded, color: Color(0xFF0284C7), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Branch Allocation',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: VendorColors.textMain,
                            ),
                          ),
                        ),
                        Text(
                          '${vendor.stores.length} of ${vendor.maxStores} slots',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: VendorColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: vendor.maxStores > 0
                            ? (vendor.stores.length / vendor.maxStores).clamp(0.0, 1.0)
                            : 0.0,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(VendorColors.primary),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Default max is 10 stores. System administrators can increase your branch capacity as your business scales.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

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
                _buildMenuItem(
                  icon: Icons.add_business_rounded,
                  iconBgColor: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Add New Store Branch',
                  subtitle: vendor.canAddStore
                      ? '${vendor.maxStores - vendor.stores.length} branch slots remaining'
                      : 'Limit reached (${vendor.maxStores} max) · Contact admin',
                  onTap: () {
                    if (vendor.canAddStore) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VendorStoreDetailsScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Store capacity reached (${vendor.stores.length}/${vendor.maxStores}). Contact admin to increase limit.',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ]),

              const SizedBox(height: 20),

              // 3. Payouts & Finance Section
              _buildSectionHeader('Payouts & Finance'),
              const SizedBox(height: 8),

              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.account_balance_rounded,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Payout Bank Account',
                  subtitle: hasBank
                      ? '${kyc.bankName} •••• ${kyc.accountNumber.length >= 4 ? kyc.accountNumber.substring(kyc.accountNumber.length - 4) : kyc.accountNumber}'
                      : 'Not configured · Add verified bank account',
                  trailingText: hasBank ? 'Edit' : 'Add',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorPayoutBankScreen(),
                      ),
                    );
                  },
                ),
                _buildCardDivider(),
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBgColor: const Color(0xFFCCFBF1),
                  iconColor: const Color(0xFF0D9488),
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
                  iconBgColor: const Color(0xFFEDE9FE),
                  iconColor: const Color(0xFF7C3AED),
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

              // 4. Mode Switch & Account
              _buildSectionHeader('App Mode & Preferences'),
              const SizedBox(height: 8),

              _buildMenuCard([
                _buildMenuItem(
                  icon: Icons.swap_horiz_rounded,
                  iconBgColor: const Color(0xFFF1F5F9),
                  iconColor: const Color(0xFF334155),
                  title: 'Switch to Customer App',
                  subtitle: 'Browse laundry services as a customer',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, MainScreen.id);
                  },
                ),
              ]),

              const SizedBox(height: 28),

              // 5. Logout Button
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
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
              letterSpacing: -0.2,
            ),
          ),
          if (actionText != null)
            Text(
              actionText,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: VendorColors.primary,
              ),
            ),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailingText,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0284C7),
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
