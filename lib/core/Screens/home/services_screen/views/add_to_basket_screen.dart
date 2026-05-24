import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/controllers/remote_services.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/models/add_to_basket_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:foam_mobile/utils/shimmer_effect.dart';

class AddToBasket extends StatefulWidget {
  const AddToBasket({super.key});

  static const String id = '/add_to_basket_screen';

  @override
  State<AddToBasket> createState() => _AddToBasketState();
}

class _AddToBasketState extends State<AddToBasket> {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  bool isLoaded = false;
  String selectedClothe = "Tops";
  final List<String> filterClothesType = [
    "Tops",
    "Bottoms",
    "Caps/Hats",
    "Men’s Corporate",
    "Full Body Wears",
    "Two Piece",
    "Bridal Wears",
    "Beddings",
    "Household",
    "Footwears",
  ];
  final List<Items> items = AddToBasketModel().items ?? [];

  // int quantity = 0;

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
            'Add to Basket',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
        ),
        body: SizedBox(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (String clotheType in filterClothesType)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedClothe = clotheType;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 30.0,
                          ),
                          decoration: BoxDecoration(
                            color: clotheType == selectedClothe
                                ? AppColors.primaryAccentColor
                                : AppColors.fadeBlueAccentColor,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(
                                20.0,
                              ),
                            ),
                          ),
                          child: Text(
                            clotheType,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:
                                  Constants.subHeadingStyle.fontSize ?? 16,
                              fontWeight: FontWeight.w700,
                              color: clotheType == selectedClothe
                                  ? AppColors.primaryBackgroundColor
                                  : AppColors.blackAccentColor,
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
              AppSpaces.verticalSpace20,
              Expanded(
                child: Visibility(
                  // visible: isLoaded,
                  visible: true,
                  replacement: ShimmerEffect().addToBasketLoadingCard(),
                  child: ListView.builder(
                    itemCount: (items.isNotEmpty) ? items.length + 1 : 1,
                    // itemCount: 8,
                    itemBuilder: ((context, index) {
                      if (index == items.length) {
                        return Row(
                          children: [
                            Expanded(
                              child: ClickButton(
                                text: 'Schedule Pickup',
                                textColor: Colors.white,
                                isLoading: isLoaded,
                                onPressed: () async {
                                  setState(() {
                                    isLoaded = true;
                                  });
                                  await ServicesClass.addToBasket(
                                      context,
                                      items[0].id ?? 1,
                                      (items[0].quantity == 0)
                                          ? 1
                                          : items[0].quantity!,
                                      scaffoldKey);
                                  setState(() {
                                    isLoaded = false;
                                  });
                                },
                                fontSize:
                                    MediaQuery.sizeOf(context).height / 53,
                                color: AppColors.secondaryBackgroundColor,
                              ),
                            ),
                          ],
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                              0.12,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.fadeBlueAccentColor,
                                        image: DecorationImage(
                                          image: AssetImage(
                                            items[index].image ?? '',
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
                                          items[index].name ?? '',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: Constants.subHeadingStyle,
                                        ),
                                        AppSpaces.verticalSpace20,
                                        Row(
                                          children: [
                                            if (items[index].oldPrice != null)
                                              Text(
                                                items[index].oldPrice!,
                                                style: Constants.subHeadingStyle
                                                    .copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            if (items[index].oldPrice != null)
                                              AppSpaces.horizontalSpace5,
                                            Text(
                                              items[index].price ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Constants.subHeadingStyle
                                                  .copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 19,
                                                color: AppColors
                                                    .primaryAccentColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width:
                                              MediaQuery.sizeOf(context).width /
                                                  9,
                                          child: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                if (items[index].quantity! >
                                                    0) {
                                                  items[index].quantity =
                                                      (items[index].quantity ??
                                                              0) -
                                                          1;
                                                }
                                              });
                                            },
                                            icon: Icon(
                                              Icons.remove_circle,
                                              color: AppColors.navyBlueAccent,
                                              size: MediaQuery.sizeOf(context)
                                                      .width /
                                                  14,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              MediaQuery.sizeOf(context).width /
                                                  15,
                                          child: Center(
                                            child: Text(
                                              items[index].quantity.toString(),
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize:
                                                    MediaQuery.sizeOf(context)
                                                            .width /
                                                        20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width:
                                              MediaQuery.sizeOf(context).width /
                                                  9,
                                          child: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                items[index].quantity =
                                                    (items[index].quantity ??
                                                            0) +
                                                        1;
                                              });
                                            },
                                            icon: Icon(
                                              Icons.add_circle,
                                              color: AppColors.navyBlueAccent,
                                              size: MediaQuery.sizeOf(context)
                                                      .width /
                                                  14,
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
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
