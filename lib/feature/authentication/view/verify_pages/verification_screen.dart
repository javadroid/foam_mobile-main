import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/verification_model.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/custom_digit_field.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class VerificationScreen extends StatefulWidget {
  final bool isForgotPassword;
  final String? email;

  const VerificationScreen({
    super.key,
    this.isForgotPassword = false,
    this.email,
  });

  static const String id = 'verification_screen';

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final List<TextEditingController> controllers =
      List.generate(6, (index) => TextEditingController());

  bool loading = false;
  bool resending = false;

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _getEffectiveEmail(AuthProvider authProvider) {
    if (widget.email != null && widget.email!.trim().isNotEmpty) {
      return widget.email!.trim();
    }
    return authProvider.email.trim();
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

  Future<void> _handleVerify(String effectiveEmail) async {
    final code = controllers.map((e) => e.text).join().trim();
    if (code.length < 6) {
      _showError('Please enter all 6 digits of the verification code');
      return;
    }

    setState(() => loading = true);

    if (widget.isForgotPassword) {
      await VerifyClass.verifyForgotPassword(
        code,
        context,
        _scaffoldKey,
        email: effectiveEmail,
      );
    } else {
      await VerifyClass.verify(code, context, _scaffoldKey);
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _handleResend(String effectiveEmail) async {
    setState(() => resending = true);
    await VerifyClass.resend(
      context,
      _scaffoldKey,
      isForgotPassword: widget.isForgotPassword,
      email: effectiveEmail,
    );
    if (mounted) {
      setState(() => resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final effectiveEmail = _getEffectiveEmail(authProvider);

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

                    // Shield / Key Icon Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(
                          Icons.mark_email_read_outlined,
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
                            'Verify Your Identity',
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
                            effectiveEmail.isNotEmpty
                                ? 'We sent a 6-digit confirmation code to\n$effectiveEmail'
                                : 'Enter the 6-digit verification code sent to your email.',
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

                    // 6-digit input
                    Center(
                      child: CustomDigitField(
                        controllers: controllers,
                        hintText: '0',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Resend Code Action
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Didn\'t receive a code?',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: resending ? null : () => _handleResend(effectiveEmail),
                            child: Text(
                              resending ? 'Sending...' : 'Resend Code',
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

                    const SizedBox(height: 28),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        isLoading: loading,
                        onPressed: () => _handleVerify(effectiveEmail),
                        text: widget.isForgotPassword
                            ? 'Continue to Reset'
                            : 'Verify Account',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign Up / Register fallback
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account?',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(SignUpPage0.id),
                            child: Text(
                              'Sign Up',
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
