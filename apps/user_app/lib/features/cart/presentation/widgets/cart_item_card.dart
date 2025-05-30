import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:user_app/features/cart/domain/cart_repository.dart';


class CartItemCard extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final Function(String?) onUpdateInstructions;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onUpdateInstructions,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  late TextEditingController _instructionsController;
  bool _isEditingInstructions = false;

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController(text: widget.item.instructions);
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controller if item changes
    if (widget.item.instructions != oldWidget.item.instructions) {
      _instructionsController.text = widget.item.instructions ?? '';
    }
  }

  void _toggleInstructionsEdit() {
    setState(() {
      _isEditingInstructions = !_isEditingInstructions;
      
      // If we're closing, update instructions
      if (!_isEditingInstructions) {
        final instructions = _instructionsController.text.trim();
        widget.onUpdateInstructions(instructions.isEmpty ? null : instructions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppCard(
      contentPadding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Item details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                if (widget.item.productImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.item.productImageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            width: 80,
                            height: 80,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fastfood),
                  ),
                  
                const SizedBox(width: 12),
                
                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.productName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.shopName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Price
                      Row(
                        children: [
                          if (widget.item.discountedPrice != null) ...[
                            Text(
                              '\$${widget.item.productPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${widget.item.discountedPrice!.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ] else
                            Text(
                              '\$${widget.item.productPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Remove button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove item',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Quantity controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decrement button
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: widget.onDecrement,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      
                      // Quantity
                      Text(
                        '${widget.item.quantity}',
                        style: theme.textTheme.titleMedium,
                      ),
                      
                      // Increment button
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: widget.onIncrement,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Total price
                Flexible(
                  child: Text(
                    'Total: \$${widget.item.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Special instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Special Instructions',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _toggleInstructionsEdit,
                      icon: Icon(
                        _isEditingInstructions ? Icons.check : Icons.edit,
                        size: 12,
                      ),
                      label: Text(
                        _isEditingInstructions ? 'Save' : 'Edit',
                        style: const TextStyle(fontSize: 10),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                if (_isEditingInstructions)
                  TextField(
                    controller: _instructionsController,
                    decoration: InputDecoration(
                      hintText: 'Add special instructions...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _toggleInstructionsEdit,
                  )
                else if (widget.item.instructions?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.item.instructions!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'None',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
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