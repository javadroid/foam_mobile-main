import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class OrderClass {
  /// Calls POST /api/order/create to create order on server
  static Future<bool> createOrder({
    required BuildContext context,
    required GlobalKey<ScaffoldMessengerState> scaffoldKey,
    required bool noFolding,
    required String paymentId,
    String paymentType = 'ONLINE',
    String paymentStatus = 'SUCCEEDED',
  }) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/order/create"),
        headers: {
          "Authorization": "Bearer ${HiveClass.getToken()}",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "noFolding": noFolding,
          "paymentType": paymentType,
          "paymentId": paymentId,
          "paymentStatus": paymentStatus,
        }),
      );

      if (res.statusCode == 401) {
        LogoutClass.logOut2(context);
        return false;
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        log("Order created successfully: ${res.body}");
        return true;
      } else {
        final dynamic body = jsonDecode(res.body);
        final String errorMsg = body['error'] ?? 'Failed to create order';
        log("Failed to create order (${res.statusCode}): $errorMsg");
        MyMessageHandler.showSnackBar(scaffoldKey, errorMsg);
        return false;
      }
    } catch (e) {
      log("Exception creating order: $e");
      MyMessageHandler.showSnackBar(scaffoldKey, "Error creating order: ${e.toString()}");
      return false;
    }
  }
}

class PayStackOrderClass {
  static Future<bool> payStackOrder({
    required BuildContext context,
    required GlobalKey<ScaffoldMessengerState> scaffoldKey,
    required int totalAmount,
    required bool noFolding,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final secretKey = Constants.payStackSecretKey;
    final reference = 'ps_${DateTime.now().millisecondsSinceEpoch}';

    final request = PaystackTransactionRequest(
      reference: reference,
      secretKey: secretKey,
      email: authProvider.email.isNotEmpty ? authProvider.email : 'customer@foamlaundryapp.com',
      amount: (totalAmount * 100).toDouble(),
      currency: PaystackCurrency.ngn,
      channel: [
        PaystackPaymentChannel.mobileMoney,
        PaystackPaymentChannel.card,
        PaystackPaymentChannel.ussd,
        PaystackPaymentChannel.bankTransfer,
        PaystackPaymentChannel.bank,
        PaystackPaymentChannel.qr,
        PaystackPaymentChannel.eft,
      ],
    );

    final initializedTransaction =
        await PaymentService.initializeTransaction(request);

    if (!initializedTransaction.status) {
      MyMessageHandler.showSnackBar(
        scaffoldKey,
        initializedTransaction.message.isNotEmpty
            ? initializedTransaction.message
            : 'Payment initialization failed',
      );
      return false;
    }

    // Show Paystack payment modal once
    await PaymentService.showPaymentModal(
      context,
      transaction: initializedTransaction,
      callbackUrl: 'https://foamlaundryapp.netlify.app',
    );

    final String transactionRef =
        initializedTransaction.data?.reference ?? reference;

    // Verify transaction status with Paystack
    final verifyResponse = await PaymentService.verifyTransaction(
      paystackSecretKey: secretKey,
      transactionRef,
    );

    log("Paystack verification response status: ${verifyResponse.status}, transaction status: ${verifyResponse.data?.status}");

    final bool isPaymentSuccess = verifyResponse.status &&
        (verifyResponse.data?.status == PaystackTransactionStatus.success ||
            verifyResponse.data?.status.toString().toLowerCase().contains('success') == true);

    if (isPaymentSuccess) {
      final bool orderCreated = await OrderClass.createOrder(
        context: context,
        scaffoldKey: scaffoldKey,
        noFolding: noFolding,
        paymentId: initializedTransaction.data?.reference ?? reference,
        paymentType: 'ONLINE',
        paymentStatus: 'SUCCEEDED',
      );

      if (orderCreated) {
        MyMessageHandler.showSnackBar(scaffoldKey, "Order placed successfully!");
        return true;
      }
    } else {
      MyMessageHandler.showSnackBar(
        scaffoldKey,
        "Payment was not completed or failed. Please try again.",
      );
    }

    return false;
  }
}
