import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:foam_mobile/feature/authentication/controller/provider/authprovider.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:provider/provider.dart';

class PayStackOrderClass {
  static Future<void> payStackOrder(
      BuildContext context,
      GlobalKey<ScaffoldMessengerState> scaffoldKey,
      int totalAmount,
      bool isLoading) async {
    var authProvider = Provider.of<AuthProvider>(context, listen: false);

    final secretKey = Constants.payStackSecretKey;
    final request = PaystackTransactionRequest(
      reference: 'ps_${DateTime.now().microsecondsSinceEpoch}',
      secretKey: secretKey,
      email: authProvider.email,
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

    isLoading = true;
    final initializedTransaction =
        await PaymentService.initializeTransaction(request);

    // if (!mounted) return;
    isLoading = false;

    if (!initializedTransaction.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(initializedTransaction.message),
        ),
      );

      return;
    }

    await PaymentService.showPaymentModal(
      context,
      transaction: initializedTransaction,
      // Callback URL must match the one specified on your paystack dashboard,
      callbackUrl: 'https://foamlaundryapp.netlify.app',
    );

    final response = await PaymentService.showPaymentModal(context,
            transaction: initializedTransaction,
            // Callback URL must match the one specified on your paystack dashboard,
            callbackUrl: '...')
        .then((_) async {
      return await PaymentService.verifyTransaction(
        paystackSecretKey: '...',
        initializedTransaction.data?.reference ?? request.reference,
      );
    });

    log(
      response.toString(),
    ); // Result of the confirmed payment

    // if (kDebugMode)
    //   Logger().i(response.data.status ==
    //       PaystackTransactionStatus
    //           .abandoned);
  }
}
