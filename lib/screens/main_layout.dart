import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';

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
  String _searchQuery = '';

  final NumberFormat _compactCurrency = NumberFormat.compact(locale: 'en_US');
  final NumberFormat _fullCurrency = NumberFormat('#,##0', 'en_US');

  static const Color _sidebarBg = Color(0xFF0F172A);
  static const Color _sidebarSurface = Color(0xFF1E293B);
  static const Color _sidebarBorder = Color(0xFF1E293B);

  final List<_NavGroup> _navGroups = const [
    _NavGroup(
      groupTitle: 'COMMAND & TREASURY',
      items: [
        _NavItem(index: 0, title: 'Executive Dashboard', category: 'Command Center', icon: Icons.space_dashboard_rounded),
        _NavItem(index: 1, title: 'Manual Payouts Desk', category: 'Treasury', icon: Icons.outbox_rounded, badgeKey: 'payouts'),
        _NavItem(index: 2, title: 'Deposits Clearing', category: 'Treasury', icon: Icons.move_to_inbox_rounded, badgeKey: 'deposits'),
        _NavItem(index: 3, title: 'Outward Ledger', category: 'Treasury', icon: Icons.receipt_long_rounded),
      ],
    ),
    _NavGroup(
      groupTitle: 'CUSTOMERS & COMPLIANCE',
      items: [
        _NavItem(index: 4, title: 'Users Directory', category: 'Customers', icon: Icons.people_alt_rounded, badgeKey: 'users'),
        _NavItem(index: 5, title: 'Biometric KYC Desk', category: 'Compliance', icon: Icons.verified_user_rounded, badgeKey: 'kyc'),
        _NavItem(index: 6, title: 'Customer 360° Dossiers', category: 'Customers', icon: Icons.folder_shared_rounded),
        _NavItem(index: 7, title: 'Closure Requests', category: 'Compliance', icon: Icons.person_off_rounded),
        _NavItem(index: 8, title: 'Support Helpdesk', category: 'Operations', icon: Icons.support_agent_rounded, badgeKey: 'tickets'),
      ],
    ),
    _NavGroup(
      groupTitle: 'CREDIT, ROSCA & VAULTS',
      items: [
        _NavItem(index: 9, title: 'EasyCash Loans Desk', category: 'Credit', icon: Icons.account_balance_rounded, badgeKey: 'loans'),
        _NavItem(index: 10, title: 'Digital Kameti ROSCA', category: 'ROSCA', icon: Icons.groups_rounded),
        _NavItem(index: 11, title: 'Matured Savings Vaults', category: 'Vaults', icon: Icons.lock_clock_rounded),
        _NavItem(index: 12, title: 'Takaful Claims Desk', category: 'Insurance', icon: Icons.health_and_safety_rounded),
      ],
    ),
    _NavGroup(
      groupTitle: 'MARKETS, BULLION & SHOP',
      items: [
        _NavItem(index: 13, title: 'US Stocks Brokerage', category: 'Equities', icon: Icons.candlestick_chart_rounded),
        _NavItem(index: 14, title: '24K Gold Mint Dispatch', category: 'Bullion', icon: Icons.diamond_rounded),
        _NavItem(index: 15, title: 'Gaming Vouchers Desk', category: 'Digital Fulfillment', icon: Icons.sports_esports_rounded, badgeKey: 'vouchers'),
        _NavItem(index: 16, title: 'Forensic Audit Trail', category: 'Risk & Security', icon: Icons.policy_rounded),
      ],
    ),
    _NavGroup(
      groupTitle: 'SYSTEM CMS & GATEWAYS',
      items: [
        _NavItem(index: 17, title: 'Binance P2P Gateway', category: 'CMS', icon: Icons.currency_bitcoin_rounded),
        _NavItem(index: 18, title: 'Bank Broadcast Notice', category: 'CMS', icon: Icons.campaign_rounded),
        _NavItem(index: 19, title: 'Limits & SBP Compliance', category: 'CMS', icon: Icons.tune_rounded),
        _NavItem(index: 20, title: 'Maintenance & Versioning', category: 'CMS', icon: Icons.system_security_update_rounded),
        _NavItem(index: 21, title: 'Home Promo Banners', category: 'CMS', icon: Icons.view_carousel_rounded),
        _NavItem(index: 22, title: 'Deposit Gateways (Banks)', category: 'CMS', icon: Icons.account_balance_wallet_rounded),
        _NavItem(index: 23, title: 'Utility Biller Companies', category: 'CMS', icon: Icons.bolt_rounded),
        _NavItem(index: 24, title: 'Telecom Packages Catalog', category: 'CMS', icon: Icons.signal_cellular_alt_rounded),
        _NavItem(index: 25, title: 'Digital Shop Inventory', category: 'CMS', icon: Icons.vpn_key_rounded),
        _NavItem(index: 26, title: 'Savings Tiers & Halal ROI', category: 'CMS', icon: Icons.savings_rounded),
        _NavItem(index: 27, title: 'Takaful Plans & Policies', category: 'CMS', icon: Icons.shield_rounded),
        _NavItem(index: 28, title: 'Referral Affiliate Engine', category: 'CMS', icon: Icons.share_rounded),
        _NavItem(index: 29, title: 'Forex & 24K Gold Ticker', category: 'CMS', icon: Icons.currency_exchange_rounded),
        _NavItem(index: 30, title: 'Admin Staff & RBAC Matrix', category: 'CMS', icon: Icons.admin_panel_settings_rounded),
        _NavItem(index: 31, title: 'Security, 2FA & IP Shield', category: 'CMS', icon: Icons.security_rounded),
        _NavItem(index: 32, title: 'System Audit Logs', category: 'CMS', icon: Icons.history_edu_rounded),
      ],
    ),
  ];

  List<_NavItem> get _allNavItems =>
      _navGroups.expand((group) => group.items).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLiveLedger();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshLiveLedger() async {
    await context.read<AdminProvider>().fetchAllData();
    if (mounted) {
      setState(() => _lastSyncTime = DateTime.now());
    }
  }

  Widget _buildActiveScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardDeskScreen();
      case 1:
        return const ManualPayoutsDeskScreen();
      case 2:
        return const DepositsDeskScreen();
      case 3:
        return const OutwardLedgerDeskScreen();
      case 4:
        return const UsersDirectoryDeskScreen();
      case 5:
        return const KycVerificationDeskScreen();
      case 6:
        return const CustomerDossierDeskScreen();
      case 7:
        return const ClosureRequestsDeskScreen();
      case 8:
        return const SupportTicketsDeskScreen();
      case 9:
        return const LoansDeskScreen();
      case 10:
        return const DigitalKametiDeskScreen();
      case 11:
        return const MaturedVaultsDeskScreen();
      case 12:
        return const TakafulClaimsDeskScreen();
      case 13:
        return const StocksTradingDeskScreen();
      case 14:
        return const GoldDispatchDeskScreen();
      case 15:
        return const GamingOrdersDeskScreen();
      case 16:
        return const AuditTrailDeskScreen();
      case 17:
        return const BinanceGatewayCmsScreen();
      case 18:
        return const BroadcastCmsScreen();
      case 19:
        return const SystemLimitsCmsScreen();
      case 20:
        return const MaintenanceUpdateCmsScreen();
      case 21:
        return const HomeBannersCmsScreen();
      case 22:
        return const DepositGatewaysCmsScreen();
      case 23:
        return const BillProvidersCmsScreen();
      case 24:
        return const TelecomPackagesCmsScreen();
      case 25:
        return const DigitalShopInventoryCmsScreen();
      case 26:
        return const SavingsTiersCmsScreen();
      case 27:
        return const TakafulPlansCmsScreen();
      case 28:
        return const ReferralsAffiliateCmsScreen();
      case 29:
        return const CurrencyRatesTickerCmsScreen();
      case 30:
        return const AdminRolesCmsScreen();
      case 31:
        return const SecurityIpWhitelistCmsScreen();
      case 32:
        return const AuditLogsCmsScreen();
      default:
        return const DashboardDeskScreen();
    }
  }

  int _getBadgeCount(AdminProvider admin, String? badgeKey) {
    if (badgeKey == null) return 0;
    switch (badgeKey) {
      case 'payouts':
        return admin.payouts.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING').length;
      case 'deposits':
        return admin.deposits.where((d) => (d['status'] ?? '').toString().toUpperCase() == 'PENDING').length;
      case 'loans':
        return admin.loans.where((l) => (l['status'] ?? '').toString().toUpperCase() == 'UNDER_REVIEW').length;
      case 'tickets':
        return admin.tickets.where((t) => (t['status'] ?? '').toString().toUpperCase() == 'OPEN').length;
      case 'vouchers':
        return admin.voucherOrders.where((v) => (v['status'] ?? '').toString().toUpperCase() == 'PENDING').length;
      case 'kyc':
        return admin.users.values
            .where((u) => u is Map && (u['kycStatus'] ?? '').toString().toUpperCase() == 'PENDING' && u['isKycVerified'] != true)
            .length;
      case 'users':
        return admin.users.length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final admin = context.watch<AdminProvider>();
    final currentNav = _allNavItems.firstWhere(
          (item) => item.index == _selectedIndex,
      orElse: () => _allNavItems.first,
    );

    // Live Financial Aggregations
    final pendingPayouts = admin.payouts
        .where((p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING')
        .toList();
    final pendingDeposits = admin.deposits
        .where((d) => (d['status'] ?? '').toString().toUpperCase() == 'PENDING')
        .toList();
    final pendingLoans = admin.loans
        .where((l) => (l['status'] ?? '').toString().toUpperCase() == 'UNDER_REVIEW')
        .toList();

    final totalPendingPayoutAmt = pendingPayouts.fold<double>(
      0.0,
          (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0),
    );
    final totalPendingDepositAmt = pendingDeposits.fold<double>(
      0.0,
          (sum, item) => sum + (double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0),
    );

    double totalSystemFloat = 0.0;
    int verifiedUsersCount = 0;
    admin.users.forEach((_, val) {
      if (val is Map) {
        totalSystemFloat += double.tryParse(val['balance']?.toString() ?? '0') ?? 0.0;
        if (val['isKycVerified'] == true) verifiedUsersCount++;
      }
    });

    return Scaffold(
      backgroundColor: AppConstants.background,
      drawer: isDesktop
          ? null
          : Drawer(
        backgroundColor: _sidebarBg,
        child: _buildSidebar(admin, isDrawer: true),
      ),
      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _isSidebarCollapsed ? 78 : 276,
              decoration: const BoxDecoration(
                color: _sidebarBg,
                border: Border(right: BorderSide(color: _sidebarBorder)),
              ),
              child: _buildSidebar(admin, isDrawer: false),
            ),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopCommandBar(context, admin, currentNav, isDesktop),
                    _buildExecutiveTickerBar(
                      totalUsers: admin.users.length,
                      verifiedUsers: verifiedUsersCount,
                      totalFloat: totalSystemFloat,
                      pendingPayoutsCount: pendingPayouts.length,
                      pendingPayoutsAmt: totalPendingPayoutAmt,
                      pendingDepositsCount: pendingDeposits.length,
                      pendingDepositsAmt: totalPendingDepositAmt,
                      pendingLoansCount: pendingLoans.length,
                    ),
                    Expanded(
                      child: Container(
                        color: AppConstants.background,
                        child: _buildActiveScreen(_selectedIndex),
                      ),
                    ),
                  ],
                ),
                if (_searchQuery.isNotEmpty)
                  Positioned(
                    top: 66,
                    left: isDesktop ? 24 : 16,
                    child: _buildOmniSearchOverlay(admin),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AdminProvider admin, {required bool isDrawer}) {
    final collapsed = !isDrawer && _isSidebarCollapsed;

    return Column(
      children: [
        // Brand Header
        Container(
          height: 68,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 14 : 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _sidebarBorder)),
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NexPay Core',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'EXECUTIVE CONSOLE',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Navigation Tree
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            itemCount: _navGroups.length,
            itemBuilder: (context, gIndex) {
              final group = _navGroups[gIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!collapsed)
                    Padding(
                      padding: EdgeInsets.fromLTRB(12, gIndex == 0 ? 4 : 18, 12, 8),
                      child: Text(
                        group.groupTitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    )
                  else if (gIndex > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Divider(color: _sidebarSurface, height: 1),
                    ),
                  ...group.items.map((item) {
                    final isSelected = _selectedIndex == item.index;
                    final count = _getBadgeCount(admin, item.badgeKey);
                    final isAlertBadge = item.badgeKey != null && item.badgeKey != 'users' && count > 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Tooltip(
                        message: collapsed ? item.title : '',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _selectedIndex = item.index;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                            if (isDrawer) Navigator.of(context).pop();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: EdgeInsets.symmetric(
                              horizontal: collapsed ? 0 : 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981).withValues(alpha: 0.16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF10B981).withValues(alpha: 0.45)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: collapsed
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 19,
                                  color: isSelected
                                      ? const Color(0xFF34D399)
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
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFFCBD5E1),
                                        fontSize: 12.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (count > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isAlertBadge
                                            ? const Color(0xFFEF4444)
                                            : _sidebarSurface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          color: isAlertBadge
                                              ? Colors.white
                                              : const Color(0xFF94A3B8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
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
            },
          ),
        ),

        // Bottom Server Footer
        Container(
          padding: EdgeInsets.all(collapsed ? 10 : 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _sidebarBorder)),
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'smartvest.tech • SSL Active',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopCommandBar(
      BuildContext context,
      AdminProvider admin,
      _NavItem currentNav,
      bool isDesktop,
      ) {
    final formattedTime = DateFormat('hh:mm:ss a').format(_lastSyncTime);

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppConstants.surface,
        border: Border(bottom: BorderSide(color: AppConstants.borderColor)),
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
                size: 21,
              ),
              tooltip: _isSidebarCollapsed ? 'Expand Navigation' : 'Collapse Navigation',
              onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
          const SizedBox(width: 8),

          // Active Module Breadcrumb
          if (isDesktop) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentNav.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppConstants.accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                Text(
                  currentNav.title,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
          ],

          // Omni-Search Bar
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 420),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Jump to any Desk, CMS, Customer Mobile or CNIC...',
                  hintStyle: const TextStyle(color: AppConstants.textMuted, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.textMuted, size: 19),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppConstants.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: AppConstants.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppConstants.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppConstants.accentGreen, width: 1.5),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Live DB Status Pill
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppConstants.accentGreenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppConstants.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'LIVE DB • $formattedTime',
                    style: const TextStyle(
                      color: AppConstants.accentGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),

          // Sync Ledger Button
          OutlinedButton.icon(
            onPressed: admin.isLoading ? null : _refreshLiveLedger,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.textPrimary,
              side: const BorderSide(color: AppConstants.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: admin.isLoading
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.accentGreen),
            )
                : const Icon(Icons.sync_rounded, size: 17, color: AppConstants.accentGreen),
            label: Text(
              admin.isLoading ? 'Syncing...' : 'Sync Ledger',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),

          // Logged-in Executive Profile Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppConstants.accentGreen,
                  child: Text(
                    AppConstants.defaultAdminUser.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 9),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.defaultAdminUser,
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Executive Owner',
                        style: TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 17, color: AppConstants.dangerRed),
                  tooltip: 'Lock & Sign Out',
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  padding: EdgeInsets.zero,
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveTickerBar({
    required int totalUsers,
    required int verifiedUsers,
    required double totalFloat,
    required int pendingPayoutsCount,
    required double pendingPayoutsAmt,
    required int pendingDepositsCount,
    required double pendingDepositsAmt,
    required int pendingLoansCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppConstants.surface,
        border: Border(bottom: BorderSide(color: AppConstants.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiChip(
              icon: Icons.account_balance_wallet_rounded,
              color: AppConstants.accentGreen,
              bgColor: AppConstants.accentGreenLight,
              label: 'TOTAL WALLET FLOAT',
              value: 'Rs ${_fullCurrency.format(totalFloat)}',
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            const SizedBox(width: 12),
            _buildKpiChip(
              icon: Icons.people_alt_rounded,
              color: AppConstants.accentBlue,
              bgColor: AppConstants.accentBlueLight,
              label: 'CUSTOMERS (KYC)',
              value: '$totalUsers Total ($verifiedUsers Verified)',
              onTap: () => setState(() => _selectedIndex = 4),
            ),
            const SizedBox(width: 12),
            _buildKpiChip(
              icon: Icons.outbox_rounded,
              color: AppConstants.dangerRed,
              bgColor: AppConstants.dangerRedLight,
              label: 'PENDING PAYOUTS',
              value: 'Rs ${_compactCurrency.format(pendingPayoutsAmt)} ($pendingPayoutsCount Req)',
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(width: 12),
            _buildKpiChip(
              icon: Icons.move_to_inbox_rounded,
              color: AppConstants.accentGreen,
              bgColor: AppConstants.accentGreenLight,
              label: 'DEPOSIT QUEUE',
              value: 'Rs ${_compactCurrency.format(pendingDepositsAmt)} ($pendingDepositsCount Req)',
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            const SizedBox(width: 12),
            _buildKpiChip(
              icon: Icons.request_quote_rounded,
              color: AppConstants.accentGold,
              bgColor: AppConstants.accentGoldLight,
              label: 'LOAN APPLICATIONS',
              value: '$pendingLoansCount Under Review',
              onTap: () => setState(() => _selectedIndex = 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiChip({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppConstants.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    color: color == AppConstants.dangerRed
                        ? AppConstants.dangerRed
                        : AppConstants.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOmniSearchOverlay(AdminProvider admin) {
    final matchingModules = _allNavItems
        .where((m) =>
    m.title.toLowerCase().contains(_searchQuery) ||
        m.category.toLowerCase().contains(_searchQuery))
        .take(6)
        .toList();

    final matchingUsers = admin.users.entries.where((entry) {
      final u = entry.value;
      if (u is! Map) return false;
      final name = (u['name'] ?? '').toString().toLowerCase();
      final mobile = (u['mobile'] ?? entry.key).toString().toLowerCase();
      final cnic = (u['cnic'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) ||
          mobile.contains(_searchQuery) ||
          cnic.contains(_searchQuery);
    }).take(5).toList();

    return Material(
      elevation: 14,
      borderRadius: BorderRadius.circular(14),
      color: AppConstants.surface,
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          children: [
            if (matchingModules.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'MODULES & DESKS',
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...matchingModules.map((m) => ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: Icon(m.icon, size: 18, color: AppConstants.accentGreen),
                title: Text(
                  m.title,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  m.category,
                  style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                ),
                onTap: () {
                  setState(() {
                    _selectedIndex = m.index;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )),
            ],
            if (matchingUsers.isNotEmpty) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'MATCHING CUSTOMERS',
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...matchingUsers.map((entry) {
                final u = entry.value as Map;
                return ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.person_rounded, size: 18, color: AppConstants.accentBlue),
                  title: Text(
                    '${u['name'] ?? 'User'} (${u['mobile'] ?? entry.key})',
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Balance: Rs ${u['balance'] ?? 0} • CNIC: ${u['cnic'] ?? 'N/A'}',
                    style: const TextStyle(color: AppConstants.textMuted, fontSize: 11),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 4; // Open Users Directory
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                );
              }),
            ],
            if (matchingModules.isEmpty && matchingUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No matching desk or customer found.',
                    style: TextStyle(color: AppConstants.textMuted, fontSize: 12.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}