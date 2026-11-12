import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Reusable Light/Dark Mode Switcher Button
class NexPayThemeToggleButton extends StatelessWidget {
  final bool compact;

  const NexPayThemeToggleButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NexPayThemeController.instance,
      builder: (context, _) {
        final isDark = NexPayThemeController.instance.isDark;
        if (compact) {
          return Tooltip(
            message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            child: InkWell(
              onTap: () => NexPayThemeController.instance.toggleTheme(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFFFBBF24) : AppConstants.textSecondary,
                ),
              ),
            ),
          );
        }

        return InkWell(
          onTap: () => NexPayThemeController.instance.toggleTheme(),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 15,
                  color: isDark ? const Color(0xFFFBBF24) : AppConstants.accentBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  isDark ? 'Light Mode' : 'Dark Mode',
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 1. Full-Screen Desk Canvas with Guaranteed Right-Edge Vertical Scrollbar & Quick Scroll-to-Top
class NexPayDeskScaffold extends StatefulWidget {
  final Widget header;
  final Widget? statStrip;
  final Widget? filterBar;
  final Widget body;
  final EdgeInsetsGeometry padding;

  const NexPayDeskScaffold({
    super.key,
    required this.header,
    this.statStrip,
    this.filterBar,
    required this.body,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  State<NexPayDeskScaffold> createState() => _NexPayDeskScaffoldState();
}

class _NexPayDeskScaffoldState extends State<NexPayDeskScaffold> {
  final ScrollController _verticalController = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_verticalController.hasClients) return;
    final shouldShow = _verticalController.offset > 340;
    if (shouldShow != _showScrollTop) {
      setState(() => _showScrollTop = shouldShow);
    }
  }

  @override
  void dispose() {
    _verticalController.removeListener(_onScroll);
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Container(
            color: AppConstants.background,
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 10,
              radius: const Radius.circular(6),
              child: SingleChildScrollView(
                controller: _verticalController,
                primary: false,
                padding: widget.padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    widget.header,
                    if (widget.statStrip != null) ...[
                      const SizedBox(height: 18),
                      widget.statStrip!,
                    ],
                    if (widget.filterBar != null) ...[
                      const SizedBox(height: 18),
                      widget.filterBar!,
                    ],
                    const SizedBox(height: 16),
                    widget.body,
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
          if (_showScrollTop)
            Positioned(
              right: 24,
              bottom: 22,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                color: AppConstants.bgDark,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _verticalController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward_rounded,
                            size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Top',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 2. Full-Width Data Table with Built-In Client Pagination & Bottom Scrollbar
class NexPayFullWidthTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget? emptyState;
  final double minTableWidth;
  final bool enablePagination;
  final int initialRowsPerPage;

  const NexPayFullWidthTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyState,
    this.minTableWidth = 980,
    this.enablePagination = true,
    this.initialRowsPerPage = 15,
  });

  @override
  State<NexPayFullWidthTable> createState() => _NexPayFullWidthTableState();
}

class _NexPayFullWidthTableState extends State<NexPayFullWidthTable> {
  final ScrollController _horizontalController = ScrollController();
  int _currentPage = 0;
  late int _rowsPerPage;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.initialRowsPerPage;
  }

  @override
  void didUpdateWidget(covariant NexPayFullWidthTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxPage = widget.rows.isEmpty
        ? 0
        : ((widget.rows.length - 1) / _rowsPerPage).floor();
    if (_currentPage > maxPage) {
      _currentPage = maxPage;
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty && widget.emptyState != null) {
      return widget.emptyState!;
    }

    final total = widget.rows.length;
    final totalPages =
    total == 0 ? 1 : (total / _rowsPerPage).ceil();
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final startIdx = widget.enablePagination ? safePage * _rowsPerPage : 0;
    final endIdx = widget.enablePagination
        ? (startIdx + _rowsPerPage).clamp(0, total)
        : total;
    final visibleRows = widget.rows.sublist(startIdx, endIdx);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: AppConstants.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final targetWidth = constraints.maxWidth > widget.minTableWidth
                    ? constraints.maxWidth
                    : widget.minTableWidth;

                return Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thickness: 9,
                  radius: const Radius.circular(6),
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: targetWidth),
                      child: DataTable(
                        headingRowHeight: 46,
                        dataRowMinHeight: 54,
                        dataRowMaxHeight: 70,
                        horizontalMargin: 20,
                        columnSpacing: 24,
                        headingRowColor:
                        WidgetStateProperty.all(AppConstants.surfaceCard),
                        dataRowColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return AppConstants.surfaceCard
                                .withValues(alpha: 0.55);
                          }
                          return AppConstants.surface;
                        }),
                        dividerThickness: 1,
                        columns: widget.columns,
                        rows: visibleRows,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (widget.enablePagination && total > 0)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceCard.withValues(alpha: 0.65),
                  border:
                  Border(top: BorderSide(color: AppConstants.borderColor)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Showing ${startIdx + 1}–$endIdx of $total records',
                      style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rows:',
                          style: TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppConstants.surface,
                            borderRadius: BorderRadius.circular(6),
                            border:
                            Border.all(color: AppConstants.borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _rowsPerPage,
                              isDense: true,
                              dropdownColor: AppConstants.surface,
                              style: TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              items: const [15, 30, 50, 100]
                                  .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text('$v'),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _rowsPerPage = val;
                                    _currentPage = 0;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Page ${safePage + 1} of $totalPages',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PageNavBtn(
                          icon: Icons.first_page_rounded,
                          enabled: safePage > 0,
                          onTap: () => setState(() => _currentPage = 0),
                        ),
                        const SizedBox(width: 4),
                        _PageNavBtn(
                          icon: Icons.chevron_left_rounded,
                          enabled: safePage > 0,
                          onTap: () =>
                              setState(() => _currentPage = safePage - 1),
                        ),
                        const SizedBox(width: 4),
                        _PageNavBtn(
                          icon: Icons.chevron_right_rounded,
                          enabled: safePage < totalPages - 1,
                          onTap: () =>
                              setState(() => _currentPage = safePage + 1),
                        ),
                        const SizedBox(width: 4),
                        _PageNavBtn(
                          icon: Icons.last_page_rounded,
                          enabled: safePage < totalPages - 1,
                          onTap: () =>
                              setState(() => _currentPage = totalPages - 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageNavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageNavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: enabled ? AppConstants.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? AppConstants.borderColor
                : AppConstants.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? AppConstants.textPrimary : AppConstants.textLight,
        ),
      ),
    );
  }
}

/// 3. Executive Page Header
class NexPayDeskHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final List<Widget> actions;

  const NexPayDeskHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final accent = badgeColor ?? AppConstants.accentGreen;
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badgeText!,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        if (actions.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
      ],
    );
  }
}

/// 4. Full-Width Slim KPI Strip
class NexPayStatItem {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color color;

  const NexPayStatItem({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.color,
  });
}

class NexPayStatStrip extends StatelessWidget {
  final List<NexPayStatItem> items;

  const NexPayStatStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = items.length;
        final cols = constraints.maxWidth >= 1050
            ? count
            : (constraints.maxWidth >= 600 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (14 * (cols - 1))) / cols;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: items.map((item) {
            return Container(
              width: cardWidth,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                color: AppConstants.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.borderColor),
                boxShadow: AppConstants.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10),
                      border:
                      Border.all(color: item.color.withValues(alpha: 0.22)),
                    ),
                    child: Icon(item.icon, size: 20, color: item.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.sublabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// 5. Full-Width Search & Status Filter Toolbar
class NexPayFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final String resultSummary;

  const NexPayFilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.resultSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 340,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(color: AppConstants.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: AppConstants.textMuted),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged('');
                  },
                )
                    : null,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...filters.map((f) {
                final active = selectedFilter == f;
                return InkWell(
                  onTap: () => onFilterChanged(f),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? AppConstants.accentGreen
                          : AppConstants.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? AppConstants.accentGreen
                            : AppConstants.borderColor,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : AppConstants.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.background,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Text(
                  resultSummary,
                  style: TextStyle(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 6. High-Contrast Semantic Status Pill
class NexPayStatusBadge extends StatelessWidget {
  final String status;

  const NexPayStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    Color fg = AppConstants.textSecondary;
    Color bg = AppConstants.surfaceCard;

    if (s.contains('APPROV') ||
        s.contains('COMPLET') ||
        s.contains('VERIF') ||
        s.contains('ACTIVE') ||
        s.contains('SUCCESS') ||
        s.contains('DELIVER') ||
        s.contains('SETTL')) {
      fg = AppConstants.accentGreen;
      bg = AppConstants.accentGreenLight;
    } else if (s.contains('PEND') ||
        s.contains('REVIEW') ||
        s.contains('PROCESS') ||
        s.contains('DISPATCH') ||
        s.contains('OPEN')) {
      fg = AppConstants.accentGold;
      bg = AppConstants.accentGoldLight;
    } else if (s.contains('REJECT') ||
        s.contains('FAIL') ||
        s.contains('FROZEN') ||
        s.contains('BLOCK') ||
        s.contains('REVERS') ||
        s.contains('CLOS')) {
      fg = AppConstants.dangerRed;
      bg = AppConstants.dangerRedLight;
    } else if (s.contains('INFO') || s.contains('NEW') || s.contains('BUY')) {
      fg = AppConstants.accentBlue;
      bg = AppConstants.accentBlueLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            s,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 7. Stripe-Style Right Slide-Over Inspector Drawer
Future<T?> showNexPayInspectorDrawer<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Widget child,
  List<Widget> footerActions = const [],
  double width = 540,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close Inspector',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: AppConstants.surface,
          elevation: 20,
          child: Container(
            width: MediaQuery.of(ctx).size.width < width
                ? MediaQuery.of(ctx).size.width * 0.94
                : width,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.surface,
              border: Border(left: BorderSide(color: AppConstants.borderColor)),
            ),
            child: Column(
              children: [
                // Drawer Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
                  decoration: BoxDecoration(
                    color: AppConstants.surface,
                    border: Border(
                        bottom: BorderSide(color: AppConstants.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: AppConstants.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close Panel',
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded,
                            color: AppConstants.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Drawer Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
                // Drawer Sticky Footer
                if (footerActions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceCard,
                      border: Border(
                          top: BorderSide(color: AppConstants.borderColor)),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: footerActions,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

/// 8. One-Click Copyable Reference ID / IBAN Pill
class NexPayCopyableId extends StatelessWidget {
  final String text;
  final String? label;

  const NexPayCopyableId({super.key, required this.text, this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Click to copy ${label ?? text}',
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied: $text'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                width: 320,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Consolas',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.copy_rounded, size: 13, color: AppConstants.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// 9. Polished Empty State Card
class NexPayEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const NexPayEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: AppConstants.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 13,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

/// 10. Structured Inspector Detail Card & Key-Value Row
class NexPayDetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const NexPayDetailSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class NexPayKeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final Color? valueColor;

  const NexPayKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.copyable = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: TextStyle(
                color: AppConstants.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: copyable
                ? Align(
              alignment: Alignment.centerLeft,
              child: NexPayCopyableId(text: value, label: label),
            )
                : Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppConstants.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 11. Interactive Receipt / CNIC Zoom Lightbox
Future<void> showNexPayImageViewer({
  required BuildContext context,
  required String title,
  required String imageUrl,
}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppConstants.surface,
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 780,
          height: 600,
          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.zoom_in_rounded,
                        color: AppConstants.accentGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'Scroll / Pinch to Zoom',
                      style: TextStyle(
                          color: AppConstants.textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppConstants.borderColor),
              Expanded(
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stack) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Unable to load document image.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 12. Enterprise Confirmation Dialog for Critical Actions
Future<bool> showNexPayConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm Action',
  Color? confirmColor,
  IconData icon = Icons.shield_outlined,
}) async {
  final btnColor = confirmColor ?? AppConstants.accentGreen;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: btnColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: btnColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
            color: AppConstants.textSecondary, fontSize: 13.5, height: 1.5),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: btnColor),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}