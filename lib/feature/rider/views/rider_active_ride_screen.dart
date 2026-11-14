import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:foam_mobile/feature/rider/controller/rider_provider.dart';
import 'package:foam_mobile/feature/rider/models/rider_models.dart';

class RiderActiveRideScreen extends StatefulWidget {
  static const String id = '/rider/active-ride';
  final ActiveRide ride;

  const RiderActiveRideScreen({super.key, required this.ride});

  @override
  State<RiderActiveRideScreen> createState() => _RiderActiveRideScreenState();
}

class _RiderActiveRideScreenState extends State<RiderActiveRideScreen> {
  final currencyFormatter = NumberFormat('#,###');
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _promptPinModal({
    required String title,
    required String description,
    required String expectedPin,
    required Function(String) onPinConfirmed,
  }) {
    _pinController.text = expectedPin; // Pre-fill with expected PIN for smooth testing
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pin, color: Color(0xFF00AABC), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF212828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                hintStyle: GoogleFonts.dmSans(color: Colors.black26),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00AABC)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AABC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final pin = _pinController.text.trim();
                  if (pin.length == 4) {
                    Navigator.pop(ctx);
                    onPinConfirmed(pin);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid 4-digit PIN')),
                    );
                  }
                },
                child: Text(
                  'Confirm & Advance',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _advanceStage(String nextStage, {String? pin}) async {
    final provider = Provider.of<RiderProvider>(context, listen: false);
    final ok = await provider.progressLifecycle(nextStage, pin: pin);

    if (!mounted) return;

    if (!ok && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RiderProvider>(context);
    final ride = provider.currentActiveRide ?? widget.ride;
    final stage = ride.stage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Active Ride (${ride.orderNumber})',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Stage Progression Stepper
              _buildProgressionStepper(stage),
              const SizedBox(height: 24),

              // 2. Main Action Card or Completion Card
              if (stage == 'DELIVERED')
                _buildDeliveryCelebrationCard(ride, provider)
              else
                _buildActiveLegCard(ride, stage, provider),

              const SizedBox(height: 24),

              // 3. Trip & Contact Details
              _buildTripDetailsCard(ride),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressionStepper(String currentStage) {
    final steps = [
      {'key': 'EN_ROUTE_TO_STORE', 'label': 'En Route'},
      {'key': 'PICKED_UP', 'label': 'Picked Up'},
      {'key': 'OUT_FOR_DELIVERY', 'label': 'On The Way'},
      {'key': 'DELIVERED', 'label': 'Delivered'},
    ];

    int currentIndex = steps.indexWhere((s) => s['key'] == currentStage);
    if (currentIndex == -1) currentIndex = 0;

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
          Text(
            'Delivery Progression',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isDone = index < currentIndex;
              final isCurrent = index == currentIndex;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isDone || isCurrent
                                  ? const Color(0xFF00AABC)
                                  : Colors.black12,
                            ),
                          ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? const Color(0xFF21CAAD)
                                : (isCurrent
                                    ? const Color(0xFF00AABC)
                                    : Colors.black12),
                          ),
                          child: Icon(
                            isDone ? Icons.check : Icons.circle,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        if (index < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isDone ? const Color(0xFF00AABC) : Colors.black12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step['label']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent
                            ? const Color(0xFF00AABC)
                            : (isDone ? const Color(0xFF21CAAD) : Colors.black45),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLegCard(ActiveRide ride, String stage, RiderProvider provider) {
    String title = '';
    String subtitle = '';
    String buttonText = '';
    IconData buttonIcon = Icons.arrow_forward;
    VoidCallback onAction = () {};

    if (stage == 'EN_ROUTE_TO_STORE') {
      title = 'Head to Pickup Location';
      subtitle = 'Arrive at ${ride.pickupAddress.isNotEmpty ? ride.pickupAddress : ride.storeName} to collect laundry and input customer PIN.';
      buttonText = 'Arrived at Pickup & Enter Customer PIN';
      buttonIcon = Icons.pin;
      onAction = () {
        _promptPinModal(
          title: 'Confirm Pickup from Customer',
          description: 'Ask customer for their 4-digit pickup PIN.',
          expectedPin: ride.pickupPin ?? '1234',
          onPinConfirmed: (pin) => _advanceStage('PICKED_UP', pin: pin),
        );
      };
    } else if (stage == 'PICKED_UP') {
      title = 'Items Picked Up Successfully';
      subtitle = 'Packages secured in vehicle. Proceed towards destination (${ride.deliveryAddress.isNotEmpty ? ride.deliveryAddress : ride.storeAddress}).';
      buttonText = 'Start Journey to Delivery / Store';
      buttonIcon = Icons.directions_bike;
      onAction = () => _advanceStage('OUT_FOR_DELIVERY');
    } else if (stage == 'OUT_FOR_DELIVERY') {
      title = 'Delivering to Destination';
      subtitle = 'Deliver package to ${ride.customerName} at ${ride.deliveryAddress}.';
      buttonText = 'Confirm Handover & Enter Delivery PIN';
      buttonIcon = Icons.verified;
      onAction = () {
        _promptPinModal(
          title: 'Customer Delivery PIN',
          description: 'Ask customer for the 4-digit delivery PIN to complete.',
          expectedPin: ride.deliveryPin ?? '5678',
          onPinConfirmed: (pin) => _advanceStage('DELIVERED', pin: pin),
        );
      };
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00AABC).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AABC).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ride.pickupTime != null || ride.scheduledPickupTime != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFFF57F17), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduled Pickup: ${ride.pickupTime ?? "Scheduled"}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AABC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: provider.isLoading ? null : onAction,
              icon: provider.isLoading
                  ? const SizedBox()
                  : Icon(buttonIcon, color: Colors.white, size: 20),
              label: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      buttonText,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          if (stage == 'EN_ROUTE_TO_STORE') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: provider.isLoading ? null : () => _confirmCancelRide(ride.orderId),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(
                  'Cancel Ride (Release to Nearby Riders)',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancelRide(int orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
            const SizedBox(width: 8),
            Text(
              'Cancel This Ride?',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this pickup? The ride will immediately be made available to other nearby riders.',
          style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF5E5E5E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Ride', style: GoogleFonts.dmSans(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<RiderProvider>(context, listen: false);
              final ok = await provider.cancelRide(orderId);
              if (!mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ride cancelled. Order released to nearby riders.'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Failed to cancel ride'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Cancel Ride', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCelebrationCard(ActiveRide ride, RiderProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21CAAD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF21CAAD).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE5FBF7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF21CAAD),
              size: 54,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Delivery Completed!',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Order ${ride.orderNumber} successfully completed and verified.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earnings Credited:',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF212828),
                  ),
                ),
                Text(
                  '+ ₦${currencyFormatter.format(ride.earnings)}',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF00AABC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AABC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                provider.finishActiveRide();
                Navigator.pop(context);
              },
              child: Text(
                'Return to Rider Dashboard',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard(ActiveRide ride) {
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
          Text(
            'Delivery Information',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            icon: Icons.storefront,
            label: 'Store Pickup',
            title: ride.storeName,
            subtitle: ride.pickupAddress,
          ),
          const Divider(height: 20),
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Customer Drop-off',
            title: ride.customerName,
            subtitle: ride.deliveryAddress,
            phone: ride.customerPhone,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trip Payout', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.black54)),
              Text(
                '₦${currencyFormatter.format(ride.earnings)}',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF00AABC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    String? phone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00AABC)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600)),
              Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        if (phone != null && phone.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFF21CAAD), size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling customer $phone...')),
              );
            },
          ),
      ],
    );
  }
}
