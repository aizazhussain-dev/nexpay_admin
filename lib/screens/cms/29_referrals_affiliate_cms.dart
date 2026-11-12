import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/nexpay_ui_kit.dart';

class ReferralsAffiliateCmsScreen extends StatefulWidget {
  const ReferralsAffiliateCmsScreen({super.key});

  @override
  State<ReferralsAffiliateCmsScreen> createState() =>
      _ReferralsAffiliateCmsScreenState();
}

class _ReferralsAffiliateCmsScreenState
    extends State<ReferralsAffiliateCmsScreen> {
  final _inviterCtrl = TextEditingController(text: '250');
  final _inviteeCtrl = TextEditingController(text: '150');
  final _minSpendCtrl = TextEditingController(text: '1000');
  final _titleCtrl =
  TextEditingController(text: 'Invite Friends & Earn Rs. 250 Cash');
  final _subCtrl = TextEditingController(
      text: 'Share your NexPay invite code and earn instant wallet rewards.');
  bool _autoCredit = true;
  bool _active = true;
  bool _init = false;
  bool _saving = false;

  void _sync(AdminProvider admin) {
    final r = (admin.cmsConfig['referralProgram'] is Map)
        ? Map<String, dynamic>.from(admin.cmsConfig['referralProgram'])
        : <String, dynamic>{};
    _inviterCtrl.text = (r['inviterReward'] ?? 250).toString();
    _inviteeCtrl.text = (r['inviteeBonus'] ?? 150).toString();
    _minSpendCtrl.text = (r['minQualifyingSpend'] ?? 1000).toString();
    if ((r['campaignTitle'] ?? '').toString().isNotEmpty) {
      _titleCtrl.text = r['campaignTitle'].toString();
    }
    if ((r['campaignSubtitle'] ?? '').toString().isNotEmpty) {
      _subCtrl.text = r['campaignSubtitle'].toString();
    }
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
    final isDesktop = MediaQuery.of(context).size.width >= 1050;

    final inviterVal = double.tryParse(_inviterCtrl.text.trim()) ?? 250;
    final inviteeVal = double.tryParse(_inviteeCtrl.text.trim()) ?? 150;
    final minSpendVal = double.tryParse(_minSpendCtrl.text.trim()) ?? 1000;

    final editorCard = Container(
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
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _inviterCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Inviter Cash Reward (PKR)',
                          prefixText: 'Rs. '))),
              const SizedBox(width: 14),
              Expanded(
                  child: TextField(
                      controller: _inviteeCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'New User Welcome Bonus (PKR)',
                          prefixText: 'Rs. '))),
              const SizedBox(width: 14),
              Expanded(
                  child: TextField(
                      controller: _minSpendCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppConstants.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Qualifying Min Deposit/Spend',
                          prefixText: 'Rs. '))),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: AppConstants.textPrimary),
              decoration:
              const InputDecoration(labelText: 'Invite Banner Headline')),
          const SizedBox(height: 12),
          TextField(
              controller: _subCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: AppConstants.textPrimary),
              decoration:
              const InputDecoration(labelText: 'Invite Banner Subtitle')),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
                'Auto-Credit Rewards Upon Qualifying Transaction',
                style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600)),
            value: _autoCredit,
            activeThumbColor: AppConstants.accentGreen,
            onChanged: (v) => setState(() => _autoCredit = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Referral Program Active Live',
                style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600)),
            value: _active,
            activeThumbColor: AppConstants.accentGreen,
            onChanged: (v) => setState(() => _active = v),
          ),
        ],
      ),
    );

    final previewCard = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IN-APP INVITE CARD PREVIEW',
                style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6),
              ),
              NexPayStatusBadge(status: _active ? 'ACTIVE' : 'PAUSED'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'EARN RS. ${inviterVal.toStringAsFixed(0)} + RS. ${inviteeVal.toStringAsFixed(0)} BONUS',
                    style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _titleCtrl.text.trim().isEmpty
                      ? 'Invite & Earn Cash'
                      : _titleCtrl.text.trim(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _subCtrl.text.trim(),
                  style: const TextStyle(
                      color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Min Qualifying Activity: Rs. ${minSpendVal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return NexPayDeskScaffold(
      header: NexPayDeskHeader(
        title: 'Referral & Affiliate Growth Reward Engine',
        subtitle:
        'Configure inviter/invitee cash bonuses, qualifying deposit thresholds, and automated payout rules',
        badgeText: _active ? 'CAMPAIGN ACTIVE' : 'PAUSED',
        badgeColor:
        _active ? AppConstants.accentGreen : AppConstants.textMuted,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _save(admin),
            icon: const Icon(Icons.save_rounded, size: 17),
            label: Text(_saving ? 'Saving...' : 'Save Campaign Rules'),
          ),
        ],
      ),
      statStrip: NexPayStatStrip(
        items: [
          NexPayStatItem(
            label: 'Inviter Cash Reward',
            value: 'Rs. ${inviterVal.toStringAsFixed(0)}',
            sublabel: 'Credited to referrer wallet',
            icon: Icons.person_add_alt_1_rounded,
            color: AppConstants.accentGreen,
          ),
          NexPayStatItem(
            label: 'Invitee Welcome Bonus',
            value: 'Rs. ${inviteeVal.toStringAsFixed(0)}',
            sublabel: 'New user signup reward',
            icon: Icons.card_giftcard_rounded,
            color: AppConstants.accentGold,
          ),
          NexPayStatItem(
            label: 'Qualifying Threshold',
            value: 'Rs. ${minSpendVal.toStringAsFixed(0)}',
            sublabel: 'Minimum first deposit/spend',
            icon: Icons.verified_outlined,
            color: AppConstants.accentBlue,
          ),
          NexPayStatItem(
            label: 'Disbursement Engine',
            value: _autoCredit ? 'Auto-Credit' : 'Manual Review',
            sublabel: 'Instant ledger reward trigger',
            icon: Icons.bolt_rounded,
            color: AppConstants.accentGreen,
          ),
        ],
      ),
      body: isDesktop
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: editorCard),
          const SizedBox(width: 18),
          Expanded(flex: 2, child: previewCard),
        ],
      )
          : Column(
        children: [
          editorCard,
          const SizedBox(height: 16),
          previewCard,
        ],
      ),
    );
  }

  Future<void> _save(AdminProvider admin) async {
    final confirmed = await showNexPayConfirmDialog(
      context: context,
      title: 'Publish Referral Rules',
      message:
      'Deploy updated referral bonuses and qualifying threshold rules live across all customer accounts?',
      confirmLabel: 'Publish Rules',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final ok = await admin.saveCmsConfig({
      'referralProgram': {
        'inviterReward': double.tryParse(_inviterCtrl.text.trim()) ?? 250,
        'inviteeBonus': double.tryParse(_inviteeCtrl.text.trim()) ?? 150,
        'minQualifyingSpend':
        double.tryParse(_minSpendCtrl.text.trim()) ?? 1000,
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
        SnackBar(
            content: Text(ok
                ? 'Referral campaign rules updated live!'
                : 'Save failed.'),
            backgroundColor:
            ok ? AppConstants.accentGreen : AppConstants.dangerRed),
      );
    }
  }
}