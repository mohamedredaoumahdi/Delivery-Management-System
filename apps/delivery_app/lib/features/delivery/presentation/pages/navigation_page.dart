import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../bloc/delivery_bloc.dart';

class NavigationPage extends StatefulWidget {
  final String deliveryId;

  const NavigationPage({
    super.key,
    required this.deliveryId,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  bool _showFullscreenMap = false;
  
  // Mock delivery and location data
  final LatLng _restaurantLocation = const LatLng(37.7749, -122.4194); // San Francisco
  final LatLng _customerLocation = const LatLng(37.7849, -122.4094); // Customer location
  LatLng _currentLocation = const LatLng(37.7649, -122.4294); // Driver starting location
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Delivery state
  DeliveryStatus _currentStatus = DeliveryStatus.accepted;
  bool _isAtRestaurant = false;
  bool _isAtCustomer = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeMap() {
    _updateMarkers();
    _createRoute();
  }

  void _updateMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('restaurant'),
        position: _restaurantLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Golden Dragon Restaurant',
          snippet: 'Pickup Location',
        ),
      ),
      Marker(
        markerId: const MarkerId('customer'),
        position: _customerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'John Doe',
          snippet: 'Delivery Location',
        ),
      ),
      Marker(
        markerId: const MarkerId('driver'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Driver Position',
        ),
      ),
    };
  }

  void _createRoute() {
    // Simple route - in real app, use Google Directions API
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_currentLocation, _restaurantLocation, _customerLocation],
        color: Colors.blue,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  void _startLocationTracking() {
    // Mock location updates - in real app, use Geolocator.getPositionStream()
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Simulate movement towards target
          if (_currentStatus == DeliveryStatus.accepted || _currentStatus == DeliveryStatus.pickedUp) {
            final target = _currentStatus == DeliveryStatus.accepted 
                ? _restaurantLocation 
                : _customerLocation;
            
            // Move slightly towards target
            final deltaLat = (target.latitude - _currentLocation.latitude) * 0.1;
            final deltaLng = (target.longitude - _currentLocation.longitude) * 0.1;
            
            _currentLocation = LatLng(
              _currentLocation.latitude + deltaLat,
              _currentLocation.longitude + deltaLng,
            );
            
            _updateMarkers();
            _checkProximity();
          }
        });
      }
    });
  }

  void _checkProximity() {
    const double proximityThreshold = 0.002; // ~200 meters
    
    // Check if at restaurant
    final distanceToRestaurant = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      _restaurantLocation.latitude,
      _restaurantLocation.longitude,
    );
    
    // Check if at customer
    final distanceToCustomer = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      _customerLocation.latitude,
      _customerLocation.longitude,
    );
    
    if (distanceToRestaurant < 200 && !_isAtRestaurant && _currentStatus == DeliveryStatus.accepted) {
      _isAtRestaurant = true;
      _showArrivalDialog('restaurant');
    }
    
    if (distanceToCustomer < 200 && !_isAtCustomer && _currentStatus == DeliveryStatus.inTransit) {
      _isAtCustomer = true;
      _showArrivalDialog('customer');
    }
  }

  void _showArrivalDialog(String location) {
    final isRestaurant = location == 'restaurant';
    final title = isRestaurant ? 'Arrived at Restaurant' : 'Arrived at Customer';
    final message = isRestaurant 
        ? 'You have arrived at the pickup location. Please collect the order.'
        : 'You have arrived at the delivery location. Please deliver the order.';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (isRestaurant) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateDeliveryStatus(DeliveryStatus.pickedUp);
              },
              child: const Text('Mark as Picked Up'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Yet'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeliveryConfirmation();
              },
              child: const Text('Delivered'),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeliveryConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please confirm that the order has been delivered successfully.'),
            SizedBox(height: 16),
            Text('Would you like to take a photo as proof of delivery?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateDeliveryStatus(DeliveryStatus.delivered);
            },
            child: const Text('Skip Photo'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _takeDeliveryPhoto();
            },
            child: const Text('Take Photo'),
          ),
        ],
      ),
    );
  }

  void _takeDeliveryPhoto() {
    // This would integrate with camera in real app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera feature will be implemented next!'),
        backgroundColor: Colors.blue,
      ),
    );
    _updateDeliveryStatus(DeliveryStatus.delivered);
  }

  void _updateDeliveryStatus(DeliveryStatus status) {
    setState(() {
      _currentStatus = status;
    });
    
    context.read<DeliveryBloc>().add(DeliveryUpdateStatusEvent(status));
    
    if (status == DeliveryStatus.delivered) {
      _showDeliveryCompleteDialog();
    }
  }

  void _showDeliveryCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Delivery Complete!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Congratulations! You have successfully completed this delivery.'),
            SizedBox(height: 16),
            Text('Earnings: \$8.47'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showFullscreenMap ? null : _buildAppBar(),
      body: _showFullscreenMap ? _buildFullscreenMap() : _buildNavigationView(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Order #${widget.deliveryId}'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.fullscreen),
          onPressed: () {
            setState(() {
              _showFullscreenMap = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: _callCustomer,
        ),
      ],
    );
  }

  Widget _buildNavigationView() {
    return Column(
      children: [
        // Status Bar
        _buildStatusBar(),
        
        // Map Container
        Expanded(
          flex: 2,
          child: _buildMapView(),
        ),
        
        // Navigation Controls
        _buildNavigationControls(),
      ],
    );
  }

  Widget _buildFullscreenMap() {
    return Stack(
      children: [
        _buildMapView(),
        Positioned(
          top: 50,
          left: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                _showFullscreenMap = false;
              });
            },
            child: const Icon(Icons.fullscreen_exit),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: _buildQuickControls(),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(_currentStatus);
    final statusText = _getStatusText(_currentStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: statusColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(_currentStatus),
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusDescription(_currentStatus),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // Center on current location
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                [_restaurantLocation.latitude, _customerLocation.latitude, _currentLocation.latitude].reduce((a, b) => a < b ? a : b) - 0.01,
                [_restaurantLocation.longitude, _customerLocation.longitude, _currentLocation.longitude].reduce((a, b) => a < b ? a : b) - 0.01,
              ),
              northeast: LatLng(
                [_restaurantLocation.latitude, _customerLocation.latitude, _currentLocation.latitude].reduce((a, b) => a > b ? a : b) + 0.01,
                [_restaurantLocation.longitude, _customerLocation.longitude, _currentLocation.longitude].reduce((a, b) => a > b ? a : b) + 0.01,
              ),
            ),
            100,
          ),
        );
      },
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: 14,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
      trafficEnabled: true,
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Distance and ETA
          _buildDistanceInfo(),
          const SizedBox(height: 16),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildQuickControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickActionButton(Icons.phone, 'Call', _callCustomer),
            _buildQuickActionButton(Icons.message, 'Message', _messageCustomer),
            _buildQuickActionButton(Icons.navigation, 'Directions', _openExternalNavigation),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildDistanceInfo() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2.3 km',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Distance',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.access_time,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '12 min',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ETA',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: Column(
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$8.47',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Earnings',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_currentStatus) {
      case DeliveryStatus.accepted:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateDeliveryStatus(DeliveryStatus.pickedUp),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Picked Up'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openExternalNavigation,
                icon: const Icon(Icons.navigation),
                label: const Text('Open in Maps'),
              ),
            ),
          ],
        );
      
      case DeliveryStatus.pickedUp:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateDeliveryStatus(DeliveryStatus.inTransit),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Start Delivery'),
          ),
        );
      
      case DeliveryStatus.inTransit:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showDeliveryConfirmation,
                icon: const Icon(Icons.done_all),
                label: const Text('Mark as Delivered'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _callCustomer,
                    child: const Text('Call Customer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _messageCustomer,
                    child: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          mini: true,
          onPressed: () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_currentLocation),
            );
          },
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.accepted:
        return Colors.blue;
      case DeliveryStatus.pickedUp:
        return Colors.purple;
      case DeliveryStatus.inTransit:
        return Colors.orange;
      case DeliveryStatus.delivered:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.accepted:
        return Icons.restaurant;
      case DeliveryStatus.pickedUp:
        return Icons.inventory;
      case DeliveryStatus.inTransit:
        return Icons.local_shipping;
      case DeliveryStatus.delivered:
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.accepted:
        return 'Heading to Restaurant';
      case DeliveryStatus.pickedUp:
        return 'Order Picked Up';
      case DeliveryStatus.inTransit:
        return 'Delivering to Customer';
      case DeliveryStatus.delivered:
        return 'Delivery Complete';
      default:
        return 'Unknown Status';
    }
  }

  String _getStatusDescription(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.accepted:
        return 'Navigate to Golden Dragon Restaurant';
      case DeliveryStatus.pickedUp:
        return 'Ready to start delivery';
      case DeliveryStatus.inTransit:
        return 'Navigate to customer location';
      case DeliveryStatus.delivered:
        return 'Order successfully delivered';
      default:
        return '';
    }
  }

  void _callCustomer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+15551234567');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _messageCustomer() async {
    final Uri smsUri = Uri(scheme: 'sms', path: '+15551234567');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  void _openExternalNavigation() async {
    final target = _currentStatus == DeliveryStatus.accepted 
        ? _restaurantLocation 
        : _customerLocation;
    
    final Uri mapsUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/dir/',
      queryParameters: {
        'api': '1',
        'destination': '${target.latitude},${target.longitude}',
      },
    );
    
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    }
  }
} 