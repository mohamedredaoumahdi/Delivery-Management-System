# Vendor App

The Vendor App is part of the delivery management system, designed specifically for restaurant owners and food vendors to manage their business operations.

## Features

### 🔐 Authentication
- **Login**: Secure vendor login with email and password
- **Registration**: Complete vendor registration with business information
- **Password validation**: Strong password requirements
- **Form validation**: Comprehensive input validation

### 📊 Dashboard
- **Business Overview**: Today's key metrics and statistics
- **Quick Stats**: Orders, revenue, pending orders, and ratings
- **Quick Actions**: Fast access to common tasks
- **Recent Orders**: Live view of recent order activity

### 📋 Order Management
- **Order List**: View all incoming orders
- **Order Details**: Detailed view of individual orders
- **Status Updates**: Update order status (preparing, ready, delivered)
- **Real-time Updates**: Live order notifications

### 🍽️ Menu Management
- **Menu Items**: View and manage all menu items
- **Add Items**: Add new dishes with photos and descriptions
- **Edit Items**: Update existing menu items
- **Delete Items**: Remove items from the menu
- **Categories**: Organize items by categories

### 👤 Profile Management
- **Vendor Profile**: Manage business information
- **Business Details**: Update restaurant name, address, contact info
- **Settings**: App preferences and configurations

### 📈 Analytics
- **Sales Reports**: Revenue and sales analytics
- **Order Analytics**: Order patterns and trends
- **Performance Metrics**: Business performance insights
- **Charts and Graphs**: Visual data representation

## Architecture

The app follows Clean Architecture principles with:

- **Presentation Layer**: UI components, pages, and BLoC state management
- **Domain Layer**: Business logic and use cases (shared package)
- **Data Layer**: API calls and data sources (shared package)
- **Core Layer**: Common utilities and configurations (shared package)

## Project Structure

```
lib/
├── config/
│   ├── app_config.dart          # App configuration constants
│   ├── router_config.dart       # Navigation routing setup
│   └── theme_config.dart        # App theme and styling
├── di/
│   └── injection_container.dart # Dependency injection setup
├── common/
│   └── presentation/
│       └── pages/
│           ├── splash_page.dart      # App splash screen
│           └── main_wrapper_page.dart # Bottom navigation wrapper
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── auth_bloc.dart    # Authentication state management
│   │       └── pages/
│   │           ├── login_page.dart   # Vendor login screen
│   │           └── register_page.dart # Vendor registration
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── dashboard_bloc.dart # Dashboard state management
│   │       └── pages/
│   │           └── dashboard_page.dart # Main dashboard
│   ├── orders/
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── orders_bloc.dart    # Orders state management
│   │       └── pages/
│   │           ├── orders_page.dart    # Orders list
│   │           └── order_details_page.dart # Order details
│   ├── menu/
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── menu_bloc.dart      # Menu state management
│   │       └── pages/
│   │           ├── menu_management_page.dart # Menu overview
│   │           ├── add_menu_item_page.dart   # Add new item
│   │           └── edit_menu_item_page.dart  # Edit existing item
│   ├── profile/
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── profile_bloc.dart   # Profile state management
│   │       └── pages/
│   │           └── profile_page.dart   # Vendor profile
│   └── analytics/
│       └── presentation/
│           ├── bloc/
│           │   └── analytics_bloc.dart # Analytics state management
│           └── pages/
│               └── analytics_page.dart # Business analytics
└── main.dart                    # App entry point
```

## Dependencies

### Core Dependencies
- **flutter_bloc**: State management
- **go_router**: Navigation and routing
- **get_it**: Dependency injection
- **dio**: HTTP client for API calls
- **shared_preferences**: Local storage

### UI Dependencies
- **cached_network_image**: Image caching
- **fl_chart**: Charts and graphs for analytics
- **image_picker**: Image selection for menu items

### Utility Dependencies
- **equatable**: Value equality
- **dartz**: Functional programming
- **connectivity_plus**: Network connectivity
- **geolocator**: Location services
- **intl**: Internationalization

## Getting Started

1. **Install Dependencies**
   ```bash
   cd apps/vendor_app
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Build for Production**
   ```bash
   flutter build apk  # For Android
   flutter build ios  # For iOS
   ```

## Configuration

### API Configuration
Update the base URL in `lib/config/app_config.dart`:
```dart
static const String baseUrl = 'your-api-url';
```

### Theme Customization
Modify colors and styling in `lib/config/theme_config.dart`.

## Development Status

### ✅ Completed
- Basic app structure and navigation
- Authentication UI (login/register)
- Dashboard with mock data
- Theme configuration
- Routing setup
- Dependency injection structure

### 🚧 In Progress
- BLoC implementation for all features
- API integration
- Real data implementation

### 📋 TODO
- Complete menu management functionality
- Order management with real-time updates
- Analytics with charts
- Profile management
- Push notifications
- Image upload for menu items
- Testing implementation

## Contributing

1. Follow the established architecture patterns
2. Use BLoC for state management
3. Implement proper error handling
4. Add tests for new features
5. Follow the existing code style

## Related Apps

- **User App**: Customer-facing mobile application
- **Delivery App**: Driver application for order delivery
- **Admin App**: Web-based admin panel for system management 