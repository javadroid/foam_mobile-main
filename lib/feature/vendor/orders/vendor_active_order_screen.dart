import 'package:flutter/material.dart';
import 'package:foam_mobile/feature/vendor/controller/vendor_provider.dart';
import 'package:foam_mobile/feature/vendor/models/vendor_models.dart';
import 'package:foam_mobile/feature/vendor/widgets/vendor_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorActiveOrderScreen extends StatelessWidget {
  final VendorOrder order;

  const VendorActiveOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final provider = Provider.of<VendorProvider>(context);

    // Identify current status index
    // 0: Received at store, 1: Washing, 2: Ready, 3: Out for delivery, 4: Completed
    int currentStep = 1; // Default Washing
    if (order.status == 'ACCEPTED') currentStep = 0;
    if (order.status == 'RECEIVED_AT_STORE') currentStep = 0;
    if (order.status == 'WASHING') currentStep = 1;
    if (order.status == 'READY') currentStep = 2;
    if (order.status == 'OUT_FOR_DELIVERY') currentStep = 3;
    if (order.status == 'COMPLETED') currentStep = 4;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VendorColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          order.id,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: VendorColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.customerName} · ${order.itemCount} items',
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: VendorColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.serviceType,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: VendorColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: VendorColors.liveBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₦${currencyFormatter.format(order.vendorEarnings)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: VendorColors.liveText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Status Progression Stepper
              _buildStepItem(
                stepIndex: 0,
                currentStep: currentStep,
                title: 'Received at store',
                subtitle: order.receivedAt != null
                    ? 'Dropped off by rider · ${order.receivedAt}'
                    : 'Awaiting rider drop-off',
                isLast: false,
              ),
              _buildStepItem(
                stepIndex: 1,
                currentStep: currentStep,
                title: 'Washing',
                subtitle: order.washingStartedAt != null
                    ? 'Started ${order.washingStartedAt}'
                    : 'In washing queue',
                isLast: false,
              ),
              _buildStepItem(
                stepIndex: 2,
                currentStep: currentStep,
                title: 'Ready',
                subtitle: 'Rider is notified to collect from store',
                isLast: false,
              ),
              _buildStepItem(
                stepIndex: 3,
                currentStep: currentStep,
                title: 'Out for delivery',
                subtitle: 'Rider takes laundry to the customer',
                isLast: false,
              ),
              _buildStepItem(
                stepIndex: 4,
                currentStep: currentStep,
                title: 'Completed',
                subtitle: 'Earnings land in your vendor wallet',
                isLast: true,
              ),

              const Spacer(),

              // Helpful prompt
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VendorColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: VendorColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Marking ready notifies a Foam rider to collect from your store.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: VendorColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (currentStep == 1) // Washing -> Mark as ready
                VendorButton(
                  text: 'Mark as ready',
                  onPressed: () {
                    provider.updateOrderStatus(order.id, 'READY');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rider notified for pickup!')),
                    );
                  },
                )
              else if (currentStep == 2) // Ready -> Rider picked up
                VendorButton(
                  text: 'Dispatched with rider',
                  onPressed: () {
                    provider.updateOrderStatus(order.id, 'OUT_FOR_DELIVERY');
                  },
                )
              else if (currentStep == 3) // Delivering -> Complete
                VendorButton(
                  text: 'Confirm delivery complete',
                  onPressed: () {
                    provider.updateOrderStatus(order.id, 'COMPLETED');
                    Navigator.pop(context);
                  },
                )
              else
                VendorButton(
                  text: 'Back to orders',
                  isSecondary: true,
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int stepIndex,
    required int currentStep,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    final bool isCompleted = stepIndex < currentStep;
    final bool isActive = stepIndex == currentStep;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? VendorColors.liveBg
                    : isActive
                        ? VendorColors.draftBg
                        : VendorColors.lightBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? VendorColors.liveText
                      : isActive
                          ? VendorColors.primary
                          : VendorColors.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: VendorColors.liveText)
                    : isActive
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: VendorColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? VendorColors.liveText : VendorColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isActive || isCompleted
                      ? VendorColors.textMain
                      : VendorColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: VendorColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
