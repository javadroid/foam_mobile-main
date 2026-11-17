import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/basket/view/pickup_address_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/models/add_to_basket_model.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/controllers/remote_services.dart';
import 'package:foam_mobile/core/Screens/main_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/utils/shimmer_effect.dart';
import 'package:foam_mobile/core/provider/basket_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class BasketScreen extends StatefulWidget {
  final VoidCallback? toHome;

  const BasketScreen({super.key, this.toHome});

  static const String id = '/basket_screen';

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  bool isLoaded = false;
  bool isLoading = false;
  List<CategoryItem> categories = [];
  bool categoriesLoaded = false;
  final Set<String> _loadingItemIds = {};

  Future<void> _handleBasketAction(
      String categoryId, Future<void> Function() action) async {
    setState(() => _loadingItemIds.add(categoryId));
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _loadingItemIds.remove(categoryId));
      }
    }
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
    final deliveryCharge = basketProvider.deliveryFee;
    final noFoldingSurcharge = basketProvider.foldingSurchargeTotal;
    final totalPrice = basketProvider.totalPrice;
    final isNoFolding = basketProvider.isNoFolding;
    final isQuoteLoading = basketProvider.isQuoteLoading;
    if (basket.isNotEmpty &&
        basketProvider.currentQuote == null &&
        !isQuoteLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          basketProvider.fetchQuote(scaffoldKey: scaffoldKey);
        }
      });
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else if (widget.toHome != null) {
          widget.toHome!();
        } else {
          Navigator.pushReplacementNamed(context, MainScreen.id);
        }
      },
      child: ScaffoldMessenger(
        key: scaffoldKey,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (widget.toHome != null) {
                  widget.toHome!();
                } else {
                  Navigator.pushReplacementNamed(context, MainScreen.id);
                }
              },
            ),
            title: Text(
              'Basket',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            centerTitle: true,
            actions: [
              if (basket.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Clear Cart',
                          style:
                              GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                        ),
                        content: Text(
                          'Are you sure you want to remove all items from your basket?',
                          style: GoogleFonts.dmSans(
                              color: const Color(0xFF64748B)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.dmSans(
                                  color: const Color(0xFF64748B)),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              'Clear',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await basketProvider.clearBasket(scaffoldKey);
                    }
                  },
                  child: Text(
                    'Clear Cart',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          body: basketProvider.isLoading
              ? ShimmerEffect().basketLoadingCard()
              : basket.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccentColor
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 44,
                                color: AppColors.primaryAccentColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Your basket is empty',
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Looks like you haven\'t added any laundry items yet. Browse our services or schedule a pickup.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAccentColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, ServicesScreen.id);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Browse Services',
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: basket.length + 1,
                            itemBuilder: ((context, index) {
                              if (index == 0) {
                                return Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryAccentColor
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.checkroom_outlined,
                                          size: 20,
                                          color: AppColors.primaryAccentColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Include folding?',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              'Neatly folded & wrapped packaging',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 12,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch.adaptive(
                                        value: isNoFolding,
                                        onChanged: isQuoteLoading
                                            ? null
                                            : (value) async {
                                                await basketProvider
                                                    .setNoFolding(
                                                  value,
                                                  scaffoldKey: scaffoldKey,
                                                );
                                              },
                                        activeColor:
                                            AppColors.primaryAccentColor,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final item = basket[index - 1];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
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
                                                        BorderRadius.circular(
                                                            12),
                                                    color: AppColors
                                                        .fadeBlueAccentColor,
                                                    image: (item.imageUrl !=
                                                            null)
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
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name.trimRight(),
                                                      maxLines: 1,
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
                                                        const SizedBox(
                                                            height: 4),
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
                                        ),
                                        const SizedBox(width: 8),
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
                                                      child: _loadingItemIds
                                                              .contains(item
                                                                  .categoryId)
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(6.0),
                                                              child: SizedBox(
                                                                width: 16,
                                                                height: 16,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: AppColors
                                                                      .navyBlueAccent,
                                                                ),
                                                              ),
                                                            )
                                                          : DropdownButtonHideUnderline(
                                                              child:
                                                                  DropdownButton<
                                                                      int>(
                                                                value: item
                                                                    .quantity,
                                                                icon: Icon(
                                                                  Icons
                                                                      .arrow_drop_down,
                                                                  color: AppColors
                                                                      .navyBlueAccent,
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: AppColors
                                                                      .navyBlueAccent,
                                                                ),
                                                                onChanged:
                                                                    (newValue) async {
                                                                  if (newValue !=
                                                                      null) {
                                                                    _handleBasketAction(
                                                                        item
                                                                            .categoryId,
                                                                        () =>
                                                                            basketProvider.updateQuantity(
                                                                              item.categoryId,
                                                                              newValue,
                                                                              scaffoldKey,
                                                                            ));
                                                                  }
                                                                },
                                                                items: List
                                                                    .generate(
                                                                  200,
                                                                  (index) =>
                                                                      index + 1,
                                                                ).map<
                                                                    DropdownMenuItem<
                                                                        int>>((int
                                                                    value) {
                                                                  return DropdownMenuItem<
                                                                      int>(
                                                                    value:
                                                                        value,
                                                                    child: Text(
                                                                        value
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
                                                      onPressed: _loadingItemIds
                                                              .contains(item
                                                                  .categoryId)
                                                          ? null
                                                          : () =>
                                                              _handleBasketAction(
                                                                item.categoryId,
                                                                () async {
                                                                  if (item.quantity >
                                                                      1) {
                                                                    await basketProvider
                                                                        .updateQuantity(
                                                                      item.categoryId,
                                                                      item.quantity -
                                                                          1,
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
                                                              ),
                                                      icon: Icon(
                                                        Icons.remove_circle,
                                                        color: _loadingItemIds
                                                                .contains(item
                                                                    .categoryId)
                                                            ? Colors.grey
                                                            : AppColors
                                                                .navyBlueAccent,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6.0),
                                                      child: _loadingItemIds
                                                              .contains(item
                                                                  .categoryId)
                                                          ? SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: AppColors
                                                                    .navyBlueAccent,
                                                              ),
                                                            )
                                                          : Text(
                                                              item.quantity
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                    ),
                                                    IconButton(
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed: _loadingItemIds
                                                              .contains(item
                                                                  .categoryId)
                                                          ? null
                                                          : () =>
                                                              _handleBasketAction(
                                                                item.categoryId,
                                                                () async {
                                                                  await basketProvider
                                                                      .updateQuantity(
                                                                    item.categoryId,
                                                                    item.quantity +
                                                                        1,
                                                                    scaffoldKey,
                                                                  );
                                                                },
                                                              ),
                                                      icon: Icon(
                                                        Icons.add_circle,
                                                        color: _loadingItemIds
                                                                .contains(item
                                                                    .categoryId)
                                                            ? Colors.grey
                                                            : AppColors
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
                            margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            padding: const EdgeInsets.all(18.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Summary',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (isQuoteLoading)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.fadeBlueAccentColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.primaryAccentColor
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primaryAccentColor,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Calculating new price...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.navyBlueAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const Divider(),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Subtotal',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14.5,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        '₦${Constants().currencyFormat(totalAmount)}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isNoFolding && noFoldingSurcharge > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Folding Surcharge',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14.5,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          '₦${Constants().currencyFormat(noFoldingSurcharge)}',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
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
                                      Text(
                                        'Delivery Charge',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14.5,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        '₦${Constants().currencyFormat(deliveryCharge)}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
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
                                      Text(
                                        'Total Payable',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (isQuoteLoading)
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors
                                                    .primaryAccentColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Calculating...',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          '₦${Constants().currencyFormat(totalPrice)}',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryAccentColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Make Payment Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (isQuoteLoading ||
                                              isLoading)
                                          ? Colors.grey.shade400
                                          : AppColors.secondaryBackgroundColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: (isQuoteLoading || isLoading)
                                        ? null
                                        : () async {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PickupAddressScreen(
                                                  totalAmount: totalPrice,
                                                  noFolding: isNoFolding,
                                                ),
                                              ),
                                            );
                                          },
                                    child: isQuoteLoading
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Calculating new price...',
                                                style: GoogleFonts.dmSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.lock_outline_rounded,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Proceed to Checkout',
                                                style: GoogleFonts.dmSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15.5,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 16),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
