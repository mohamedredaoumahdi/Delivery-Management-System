import '../entities/menu_item.dart';
import '../repositories/menu_repository.dart';

/// Use case for managing menu items
class ManageMenuItemsUseCase {
  final MenuRepository repository;

  ManageMenuItemsUseCase(this.repository);

  /// Get all menu items for a vendor
  Future<List<MenuItem>> getMenuItems(String vendorId) async {
    return await repository.getMenuItems(vendorId);
  }

  /// Create a new menu item
  Future<MenuItem> createMenuItem(MenuItem menuItem) async {
    return await repository.createMenuItem(menuItem);
  }

  /// Update an existing menu item
  Future<MenuItem> updateMenuItem(MenuItem menuItem) async {
    return await repository.updateMenuItem(menuItem);
  }

  /// Delete a menu item
  Future<void> deleteMenuItem(String menuItemId) async {
    return await repository.deleteMenuItem(menuItemId);
  }

  /// Update menu item availability
  Future<MenuItem> updateItemAvailability(String menuItemId, bool isAvailable) async {
    return await repository.updateItemAvailability(menuItemId, isAvailable);
  }

  /// Get menu items by category
  Future<List<MenuItem>> getMenuItemsByCategory(String vendorId, String category) async {
    return await repository.getMenuItemsByCategory(vendorId, category);
  }
} 