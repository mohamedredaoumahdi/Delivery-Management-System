import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  AppThemeMode _selectedTheme = AppThemeMode.system;
  
  final Map<AppThemeMode, Map<String, dynamic>> _themeOptions = {
    AppThemeMode.light: {
      'name': 'Light',
      'description': 'Clean and bright interface',
      'icon': Icons.light_mode,
      'colors': {
        'primary': Colors.blue,
        'background': Colors.white,
        'surface': Colors.grey[100],
        'text': Colors.black87,
      },
    },
    AppThemeMode.dark: {
      'name': 'Dark',
      'description': 'Easy on your eyes in low light',
      'icon': Icons.dark_mode,
      'colors': {
        'primary': Colors.blue[300],
        'background': Colors.grey[900],
        'surface': Colors.grey[800],
        'text': Colors.white,
      },
    },
    AppThemeMode.system: {
      'name': 'System',
      'description': 'Follows your device settings',
      'icon': Icons.settings_suggest,
      'colors': {
        'primary': Colors.blue,
        'background': Colors.white,
        'surface': Colors.grey[100],
        'text': Colors.black87,
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('app_theme') ?? 'system';
    setState(() {
      _selectedTheme = AppThemeMode.values.firstWhere(
        (mode) => mode.name == themeString,
        orElse: () => AppThemeMode.system,
      );
    });
  }

  Future<void> _saveThemePreference(AppThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme.name);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme changed to ${_themeOptions[theme]?['name'] ?? theme.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          
          // Theme Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildThemeOptions(context),
                const SizedBox(height: 32),
                _buildThemeNote(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
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
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.palette_outlined,
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
                  'Choose Theme',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your preferred app appearance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptions(BuildContext context) {
    return Column(
      children: AppThemeMode.values.map((themeMode) {
        final themeData = _themeOptions[themeMode]!;
        final isSelected = _selectedTheme == themeMode;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildThemeCard(
            context,
            themeMode: themeMode,
            name: themeData['name'],
            description: themeData['description'],
            icon: themeData['icon'],
            colors: themeData['colors'],
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedTheme = themeMode;
              });
              _saveThemePreference(themeMode);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required AppThemeMode themeMode,
    required String name,
    required String description,
    required IconData icon,
    required Map<String, dynamic> colors,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Theme Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.primary.withOpacity(0.7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Theme Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Theme Preview
                _buildThemePreview(context, colors),
                
                const SizedBox(width: 16),
                
                // Selection Indicator
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context, Map<String, dynamic> colors) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colors['background'],
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: colors['background'],
            ),
          ),
          
          // Top bar
          Positioned(
            top: 4,
            left: 4,
            right: 4,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                color: colors['primary'],
              ),
            ),
          ),
          
          // Content area
          Positioned(
            top: 10,
            left: 4,
            right: 4,
            bottom: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: colors['surface'],
              ),
            ),
          ),
          
          // Text lines
          Positioned(
            top: 13,
            left: 6,
            child: Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: colors['text'],
              ),
            ),
          ),
          Positioned(
            top: 17,
            left: 6,
            child: Container(
              width: 15,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: (colors['text'] as Color).withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeNote(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.primary.withOpacity(0.05),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Settings',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'System theme automatically switches between light and dark modes based on your device settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 