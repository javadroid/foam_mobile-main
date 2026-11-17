import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/core/Screens/history/model/order.dart';
import 'package:foam_mobile/widgets/history_widget.dart';

void main() {
  group('Order History Filtering & Display Tests', () {
    final pendingOrder = Order(
      id: '101',
      userId: 'user1',
      status: 'PENDING',
      vendorStatus: 'NEW',
      totalPrice: 2500,
      paymentType: 'CARD',
      paymentId: 'pay_1',
      paymentStatus: 'PAID',
      createdAt: DateTime.now(),
      items: [],
    );

    final acceptedOrder = Order(
      id: '102',
      userId: 'user1',
      status: 'ACCEPTED',
      vendorStatus: 'ACCEPTED',
      totalPrice: 3500,
      paymentType: 'CARD',
      paymentId: 'pay_2',
      paymentStatus: 'PAID',
      createdAt: DateTime.now(),
      items: [],
    );

    final washingOrder = Order(
      id: '103',
      userId: 'user1',
      status: 'ONGOING',
      vendorStatus: 'WASHING',
      totalPrice: 4000,
      paymentType: 'CARD',
      paymentId: 'pay_3',
      paymentStatus: 'PAID',
      createdAt: DateTime.now(),
      items: [],
    );

    final completedOrder = Order(
      id: '104',
      userId: 'user1',
      status: 'COMPLETED',
      vendorStatus: 'COMPLETED',
      totalPrice: 5000,
      paymentType: 'CARD',
      paymentId: 'pay_4',
      paymentStatus: 'PAID',
      createdAt: DateTime.now(),
      items: [],
    );

    final cancelledOrder = Order(
      id: '105',
      userId: 'user1',
      status: 'CANCELLED',
      vendorStatus: 'DECLINED',
      totalPrice: 1500,
      paymentType: 'CARD',
      paymentId: 'pay_5',
      paymentStatus: 'FAILED',
      createdAt: DateTime.now(),
      items: [],
    );

    final allOrders = [
      pendingOrder,
      acceptedOrder,
      washingOrder,
      completedOrder,
      cancelledOrder,
    ];

    List<Order> filterOrders(List<Order> orders, String tab) {
      switch (tab) {
        case "Pending":
        case "Ongoing":
          return orders.where((order) {
            final s = order.status.toUpperCase();
            final vs = (order.vendorStatus ?? '').toUpperCase();
            final isCompleted =
                s == "COMPLETED" || s == "DELIVERED" || vs == "COMPLETED";
            final isCancelled = s == "CANCELLED" || vs == "DECLINED";
            return !isCompleted && !isCancelled;
          }).toList();
        case "Completed":
          return orders.where((order) {
            final s = order.status.toUpperCase();
            final vs = (order.vendorStatus ?? '').toUpperCase();
            return s == "COMPLETED" || s == "DELIVERED" || vs == "COMPLETED";
          }).toList();
        case "Cancelled":
          return orders.where((order) {
            final s = order.status.toUpperCase();
            final vs = (order.vendorStatus ?? '').toUpperCase();
            return s == "CANCELLED" || vs == "DECLINED";
          }).toList();
        default:
          return orders;
      }
    }

    test('Ongoing tab includes pending, accepted, and ongoing orders', () {
      final ongoingOrders = filterOrders(allOrders, 'Ongoing');
      expect(ongoingOrders.map((o) => o.id).toList(), containsAll(['101', '102', '103']));
      expect(ongoingOrders.map((o) => o.id).toList(), isNot(contains('104')));
      expect(ongoingOrders.map((o) => o.id).toList(), isNot(contains('105')));
    });

    test('Completed tab only includes completed/delivered orders', () {
      final completedOrders = filterOrders(allOrders, 'Completed');
      expect(completedOrders.map((o) => o.id).toList(), equals(['104']));
    });

    test('Cancelled tab only includes cancelled/declined orders', () {
      final cancelledOrders = filterOrders(allOrders, 'Cancelled');
      expect(cancelledOrders.map((o) => o.id).toList(), equals(['105']));
    });

    testWidgets('HistoryWidget renders pending order in ongoing list properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryWidget(
              order: pendingOrder,
              onTap: () {},
              onTrack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Order #FM-101'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
    });

    testWidgets('HistoryWidget formats 36-char UUID into clean FM-XXXXXXXX and does not overflow', (tester) async {
      final uuidOrder = Order(
        id: '90b180eb-c77d-4f9f-9018-21d3cf556f84',
        userId: 'user1',
        status: 'ONGOING',
        vendorStatus: 'WASHING',
        totalPrice: 9600,
        paymentType: 'CARD',
        paymentId: 'pay_99',
        paymentStatus: 'PAID',
        createdAt: DateTime.now(),
        items: [],
      );

      expect(uuidOrder.displayOrderNumber, equals('FM-90B180EB'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryWidget(
              order: uuidOrder,
              onTap: () {},
              onTrack: () {},
            ),
          ),
        ),
      );

      expect(find.text('Order #FM-90B180EB'), findsOneWidget);
      expect(find.text('Washing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
