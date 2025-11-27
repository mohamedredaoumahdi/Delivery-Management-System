import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _orderNotifications = true;
  bool _promotionNotifications = true;
  bool _systemNotifications = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderNotifications = prefs.getBool('notif_order') ?? true;
      _promotionNotifications = prefs.getBool('notif_promotion') ?? true;
      _systemNotifications = prefs.getBool('notif_system') ?? true;
      _emailNotifications = prefs.getBool('notif_email') ?? true;
      _pushNotifications = prefs.getBool('notif_push') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_order', _orderNotifications);
    await prefs.setBool('notif_promotion', _promotionNotifications);
    await prefs.setBool('notif_system', _systemNotifications);
    await prefs.setBool('notif_email', _emailNotifications);
    await prefs.setBool('notif_push', _pushNotifications);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Order Notifications
            _buildNotificationTile(
              context,
              icon: Icons.shopping_bag,
              title: 'Order Notifications',
              subtitle: 'Get notified about new orders and order updates',
              iconColor: Colors.blue,
              value: _orderNotifications,
              onChanged: (value) => setState(() => _orderNotifications = value),
            ),

            const SizedBox(height: 12),

            // Promotion Notifications
            _buildNotificationTile(
              context,
              icon: Icons.local_offer,
              title: 'Promotions & Offers',
              subtitle: 'Receive notifications about special offers and promotions',
              iconColor: Colors.orange,
              value: _promotionNotifications,
              onChanged: (value) => setState(() => _promotionNotifications = value),
            ),

            const SizedBox(height: 12),

            // System Notifications
            _buildNotificationTile(
              context,
              icon: Icons.info,
              title: 'System Notifications',
              subtitle: 'Important updates and system announcements',
              iconColor: Colors.purple,
              value: _systemNotifications,
              onChanged: (value) => setState(() => _systemNotifications = value),
            ),

            const SizedBox(height: 32),

            // Delivery Methods Section
            Row(
              children: [
                Icon(
                  Icons.send,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delivery Methods',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Email Notifications
            _buildNotificationTile(
              context,
              icon: Icons.email,
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              iconColor: Colors.red,
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
            ),

            const SizedBox(height: 12),

            // Push Notifications
            _buildNotificationTile(
              context,
              icon: Icons.notifications_active,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications on your device',
              iconColor: Colors.green,
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

