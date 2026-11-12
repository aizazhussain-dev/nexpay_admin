import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class ReferralsAffiliateCmsScreen extends StatefulWidget {
  const ReferralsAffiliateCmsScreen({super.key});

  @override
  State<ReferralsAffiliateCmsScreen> createState() => _ReferralsAffiliateCmsScreenState();
}

class _ReferralsAffiliateCmsScreenState extends State<ReferralsAffiliateCmsScreen> {
  final _inviterCtrl = TextEditingController(text: '250');
  final _inviteeCtrl = TextEditingController(text: '150');
  final _minSpendCtrl = TextEditingController(text: '1000');
  final _titleCtrl = TextEditingController(text: 'Invite Friends & Earn Rs. 250 Cash');
  final _subCtrl = TextEditingController(text: 'Share your NexPay invite code and earn instant wallet rewards.');
  bool _autoCredit = true;
  bool _active = true;
  bool _init = false;
  bool _saving = false;

  void _sync(AdminProvider admin) {
    final r = (admin.cmsConfig['referralProgram'] is Map) ? Map<String, dynamic>.from(admin.cmsConfig['referralProgram']) : <String, dynamic>{};
    _inviterCtrl.text = (r['inviterReward'] ?? 250).toString();
    _inviteeCtrl.text = (r['inviteeBonus'] ?? 150).toString();
    _minSpendCtrl.text = (r['minQualifyingSpend'] ?? 1000).toString();
    if ((r['campaignTitle'] ?? '').toString().isNotEmpty) _titleCtrl.text = r['campaignTitle'].toString();
    if ((r['campaignSubtitle'] ?? '').toString().isNotEmpty) _subCtrl.text = r['campaignSubtitle'].toString();
    _autoCredit = r['autoCreditOnSpend'] != false;
    _active = (r['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';
    _init = true;
  }

  @override
  void dispose() {
    _inviterCtrl.dispose();
    _inviteeCtrl.dispose();
    _minSpendCtrl.dispose();
    _titleCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!_init && admin.cmsConfig.isNotEmpty) _sync(admin);

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Referral & Affiliate Growth Reward Engine',
        subtitle: 'Configure inviter/invitee cash bonuses, qualifying deposit thresholds, and automated payout rules',
        badgeText: _active ? 'CAMPAIGN ACTIVE' : 'PAUSED',
        badgeColor: _active ? AppConstants.accentGreen : AppConstants.textMuted,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.save_rounded, size: 17),
            label: Text(_saving ? 'Saving...' : 'Save Campaign Rules'),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _inviterCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Inviter Cash Reward (PKR)', prefixText: 'Rs. '))),
                const SizedBox(width: 14),
                Expanded(child: TextField(controller: _inviteeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New User Welcome Bonus (PKR)', prefixText: 'Rs. '))),
                const SizedBox(width: 14),
                Expanded(child: TextField(controller: _minSpendCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qualifying Min Deposit/Spend', prefixText: 'Rs. '))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Invite Banner Headline')),
            const SizedBox(height: 12),
            TextField(controller: _subCtrl, decoration: const InputDecoration(labelText: 'Invite Banner Subtitle')),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-Credit Rewards Upon Qualifying Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
              value: _autoCredit,
              activeThumbColor: AppConstants.accentGreen,
              onChanged: (v) => setState(() => _autoCredit = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Referral Program Active Live', style: TextStyle(fontWeight: FontWeight.w600)),
              value: _active,
              activeThumbColor: AppConstants.accentGreen,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
    setState(() => _saving = true);
    final ok = await admin.saveCmsConfig({
      'referralProgram': {
        'inviterReward': double.tryParse(_inviterCtrl.text.trim()) ?? 250,
        'inviteeBonus': double.tryParse(_inviteeCtrl.text.trim()) ?? 150,
        'minQualifyingSpend': double.tryParse(_minSpendCtrl.text.trim()) ?? 1000,
        'campaignTitle': _titleCtrl.text.trim(),
        'campaignSubtitle': _subCtrl.text.trim(),
        'autoCreditOnSpend': _autoCredit,
        'status': _active ? 'ACTIVE' : 'DISABLED',
        'updatedAt': DateTime.now().toIso8601String(),
      },
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Referral campaign rules updated live!' : 'Save failed.'), backgroundColor: ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}