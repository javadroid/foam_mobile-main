import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/feature/wallet/models/wallet_models.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:http/http.dart' as http;

class WalletProvider extends ChangeNotifier {
  double _balance = 0.0;
  double _pendingBalance = 0.0;
  String _currency = 'NGN';
  bool _isLoading = false;
  List<WalletLedgerItem> _ledger = [];

  double get balance => _balance;
  double get pendingBalance => _pendingBalance;
  String get currency => _currency;
  bool get isLoading => _isLoading;
  List<WalletLedgerItem> get ledger => _ledger;

  Map<String, String> get _headers => {
        "Authorization": "Bearer ${HiveClass.getToken()}",
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

  Future<void> fetchWallet() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/wallet"),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        _pendingBalance = (data['pendingBalance'] as num?)?.toDouble() ?? 0.0;
        _currency = data['currency'] ?? 'NGN';
      }
    } catch (e) {
      log("Error fetching wallet: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLedger({int page = 1, int limit = 20}) async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/wallet/ledger?page=$page&limit=$limit"),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List entries = data['entries'] ?? [];
        _ledger = entries.map((e) => WalletLedgerItem.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      log("Error fetching ledger: $e");
    }
  }

  Future<Map<String, dynamic>?> initializeDeposit(double amount) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/wallet/deposit/initialize"),
        headers: _headers,
        body: jsonEncode({"amount": amount}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      log("Initialize deposit failed: ${res.body}");
      return null;
    } catch (e) {
      log("Error initializing deposit: $e");
      return null;
    }
  }

  Future<bool> verifyDeposit(String reference) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.url}/api/wallet/deposit/verify"),
        headers: _headers,
        body: jsonEncode({"reference": reference}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _balance = (data['balance'] as num?)?.toDouble() ?? _balance;
        notifyListeners();
        await fetchLedger();
        return true;
      }
      return false;
    } catch (e) {
      log("Error verifying deposit: $e");
      return false;
    }
  }
}
