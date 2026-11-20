import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pay/pay.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/customer_schedule_service.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/wallet/controller/wallet_provider.dart';
import 'package:foam_mobile/utils/values.dart';

enum FoamPaymentMethod {
  wallet,
  paystack,
  googlePay,
  applePay,
}

enum FoamPaymentPurpose {
  subscription,
  order,
  walletDeposit,
}

class PaymentProcessResult {
  final bool success;
  final String message;
  final String? reference;
  final Map<String, dynamic>? data;
  final bool insufficientWallet;
  final double? shortfall;

  PaymentProcessResult({
    required this.success,
    required this.message,
    this.reference,
    this.data,
    this.insufficientWallet = false,
    this.shortfall,
  });
}

class FoamPaymentService {
  static Map<String, String> get _headers => {
        "Authorization": "Bearer ${HiveClass.getToken()}",
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

  static const String googlePayConfigJson = '''{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "paystack",
            "gatewayMerchantId": "pk_test_54b24598d6fa688ebf11aa69f689ae41e7765d2d"
          }
        },
        "parameters": {
          "allowedCardNetworks": ["VISA", "MASTERCARD"],
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "billingAddressRequired": false
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "BCR2DN6DZKL7RYTR",
      "merchantName": "Foam"
    },
    "transactionInfo": {
      "countryCode": "NG",
      "currencyCode": "NGN"
    }
  }
}''';

  static const String _applePayConfigJson = '''{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.foamlaundryapp",
    "displayName": "Foam Laundry",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["amex", "visa", "discover", "masterCard"],
    "countryCode": "NG",
    "currencyCode": "NGN",
    "requiredBillingContactFields": ["emailAddress", "name", "phoneNumber"]
  }
}''';

  static Pay? _payClient;

  /// Initializes the native Pay client with Google Pay & Apple Pay profiles
  static Future<Pay> _getPayClient() async {
    if (_payClient != null) return _payClient!;
    try {
      final googleConfig =
          PaymentConfiguration.fromJsonString(googlePayConfigJson);
      final appleConfig =
          PaymentConfiguration.fromJsonString(_applePayConfigJson);
      _payClient = Pay({
        PayProvider.google_pay: googleConfig,
        PayProvider.apple_pay: appleConfig,
      });
      return _payClient!;
    } catch (e) {
      debugPrint('Error initializing in-memory Pay configurations: $e');
      final googleConfig = await PaymentConfiguration.fromAsset(
          'payment/default_google_pay_config.json');
      final appleConfig = await PaymentConfiguration.fromAsset(
          'payment/default_apple_pay_config.json');
      _payClient = Pay({
        PayProvider.google_pay: googleConfig,
        PayProvider.apple_pay: appleConfig,
      });
      return _payClient!;
    }
  }

  static const EventChannel _googlePayEventChannel =
      EventChannel('plugins.flutter.io/pay/payment_result');

  /// Safe wrapper to invoke the payment selector across platforms.
  /// On Android (Google Pay), package:pay requires an active EventChannel listener
  /// before calling showPaymentSelector, otherwise it throws illegalEventChannelState.
  /// On iOS (Apple Pay), results return synchronously from the method call.
  static Future<Map<String, dynamic>> _showPlatformPaymentSelector(
    Pay payClient,
    PayProvider provider,
    List<PaymentItem> items,
  ) async {
    if (provider == PayProvider.google_pay &&
        defaultTargetPlatform == TargetPlatform.android) {
      final completer = Completer<Map<String, dynamic>>();
      StreamSubscription? subscription;

      subscription = _googlePayEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          subscription?.cancel();
          if (!completer.isCompleted) {
            try {
              if (event is String) {
                final decoded = jsonDecode(event);
                if (decoded is Map<String, dynamic>) {
                  completer.complete(decoded);
                } else if (decoded is Map) {
                  completer.complete(Map<String, dynamic>.from(decoded));
                } else {
                  completer.complete({'data': decoded});
                }
              } else if (event is Map<String, dynamic>) {
                completer.complete(event);
              } else if (event is Map) {
                completer.complete(Map<String, dynamic>.from(event));
              } else {
                completer.complete({'data': event});
              }
            } catch (err) {
              completer.completeError(err);
            }
          }
        },
        onError: (dynamic error) {
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.completeError('Google Pay stream closed unexpectedly.');
          }
        },
        cancelOnError: true,
      );

      try {
        await payClient.showPaymentSelector(provider, items);
      } catch (e) {
        subscription.cancel();
        rethrow;
      }

      return await completer.future;
    } else {
      return await payClient.showPaymentSelector(provider, items);
    }
  }

  /// -------------------------------------------------------------
  /// 1. SUBSCRIPTIONS END-TO-END
  /// -------------------------------------------------------------

  /// Subscribe to a plan using the chosen payment method
  static Future<PaymentProcessResult> processSubscription({
    required BuildContext context,
    required dynamic plan,
    required FoamPaymentMethod method,
  }) async {
    final planId = plan['id'];
    final double planPrice = (plan['price'] as num?)?.toDouble() ?? 0.0;
    final planName = plan['name'] ?? 'Subscription';

    // A. FOAM WALLET (For supported accounts)
    if (method == FoamPaymentMethod.wallet) {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.fetchWallet();
      final currentBalance = walletProvider.balance;

      if (currentBalance < planPrice) {
        final shortfall = planPrice - currentBalance;
        return PaymentProcessResult(
          success: false,
          insufficientWallet: true,
          shortfall: shortfall,
          message:
              'Insufficient wallet balance. Shortfall: ₦${shortfall.toStringAsFixed(0)}',
        );
      }

      try {
        final res = await http.post(
          Uri.parse("${Constants.url}/api/subscriptions/subscribe"),
          headers: _headers,
          body: jsonEncode({
            "planId": planId,
            "paymentMethod": "WALLET",
          }),
        );

        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          await walletProvider.fetchWallet();
          return PaymentProcessResult(
            success: true,
            message: 'Subscribed to $planName via Foam Wallet! 🎉',
            data: data['subscription'],
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message: data['error'] ?? data['message'] ?? 'Subscription failed',
          );
        }
      } catch (e) {
        return PaymentProcessResult(
            success: false, message: 'Network connection error: $e');
      }
    }

    // B. PAYSTACK
    if (method == FoamPaymentMethod.paystack) {
      try {
        // Step 1: Initialize transaction with backend
        final initRes = await http.post(
          Uri.parse("${Constants.url}/api/subscriptions/initialize-payment"),
          headers: _headers,
          body: jsonEncode({
            "planId": planId,
            "paymentMethod": "PAYSTACK",
          }),
        );

        final dynamic initData = jsonDecode(initRes.body);

        if (initRes.statusCode != 200) {
          final errorMsg = initData['error'] ??
              initData['message'] ??
              'Failed to initialize Paystack payment (${initRes.statusCode})';
          return PaymentProcessResult(
            success: false,
            message: errorMsg,
          );
        }

        final String reference = initData['reference'] ?? '';
        final String? authUrl = initData['authorization_url'];

        if (authUrl == null || authUrl.isEmpty) {
          return PaymentProcessResult(
            success: false,
            message: 'Paystack authorization URL was not received from server.',
          );
        }

        // Step 2: Open Paystack interactive webview modal
        if (!context.mounted) {
          return PaymentProcessResult(
              success: false, message: 'Payment cancelled');
        }

        final completed = await _showPaystackCheckoutModal(
          context: context,
          title: 'Paystack Checkout',
          planName: planName,
          amount: planPrice,
          authUrl: authUrl,
          reference: reference,
        );

        if (!completed) {
          return PaymentProcessResult(
            success: false,
            message: 'Paystack payment was cancelled or closed.',
          );
        }

        // Step 3: Verify payment with backend
        final verifyRes = await http.post(
          Uri.parse("${Constants.url}/api/subscriptions/verify-payment"),
          headers: _headers,
          body: jsonEncode({
            "reference": reference,
            "planId": planId,
          }),
        );

        final dynamic verifyData = jsonDecode(verifyRes.body);
        if (verifyRes.statusCode == 200) {
          return PaymentProcessResult(
            success: true,
            message: 'Subscribed to $planName via Paystack! 🎉',
            reference: reference,
            data: verifyData['subscription'],
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message: verifyData['error'] ??
                verifyData['message'] ??
                'Payment verification failed with Paystack.',
          );
        }
      } catch (e) {
        return PaymentProcessResult(
            success: false, message: 'Paystack checkout error: $e');
      }
    }

    // C. GOOGLE PAY (Native Android)
    if (method == FoamPaymentMethod.googlePay) {
      try {
        final payClient = await _getPayClient();
        final canPay = await payClient.userCanPay(PayProvider.google_pay);

        if (!canPay) {
          return PaymentProcessResult(
            success: false,
            message:
                'Google Pay is not set up on this device or has no active payment methods. Please configure Google Wallet or pay with Debit Card via Paystack.',
          );
        }

        final paymentResult = await _showPlatformPaymentSelector(
          payClient,
          PayProvider.google_pay,
          [
            PaymentItem(
              label: planName,
              amount: planPrice.toStringAsFixed(2),
              status: PaymentItemStatus.final_price,
            ),
          ],
        );

        final reference = 'sub_gpay_${DateTime.now().millisecondsSinceEpoch}';

        final res = await http.post(
          Uri.parse("${Constants.url}/api/subscriptions/mobile-pay"),
          headers: _headers,
          body: jsonEncode({
            "planId": planId.toString(),
            "provider": "GOOGLE_PAY",
            "token": jsonEncode(paymentResult),
            "reference": reference,
          }),
        );

        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          return PaymentProcessResult(
            success: true,
            message: 'Subscribed to $planName via Google Pay! 🎉',
            data: data['subscription'],
            reference: reference,
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message: data['error'] ??
                data['message'] ??
                'Google Pay transaction failed on server.',
          );
        }
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('Canceled') ||
            errStr.contains('canceled') ||
            errStr.contains('USER_CANCELLED')) {
          return PaymentProcessResult(
              success: false, message: 'Google Pay was cancelled by user.');
        }
        return PaymentProcessResult(
            success: false, message: 'Google Pay error: $e');
      }
    }

    // D. APPLE PAY (Native iOS)
    if (method == FoamPaymentMethod.applePay) {
      try {
        final payClient = await _getPayClient();
        final canPay = await payClient.userCanPay(PayProvider.apple_pay);

        if (!canPay) {
          return PaymentProcessResult(
            success: false,
            message:
                'Apple Pay is not configured on this device or has no supported cards. Please add a card to Apple Wallet or pay via Paystack.',
          );
        }

        final paymentResult = await _showPlatformPaymentSelector(
          payClient,
          PayProvider.apple_pay,
          [
            PaymentItem(
              label: planName,
              amount: planPrice.toStringAsFixed(2),
              status: PaymentItemStatus.final_price,
            ),
          ],
        );

        final reference = 'sub_apay_${DateTime.now().millisecondsSinceEpoch}';

        final res = await http.post(
          Uri.parse("${Constants.url}/api/subscriptions/mobile-pay"),
          headers: _headers,
          body: jsonEncode({
            "planId": planId.toString(),
            "provider": "APPLE_PAY",
            "token": jsonEncode(paymentResult),
            "reference": reference,
          }),
        );

        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          return PaymentProcessResult(
            success: true,
            message: 'Subscribed to $planName via Apple Pay! 🎉',
            data: data['subscription'],
            reference: reference,
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message: data['error'] ??
                data['message'] ??
                'Apple Pay transaction failed on server.',
          );
        }
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('Canceled') ||
            errStr.contains('canceled') ||
            errStr.contains('USER_CANCELLED')) {
          return PaymentProcessResult(
              success: false, message: 'Apple Pay was cancelled by user.');
        }
        return PaymentProcessResult(
            success: false, message: 'Apple Pay error: $e');
      }
    }

    return PaymentProcessResult(
        success: false, message: 'Unsupported payment method');
  }

  /// -------------------------------------------------------------
  /// 2. LAUNDRY ORDERS END-TO-END
  /// -------------------------------------------------------------

  /// Pay for and place a laundry order using the chosen payment method
  static Future<PaymentProcessResult> processOrderPayment({
    required BuildContext context,
    required bool noFolding,
    required double totalPrice,
    String? storeId,
    required FoamPaymentMethod method,
    String? pickupAddress,
    String? deliveryAddress,
    DateTime? pickupDate,
    String? pickupTime,
    DateTime? deliveryDate,
    String? deliveryTime,
  }) async {
    // A. WALLET
    if (method == FoamPaymentMethod.wallet) {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.fetchWallet();

      if (walletProvider.balance < totalPrice) {
        final shortfall = totalPrice - walletProvider.balance;
        return PaymentProcessResult(
          success: false,
          insufficientWallet: true,
          shortfall: shortfall,
          message: 'Insufficient wallet balance',
        );
      }

      try {
        final res = await http.post(
          Uri.parse("${Constants.url}/api/order/create"),
          headers: _headers,
          body: jsonEncode({
            "noFolding": noFolding,
            "storeId": storeId,
            "pickupAddress": pickupAddress,
            "deliveryAddress": deliveryAddress ?? pickupAddress,
            "pickupDate": pickupDate?.toIso8601String(),
            "pickupTime": pickupTime,
            "deliveryDate": deliveryDate?.toIso8601String(),
            "deliveryTime": deliveryTime,
          }),
        );

        final data = jsonDecode(res.body);
        if (res.statusCode == 201 || res.statusCode == 200) {
          await walletProvider.fetchWallet();
          return PaymentProcessResult(
            success: true,
            message: 'Order placed successfully with Foam Wallet! 🧺',
            data: data['order'],
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message: data['error'] ?? 'Failed to place order',
          );
        }
      } catch (e) {
        return PaymentProcessResult(success: false, message: 'Order error: $e');
      }
    }

    // B. PAYSTACK
    if (method == FoamPaymentMethod.paystack) {
      try {
        final initRes = await http.post(
          Uri.parse("${Constants.url}/api/payment/paystack/initialize-order"),
          headers: _headers,
          body: jsonEncode({
            "noFolding": noFolding,
            "storeId": storeId,
            "pickupAddress": pickupAddress,
            "deliveryAddress": deliveryAddress ?? pickupAddress,
            "pickupDate": pickupDate?.toIso8601String(),
            "pickupTime": pickupTime,
            "deliveryDate": deliveryDate?.toIso8601String(),
            "deliveryTime": deliveryTime,
          }),
        );

        final initData = jsonDecode(initRes.body);

        if (initRes.statusCode != 200) {
          final err = initData['error'] ??
              initData['message'] ??
              'Failed to initialize Paystack order payment';
          return PaymentProcessResult(
            success: false,
            message: err,
          );
        }

        final String reference = initData['reference'] ?? '';
        final String? authUrl = initData['authorization_url'];

        if (authUrl == null || authUrl.isEmpty) {
          return PaymentProcessResult(
              success: false, message: 'No authorization URL received');
        }

        if (!context.mounted) {
          return PaymentProcessResult(
              success: false, message: 'Payment cancelled');
        }

        final completed = await _showPaystackCheckoutModal(
          context: context,
          title: 'Paystack Order Payment',
          planName: 'Foam Laundry Order',
          amount: totalPrice,
          authUrl: authUrl,
          reference: reference,
        );

        if (!completed) {
          return PaymentProcessResult(
              success: false, message: 'Order payment cancelled or closed');
        }

        final verifyRes = await http.post(
          Uri.parse("${Constants.url}/api/payment/paystack/verify/$reference"),
          headers: _headers,
        );

        final verifyData = jsonDecode(verifyRes.body);
        if (verifyRes.statusCode == 200) {
          return PaymentProcessResult(
            success: true,
            message: 'Order paid and confirmed via Paystack! 🧺',
            reference: reference,
            data: verifyData['result'],
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message: verifyData['error'] ??
                verifyData['message'] ??
                'Order payment verification failed',
          );
        }
      } catch (e) {
        return PaymentProcessResult(
            success: false, message: 'Paystack order error: $e');
      }
    }

    // C. GOOGLE PAY / APPLE PAY
    if (method == FoamPaymentMethod.googlePay ||
        method == FoamPaymentMethod.applePay) {
      final isGoogle = method == FoamPaymentMethod.googlePay;
      final provider = isGoogle ? 'GOOGLE_PAY' : 'APPLE_PAY';
      final providerName = isGoogle ? 'Google Pay' : 'Apple Pay';
      final payProvider =
          isGoogle ? PayProvider.google_pay : PayProvider.apple_pay;

      try {
        final payClient = await _getPayClient();
        final canPay = await payClient.userCanPay(payProvider);

        if (!canPay) {
          return PaymentProcessResult(
            success: false,
            message:
                '$providerName is not available on this device. Please select Paystack to pay with Debit Card.',
          );
        }

        final paymentResult = await _showPlatformPaymentSelector(
          payClient,
          payProvider,
          [
            PaymentItem(
              label: 'Foam Laundry Order',
              amount: totalPrice.toStringAsFixed(2),
              status: PaymentItemStatus.final_price,
            ),
          ],
        );

        final res = await http.post(
          Uri.parse("${Constants.url}/api/payment/mobile-pay/process"),
          headers: _headers,
          body: jsonEncode({
            "provider": provider,
            "purpose": "ORDER",
            "amount": totalPrice,
            "noFolding": noFolding,
            "storeId": storeId,
            "token": jsonEncode(paymentResult),
            "pickupAddress": pickupAddress,
            "deliveryAddress": deliveryAddress ?? pickupAddress,
            "pickupDate": pickupDate?.toIso8601String(),
            "pickupTime": pickupTime,
            "deliveryDate": deliveryDate?.toIso8601String(),
            "deliveryTime": deliveryTime,
          }),
        );

        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          return PaymentProcessResult(
            success: true,
            message: 'Order confirmed with $providerName! 🧺',
            data: data['order'],
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message: data['error'] ??
                data['message'] ??
                '$providerName order failed on server',
          );
        }
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('Canceled') ||
            errStr.contains('canceled') ||
            errStr.contains('USER_CANCELLED')) {
          return PaymentProcessResult(
              success: false, message: '$providerName was cancelled by user.');
        }
        return PaymentProcessResult(
            success: false, message: '$providerName error: $e');
      }
    }

    return PaymentProcessResult(
        success: false, message: 'Invalid payment method');
  }

  /// -------------------------------------------------------------
  /// 2b. VENDOR SCHEDULE PICKUP ORDERS END-TO-END
  /// -------------------------------------------------------------

  /// Pay for and place a vendor schedule order using the chosen payment method
  /// ONLY succeeds and confirms order when payment is fully verified.
  static Future<PaymentProcessResult> processScheduleOrderPayment({
    required BuildContext context,
    required SchedulePickupProvider provider,
    required FoamPaymentMethod method,
    required double amount,
    required String pickupAddress,
    DateTime? pickupDate,
    String? pickupTime,
    String? deliveryAddress,
    DateTime? deliveryDate,
    String? deliveryTime,
  }) async {
    final storeName = provider.currentStore.name.isNotEmpty
        ? provider.currentStore.name
        : 'Foam Laundry Store';
    final int amountInt = amount.round();

    // A. PAYSTACK
    if (method == FoamPaymentMethod.paystack) {
      try {
        final initRes = await CustomerScheduleService.initializeSchedulePayment(
          storeId: provider.currentStore.id,
          tier: provider.selectedTierId,
          items: provider.items,
          pickupAddress: pickupAddress,
          pickupTime: pickupTime ?? provider.pickupSlot,
          deliveryAddress: deliveryAddress ?? pickupAddress,
          totalPrice: amountInt,
        );

        if (initRes['status'] != true || initRes['reference'] == null) {
          final err = initRes['error'] ??
              initRes['message'] ??
              'Failed to initialize Paystack order payment';
          return PaymentProcessResult(success: false, message: err);
        }

        final String reference = initRes['reference'];
        final String? authUrl = initRes['authorization_url'];

        if (authUrl == null || authUrl.isEmpty) {
          return PaymentProcessResult(
            success: false,
            message: 'Paystack authorization URL was not received from server.',
          );
        }

        if (!context.mounted) {
          return PaymentProcessResult(
              success: false, message: 'Payment cancelled');
        }

        final completed = await _showPaystackCheckoutModal(
          context: context,
          title: 'Paystack Checkout',
          planName: 'Order at $storeName',
          amount: amount,
          authUrl: authUrl,
          reference: reference,
        );

        if (!completed) {
          return PaymentProcessResult(
            success: false,
            message: 'Paystack payment was cancelled or closed.',
          );
        }

        // Verify and create order with backend
        final success =
            await provider.processPaystackOrder(paystackRef: reference);
        if (success && provider.lastCreatedOrder != null) {
          return PaymentProcessResult(
            success: true,
            message: 'Order paid and confirmed via Paystack! 🧺',
            reference: reference,
            data: provider.lastCreatedOrder,
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message:
                'Payment verification failed with Paystack. Order was not placed.',
          );
        }
      } catch (e) {
        return PaymentProcessResult(
          success: false,
          message: 'Paystack payment error: $e',
        );
      }
    }

    // B. APPLE PAY (Native iOS - NOT Paystack)
    // "the apple payment work on it dont paysatck for it use apple it self of it"
    if (method == FoamPaymentMethod.applePay) {
      try {
        final payClient = await _getPayClient();
        final canPay = await payClient.userCanPay(PayProvider.apple_pay);

        if (!canPay) {
          return PaymentProcessResult(
            success: false,
            message:
                'Apple Pay is not configured on this device or has no supported cards. Please add a card to Apple Wallet or pay via Paystack.',
          );
        }

        final paymentResult = await _showPlatformPaymentSelector(
          payClient,
          PayProvider.apple_pay,
          [
            PaymentItem(
              label: storeName,
              amount: amount.toStringAsFixed(2),
              status: PaymentItemStatus.final_price,
            ),
          ],
        );

        final reference =
            'ord_sched_apay_${DateTime.now().millisecondsSinceEpoch}';

        final success = await provider.processApplePayOrder(
          token: jsonEncode(paymentResult),
          reference: reference,
        );

        if (success && provider.lastCreatedOrder != null) {
          return PaymentProcessResult(
            success: true,
            message: 'Order confirmed with Apple Pay! 🧺',
            reference: reference,
            data: provider.lastCreatedOrder,
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message:
                'Apple Pay transaction failed on server. Order was not placed.',
          );
        }
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('Canceled') ||
            errStr.contains('canceled') ||
            errStr.contains('USER_CANCELLED')) {
          return PaymentProcessResult(
              success: false, message: 'Apple Pay was cancelled by user.');
        }
        return PaymentProcessResult(
            success: false, message: 'Apple Pay error: $e');
      }
    }

    // C. GOOGLE PAY (Native Android)
    if (method == FoamPaymentMethod.googlePay) {
      try {
        final payClient = await _getPayClient();
        final canPay = await payClient.userCanPay(PayProvider.google_pay);

        if (!canPay) {
          return PaymentProcessResult(
            success: false,
            message:
                'Google Pay is not set up on this device or has no active payment methods. Please configure Google Wallet or pay with Debit Card via Paystack.',
          );
        }

        final paymentResult = await _showPlatformPaymentSelector(
          payClient,
          PayProvider.google_pay,
          [
            PaymentItem(
              label: storeName,
              amount: amount.toStringAsFixed(2),
              status: PaymentItemStatus.final_price,
            ),
          ],
        );

        final reference =
            'ord_sched_gpay_${DateTime.now().millisecondsSinceEpoch}';

        final success = await provider.processGooglePayOrder(
          token: jsonEncode(paymentResult),
          reference: reference,
        );

        if (success && provider.lastCreatedOrder != null) {
          return PaymentProcessResult(
            success: true,
            message: 'Order confirmed with Google Pay! 🧺',
            reference: reference,
            data: provider.lastCreatedOrder,
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message:
                'Google Pay transaction failed on server. Order was not placed.',
          );
        }
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('Canceled') ||
            errStr.contains('canceled') ||
            errStr.contains('USER_CANCELLED')) {
          return PaymentProcessResult(
              success: false, message: 'Google Pay was cancelled by user.');
        }
        return PaymentProcessResult(
            success: false, message: 'Google Pay error: $e');
      }
    }

    return PaymentProcessResult(
        success: false, message: 'Invalid payment method');
  }

  /// -------------------------------------------------------------
  /// 3. WALLET TOP-UP END-TO-END (Vendor / Supported Accounts)
  /// -------------------------------------------------------------

  static Future<PaymentProcessResult> processWalletDeposit({
    required BuildContext context,
    required double amount,
    required FoamPaymentMethod method,
  }) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    // Paystack Top-Up
    if (method == FoamPaymentMethod.paystack) {
      final initData = await walletProvider.initializeDeposit(amount);
      if (initData == null || initData['reference'] == null) {
        return PaymentProcessResult(
            success: false, message: 'Failed to initialize wallet deposit');
      }

      final String reference = initData['reference'];
      final String? authUrl = initData['authorization_url'];

      if (!context.mounted) {
        return PaymentProcessResult(
            success: false, message: 'Payment cancelled');
      }
      final completed = await _showPaystackCheckoutModal(
        context: context,
        title: 'Paystack Wallet Deposit',
        planName: 'Foam Wallet Top-Up',
        amount: amount,
        authUrl: authUrl,
        reference: reference,
      );

      if (!completed) {
        return PaymentProcessResult(
            success: false, message: 'Deposit cancelled');
      }

      final verified = await walletProvider.verifyDeposit(reference);
      if (verified) {
        return PaymentProcessResult(
          success: true,
          message:
              '₦${amount.toStringAsFixed(0)} deposited to wallet via Paystack! 💳',
          reference: reference,
        );
      } else {
        return PaymentProcessResult(
            success: false, message: 'Wallet deposit verification failed');
      }
    }

    // Google Pay / Apple Pay Top-Up
    if (method == FoamPaymentMethod.googlePay ||
        method == FoamPaymentMethod.applePay) {
      final isGoogle = method == FoamPaymentMethod.googlePay;
      final provider = isGoogle ? 'GOOGLE_PAY' : 'APPLE_PAY';
      final providerName = isGoogle ? 'Google Pay' : 'Apple Pay';
      final payProvider =
          isGoogle ? PayProvider.google_pay : PayProvider.apple_pay;

      try {
        final payClient = await _getPayClient();
        final canPay = await payClient.userCanPay(payProvider);

        if (!canPay) {
          return PaymentProcessResult(
            success: false,
            message: '$providerName is not available on this device.',
          );
        }

        final paymentResult = await _showPlatformPaymentSelector(
          payClient,
          payProvider,
          [
            PaymentItem(
              label: 'Wallet Top-Up',
              amount: amount.toStringAsFixed(2),
              status: PaymentItemStatus.final_price,
            ),
          ],
        );

        final res = await http.post(
          Uri.parse("${Constants.url}/api/payment/mobile-pay/process"),
          headers: _headers,
          body: jsonEncode({
            "provider": provider,
            "purpose": "WALLET_DEPOSIT",
            "amount": amount,
            "token": jsonEncode(paymentResult),
          }),
        );

        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          await walletProvider.fetchWallet();
          return PaymentProcessResult(
            success: true,
            message:
                '₦${amount.toStringAsFixed(0)} credited to wallet via $providerName! 💳',
          );
        } else {
          return PaymentProcessResult(
            success: false,
            message: data['error'] ?? '$providerName top-up failed',
          );
        }
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('Canceled') || errStr.contains('canceled')) {
          return PaymentProcessResult(
              success: false, message: '$providerName top-up cancelled.');
        }
        return PaymentProcessResult(
            success: false, message: '$providerName error: $e');
      }
    }

    return PaymentProcessResult(
        success: false, message: 'Unsupported top-up method');
  }

  /// -------------------------------------------------------------
  /// 4. SUBSCRIPTION LIFECYCLE HELPERS
  /// -------------------------------------------------------------

  /// Cancel active subscription auto-renew
  static Future<bool> cancelActiveSubscription() async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/subscriptions/cancel"),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Error cancelling subscription: $e");
      return false;
    }
  }

  /// Fetch subscription history
  static Future<List<Map<String, dynamic>>> fetchSubscriptionHistory() async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/subscriptions/history"),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['history'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching subscription history: $e");
      return [];
    }
  }

  /// -------------------------------------------------------------
  /// 5. PAYSTACK INTERACTIVE WEBVIEW MODAL
  /// -------------------------------------------------------------

  /// Shows Paystack checkout webview dialog loading the live authorization URL
  static Future<bool> showPaystackCheckoutModal({
    required BuildContext context,
    required String title,
    required String planName,
    required double amount,
    String? authUrl,
    required String reference,
  }) async {
    return _showPaystackCheckoutModal(
      context: context,
      title: title,
      planName: planName,
      amount: amount,
      authUrl: authUrl,
      reference: reference,
    );
  }

  static Future<bool> _showPaystackCheckoutModal({
    required BuildContext context,
    required String title,
    required String planName,
    required double amount,
    String? authUrl,
    required String reference,
  }) async {
    if (authUrl == null || authUrl.isEmpty) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Paystack Error'),
              ],
            ),
            content: const Text(
                'No valid Paystack checkout URL was provided by the payment server.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
      return false;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (ctx) {
        return PaystackCheckoutModal(
          authUrl: authUrl,
          title: title,
          planName: planName,
          amount: amount,
          reference: reference,
        );
      },
    );

    return result ?? false;
  }
}

/// Dedicated Paystack interactive WebView sheet
class PaystackCheckoutModal extends StatefulWidget {
  final String authUrl;
  final String title;
  final String planName;
  final double amount;
  final String reference;

  const PaystackCheckoutModal({
    super.key,
    required this.authUrl,
    required this.title,
    required this.planName,
    required this.amount,
    required this.reference,
  });

  @override
  State<PaystackCheckoutModal> createState() => _PaystackCheckoutModalState();
}

class _PaystackCheckoutModalState extends State<PaystackCheckoutModal> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
            final lower = url.toLowerCase();
            if (lower.contains('/callback') ||
                lower.contains('standard/callback') ||
                lower.contains('status=success') ||
                lower.contains('trxref=')) {
              Navigator.pop(context, true);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (request) {
            final lower = request.url.toLowerCase();
            if (lower.contains('/payment/callback') ||
                lower.contains('standard/callback') ||
                lower.contains('status=success')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            if (lower.contains('cancel') || lower.contains('close')) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0098A6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded,
                            size: 16, color: Color(0xFF0098A6)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '₦${widget.amount.toStringAsFixed(0)} • ${widget.planName}',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF0098A6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'I have paid',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: Colors.grey),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF0098A6),
              backgroundColor: Color(0xFFE0F2FE),
            ),

          if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load Paystack checkout:\n$_errorMessage',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0098A6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _controller.reload();
                        },
                        child: Text('Retry Connection',
                            style: GoogleFonts.dmSans(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
        ],
      ),
    );
  }
}
