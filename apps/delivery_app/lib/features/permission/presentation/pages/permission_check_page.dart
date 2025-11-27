import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

/// Permission check page that appears before login
/// Checks location permission and requests it if needed
class PermissionCheckPage extends StatefulWidget {
  const PermissionCheckPage({super.key});

  @override
  State<PermissionCheckPage> createState() => _PermissionCheckPageState();
}

class _PermissionCheckPageState extends State<PermissionCheckPage> {
  bool _isChecking = true;
  bool _hasPermission = false;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    // Small delay to ensure the page is fully rendered before showing native dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermission();
    });
  }

  Future<void> _checkAndRequestPermission() async {
    print('🔐 PermissionCheckPage: Starting permission check...');
    
    // Try using geolocator first, which uses CLLocationManager directly
    // This might show the native dialog even when permission_handler doesn't
    print('🔐 PermissionCheckPage: Checking location service enabled...');
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('🔐 PermissionCheckPage: Location service enabled: $serviceEnabled');
    
    if (!serviceEnabled) {
      print('❌ PermissionCheckPage: Location service is disabled');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        _showLocationServiceDisabledDialog();
      }
      return;
    }
    
    // Check permission status using geolocator (uses CLLocationManager)
    print('🔐 PermissionCheckPage: Checking permission status with geolocator...');
    LocationPermission geolocatorPermission = await Geolocator.checkPermission();
    print('🔐 PermissionCheckPage: Geolocator permission status: $geolocatorPermission');
    
    if (geolocatorPermission == LocationPermission.always || 
        geolocatorPermission == LocationPermission.whileInUse) {
      print('✅ PermissionCheckPage: Permission already granted via geolocator');
      if (mounted) {
        setState(() {
          _hasPermission = true;
          _isChecking = false;
        });
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/login');
      }
      return;
    }
    
    if (geolocatorPermission == LocationPermission.deniedForever) {
      print('❌ PermissionCheckPage: Permission permanently denied (geolocator)');
      if (mounted) {
        setState(() {
          _isPermanentlyDenied = true;
          _isChecking = false;
        });
        _showSettingsDialog();
      }
      return;
    }
    
    // Permission is denied or not determined - request it using geolocator
    // This should show the native iOS dialog
    print('🔐 PermissionCheckPage: Requesting permission with geolocator (should show native dialog)...');
    geolocatorPermission = await Geolocator.requestPermission();
    print('🔐 PermissionCheckPage: Geolocator permission after request: $geolocatorPermission');
    
    if (geolocatorPermission == LocationPermission.always || 
        geolocatorPermission == LocationPermission.whileInUse) {
      print('✅ PermissionCheckPage: Permission granted via native dialog');
      if (mounted) {
        setState(() {
          _hasPermission = true;
          _isChecking = false;
        });
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.go('/login');
      }
    } else if (geolocatorPermission == LocationPermission.deniedForever) {
      print('❌ PermissionCheckPage: Permission permanently denied after request');
      if (mounted) {
        setState(() {
          _isPermanentlyDenied = true;
          _isChecking = false;
        });
        _showSettingsDialog();
      }
    } else {
      // Permission denied by user
      print('❌ PermissionCheckPage: Permission denied by user via native dialog');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        _showPermissionDeniedDialog();
      }
    }
  }
  
  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled on your device. Please enable them in Settings to use this app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }


  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
          'Location permission was denied. You can still use the app, but some features may not work properly.\n\n'
          'You can enable location permission later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Try requesting again (will show native dialog)
              setState(() {
                _isChecking = true;
              });
              _checkAndRequestPermission();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Allow user to proceed anyway
              context.go('/login');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    // Only show dialog if not already showing
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'The native iOS permission dialog cannot be shown because location permission was previously denied.\n\n'
          'On iOS Simulator, permissions are cached even after app reinstall.\n\n'
          'To see the native dialog:\n'
          '1. Go to Simulator menu: Device > Erase All Content and Settings\n'
          '   OR\n'
          '2. Go to Settings > General > Reset > Reset Location & Privacy\n\n'
          'To enable permission now:\n'
          '1. Tap "Open Settings" below\n'
          '2. Find "Location Services"\n'
          '3. Select "Delivery App"\n'
          '4. Choose "While Using the App" or "Always"',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Allow user to proceed anyway (they can enable later)
              context.go('/login');
            },
            child: const Text('Skip for Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final opened = await openAppSettings();
              print('📱 PermissionCheckPage: Settings opened: $opened');
              // Check permission again after returning from settings
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) {
                _checkAndRequestPermission();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Delivery Driver App',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Status message
                if (_isChecking)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'Checking permissions...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else if (_hasPermission)
                  Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Permission granted!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Location permission is required',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please grant location permission to continue',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isPermanentlyDenied
                            ? () => _showSettingsDialog()
                            : () {
                                // Request permission again
                                setState(() {
                                  _isChecking = true;
                                });
                                _checkAndRequestPermission();
                              },
                        child: Text(_isPermanentlyDenied ? 'Open Settings' : 'Grant Permission'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Skip for Now'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

