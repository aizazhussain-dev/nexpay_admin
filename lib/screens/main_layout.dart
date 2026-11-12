import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

// --- System CMS Screens 18 to 20 (Desks Folder) ---
import 'desks/18_binance_gateway_cms.dart';
import 'desks/19_broadcast_cms.dart';
import 'desks/20_system_limits_cms.dart';

// --- System CMS Screens 21 to 33 (CMS Folder) ---
import 'cms/21_maintenance_update_cms.dart';
import 'cms/22_home_banners_cms.dart';
import 'cms/23_deposit_gateways_cms.dart';
import 'cms/24_bill_providers_cms.dart';
import 'cms/25_telecom_packages_cms.dart';
import 'cms/26_digital_shop_inventory_cms.dart';
import 'cms/27_savings_tiers_cms.dart';
import 'cms/28_takaful_plans_cms.dart';
import 'cms/29_referrals_affiliate_cms.dart';
import 'cms/30_currency_rates_ticker_cms.dart';
import 'cms/31_admin_roles_cms.dart';
import 'cms/32_security_ip_whitelist_cms.dart';
import 'cms/33_audit_logs_cms.dart';

class MainAdminLayout extends StatefulWidget {
  const MainAdminLayout({super.key});

  @override
  State<MainAdminLayout> createState() => _MainAdminLayoutState();
}

class _MainAdminLayoutState extends State<MainAdminLayout> {
  int _selectedIndex = 0;
  String _globalSearchQuery = "";
  bool _isSidebarCollapsed = false;
  DateTime _lastSyncTime = DateTime.now();
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLiveLedger();
    });
  }

  Future<void> _refreshLiveLedger() async {
    await context.read<AdminProvider>().fetchAllData();
    if (mounted) {
      setState(() => _lastSyncTime = DateTime.now());
    }
  }

  // Master Navigation Directory (All 22 Connected Desks & CMS Screens)
  final List _navigationDirectory = [
  // --- Section 1: Financial & Core Operations ---
      {
  'group': 'BANKING OPERATIONS',
  'items': [
  {'id': 0, 'title': 'Executive Dashboard', 'icon': Icons.space_dashboard_rounded, 'badge': 'LIVE'},
  {'id': 1, 'title': 'Manual Payouts Desk', 'icon': Icons.send_and_archive, 'badge': 'PAYOUTS'},
  {'id': 2, 'title': 'Users & KYC Directory', 'icon': Icons.people_alt_rounded, 'badge': 'USERS'},
  {'id': 3, 'title': 'Deposits Clearing Queue', 'icon': Icons.move_to_inbox, 'badge': 'DEPOSITS'},
  {'id': 4, 'title': 'Digital Kameti ROSCA', 'icon': Icons.groups_rounded, 'badge': 'KAMETI'},
  {'id': 5, 'title': 'US Stocks Trading Desk', 'icon': Icons.trending_up, 'badge': 'MARKETS'},
  ]
  },
  // --- Section 2: Platform Engine CMS ---
      {
  'group': 'CMS CONFIGURATIONS & GATEWAYS',
  'items': [
  {'id': 6, 'title': '18. Binance P2P Gateway', 'icon': Icons.toll_rounded, 'badge': 'CRYPTO'},
  {'id': 7, 'title': '19. Bank Broadcast Notice', 'icon': Icons.campaign_rounded, 'badge': 'PUSH'},
  {'id': 8, 'title': '20. Limits & SBP Compliance', 'icon': Icons.tune_rounded, 'badge': 'SBP'},
  {'id': 9, 'title': '21. Maintenance & Versioning', 'icon': Icons.system_security_update_rounded, 'badge': 'SYSTEM'},
  {'id': 10, 'title': '22. Home Promo Banners', 'icon': Icons.view_carousel_rounded, 'badge': 'UI'},
  {'id': 11, 'title': '23. Deposit Gateways (Banks)', 'icon': Icons.account_balance_wallet_rounded, 'badge': 'BANK'},
  {'id': 12, 'title': '24. Utility Biller Companies', 'icon': Icons.bolt_rounded, 'badge': 'BILLER'},
  {'id': 13, 'title': '25. Telecom Packages Catalog', 'icon': Icons.signal_cellular_alt_rounded, 'badge': 'TELCO'},
  {'id': 14, 'title': '26. Digital Shop Keys Vault', 'icon': Icons.vpn_key_rounded, 'badge': 'SHOP'},
  {'id': 15, 'title': '27. Savings Plans & Halal ROI', 'icon': Icons.savings_rounded, 'badge': 'PLANS'},
  {'id': 16, 'title': '28. Takaful Policies Desk', 'icon': Icons.health_and_safety_rounded, 'badge': 'INSURE'},
  {'id': 17, 'title': '29. Referral Rewards Program', 'icon': Icons.share_rounded, 'badge': 'AFFILIATE'},
  {'id': 18, 'title': '30. Currency & 24K Gold Ticker', 'icon': Icons.currency_exchange_rounded, 'badge': 'FOREX'},
  {'id': 19, 'title': '31. Admin Staff & RBAC Matrix', 'icon': Icons.admin_panel_settings_rounded, 'badge': 'ROLES'},
  {'id': 20, 'title': '32. Security, 2FA & IP Shield', 'icon': Icons.security_rounded, 'badge': 'FIREWALL'},
  {'id': 21, 'title': '33. Forensic Audit Logs Trail', 'icon': Icons.history_edu_rounded, 'badge': 'AUDIT'},
  ]
  },
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final admin = context.watch<AdminProvider>();

    // Live Database Aggregations
    final pendingPayouts = admin.payouts.where((p) => p['status'] == 'PENDING').toList();
    final pendingDeposits = admin.deposits.where((d) => d['status'] == 'PENDING').toList();
    final totalPendingPayoutAmount = pendingPayouts.fold<double>(
      0.0,
          (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0),
    );
    final totalPendingDepositAmount = pendingDeposits.fold<double>(
      0.0,
          (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0),
    );

    // Dynamic Pages Stack
    final List<Widget> pages = [
      _buildLiveOperationsDashboard(admin, pendingPayouts.length, pendingDeposits.length, totalPendingPayoutAmount, totalPendingDepositAmount),
      _buildPlaceholderDesk("Manual Payouts Clearance Desk", Icons.send_and_archive, "${pendingPayouts.length} Withdrawal Requests Pending", AppConstants.dangerRed, admin),
      _buildPlaceholderDesk("Users & Biometric KYC Directory", Icons.people_alt_rounded, "${admin.users.length} Registered Accounts In Ledger", AppConstants.accentBlue, admin),
      _buildPlaceholderDesk("Deposits Settlement Desk", Icons.move_to_inbox, "${pendingDeposits.length} Payment Receipts Awaiting Clearance", AppConstants.accentGreen, admin),
      _buildPlaceholderDesk("Digital Kameti ROSCA Ledger", Icons.groups_rounded, "Automated Monthly Pools Engine", AppConstants.accentGold, admin),
      _buildPlaceholderDesk("Global US Stocks Brokerage Desk", Icons.trending_up, "Real-time Wall Street Settlement Bridge", AppConstants.accentBlue, admin),

      // Integrated CMS Screens
      const BinanceGatewayCmsScreen(),
      const BroadcastCmsScreen(),
      const SystemLimitsCmsScreen(),
      const MaintenanceUpdateCmsScreen(),
      const HomeBannersCmsScreen(),
      const DepositGatewaysCmsScreen(),
      const BillProvidersCmsScreen(),
      const TelecomPackagesCmsScreen(),
      const DigitalShopInventoryCmsScreen(),
      const SavingsTiersCmsScreen(),
      const TakafulPlansCmsScreen(),
      const ReferralsAffiliateCmsScreen(),
      const CurrencyRatesTickerCmsScreen(),
      const AdminRolesCmsScreen(),
      const SecurityIpWhitelistCmsScreen(),
      const AuditLogsCmsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppConstants.background,
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent(admin, pendingPayouts.length, pendingDeposits.length)),
      body: Row(
        children: [
          // Collapsible Left Navigation Drawer (Desktop)
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isSidebarCollapsed ? 82 : 280,
              decoration: BoxDecoration(
                color: AppConstants.surface,
                border: const Border(right: BorderSide(color: AppConstants.borderColor)),
                boxShadow: AppConstants.cardShadow,
              ),
              child: _buildSidebarContent(admin, pendingPayouts.length, pendingDeposits.length),
            ),

          // Main Viewport
          Expanded(
            child: Column(
              children: [
                // Top Light Navigation Bar with Global Search & Database Latency
                _buildTopHeaderBar(context, admin, isDesktop),

                // Live Financial Ticker Ribbon
                _buildFinancialMetricRibbon(admin, pendingPayouts.length, pendingDeposits.length, totalPendingPayoutAmount, totalPendingDepositAmount),

                // Active Workspace Screen
                Expanded(
                  child: Container(
                    color: AppConstants.background,
                    child: admin.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
                        : pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Top Light Navigation Header
  Widget _buildTopHeaderBar(BuildContext context, AdminProvider admin, bool isDesktop) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        border: const Border(bottom: BorderSide(color: AppConstants.borderColor)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppConstants.textPrimary),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isSidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: AppConstants.textPrimary,
                size: 22,
              ),
              tooltip: _isSidebarCollapsed ? "Expand Sidebar" : "Collapse Sidebar",
              onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
          const SizedBox(width: 12),

          // Omni-Search Bar
          Expanded(
            child: Container(
              height: 42,
              constraints: const BoxConstraints(maxWidth: 480),
              child: TextField(
                style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "Omni Search: Desks, Screens, User CNIC, TRX IDs...",
                  hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.textMuted, size: 20),
                  suffixIcon: _globalSearchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: AppConstants.textMuted),
                    onPressed: () => setState(() => _globalSearchQuery = ""),
                  )
                      : null,
                  filled: true,
                  fillColor: AppConstants.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConstants.accentGreen, width: 1.5)),
                ),
                onChanged: (val) => setState(() => _globalSearchQuery = val.trim().toLowerCase()),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Real-time Database Health Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.accentGreenLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text("●", style: TextStyle(color: AppConstants.accentGreen, fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  "LIVE DB • ${DateFormat('hh:mm:ss a').format(_lastSyncTime)}",
                  style: const TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Sync Ledger Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.textPrimary,
              side: const BorderSide(color: AppConstants.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _refreshLiveLedger,
            icon: const Icon(Icons.sync_rounded, size: 16, color: AppConstants.accentGreen),
            label: const Text("Sync Ledger", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const SizedBox(width: 12),

          // Operator Profile & Logout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppConstants.accentGreen,
                  child: const Text("A", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
                if (isDesktop && !_isSidebarCollapsed) ...[
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("root_admin", style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text("Super Administrator", style: TextStyle(color: AppConstants.textMuted, fontSize: 9.5)),
                    ],
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppConstants.dangerRed),
                  tooltip: "Sign Out",
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Live Financial Metric Ribbon
  Widget _buildFinancialMetricRibbon(AdminProvider admin, int pendingPayoutsCount, int pendingDepositsCount, double pendingPayoutsVol, double pendingDepositsVol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        border: const Border(bottom: BorderSide(color: AppConstants.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricTile("TOTAL VERIFIED USERS", "${admin.users.length} Accounts", Icons.people_alt_rounded, AppConstants.accentBlue, AppConstants.accentBlueLight),
            _buildMetricDivider(),
            _buildMetricTile("PENDING PAYOUTS", "₨ ${_currencyFormat.format(pendingPayoutsVol)} ($pendingPayoutsCount Req)", Icons.output_rounded, AppConstants.dangerRed, AppConstants.dangerRedLight),
            _buildMetricDivider(),
            _buildMetricTile("DEPOSIT CLEARANCES", "₨ ${_currencyFormat.format(pendingDepositsVol)} ($pendingDepositsCount Req)", Icons.input_rounded, AppConstants.accentGreen, AppConstants.accentGreenLight),
            _buildMetricDivider(),
            _buildMetricTile("GATEWAY STATUS", "24/24 Operational", Icons.verified_rounded, AppConstants.accentGold, AppConstants.accentGoldLight),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color, Color bgColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 20), width: 1, height: 28, color: AppConstants.borderColor);
  }

  // Light Sidebar Content
  Widget _buildSidebarContent(AdminProvider admin, int pendingPayouts, int pendingDeposits) {
    return Column(
      children: [
        // Brand Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppConstants.borderColor))),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Center(child: Text("N", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NexPay Admin", style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
                    Text("Fintech Console v2.5", style: TextStyle(color: AppConstants.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Navigation Items Tree
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _navigationDirectory.map((group) {
              final items = (group['items'] as List).where((it) {
                if (_globalSearchQuery.isEmpty) return true;
                return it['title'].toString().toLowerCase().contains(_globalSearchQuery);
              }).toList();

              if (items.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isSidebarCollapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(
                        group['group'],
                        style: const TextStyle(color: AppConstants.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                      ),
                    ),
                  ...items.map((item) {
                    final int id = item['id'];
                    final bool isSelected = _selectedIndex == id;

                    // Counter badge calculation
                    int badgeCount = 0;
                    if (id == 1) badgeCount = pendingPayouts;
                    if (id == 3) badgeCount = pendingDeposits;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? AppConstants.accentGreenLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppConstants.accentGreen.withValues(alpha: 0.4) : Colors.transparent),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 12 : 12, vertical: 2),
                        leading: Icon(
                          item['icon'],
                          size: 20,
                          color: isSelected ? AppConstants.accentGreen : AppConstants.textMuted,
                        ),
                        title: _isSidebarCollapsed
                            ? null
                            : Text(
                          item['title'],
                          style: TextStyle(
                            color: isSelected ? AppConstants.accentGreen : AppConstants.textPrimary,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: (!_isSidebarCollapsed && badgeCount > 0)
                            ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.dangerRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text("$badgeCount", style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        )
                            : null,
                        onTap: () {
                          setState(() => _selectedIndex = id);
                          if (MediaQuery.of(context).size.width < 1100) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Screen 0: Executive Dashboard Desk
  Widget _buildLiveOperationsDashboard(AdminProvider admin, int pendingPayouts, int pendingDeposits, double payoutsVol, double depositsVol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Executive Operations Overview", style: TextStyle(color: AppConstants.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text("Real-time telemetry showing live customer activities, pending clearances, and financial liquidity", style: TextStyle(color: AppConstants.textMuted, fontSize: 12.5)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _refreshLiveLedger,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text("Run Ledger Audit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Big Feature Cards
          Row(
            children: [
              Expanded(
                child: _buildActionInsightCard(
                  "Withdrawals Queue",
                  "₨ ${_currencyFormat.format(payoutsVol)}",
                  "$pendingPayouts requests waiting for treasury dispatch",
                  Icons.send_and_archive,
                  AppConstants.dangerRed,
                  AppConstants.dangerRedLight,
                      () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionInsightCard(
                  "Manual Deposits Clearance",
                  "₨ ${_currencyFormat.format(depositsVol)}",
                  "$pendingDeposits bank slips submitted by customers",
                  Icons.move_to_inbox,
                  AppConstants.accentGreen,
                  AppConstants.accentGreenLight,
                      () => setState(() => _selectedIndex = 3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionInsightCard(
                  "Registered User Base",
                  "${admin.users.length} Verified Users",
                  "Active Tier-1 & Tier-2 customer accounts",
                  Icons.people_alt_rounded,
                  AppConstants.accentBlue,
                  AppConstants.accentBlueLight,
                      () => setState(() => _selectedIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Operational Activity Feed
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppConstants.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppConstants.borderColor),
              boxShadow: AppConstants.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Latest Pending Withdrawals (Action Required)", style: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w900, fontSize: 15)),
                    TextButton(onPressed: () => setState(() => _selectedIndex = 1), child: const Text("View All Payouts →", style: TextStyle(color: AppConstants.accentGreen, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 12),
                if (admin.payouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text("All transactions cleared. Zero pending requests in queue.", style: TextStyle(color: AppConstants.textMuted, fontSize: 13))),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: admin.payouts.take(5).length,
                    separatorBuilder: (_, __) => const Divider(color: AppConstants.borderColor, height: 16),
                    itemBuilder: (ctx, idx) {
                      final item = admin.payouts[idx];
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppConstants.dangerRedLight, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.arrow_upward_rounded, color: AppConstants.dangerRed, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Customer: ${item['phone'] ?? item['userId'] ?? 'Account'}", style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w900, fontSize: 13.5)),
                                Text("Channel: ${item['method'] ?? 'Bank Transfer'} • ${item['accountNumber'] ?? '-'}", style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text("₨ ${_currencyFormat.format(double.tryParse(item['amount']?.toString() ?? '0') ?? 0)}", style: const TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w900, fontSize: 15)),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionInsightCard(String title, String mainValue, String subtitle, IconData icon, Color color, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppConstants.borderColor),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11.5, fontWeight: FontWeight.w800)),
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            Text(mainValue, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderDesk(String title, IconData icon, String subtitle, Color themeColor, AdminProvider admin) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppConstants.borderColor),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 48, color: themeColor)),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppConstants.textMuted, fontSize: 12.5)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _refreshLiveLedger,
              icon: const Icon(Icons.sync, size: 16),
              label: const Text("Sync Live Records"),
            ),
          ],
        ),
      ),
    );
  }
}