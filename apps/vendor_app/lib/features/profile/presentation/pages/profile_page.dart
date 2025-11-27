import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/profile_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';

class ProfilePage extends StatefulWidget {
  final Function(int)? navigateToTab;
  
  const ProfilePage({super.key, this.navigateToTab});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Function(int)? get _navigateToTab => widget.navigateToTab;

  @override
  void initState() {
    super.initState();
    // Load profile when page initializes
    context.read<ProfileBloc>().add(LoadProfile());
  }

  String _toAbsoluteImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Backend serves static files at http://localhost:3000/uploads/...
    if (url.startsWith('/')) {
      return 'http://localhost:3000$url';
    }
    return 'http://localhost:3000/$url';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Navigate to login page when user logs out
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading profile',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProfileBloc>().add(LoadProfile());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ProfileBloc>().add(LoadProfile());
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Header
                      _buildProfileHeader(state.user),
                      
                      const SizedBox(height: 20),
                      
                      // Business Information
                      _buildBusinessInfoSection(state.user),
                      
                      const SizedBox(height: 20),
                      
                      // Account Settings
                      _buildAccountSettingsSection(),
                      
                      const SizedBox(height: 20),
                      
                      // Help & Support
                      _buildHelpSupportSection(),
                      
                      const SizedBox(height: 20),
                      
                      // Logout Button
                      _buildLogoutButton(),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            }

            return const Center(
              child: Text('No profile data available'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
    // Try to get shop logo from dashboard state
    String? logoUrl;
    final dashboardState = context.read<DashboardBloc>().state;
    if (dashboardState is DashboardLoaded) {
      final shop = dashboardState.dashboardData;
      final dynamic rawLogo = shop['logoUrl'] ?? shop['logo_url'];
      if (rawLogo is String && rawLogo.isNotEmpty) {
        logoUrl = rawLogo;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile / Shop Image
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: logoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _toAbsoluteImageUrl(logoUrl),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.store,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.store,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Business Name or User Name
            Text(
              user['businessName'] ?? user['name'] ?? 'Your Business',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Owner Name (only show if different from business name)
            if (user['businessName'] != null && user['name'] != null)
              Text(
                'Owner: ${user['name']}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            
            if (user['businessName'] != null && user['name'] != null)
              const SizedBox(height: 4),
            
            // Email
            Text(
              user['email'] ?? 'No email provided',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status Badge - Show account status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getAccountStatusColor(user),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getAccountStatusText(user),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoSection(Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.business_center,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Business Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Separate tiles for each info item
        _buildInfoTile(
          context,
          icon: Icons.person,
          label: 'Name',
          value: user['name'] ?? 'Not provided',
          iconColor: Colors.blue,
        ),
        _buildInfoTile(
          context,
          icon: Icons.email,
          label: 'Email',
          value: user['email'] ?? 'Not provided',
          iconColor: Colors.orange,
        ),
        if (user['phone'] != null)
          _buildInfoTile(
            context,
            icon: Icons.phone,
            label: 'Phone',
            value: user['phone'],
            iconColor: Colors.green,
          ),
        _buildInfoTile(
          context,
          icon: Icons.verified_user,
          label: 'Account Status',
          value: user['isActive'] == true ? 'Active' : 'Inactive',
          iconColor: user['isActive'] == true ? Colors.green : Colors.red,
        ),
        _buildInfoTile(
          context,
          icon: Icons.email_outlined,
          label: 'Email Verified',
          value: user['isEmailVerified'] == true ? 'Yes' : 'No',
          iconColor: user['isEmailVerified'] == true ? Colors.green : Colors.grey,
        ),
        if (user['phone'] != null)
          _buildInfoTile(
            context,
            icon: Icons.phone_android,
            label: 'Phone Verified',
            value: user['isPhoneVerified'] == true ? 'Yes' : 'No',
            iconColor: user['isPhoneVerified'] == true ? Colors.green : Colors.grey,
          ),
        if (user['lastLoginAt'] != null)
          _buildInfoTile(
            context,
            icon: Icons.access_time,
            label: 'Last Login',
            value: _formatDate(user['lastLoginAt']),
            iconColor: Colors.purple,
          ),
        _buildInfoTile(
          context,
          icon: Icons.calendar_today,
          label: 'Member Since',
          value: _formatDate(user['createdAt']),
          iconColor: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final row = _buildInfoRow(icon, label, value, iconColor: iconColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: row,
        ),
      ),
    );
  }

  Widget _buildAccountSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Account Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Separate tiles for each setting
        _buildSettingsTile(
          context,
          icon: Icons.edit,
          title: 'Edit Profile',
          subtitle: 'Update your business information',
          iconColor: Colors.blue,
          onTap: () => _showEditProfileDialog(),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          iconColor: Colors.orange,
          onTap: () => _showNotificationSettings(),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.payment,
          title: 'Payment Settings',
          subtitle: 'Manage payment methods and payouts',
          iconColor: Colors.green,
          onTap: () => _showPaymentSettings(),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.security,
          title: 'Security',
          subtitle: 'Change password and security settings',
          iconColor: Colors.red,
          onTap: () => _showSecuritySettings(),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.help,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Help & Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSettingsTile(
          context,
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'Get help with common questions',
          iconColor: Colors.blue,
          onTap: () => _showHelpCenter(),
        ),
        const SizedBox(height: 4),
        _buildSettingsTile(
          context,
          icon: Icons.support_agent,
          title: 'Contact Support',
          subtitle: 'Reach out to our support team',
          iconColor: Colors.orange,
          onTap: () => _contactSupport(),
        ),
        const SizedBox(height: 4),
        _buildSettingsTile(
          context,
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App version and information',
          iconColor: Colors.purple,
          onTap: () => _showAboutDialog(),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () => _showLogoutConfirmation(),
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text(
        'Sign Out',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? iconColor}) {
    final effectiveIconColor = iconColor ?? Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: effectiveIconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: effectiveIconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAccountStatusColor(Map<String, dynamic> user) {
    if (user['isActive'] == true) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  String _getAccountStatusText(Map<String, dynamic> user) {
    if (user['isActive'] == true) {
      return 'Active Account';
    } else {
      return 'Account Pending';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not available';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showEditProfileDialog() {
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      context.push('/edit-profile', extra: state.user);
    }
  }

  void _showNotificationSettings() {
    context.push('/notifications-settings');
  }

  void _showPaymentSettings() {
    context.push('/payment-settings');
  }

  void _showSecuritySettings() {
    context.push('/security-settings');
  }

  void _showHelpCenter() {
    context.push('/help-center');
  }

  void _contactSupport() {
    context.push('/contact-support');
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vendor App'),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('Built with Flutter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
} 