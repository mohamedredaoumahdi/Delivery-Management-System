import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:user_app/features/auth/presentation/bloc/auth_bloc.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
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

          if (state is AuthPasswordChanged) {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(context, user),
          const SizedBox(height: 40),
          
          // Account section
          _buildSectionTitle(context, 'Account'),
          _buildAccountSection(context, user),
          const SizedBox(height: 40),
          
          // Preferences section
          _buildSectionTitle(context, 'Preferences'),
          _buildPreferencesSection(context),
          const SizedBox(height: 40),
          
          // Support section
          _buildSectionTitle(context, 'Support'),
          _buildSupportSection(context),
          const SizedBox(height: 40),
          
          // App information section
          _buildSectionTitle(context, 'App'),
          _buildAppSection(context),
          const SizedBox(height: 40),
          
          // Logout button
          _buildLogoutButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.12),
            theme.colorScheme.primary.withOpacity(0.03),
            theme.colorScheme.surface,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Enhanced profile picture with glowing effect
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.3),
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  width: 3,
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
            const SizedBox(width: 24),
            
            // User info with enhanced typography
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatName(user.name),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxWidth: double.infinity),
                    child: Text(
                      user.email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  if (user.phone != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      user.phone!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Enhanced verification badges
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
                        const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
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
          icon: Icons.location_on_outlined,
          title: 'Delivery Addresses',
          subtitle: 'Manage your saved addresses',
          onTap: () => context.push('/profile/addresses'),
        ),
        _buildSettingsItem(
          context,
          icon: Icons.payment_outlined,
          title: 'Payment Methods',
          subtitle: 'Manage your payment options',
          onTap: () => context.push('/profile/payment-methods'),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      children: [
        _buildSettingsItem(
          context,
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: () => context.push('/profile/notifications'),
        ),
        _buildSettingsItem(
          context,
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'Choose your preferred language',
          trailing: 'English',
          onTap: () => context.push('/profile/language'),
        ),
        _buildSettingsItem(
          context,
          icon: Icons.dark_mode_outlined,
          title: 'Theme',
          subtitle: 'Light, dark, or system default',
          trailing: 'System',
          onTap: () => context.push('/profile/theme'),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Enhanced icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.15),
                        theme.colorScheme.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trailing,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.error.withOpacity(0.1),
            theme.colorScheme.error.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.error.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

  String _formatName(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'User';
    
    return parts.map((part) => 
      part.isEmpty ? part : part[0].toUpperCase() + part.substring(1).toLowerCase()
    ).join(' ');
  }

  String _getInitials(String name) {
    final parts = _formatName(name).trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}