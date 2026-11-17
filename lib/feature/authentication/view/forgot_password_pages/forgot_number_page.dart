import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/forgot_email_page.dart';
import 'package:foam_mobile/feature/authentication/view/verify_pages/verification_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ForgotPasswordNumber extends StatefulWidget {
  const ForgotPasswordNumber({super.key});

  static const String id = '/forgotnumber';

  @override
  State<ForgotPasswordNumber> createState() => _ForgotPasswordNumberState();
}

class _ForgotPasswordNumberState extends State<ForgotPasswordNumber> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final TextEditingController _numberController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _numberController.dispose();
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

  Future<void> _handleSendOtp() async {
    final phone = _numberController.text.trim();

    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    if (phone.length < 10) {
      _showError('Please enter a valid phone number (at least 10 digits)');
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
        body: jsonEncode({'email': phone}),
      );

      final data = json.decode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200) {
        Provider.of<AuthProvider>(context, listen: false).phoneNumber = phone;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              isForgotPassword: true,
              email: phone,
            ),
          ),
        );
      } else {
        _showError(data['error'] ?? 'Could not find an account with that phone number.');
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Phone Reset Badge Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(
                          Icons.phonelink_lock_rounded,
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
                            'Enter your registered phone number and we\'ll send you a verification code to reset your password.',
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

                    // Phone Field
                    MyTextField(
                      controller: _numberController,
                      labelText: 'Phone Number',
                      hinText: '08012345678',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      obscureText: false,
                      isPassword: false,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Switch to Email option
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed(
                            ForgotPasswordEmail.id,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                          child: Text(
                            'Use Email Address instead',
                            style: GoogleFonts.dmSans(
                              color: AppColors.primaryAccentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Submit Button (Bounded SizedBox, never unconstrained in Row)
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
