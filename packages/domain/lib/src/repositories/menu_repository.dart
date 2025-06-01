import '../entities/menu_item.dart';

/// Repository interface for menu management operations
abstract class MenuRepository {
  /// Get all menu items for a vendor
  Future<List<MenuItem>> getMenuItems(String vendorId);
  
  /// Get menu items by category
  Future<List<MenuItem>> getMenuItemsByCategory(String vendorId, String category);
  
  /// Get a specific menu item by ID
  Future<MenuItem> getMenuItemById(String menuItemId);
  
  /// Create a new menu item
  Future<MenuItem> createMenuItem(MenuItem menuItem);
  
  /// Update an existing menu item
  Future<MenuItem> updateMenuItem(MenuItem menuItem);
  
  /// Delete a menu item
  Future<void> deleteMenuItem(String menuItemId);
  
  /// Update menu item availability status
  Future<MenuItem> updateItemStatus(String menuItemId, MenuItemStatus status);
  
  /// Update menu item availability
  Future<MenuItem> updateItemAvailability(String menuItemId, bool isAvailable);
  
  /// Bulk update menu items availability
  Future<List<MenuItem>> bulkUpdateAvailability(List<String> menuItemIds, bool isAvailable);
  
  /// Upload image for menu item
  Future<String> uploadMenuItemImage(String menuItemId, String imagePath);
  
  /// Delete image from menu item
  Future<MenuItem> deleteMenuItemImage(String menuItemId, String imageUrl);
  
  /// Get menu categories for a vendor
  Future<List<String>> getMenuCategories(String vendorId);
  
  /// Update menu item sort order
  Future<void> updateSortOrder(List<Map<String, dynamic>> itemsWithOrder);
  
  /// Search menu items by name or description
  Future<List<MenuItem>> searchMenuItems(String vendorId, String query);
  
  /// Get featured menu items
  Future<List<MenuItem>> getFeaturedItems(String vendorId);
  
  /// Toggle featured status of menu item
  Future<MenuItem> toggleFeatured(String menuItemId, bool isFeatured);
  
  /// Get low stock menu items
  Future<List<MenuItem>> getLowStockItems(String vendorId);
  
  /// Apply discount to menu item
  Future<MenuItem> applyDiscount(String menuItemId, double discountPercentage);
  
  /// Remove discount from menu item
  Future<MenuItem> removeDiscount(String menuItemId);
} 