import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';

import '../bloc/payment_method_bloc.dart';
import '../bloc/payment_method_event.dart';
import '../bloc/payment_method_state.dart';
import '../widgets/payment_method_list_item.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  @override
  void initState() {
    super.initState();
    // Load payment methods when page initializes
    context.read<PaymentMethodBloc>().add(const PaymentMethodLoadEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddPaymentMethod(),
          ),
        ],
      ),
      body: BlocConsumer<PaymentMethodBloc, PaymentMethodState>(
        listener: (context, state) {
          if (state is PaymentMethodCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment method added successfully')),
            );
            _loadPaymentMethods();
          } else if (state is PaymentMethodUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment method updated successfully')),
            );
            _loadPaymentMethods();
          } else if (state is PaymentMethodDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment method deleted successfully')),
            );
            _loadPaymentMethods();
          } else if (state is PaymentMethodDefaultSet) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Default payment method updated')),
            );
            _loadPaymentMethods();
          } else if (state is PaymentMethodError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentMethodLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is PaymentMethodError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load payment methods',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadPaymentMethods,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is PaymentMethodLoaded) {
            if (state.paymentMethods.isEmpty) {
              return _buildEmptyState();
            }
            
            return RefreshIndicator(
              onRefresh: () async => _loadPaymentMethods(),
              child: ListView.builder(
                itemCount: state.paymentMethods.length,
                itemBuilder: (context, index) {
                  final paymentMethod = state.paymentMethods[index];
                  return PaymentMethodListItem(
                    paymentMethod: paymentMethod,
                    onEdit: () => _navigateToEditPaymentMethod(paymentMethod),
                    onDelete: () => _showDeleteConfirmation(paymentMethod),
                    onSetDefault: () => _setDefaultPaymentMethod(paymentMethod.id),
                  );
                },
              ),
            );
          }
          
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No Payment Methods',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first payment method to make checkout faster and easier.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _loadPaymentMethods() {
    context.read<PaymentMethodBloc>().add(const PaymentMethodLoadEvent());
  }

  Future<void> _navigateToAddPaymentMethod() async {
    final result = await context.push('/profile/payment-methods/add');
    if (result == true) {
      _loadPaymentMethods();
    }
  }

  Future<void> _navigateToEditPaymentMethod(UserPaymentMethod paymentMethod) async {
    final result = await context.push('/profile/payment-methods/edit/${paymentMethod.id}');
    if (result == true) {
      _loadPaymentMethods();
    }
  }

  void _setDefaultPaymentMethod(String id) {
    context.read<PaymentMethodBloc>().add(PaymentMethodSetDefaultEvent(id: id));
  }

  void _showDeleteConfirmation(UserPaymentMethod paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
          'Are you sure you want to delete "${paymentMethod.label}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PaymentMethodBloc>().add(
                PaymentMethodDeleteEvent(id: paymentMethod.id),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 