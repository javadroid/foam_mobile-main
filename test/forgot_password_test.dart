import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/create_new_password.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/forgot_email_page.dart';
import 'package:foam_mobile/feature/authentication/view/forgot_password_pages/forgot_number_page.dart';
import 'package:foam_mobile/feature/authentication/view/verify_pages/verification_screen.dart';
import 'package:foam_mobile/theme/theme_main_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('ForgotPasswordEmail renders correctly without crashing or overflowing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: Builder(
          builder: (context) {
            themeProvider.height = MediaQuery.sizeOf(context).height;
            themeProvider.width = MediaQuery.sizeOf(context).width;
            return const MaterialApp(
              home: ForgotPasswordEmail(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.white);
    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Send Verification Code'), findsOneWidget);
  });

  testWidgets('ForgotPasswordNumber renders correctly without crashing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: ForgotPasswordNumber(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Send Verification Code'), findsOneWidget);
  });

  testWidgets('VerificationScreen renders correctly in forgot password mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: VerificationScreen(isForgotPassword: true, email: 'user@test.com'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Verify Your Identity'), findsOneWidget);
    expect(find.text('Continue to Reset'), findsOneWidget);
  });

  testWidgets('CreateNewPassword renders correctly without crashing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: CreateNewPassword(email: 'user@test.com', otp: '123456'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Create New Password'), findsOneWidget);
    expect(find.text('Update Password'), findsOneWidget);
  });
}
