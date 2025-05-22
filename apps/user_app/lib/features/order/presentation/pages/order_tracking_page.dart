import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:domain/domain.dart';

import '../bloc/order_bloc.dart';
import '../widgets/delivery_progress.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  
  // To track map markers and camera position
  Set<Marker> _markers = {};
  LatLng? _initialPosition;
  
  // For auto-refresh of tracking data
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderTrackEvent(widget.orderId));
    
    // Set up auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        context.read<OrderBloc>().add(OrderTrackEvent(widget.orderId));
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderTrackingLoaded) {
            _updateMap(state.order);
          } else if (state is OrderError && state.isTrackingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is OrderDelivered) {
            // Order has been delivered, navigate to order details
            _showDeliveredDialog(context, state.order);
          }
        },
        builder: (context, state) {
          if (state is OrderTrackingLoaded) {
            return _buildTrackingView(context, state.order);
          } else if (state is OrderLoadingTracking) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is OrderError && state.isTrackingError) {
            return _buildErrorView(context, state.message);
          }
          
          // Default loading state
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
  
  Widget _buildTrackingView(BuildContext context, Order order) {
    if (_initialPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Stack(
      children: [
        // Map view
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialPosition!,
            zoom: 15,
          ),
          markers: _markers,
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _mapController.complete(controller);
          },
        ),
        
        // Back button
        Positioned(
          top: 40,
          left: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'back_button',
            onPressed: () => context.pop(),
            backgroundColor: Colors.white,
            elevation: 2,
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        
        // Order info panel
        DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  // Order info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Estimated arrival: ${_formatEstimatedTime(order.estimatedDeliveryTime)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      AppButton(
                        text: 'Call Driver',
                        onPressed: () {
                          // Call the delivery person
                        },
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.small,
                        icon: Icons.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Delivery progress
                  DeliveryProgress(status: order.status),
                  const SizedBox(height: 24),
                  
                  // Shop info
                  AppCard(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        'https://via.placeholder.com/48', // Replace with actual shop logo
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: Theme.of(context).colorScheme.primary,
                          child: const Icon(
                            Icons.store,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    title: order.shopName,
                    subtitle: '${order.totalItems} ${order.totalItems == 1 ? 'item' : 'items'}',
                    trailing: Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const SizedBox(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Delivery address
                  AppCard(
                    leading: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    title: 'Delivery Address',
                    subtitle: order.deliveryAddress,
                    child: const SizedBox(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Delivery instructions if any
                  if (order.deliveryInstructions?.isNotEmpty ?? false)
                    AppCard(
                      leading: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: 'Delivery Instructions',
                      subtitle: order.deliveryInstructions!,
                      child: const SizedBox(),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to track order',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<OrderBloc>().add(OrderTrackEvent(widget.orderId));
              },
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _updateMap(Order order) {
    // Create markers for shop, delivery person, and delivery location
    final Set<Marker> markers = {};
    
    // Delivery location marker
    final deliveryLocation = LatLng(
      order.deliveryLatitude,
      order.deliveryLongitude,
    );
    markers.add(Marker(
      markerId: const MarkerId('delivery_location'),
      position: deliveryLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'Delivery Location',
        snippet: order.deliveryAddress,
      ),
    ));
    
    // Add delivery person marker if available
    if (order.status == OrderStatus.inDelivery) {
      // In a real app, you would get the delivery person's current location
      // For this example, we'll simulate it with a position near the delivery location
      final deliveryPersonLocation = LatLng(
        order.deliveryLatitude + 0.001, // Simulate a nearby position
        order.deliveryLongitude + 0.001,
      );
      markers.add(Marker(
        markerId: const MarkerId('delivery_person'),
        position: deliveryPersonLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Delivery Person',
          snippet: 'On the way to your location',
        ),
      ));
      
      // Set initial camera position to delivery person's location
      _initialPosition = deliveryPersonLocation;
    } else {
      // If not in delivery, focus on delivery location
      _initialPosition = deliveryLocation;
    }
    
    setState(() {
      _markers = markers;
    });
    
    // Update camera position if map controller is ready
    if (_mapController.isCompleted) {
      _mapController.future.then((controller) {
        controller.animateCamera(CameraUpdate.newLatLng(_initialPosition!));
      });
    }
  }
  
  String _formatEstimatedTime(DateTime? estimatedTime) {
    if (estimatedTime == null) {
      return 'Unknown';
    }
    
    return DateFormat('h:mm a').format(estimatedTime);
  }
  
  void _showDeliveredDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Delivered!'),
        content: const Text(
          'Your order has been delivered successfully. Enjoy your meal!',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/orders/${order.id}'); // Navigate to order details
            },
            child: const Text('View Order Details'),
          ),
        ],
      ),
    );
  }
}