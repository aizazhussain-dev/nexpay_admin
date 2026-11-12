import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class SystemLimitsCmsScreen extends StatefulWidget {
  const SystemLimitsCmsScreen({super.key});

  @override
  State<SystemLimitsCmsScreen> createState() => _SystemLimitsCmsScreenState();
}

class _SystemLimitsCmsScreenState extends State<SystemLimitsCmsScreen> {
  final _t1Daily = TextEditingController(text: '50000');
  final _t1Monthly = TextEditingController(text: '200000');
  final _t1Yearly = TextEditingController(text: '1200000');
  final _t2Daily = TextEditingController(text: '500000');
  final _t2Monthly = TextEditingController(text: '2500000');
  final _t2Yearly = TextEditingController(text: '15000000');
  final _courierFee = TextEditingController(text: '750');
  final _bankFee = TextEditingController(text: '0');
  final NumberFormat _compact = NumberFormat.compact(locale: 'en_US');
  bool _init = false;
  bool _saving = false;

  void _sync(AdminProvider admin) {
    final cfg = admin.cmsConfig;
    final lim = (cfg['limits'] is Map)
        ? Map<String, dynamic>.from(cfg['limits'])
        : <String, dynamic>{};
    _t1Daily.text = (lim['tier1_daily'] ?? 50000).toString();
    _t1Monthly.text = (lim['tier1_monthly'] ?? 200000).toString();
    _t1Yearly.text = (lim['tier1_yearly'] ?? 1200000).toString();
    _t2Daily.text = (lim['tier2_daily'] ?? 500000).toString();
    _t2Monthly.text = (lim['tier2_monthly'] ?? 2500000).toString();
    _t2Yearly.text = (lim['tier2_yearly'] ?? 15000000).toString();
    _courierFee.text = (cfg['courierFee'] ?? 750).toString();
    _bankFee.text = (cfg['bankTransferFee'] ?? 0).toString();
    _init = true;
  }

  @override
  void dispose() {
    _t1Daily.dispose();
    _t1Monthly.dispose();
    _t1Yearly.dispose();
    _t2Daily.dispose();
    _t2Monthly.dispose();
    _t2Yearly.dispose();
    _courierFee.dispose();
    _bankFee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!_init && admin.cmsConfig.isNotEmpty) _sync(admin);

    final t1D = double.tryParse(_t1Daily.text.trim()) ?? 50000;
    final t2D = double.tryParse(_t2Daily.text.trim()) ?? 500000;
    final cFee = double.tryParse(_courierFee.text.trim()) ?? 750;
    final bFee = double.tryParse(_bankFee.text.trim()) ?? 0;

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'SBP Tier-1 / Tier-2 Transaction Limits & Fee Schedule',
        subtitle:
        'Enforce daily, monthly, and annual transaction caps along with IBFT and bullion courier service fees',
        badgeText: 'SBP REGULATORY QUOTAS',
        badgeColor: AppConstants.accentBlue,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.save_rounded, size: 17),
            label: Text(_saving ? 'Enforcing...' : 'Enforce Limits Live'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Tier-1 Daily Cap',
            value: 'Rs. ${_compact.format(t1D)}',
            sublabel: 'Basic / unverified KYC limit',
            icon: Icons.shield_outlined,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Tier-2 Daily Cap',
            value: 'Rs. ${_compact.format(t2D)}',
            sublabel: 'Biometric verified full limit',
            icon: Icons.verified_user_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Bullion Courier Fee',
            value: 'Rs. ${cFee.toStringAsFixed(0)}',
            sublabel: 'Insured 24K gold delivery charge',
            icon: Icons.local_shipping_outlined,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Outward IBFT Fee',
            value: bFee == 0 ? 'FREE (Rs. 0)' : 'Rs. ${bFee.toStringAsFixed(0)}',
            sublabel: 'Interbank funds transfer fee',
            icon: Icons.account_balance_rounded,
            color: AppConstants.accentGreen,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.borderColor),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TIER-1 BASIC ACCOUNTS (UNVERIFIED KYC)',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.accentGold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _t1Daily,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Daily Limit (PKR)',
                            prefixText: 'Rs. '))),
                const SizedBox(width: 14),
                Expanded(
                    child: TextField(
                        controller: _t1Monthly,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Monthly Limit (PKR)',
                            prefixText: 'Rs. '))),
                const SizedBox(width: 14),
                Expanded(
                    child: TextField(
                        controller: _t1Yearly,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Yearly Limit (PKR)',
                            prefixText: 'Rs. '))),
              ],
            ),
            const SizedBox(height: 24),
            Text('TIER-2 BIOMETRIC VERIFIED ACCOUNTS (FULL KYC)',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.accentGreen)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _t2Daily,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Daily Limit (PKR)',
                            prefixText: 'Rs. '))),
                const SizedBox(width: 14),
                Expanded(
                    child: TextField(
                        controller: _t2Monthly,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Monthly Limit (PKR)',
                            prefixText: 'Rs. '))),
                const SizedBox(width: 14),
                Expanded(
                    child: TextField(
                        controller: _t2Yearly,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Yearly Limit (PKR)',
                            prefixText: 'Rs. '))),
              ],
            ),
            const SizedBox(height: 24),
            Text('PLATFORM SERVICE & LOGISTICS FEES',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.accentBlue)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _courierFee,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                            labelText: '24K Gold Insured Courier Fee (PKR)',
                            prefixText: 'Rs. '))),
                const SizedBox(width: 14),
                Expanded(
                    child: TextField(
                        controller: _bankFee,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: AppConstants.textPrimary),
                        decoration: const InputDecoration(
                            labelText:
                            'Outward IBFT Bank Transfer Fee (PKR)',
                            prefixText: 'Rs. '))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
    final confirmed = await showNexPayConfirmDialog(
      context: context,
      title: 'Enforce Transaction Limits & Fees',
      message:
      'Apply updated Tier-1/Tier-2 transaction caps and platform fee schedules immediately across all live wallets?',
      confirmLabel: 'Enforce Limits',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final ok = await admin.saveCmsConfig({
      'limits': {
        'tier1_daily': double.tryParse(_t1Daily.text.trim()) ?? 50000,
        'tier1_monthly': double.tryParse(_t1Monthly.text.trim()) ?? 200000,
        'tier1_yearly': double.tryParse(_t1Yearly.text.trim()) ?? 1200000,
        'tier2_daily': double.tryParse(_t2Daily.text.trim()) ?? 500000,
        'tier2_monthly': double.tryParse(_t2Monthly.text.trim()) ?? 2500000,
        'tier2_yearly': double.tryParse(_t2Yearly.text.trim()) ?? 15000000,
      },
      'courierFee': double.tryParse(_courierFee.text.trim()) ?? 750,
      'bankTransferFee': double.tryParse(_bankFee.text.trim()) ?? 0,
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok
                ? 'System limits & fee schedule enforced live!'
                : 'Save failed.'),
            backgroundColor:
            ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}