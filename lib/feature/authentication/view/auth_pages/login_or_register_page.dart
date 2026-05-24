import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/view/login_pages/log_in.dart';
import 'package:foam_mobile/feature/authentication/view/sign_up_pages/sign_up_0.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  static const String id = '/login';

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  //initially show the login page
  bool showLoginPage = true;

  //toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    } else {
      return const SignUpPage0();
    }
  }
}
