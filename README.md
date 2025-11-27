# Delivery Management System

Complete delivery management system for restaurants and businesses. Built with Flutter and Node.js.

## 🚀 Quick Start

```bash
# Clone repository
git clone <repository-url>
cd Delivery-Management-System

# Run installation script
./scripts/install.sh

# Or follow manual installation
# See INSTALLATION.md for details
```

## 📱 Applications

This system includes 4 main applications:

1. **Customer App** - Mobile app for end users
2. **Vendor App** - Dashboard for restaurants/shops  
3. **Delivery App** - App for delivery drivers
4. **Admin Panel** - Web-based admin dashboard

## ✨ Features

- ✅ Complete order management system
- ✅ Real-time updates with Socket.io
- ✅ Payment gateway integration
- ✅ Push notifications
- ✅ Reviews & ratings
- ✅ White-label customization
- ✅ **Full-featured Admin Web Dashboard** with:
  - Real-time system statistics
  - User, Shop, and Order management
  - Advanced filtering and search
  - System analytics with interactive charts
  - Responsive design (Mobile, Tablet, Desktop)
  - Light/Dark theme support
- ✅ Multi-role user system

See [FEATURES.md](FEATURES.md) for complete feature list.

## 📚 Documentation

- [Installation Guide](INSTALLATION.md) - Setup instructions
- [Configuration Guide](CONFIGURATION.md) - Configuration options
- [User Manual](USER_MANUAL.md) - User guides
- [System Documentation](SYSTEM_DOCUMENTATION.md) - Technical docs
- [CodeCanyon Package](CODE_CANYON_PACKAGE.md) - Package information

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform framework
- **BLoC** - State management
- **GoRouter** - Navigation
- **GetIt** - Dependency injection

### Backend
- **Node.js** - Runtime
- **TypeScript** - Language
- **Express** - Web framework
- **Prisma** - ORM
- **PostgreSQL** - Database
- **Redis** - Caching
- **Socket.io** - Real-time

## 📋 Requirements

- Node.js 18+
- Flutter 3.7+
- PostgreSQL 12+
- Docker (optional)

## 🏗️ Project Structure

```
Delivery-Management-System/
├── apps/
│   ├── user_app/          # Customer app
│   ├── vendor_app/        # Vendor app
│   ├── delivery_app/      # Delivery app
│   └── admin_app/         # Admin panel
├── backend/               # Backend API
├── packages/              # Shared packages
├── config/                # Configuration files
├── scripts/               # Installation scripts
└── docs/                  # Documentation
```

## 🚦 Getting Started

### 1. Backend Setup

```bash
cd backend
npm install
cp .env.example .env  # Edit .env with your config
docker-compose up -d   # Start database
npm run prisma:migrate # Run migrations
npm run seed          # Seed database (optional)
npm run dev           # Start server
```

### 2. Flutter Apps Setup

**Important:** This is a monorepo managed by Melos. You must run `melos bootstrap` from the root directory, not `flutter pub get` from individual apps.

```bash
# Install melos if not already installed
dart pub global activate melos

# Install dependencies for all apps and packages
melos bootstrap

# Then run apps:
cd apps/user_app
flutter run -d chrome # Run customer app
```

### 3. Admin Panel (Web)

```bash
cd apps/admin_app
flutter pub get
flutter run -d chrome # Run admin panel
# Or for production build:
flutter build web --release
```

**Admin Login:**
- Email: `admin@example.com`
- Password: (as configured in backend)

**Features:**
- Dashboard with real-time statistics
- User, Shop, and Order management
- Advanced filtering and search
- System analytics
- Responsive design (Mobile, Tablet, Desktop)
- Light/Dark theme support

## ⚙️ Configuration

Edit `config/whitelabel.json` to customize:
- App name and branding
- Colors and logos
- Feature flags
- Payment settings

See [CONFIGURATION.md](CONFIGURATION.md) for details.

## 🔐 Default Credentials

After seeding database:

- **Admin:** admin@example.com / password123
- **Vendor:** vendor@example.com / password123
- **Customer:** customer@example.com / password123
- **Delivery:** delivery@example.com / password123

**⚠️ Change these in production!**

## 📦 Installation Packages

### For Development
- Source code
- Documentation
- Setup scripts

### For Production
- Build scripts
- Deployment guides
- Environment templates

## 🎨 White-label Support

Fully customizable:
- App names
- Logos and branding
- Color themes
- Feature toggles

## 📊 Admin Features

- User management
- Shop management
- Order management
- Analytics dashboard
- Content moderation
- System configuration

## 🔒 Security

- JWT authentication
- Password hashing
- Role-based access control
- Input validation
- SQL injection prevention
- XSS protection

## 📈 Analytics

- Revenue reports
- User statistics
- Order analytics
- Performance metrics
- Charts and visualizations

## 🌐 API

RESTful API with:
- Complete endpoints
- API documentation
- WebSocket support
- Real-time updates

## 🤝 Support

- Email: support@example.com
- Documentation: See `docs/` folder
- Issues: Create GitHub issue

## 📄 License

See LICENSE file for details.

## 🙏 Credits

Built with:
- Flutter
- Node.js
- PostgreSQL
- Redis
- Socket.io

## 📝 Changelog

See CHANGELOG.md for version history.

## 🗺️ Roadmap

- Multi-language support
- Advanced analytics
- Chat/messaging
- Route optimization
- AI recommendations

---

**Made with ❤️ for delivery businesses**

For questions or support, contact: support@example.com
