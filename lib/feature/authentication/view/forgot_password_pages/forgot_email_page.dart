import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/verify_pages/verification_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ForgotPasswordEmail extends StatefulWidget {
  const ForgotPasswordEmail({super.key});

  static const String id = '/forgotemail';

  @override
  State<ForgotPasswordEmail> createState() => _ForgotPasswordEmailState();
}

class _ForgotPasswordEmailState extends State<ForgotPasswordEmail> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
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
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 20),
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

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('${Constants.url}/api/auth/forgotPassword'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email.toLowerCase()}),
      );

      final data = json.decode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200) {
        // Store email in AuthProvider for downstream verification screens
        Provider.of<AuthProvider>(context, listen: false).email =
            email.toLowerCase();

        _showSuccess(data['message'] ?? 'Verification code sent to your email');

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              isForgotPassword: true,
              email: email.toLowerCase(),
            ),
          ),
        );
      } else {
        _showError(
            data['error'] ?? 'Could not find an account with that email.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to connect to server. Please check your connection.');
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Reset Icon Badge
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

                    // Title & Description
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Forgot Password',
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
                            'Enter your registered email address and we\'ll send you a 6-digit verification code to reset your password.',
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

                    // Email Field
                    MyTextField(
                      controller: _emailController,
                      labelText: 'Email Address',
                      hinText: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      obscureText: false,
                      isPassword: false,
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button (Wrapped in bounded SizedBox, NEVER raw inside Row)
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        isLoading: _loading,
                        onPressed: _handleSendOtp,
                        text: 'Send Verification Code',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Remember Password / Back to Login
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
                            onTap: () => Navigator.of(context).pop(),
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
