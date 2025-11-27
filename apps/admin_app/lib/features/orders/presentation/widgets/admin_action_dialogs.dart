import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../data/models/order_model.dart';
import '../../data/order_service.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';

class AssignDeliveryAgentDialog extends StatefulWidget {
  final OrderModel order;

  const AssignDeliveryAgentDialog({super.key, required this.order});

  @override
  State<AssignDeliveryAgentDialog> createState() => _AssignDeliveryAgentDialogState();
}

class _AssignDeliveryAgentDialogState extends State<AssignDeliveryAgentDialog> {
  final OrderService _orderService = GetIt.instance<OrderService>();
  List<Map<String, dynamic>> _agents = [];
  String? _selectedAgentId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      final agents = await _orderService.getAvailableDeliveryAgents();
      setState(() {
        _agents = agents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load agents: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedAgentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery agent')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      context.read<OrderBloc>().add(
            AssignDeliveryAgent(widget.order.id, _selectedAgentId!),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign agent: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Delivery Agent'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _agents.isEmpty
                ? const Text('No available delivery agents')
                : DropdownButtonFormField<String>(
                    initialValue: _selectedAgentId,
                    decoration: const InputDecoration(
                      labelText: 'Select Delivery Agent',
                      border: OutlineInputBorder(),
                    ),
                    items: _agents.map((agent) {
                      return DropdownMenuItem<String>(
                        value: agent['id'] as String,
                        child: Text(agent['name'] as String? ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAgentId = value;
                      });
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedAgentId == null ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }
}

class ChangeOrderStatusDialog extends StatefulWidget {
  final OrderModel order;

  const ChangeOrderStatusDialog({super.key, required this.order});

  @override
  State<ChangeOrderStatusDialog> createState() => _ChangeOrderStatusDialogState();
}

class _ChangeOrderStatusDialogState extends State<ChangeOrderStatusDialog> {
  String? _selectedStatus;
  bool _isSubmitting = false;

  final List<Map<String, String>> _statuses = [
    {'value': 'PENDING', 'label': 'Pending'},
    {'value': 'ACCEPTED', 'label': 'Accepted'},
    {'value': 'PREPARING', 'label': 'Preparing'},
    {'value': 'READY_FOR_PICKUP', 'label': 'Ready for Pickup'},
    {'value': 'IN_DELIVERY', 'label': 'In Delivery'},
    {'value': 'DELIVERED', 'label': 'Delivered'},
    {'value': 'CANCELLED', 'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  Future<void> _submit() async {
    if (_selectedStatus == null || _selectedStatus == widget.order.status) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      context.read<OrderBloc>().add(
            UpdateOrderStatus(widget.order.id, _selectedStatus!),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Order Status'),
      content: DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        decoration: const InputDecoration(
          labelText: 'New Status',
          border: OutlineInputBorder(),
        ),
        items: _statuses.map((status) {
          return DropdownMenuItem<String>(
            value: status['value'],
            child: Text(status['label']!),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedStatus = value;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

class CancelOrderDialog extends StatefulWidget {
  final OrderModel order;

  const CancelOrderDialog({super.key, required this.order});

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      context.read<OrderBloc>().add(
            CancelOrder(widget.order.id, _reasonController.text.trim()),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Cancellation Reason',
            hintText: 'Enter reason for cancellation',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a cancellation reason';
            }
            if (value.trim().length < 5) {
              return 'Reason must be at least 5 characters';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cancel Order'),
        ),
      ],
    );
  }
}

class RefundOrderDialog extends StatefulWidget {
  final OrderModel order;

  const RefundOrderDialog({super.key, required this.order});

  @override
  State<RefundOrderDialog> createState() => _RefundOrderDialogState();
}

class _RefundOrderDialogState extends State<RefundOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;
  bool _customAmount = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.order.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _customAmount
        ? double.tryParse(_amountController.text)
        : widget.order.total;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid refund amount')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      context.read<OrderBloc>().add(
            RefundOrder(
              widget.order.id,
              _reasonController.text.trim(),
              amount: _customAmount ? amount : null,
            ),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refund order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refund Order'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order Total: \$${widget.order.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _customAmount,
                    onChanged: (value) {
                      setState(() {
                        _customAmount = value ?? false;
                      });
                    },
                  ),
                  const Text('Custom refund amount'),
                ],
              ),
              if (_customAmount) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (_customAmount) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter refund amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Invalid amount';
                      }
                      if (amount > widget.order.total) {
                        return 'Amount cannot exceed order total';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Refund Reason',
                  hintText: 'Enter reason for refund',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a refund reason';
                  }
                  if (value.trim().length < 5) {
                    return 'Reason must be at least 5 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Process Refund'),
        ),
      ],
    );
  }
}

class EditOrderFeesDialog extends StatefulWidget {
  final OrderModel order;

  const EditOrderFeesDialog({super.key, required this.order});

  @override
  State<EditOrderFeesDialog> createState() => _EditOrderFeesDialogState();
}

class _EditOrderFeesDialogState extends State<EditOrderFeesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deliveryFeeController = TextEditingController();
  final _discountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _deliveryFeeController.text = widget.order.deliveryFee.toStringAsFixed(2);
    _discountController.text = widget.order.discount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _discountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final deliveryFee = double.tryParse(_deliveryFeeController.text) ?? widget.order.deliveryFee;
    final discount = double.tryParse(_discountController.text) ?? widget.order.discount;

    setState(() {
      _isSubmitting = true;
    });

    try {
      context.read<OrderBloc>().add(
            UpdateOrderFees(
              widget.order.id,
              deliveryFee: deliveryFee != widget.order.deliveryFee ? deliveryFee : null,
              discount: discount != widget.order.discount ? discount : null,
              reason: _reasonController.text.trim().isEmpty
                  ? null
                  : _reasonController.text.trim(),
            ),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update fees: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Order Fees'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _deliveryFeeController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Fee',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter delivery fee';
                  }
                  final fee = double.tryParse(value);
                  if (fee == null || fee < 0) {
                    return 'Invalid delivery fee';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter discount (0 if none)';
                  }
                  final discount = double.tryParse(value);
                  if (discount == null || discount < 0) {
                    return 'Invalid discount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  hintText: 'Enter reason for fee change',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Fees'),
        ),
      ],
    );
  }
}

