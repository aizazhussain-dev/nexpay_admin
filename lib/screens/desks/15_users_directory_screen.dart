import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/institutional_scroll.dart';
import '../../widgets/nexpay_ui_kit.dart';

class UsersDirectoryScreen extends StatefulWidget {
  const UsersDirectoryScreen({super.key});

  @override
  State<UsersDirectoryScreen> createState() => _UsersDirectoryScreenState();
}

class _UsersDirectoryScreenState extends State<UsersDirectoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  String _filter = 'ALL';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final List allUsers = [];

    double totalPkr = 0;
    double totalUsdt = 0;
    double totalGold = 0;
    int verifiedCount = 0;
    int frozenCount = 0;

    admin.users.forEach((mobile, raw) {
    if (raw is! Map) return;
    final u = Map<String, dynamic>.from(raw);
    u['mobile'] = (u['mobile'] ?? mobile).toString();
    allUsers.add(u);

    totalPkr += double.tryParse(u['balance']?.toString() ?? '0') ?? 0;
    totalUsdt += double.tryParse(u['cryptoBalance']?.toString() ?? u['usdt']?.toString() ?? '0') ?? 0;
    totalGold += double.tryParse(u['goldGrams']?.toString() ?? u['gold']?.toString() ?? '0') ?? 0;

    final isKyc = u['isKycVerified'] == true ||
    u['isKycVerified'] == 1 ||
    (u['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    if (isKyc) verifiedCount++;
    if (u['isFrozen'] == true || u['isFrozen'] == 1) frozenCount++;
    });

    final filtered = allUsers.where((u) {
    final isKyc = u['isKycVerified'] == true ||
    u['isKycVerified'] == 1 ||
    (u['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    final isFrozen = u['isFrozen'] == true || u['isFrozen'] == 1;
    final kycStatus = (u['kycStatus'] ?? (isKyc ? 'VERIFIED' : 'UNVERIFIED')).toString().toUpperCase();

    if (_filter == 'VERIFIED' && !isKyc) return false;
    if (_filter == 'PENDING KYC' && kycStatus != 'PENDING') return false;
    if (_filter == 'FROZEN' && !isFrozen) return false;

    if (_query.isEmpty) return true;
    final hay = '${u['name']} ${u['mobile']} ${u['email']} ${u['cnic']} ${u['address']}'.toLowerCase();
    return hay.contains(_query);
    }).toList();

    return NexPayDeskScaffold(
    header: NexPayDeskHeader(
    title: 'Master Customer Accounts Directory',
    subtitle: 'Live customer custody balances, CNIC profile editing, wallet adjustments, freeze & device reset controls',
    badgeText: '${allUsers.length} LIVE ACCOUNTS',
    badgeColor: AppConstants.accentGreen,
    actions: [
    ElevatedButton.icon(
    onPressed: () => admin.fetchAllData(),
    icon: const Icon(Icons.refresh_rounded, size: 17),
    label: const Text('Sync Customer Base'),
    ),
    ],
    ),
    statStrip: NexPayStatStrip(
    items: [
    NexPayStatItem(
    label: 'Total Registered Users',
    value: '${allUsers.length} Accounts',
    sublabel: '$verifiedCount KYC Verified • $frozenCount Frozen',
    icon: Icons.people_alt_rounded,
    color: AppConstants.accentBlue,
    ),
    NexPayStatItem(
    label: 'Total PKR Wallet Custody',
    value: 'Rs. ${_money.format(totalPkr)}',
    sublabel: 'Aggregate customer liquid float',
    icon: Icons.account_balance_wallet_rounded,
    color: AppConstants.accentGreen,
    ),
    NexPayStatItem(
    label: 'Total USDT Custody',
    value: '\$ ${_money.format(totalUsdt)}',
    sublabel: 'Digital dollar wallet reserves',
    icon: Icons.currency_bitcoin_rounded,
    color: AppConstants.accentGold,
    ),
    NexPayStatItem(
    label: '24K Bullion Holdings',
    value: '${totalGold.toStringAsFixed(3)} g',
    sublabel: 'Allocated physical gold vault grams',
    icon: Icons.diamond_rounded,
    color: AppConstants.accentGold,
    ),
    ],
    ),
    filterBar: NexPayFilterBar(
    searchController: _searchCtrl,
    searchHint: 'Search by customer name, mobile (03xx), CNIC, or email...',
    onSearchChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
    filters: const ['ALL', 'VERIFIED', 'PENDING KYC', 'FROZEN'],
    selectedFilter: _filter,
    onFilterChanged: (f) => setState(() => _filter = f),
    resultSummary: 'Showing ${filtered.length} of ${allUsers.length} customers',
    ),
    body: NexPayFullWidthTable(
    minTableWidth: 1240,
    emptyState: const InstitutionalEmptyState(
    icon: Icons.people_outline_rounded,
    title: 'No Customer Accounts Found',
    subtitle: 'No registered accounts match your current search or filter.',
    ),
    columns: const [
    DataColumn(label: Text('CUSTOMER & MOBILE')),
    DataColumn(label: Text('CNIC / EMAIL')),
    DataColumn(label: Text('PKR BALANCE'), numeric: true),
    DataColumn(label: Text('USDT'), numeric: true),
    DataColumn(label: Text('GOLD (g)'), numeric: true),
    DataColumn(label: Text('KYC STATUS')),
    DataColumn(label: Text('ACCOUNT STATE')),
    DataColumn(label: Text('ADMIN CONTROLS')),
    ],
    rows: filtered.map((u) {
    final mobile = u['mobile'].toString();
    final name = (u['name'] ?? 'Unnamed User').toString();
    final email = (u['email'] ?? '-').toString();
    final cnic = (u['cnic'] ?? 'Not Submitted').toString();
    final pkr = double.tryParse(u['balance']?.toString() ?? '0') ?? 0;
    final usdt = double.tryParse(u['cryptoBalance']?.toString() ?? u['usdt']?.toString() ?? '0') ?? 0;
    final gold = double.tryParse(u['goldGrams']?.toString() ?? u['gold']?.toString() ?? '0') ?? 0;
    final isKyc = u['isKycVerified'] == true ||
    u['isKycVerified'] == 1 ||
    (u['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    final kycStatus = (u['kycStatus'] ?? (isKyc ? 'VERIFIED' : 'UNVERIFIED')).toString().toUpperCase();
    final isFrozen = u['isFrozen'] == true || u['isFrozen'] == 1;

    return DataRow(
    cells: [
    DataCell(
    Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
    Text(mobile, style: const TextStyle(color: AppConstants.accentBlue, fontSize: 12, fontWeight: FontWeight.w600)),
    ],
    ),
    ),
    DataCell(
    Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(cnic, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12)),
    Text(email, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5)),
    ],
    ),
    ),
    DataCell(
    Text(
    'Rs. ${_money.format(pkr)}',
    style: const TextStyle(
    fontWeight: FontWeight.w700,
    color: AppConstants.accentGreen,
    fontFeatures: [FontFeature.tabularFigures()],
    ),
    ),
    ),
    DataCell(
    Text(
    '\$ ${_money.format(usdt)}',
    style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGold),
    ),
    ),
    DataCell(
    Text(
    '${gold.toStringAsFixed(3)} g',
    style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.accentGold),
    ),
    ),
    DataCell(NexPayStatusBadge(status: kycStatus)),
    DataCell(NexPayStatusBadge(status: isFrozen ? 'FROZEN' : 'ACTIVE')),
    DataCell(
    Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    ElevatedButton.icon(
    onPressed: () => _openCustomerControlDrawer(context, admin, u),
    icon: const Icon(Icons.manage_accounts_rounded, size: 15),
    label: const Text('Manage'),
    ),
    const SizedBox(width: 6),
    IconButton(
    tooltip: isFrozen ? 'Unfreeze Account' : 'Freeze Account',
    icon: Icon(
    isFrozen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
    color: isFrozen ? AppConstants.accentGreen : AppConstants.dangerRed,
    size: 19,
    ),
    onPressed: () async {
    final ok = await admin.toggleUserFreeze(mobile, !isFrozen);
    if (context.mounted) {
    _toast(
    context,
    ok ? (isFrozen ? 'Account $mobile unfrozen.' : 'Account $mobile frozen.') : 'Action failed.',
    ok,
    );
    }
    },
    ),
    ],
    ),
    ),
    ],
    );
    }).toList(),
    ),
    );
  }

  void _openCustomerControlDrawer(BuildContext context, AdminProvider admin, Map<String, dynamic> u) {
    final oldMobile = u['mobile'].toString();
    final nameCtrl = TextEditingController(text: (u['name'] ?? '').toString());
    final mobileCtrl = TextEditingController(text: oldMobile);
    final emailCtrl = TextEditingController(text: (u['email'] ?? '').toString());
    final cnicCtrl = TextEditingController(text: (u['cnic'] ?? '').toString());
    final addressCtrl = TextEditingController(text: (u['address'] ?? '').toString());
    final deltaCtrl = TextEditingController();

    bool isKycVerified = u['isKycVerified'] == true ||
        u['isKycVerified'] == 1 ||
        (u['kycStatus'] ?? '').toString().toUpperCase() == 'VERIFIED';
    String kycStatus = (u['kycStatus'] ?? (isKycVerified ? 'VERIFIED' : 'UNVERIFIED')).toString().toUpperCase();
    if (!['VERIFIED', 'PENDING', 'UNVERIFIED', 'REJECTED'].contains(kycStatus)) {
      kycStatus = isKycVerified ? 'VERIFIED' : 'UNVERIFIED';
    }
    final isFrozen = u['isFrozen'] == true || u['isFrozen'] == 1;
    final pkr = double.tryParse(u['balance']?.toString() ?? '0') ?? 0;

    showNexPayInspectorDrawer(
      context: context,
      width: 580,
      title: (u['name'] ?? 'Customer Control').toString(),
      subtitle: 'Mobile: $oldMobile • Balance: Rs. ${_money.format(pkr)}',
      child: StatefulBuilder(
        builder: (ctx, setDrawerState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Direct Wallet Adjustment Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INSTANT TREASURY WALLET CREDIT / DEBIT (PKR)',
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Current Wallet: Rs. ${_money.format(pkr)}',
                      style: const TextStyle(color: AppConstants.accentGreen, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: deltaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(
                              hintText: 'Amount e.g. 5000 or -2000',
                              prefixText: 'Rs. ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final delta = double.tryParse(deltaCtrl.text.trim());
                            if (delta == null || delta == 0) return;
                            Navigator.pop(context);
                            final ok = await admin.adjustBalance(oldMobile, delta);
                            if (context.mounted) {
                              _toast(
                                context,
                                ok ? 'Wallet adjusted by Rs. ${_money.format(delta)} for $oldMobile.' : 'Adjustment failed.',
                                ok,
                              );
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 2. Full Profile & Identity Editor
              const Text(
                'CUSTOMER PROFILE & IDENTITY RECORD',
                style: TextStyle(color: AppConstants.textPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Legal Name')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile Number'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: cnicCtrl, decoration: const InputDecoration(labelText: 'CNIC Number'))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Residential Address')),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: kycStatus,
                      decoration: const InputDecoration(labelText: 'KYC Status'),
                      items: const ['VERIFIED', 'PENDING', 'UNVERIFIED', 'REJECTED']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDrawerState(() {
                            kycStatus = val;
                            isKycVerified = val == 'VERIFIED';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('KYC Verified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: isKycVerified,
                      activeThumbColor: AppConstants.accentGreen,
                      onChanged: (v) {
                        setDrawerState(() {
                          isKycVerified = v;
                          kycStatus = v ? 'VERIFIED' : 'UNVERIFIED';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 3. Security & Hardware Reset Controls
              const Text(
                'SECURITY & HARDWARE COMPLIANCE ACTIONS',
                style: TextStyle(color: AppConstants.textPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFrozen ? AppConstants.accentGreen : AppConstants.dangerRed,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final ok = await admin.toggleUserFreeze(oldMobile, !isFrozen);
                      if (context.mounted) {
                        _toast(context, ok ? (isFrozen ? 'Account Unfrozen' : 'Account Frozen') : 'Failed', ok);
                      }
                    },
                    icon: Icon(isFrozen ? Icons.lock_open_rounded : Icons.lock_rounded, size: 16),
                    label: Text(isFrozen ? 'Unfreeze Wallet' : 'Freeze Wallet'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final ok = await admin.resetUserKyc(oldMobile);
                      if (context.mounted) {
                        _toast(context, ok ? 'Biometric KYC reset for $oldMobile.' : 'Reset failed.', ok);
                      }
                    },
                    icon: const Icon(Icons.verified_user_outlined, size: 16, color: AppConstants.accentGold),
                    label: const Text('Reset Biometric KYC'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final ok = await admin.resetUserDevice(oldMobile);
                      if (context.mounted) {
                        _toast(context, ok ? 'Trusted device binding cleared for $oldMobile.' : 'Reset failed.', ok);
                      }
                    },
                    icon: const Icon(Icons.phonelink_erase_rounded, size: 16, color: AppConstants.accentBlue),
                    label: const Text('Reset Device Lock'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      footerActions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await admin.updateUserFullProfile(
              oldMobile: oldMobile,
              newMobile: mobileCtrl.text.trim(),
              name: nameCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              cnic: cnicCtrl.text.trim(),
              address: addressCtrl.text.trim(),
              isKycVerified: isKycVerified,
              kycStatus: kycStatus,
            );
            if (context.mounted) {
              _toast(context, ok ? 'Customer profile updated in live database.' : 'Update failed.', ok);
            }
          },
          icon: const Icon(Icons.save_rounded, size: 17),
          label: const Text('Save Profile Changes'),
        ),
      ],
    );
  }

  void _toast(BuildContext context, String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
    );
  }
}