import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/social_auth_service.dart';
import 'package:foam_mobile/feature/authentication/model/sign_up_model.dart';
import 'package:foam_mobile/feature/authentication/view/auth_pages/login_or_register_page.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/login_with_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage0 extends StatefulWidget {
  final VoidCallback? onTap;

  const SignUpPage0({
    super.key,
    this.onTap,
  });

  static const String id = '/signup';

  @override
  State<SignUpPage0> createState() => _SignUpPage0State();
}

class _SignUpPage0State extends State<SignUpPage0> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
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

  void _handleSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneNumberController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty) {
      _showError('Please enter your first name');
      return;
    }
    if (lastName.isEmpty) {
      _showError('Please enter your last name');
      return;
    }
    if (phone.isEmpty || phone.length < 10 || phone.length > 15) {
      _showError('Please enter a valid phone number (10-15 digits)');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
    });

    final bool isVerified = await SignUpModel.signUp(
      context,
      email,
      password,
      phone,
      _scaffoldKey,
    );

    if (!mounted) return;

    if (isVerified) {
      await SignUpModel.getStarted(
        context,
        firstName,
        lastName,
        phone,
        email,
        password,
        _scaffoldKey,
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _navigateToLogin() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.of(context, rootNavigator: true).pushNamed(
        LoginOrRegisterPage.id,
      );
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                _navigateToLogin();
              }
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 18.0, top: 12.0, bottom: 12.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppColors.fadeBlueAccentColor,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                'Step 1 of 2',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryAccentColor,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: LinearProgressIndicator(
                          value: 0.5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryAccentColor,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Headline
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account ✨',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF0F172A),
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Join Foam for fast, premium laundry pickup & delivery.',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Name Row (First + Last Name)
                    Row(
                      children: [
                        Expanded(
                          child: MyTextField(
                            controller: _firstNameController,
                            labelText: 'First Name',
                            hinText: 'e.g. John',
                            textInputAction: TextInputAction.next,
                            obscureText: false,
                            isPassword: false,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: MyTextField(
                            controller: _lastNameController,
                            labelText: 'Last Name',
                            hinText: 'e.g. Doe',
                            textInputAction: TextInputAction.next,
                            obscureText: false,
                            isPassword: false,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Phone Number
                    MyTextField(
                      controller: _phoneNumberController,
                      labelText: 'Phone Number',
                      hinText: '08012345678',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      obscureText: false,
                      isPassword: false,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Email Address
                    MyTextField(
                      controller: _emailController,
                      labelText: 'Email Address',
                      hinText: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      obscureText: false,
                      isPassword: false,
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Password
                    MyTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hinText: 'At least 8 characters',
                      textInputAction: TextInputAction.next,
                      obscureText: true,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Confirm Password
                    MyTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hinText: 'Re-enter your password',
                      textInputAction: TextInputAction.done,
                      obscureText: true,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Next Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: GradientButton(
                        text: 'Continue to Address',
                        isLoading: _loading,
                        onPressed: _handleSignUp,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "OR SIGN UP WITH" Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE2E8F0),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'or sign up with',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE2E8F0),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Social Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        children: [
                          LoginWithButton(
                            text: 'Google',
                            isLoading: _isGoogleLoading,
                            onTap: () async {
                              setState(() {
                                _isGoogleLoading = true;
                              });
                              await SocialAuthService.handleGoogleSignIn(
                                context,
                                _scaffoldKey,
                              );
                              if (mounted) {
                                setState(() {
                                  _isGoogleLoading = false;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          LoginWithButton(
                            text: 'Apple',
                            isLoading: _isAppleLoading,
                            onTap: () async {
                              setState(() {
                                _isAppleLoading = true;
                              });
                              await SocialAuthService.handleAppleSignIn(
                                context,
                                _scaffoldKey,
                              );
                              if (mounted) {
                                setState(() {
                                  _isAppleLoading = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Already have an account? Log In
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                'Log In',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.primaryAccentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Terms & Privacy Note
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
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

