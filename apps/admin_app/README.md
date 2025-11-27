# 🎛️ Admin Web Application

A comprehensive Flutter Web application for managing the Delivery Management System platform.

## 📋 Overview

The Admin App is a full-featured web application built with Flutter Web that provides administrators with complete control over the delivery management platform. It offers intuitive interfaces for managing users, shops, orders, and viewing system analytics.

## ✨ Features

### 🏠 Dashboard
- **Real-time Statistics**: View total users, shops, orders, and revenue at a glance
- **Interactive Cards**: Click on stat cards to navigate to relevant sections
- **Quick Actions**: Fast access to key management sections
- **Welcome Section**: Personalized greeting with system overview
- **Responsive Design**: Optimized for desktop, tablet, and mobile views

### 👥 User Management
- **Comprehensive User List**: View all users (Customers, Vendors, Delivery, Admins)
- **Advanced Filtering**: Filter by user role
- **Real-time Search**: Search by name, email, or phone number
- **User Actions**: View details, edit, activate/deactivate, and delete users
- **Active Filters Display**: See and remove active filters easily
- **Responsive Views**: Table view on desktop, card view on mobile

### 🏪 Shop Management
- **Shop Directory**: View all registered shops
- **Category Filtering**: Filter by shop category (Restaurant, Grocery, Pharmacy, Retail, Other)
- **Status Filtering**: Filter by active/inactive status
- **Real-time Search**: Search by name, address, email, or phone
- **Shop Actions**: View details, edit, toggle status, and delete shops
- **Visual Indicators**: Color-coded category and status chips
- **Responsive Design**: Adapts to all screen sizes

### 🛒 Order Management
- **Order Overview**: View all orders with comprehensive details
- **Status Filtering**: Filter by order status (Pending, Accepted, Preparing, Ready, In Delivery, Delivered, Cancelled, etc.)
- **Real-time Search**: Search by order number, customer name, shop name, or delivery address
- **Order Actions**: View details and update order status
- **Status Visualization**: Color-coded status indicators
- **Order Timeline**: Track order progression

### 📊 Analytics
- **System Analytics**: Comprehensive system-wide metrics
- **Revenue Tracking**: View revenue trends and statistics
- **Order Analytics**: Order statistics and trends
- **User Growth**: Track user growth over time
- **Shop Performance**: Monitor shop performance metrics
- **Interactive Charts**: Visual data representation using FL Chart
- **Date Filtering**: Filter analytics by date range

### 🔐 Authentication & Security
- **Secure Login**: JWT-based authentication
- **Token Management**: Automatic token refresh
- **Session Handling**: Secure session management
- **Logout Confirmation**: Confirmation dialog before logout
- **Protected Routes**: Role-based access control
- **Error Handling**: Graceful handling of authentication errors

## 🎨 UI/UX Features

### Design
- **Material Design 3**: Modern Material Design implementation
- **Theme Support**: Automatic light/dark mode based on system preferences
- **Consistent Styling**: Unified design language across all pages
- **Enhanced Visuals**: Gradient backgrounds, shadows, and modern card designs

### Responsive Design
- **Desktop**: Fixed sidebar navigation with full-width content
- **Tablet**: Drawer navigation with optimized layouts
- **Mobile**: Drawer navigation with mobile-optimized views
- **Breakpoints**: 
  - Mobile: ≤ 800px
  - Tablet: 801px - 1200px
  - Desktop: > 1200px

### Navigation
- **Web-style Transitions**: Instant page transitions (no mobile-style slides)
- **Sidebar Navigation**: Fixed sidebar on desktop, drawer on mobile/tablet
- **Breadcrumbs**: Clear navigation hierarchy
- **Quick Actions**: Fast access to common tasks

### User Experience
- **Real-time Search**: Instant filtering as you type
- **Active Filters**: Visual indicators showing active filters with easy removal
- **Loading States**: Proper loading indicators during data fetching
- **Error Handling**: User-friendly error messages with retry options
- **Empty States**: Helpful messages when no data is found
- **Confirmation Dialogs**: For destructive actions (delete, logout)
- **Overflow Protection**: Handles window resizing gracefully

## 🏗️ Architecture

### Clean Architecture
The app follows Clean Architecture principles:

```
admin_app/lib/
├── features/              # Feature modules
│   ├── auth/            # Authentication
│   ├── dashboard/       # Dashboard
│   ├── users/           # User management
│   ├── shops/           # Shop management
│   ├── orders/          # Order management
│   └── analytics/       # Analytics
│       ├── data/        # Data layer (services, models)
│       └── presentation/ # Presentation layer (pages, widgets, bloc)
├── common/              # Shared components
│   └── widgets/         # Common widgets (AdminLayout)
├── config/              # Configuration
│   ├── app_config.dart  # App constants
│   ├── router_config.dart # Routing
│   └── theme_config.dart # Theme
└── di/                  # Dependency injection
    └── injection_container.dart
```

### State Management
- **BLoC Pattern**: Business Logic Component pattern for state management
- **Event-Driven**: Clear separation of events and states
- **Reactive UI**: UI automatically updates based on state changes

### Dependency Injection
- **GetIt**: Service locator for dependency injection
- **Singleton Services**: Shared services across the app
- **Factory BLoCs**: New BLoC instances per page

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Backend API running on `http://localhost:3000`

### Installation

1. **Navigate to the admin app directory:**
   ```bash
   cd apps/admin_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code generation (if needed):**
   ```bash
   flutter pub run build_runner build
   ```

4. **Start the backend server:**
   ```bash
   cd ../../backend
   npm run dev
   ```

5. **Run the admin app:**
   ```bash
   cd ../../apps/admin_app
   flutter run -d chrome
   ```

### Configuration

Update the API base URL in `lib/config/app_config.dart` if needed:

```dart
static const String apiBaseUrl = 'http://localhost:3000/api';
```

## 📱 Usage

### Login
1. Navigate to the login page
2. Enter admin credentials:
   - Email: `admin@example.com`
   - Password: (as configured in backend)
3. Click "Login"

### Dashboard
- View system statistics at a glance
- Click on stat cards to navigate to relevant sections
- Use quick action buttons for common tasks

### Managing Users
1. Navigate to "Users" from the sidebar
2. Use the search bar to find specific users
3. Click "Filter" to filter by role
4. Click on a user to view details
5. Use action buttons to edit or delete users

### Managing Shops
1. Navigate to "Shops" from the sidebar
2. Use search or filters to find shops
3. Filter by category or status
4. Toggle shop status or delete shops as needed

### Managing Orders
1. Navigate to "Orders" from the sidebar
2. Filter by order status
3. Search by order number, customer, or shop
4. Update order status as needed

### Viewing Analytics
1. Navigate to "Analytics" from the sidebar
2. View system-wide metrics
3. Filter by date range
4. Export data if needed

## 🛠️ Technology Stack

- **Framework**: Flutter Web
- **State Management**: BLoC (flutter_bloc)
- **Navigation**: GoRouter
- **Dependency Injection**: GetIt
- **Network**: Dio
- **Charts**: FL Chart
- **Local Storage**: SharedPreferences
- **Theme**: Material Design 3

## 📦 Dependencies

Key dependencies:
- `flutter_bloc`: State management
- `go_router`: Navigation
- `get_it`: Dependency injection
- `dio`: HTTP client
- `fl_chart`: Charts for analytics
- `shared_preferences`: Local storage
- `cached_network_image`: Image caching
- `intl`: Internationalization

## 🔧 Development

### Running in Development Mode
```bash
flutter run -d chrome --web-port=8080
```

### Building for Production
```bash
flutter build web --release
```

### Code Generation
If you modify models with `@JsonSerializable`:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🐛 Troubleshooting

### Common Issues

1. **401 Unauthorized Errors**
   - Ensure backend is running
   - Check if tokens are expired (logout and login again)
   - Verify API base URL in `app_config.dart`

2. **CORS Errors**
   - Ensure backend CORS is configured to allow the admin app origin
   - Check backend `cors.ts` configuration

3. **Build Errors**
   - Run `flutter clean` and `flutter pub get`
   - Ensure all dependencies are compatible
   - Check Flutter version compatibility

## 📝 Notes

- The app requires a running backend API
- Admin credentials must be created in the backend
- All API endpoints require authentication
- The app automatically handles token refresh

## 🎯 Future Enhancements

- [ ] Export functionality for reports
- [ ] Bulk operations (bulk delete, bulk update)
- [ ] Advanced analytics with more chart types
- [ ] Notification system
- [ ] Activity logs
- [ ] System settings management
- [ ] Multi-language support
