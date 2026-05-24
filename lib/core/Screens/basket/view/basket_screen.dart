import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foam_mobile/core/Screens/basket/controller/remote_basket.dart';
import 'package:foam_mobile/core/Screens/basket/model/basket.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/utils/shimmer_effect.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/widgets/click_button.dart';

class BasketScreen extends StatefulWidget {
  const BasketScreen({super.key});

  static const String id = '/basket_screen';

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  List<BasketList>? basket;
  bool isLoaded = false;
  bool isNoFolding = false;
  int totalAmount = 0;
  final int noFoldingSurcharge = 200;
  int firstAmount = 0;

  @override
  void initState() {
    super.initState();
    //fetch data from API
    getData();
  }

  getData() async {
    basket = await BasketClass.getServices(scaffoldKey);
    if (basket != null && basket!.isNotEmpty) {
      // Sort by categoryId to keep the list position consistent
      basket!.sort((a, b) => a.categoryId.compareTo(b.categoryId));
      setState(() {
        isLoaded = true;
        totalAmount = 0;
        for (int i = 0; i < basket!.length; i++) {
          totalAmount += basket![i].price * basket![i].quantity;
        }
        if (isNoFolding) {
          totalAmount += noFoldingSurcharge;
        }
      });
    } else {
      setState(() {
        isLoaded = true;
        basket = [];
        totalAmount = 0;
      });
    }
  }

  void _recalculateTotal() {
    int newTotal = 0;
    if (basket != null) {
      for (var item in basket!) {
        newTotal += item.price * item.quantity;
      }
    }
    if (isNoFolding) {
      newTotal += noFoldingSurcharge;
    }
    setState(() {
      totalAmount = newTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isLoading = false;
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
            'Basket',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
          actions: [
            if (isLoaded && basket != null && basket!.isNotEmpty)
              IconButton(
                onPressed: () async {
                  await BasketClass.clearBasket(scaffoldKey);
                  getData();
                },
                icon: const Icon(
                  Icons.delete_sweep,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Visibility(
                visible: isLoaded,
                replacement: ShimmerEffect().basketLoadingCard(),
                child: ListView.builder(
                  itemCount: (basket?.length != null) ? basket!.length + 2 : 1,
                  itemBuilder: ((context, index) {
                    if (index == 0) {
                      // Header widget
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      Constants().formatDate(DateTime.now()),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "|",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      Constants().formatTime(DateTime.now()),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₦${Constants().currencyFormat(totalAmount)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Text(
                                  "Status :",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Ongoing",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(
                              thickness: 1,
                              color: Colors.black12,
                            ),
                          ),
                        ],
                      );
                    }

                    //Footer widget
                    if (index == basket!.length + 1) {
                      // Footer widget
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Customer Address Section
                            const Text(
                              'Customer address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (authProvider.addressStreet != '')
                                  ? authProvider.addressStreet
                                  : 'No Address',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),

                            // Add-ons Section
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: CheckboxListTile(
                                title: const Text(
                                  'No Folding Add-on',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '+ ₦$noFoldingSurcharge surcharge',
                                  style: TextStyle(
                                      color: AppColors.primaryAccentColor),
                                ),
                                value: isNoFolding,
                                activeColor: AppColors.primaryAccentColor,
                                onChanged: (value) {
                                  setState(() {
                                    isNoFolding = value ?? false;
                                    _recalculateTotal();
                                  });
                                },
                              ),
                            ),
                            const Divider(),
                            // Total Amount and Charges Section
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '₦${Constants().currencyFormat(totalAmount)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Delivery Charge',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '₦1,500',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),

                            // Total Payable Section
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Payable',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₦${Constants().currencyFormat(totalAmount + 1500)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            AppSpaces.verticalSpace40,

                            // Make Payment Button
                            Row(
                              children: [
                                Expanded(
                                  child: ClickButton(
                                    text: 'Make Payment',
                                    textColor: Colors.white,
                                    isLoading: isLoading,
                                    onPressed: () async {
                                      final secretKey =
                                          Constants.payStackSecretKey;
                                      final request =
                                          PaystackTransactionRequest(
                                        reference:
                                            'ps_${DateTime.now().microsecondsSinceEpoch}',
                                        secretKey: secretKey,
                                        email: authProvider.email,
                                        amount: ((totalAmount + 1500) * 100)
                                            .toDouble(),
                                        currency: PaystackCurrency.ngn,
                                        channel: [
                                          PaystackPaymentChannel.mobileMoney,
                                          PaystackPaymentChannel.card,
                                          PaystackPaymentChannel.ussd,
                                          PaystackPaymentChannel.bankTransfer,
                                          PaystackPaymentChannel.bank,
                                          PaystackPaymentChannel.qr,
                                          PaystackPaymentChannel.eft,
                                        ],
                                      );

                                      setState(() => isLoading = true);
                                      final initializedTransaction =
                                          await PaymentService
                                              .initializeTransaction(request);

                                      if (!mounted) return;
                                      setState(() => isLoading = false);

                                      if (!initializedTransaction.status) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.red,
                                            content: Text(
                                                initializedTransaction.message),
                                          ),
                                        );

                                        return;
                                      }

                                      await PaymentService.showPaymentModal(
                                        context,
                                        transaction: initializedTransaction,
                                        // Callback URL must match the one specified on your paystack dashboard,
                                        callbackUrl:
                                            'https://foamlaundryapp.netlify.app',
                                      );

                                      final response =
                                          await PaymentService.showPaymentModal(
                                                  context,
                                                  transaction:
                                                      initializedTransaction,
                                                  // Callback URL must match the one specified on your paystack dashboard,
                                                  callbackUrl: '...')
                                              .then((_) async {
                                        return await PaymentService
                                            .verifyTransaction(
                                          paystackSecretKey: '...',
                                          initializedTransaction
                                                  .data?.reference ??
                                              request.reference,
                                        );
                                      });

                                      log(
                                        response.toString(),
                                      ); // Result of the confirmed payment

                                      // if (kDebugMode)
                                      //   Logger().i(response.data.status ==
                                      //       PaystackTransactionStatus
                                      //           .abandoned);
                                    },
                                    fontSize:
                                        MediaQuery.sizeOf(context).height / 53,
                                    color: AppColors.secondaryBackgroundColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    //Body widget
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: (basket!.isNotEmpty)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          height: MediaQuery.sizeOf(context)
                                                  .height *
                                              0.12,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color:
                                                AppColors.fadeBlueAccentColor,
                                            image: DecorationImage(
                                              image: AssetImage(
                                                'assets/images/basket${basket![index - 1].categoryId + 1}.png',
                                              ),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                      AppSpaces.horizontalSpace10,
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              basket![index - 1]
                                                      .name[0]
                                                      .toUpperCase() +
                                                  basket![index - 1]
                                                      .name
                                                      .substring(1),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${basket![index - 1].price}/Item',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Constants.subHeadingStyle
                                                  .copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.sizeOf(context)
                                                      .width /
                                                  9,
                                              child: IconButton(
                                                onPressed: () async {
                                                  if (basket![index - 1]
                                                          .quantity >
                                                      1) {
                                                    setState(() {
                                                      basket![index - 1]
                                                          .quantity -= 1;
                                                    });
                                                    _recalculateTotal();
                                                    await BasketClass
                                                        .updateQuantity(
                                                      basket![index - 1]
                                                          .categoryId,
                                                      basket![index - 1]
                                                          .quantity,
                                                      scaffoldKey,
                                                    );
                                                  }
                                                },
                                                icon: Icon(
                                                  Icons.remove_circle,
                                                  color:
                                                      AppColors.navyBlueAccent,
                                                  size:
                                                      MediaQuery.sizeOf(context)
                                                              .width /
                                                          16,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.sizeOf(context)
                                                      .width /
                                                  15,
                                              child: Center(
                                                child: Text(
                                                  basket![index - 1]
                                                      .quantity
                                                      .toString(),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: MediaQuery.sizeOf(
                                                                context)
                                                            .width /
                                                        20,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.sizeOf(context)
                                                      .width /
                                                  9,
                                              child: IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    basket![index - 1]
                                                        .quantity += 1;
                                                  });
                                                  _recalculateTotal();
                                                  await BasketClass
                                                      .updateQuantity(
                                                    basket![index - 1]
                                                        .categoryId,
                                                    basket![index - 1].quantity,
                                                    scaffoldKey,
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.add_circle,
                                                  color:
                                                      AppColors.navyBlueAccent,
                                                  size:
                                                      MediaQuery.sizeOf(context)
                                                              .width /
                                                          16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/images/basket_empty.svg',
                                  width: MediaQuery.sizeOf(context).width / 2.5,
                                  height:
                                      MediaQuery.sizeOf(context).height / 2.5,
                                ),
                                Text(
                                  'NO ITEM IN CART',
                                  style: Constants.headingStyle.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                AppSpaces.verticalSpace40,
                                ClickButton(
                                  text: 'Schedule Pickup',
                                  textColor: Colors.white,
                                  onPressed: () => Navigator.of(context)
                                      .pushNamed(ServicesScreen.id),
                                  fontSize: 17,
                                  color: AppColors.secondaryBackgroundColor,
                                ),
                              ],
                            ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
