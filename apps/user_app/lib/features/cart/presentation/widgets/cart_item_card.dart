import 'package:flutter/material.dart';
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

class _CartItemCardState extends State<CartItemCard> with TickerProviderStateMixin {
  late TextEditingController _instructionsController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isEditingInstructions = false;

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController(text: widget.item.instructions);
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _scaleController.dispose();
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

  void _onQuantityButtonPressed(VoidCallback callback) {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      callback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
          ),
      child: Column(
        children: [
              // Main item content
          Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Item header with image and details
                    Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        // Product image with hero animation
                        Hero(
                          tag: 'cart-item-${widget.item.productId}',
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.item.productImageUrl != null
                                  ? Image.network(
                      widget.item.productImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                                          _buildPlaceholderImage(theme),
                                    )
                                  : _buildPlaceholderImage(theme),
                    ),
                          ),
                  ),
                  
                        const SizedBox(width: 16),
                
                        // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                              // Product name
                      Text(
                        widget.item.productName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                        ),
                              
                              const SizedBox(height: 6),
                      
                              // Shop name with location icon
                      Row(
                        children: [
                                  Icon(
                                    Icons.store_outlined,
                                    size: 14,
                                color: theme.colorScheme.primary,
                              ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.item.shopName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                              
                              const SizedBox(height: 12),
                              
                              // Price with discount handling
                              _buildPriceSection(theme),
                    ],
                  ),
                ),
                
                // Remove button
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.error,
                            ),
                  onPressed: widget.onRemove,
                            tooltip: 'Remove from cart',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: theme.colorScheme.error,
                            ),
                          ),
                ),
              ],
          ),
          
                    const SizedBox(height: 20),
          
                    // Quantity controls and total
                    Row(
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decrement button
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: widget.item.quantity > 1
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: widget.item.quantity > 1
                                        ? () => _onQuantityButtonPressed(widget.onDecrement)
                                        : null,
                        style: IconButton.styleFrom(
                                      foregroundColor: widget.item.quantity > 1
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                        ),
                      ),
                      
                              // Quantity display
                              Container(
                                constraints: const BoxConstraints(minWidth: 50),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                        '${widget.item.quantity}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                      ),
                      
                      // Increment button
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () => _onQuantityButtonPressed(widget.onIncrement),
                        style: IconButton.styleFrom(
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Total price
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                  child: Text(
                            '\$${widget.item.totalPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Special instructions section
              _buildInstructionsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Icon(
        Icons.restaurant_menu,
        size: 32,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    if (widget.item.discountedPrice != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original price (crossed out)
          Text(
            '\$${widget.item.productPrice.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          // Discounted price
          Row(
            children: [
              Text(
                '\$${widget.item.discountedPrice!.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SAVE \$${(widget.item.productPrice - widget.item.discountedPrice!).toStringAsFixed(2)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
              ],
            ),
        ],
      );
    } else {
      return Text(
        '\$${widget.item.productPrice.toStringAsFixed(2)}',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      );
    }
  }

  Widget _buildInstructionsSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.note_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          'Special Instructions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: widget.item.instructions?.isNotEmpty == true
            ? Text(
                widget.item.instructions!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
                          : Text(
                'Tap to add instructions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditingInstructions) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _instructionsController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Extra spicy, no onions, etc.',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      maxLines: 3,
                      style: theme.textTheme.bodyMedium,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _toggleInstructionsEdit,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditingInstructions = false;
                            _instructionsController.text = widget.item.instructions ?? '';
                          });
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _toggleInstructionsEdit,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                ] else ...[
                  if (widget.item.instructions?.isNotEmpty == true) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    child: Text(
                      widget.item.instructions!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                      ),
                    ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditingInstructions = true;
                        });
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        widget.item.instructions?.isNotEmpty == true
                            ? 'Edit Instructions'
                            : 'Add Instructions',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}