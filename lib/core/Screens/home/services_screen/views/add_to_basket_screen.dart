import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/view/basket_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/controllers/remote_services.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/models/add_to_basket_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:foam_mobile/utils/shimmer_effect.dart';
import 'package:foam_mobile/widgets/click_button.dart';
import 'package:provider/provider.dart';

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
  String selectedFilter = "Tops";
  
  final List<Map<String, String>> filterOptions = [
    {"label": "Tops", "filter": "tops"},
    {"label": "Bottoms", "filter": "bottoms"},
    {"label": "Children", "filter": "children"},
    {"label": "Corporate", "filter": "corporate-wears"},
    {"label": "Bridal", "filter": "bridal-wears"},
    {"label": "Beddings", "filter": "beddings"},
    {"label": "Household", "filter": "household"},
    {"label": "Footwears", "filter": "footwears"},
    {"label": "Native", "filter": "native"},
    {"label": "Bathroom", "filter": "bathroom"},
    {"label": "Specialty", "filter": "specialty"},
    {"label": "Uniform", "filter": "uniform"},
    {"label": "Gym", "filter": "gym-wears"},
  ];

  List<CategoryItem> allCategories = [];
  List<CategoryItem> filteredCategories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  fetchCategories() async {
    final result = await ServicesClass.getCategories(scaffoldKey);
    if (result != null) {
      setState(() {
        allCategories = result;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    setState(() {
      filteredCategories = allCategories
          .where((item) => item.description.toLowerCase().contains(selectedFilter.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args == null || args is! int) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Service ID not found.')),
      );
    }
    final int serviceId = args;
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
                    for (var option in filterOptions)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedFilter = option['filter']!;
                          });
                          _applyFilter();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 20.0,
                          ),
                          decoration: BoxDecoration(
                            color: option['filter'] == selectedFilter
                                ? AppColors.primaryAccentColor
                                : AppColors.fadeBlueAccentColor,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(
                                20.0,
                              ),
                            ),
                          ),
                          child: Text(
                            option['label']!,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:
                                  Constants.subHeadingStyle.fontSize ?? 16,
                              fontWeight: FontWeight.w700,
                              color: option['filter'] == selectedFilter
                                  ? AppColors.primaryBackgroundColor
                                  : AppColors.blackAccentColor,
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            
              Expanded(
                child: Visibility(
                  visible: allCategories.isNotEmpty,
                  replacement: ShimmerEffect().addToBasketLoadingCard(),
                  child: Consumer<BasketProvider>(
                    builder: (context, basketProvider, child) {
                      return ListView.builder(
                        itemCount: filteredCategories.length,
                        itemBuilder: ((context, index) {
                          final item = filteredCategories[index];
                          final currentQuantity = basketProvider.getQuantity(item.id);
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
Row(
  children: [
     SizedBox(
      width: 100,
                                        child: Container(
                                          height:
                                              MediaQuery.sizeOf(context).height *
                                                  0.12,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: AppColors.fadeBlueAccentColor,
                                            image: item.imageUrl != null
                                                ? DecorationImage(
                                                    image: NetworkImage(item.imageUrl!),
                                                    fit: BoxFit.contain,
                                                  )
                                                : null,
                                          ),
                                          child: item.imageUrl == null
                                              ? const Icon(Icons.image_not_supported)
                                              : null,
                                        ),
                                      ),
                                      AppSpaces.horizontalSpace10,
                                      SizedBox(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: Constants.subHeadingStyle,
                                            ),
                                            AppSpaces.verticalSpace20,
                                            Column(
                                              children: [
                                                Text(
                                                  '₦${Constants().currencyFormat(item.price)}',
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
                                                const SizedBox(width: 8),
                                                Text(
                                                  '₦${Constants().currencyFormat((item.price * 1.3).round())}',
                                                  style: Constants.subHeadingStyle
                                                      .copyWith(
                                                    decoration:
                                                        TextDecoration.lineThrough,
                                                    color: Colors.grey,
                                                    fontSize: 14,
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
                                      
                                        child: currentQuantity == 0
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  InkWell(
                                                    onTap: () async {
                                                      await basketProvider.addToBasket(
                                                          context,
                                                          serviceId,
                                                          item.id,
                                                          1,
                                                          scaffoldKey);
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .navyBlueAccent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8),
                                                      ),
                                                      child: const Text(
                                                        'Add',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
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
                                                      if (currentQuantity == 1) {
                                                        await basketProvider.removeFromBasket(
                                                                item.id,
                                                                scaffoldKey);
                                                      } else if (currentQuantity >
                                                          1) {
                                                        await basketProvider.updateQuantity(
                                                                item.id,
                                                                currentQuantity - 1,
                                                                scaffoldKey);
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.remove_circle,
                                                      color:
                                                          AppColors.navyBlueAccent,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  // const SizedBox(width: 8),
                                                  Text(
                                                    currentQuantity.toString(),
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  // const SizedBox(width: 8),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    onPressed: () async {
                                                      await basketProvider.updateQuantity(
                                                              item.id,
                                                              currentQuantity + 1,
                                                              scaffoldKey);
                                                    },
                                                    icon: Icon(
                                                      Icons.add_circle,
                                                      color:
                                                          AppColors.navyBlueAccent,
                                                      size: 28,
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
                      );
                    },
                  )
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClickButton(
                  text: 'Go to Basket',
                  textColor: Colors.white,
                  onPressed: () =>
                      Navigator.pushNamed(context, BasketScreen.id),
                  fontSize: MediaQuery.sizeOf(context).height / 53,
                  color: AppColors.secondaryBackgroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
