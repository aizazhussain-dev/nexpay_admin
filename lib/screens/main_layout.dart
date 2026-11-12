import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/nexpay_ui_kit.dart';
import 'login_screen.dart';

// --- Operations & Financial Desks (01 to 17) ---
import 'desks/01_dashboard_desk.dart';
import 'desks/02_manual_payouts_desk.dart';
import 'desks/03_deposits_desk.dart';
import 'desks/04_outward_ledger_desk.dart';
import 'desks/05_loans_desk.dart';
import 'desks/06_gaming_orders_desk.dart';
import 'desks/07_mature_vaults_desk.dart';
import 'desks/08_audit_trail_desk.dart';
import 'desks/09_support_tickets_desk.dart';
import 'desks/10_gold_dispatch_desk.dart';
import 'desks/11_stocks_trading_desk.dart';
import 'desks/12_takaful_claims_desk.dart';
import 'desks/13_digital_kameti_desk.dart';
import 'desks/14_closure_requests_desk.dart';
import 'desks/15_users_directory_screen.dart';
import 'desks/16_kyc_verification_desk.dart';
import 'desks/17_customer_dossier_screen.dart';

// --- System CMS Screens (18 to 20 in desks, 21 to 33 in cms) ---
import 'desks/18_binance_gateway_cms.dart';
import 'desks/19_broadcast_cms.dart';
import 'desks/20_system_limits_cms.dart';
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

class _NavItem {
  final int index;
  final String title;
  final String category;
  final IconData icon;
  final String? badgeKey;

  const _NavItem({
    required this.index,
    required this.title,
    required this.category,
    required this.icon,
    this.badgeKey,
  });
}

class _NavGroup {
  final String groupTitle;
  final List<_NavItem> items;

  const _NavGroup({required this.groupTitle, required this.items});
}

class MainAdminLayout extends StatefulWidget {
  const MainAdminLayout({super.key});

  @override
  State<MainAdminLayout> createState() => _MainAdminLayoutState();
}

class _MainAdminLayoutState extends State<MainAdminLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  DateTime _lastSyncTime = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _sidebarScrollController = ScrollController();
  String _searchQuery = '';

  final NumberFormat _compactCurrency = NumberFormat.compact(locale: 'en_US');

  final List<_NavGroup> _navGroups = const [
    _NavGroup(
      groupTitle: 'COMMAND & TREASURY',
      items: [
        _NavItem(
            index: 0,
            title: 'Executive Dashboard',
            category: 'Command Center',
            icon: Icons.space_dashboard_rounded),
        _NavItem(
            index: 1,
            title: 'Manual Payouts Desk',
            category: 'Treasury',
            icon: Icons.outbox_rounded,
            badgeKey: 'payouts'),
        _NavItem(
            index: 2,
            title: 'Deposits Clearing',
            category: 'Treasury',
            icon: Icons.move_to_inbox_rounded,
            badgeKey: 'deposits'),
        _NavItem(
            index: 3,
            title: 'Outward Ledger',
            category: 'Treasury',
            icon: Icons.receipt_long_rounded),
      ],
    ),
    _NavGroup(
      groupTitle: 'CUSTOMERS & COMPLIANCE',
      items: [
        _NavItem(
            index: 4,
            title: 'Users Directory',
            category: 'Customers',
            icon: Icons.people_alt_rounded,
            badgeKey: 'users'),
        _NavItem(
            index: 5,
            title: 'Biometric KYC Desk',
            category: 'Compliance',
            icon: Icons.verified_user_rounded,
            badgeKey: 'kyc'),
        _NavItem(
            index: 6,
            title: 'Customer 360° Dossiers',
            category: 'Customers',
            icon: Icons.folder_shared_rounded),
        _NavItem(
            index: 7,
            title: 'Closure Requests',
            category: 'Compliance',
            icon: Icons.person_off_rounded,
            badgeKey: 'closures'),
        _NavItem(
            index: 8,
            title: 'Support Helpdesk',
            category: 'Operations',
            icon: Icons.support_agent_rounded,
            badgeKey: 'tickets'),
      ],
    ),
    _NavGroup(
      groupTitle: 'CREDIT, ROSCA & VAULTS',
      items: [
        _NavItem(
            index: 9,
            title: 'EasyCash Loans Desk',
            category: 'Credit',
            icon: Icons.account_balance_rounded,
            badgeKey: 'loans'),
        _NavItem(
            index: 10,
            title: 'Digital Kameti ROSCA',
            category: 'ROSCA',
            icon: Icons.groups_rounded),
        _NavItem(
            index: 11,
            title: 'Matured Savings Vaults',
            category: 'Vaults',
            icon: Icons.lock_clock_rounded),
        _NavItem(
            index: 12,
            title: 'Takaful Claims Desk',
            category: 'Insurance',
            icon: Icons.health_and_safety_rounded,
            badgeKey: 'takaful'),
      ],
    ),
    _NavGroup(
      groupTitle: 'MARKETS, BULLION & SHOP',
      items: [
        _NavItem(
            index: 13,
            title: 'US Stocks Brokerage',
            category: 'Equities',
            icon: Icons.candlestick_chart_rounded),
        _NavItem(
            index: 14,
            title: '24K Gold Mint Dispatch',
            category: 'Bullion',
            icon: Icons.diamond_rounded),
        _NavItem(
            index: 15,
            title: 'Gaming Vouchers Desk',
            category: 'Digital Fulfillment',
            icon: Icons.sports_esports_rounded,
            badgeKey: 'vouchers'),
        _NavItem(
            index: 16,
            title: 'Forensic Audit Trail',
            category: 'Risk & Security',
            icon: Icons.policy_rounded),
      ],
    ),
    _NavGroup(
      groupTitle: 'SYSTEM CMS & GATEWAYS',
      items: [
        _NavItem(
            index: 17,
            title: 'Binance P2P Gateway',
            category: 'CMS',
            icon: Icons.currency_bitcoin_rounded),
        _NavItem(
            index: 18,
            title: 'Bank Broadcast Notice',
            category: 'CMS',
            icon: Icons.campaign_rounded),
        _NavItem(
            index: 19,
            title: 'Limits & SBP Compliance',
            category: 'CMS',
            icon: Icons.tune_rounded),
        _NavItem(
            index: 20,
            title: 'Maintenance & Versioning',
            category: 'CMS',
            icon: Icons.system_security_update_rounded),
        _NavItem(
            index: 21,
            title: 'Home Promo Banners',
            category: 'CMS',
            icon: Icons.view_carousel_rounded),
        _NavItem(
            index: 22,
            title: 'Deposit Gateways (Banks)',
            category: 'CMS',
            icon: Icons.account_balance_wallet_rounded),
        _NavItem(
            index: 23,
            title: 'Utility Biller Companies',
            category: 'CMS',
            icon: Icons.bolt_rounded),
        _NavItem(
            index: 24,
            title: 'Telecom Packages Catalog',
            category: 'CMS',
            icon: Icons.signal_cellular_alt_rounded),
        _NavItem(
            index: 25,
            title: 'Digital Shop Inventory',
            category: 'CMS',
            icon: Icons.vpn_key_rounded),
        _NavItem(
            index: 26,
            title: 'Savings Tiers & Halal ROI',
            category: 'CMS',
            icon: Icons.savings_rounded),
        _NavItem(
            index: 27,
            title: 'Takaful Plans & Policies',
            category: 'CMS',
            icon: Icons.shield_rounded),
        _NavItem(
            index: 28,
            title: 'Referrals & Affiliate',
            category: 'CMS',
            icon: Icons.share_rounded),
        _NavItem(
            index: 29,
            title: 'FX Rates & Live Ticker',
            category: 'CMS',
            icon: Icons.currency_exchange_rounded),
        _NavItem(
            index: 30,
            title: 'Admin RBAC & Roles',
            category: 'CMS',
            icon: Icons.admin_panel_settings_rounded),
        _NavItem(
            index: 31,
            title: 'IP Whitelist & Security',
            category: 'CMS',
            icon: Icons.security_rounded),
        _NavItem(
            index: 32,
            title: 'System Audit Logs',
            category: 'CMS',
            icon: Icons.history_edu_rounded),
      ],
    ),
  ];

  final List<Widget> _screens = const [
    DashboardDeskScreen(),
    ManualPayoutsDeskScreen(),
    DepositsDeskScreen(),
    OutwardLedgerDeskScreen(),
    UsersDirectoryScreen(),
    KycVerificationDeskScreen(),
    CustomerDossierScreen(),
    ClosureRequestsDeskScreen(),
    SupportTicketsDeskScreen(),
    LoansDeskScreen(),
    DigitalKametiDeskScreen(),
    MatureVaultsDeskScreen(),
    TakafulClaimsDeskScreen(),
    StocksTradingDeskScreen(),
    GoldDispatchDeskScreen(),
    GamingOrdersDeskScreen(),
    AuditTrailDeskScreen(),
    BinanceGatewayCmsScreen(),
    BroadcastCmsScreen(),
    SystemLimitsCmsScreen(),
    MaintenanceUpdateCmsScreen(),
    HomeBannersCmsScreen(),
    DepositGatewaysCmsScreen(),
    BillProvidersCmsScreen(),
    TelecomPackagesCmsScreen(),
    DigitalShopInventoryCmsScreen(),
    SavingsTiersCmsScreen(),
    TakafulPlansCmsScreen(),
    ReferralsAffiliateCmsScreen(),
    CurrencyRatesTickerCmsScreen(),
    AdminRolesCmsScreen(),
    SecurityIpWhitelistCmsScreen(),
    AuditLogsCmsScreen(),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _sidebarScrollController.dispose();
    super.dispose();
  }

  _NavItem get _activeItem {
    for (final g in _navGroups) {
      for (final item in g.items) {
        if (item.index == _selectedIndex) return item;
      }
    }
    return _navGroups.first.items.first;
  }

  int _getBadgeCount(AdminProvider admin, String? key) {
    if (key == null) return 0;
    switch (key) {
      case 'payouts':
        return admin.payouts
            .where((p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING')
            .length;
      case 'deposits':
        return admin.deposits
            .where((d) => (d['status'] ?? '').toString().toUpperCase() == 'PENDING')
            .length;
      case 'users':
        return admin.users.length;
      case 'kyc':
        int count = 0;
        admin.users.forEach((_, u) {
          if (u is Map &&
              (u['kycStatus'] ?? '').toString().toUpperCase() == 'PENDING') {
            count++;
          }
        });
        return count;
      case 'tickets':
        return admin.tickets
            .where((t) => (t['status'] ?? '').toString().toUpperCase() == 'OPEN')
            .length;
      case 'loans':
        return admin.loans
            .where((l) =>
        (l['status'] ?? '').toString().toUpperCase() == 'UNDER_REVIEW')
            .length;
      case 'vouchers':
        return admin.voucherOrders
            .where((v) => (v['status'] ?? '').toString().toUpperCase() == 'PENDING')
            .length;
      case 'takaful':
        return admin.takafulClaims
            .where((c) => (c['status'] ?? '').toString().toUpperCase() == 'PENDING')
            .length;
      case 'closures':
        return admin.closureRequests
            .where((r) => (r['status'] ?? '').toString().toUpperCase() == 'PENDING')
            .length;
      default:
        return 0;
    }
  }

  void _openQuickCommandPalette() {
    final allItems = _navGroups.expand((g) => g.items).toList();
    String query = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = query.isEmpty
                ? allItems
                : allItems
                .where((i) =>
            i.title.toLowerCase().contains(query) ||
                i.category.toLowerCase().contains(query))
                .toList();

            return Dialog(
              backgroundColor: AppConstants.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppConstants.borderColor),
              ),
              child: SizedBox(
                width: 520,
                height: 440,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: TextField(
                        autofocus: true,
                        onChanged: (v) =>
                            setModalState(() => query = v.trim().toLowerCase()),
                        style: TextStyle(
                            color: AppConstants.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                          'Quick jump to any of 33 Desks or CMS modules...',
                          prefixIcon: Icon(Icons.bolt_rounded,
                              color: AppConstants.accentGreen),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: AppConstants.borderColor),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filtered.length,
                        itemBuilder: (_, idx) {
                          final item = filtered[idx];
                          final active = item.index == _selectedIndex;
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            selected: active,
                            selectedTileColor: AppConstants.accentGreenLight,
                            leading: Icon(
                              item.icon,
                              size: 19,
                              color: active
                                  ? AppConstants.accentGreen
                                  : AppConstants.textMuted,
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: AppConstants.textPrimary,
                                fontWeight:
                                active ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppConstants.surfaceCard,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  color: AppConstants.textMuted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() => _selectedIndex = item.index);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    double totalFloat = 0;
    admin.users.forEach((_, u) {
      if (u is Map) {
        totalFloat += double.tryParse(u['balance']?.toString() ?? '0') ?? 0;
      }
    });

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
        _openQuickCommandPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
        _openQuickCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppConstants.background,
          drawer: isDesktop
              ? null
              : Drawer(child: _buildSidebar(admin, isDrawer: true)),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop) _buildSidebar(admin, isDrawer: false),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopHeader(context, admin, isDesktop, totalFloat),
                    if (admin.isLoading)
                      LinearProgressIndicator(
                        minHeight: 2.5,
                        backgroundColor: AppConstants.accentGreenLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.accentGreen),
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _screens,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(AdminProvider admin, {required bool isDrawer}) {
    final collapsed = !isDrawer && _isSidebarCollapsed;
    final sidebarWidth = collapsed ? 74.0 : 254.0;
    final sidebarBg = AppConstants.bgDark;
    const sidebarSurface = Color(0xFF1E293B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: const Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          // Brand Header + Collapse Toggle
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!collapsed)
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'N',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NexPay Core',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'EXECUTIVE TERMINAL',
                            style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (!isDrawer)
                  IconButton(
                    tooltip: collapsed
                        ? 'Expand Sidebar'
                        : 'Full-Screen Focus Mode',
                    onPressed: () => setState(
                            () => _isSidebarCollapsed = !_isSidebarCollapsed),
                    icon: Icon(
                      collapsed
                          ? Icons.keyboard_double_arrow_right_rounded
                          : Icons.keyboard_double_arrow_left_rounded,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // Sidebar Quick Filter
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Filter desks (or Ctrl+K)...',
                  hintStyle:
                  const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  filled: true,
                  fillColor: sidebarSurface,
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 16, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 14, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
            ),

          // Navigation Groups
          Expanded(
            child: Scrollbar(
              controller: _sidebarScrollController,
              thumbVisibility: true,
              child: ListView(
                controller: _sidebarScrollController,
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: _navGroups.map((group) {
                  final visibleItems = _searchQuery.isEmpty
                      ? group.items
                      : group.items
                      .where((i) =>
                  i.title.toLowerCase().contains(_searchQuery) ||
                      i.category.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (visibleItems.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!collapsed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                          child: Text(
                            group.groupTitle,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                      ...visibleItems.map((item) {
                        final selected = _selectedIndex == item.index;
                        final badge = _getBadgeCount(admin, item.badgeKey);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2.5),
                          child: Tooltip(
                            message: collapsed ? item.title : '',
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedIndex = item.index);
                                if (isDrawer) Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: collapsed ? 0 : 11,
                                  vertical: 9.5,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF059669)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: collapsed
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: 18,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                    ),
                                    if (!collapsed) ...[
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : const Color(0xFFCBD5E1),
                                            fontSize: 12.5,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (badge > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Colors.white
                                                .withValues(alpha: 0.22)
                                                : (item.badgeKey == 'users'
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFDC2626)),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$badge',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          // Operator Footer
          Container(
            padding: EdgeInsets.all(collapsed ? 10 : 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!collapsed)
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Root Administrator',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      Text('smartvest.tech • Live',
                          style: TextStyle(
                              color: Color(0xFF34D399), fontSize: 10.5)),
                    ],
                  ),
                IconButton(
                  tooltip: 'Lock & Sign Out',
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFFF87171), size: 19),
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final nav = Navigator.of(context);
                    await auth.logout();
                    nav.pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, AdminProvider admin,
      bool isDesktop, double totalFloat) {
    final active = _activeItem;

    // Aggregate actionable queues for quick operator alerts
    final queues = [
      (
      label: 'Manual Payouts Pending',
      count: _getBadgeCount(admin, 'payouts'),
      deskIndex: 1
      ),
      (
      label: 'Deposits Awaiting Clear',
      count: _getBadgeCount(admin, 'deposits'),
      deskIndex: 2
      ),
      (
      label: 'Biometric KYC Reviews',
      count: _getBadgeCount(admin, 'kyc'),
      deskIndex: 5
      ),
      (
      label: 'Open Support Tickets',
      count: _getBadgeCount(admin, 'tickets'),
      deskIndex: 8
      ),
      (
      label: 'EasyCash Loans Review',
      count: _getBadgeCount(admin, 'loans'),
      deskIndex: 9
      ),
      (
      label: 'Gaming Vouchers Pending',
      count: _getBadgeCount(admin, 'vouchers'),
      deskIndex: 15
      ),
      (
      label: 'Takaful Claims Pending',
      count: _getBadgeCount(admin, 'takaful'),
      deskIndex: 12
      ),
      (
      label: 'Account Closure Requests',
      count: _getBadgeCount(admin, 'closures'),
      deskIndex: 7
      ),
    ];
    final totalPending = queues.fold<int>(0, (sum, q) => sum + q.count);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        border: Border(bottom: BorderSide(color: AppConstants.borderColor)),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),

          // Breadcrumb
          Expanded(
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    active.category.toUpperCase(),
                    style: TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppConstants.textLight),
                ),
                Flexible(
                  child: Text(
                    active.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick Jump Button (Ctrl + K)
          if (isDesktop) ...[
            InkWell(
              onTap: _openQuickCommandPalette,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                decoration: BoxDecoration(
                  color: AppConstants.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded,
                        size: 14, color: AppConstants.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Jump...',
                      style: TextStyle(
                          color: AppConstants.textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceCard,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ctrl+K',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildTopMetricPill(
                'FLOAT',
                'Rs. ${_compactCurrency.format(totalFloat)}',
                AppConstants.accentGreen),
            const SizedBox(width: 8),
            _buildTopMetricPill(
                'USD/PKR',
                'Rs. ${admin.usdPkrRate.toStringAsFixed(1)}',
                AppConstants.accentBlue),
            const SizedBox(width: 10),
          ],

          // Light / Dark Mode Switcher Button
          NexPayThemeToggleButton(compact: !isDesktop),
          const SizedBox(width: 8),

          // Pending Queues Alert Center
          PopupMenuButton<int>(
            tooltip: 'Actionable Queues ($totalPending Pending)',
            offset: const Offset(0, 46),
            color: AppConstants.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppConstants.borderColor),
            ),
            onSelected: (deskIdx) => setState(() => _selectedIndex = deskIdx),
            itemBuilder: (_) {
              final activeQueues = queues.where((q) => q.count > 0).toList();
              if (activeQueues.isEmpty) {
                return [
                  PopupMenuItem<int>(
                    enabled: false,
                    child: Text(
                      'All operational queues are clear',
                      style: TextStyle(
                          color: AppConstants.textMuted, fontSize: 12.5),
                    ),
                  ),
                ];
              }
              return activeQueues
                  .map(
                    (q) => PopupMenuItem<int>(
                  value: q.deskIndex,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        q.label,
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConstants.dangerRedLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${q.count}',
                          style: TextStyle(
                            color: AppConstants.dangerRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppConstants.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 16,
                    color: totalPending > 0
                        ? AppConstants.accentGold
                        : AppConstants.textMuted,
                  ),
                  if (totalPending > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5.5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppConstants.dangerRed,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$totalPending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Live Sync Button
          OutlinedButton.icon(
            onPressed: () async {
              await admin.fetchAllData();
              if (mounted) setState(() => _lastSyncTime = DateTime.now());
            },
            icon: Icon(Icons.sync_rounded,
                size: 16, color: AppConstants.accentGreen),
            label: Text(isDesktop
                ? 'Sync (${DateFormat('HH:mm').format(_lastSyncTime)})'
                : 'Sync'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetricPill(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      decoration: BoxDecoration(
        color: AppConstants.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
          Text(
            value,
            style: TextStyle(
                color: accent, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}