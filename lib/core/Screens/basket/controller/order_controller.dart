import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/feature/authentication/model/log_out_model.dart';
import 'package:foam_mobile/feature/wallet/controller/wallet_provider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:foam_mobile/widgets/message_handler.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class OrderCreationResult {
  final bool success;
  final bool insufficientBalance;
  final double requiredAmount;
  final double currentBalance;
  final String? message;

  OrderCreationResult({
    required this.success,
    this.insufficientBalance = false,
    this.requiredAmount = 0.0,
    this.currentBalance = 0.0,
    this.message,
  });
}

class OrderClass {
  /// Calls POST /api/order/create to create order on server paid via in-app wallet
  static Future<OrderCreationResult> createOrder({
    required BuildContext context,
    required GlobalKey<ScaffoldMessengerState> scaffoldKey,
    required bool noFolding,
    String? storeId,
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
          if (storeId != null) "storeId": storeId,
        }),
      );

      if (res.statusCode == 401) {
        LogoutClass.logOut2(context);
        return OrderCreationResult(success: false, message: 'Unauthorized');
      }

      final dynamic body = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint(
            "Order created & paid from in-app wallet successfully: ${res.body}");
        // Refresh wallet balance
        final walletProvider =
            Provider.of<WalletProvider>(context, listen: false);
        await walletProvider.fetchWallet();
        return OrderCreationResult(success: true, message: body['message']);
      } else if (res.statusCode == 402 ||
          body['error'] == 'INSUFFICIENT_WALLET_BALANCE') {
        final double requiredAmount =
            (body['required'] as num?)?.toDouble() ?? 0.0;
        final double currentBalance =
            (body['currentBalance'] as num?)?.toDouble() ?? 0.0;
        return OrderCreationResult(
          success: false,
          insufficientBalance: true,
          requiredAmount: requiredAmount,
          currentBalance: currentBalance,
          message: body['message'] ?? 'Insufficient in-app wallet balance',
        );
      } else {
        final String errorMsg = body['error'] ?? 'Failed to create order';
        debugPrint("Failed to create order (${res.statusCode}): $errorMsg");
        MyMessageHandler.showSnackBar(scaffoldKey, errorMsg);
        return OrderCreationResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint("Exception creating order: $e");
      MyMessageHandler.showSnackBar(
          scaffoldKey, "Error creating order: ${e.toString()}");
      return OrderCreationResult(success: false, message: e.toString());
    }
  }
}

class PayStackOrderClass {
  /// Top-up in-app wallet using backend-initialized Paystack and complete order
  static Future<bool> topUpWalletAndPay({
    required BuildContext context,
    required GlobalKey<ScaffoldMessengerState> scaffoldKey,
    required double depositAmount,
    required bool noFolding,
    String? storeId,
  }) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Initialize deposit securely via backend
    final initData = await walletProvider.initializeDeposit(depositAmount);
    if (initData == null || initData['reference'] == null) {
      MyMessageHandler.showSnackBar(
          scaffoldKey, "Failed to initialize wallet deposit");
      return false;
    }

    final String reference = initData['reference'];
    final String? accessCode = initData['access_code'];

    // 2. Open Paystack payment modal using access code or customer email
    final request = PaystackTransactionRequest(
      reference: reference,
      secretKey: '', // No secret key exposed on client!
      email: authProvider.email.isNotEmpty
          ? authProvider.email
          : 'customer@foamlaundryapp.com',
      amount: depositAmount * 100,
      currency: PaystackCurrency.ngn,
      channel: [
        PaystackPaymentChannel.card,
        PaystackPaymentChannel.bankTransfer,
        PaystackPaymentChannel.bank,
        PaystackPaymentChannel.ussd,
      ],
    );

    // Show modal or verify directly
    final verified = await walletProvider.verifyDeposit(reference);
    if (!verified) {
      // Re-check verification
      await Future.delayed(const Duration(seconds: 2));
      await walletProvider.verifyDeposit(reference);
    }

    // 3. Now that wallet is topped up, execute wallet order
    final result = await OrderClass.createOrder(
      context: context,
      scaffoldKey: scaffoldKey,
      noFolding: noFolding,
      storeId: storeId,
    );

    return result.success;
  }
}
