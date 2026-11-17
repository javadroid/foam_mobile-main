import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/auth_pages/login_or_register_page.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CreateNewPassword extends StatefulWidget {
  final String email;
  final String otp;

  const CreateNewPassword({
    super.key,
    this.email = '',
    this.otp = '',
  });

  static const String id = '/createnewpassword';

  @override
  State<CreateNewPassword> createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 8) {
      _showError('Password must be at least 8 characters long');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final targetEmail = widget.email.isNotEmpty ? widget.email : authProvider.email;

    if (targetEmail.isEmpty) {
      _showError('Missing email context. Please restart password recovery.');
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('${Constants.url}/api/auth/resetPassword'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': targetEmail.trim().toLowerCase(),
          'password': password,
          'otp': widget.otp.trim(),
        }),
      );

      final data = json.decode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200 || data['status'] == true) {
        _showSuccess('Password reset successfully! Please log in.');

        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginOrRegisterPage.id,
          (route) => false,
        );
      } else {
        _showError(data['error'] ?? data['message'] ?? 'Failed to reset password. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to connect to server. Please check your network.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Reset Lock Icon Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 40,
                          color: AppColors.primaryAccentColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Headline
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Create New Password',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF0F172A),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your new password must be at least 8 characters long and secure.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // New Password Field
                    MyTextField(
                      controller: _passwordController,
                      labelText: 'New Password',
                      hinText: 'Enter new password',
                      textInputAction: TextInputAction.next,
                      obscureText: true,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    MyTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hinText: 'Re-enter your new password',
                      textInputAction: TextInputAction.done,
                      obscureText: true,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Reset Button (Bounded SizedBox, never unconstrained in Row)
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        isLoading: _loading,
                        onPressed: _handleResetPassword,
                        text: 'Update Password',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Back to Sign In
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Remember your password?',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                LoginOrRegisterPage.id,
                                (route) => false,
                              );
                            },
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.dmSans(
                                color: AppColors.primaryAccentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
