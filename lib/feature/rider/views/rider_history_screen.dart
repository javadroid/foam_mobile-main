import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';

class RiderHistoryScreen extends StatefulWidget {
  static const String id = '/rider/history';
  const RiderHistoryScreen({super.key});

  @override
  State<RiderHistoryScreen> createState() => _RiderHistoryScreenState();
}

class _RiderHistoryScreenState extends State<RiderHistoryScreen> {
  final currencyFormatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RiderProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RiderProvider>(context);
    final history = provider.history;
    final totalEarnings = history.fold<double>(0.0, (sum, item) => sum + item.earnings);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Delivery History',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212828),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212828)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF00AABC),
          onRefresh: () async => provider.fetchHistory(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Stat Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Deliveries',
                        value: '${history.length}',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF21CAAD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Earnings',
                        value: '₦${currencyFormatter.format(totalEarnings)}',
                        icon: Icons.payments_outlined,
                        color: const Color(0xFF00AABC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Completed Rides',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF212828),
                  ),
                ),
                const SizedBox(height: 12),

                if (provider.isLoading && history.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: Color(0xFF00AABC)),
                    ),
                  )
                else if (history.isEmpty)
                  _buildEmptyHistory()
                else
                  ...history.map((item) => _buildHistoryCard(item)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(RiderDeliveryHistoryItem item) {
    String formattedDate = item.date;
    try {
      final parsed = DateTime.parse(item.date);
      formattedDate = DateFormat('MMM dd, yyyy · hh:mm a').format(parsed);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.orderNumber,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF212828),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5FBF7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+ ₦${currencyFormatter.format(item.earnings)}',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF21CAAD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: GoogleFonts.dmSans(fontSize: 11, color: Colors.black45),
          ),
          const Divider(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF00AABC)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.storeName} (${item.pickupAddress})',
                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.redAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.deliveryAddress,
                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.route, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                '${item.distanceKm} km',
                style: GoogleFonts.dmSans(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_outlined, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            'No Deliveries Yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your completed customer deliveries will appear here with detailed earnings per ride.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
