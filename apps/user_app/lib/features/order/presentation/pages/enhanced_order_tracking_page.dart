import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:domain/domain.dart';

import '../bloc/order_bloc.dart';
import '../bloc/realtime_order_bloc.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/delivery_tracker.dart';

class EnhancedOrderTrackingPage extends StatefulWidget {
  final String orderId;

  const EnhancedOrderTrackingPage({
    super.key,
    required this.orderId,
  });

  @override
  State<EnhancedOrderTrackingPage> createState() => _EnhancedOrderTrackingPageState();
}

class _EnhancedOrderTrackingPageState extends State<EnhancedOrderTrackingPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    
    // Load order details
    context.read<OrderBloc>().add(OrderLoadDetailsEvent(widget.orderId));
    
    // Connect to real-time updates
    _connectToRealtimeUpdates();
  }

  void _connectToRealtimeUpdates() {
    // This would get the current user ID from auth state
    final userId = "current-user-id"; // Replace with actual user ID
    context.read<RealtimeOrderBloc>().add(RealtimeOrderConnect(userId: userId));
    
    // Subscribe to this specific order
    context.read<RealtimeOrderBloc>().add(RealtimeOrderSubscribe(widget.orderId));
  }

  @override
  void dispose() {
    // Unsubscribe from order updates
    context.read<RealtimeOrderBloc>().add(RealtimeOrderUnsubscribe(widget.orderId));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OrderBloc>().add(OrderLoadDetailsEvent(widget.orderId));
            },
          ),
        ],
      ),
            body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderDetailsLoaded) {
            _updateMapMarkers(state.order);
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: BlocListener<RealtimeOrderBloc, RealtimeOrderState>(
          listener: (context, state) {
            if (state is RealtimeOrderUpdate) {
              _handleRealtimeUpdate(state);
            } else if (state is RealtimeOrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Real-time connection error: ${state.message}'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          child: BlocBuilder<OrderBloc, OrderState>(
            builder: (context, orderState) {
              if (orderState is OrderLoadingDetails) {
                return const Center(child: CircularProgressIndicator());
              } else if (orderState is OrderDetailsLoaded) {
                return _buildTrackingContent(context, orderState.order);
              } else if (orderState is OrderError) {
                return _buildErrorContent(context, orderState.message);
              } else {
                return const Center(child: Text('No order data available'));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingContent(BuildContext context, Order order) {
    return Column(
      children: [
        // Order Summary Card
        _buildOrderSummaryCard(context, order),
        
        // Map Section
        Expanded(
          flex: 2,
          child: _buildMapSection(context, order),
        ),
        
        // Status Timeline
        Expanded(
          flex: 1,
          child: OrderStatusTimeline(order: order),
        ),
        
        // Delivery Tracker
        if (order.status == OrderStatus.inDelivery || order.status == OrderStatus.delivered)
          DeliveryTracker(order: order),
      ],
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, Order order) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.shopName}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Total: \$${order.total.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (order.estimatedDeliveryTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Estimated delivery: ${_formatEstimatedTime(order.estimatedDeliveryTime!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context, Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              order.deliveryLatitude,
              order.deliveryLongitude,
            ),
            zoom: 15,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.accepted:
        color = Colors.blue;
        text = 'Accepted';
        break;
      case OrderStatus.preparing:
        color = Colors.purple;
        text = 'Preparing';
        break;
      case OrderStatus.readyForPickup:
        color = Colors.indigo;
        text = 'Ready';
        break;
      case OrderStatus.inDelivery:
        color = Colors.green;
        text = 'In Delivery';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String message) {
    return Center(
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
            'Error loading order',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<OrderBloc>().add(OrderLoadDetailsEvent(widget.orderId));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _updateMapMarkers(Order order) {
    final markers = <Marker>{};
    
    // Shop marker
    markers.add(
      Marker(
        markerId: const MarkerId('shop'),
        position: LatLng(
          0, // TODO: Get shop coordinates from shopId
          0,
        ),
        infoWindow: InfoWindow(
          title: order.shopName,
          snippet: 'Pickup location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    
    // Delivery location marker
    markers.add(
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(
          order.deliveryLatitude,
          order.deliveryLongitude,
        ),
        infoWindow: InfoWindow(
          title: 'Delivery Location',
          snippet: order.deliveryAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    
    // Delivery person marker (if available)
    if (order.deliveryPersonId != null) {
      // This would be updated with real delivery person location
      markers.add(
        Marker(
          markerId: const MarkerId('delivery_person'),
          position: LatLng(
            order.deliveryLatitude + 0.001, // Offset for demo
            order.deliveryLongitude + 0.001,
          ),
          infoWindow: const InfoWindow(
            title: 'Delivery Person',
            snippet: 'On the way',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
    
    // Update camera position to show all markers
    _fitBounds();
  }

  void _fitBounds() {
    if (_markers.isEmpty || _mapController == null) return;
    
    final bounds = _calculateBounds();
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  LatLngBounds _calculateBounds() {
    double? minLat, maxLat, minLng, maxLng;
    
    for (final marker in _markers) {
      final position = marker.position;
      minLat = minLat == null ? position.latitude : min(minLat, position.latitude);
      maxLat = maxLat == null ? position.latitude : max(maxLat, position.latitude);
      minLng = minLng == null ? position.longitude : min(minLng, position.longitude);
      maxLng = maxLng == null ? position.longitude : max(maxLng, position.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _handleRealtimeUpdate(RealtimeOrderUpdate update) {
    // Update the order in the bloc
    context.read<OrderBloc>().add(OrderLoadDetailsEvent(widget.orderId));
    
    // Show notification based on update type
    final message = _getUpdateMessage(update.updateType, update.order);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String _getUpdateMessage(String updateType, Order order) {
    switch (updateType) {
      case 'status':
        return 'Order status updated: ${order.status.name}';
      case 'delivery':
        return 'Delivery update received';
      case 'general':
        return 'Order updated';
      default:
        return 'Order update received';
    }
  }

  String _formatEstimatedTime(DateTime estimatedTime) {
    final now = DateTime.now();
    final difference = estimatedTime.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '$hours hours $minutes minutes';
    }
  }
}
