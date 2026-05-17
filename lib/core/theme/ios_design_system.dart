/// iOS-first Design System for PS LASER Manufacturing OS v2.0
///
/// Inspired by: Tesla UI, Palantir Foundry, Apple Industrial, Linear, Notion
/// Design language: Dark glassmorphism + electric neon accents + SF-style precision
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════
// COLOR SYSTEM
// ═══════════════════════════════════════════════════════════════════

class PSColors {
  PSColors._();

  // ── Primary Brand ──────────────────────────────────────────────────
  static const Color brand = Color(0xFF0066FF);        // Electric blue
  static const Color brandLight = Color(0xFF3B85FF);   // Lighter electric blue
  static const Color brandDark = Color(0xFF0047CC);    // Deep blue

  // ── Neon Accents (for dark UI) ─────────────────────────────────────
  static const Color neonCyan = Color(0xFF00D4FF);     // Realtime indicators
  static const Color neonGreen = Color(0xFF00FF9D);    // Available / success
  static const Color neonOrange = Color(0xFFFF6B35);   // Warnings
  static const Color neonRed = Color(0xFFFF2D55);      // Critical / overdue
  static const Color neonPurple = Color(0xFFBF5AF2);   // AI features
  static const Color neonYellow = Color(0xFFFFD60A);   // Moderate / caution

  // ── Status Colors ──────────────────────────────────────────────────
  static const Color statusOnline = Color(0xFF30D158);
  static const Color statusWarning = Color(0xFFFF9F0A);
  static const Color statusCritical = Color(0xFFFF453A);
  static const Color statusNeutral = Color(0xFF636366);

  // ── Priority Colors ────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF30D158);
  static const Color priorityMedium = Color(0xFFFF9F0A);
  static const Color priorityHigh = Color(0xFFFF6B35);
  static const Color priorityUrgent = Color(0xFFFF2D55);

  // ── Dark Background System ─────────────────────────────────────────
  /// Primary background — almost black
  static const Color darkBg = Color(0xFF000000);
  /// Secondary background — elevated surface
  static const Color darkSurface = Color(0xFF0D0D0D);
  /// Card background
  static const Color darkCard = Color(0xFF161616);
  /// Elevated card (modal, sheet)
  static const Color darkElevated = Color(0xFF1C1C1E);
  /// Borders and separators
  static const Color darkBorder = Color(0xFF2C2C2E);
  /// Subtle border
  static const Color darkSubtleBorder = Color(0xFF1C1C1E);

  // ── Light Background System ────────────────────────────────────────
  static const Color lightBg = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5EA);

  // ── Text ───────────────────────────────────────────────────────────
  static const Color textDark1 = Color(0xFFFFFFFF);
  static const Color textDark2 = Color(0xFFAEAEB2);
  static const Color textDark3 = Color(0xFF636366);
  static const Color textLight1 = Color(0xFF000000);
  static const Color textLight2 = Color(0xFF3A3A3C);
  static const Color textLight3 = Color(0xFF8E8E93);

  // ── Glassmorphism ──────────────────────────────────────────────────
  static Color glassLight = Colors.white.withOpacity(0.08);
  static Color glassBorder = Colors.white.withOpacity(0.12);
  static Color glassDark = Colors.black.withOpacity(0.40);

  // ── Gradients ──────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient urgentGradient = LinearGradient(
    colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFFBF5AF2), Color(0xFF0066FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF0A0A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Status → Color mapping ─────────────────────────────────────────
  static Color forStatus(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED': return neonCyan;
      case 'SCHEDULED': return brand;
      case 'IN_PROGRESS': return neonOrange;
      case 'QUALITY_CHECK': return neonPurple;
      case 'COMPLETED': return neonGreen;
      case 'DELIVERED': return statusOnline;
      case 'CANCELLED': return statusNeutral;
      case 'RUNNING': return neonGreen;
      case 'PRESENT': return neonGreen;
      case 'APPROVED': return neonGreen;
      case 'PENDING': return neonYellow;
      case 'IDLE': return neonYellow;
      case 'MAINTENANCE': return neonOrange;
      case 'CRITICAL': return neonRed;
      case 'ABSENT': return neonRed;
      case 'REJECTED': return neonRed;
      default: return statusNeutral;
    }
  }

  static Color forPriority(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW': return priorityLow;
      case 'MEDIUM': return priorityMedium;
      case 'HIGH': return priorityHigh;
      case 'URGENT': return priorityUrgent;
      default: return statusNeutral;
    }
  }

  static Color bgForStatus(String status) => forStatus(status).withOpacity(0.15);
  static Color bgForPriority(String priority) => forPriority(priority).withOpacity(0.15);
}

// ═══════════════════════════════════════════════════════════════════
// TYPOGRAPHY SYSTEM
// ═══════════════════════════════════════════════════════════════════

class PSText {
  PSText._();

  // ── Display ────────────────────────────────────────────────────────
  static TextStyle display({Color? color}) => GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static TextStyle headline({Color? color}) => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static TextStyle title({Color? color}) => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.3,
  );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.3,
  );

  // ── Body ───────────────────────────────────────────────────────────
  static TextStyle body({Color? color, FontWeight? weight}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: weight ?? FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodySmall({Color? color, FontWeight? weight}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: weight ?? FontWeight.w400,
    color: color,
    height: 1.4,
  );

  // ── Label ──────────────────────────────────────────────────────────
  static TextStyle label({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: color,
    letterSpacing: 0.3,
    height: 1.2,
  );

  // ── Section header (all-caps label) ───────────────────────────────
  static TextStyle sectionHeader({Color? color}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: color ?? PSColors.textDark3,
    letterSpacing: 1.2,
  );

  // ── Number / Metric ────────────────────────────────────────────────
  static TextStyle metric({Color? color, double? fontSize}) => GoogleFonts.inter(
    fontSize: fontSize ?? 36,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: -1.0,
    height: 1.0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle metricSmall({Color? color}) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

// ═══════════════════════════════════════════════════════════════════
// SPACING SYSTEM (8-pt grid)
// ═══════════════════════════════════════════════════════════════════

class PSSpacing {
  PSSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets sectionPadding = EdgeInsets.only(bottom: 24);
}

// ═══════════════════════════════════════════════════════════════════
// BORDER RADIUS SYSTEM
// ═══════════════════════════════════════════════════════════════════

class PSRadius {
  PSRadius._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

// ═══════════════════════════════════════════════════════════════════
// GLASSMORPHISM COMPONENTS
// ═══════════════════════════════════════════════════════════════════

/// A frosted-glass container — the signature visual of this design system.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double blurStrength;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = PSRadius.md,
    this.borderColor,
    this.blurStrength = 10,
    this.backgroundColor,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? PSSpacing.cardPadding,
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isDark ? PSColors.glassLight : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ??
                  (isDark ? PSColors.glassBorder : PSColors.lightBorder),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ── Solid card (used in light mode and secondary contexts) ──────────

class PSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;

  const PSCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = PSRadius.md,
    this.onTap,
    this.color,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? PSColors.darkCard : PSColors.lightCard);

    Widget content = Container(
      padding: padding ?? PSSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
                width: 0.5,
              )
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

// ── Priority Badge ────────────────────────────────────────────────

class PSPriorityBadge extends StatelessWidget {
  final String priority;
  final bool compact;

  const PSPriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = PSColors.forPriority(priority);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(PSRadius.full),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 3 : 5),
          Text(
            priority,
            style: PSText.caption(color: color).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────

class PSStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const PSStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  static const Map<String, String> _labels = {
    'RECEIVED': 'Received',
    'SCHEDULED': 'Scheduled',
    'IN_PROGRESS': 'In Progress',
    'QUALITY_CHECK': 'Quality Check',
    'COMPLETED': 'Completed',
    'DELIVERED': 'Delivered',
    'CANCELLED': 'Cancelled',
    'RUNNING': 'Running',
    'IDLE': 'Idle',
    'PRESENT': 'Present',
    'ABSENT': 'Absent',
    'PENDING': 'Pending',
    'APPROVED': 'Approved',
    'REJECTED': 'Rejected',
  };

  @override
  Widget build(BuildContext context) {
    final color = PSColors.forStatus(status);
    final label = _labels[status] ?? status;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(PSRadius.full),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: PSText.caption(color: color).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: compact ? 10 : 11,
        ),
      ),
    );
  }
}

// ── Metric Card ───────────────────────────────────────────────────

class PSMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const PSMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? PSColors.darkCard : PSColors.lightCard,
          borderRadius: BorderRadius.circular(PSRadius.md),
          border: Border.all(
            color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? PSColors.textDark3 : PSColors.textLight3,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: PSText.metricSmall(color: color)),
            const SizedBox(height: 2),
            Text(
              label,
              style: PSText.bodySmall(
                color: isDark ? PSColors.textDark2 : PSColors.textLight2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: PSText.caption(
                  color: isDark ? PSColors.textDark3 : PSColors.textLight3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────

class PSSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const PSSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: PSText.sectionHeader(
              color: isDark ? PSColors.textDark3 : PSColors.textLight3,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: PSText.bodySmall(color: PSColors.brand).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Live Indicator (animated pulsing dot) ─────────────────────────

class PSLiveIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final String? label;

  const PSLiveIndicator({
    super.key,
    this.color = PSColors.neonGreen,
    this.size = 8,
    this.label,
  });

  @override
  State<PSLiveIndicator> createState() => _PSLiveIndicatorState();
}

class _PSLiveIndicatorState extends State<PSLiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_animation.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_animation.value * 0.5),
              blurRadius: widget.size,
              spreadRadius: widget.size * 0.3,
            ),
          ],
        ),
      ),
    );

    if (widget.label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 4),
          Text(
            widget.label!,
            style: PSText.caption(color: widget.color)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      );
    }
    return dot;
  }

}
