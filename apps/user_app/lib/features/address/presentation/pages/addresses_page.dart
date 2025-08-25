import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';

import '../bloc/address_bloc.dart';
import '../bloc/address_event.dart';
import '../bloc/address_state.dart';
import '../widgets/address_list_item.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  @override
  void initState() {
    super.initState();
    // Load addresses when page initializes
    _loadAddresses();
  }

  void _loadAddresses() {
    context.read<AddressBloc>().add(const AddressLoadEvent());
  }

  Future<void> _navigateToAddAddress() async {
    await context.push('/profile/addresses/add');
    // Reload addresses when returning from add page
    _loadAddresses();
  }

  Future<void> _navigateToEditAddress(String addressId) async {
    await context.push('/profile/addresses/edit/$addressId');
    // Reload addresses when returning from edit page
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddAddress,
            tooltip: 'Add Address',
          ),
        ],
      ),
      body: BlocConsumer<AddressBloc, AddressState>(
        listener: (context, state) {
          if (state is AddressError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is AddressCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Address added successfully'),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          } else if (state is AddressDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Address deleted successfully'),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          } else if (state is AddressDefaultSet) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Default address updated'),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AddressLoaded) {
            if (state.addresses.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AddressBloc>().add(const AddressRefreshEvent());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.addresses.length,
                itemBuilder: (context, index) {
                  final address = state.addresses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AddressListItem(
                      address: address,
                      onTap: () {
                        _navigateToEditAddress(address.id);
                      },
                      onSetDefault: () {
                        context.read<AddressBloc>().add(
                          AddressSetDefaultEvent(id: address.id),
                        );
                      },
                      onDelete: () {
                        _showDeleteConfirmation(context, address);
                      },
                    ),
                  );
                },
              ),
            );
          }

          // Error state or initial state
          if (state is AddressError) {
            return _buildErrorState(context, state.message);
          }

          return const Center(
            child: Text('No addresses found'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha:0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Addresses Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first delivery address to get started with orders.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Addresses',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Try Again',
              onPressed: () {
                context.read<AddressBloc>().add(const AddressLoadEvent());
              },
              variant: AppButtonVariant.primary,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Address address) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text(
          'Are you sure you want to delete "${address.label}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AddressBloc>().add(
                AddressDeleteEvent(id: address.id),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 