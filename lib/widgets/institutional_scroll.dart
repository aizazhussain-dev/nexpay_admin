import 'package:flutter/material.dart';
import '../core/constants.dart';

class InstitutionalHScroll extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const InstitutionalHScroll({
    super.key,
    required this.child,
    this.padding,
    this.physics,
  });

  @override
  State<InstitutionalHScroll> createState() => _InstitutionalHScrollState();
}

class _InstitutionalHScrollState extends State<InstitutionalHScroll> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        padding: widget.padding ?? const EdgeInsets.only(bottom: 12),
        physics: widget.physics,
        child: widget.child,
      ),
    );
  }
}

class InstitutionalVScroll extends StatefulWidget {
  final Widget child;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool? primary;
  final Clip clipBehavior;

  const InstitutionalVScroll({
    super.key,
    required this.child,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.physics,
    this.primary,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  State<InstitutionalVScroll> createState() => _InstitutionalVScrollState();
}

class _InstitutionalVScrollState extends State<InstitutionalVScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.scrollDirection == Axis.horizontal;
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: 9,
      radius: const Radius.circular(6),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: widget.scrollDirection,
        padding: widget.padding ?? (isHorizontal ? const EdgeInsets.only(bottom: 12) : null),
        physics: widget.physics,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      ),
    );
  }
}

class InstitutionalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const InstitutionalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
      decoration: BoxDecoration(
        color: AppConstants.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.surfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 26, color: AppConstants.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConstants.textMuted,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}