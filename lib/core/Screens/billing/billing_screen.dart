import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/core/services/foam_payment_service.dart';
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
        _userSubscription = data['subscription'] as Map<String, dynamic>?;
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

    if (result != null && result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _fetchPlansAndStatus();
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Subscription Auto-Renew'),
        content: const Text(
          'Are you sure you want to cancel auto-renewal? You will retain access until the current period ends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Auto-Renew', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await FoamPaymentService.cancelActiveSubscription();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription auto-renew cancelled.'),
            backgroundColor: Colors.orange,
          ),
        );
        _fetchPlansAndStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel subscription.'),
            backgroundColor: Colors.red,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Subscription History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Text(
                          'No past subscription records found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(height: 20),
                        itemBuilder: (ctx, i) {
                          final sub = history[i];
                          final plan = sub['plan'] ?? {};
                          final status = sub['status'] ?? 'UNKNOWN';
                          final method = sub['paymentMethod'] ?? 'WALLET';
                          final isAct = status == 'ACTIVE';

                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isAct ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAct ? Icons.check_circle_rounded : Icons.history_rounded,
                                  color: isAct ? const Color(0xFF16A34A) : const Color(0xFF64748B),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Paid via $method • Status: $status',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₦${plan['price'] ?? 0}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
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
      AppColors.navyBlueAccent,
      AppColors.greenTaleColor,
      AppColors.oceanBlueColor,
      AppColors.blackAccentColor,
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
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.blackAccentColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Billing & Subscription',
            overflow: TextOverflow.ellipsis,
            style: Constants.headingStyle,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Color(0xFF0F172A)),
              tooltip: 'Billing History',
              onPressed: _showHistoryModal,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchPlansAndStatus,
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Active Subscription Card
                    if (_userSubscription != null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                              blurRadius: 10,
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
                                    const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 26),
                                    const SizedBox(width: 8),
                                    Text(
                                      _userSubscription!['plan']?['name'] ?? 'Active Plan',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_userSubscription!['status'] ?? 'ACTIVE'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Method: ${_userSubscription!['paymentMethod'] ?? 'WALLET'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                                if (_userSubscription!['autoRenew'] == true)
                                  InkWell(
                                    onTap: _cancelSubscription,
                                    child: const Text(
                                      'Cancel Auto-Renew',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFDC2626),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // Plans List
                    if (_plans.isNotEmpty)
                      ..._plans.asMap().entries.map((entry) {
                        final index = entry.key;
                        final plan = entry.value;
                        final rawServices = plan['features'] as List? ?? [];
                        final services = rawServices.map((e) => e.toString()).toList();
                        final isCurrentPlan = _userSubscription != null &&
                            _userSubscription!['planId'] == plan['id'] &&
                            _userSubscription!['status'] == 'ACTIVE';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: BillingWidget(
                            backgroundColor: AppColors.primaryBackgroundColor,
                            titleColor: _getTitleColor(index),
                            title: plan['name'] ?? '',
                            subtitle: plan['subtitle'] ?? plan['description'] ?? '',
                            price: '${plan['price'] ?? 0}',
                            services: services,
                            additionalBenefits: isCurrentPlan
                                ? const ['Active Plan on your account 🎉']
                                : const [
                                    'Multi-gateway payment: Paystack, Google Pay, Apple Pay & Wallet',
                                    'Free monthly doorstep pickups included',
                                  ],
                            isComingSoon: false,
                            onGetStarted: () => _subscribeToPlan(plan),
                          ),
                        );
                      })
                    else ...[
                      // Fallback UI
                      BillingWidget(
                        backgroundColor: AppColors.primaryBackgroundColor,
                        titleColor: AppColors.navyBlueAccent,
                        title: 'Basic Plan (Heavy Users)',
                        subtitle: 'Perfect for users with regular laundry needs twice monthly.',
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
                          'id': 1,
                          'name': 'Basic Plan (Heavy Users)',
                          'price': 54000,
                        }),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }
}
