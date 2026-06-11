import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/history/model/order.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  static const String id = '/order_details';

  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Order #${order.id}',
          overflow: TextOverflow.ellipsis,
          style: Constants.headingStyle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status & Date
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${order.status}',
                      style: Constants.headingStyle.copyWith(
                        fontSize: 20,
                        color: order.status == 'PENDING' 
                            ? Colors.orange 
                            : order.status == 'COMPLETED' 
                                ? Colors.green 
                                : Colors.red,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt),
                      style: Constants.textStyle,
                    ),
                  ],
                ),
                AppSpaces.verticalSpace20,

                // Items Section
                Text(
                  'Items',
                  style: Constants.headingStyle.copyWith(fontSize: 18),
                ),
                AppSpaces.verticalSpace10,
                Column(
                  children: order.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.shadeGreyAccentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Item Image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.fadeBlueAccentColor,
                              borderRadius: BorderRadius.circular(8),
                              image: item.category.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        item.category.imageUrl!,
                                      ),
                                      fit: BoxFit.contain,
                                    )
                                  : null,
                            ),
                            child: item.category.imageUrl == null
                                ? const Icon(Icons.image_not_supported)
                                : null,
                          ),
                          AppSpaces.horizontalSpace10,

                          // Item Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.category.name,
                                  style: Constants.subHeadingStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                AppSpaces.verticalSpace5,
                                Text(
                                  item.category.description,
                                  style: Constants.textStyle,
                                ),
                              ],
                            ),
                          ),

                          // Quantity & Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'x${item.quantity}',
                                style: Constants.headingStyle.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              AppSpaces.verticalSpace5,
                              Text(
                                '₦${Constants().currencyFormat(item.category.price * item.quantity)}',
                                style: Constants.headingStyle.copyWith(
                                  fontSize: 16,
                                  color: AppColors.primaryAccentColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                AppSpaces.verticalSpace20,

                // Price Summary
                const Divider(),
                AppSpaces.verticalSpace10,
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(
                          '₦${Constants().currencyFormat(order.totalPrice)}',
                        ),
                      ],
                    ),
                    AppSpaces.verticalSpace10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Method'),
                        Text(order.paymentType),
                      ],
                    ),
                    AppSpaces.verticalSpace10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Status'),
                        Text(
                          order.paymentStatus,
                          style: TextStyle(
                            color: order.paymentStatus == 'SUCCEEDED'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
