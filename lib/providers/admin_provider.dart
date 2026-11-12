import 'package:flutter/material.dart';
import '../core/api_client.dart';

class AdminProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool isLoading = false;
  Map<String, dynamic> users = {};
  List<dynamic> deposits = [];
  List<dynamic> payouts = [];
  List<dynamic> loans = [];
  List<dynamic> tickets = [];
  List<dynamic> voucherOrders = [];
  List<dynamic> kametiPools = [];
  Map<String, dynamic> cmsConfig = {};

  // 1. Fetch All Master Data (Dashboard & Desks)
  Future<void> fetchAllData() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get(
        '',
        queryParameters: {'action': 'get_all', '_t': DateTime.now().millisecondsSinceEpoch},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        users = data['users'] ?? {};
        deposits = data['deposits'] ?? [];
        payouts = data['payouts'] ?? [];
        loans = data['loans'] ?? [];
        tickets = data['tickets'] ?? [];
        voucherOrders = data['voucher_orders'] ?? [];
        kametiPools = data['kameti_pools'] ?? [];
        cmsConfig = data['cmsConfig'] ?? {};
      }
    } catch (e) {
      debugPrint("API Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 2. Manual Payout: Accept / Complete
  Future<bool> completePayout(int id, String tid) async {
    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'complete_manual_payout'},
        data: {'payoutId': id, 'tid': tid, 'adminName': 'Administrator'},
      );
      if (res.data['status'] == 'success') {
        await fetchAllData();
        return true;
      }
    } catch (e) {
      debugPrint("Payout complete error: $e");
    }
    return false;
  }

  // 3. Manual Payout: Reject & Auto-Refund to User Wallet
  Future<bool> rejectPayout(int id, String tid, String mobile, double amount) async {
    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'reject_manual_payout'},
        data: {
          'payoutId': id,
          'tid': tid,
          'senderMobile': mobile,
          'amount': amount,
          'adminName': 'Administrator',
        },
      );
      if (res.data['status'] == 'success') {
        await fetchAllData();
        return true;
      }
    } catch (e) {
      debugPrint("Payout reject error: $e");
    }
    return false;
  }

  // 4. Deposit Review (Approve/Reject)
  Future<bool> reviewDeposit(int depId, bool approved) async {
    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'review_deposit'},
        data: {'depositId': depId, 'approved': approved},
      );
      if (res.data['status'] == 'success') {
        await fetchAllData();
        return true;
      }
    } catch (e) {
      debugPrint("Deposit review error: $e");
    }
    return false;
  }

  // 5. Balance Adjustment
  Future<bool> adjustBalance(String mobile, double amount) async {
    try {
      final res = await _api.dio.post(
        '',
        queryParameters: {'action': 'adjust_balance'},
        data: {'mobile': mobile, 'amount': amount},
      );
      if (res.data['status'] == 'success') {
        await fetchAllData();
        return true;
      }
    } catch (e) {
      debugPrint("Adjust balance error: $e");
    }
    return false;
  }
}