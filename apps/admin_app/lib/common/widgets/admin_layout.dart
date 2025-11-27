import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

class AdminLayout extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final bool showAppBar;

  const AdminLayout({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.showAppBar = true,
  });

  void _showLogoutConfirmation(BuildContext context, bool useDrawer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 12),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to access the admin panel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Close drawer if open
              if (useDrawer) {
                Navigator.of(context).pop();
              }
              // Redirect to login immediately to prevent API calls
              context.go('/login');
              // Then clear tokens
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;
    final isTablet = screenWidth > 800 && screenWidth <= 1200;
    final useDrawer = isMobile || isTablet;
    final sidebarWidth = isMobile ? 240.0 : 260.0;
    
    Widget buildSidebar() {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      
      return Container(
        width: sidebarWidth,
        color: isDark ? theme.colorScheme.surface : Colors.grey[50],
        child: Column(
          children: [
            // Header
            Container(
              height: 64,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: isMobile ? 28 : 32,
                    color: Colors.white,
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Flexible(
                    child: Text(
                      'Admin Panel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 14 : null,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Navigation Items
            Expanded(
              child: Builder(
                builder: (context) {
                  final location = GoRouterState.of(context).matchedLocation;
                  return ListView(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
                    children: [
                      _NavItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        isSelected: location == '/dashboard',
                        onTap: () {
                          context.go('/dashboard');
                          if (useDrawer) Navigator.of(context).pop();
                        },
                        isMobile: isMobile,
                      ),
                      _NavItem(
                        icon: Icons.people,
                        title: 'Users',
                        isSelected: location.startsWith('/users'),
                        onTap: () {
                          context.go('/users');
                          if (useDrawer) Navigator.of(context).pop();
                        },
                        isMobile: isMobile,
                      ),
                      _NavItem(
                        icon: Icons.store,
                        title: 'Shops',
                        isSelected: location.startsWith('/shops'),
                        onTap: () {
                          context.go('/shops');
                          if (useDrawer) Navigator.of(context).pop();
                        },
                        isMobile: isMobile,
                      ),
                      _NavItem(
                        icon: Icons.shopping_cart,
                        title: 'Orders',
                        isSelected: location.startsWith('/orders'),
                        onTap: () {
                          context.go('/orders');
                          if (useDrawer) Navigator.of(context).pop();
                        },
                        isMobile: isMobile,
                      ),
                      _ExpandableNavItem(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        isSelected: location.startsWith('/analytics'),
                        isMobile: isMobile,
                        children: [
                          _NavItem(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Orders Analytics',
                            isSelected: location == '/analytics/orders',
                            onTap: () {
                              context.go('/analytics/orders');
                              if (useDrawer) Navigator.of(context).pop();
                            },
                            isMobile: isMobile,
                            isSubItem: true,
                          ),
                          _NavItem(
                            icon: Icons.attach_money,
                            title: 'Revenue Analytics',
                            isSelected: location == '/analytics/revenue',
                            onTap: () {
                              context.go('/analytics/revenue');
                              if (useDrawer) Navigator.of(context).pop();
                            },
                            isMobile: isMobile,
                            isSubItem: true,
                          ),
                          _NavItem(
                            icon: Icons.store_outlined,
                            title: 'Vendor Analytics',
                            isSelected: location == '/analytics/vendors',
                            onTap: () {
                              context.go('/analytics/vendors');
                              if (useDrawer) Navigator.of(context).pop();
                            },
                            isMobile: isMobile,
                            isSubItem: true,
                          ),
                          _NavItem(
                            icon: Icons.local_shipping,
                            title: 'Delivery Analytics',
                            isSelected: location == '/analytics/delivery',
                            onTap: () {
                              context.go('/analytics/delivery');
                              if (useDrawer) Navigator.of(context).pop();
                            },
                            isMobile: isMobile,
                            isSubItem: true,
                          ),
                          _NavItem(
                            icon: Icons.people_outline,
                            title: 'Customer Analytics',
                            isSelected: location == '/analytics/customers',
                            onTap: () {
                              context.go('/analytics/customers');
                              if (useDrawer) Navigator.of(context).pop();
                            },
                            isMobile: isMobile,
                            isSubItem: true,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            // Logout Button
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              child: _NavItem(
                icon: Icons.logout,
                title: 'Logout',
                isSelected: false,
                onTap: () => _showLogoutConfirmation(context, useDrawer),
                isLogout: true,
                isMobile: isMobile,
              ),
            ),
          ],
        ),
      );
    }
    
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: useDrawer
                  ? Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    )
                  : null,
              title: title != null ? Text(title!) : null,
              actions: [
                ...?actions,
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    if (value == 'logout') {
                      _showLogoutConfirmation(context, useDrawer);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : useDrawer
              ? AppBar(
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  actions: [
                    ...?actions,
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.account_circle),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _showLogoutConfirmation(context, useDrawer);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : null,
      drawer: useDrawer ? buildSidebar() : null,
      body: useDrawer
          ? Align(
              alignment: Alignment.topLeft,
              child: body,
            )
          : Row(
              children: [
                // Fixed Sidebar for Desktop
                buildSidebar(),
                // Main Content
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: body,
                  ),
                ),
              ],
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLogout;
  final bool isMobile;
  final bool isSubItem;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.isLogout = false,
    this.isMobile = false,
    this.isSubItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(
        left: isSubItem ? (isMobile ? 24 : 32) : (isMobile ? 6 : 8),
        right: isMobile ? 6 : 8,
        top: isMobile ? 3 : 4,
        bottom: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        dense: isMobile,
        leading: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.primary
              : (isLogout 
                  ? Colors.red 
                  : (isDark ? Colors.grey[400] : Colors.grey[700])),
          size: isMobile ? 20 : 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : (isLogout 
                    ? Colors.red 
                    : (isDark ? Colors.grey[300] : Colors.grey[800])),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
        selected: isSelected,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ExpandableNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool isMobile;
  final List<Widget> children;

  const _ExpandableNavItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.isMobile,
    required this.children,
  });

  @override
  State<_ExpandableNavItem> createState() => _ExpandableNavItemState();
}

class _ExpandableNavItemState extends State<_ExpandableNavItem> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand if any child is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/analytics/')) {
        setState(() {
          _isExpanded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 6 : 8,
            vertical: widget.isMobile ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: ListTile(
            dense: widget.isMobile,
            leading: Icon(
              widget.icon,
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
              size: widget.isMobile ? 20 : 22,
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                color: widget.isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey[300] : Colors.grey[800]),
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: widget.isMobile ? 13 : 14,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
              size: widget.isMobile ? 18 : 20,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_isExpanded) ...widget.children,
      ],
    );
  }
}

