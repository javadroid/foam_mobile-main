import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket? get socket => _socket;
  static bool get isConnected => _socket?.connected ?? false;

  /// Connect to backend Socket.io server using auth token
  static void connect({
    Function(Map<String, dynamic>)? onNewOrderOffer,
    Function(Map<String, dynamic>)? onOrderStatusUpdated,
    Function(Map<String, dynamic>)? onWalletUpdated,
  }) {
    if (_socket != null && _socket!.connected) return;

    final token = HiveClass.getToken();

    _socket = IO.io(
      Constants.url,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .setQuery({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket.io] Connected to server: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket.io] Disconnected from server');
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket.io] Connection error: $err');
    });

    // Listen for new order offer (for vendors)
    _socket!.on('new_order_offer', (data) {
      debugPrint('[Socket.io] Event received: new_order_offer -> $data');
      if (onNewOrderOffer != null && data is Map) {
        onNewOrderOffer(Map<String, dynamic>.from(data));
      }
    });

    // Listen for order status updates
    _socket!.on('order_status_updated', (data) {
      debugPrint('[Socket.io] Event received: order_status_updated -> $data');
      if (onOrderStatusUpdated != null && data is Map) {
        onOrderStatusUpdated(Map<String, dynamic>.from(data));
      }
    });

    // Listen for wallet credits/debits
    _socket!.on('wallet_credited', (data) {
      debugPrint('[Socket.io] Event received: wallet_credited -> $data');
      if (onWalletUpdated != null && data is Map) {
        onWalletUpdated(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('wallet_updated', (data) {
      debugPrint('[Socket.io] Event received: wallet_updated -> $data');
      if (onWalletUpdated != null && data is Map) {
        onWalletUpdated(Map<String, dynamic>.from(data));
      }
    });

    // Listen for Google Pay / Mobile payment success (backup socket event)
    _socket!.on('payment_succeeded', (data) {
      debugPrint('[Socket.io] Event received: payment_succeeded -> $data');
    });

    // Listen for subscription activated
    _socket!.on('subscription_activated', (data) {
      debugPrint('[Socket.io] Event received: subscription_activated -> $data');
    });
  }

  /// Register custom listener for payment_succeeded event
  static void onPaymentSuccess(Function(Map<String, dynamic>) handler) {
    _socket?.on('payment_succeeded', (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Remove payment_succeeded listener
  static void offPaymentSuccess() {
    _socket?.off('payment_succeeded');
  }

  /// Register custom listener for subscription_activated event
  static void onSubscriptionActive(Function(Map<String, dynamic>) handler) {
    _socket?.on('subscription_activated', (data) {
      if (data is Map) {
        handler(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Remove subscription_activated listener
  static void offSubscriptionActive() {
    _socket?.off('subscription_activated');
  }

  /// Disconnect socket on logout
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      debugPrint('[Socket.io] Socket disconnected and disposed');
    }
  }
}
