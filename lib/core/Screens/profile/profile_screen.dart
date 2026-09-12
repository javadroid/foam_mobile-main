import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/view/profile_image.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/change_password_model.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_1.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:foam_mobile/widgets/profile_tile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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

  void _showChangePasswordModal() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

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
                    // Top Drag handle
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
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
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
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 14),

                    MyTextField(
                      controller: newPasswordController,
                      labelText: 'New Password',
                      hinText: 'At least 8 characters',
                      obscureText: true,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 14),

                    MyTextField(
                      controller: confirmPasswordController,
                      labelText: 'Confirm New Password',
                      hinText: 'Re-enter new password',
                      obscureText: true,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: GradientButton(
                        text: 'Save New Password',
                        isLoading: _isPasswordChanging,
                        onPressed: () async {
                          final oldPass = oldPasswordController.text;
                          final newPass = newPasswordController.text;
                          final confirmPass = confirmPasswordController.text;

                          if (oldPass.isEmpty || newPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all password fields'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          if (newPass.length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New password must be at least 8 characters'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('New passwords do not match'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setModalState(() {
                            _isPasswordChanging = true;
                          });

                          Navigator.pop(modalContext);

                          await ChangePasswordModel.changePassword(
                            context,
                            scaffoldKey,
                            oldPass,
                            newPass,
                          );

                          if (mounted) {
                            setState(() {
                              _isPasswordChanging = false;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 8),
              Text(
                'Delete Account',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
            style: GoogleFonts.dmSans(color: const Color(0xFF64748B), height: 1.4),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final String firstName = authProvider.firstName;
            final String lastName = authProvider.lastName;
            final String phone = authProvider.phoneNumber;
            final String email = authProvider.email;
            final String address = authProvider.addressStreet;
            final String city = authProvider.addressCity;

            final String initials = (firstName.isNotEmpty && lastName.isNotEmpty)
                ? '${firstName[0]}${lastName[0]}'.toUpperCase()
                : (firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U');

            final String displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
                ? '$firstName $lastName'.trim()
                : 'Foam Member';

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                // 1. User Hero Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ProfileImage(
                        radius: 44,
                        initials: initials,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName,
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: GoogleFonts.dmSans(
                            fontSize: 13.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Customer',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Personal Information Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
                  child: Text(
                    'PERSONAL DETAILS',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ProfileTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Full Name',
                  label: displayName,
                ),
                ProfileTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  label: phone.isNotEmpty ? phone : 'Not set',
                ),
                ProfileTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email Address',
                  label: email.isNotEmpty ? email : 'Not set',
                ),

                const SizedBox(height: 20),

                // 3. Saved Address Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
                  child: Text(
                    'DELIVERY LOCATION',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ProfileTile(
                  icon: Icons.location_on_outlined,
                  title: 'Default Pickup Address',
                  label: address.isNotEmpty
                      ? (city.isNotEmpty ? '$address, $city' : address)
                      : 'No address set yet',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.fadeBlueAccentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_location_alt_rounded, size: 14, color: AppColors.primaryAccentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Update',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryAccentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage1(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 4. Security Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 6.0),
                  child: Text(
                    'SECURITY',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ProfileTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Password',
                  label: '••••••••••••',
                  onTap: _showChangePasswordModal,
                ),

                const SizedBox(height: 28),

                // 5. Account Actions / Danger Zone
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showLogoutConfirmation,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: Color(0xFF475569), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Log Out',
                              style: GoogleFonts.dmSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: _showDeleteAccountConfirmation,
                    child: Text(
                      'Delete Account',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}

