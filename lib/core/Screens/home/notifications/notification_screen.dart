import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/notification_widget.dart';

class NotificationScreen extends StatefulWidget {
  static const String id = '/notification_page';

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
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
            'Notifications',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
        ),
        body: ListView(
          children: [
            Container(
              height: MediaQuery.sizeOf(context).height,
              width: MediaQuery.sizeOf(context).width,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New',
                          style: Constants.subHeadingStyle.copyWith(
                            fontSize: 17,
                            color: AppColors.blackAccentColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        AppSpaces.verticalSpace20,
                        const Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'Your laundry is ready for pickup.',
                                time: 23,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'Our rider is waiting to pickup.',
                                time: 37,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                  const Divider(
                    thickness: 1.6,
                  ),
                  AppSpaces.verticalSpace20,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Past 7 Days',
                          style: Constants.subHeadingStyle.copyWith(
                            fontSize: 15,
                            color: AppColors.blackAccentColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        AppSpaces.verticalSpace20,
                        const Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'Your laundry is ready for pickup.',
                                time: 23,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'Our rider is waiting to pickup.',
                                time: 37,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: NotificationWidget(
                                text: 'We have received your order.',
                                time: 46,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
