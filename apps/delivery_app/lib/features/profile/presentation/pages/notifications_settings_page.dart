import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _newOrderNotifications = true;
  bool _orderUpdates = true;
  bool _earningsUpdates = true;
  bool _promotions = false;
  bool _systemNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _newOrderNotifications = prefs.getBool('notif_new_orders') ?? true;
      _orderUpdates = prefs.getBool('notif_order_updates') ?? true;
      _earningsUpdates = prefs.getBool('notif_earnings') ?? true;
      _promotions = prefs.getBool('notif_promotions') ?? false;
      _systemNotifications = prefs.getBool('notif_system') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notification Preferences',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationTile(
                    context,
                    'New Order Notifications',
                    'Get notified when new delivery orders are available',
                    _newOrderNotifications,
                    (value) {
                      setState(() => _newOrderNotifications = value);
                      _savePreference('notif_new_orders', value);
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildNotificationTile(
                    context,
                    'Order Updates',
                    'Receive updates about order status changes',
                    _orderUpdates,
                    (value) {
                      setState(() => _orderUpdates = value);
                      _savePreference('notif_order_updates', value);
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildNotificationTile(
                    context,
                    'Earnings Updates',
                    'Get notified about earnings and payments',
                    _earningsUpdates,
                    (value) {
                      setState(() => _earningsUpdates = value);
                      _savePreference('notif_earnings', value);
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildNotificationTile(
                    context,
                    'Promotions & Offers',
                    'Receive special offers and promotions',
                    _promotions,
                    (value) {
                      setState(() => _promotions = value);
                      _savePreference('notif_promotions', value);
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildNotificationTile(
                    context,
                    'System Notifications',
                    'Important system updates and announcements',
                    _systemNotifications,
                    (value) {
                      setState(() => _systemNotifications = value);
                      _savePreference('notif_system', value);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Save Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                // Save all preferences (they're already saved on toggle, but this confirms)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification preferences saved'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profile');
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

