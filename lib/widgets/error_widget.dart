import 'package:dialog_alert/dialog_alert.dart';
import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/theme/theme_main_provider.dart';
import 'package:foam_mobile/widgets/custom_button.dart';
import 'package:foam_mobile/widgets/custom_textfield.dart';
import 'package:provider/provider.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({
    super.key,
    required this.logout,
    required this.message,
    required this.onTap,
  });

  final String message;
  final Function() onTap;
  final bool logout;

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    var mainProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      body: Center(
        child: Container(
          height: 400,
          width: MediaQuery.sizeOf(context).width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                children: [
                  Icon(
                    Icons.error,
                    size: 120,
                    color: Colors.redAccent,
                  ),
                ],
              ),
              SizedBox(
                height: 240,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    CustomButton(
                      loading: loading,
                      mainProvider: mainProvider,
                      onTap: widget.onTap,
                      title: "Try again",
                    ),
                    if (widget.logout)
                      CustomTextButton(
                        text: "Logout",
                        onPressed: () async {
                          final result = await showDialogAlert(
                            context: context,
                            title: 'Are you sure?',
                            message: 'Do you want to Log Out?',
                            actionButtonTitle: 'Log out',
                            cancelButtonTitle: 'Cancel',
                            actionButtonTextStyle: const TextStyle(
                              color: Colors.red,
                            ),
                            cancelButtonTextStyle: const TextStyle(
                              color: Colors.black,
                            ),
                          );
                          if (result == ButtonActionType.action) {
                            LogoutClass.logOut2(context);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
