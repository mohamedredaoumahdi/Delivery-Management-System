import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Notification preferences
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  
  // Order notifications
  bool _orderUpdates = true;
  bool _orderConfirmation = true;
  bool _deliveryUpdates = true;
  bool _orderCancellation = true;
  
  // Marketing notifications
  bool _promotionalOffers = true;
  bool _newShopNotifications = false;
  bool _weeklyDeals = true;
  
  // App behavior
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _notificationSound = 'Default';
  
  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _smsNotifications = prefs.getBool('sms_notifications') ?? false;
      
      _orderUpdates = prefs.getBool('order_updates') ?? true;
      _orderConfirmation = prefs.getBool('order_confirmation') ?? true;
      _deliveryUpdates = prefs.getBool('delivery_updates') ?? true;
      _orderCancellation = prefs.getBool('order_cancellation') ?? true;
      
      _promotionalOffers = prefs.getBool('promotional_offers') ?? true;
      _newShopNotifications = prefs.getBool('new_shop_notifications') ?? false;
      _weeklyDeals = prefs.getBool('weekly_deals') ?? true;
      
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _notificationSound = prefs.getString('notification_sound') ?? 'Default';
    });
  }

  Future<void> _saveNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('sms_notifications', _smsNotifications);
    
    await prefs.setBool('order_updates', _orderUpdates);
    await prefs.setBool('order_confirmation', _orderConfirmation);
    await prefs.setBool('delivery_updates', _deliveryUpdates);
    await prefs.setBool('order_cancellation', _orderCancellation);
    
    await prefs.setBool('promotional_offers', _promotionalOffers);
    await prefs.setBool('new_shop_notifications', _newShopNotifications);
    await prefs.setBool('weekly_deals', _weeklyDeals);
    
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setString('notification_sound', _notificationSound);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveNotificationPreferences,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 24),
            
            // General Notifications
            _buildSection(
              context,
              title: 'General Notifications',
              subtitle: 'Choose how you want to receive notifications',
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications on your device',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                  icon: Icons.notifications_active,
                ),
                _buildSwitchTile(
                  context,
                  title: 'Email Notifications',
                  subtitle: 'Receive notifications via email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                  icon: Icons.email_outlined,
                ),
                _buildSwitchTile(
                  context,
                  title: 'SMS Notifications',
                  subtitle: 'Receive notifications via SMS',
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() {
                      _smsNotifications = value;
                    });
                  },
                  icon: Icons.sms_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Order Notifications
            _buildSection(
              context,
              title: 'Order Notifications',
              subtitle: 'Stay updated on your order status',
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Order Updates',
                  subtitle: 'Get notified when your order status changes',
                  value: _orderUpdates,
                  onChanged: (value) {
                    setState(() {
                      _orderUpdates = value;
                    });
                  },
                  icon: Icons.shopping_bag_outlined,
                ),
                _buildSwitchTile(
                  context,
                  title: 'Order Confirmation',
                  subtitle: 'Confirm when your order is placed',
                  value: _orderConfirmation,
                  onChanged: (value) {
                    setState(() {
                      _orderConfirmation = value;
                    });
                  },
                  icon: Icons.check_circle_outline,
                ),
                _buildSwitchTile(
                  context,
                  title: 'Delivery Updates',
                  subtitle: 'Track your delivery in real-time',
                  value: _deliveryUpdates,
                  onChanged: (value) {
                    setState(() {
                      _deliveryUpdates = value;
                    });
                  },
                  icon: Icons.delivery_dining_outlined,
                ),
                _buildSwitchTile(
                  context,
                  title: 'Order Cancellation',
                  subtitle: 'Get notified if an order is cancelled',
                  value: _orderCancellation,
                  onChanged: (value) {
                    setState(() {
                      _orderCancellation = value;
                    });
                  },
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Marketing Notifications
            _buildSection(
              context,
              title: 'Marketing & Promotions',
              subtitle: 'Offers and updates from your favorite shops',
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Promotional Offers',
                  subtitle: 'Get notified about deals and discounts',
                  value: _promotionalOffers,
                  onChanged: (value) {
                    setState(() {
                      _promotionalOffers = value;
                    });
                  },
                  icon: Icons.local_offer_outlined,
                ),
                _buildSwitchTile(
                  context,
                  title: 'New Shops',
                  subtitle: 'Discover new shops in your area',
                  value: _newShopNotifications,
                  onChanged: (value) {
                    setState(() {
                      _newShopNotifications = value;
                    });
                  },
                  icon: Icons.store_outlined,
                ),
                _buildSwitchTile(
                  context,
                  title: 'Weekly Deals',
                  subtitle: 'Weekly roundup of the best deals',
                  value: _weeklyDeals,
                  onChanged: (value) {
                    setState(() {
                      _weeklyDeals = value;
                    });
                  },
                  icon: Icons.weekend_outlined,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // App Behavior
            _buildSection(
              context,
              title: 'App Behavior',
              subtitle: 'Customize notification behavior',
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                  icon: Icons.volume_up_outlined,
                ),
                _buildSwitchTile(
                  context,
                  title: 'Vibration',
                  subtitle: 'Vibrate for notifications',
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                  icon: Icons.vibration_outlined,
                ),
                _buildSoundSelector(context),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha:0.1),
            theme.colorScheme.primary.withValues(alpha:0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha:0.2),
                  theme.colorScheme.primary.withValues(alpha:0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Preferences',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize how and when you receive notifications',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha:0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha:0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha:0.1),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: theme.colorScheme.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSoundSelector(BuildContext context) {
    final theme = Theme.of(context);
    final soundOptions = ['Default', 'Bell', 'Chime', 'Ding', 'None'];
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha:0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha:0.1),
          ),
          child: Icon(
            Icons.music_note_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          'Notification Sound',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Choose notification sound',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
          ),
        ),
        trailing: DropdownButton<String>(
          value: _notificationSound,
          items: soundOptions.map((sound) {
            return DropdownMenuItem(
              value: sound,
              child: Text(sound),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _notificationSound = value;
              });
            }
          },
          underline: const SizedBox(),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
} 