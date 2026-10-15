import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/controller/social_auth_service.dart';
import 'package:foam_mobile/feature/authentication/model/login_model.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/gradient_button.dart';
import 'package:foam_mobile/widgets/login_with_button.dart';
import 'package:foam_mobile/widgets/my_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onTap;

  const LoginPage({
    super.key,
    this.onTap,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToSignup() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.of(context).pushNamed(SignUpPage0.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.white,
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

                    // Foam Brand Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 48,
                          width: 48,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/foam.png',
                            height: 48,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Hero Headline
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Welcome Back',
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
                            'Sign in to manage pickups, schedule laundry, and track orders in real-time.',
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

                    // Email / Phone Field
                    MyTextField(
                      controller: _emailController,
                      labelText: 'Email Address or Phone',
                      hinText: 'name@example.com or 08012345678',
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

                    const SizedBox(height: 16),

                    // Password Field
                    MyTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hinText: 'Enter your password',
                      textInputAction: TextInputAction.done,
                      obscureText: true,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => LoginClass.forgotPassword(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 6.0,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.dmSans(
                              color: AppColors.primaryAccentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign In Button
                    GradientButton(
                      isLoading: _loading,
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter your email and password',
                                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                              ),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _loading = true;
                        });
                        await LoginClass.login(
                          context,
                          email,
                          password,
                          _scaffoldKey,
                        );
                        if (mounted) {
                          setState(() {
                            _loading = false;
                          });
                        }
                      },
                      text: 'Sign In',
                    ),

                    const SizedBox(height: 28),

                    // "OR CONTINUE WITH" Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFE2E8F0),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: Text(
                            'or continue with',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12.5,
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

                    const SizedBox(height: 22),

                    // Social Auth Buttons in a Horizontal Row
                    Row(
                      children: [
                        Expanded(
                          child: LoginWithButton(
                            text: 'Google',
                            shortLabel: true,
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
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: LoginWithButton(
                            text: 'Apple',
                            shortLabel: true,
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Don't have an account? Sign Up
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToSignup,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                'Sign Up',
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
