import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/profile_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    print('🚀 ProfilePage: initState called');
    context.read<ProfileBloc>().add(const ProfileLoadEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          print('🎨 ProfilePage: BlocBuilder triggered with state: ${state.runtimeType}');
          
          if (state is ProfileLoading) {
            print('⏳ ProfilePage: Showing loading spinner');
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
            print('❌ ProfilePage: Showing error view: ${state.message}');
            return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                    Icons.error_outline,
              size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      print('🔄 ProfilePage: Retry button pressed');
                      context.read<ProfileBloc>().add(const ProfileLoadEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            print('✅ ProfilePage: Showing profile content');
            final profile = state.profile;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          profile.name.substring(0, 1).toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                            const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Driver Information Section
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Driver Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    context,
                        'Vehicle Type',
                        profile.vehicleType,
                        Icons.directions_car,
                    theme.colorScheme.primary,
                      ),
                  const SizedBox(height: 4),
                  _buildInfoTile(
                    context,
                        'License Number',
                        profile.licenseNumber,
                        Icons.badge,
                    theme.colorScheme.primary,
                      ),
                  const SizedBox(height: 4),
                  _buildInfoTile(
                    context,
                        'Status',
                        profile.isActive ? 'Active' : 'Offline',
                        Icons.circle,
                    profile.isActive ? Colors.green : Colors.grey,
                        valueColor: profile.isActive ? Colors.green : Colors.grey,
                      ),
                  const SizedBox(height: 24),

                  // Account Settings Section
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                    children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Account Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    context,
                    'Notifications',
                    Icons.notifications_outlined,
                        onTap: () {
                      context.go('/profile/notifications');
                        },
                      ),
                  const SizedBox(height: 4),
                  _buildSettingsTile(
                    context,
                    'Help & Support',
                    Icons.help_outline,
                        onTap: () {
                      context.go('/profile/help');
                    },
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  ElevatedButton(
                    onPressed: () {
                          print('🚪 ProfilePage: Logout button pressed');
                          _showLogoutDialog(context);
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                  ),
                    ),
                    child: const Text('Sign Out'),
                ),
              ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Row(
        children: [
            Container(
              width: 40,
              height: 40,
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
          const SizedBox(width: 12),
            Expanded(
              child: Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
            ),
            Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              print('🚪 ProfilePage: Logout cancelled');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('🚪 ProfilePage: Confirming logout');
              Navigator.of(context).pop();
              context.read<ProfileBloc>().add(ProfileLogoutEvent(context));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
} 