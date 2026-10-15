import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/login_pages/log_in.dart';
import 'package:foam_mobile/feature/vendor/onboarding/vendor_documents_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class VendorSignUpScreen extends StatefulWidget {
  static const String id = '/vendor_sign_up';

  const VendorSignUpScreen({super.key});

  @override
  State<VendorSignUpScreen> createState() => _VendorSignUpScreenState();
}

class _VendorSignUpScreenState extends State<VendorSignUpScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final businessName = _businessNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (businessName.isEmpty) {
      MyMessageHandler.showSnackBar(
          _scaffoldKey, "Please enter your business name");
      return;
    }
    if (ownerName.isEmpty) {
      MyMessageHandler.showSnackBar(
          _scaffoldKey, "Please enter the owner's full name");
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      MyMessageHandler.showSnackBar(
          _scaffoldKey, "Please enter a valid email address");
      return;
    }
    if (phone.isEmpty) {
      MyMessageHandler.showSnackBar(
          _scaffoldKey, "Please enter your phone number");
      return;
    }
    if (password.length < 6) {
      MyMessageHandler.showSnackBar(
          _scaffoldKey, "Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final names = ownerName.split(' ');
      final firstName = names.first;
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : 'Vendor';

      // Call the backend registration endpoint with role: VENDOR
      final res = await http
          .post(
            Uri.parse("${Constants.url}/api/auth/register"),
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "firstName": firstName,
              "lastName": lastName,
              "email": email,
              "phone": phone.startsWith('+234')
                  ? phone
                  : phone.startsWith('0')
                      ? '+234${phone.substring(1)}'
                      : '+234$phone',
              "password": password,
              "businessName": businessName,
              "role": "VENDOR",
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (data['token'] != null) {
          HiveClass.insertToken(data['token']);
        }

        if (!mounted) return;

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.fillAuth(
          firstName,
          lastName,
          '',
          email,
          phone,
          role: 'VENDOR',
          businessName: businessName,
          vendorStatus: 'PENDING',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VendorDocumentsScreen(),
          ),
        );
      } else {
        final errorMsg = data['error'] ??
            data['message'] ??
            'Registration failed. Please check your details.';
        if (!mounted) return;
        MyMessageHandler.showSnackBar(_scaffoldKey, errorMsg.toString());
      }
    } catch (e) {
      if (!mounted) return;
      MyMessageHandler.showSnackBar(
        _scaffoldKey,
        "Unable to connect to the server. Please check your internet connection.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48.0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (Navigator.canPop(context)) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF212828),
                            ),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Header
                        Text(
                          'FOAM FOR BUSINESS',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF00AABC),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create vendor account',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF212828),
                            fontSize: 31,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Run your laundry stores on Foam. We'll verify your business before you go live.",
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF5E5E5E),
                            fontSize: 15,
                            height: 21 / 15,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Inputs
                        // 1. Business name
                        _buildInputField(
                          hint: 'Business name',
                          controller: _businessNameController,
                        ),
                        const SizedBox(height: 16),

                        // 2. Owner's full name
                        _buildInputField(
                          hint: "Owner's full name",
                          controller: _ownerNameController,
                        ),
                        const SizedBox(height: 16),

                        // 3. Email address
                        _buildInputField(
                          hint: 'Email address',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // 4. Phone number with +234 prefix
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E4E4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                '+234',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: const Color(0xFF212828),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 1,
                                height: 24,
                                color: const Color(0xFF777777),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    color: const Color(0xFF212828),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Phone number',
                                    hintStyle: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      color: const Color(0xFF212828)
                                          .withValues(alpha: 0.8),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. Password
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E4E4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    color: const Color(0xFF212828),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      color: const Color(0xFF212828)
                                          .withValues(alpha: 0.8),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF212828)
                                      .withValues(alpha: 0.6),
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 32),

                        // Continue Button
                        GestureDetector(
                          onTap: _isLoading ? null : _handleSignUp,
                          child: Container(
                            height: 53,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFFC5EFF3),
                                  Color(0xFF00AABC),
                                ],
                                stops: [0.0, 0.68],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.44,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Already a vendor? Log in
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Already a vendor? ',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF212828),
                                  fontSize: 17,
                                  fontWeight: FontWeight.normal,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Log in',
                                    style: GoogleFonts.dmSans(
                                      color: const Color(0xFF00AABC),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E4E4),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          color: const Color(0xFF212828),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
            fontSize: 16,
            color: const Color(0xFF212828).withValues(alpha: 0.8),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
