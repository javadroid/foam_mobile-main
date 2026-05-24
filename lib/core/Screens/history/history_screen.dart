import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/history_widget.dart';

class HistoryScreen extends StatefulWidget {
  static const String id = '/history_page';

  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedHistory = "Ongoing";
  final List<String> differentHistory = [
    "Ongoing",
    "Completed",
    "Cancelled",
  ];

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
            onPressed: () =>
                Navigator.pushReplacementNamed(context, MainScreen.id),
          ),
          title: Text(
            'History',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
        ),
        body: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: AppColors.shadeGreyAccentColor,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (String history in differentHistory)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedHistory = history;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: history == selectedHistory
                                          ? AppColors.primaryBackgroundColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14.0),
                                    ),
                                    child: Text(
                                      history,
                                      style: Constants.subHeadingStyle.copyWith(
                                        color: history == selectedHistory
                                            ? AppColors.primaryAccentColor
                                            : Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AppSpaces.verticalSpace20,
                    selectedHistory != differentHistory[0]
                        ? const Column(
                            children: [
                              HistoryWidget(
                                date: '10 April 2024',
                                details: 'Order Details',
                              ),
                              HistoryWidget(
                                date: '10 April 2024',
                                details: 'Order Details',
                              ),
                              HistoryWidget(
                                date: '10 April 2024',
                                details: 'Order Details',
                              ),
                              HistoryWidget(
                                date: '10 April 2024',
                                details: 'Order Details',
                              ),
                              HistoryWidget(
                                date: '10 April 2024',
                                details: 'Order Details',
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: AppColors.primaryAccentColor,
                                  size: MediaQuery.sizeOf(context).width / 3,
                                ),
                                Text(
                                  'No history',
                                  style: Constants.headingStyle,
                                ),
                              ],
                            ),
                          ),
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
