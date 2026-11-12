import 'package:flutter/material.dart';
import '../core/api_client.dart';

typedef JsonMap = Map<String, dynamic>;

class AdminProvider with ChangeNotifier {
final ApiClient _api = ApiClient();

bool isLoading = false;
JsonMap users = {};
List<dynamic> deposits = [];
List<dynamic> payouts = [];
List<dynamic> loans = [];
List<dynamic> tickets = [];
List<dynamic> voucherOrders = [];
List<dynamic> kametiPools = [];
List<dynamic> kametiMembers = [];
JsonMap cmsConfig = {};

List<dynamic> dossiers = [];
List<dynamic> takafulClaims = [];
List<dynamic> closureRequests = [];
List<dynamic> stocks = [];
List<dynamic> stockTrades = [];
double usdPkrRate = 280.0;
bool isMarketOpen = false;

Future<void> fetchAllData() async {
isLoading = true;
notifyListeners();

try {
final response = await _api.dio.get(
'',
queryParameters: {
'action': 'get_all',
'_t': DateTime.now().millisecondsSinceEpoch,
},
);

if (response.statusCode == 200 && response.data['status'] == 'success') {
final data = response.data['data'] ?? {};
users = JsonMap.from(data['users'] ?? {});
deposits = List<dynamic>.from(data['deposits'] ?? []);
payouts = List<dynamic>.from(data['payouts'] ?? []);
loans = List<dynamic>.from(data['loans'] ?? []);
tickets = List<dynamic>.from(data['tickets'] ?? []);
voucherOrders = List<dynamic>.from(data['voucher_orders'] ?? []);
kametiPools = List<dynamic>.from(data['kameti_pools'] ?? []);
kametiMembers = List<dynamic>.from(data['kameti_members'] ?? []);
cmsConfig = JsonMap.from(data['cmsConfig'] ?? {});
}

await fetchExtendedOperations(silent: true);
} catch (e) {
debugPrint("Master Fetch Error: $e");
} finally {
isLoading = false;
notifyListeners();
}
}

Future<void> fetchExtendedOperations({bool silent = false}) async {
final ts = DateTime.now().millisecondsSinceEpoch;
try {
final results = await Future.wait([
_api.dio.get('', queryParameters: {'action': 'get_customer_dossiers', '_t': ts}),
_api.dio.get('', queryParameters: {'action': 'get_takaful_claims', '_t': ts}),
_api.dio.get('', queryParameters: {'action': 'get_closure_requests', '_t': ts}),
_api.dio.get('', queryParameters: {'action': 'get_stocks', '_t': ts}),
_api.dio.get('', queryParameters: {'action': 'get_all_stock_trades', '_t': ts}),
]);

if (results[0].data['status'] == 'success') {
dossiers = List<dynamic>.from(results[0].data['dossiers'] ?? []);
}
if (results[1].data['status'] == 'success') {
takafulClaims = List<dynamic>.from(results[1].data['claims'] ?? []);
}
if (results[2].data['status'] == 'success') {
closureRequests = List<dynamic>.from(results[2].data['requests'] ?? []);
}
if (results[3].data['status'] == 'success') {
stocks = List<dynamic>.from(results[3].data['stocks'] ?? []);
usdPkrRate = double.tryParse(results[3].data['usdPkrRate']?.toString() ?? '280') ?? 280.0;
isMarketOpen = results[3].data['isMarketOpen'] == true;
}
if (results[4].data['status'] == 'success') {
stockTrades = List<dynamic>.from(results[4].data['trades'] ?? []);
}

if (!silent) notifyListeners();
} catch (e) {
debugPrint("Extended Sync Error: $e");
}
}

Future<bool> completePayout(int id, String tid) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'complete_manual_payout'},
data: {'payoutId': id, 'tid': tid, 'adminName': 'aizaz_admin'},
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
'adminName': 'aizaz_admin',
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

Future<String> getDepositProof(int id) async {
try {
final res = await _api.dio.get(
'',
queryParameters: {'action': 'get_deposit_proof', 'id': id},
);
if (res.data['status'] == 'success') {
return (res.data['screenshot'] ?? '').toString();
}
} catch (e) {
debugPrint("Deposit proof error: $e");
}
return '';
}

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

Future<JsonMap> getKycProof(String mobile) async {
try {
final res = await _api.dio.get(
'',
queryParameters: {'action': 'get_kyc_proof', 'mobile': mobile},
);
if (res.data['status'] == 'success' && res.data['kycDocs'] is Map) {
return JsonMap.from(res.data['kycDocs']);
}
} catch (e) {
debugPrint("KYC proof error: $e");
}
return {};
}

Future<bool> updateUserFullProfile({
required String oldMobile,
required String newMobile,
required String name,
required String email,
required String cnic,
required String address,
required bool isKycVerified,
required String kycStatus,
JsonMap? kycDetails,
}) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'admin_update_user_full_profile'},
data: {
'oldMobile': oldMobile,
'newMobile': newMobile,
'name': name,
'email': email,
'cnic': cnic,
'address': address,
'isKycVerified': isKycVerified ? 1 : 0,
'kycStatus': kycStatus,
if (kycDetails != null) 'kycDetails': kycDetails,
},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Update user error: $e");
}
return false;
}

Future<bool> toggleUserFreeze(String mobile, bool freeze) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'save_all'},
data: {
'users': {
mobile: {'isFrozen': freeze}
}
},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Freeze toggle error: $e");
}
return false;
}

Future<bool> resetUserKyc(String mobile) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'admin_reset_kyc'},
data: {'mobile': mobile},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Reset KYC error: $e");
}
return false;
}

Future<bool> resetUserDevice(String mobile) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'admin_reset_device'},
data: {'mobile': mobile},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Reset device error: $e");
}
return false;
}

Future<bool> reverseTransaction({
required String senderMobile,
required String tid,
required double amount,
String recipientMobile = '',
}) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'reverse_transaction'},
data: {
'senderMobile': senderMobile,
'tid': tid,
'amount': amount,
'recipientMobile': recipientMobile,
},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Reverse tx error: $e");
}
return false;
}

Future<bool> reviewLoan(int loanId, bool approved) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'review_loan'},
data: {'loanId': loanId, 'approved': approved},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Review loan error: $e");
}
return false;
}

Future<bool> reviewVoucherOrder(String orderId, String status, String mobile, double amount) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'review_voucher_order'},
data: {
'orderId': orderId,
'status': status,
'userMobile': mobile,
'amount': amount,
},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Review voucher error: $e");
}
return false;
}

Future<bool> replyTicket(int ticketId, String reply, String status) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'reply_ticket'},
data: {'ticketId': ticketId, 'reply': reply, 'status': status},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Reply ticket error: $e");
}
return false;
}

Future<bool> createKametiPool(String title, double monthlyAmount, int totalMembers, int totalMonths) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'create_kameti_pool'},
data: {
'title': title,
'monthly_amount': monthlyAmount,
'total_members': totalMembers,
'total_months': totalMonths,
},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Create kameti error: $e");
}
return false;
}

Future<bool> deleteKametiPool(int poolId) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'delete_kameti_pool'},
data: {'poolId': poolId},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Delete kameti error: $e");
}
return false;
}

Future<bool> releaseKametiPot(int poolId, {String targetMobile = ''}) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'release_kameti_pot'},
data: {'poolId': poolId, 'targetMobile': targetMobile},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Release kameti error: $e");
}
return false;
}

Future<bool> dispatchGoldDelivery(String mobile, String tid, String tracking) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'dispatch_gold_delivery'},
data: {'mobile': mobile, 'tid': tid, 'tracking': tracking},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Dispatch gold error: $e");
}
return false;
}

Future<bool> rejectGoldDelivery(String mobile, String tid, double grams, double fee) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'reject_gold_delivery'},
data: {'mobile': mobile, 'tid': tid, 'grams': grams, 'fee': fee},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Reject gold error: $e");
}
return false;
}

Future<bool> reviewTakafulClaim(String claimId, String decision) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'review_takaful_claim'},
data: {'claimId': claimId, 'decision': decision, 'adminName': 'aizaz_admin'},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Takaful review error: $e");
}
return false;
}

Future<bool> reviewClosureRequest(int requestId, String mobile, String decision) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'review_closure_request'},
data: {'requestId': requestId, 'mobile': mobile, 'decision': decision},
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Closure review error: $e");
}
return false;
}

Future<bool> saveStock(JsonMap stockData) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'admin_save_stock'},
data: stockData,
);
if (res.data['status'] == 'success') {
await fetchExtendedOperations();
return true;
}
} catch (e) {
debugPrint("Save stock error: $e");
}
return false;
}

Future<bool> deleteStock(int id) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'admin_delete_stock'},
data: {'id': id},
);
if (res.data['status'] == 'success') {
await fetchExtendedOperations();
return true;
}
} catch (e) {
debugPrint("Delete stock error: $e");
}
return false;
}

Future<bool> saveCmsConfig(JsonMap partialConfig) async {
try {
final res = await _api.dio.post(
'',
queryParameters: {'action': 'save_config'},
data: partialConfig,
);
if (res.data['status'] == 'success') {
await fetchAllData();
return true;
}
} catch (e) {
debugPrint("Save CMS error: $e");
}
return false;
}
}