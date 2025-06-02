import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatefulWidget {
  final Widget child;

  const MainPage({
    super.key,
    required this.child,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<MainNavigationItem> _navigationItems = [
    const MainNavigationItem(
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    const MainNavigationItem(
      route: '/deliveries',
      icon: Icons.delivery_dining_outlined,
      activeIcon: Icons.delivery_dining,
      label: 'Deliveries',
    ),
    const MainNavigationItem(
      route: '/earnings',
      icon: Icons.attach_money_outlined,
      activeIcon: Icons.attach_money,
      label: 'Earnings',
    ),
    const MainNavigationItem(
      route: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: _navigationItems.map((item) {
          final isSelected = _currentIndex == _navigationItems.indexOf(item);
          return BottomNavigationBarItem(
            icon: Icon(isSelected ? item.activeIcon : item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      context.go(_navigationItems[index].route);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final String location = GoRouterState.of(context).matchedLocation;
    final int newIndex = _navigationItems.indexWhere(
      (item) => location.startsWith(item.route),
    );
    
    if (newIndex != -1 && newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }
}

class MainNavigationItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const MainNavigationItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
} 