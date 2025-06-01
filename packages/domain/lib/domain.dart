/// Domain package that contains business entities and use cases
/// for the delivery system apps.
library;

// Entities
export 'src/entities/user.dart';
export 'src/entities/shop.dart';
export 'src/entities/product.dart';
export 'src/entities/order.dart';
export 'src/entities/vendor.dart';
export 'src/entities/menu_item.dart';
export 'src/entities/vendor_dashboard.dart';

// Errors
export 'src/errors/failures.dart';

// Repositories
export 'src/repositories/auth_repository.dart';
export 'src/repositories/user_repository.dart';
export 'src/repositories/shop_repository.dart';
export 'src/repositories/order_repository.dart';
export 'src/repositories/vendor_repository.dart';
export 'src/repositories/menu_repository.dart';

// Use Cases
export 'src/usecases/get_vendor_dashboard_usecase.dart';
export 'src/usecases/manage_menu_items_usecase.dart';