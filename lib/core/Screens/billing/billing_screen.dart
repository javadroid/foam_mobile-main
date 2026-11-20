import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';
import 'package:foam_mobile/core/Screens/billing/payment_success_screen.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/billing_widget.dart';
import 'package:foam_mobile/widgets/foam_payment_sheet.dart';

class BillingScreen extends StatefulWidget {
  static const String id = '/billing_screen';

  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _fetchPlansAndStatus();
  }

  Map<String, String> get _headers => {
        "Authorization": "Bearer ${HiveClass.getToken()}",
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

  Future<void> _fetchPlansAndStatus() async {
    try {
      final plansRes = await http.get(
        Uri.parse("${Constants.url}/api/subscriptions/plans"),
        headers: _headers,
      );
      if (plansRes.statusCode == 200) {
        final data = jsonDecode(plansRes.body);
        _plans = List<Map<String, dynamic>>.from(data['plans'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching plans: $e');
    }

    try {
      final subRes = await http.get(
        Uri.parse("${Constants.url}/api/subscriptions/my-subscription"),
        headers: _headers,
      );
      if (subRes.statusCode == 200) {
        final data = jsonDecode(subRes.body);
        // Keep null for clean buyflow and plan selection
        _userSubscription = null;
      }
    } catch (e) {
      debugPrint('Error fetching current subscription: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToPlan(Map<String, dynamic> plan) async {
    final name = plan['name'] ?? 'Plan';
    final double price = (plan['price'] as num?)?.toDouble() ?? 0.0;

    final result = await FoamPaymentSheet.show(
      context: context,
      title: 'Subscribe to Plan',
      itemTitle: name,
      itemSubtitle: plan['subtitle'] ?? 'Laundry Subscription Plan',
      amount: price,
      cycleLabel: '/ month',
      purpose: FoamPaymentPurpose.subscription,
      plan: plan,
    );

    if (result != null && mounted) {
      if (result.success) {
        _fetchPlansAndStatus();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              title: 'Subscription Activated! 🎉',
              subtitle: 'Your $name laundry plan is now active.',
              itemTitle: name,
              amount: price,
              paymentMethod: result.data?['paymentMethod'] ?? 'Google Pay',
              reference: result.reference ?? '',
              details: [
                if (plan['itemQuota'] != null)
                  MapEntry(
                      'Monthly Quota', '${plan['itemQuota']} clothing items'),
                if (plan['turnaroundDays'] != null)
                  MapEntry(
                      'Turnaround', '${plan['turnaroundDays']} business days'),
                if (plan['freePickupsCount'] != null)
                  MapEntry('Free Pickups',
                      '${plan['freePickupsCount']} monthly pickups included'),
              ],
              primaryButtonLabel: 'View Subscription',
              onPrimaryPressed: () {
                Navigator.pop(context);
                _fetchPlansAndStatus();
              },
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                Text('Payment Failed',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ],
            ),
            content: Text(
              result.message,
              style: GoogleFonts.dmSans(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showHistoryModal() async {
    final history = await FoamPaymentService.fetchSubscriptionHistory();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subscription History',
                    style: GoogleFonts.dmSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Text(
                          'No past subscription records found',
                          style: GoogleFonts.dmSans(
                              color: const Color(0xFF64748B)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, i) {
                          final sub = history[i];
                          final plan = sub['plan'] ?? {};
                          final status = sub['status'] ?? 'UNKNOWN';
                          final method = sub['paymentMethod'] ?? 'WALLET';
                          final isAct = status == 'ACTIVE';
                          final priceFormatted =
                              NumberFormat('#,###').format(plan['price'] ?? 0);

                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isAct
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAct
                                      ? Icons.check_circle_rounded
                                      : Icons.history_rounded,
                                  color: isAct
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF64748B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan['name'] ?? 'Subscription',
                                      style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: const Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      'Paid via $method • Status: $status',
                                      style: GoogleFonts.dmSans(
                                          color: const Color(0xFF64748B),
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₦$priceFormatted',
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: const Color(0xFF0F172A)),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getTitleColor(int index) {
    final colors = [
      const Color(0xFF0284C7),
      const Color(0xFF0098A6),
      const Color(0xFF0D9488),
      const Color(0xFF1E3A8A),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldMessengerState> scaffoldKey =
        GlobalKey<ScaffoldMessengerState>();

    return ScaffoldMessenger(
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
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Billing & Subscriptions',
            style: GoogleFonts.dmSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Color(0xFF0F172A)),
              tooltip: 'Billing History',
              onPressed: _showHistoryModal,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0098A6)))
            : RefreshIndicator(
                color: const Color(0xFF0098A6),
                onRefresh: _fetchPlansAndStatus,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  children: [
                    // Active Subscription Card
                    if (_userSubscription != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF86EFAC), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        color: Color(0xFF16A34A), size: 26),
                                    const SizedBox(width: 8),
                                    Text(
                                      _userSubscription!['plan']?['name'] ??
                                          'Active Plan',
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                        color: const Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_userSubscription!['status'] ?? 'ACTIVE'}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _buildQuotaChip(
                                  Icons.calendar_today_rounded,
                                  '${_userSubscription!['daysRemaining'] ?? 30} days left',
                                ),
                                const SizedBox(width: 8),
                                _buildQuotaChip(
                                  Icons.checkroom_rounded,
                                  '${_userSubscription!['remainingQuota'] ?? 0} items rem.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Payment Method: ${_userSubscription!['paymentMethod'] ?? 'WALLET'}',
                              style: GoogleFonts.dmSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Section Heading
                    Text(
                      _userSubscription != null
                          ? 'Available Plans'
                          : 'Choose a Laundry Plan',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Flexible monthly laundry packages built around your routine with priority pickup and free delivery.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Plans List
                    if (_plans.isNotEmpty)
                      ..._plans.asMap().entries.map((entry) {
                        final index = entry.key;
                        final plan = entry.value;
                        final rawServices = plan['features'] as List? ?? [];
                        final services =
                            rawServices.map((e) => e.toString()).toList();
                        final isCurrentPlan = _userSubscription != null &&
                            _userSubscription!['planId'] == plan['id'] &&
                            _userSubscription!['status'] == 'ACTIVE';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: BillingWidget(
                            backgroundColor: Colors.white,
                            titleColor: _getTitleColor(index),
                            title: plan['name'] ?? 'Plan',
                            subtitle:
                                plan['subtitle'] ?? plan['description'] ?? '',
                            price: '${plan['price'] ?? 0}',
                            services: services,
                            isPopular: plan['isPopular'] ?? (index == 0),
                            isCurrentPlan: isCurrentPlan,
                            additionalBenefits: isCurrentPlan
                                ? const [
                                    'Active subscription on your account 🎉'
                                  ]
                                : const [],
                            isComingSoon: false,
                            onGetStarted: () => _subscribeToPlan(plan),
                          ),
                        );
                      })
                    else ...[
                      // Fallback Pro Plan
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: BillingWidget(
                          backgroundColor: Colors.white,
                          titleColor: const Color(0xFF0098A6),
                          title: 'Standard Plan (Pro)',
                          subtitle:
                              'Complete all-in-one laundry care for busy individuals and families.',
                          price: '74,000',
                          isPopular: true,
                          services: const [
                            '100 items for laundry per month',
                            'Wash & fold + crisp ironing',
                            'Priority 2-day turnaround',
                            '2 free doorstep pickups & deliveries monthly',
                          ],
                          additionalBenefits: const [
                            '10% discount on overflow laundry beyond quota',
                          ],
                          isComingSoon: false,
                          onGetStarted: () => _subscribeToPlan({
                            'id': 1,
                            'name': 'Standard Plan (Pro)',
                            'price': 74000,
                          }),
                        ),
                      ),
                      // Fallback Basic Plan
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: BillingWidget(
                          backgroundColor: Colors.white,
                          titleColor: const Color(0xFF1E3A8A),
                          title: 'Basic Plan (Heavy Users)',
                          subtitle:
                              'Perfect for users with regular laundry needs twice monthly.',
                          price: '54,000',
                          services: const [
                            '35 items for laundry, 2X monthly',
                            'Standard wash, iron & fold',
                            '3–4 days turnaround',
                            'One free pickup & delivery per month',
                          ],
                          additionalBenefits: const [
                            '10% discount on extra laundry beyond the limit',
                          ],
                          isComingSoon: false,
                          onGetStarted: () => _subscribeToPlan({
                            'id': 2,
                            'name': 'Basic Plan (Heavy Users)',
                            'price': 54000,
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuotaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF16A34A)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }
}
