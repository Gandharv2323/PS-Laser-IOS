import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/ios_design_system.dart';


// ══════════════════════════════════════════════════════════════════
// Main Shell — iOS-First Navigation (v2.0)
// ══════════════════════════════════════════════════════════════════
//
// Tab structure (iOS-native):
//   0 → /dashboard  — Today Execution Command Center
//   1 → /orders     — Order Control System
//   2 → /calendar   — Calendar Timeline
//   3 → /clients    — Client Management
//   4 → /alerts     — Notification Center
//
// Secondary tabs accessible via More / Settings:
//   /work-orders, /inventory, /machines, /attendance, etc.

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _routes = [
    '/dashboard',
    '/orders',
    '/calendar',
    '/clients',
    '/alerts',
  ];

  static const _tabs = [
    _TabItem(icon: Icons.bolt_outlined,         activeIcon: Icons.bolt,              label: 'Today'),
    _TabItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,      label: 'Orders'),
    _TabItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month,  label: 'Calendar'),
    _TabItem(icon: Icons.people_outline,        activeIcon: Icons.people,            label: 'Clients'),
    _TabItem(icon: Icons.notifications_none,    activeIcon: Icons.notifications,     label: 'Alerts'),
  ];

  void _onTabTapped(int index) {
    // Haptic feedback on iOS
    if (Platform.isIOS) {
      HapticFeedback.selectionClick();
    }
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        if (_selectedIndex != i) setState(() => _selectedIndex = i);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final location = GoRouterState.of(context).matchedLocation;
    final isMainRoute = _routes.any((r) => location.startsWith(r));

    // Hide bottom bar on AI chat (message send bar needs full space)
    final isOnAiChat = location.startsWith('/ai-chat');
    // Show FAB only on dashboard
    final isOnDashboard = location.startsWith('/dashboard');
    // Show FAB on Orders list (for add order)
    final isOnOrders = location == '/orders';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isMainRoute && location != '/dashboard') {
          context.go('/dashboard');
          setState(() => _selectedIndex = 0);
        } else if (location == '/dashboard') {
          final shouldExit = await _showExitDialog();
          if (shouldExit == true && context.mounted) {
            SystemNavigator.pop();
          }
        } else {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? PSColors.darkBg : PSColors.lightBg,
        body: widget.child,
        bottomNavigationBar: isOnAiChat ? null : _buildBottomNav(isDark),
        floatingActionButton: _buildFab(isOnDashboard, isOnOrders, location),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PSColors.darkSurface : PSColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? PSColors.darkBorder : PSColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isSelected = _selectedIndex == i;
              return Expanded(
                child: _NavItem(
                  tab: tab,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => _onTabTapped(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget? _buildFab(bool isOnDashboard, bool isOnOrders, String location) {
    if (isOnDashboard) {
      // AI assistant FAB on dashboard
      return _AnimatedFab(
        onPressed: () => context.go('/ai-chat'),
        gradient: PSColors.aiGradient,
        icon: Icons.auto_awesome_rounded,
        tooltip: 'AI Assistant',
      );
    }
    if (isOnOrders) {
      // Add order FAB
      return _AnimatedFab(
        onPressed: () => context.go('/orders/add'),
        gradient: PSColors.brandGradient,
        icon: Icons.add_rounded,
        tooltip: 'New Order',
      );
    }
    return null;
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit PS LASER?'),
        content: const Text('Are you sure you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PSColors.neonRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

// ── Individual Nav Item ───────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = PSColors.brand;
    final inactiveColor = isDark ? PSColors.textDark3 : PSColors.textLight3;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? tab.activeIcon : tab.icon,
                key: ValueKey(isSelected),
                color: isSelected ? activeColor : inactiveColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Item Data ─────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ── Animated FAB ──────────────────────────────────────────────────

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final Gradient gradient;
  final IconData icon;
  final String tooltip;

  const _AnimatedFab({
    required this.onPressed,
    required this.gradient,
    required this.icon,
    required this.tooltip,
  });

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(PSRadius.md),
              boxShadow: [
                BoxShadow(
                  color: PSColors.brand.withAlpha(102),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
