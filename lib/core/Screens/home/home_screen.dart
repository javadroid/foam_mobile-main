import 'package:foam_mobile/feature/schedule_pickup/views/01_how_to_choose_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:foam_mobile/core/Screens/billing/billing_screen.dart';
import 'package:foam_mobile/core/Screens/billing/payment_success_screen.dart';
import 'package:foam_mobile/core/Screens/drawer.dart';
import 'package:foam_mobile/core/Screens/home/notifications/notification_screen.dart';
import 'package:foam_mobile/core/Screens/home/services_screen/views/services_screen.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/controller/profile_pic_auth.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/billing_widget.dart';
import 'package:foam_mobile/widgets/discount_tile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:foam_mobile/widgets/foam_payment_sheet.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? toProfile;

  const HomePage({
    super.key,
    this.toProfile,
  });

  static const String id = '/homepage';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentDiscountIndex = 0;
  Timer? _sliderTimer;
  final PageController _discountController = PageController(initialPage: 0);

  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _subscriptionPlans = [];

  final List<Map<String, String>> defaultDiscountDeals = [
    {
      'title': 'Special Discount',
      'promoPrefix': 'up to',
      'promoValue': '30% off',
      'description': 'all wash & fold laundry services this week!',
      'imageAsset': 'assets/images/foam_discount.png',
    },
    {
      'title': 'Express Doorstep Pickup',
      'promoPrefix': 'from only',
      'promoValue': '₦800',
      'description': 'clean clothes delivered right back to your door',
      'imageAsset': 'assets/images/foam_discount2.png',
    },
    {
      'title': 'Refer a Friend',
      'promoPrefix': 'get',
      'promoValue': '₦1,500',
      'description': 'credit towards your next dry cleaning order',
      'imageAsset': 'assets/images/foam_discount3.png',
    },
  ];

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
    _fetchSubscriptionPlans();
    _startAutoSlider();
  }

  Future<void> _fetchPromotions() async {
    try {
      final res =
          await http.get(Uri.parse("${Constants.url}/api/promotions/active"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = List<Map<String, dynamic>>.from(data['promotions'] ?? []);
        if (list.isNotEmpty && mounted) {
          setState(() {
            _promotions = list;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching promotions: $e");
    }
  }

  Future<void> _fetchSubscriptionPlans() async {
    try {
      final res =
          await http.get(Uri.parse("${Constants.url}/api/subscriptions/plans"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = List<Map<String, dynamic>>.from(data['plans'] ?? []);
        if (list.isNotEmpty && mounted) {
          setState(() {
            _subscriptionPlans = list;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching plans: $e");
    }
  }

  void _startAutoSlider() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final count = _promotions.isNotEmpty
          ? _promotions.length
          : defaultDiscountDeals.length;
      if (count <= 1) return;

      if (_currentDiscountIndex < count - 1) {
        _currentDiscountIndex++;
      } else {
        _currentDiscountIndex = 0;
      }

      if (_discountController.hasClients) {
        _discountController.animateToPage(
          _currentDiscountIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _discountController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profilePicAuth = Provider.of<ProfilePicAuth>(context);
    final File profileImg = profilePicAuth.image;
    final bool hasValidImg =
        profileImg.path.isNotEmpty && profileImg.existsSync();

    final String firstName =
        auth.firstName.isNotEmpty ? auth.firstName : 'Friend';
    final String lastName = auth.lastName;
    final String addressStreet = auth.addressStreet.isNotEmpty
        ? auth.addressStreet
        : 'Set delivery address';

    final String initials = firstName.isNotEmpty && lastName.isNotEmpty
        ? '${firstName[0]}${lastName[0]}'.toUpperCase()
        : (firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U');

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: MyDrawer(
          firstName: firstName,
          scaffoldKey: _scaffoldKey,
        ),
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 36.0),
            children: [
              // 1. Top Header Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 14.0),
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: widget.toProfile,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryBackgroundColor,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          image: hasValidImg
                              ? DecorationImage(
                                  image: FileImage(profileImg),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: !hasValidImg
                            ? Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Greeting & Address
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $firstName',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: widget.toProfile,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 13,
                                  color: Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    addressStreet,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  size: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Icons: Notifications & Drawer
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context)
                              .pushNamed(NotificationScreen.id),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(9),
                            child: SvgPicture.asset(
                              'assets/images/notification.svg',
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF334155),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (ctx) {
                            return InkWell(
                              onTap: () => Scaffold.of(ctx).openDrawer(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                padding: const EdgeInsets.all(9),
                                child: SvgPicture.asset(
                                  'assets/images/menu.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF334155),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Hero Schedule Pickup Banner (Full Width, High Conversion)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'QUICK & RELIABLE',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fresh Clothes in 24h',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Doorstep laundry pickup and fast delivery across your city.',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(HowToChooseScreen.id);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Schedule Pickup',
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/washing-machine.png',
                            width: 52,
                            height: 52,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Discount Deals & Promotions Carousel
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _discountController,
                  itemCount: _promotions.isNotEmpty
                      ? _promotions.length
                      : defaultDiscountDeals.length,
                  onPageChanged: (idx) {
                    setState(() => _currentDiscountIndex = idx);
                  },
                  itemBuilder: (context, idx) {
                    if (_promotions.isNotEmpty) {
                      final promo = _promotions[idx];
                      final isAd = promo['type'] == 'SPONSORED_AD';
                      return DiscountSlider(
                        onPressed: () {
                          final target = promo['targetAction'] ?? '';
                          if (target == 'SERVICE_DRY_CLEANING') {
                            Navigator.of(context).pushNamed(
                              ServicesScreen.id,
                              arguments: 'dry cleaning',
                            );
                          } else if (target == 'SUBSCRIPTION_PLANS') {
                            Navigator.of(context).pushNamed(BillingScreen.id);
                          } else {
                            Navigator.of(context).pushNamed(
                              ServicesScreen.id,
                              arguments: 'laundry',
                            );
                          }
                        },
                        isLoading: false,
                        imageAsset: promo['imageUrl'] ??
                            'assets/images/foam_discount.png',
                        title: promo['title'] ?? 'Special Offer',
                        promoPrefix: isAd ? 'Sponsored' : 'Special Offer',
                        promoValue: promo['badgeText'] ?? '',
                        description: promo['subtitle'] ?? '',
                      );
                    }

                    final deal = defaultDiscountDeals[idx];
                    return DiscountSlider(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          ServicesScreen.id,
                          arguments: 'laundry',
                        );
                      },
                      isLoading: false,
                      imageAsset: deal['imageAsset']!,
                      title: deal['title']!,
                      promoPrefix: deal['promoPrefix']!,
                      promoValue: deal['promoValue']!,
                      description: deal['description']!,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: SmoothPageIndicator(
                  controller: _discountController,
                  count: _promotions.isNotEmpty
                      ? _promotions.length
                      : defaultDiscountDeals.length,
                  effect: const ExpandingDotsEffect(
                    dotWidth: 7,
                    dotHeight: 7,
                    spacing: 5,
                    dotColor: Color(0xFFCBD5E1),
                    activeDotColor: Color(0xFF0284C7),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Choose a Service (Hero Image Cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose a Service',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          Navigator.of(context).pushNamed(ServicesScreen.id),
                      child: Text(
                        'See All',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Pick a service to get started — pickup and delivery included.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _buildServiceHeroCard(
                      title: 'Laundry',
                      subtitle: 'Wash, iron & fold — ready to wear.',
                      imageUrl: 'https://foamlaundryapp.com/service1.png',
                      onTap: () => Navigator.of(context).pushNamed(
                        ServicesScreen.id,
                        arguments: 'laundry',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildServiceHeroCard(
                      title: 'Dry Cleaning',
                      subtitle: 'Delicate care for your finest garments.',
                      imageUrl: 'https://foamlaundryapp.com/service3.png',
                      onTap: () => Navigator.of(context).pushNamed(
                        ServicesScreen.id,
                        arguments: 'dry cleaning',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Subscriptions Section (1 Grid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subscriptions',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          Navigator.of(context).pushNamed(BillingScreen.id),
                      child: Text(
                        'View Plans',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Get access to more streamlined service with a plan built around how often you wash.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 1 Grid Layout (Full width cards, 1 per row)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: _subscriptionPlans.isNotEmpty
                      ? _subscriptionPlans.map((plan) {
                          final price =
                              NumberFormat('#,###').format(plan['price'] ?? 0);
                          final colorHex =
                              plan['colorHex'] as String? ?? '#0098A6';
                          final colorInt = int.tryParse(
                                  colorHex.replaceFirst('#', '0xFF')) ??
                              0xFF0098A6;
                          return _buildPlanCard(
                            title: plan['name'] ?? 'Plan',
                            price: price,
                            subtitle: plan['subtitle'] ?? '',
                            color: Color(colorInt),
                            isPopular: plan['isPopular'] ?? false,
                            features: List<String>.from(plan['features'] ?? []),
                            onGetStarted: () async {
                              final double planPrice =
                                  (plan['price'] as num?)?.toDouble() ?? 0.0;
                              final result = await FoamPaymentSheet.show(
                                context: context,
                                title: 'Subscribe to Plan',
                                itemTitle: plan['name'] ?? 'Plan',
                                itemSubtitle: plan['subtitle'] ??
                                    'Laundry Subscription Plan',
                                amount: planPrice,
                                cycleLabel: '/ month',
                                purpose: FoamPaymentPurpose.subscription,
                                plan: plan,
                              );
                              if (result != null && context.mounted) {
                                if (result.success) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentSuccessScreen(
                                        title: 'Subscription Activated! 🎉',
                                        subtitle:
                                            'Your ${plan['name'] ?? 'Plan'} laundry plan is now active.',
                                        itemTitle: plan['name'] ?? 'Plan',
                                        amount: planPrice,
                                        paymentMethod:
                                            result.data?['paymentMethod'] ??
                                                'Google Pay',
                                        reference: result.reference ?? '',
                                        primaryButtonLabel: 'View Subscription',
                                        onPrimaryPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushNamed(
                                              context, BillingScreen.id);
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                    SnackBar(
                                      content: Text(result.message),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        }).toList()
                      : [
                          _buildPlanCard(
                            title: 'Standard Plan (Pro)',
                            price: '74,000',
                            subtitle: 'Complete all-in-one laundry care',
                            color: const Color(0xFF0098A6),
                            isPopular: true,
                            features: const [
                              '100 items per month',
                              'Wash & fold + crisp ironing',
                              'Priority 2-day turnaround',
                              '2 free pickups & deliveries monthly',
                            ],
                          ),
                          _buildPlanCard(
                            title: 'Basic Plan A (Heavy)',
                            price: '54,000',
                            subtitle: 'Twice monthly regular pickups',
                            color: const Color(0xFF1E3A8A),
                            features: const [
                              '35 items per month',
                              'Standard wash, iron & fold',
                              '3–4 days turnaround',
                              '1 free pickup & return monthly',
                            ],
                          ),
                          _buildPlanCard(
                            title: 'Basic Plan B (Light)',
                            price: '44,000',
                            subtitle: 'Flexible care for essential items',
                            color: const Color(0xFF0D9488),
                            features: const [
                              '50 items monthly limit',
                              'Standard wash, iron & fold',
                              '3–4 days turnaround',
                              '10% off extra items',
                            ],
                          ),
                        ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeroCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 195,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: Icon(Icons.local_laundry_service,
                      color: Colors.white54, size: 40),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Shimmer.fromColors(
                  baseColor: const Color(0xFFE2E8F0),
                  highlightColor: const Color(0xFFF1F5F9),
                  child: Container(color: Colors.white),
                );
              },
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.82),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                  stops: const [0.0, 0.60, 1.0],
                ),
              ),
            ),

            // Text & Action Overlay
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0098A6),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0098A6).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Clickable layer
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String subtitle,
    required Color color,
    required List<String> features,
    bool isPopular = false,
    VoidCallback? onGetStarted,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: BillingWidget(
        backgroundColor: Colors.white,
        titleColor: color,
        title: title,
        subtitle: subtitle,
        price: price,
        services: features,
        isPopular: isPopular,
        additionalBenefits: const [
          '10% discount on overflow laundry beyond quota',
        ],
        isComingSoon: false,
        onGetStarted: onGetStarted ??
            () => Navigator.of(context).pushNamed(BillingScreen.id),
      ),
    );
  }
}
