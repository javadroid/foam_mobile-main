import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foam_mobile/core/Screens/basket/controller/order_controller.dart';
import 'package:foam_mobile/core/Screens/basket/controller/remote_basket.dart';
import 'package:foam_mobile/core/Screens/basket/model/basket.dart';
import 'package:foam_mobile/core/Screens/basket/view/pickup_address_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/models/add_to_basket_model.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/controllers/remote_services.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/utils/shimmer_effect.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
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
  final int deliveryChargePerItem = 1500;
  bool isLoaded = false;
  bool isLoading = false;
  bool isNoFolding = false;
  List<CategoryItem> categories = [];
  bool categoriesLoaded = false;

  int calculateNoFoldingSurcharge(List<BasketList> basket) {

    final totalTopsPrice = basket.fold(0, (sum, item) {
      final category = categories.firstWhere(
        (cat) => cat.id == item.categoryId,
        orElse: () => CategoryItem(
          id: 0,
          imageUrl: null,
          name: '',
          description: '',
          price: 0,
        ),
      );
    debugPrint(category.description);
      if (category.description.toLowerCase().contains('top')) {
        return sum + (item.price * item.quantity);
      }
      return sum;
    });
    return (totalTopsPrice * 0.3).round();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<BasketProvider>(context, listen: false)
          .fetchBasket(scaffoldKey);
      final fetchedCategories = await ServicesClass.getCategories(scaffoldKey);
      if (fetchedCategories != null) {
        setState(() {
          categories = fetchedCategories;
          categoriesLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final basketProvider = Provider.of<BasketProvider>(context);
    final basket = basketProvider.basketItems;
    final totalAmount = basketProvider.totalAmount;
    final deliveryCharge =2 * deliveryChargePerItem;
    final noFoldingSurcharge = calculateNoFoldingSurcharge(basket);
    debugPrint("noFoldingSurcharge ${noFoldingSurcharge.toString()}");
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
            onPressed: () => {
              if (Navigator.canPop(context)) Navigator.pop(context)
            },
          ),
          title: Text(
            'Basket',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
          actions: [
            if (basket.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await basketProvider.clearBasket(scaffoldKey);
                },
                child: const Text(
                  'Clear Cart',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: basketProvider.isLoading
            ? ShimmerEffect().basketLoadingCard()
            : basket.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_basket_outlined,
                          size: 100,
                          color: Colors.grey,
                        ),
                        AppSpaces.verticalSpace20,
                        const Text(
                          'Your basket is empty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: basket.length + 1,
                          itemBuilder: ((context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Skip folding?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppSpaces.horizontalSpace10,
                                    Switch(
                                      value: isNoFolding,
                                      onChanged: (value) {
                                        setState(() {
                                          isNoFolding = value;
                                        });
                                      },
                                      activeColor: AppColors.primaryAccentColor,
                                    ),
                                  ],
                                ),
                              );
                            }
                            final item = basket[index - 1];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 50,
                                              child: Container(
                                                height:
                                                    MediaQuery.sizeOf(context)
                                                            .height *
                                                        0.12,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: AppColors
                                                      .fadeBlueAccentColor,
                                                  image: (item.imageUrl != null)
                                                      ? DecorationImage(
                                                          image: NetworkImage(
                                                            item.imageUrl!,
                                                          ),
                                                          fit: BoxFit.contain,
                                                        )
                                                      : null,
                                                ),
                                                child: (item.imageUrl == null)
                                                    ? const Icon(Icons
                                                        .image_not_supported)
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name.trimRight(),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '₦${Constants().currencyFormat(item.price)}',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Constants
                                                            .subHeadingStyle
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '₦${Constants().currencyFormat((item.price * 1.3).round())}',
                                                        style: Constants
                                                            .subHeadingStyle
                                                            .copyWith(
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                          color: Colors.grey,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          // Fixed width for the entire quantity selector
                                          child: item.quantity >= 6
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .fadeBlueAccentColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                          color: AppColors
                                                              .navyBlueAccent
                                                              .withOpacity(0.5),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                        child:
                                                            DropdownButton<int>(
                                                          value: item.quantity,
                                                          icon: Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            color: AppColors
                                                                .navyBlueAccent,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .navyBlueAccent,
                                                          ),
                                                          onChanged:
                                                              (newValue) async {
                                                            if (newValue !=
                                                                null) {
                                                              await basketProvider
                                                                  .updateQuantity(
                                                                item.categoryId,
                                                                newValue,
                                                                scaffoldKey,
                                                              );
                                                            }
                                                          },
                                                          items: List.generate(
                                                            200,
                                                            (index) =>
                                                                index + 1,
                                                          ).map<
                                                              DropdownMenuItem<
                                                                  int>>((int
                                                              value) {
                                                            return DropdownMenuItem<
                                                                int>(
                                                              value: value,
                                                              child: Text(value
                                                                  .toString()),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed: () async {
                                                        if (item.quantity > 1) {
                                                          await basketProvider
                                                              .updateQuantity(
                                                            item.categoryId,
                                                            item.quantity - 1,
                                                            scaffoldKey,
                                                          );
                                                        } else {
                                                          await basketProvider
                                                              .removeFromBasket(
                                                            item.categoryId,
                                                            scaffoldKey,
                                                          );
                                                        }
                                                      },
                                                      icon: Icon(
                                                        Icons.remove_circle,
                                                        color: AppColors
                                                            .navyBlueAccent,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    Text(
                                                      item.quantity.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed: () async {
                                                        await basketProvider
                                                            .updateQuantity(
                                                          item.categoryId,
                                                          item.quantity + 1,
                                                          scaffoldKey,
                                                        );
                                                      },
                                                      icon: Icon(
                                                        Icons.add_circle,
                                                        color: AppColors
                                                            .navyBlueAccent,
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ],
                                    ),
                                 
                                ],
                              ),
                            );
                          }),
                        ),
                        // AppSpaces.verticalSpace20,
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Divider(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Subtotal',
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
                              if (isNoFolding)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'No Folding Surcharge',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        '₦${Constants().currencyFormat(noFoldingSurcharge)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Delivery Charge',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      '₦${Constants().currencyFormat(deliveryChargePerItem)} *2',
                                      style: const TextStyle(
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
                                      '₦${Constants().currencyFormat(totalAmount + deliveryCharge + (isNoFolding ? noFoldingSurcharge : 0))}',
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
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PickupAddressScreen(
                                              totalAmount: totalAmount +
                                                  deliveryCharge +
                                                  (isNoFolding
                                                      ? noFoldingSurcharge
                                                      : 0),
                                            ),
                                          ),
                                        );
                                      },
                                      fontSize:
                                          MediaQuery.sizeOf(context).height /
                                              53,
                                      color: AppColors.secondaryBackgroundColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 100),
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
