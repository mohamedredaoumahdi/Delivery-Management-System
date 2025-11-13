import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainWrapperPage extends StatefulWidget {
  final Widget child;
  
  const MainWrapperPage({
    super.key,
    required this.child,
  });

  @override
  State<MainWrapperPage> createState() => _MainWrapperPageState();
}

class _MainWrapperPageState extends State<MainWrapperPage> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.receipt_long,
      label: 'Orders',
      route: '/orders',
    ),
    NavigationItem(
      icon: Icons.restaurant_menu,
      label: 'Menu',
      route: '/menu',
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Analytics',
      route: '/analytics',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navigationItems.length; i++) {
      if (location.startsWith(_navigationItems[i].route)) {
        setState(() {
          _selectedIndex = i;
        });
        break;
      }
    }
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      context.go(_navigationItems[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _navigationItems.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
} 