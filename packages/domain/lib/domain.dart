/// Domain package that contains business entities and use cases
/// for the delivery system apps.
library domain;

// Entities
export 'src/entities/user.dart';
export 'src/entities/shop.dart';
export 'src/entities/product.dart';
export 'src/entities/order.dart';

// Errors
export 'src/errors/failures.dart';

// Repositories
export 'src/repositories/auth_repository.dart';
export 'src/repositories/user_repository.dart';
export 'src/repositories/shop_repository.dart';
export 'src/repositories/order_repository.dart';