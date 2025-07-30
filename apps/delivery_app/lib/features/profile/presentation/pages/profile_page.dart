import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/profile_service.dart';
import '../bloc/profile_bloc.dart';
import '../../../../core/di/injection.dart';

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
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Header
                Center(
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
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        profile.email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Stats Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildStatRow(
                        theme,
                        'Vehicle Type',
                        profile.vehicleType,
                        Icons.directions_car,
                      ),
                      const Divider(),
                      _buildStatRow(
                        theme,
                        'License Number',
                        profile.licenseNumber,
                        Icons.badge,
                      ),
                      const Divider(),
                      _buildStatRow(
                        theme,
                        'Status',
                        profile.isActive ? 'Active' : 'Offline',
                        Icons.circle,
                        valueColor: profile.isActive ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Account Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implement notifications settings
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implement help & support
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: theme.colorScheme.error,
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        onTap: () {
                          print('🚪 ProfilePage: Logout button pressed');
                          _showLogoutDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildStatRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          const Spacer(),
            Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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