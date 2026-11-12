import 'package:flutter/material.dart';
import '../core/constants.dart';

/// 1. Full-Screen Desk Canvas with Guaranteed Right-Edge Vertical Scrollbar
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

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2. Full-Width Data Table with Permanent Bottom Horizontal Scrollbar
class NexPayFullWidthTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget? emptyState;
  final double minTableWidth;

  const NexPayFullWidthTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyState,
    this.minTableWidth = 980,
  });

  @override
  State<NexPayFullWidthTable> createState() => _NexPayFullWidthTableState();
}

class _NexPayFullWidthTableState extends State<NexPayFullWidthTable> {
  final ScrollController _horizontalController = ScrollController();

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final targetWidth = constraints.maxWidth > widget.minTableWidth
                ? constraints.maxWidth
                : widget.minTableWidth;

            return Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 10,
              radius: const Radius.circular(6),
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                primary: false,
                padding: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: targetWidth),
                  child: DataTable(
                    headingRowHeight: 46,
                    dataRowMinHeight: 54,
                    dataRowMaxHeight: 68,
                    horizontalMargin: 20,
                    columnSpacing: 24,
                    headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
                    dividerThickness: 1,
                    columns: widget.columns,
                    rows: widget.rows,
                  ),
                ),
              ),
            );
          },
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
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
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
                          style: const TextStyle(
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
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.sublabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
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
              style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppConstants.textMuted),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppConstants.bgDark : AppConstants.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active ? AppConstants.bgDark : AppConstants.borderColor,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: active ? Colors.white : AppConstants.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                resultSummary,
                style: const TextStyle(
                  color: AppConstants.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        s,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
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
  double width = 520,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close Inspector',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: AppConstants.surface,
          elevation: 16,
          child: SizedBox(
            width: MediaQuery.of(ctx).size.width < width
                ? MediaQuery.of(ctx).size.width * 0.94
                : width,
            height: double.infinity,
            child: Column(
              children: [
                // Drawer Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
                  decoration: const BoxDecoration(
                    color: AppConstants.surface,
                    border: Border(bottom: BorderSide(color: AppConstants.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: AppConstants.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: AppConstants.textSecondary),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppConstants.surfaceCard,
                      border: Border(top: BorderSide(color: AppConstants.borderColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: footerActions,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}