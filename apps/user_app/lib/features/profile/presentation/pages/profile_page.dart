import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/profile/edit'),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            // User has been logged out, navigate to login
            context.go('/login');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AuthAuthenticated) {
            final user = state.user;
            return _buildProfileContent(context, user);
          }

          // Fallback for other states
          return const Center(
            child: Text('Please log in to view your profile'),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(context, user),
          const SizedBox(height: 32),
          
          // Account section
          _buildSectionTitle(context, 'Account'),
          const SizedBox(height: 16),
          _buildAccountSection(context, user),
          const SizedBox(height: 32),
          
          // Preferences section
          _buildSectionTitle(context, 'Preferences'),
          const SizedBox(height: 16),
          _buildPreferencesSection(context),
          const SizedBox(height: 32),
          
          // Support section
          _buildSectionTitle(context, 'Support'),
          const SizedBox(height: 16),
          _buildSupportSection(context),
          const SizedBox(height: 32),
          
          // App information section
          _buildSectionTitle(context, 'App'),
          const SizedBox(height: 16),
          _buildAppSection(context),
          const SizedBox(height: 32),
          
          // Logout button
          _buildLogoutButton(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final theme = Theme.of(context);

    return AppCard(
      contentPadding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.1),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: user.profilePicture != null
                ? ClipOval(
                    child: Image.network(
                      user.profilePicture!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(context, user),
                    ),
                  )
                : _buildDefaultAvatar(context, user),
          ),
          const SizedBox(width: 16),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (user.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.phone!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                
                // Verification badges
                Row(
                  children: [
                    if (user.isEmailVerified)
                      _buildVerificationBadge(
                        context,
                        'Email Verified',
                        Icons.verified,
                        Colors.green,
                      ),
                    if (user.isEmailVerified && user.isPhoneVerified)
                      const SizedBox(width: 8),
                    if (user.isPhoneVerified)
                      _buildVerificationBadge(
                        context,
                        'Phone Verified',
                        Icons.verified,
                        Colors.blue,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context, User user) {
    final theme = Theme.of(context);
    final initials = _getInitials(user.name);

    return Center(
      child: Text(
        initials,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, User user) {
    return Column(
      children: [
        _buildSettingsItem(
          context,
          icon: Icons.person_outline,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () => context.push('/profile/edit'),
        ),
        _buildSettingsItem(
          context,
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () => context.push('/profile/change-password'),
        ),
        _buildSettingsItem(
          context,
          icon: Icons.location_on_outline,
          title: 'Delivery Addresses',
          subtitle: 'Manage your saved addresses',
          onTap: () {
            // TODO: Navigate to addresses page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address management coming soon!'),
              ),
            );
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.payment_outlined,
          title: 'Payment Methods',
          subtitle: 'Manage your payment options',
          onTap: () {
            // TODO: Navigate to payment methods page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment methods coming soon!'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingsItem(
          context,
          icon: Icons.notifications_outline,
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: () {
            // TODO: Navigate to notification settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification settings coming soon!'),
              ),
            );
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'Choose your preferred language',
          trailing: 'English',
          onTap: () {
            // TODO: Show language picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Language selection coming soon!'),
              ),
            );
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.dark_mode_outlined,
          title: 'Theme',
          subtitle: 'Light, dark, or system default',
          trailing: 'System',
          onTap: () {
            // TODO: Show theme picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Theme selection coming soon!'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingsItem(
          context,
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'Get help and find answers',
          onTap: () {
            // TODO: Navigate to help center
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Help center coming soon!'),
              ),
            );
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.chat_outlined,
          title: 'Contact Support',
          subtitle: 'Get in touch with our team',
          onTap: () {
            // TODO: Open contact support
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact support coming soon!'),
              ),
            );
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.star_outline,
          title: 'Rate the App',
          subtitle: 'Share your feedback',
          onTap: () {
            // TODO: Open app store for rating
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('App rating coming soon!'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingsItem(
          context,
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App version and information',
          trailing: 'v1.0.0',
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          subtitle: 'Read our terms and conditions',
          onTap: () {
            // TODO: Open terms of service
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Terms of service coming soon!'),
              ),
            );
          },
        ),
        _buildSettingsItem(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Learn about our privacy practices',
          onTap: () {
            // TODO: Open privacy policy
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Privacy policy coming soon!'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      contentPadding: const EdgeInsets.all(16),
      selectable: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            Text(
              trailing,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return AppButton(
      text: 'Logout',
      onPressed: () => _showLogoutDialog(context),
      variant: AppButtonVariant.outline,
      fullWidth: true,
      icon: Icons.logout,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthLogoutEvent());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Delivery System',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.delivery_dining,
        size: 48,
        color: Colors.blue,
      ),
      children: [
        const Text('A comprehensive delivery management system for users, vendors, and delivery personnel.'),
        const SizedBox(height: 16),
        const Text('Built with Flutter and modern architecture patterns.'),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}