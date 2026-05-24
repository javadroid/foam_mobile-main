import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/help_text_field.dart';

class HelpScreen extends StatefulWidget {
  static const String id = '/help_page';

  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldMessengerState> scaffoldKey =
        GlobalKey<ScaffoldMessengerState>();

    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          bottomOpacity: 6,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.blackAccentColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Help',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 25.0, top: 15.0, bottom: 25.0),
                child: Text(
                  'Contact Form',
                  style: Constants.subHeadingStyle.copyWith(
                    fontSize: MediaQuery.sizeOf(context).height / 45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const HelpTextField(
                hinText: 'SMS',
                isLink: false,
                suffixText: '+234000000000',
                prefixIcon: Icons.sms_outlined,
              ),
              AppSpaces.verticalSpace20,
              const HelpTextField(
                hinText: 'Email',
                isLink: false,
                suffixText: 'foam@example.com',
                prefixIcon: Icons.mail_outline_rounded,
              ),
              AppSpaces.verticalSpace20,
              const HelpTextField(
                hinText: 'Call',
                isLink: false,
                suffixText: '+234-00000000000',
                prefixIcon: Icons.call_outlined,
              ),
              AppSpaces.verticalSpace20,
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 15.0),
                child: Text(
                  'Useful Links',
                  style: Constants.subHeadingStyle.copyWith(
                    fontSize: MediaQuery.sizeOf(context).height / 45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AppSpaces.verticalSpace20,
              const HelpTextField(
                hinText: 'FAQ',
                isLink: true,
              ),
              AppSpaces.verticalSpace20,
              const HelpTextField(
                hinText: 'Terms of use',
                isLink: true,
              ),
              AppSpaces.verticalSpace20,
              const HelpTextField(
                hinText: 'Privacy Policy',
                isLink: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
