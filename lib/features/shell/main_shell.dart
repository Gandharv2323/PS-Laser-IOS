import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static final _routes = [
    '/dashboard',
    '/work-orders',
    '/inventory',
    '/alerts',
    '/settings',
  ];

  void _onItemTapped(int index) {
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
    final isMainRoute = _routes.contains(location);

    // AI FAB: only visible on the dashboard screen
    final isOnDashboard = location == '/dashboard';
    // Bottom nav: hidden on AI chat so the message send bar has full space
    final isOnAiChat = location == '/ai-chat';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isMainRoute && location != '/dashboard') {
          context.go('/dashboard');
          setState(() => _selectedIndex = 0);
        } else if (location == '/dashboard') {
          final shouldExit = await _showExitDialog();
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        } else {
          context.pop();
        }
      },
      child: Scaffold(
        body: widget.child,
        // Hide bottom nav on AI chat — no overlap with the send bar
        bottomNavigationBar: isOnAiChat
            ? null
            : Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF2A3547)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      activeIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assignment_outlined),
                      activeIcon: Icon(Icons.assignment),
                      label: 'Orders',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2_outlined),
                      activeIcon: Icon(Icons.inventory_2),
                      label: 'Inventory',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.notifications_outlined),
                      activeIcon: Icon(Icons.notifications),
                      label: 'Alerts',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      activeIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
        // AI FAB only on Dashboard — hidden everywhere else
        floatingActionButton: isOnDashboard
            ? FloatingActionButton(
                onPressed: () => context.go('/ai-chat'),
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 4,
                tooltip: 'ForgeOps AI',
                child: const Icon(Icons.smart_toy_outlined),
              )
            : null,
      ),
    );
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit PS Laser'),
        content: const Text('Are you sure you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
