import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/history/model/order.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  static const String id = '/order_details';

  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  String _getOrdinalDate(DateTime date) {
    int day = date.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
          break;
      }
    }
    return '$day$suffix ${DateFormat('MMMM yyyy').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    int activeIndex = 0;
    if (order.status == 'ACCEPTED') {
      activeIndex = 1;
    } else if (order.status == 'ONGOING') {
      activeIndex = 2;
    } else if (order.status == 'COMPLETED') {
      activeIndex = 3;
    } else if (order.status == 'DELIVERED') {
      activeIndex = 4;
    }

    final List<Map<String, String>> stages = [
      {
        'title': 'Order Placed',
        'description': 'You have successfully placed your order',
      },
      {
        'title': 'Order Received',
        'description': "We've got your laundry!",
      },
      {
        'title': 'Order In Progress',
        'description': 'Picked up and being washed',
      },
      {
        'title': 'Ready for Delivery',
        'description': 'Washed, dried & ready to go',
      },
      {
        'title': 'Order Delivered',
        'description': 'Back in your hands, fresh and clean',
      },
    ];

    int stagesLeft = 4 - activeIndex;
    String headerText = stagesLeft > 0
        ? '$stagesLeft stage${stagesLeft > 1 ? 's' : ''} left'
        : 'Order completed!';

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
          'Order Details',
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
                if (order.status == 'CANCELLED') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Cancelled',
                                style: Constants.headingStyle.copyWith(
                                  fontSize: 18,
                                  color: Colors.red[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'This order was cancelled and is not being processed.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpaces.verticalSpace20,
                ] else ...[
                  // Tracker Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      headerText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Tracker Stages
                  Column(
                    children: List.generate(stages.length, (index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vertical Line & Node Stack
                          SizedBox(
                            width: 30,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                if (index < stages.length - 1)
                                  Positioned(
                                    top: 10,
                                    bottom: 0,
                                    child: Container(
                                      width: 2.5,
                                      color: index < activeIndex
                                          ? AppColors.primaryAccentColor
                                          : Colors.grey[200],
                                    ),
                                  ),
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: index <= activeIndex
                                          ? AppColors.primaryAccentColor
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: index <= activeIndex
                                            ? AppColors.primaryAccentColor
                                            : Colors.grey[300]!,
                                        width: index <= activeIndex ? 0 : 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stage Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stages[index]['title']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: index <= activeIndex
                                          ? Colors.black87
                                          : Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stages[index]['description']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: index <= activeIndex
                                          ? Colors.black54
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Timestamp / Status Placeholder
                          Text(
                            index == 0
                                ? DateFormat('H:mm').format(order.createdAt)
                                : (index <= activeIndex ? '' : '-'),
                            style: TextStyle(
                              fontSize: 12,
                              color: index <= activeIndex
                                  ? Colors.black54
                                  : Colors.grey[400],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  AppSpaces.verticalSpace20,
                ],
                const Divider(),
                AppSpaces.verticalSpace10,

                // Date & Price Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getOrdinalDate(order.createdAt),
                          style: Constants.headingStyle.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(order.createdAt),
                          style: Constants.subHeadingStyle.copyWith(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₦ ${Constants().currencyFormat(order.totalPrice)}',
                      style: Constants.headingStyle.copyWith(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                AppSpaces.verticalSpace10,

                // Items Section
                Text(
                  'Items',
                  style: Constants.headingStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 15),
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

                // Bottom Payment summary info
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
