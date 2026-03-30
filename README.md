# UniNest - Campus Food Ordering App

A comprehensive Flutter application for campus food ordering and delivery services. UniNest serves as your complete campus living companion, allowing students to browse canteens, order food, track deliveries, and manage their campus dining experience.

## 🚀 Features

### Core Functionality
- **User Authentication**: Secure login and registration system
- **Canteen Browsing**: Explore all campus canteens and their menus
- **Food Ordering**: Browse detailed product information and place orders
- **Cart Management**: Add/remove items, manage quantities
- **Order Tracking**: Real-time order status and delivery tracking
- **Order History**: View past orders and reorder favorites
- **Profile Management**: Update personal information and preferences
- **Wishlist**: Save favorite items for quick ordering

### Advanced Features
- **Live Chat Support**: Real-time customer service integration
- **Help & Support**: Comprehensive support system
- **Secure Payments**: Checkout with multiple payment options
- **Push Notifications**: Order status updates and promotions
- **Offline Support**: Basic functionality without internet connection

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point and theme configuration
├── splash_screen.dart        # Animated splash screen with authentication check
├── config/                   # App configuration and environment settings
│   └── app_config.dart       # API endpoints, security settings, feature flags
├── Users/                    # User interface components
│   ├── screen/               # All app screens
│   │   ├── auth/             # Authentication screens (login, signup)
│   │   ├── home.dart         # Main home screen
│   │   ├── canteen_menu.dart # Canteen menu browsing
│   │   ├── product_details.dart # Detailed product information
│   │   ├── cart.dart         # Shopping cart management
│   │   ├── checkout.dart     # Order checkout process
│   │   ├── order_tracking.dart # Real-time order tracking
│   │   ├── order_history.dart # Past orders view
│   │   ├── profile.dart      # User profile management
│   │   ├── wishlist.dart     # Saved items
│   │   ├── live_chat.dart    # Customer support chat
│   │   └── help_support.dart # Help and support
│   ├── state/                # State management
│   └── widgets/              # Reusable UI components
├── services/                 # Business logic and external services
│   ├── api_service.dart       # HTTP client and API communication
│   ├── auth_service.dart     # Authentication logic
│   └── secure_storage_service.dart # Secure data storage
└── utils/                    # Utility functions and helpers
    ├── constants.dart        # App constants and configurations
    ├── input_validator.dart   # Form validation logic
    ├── currency_formatter.dart # Currency formatting
    ├── formatters.dart        # Data formatting utilities
    ├── helpers.dart          # General helper functions
    ├── secure_logger.dart    # Secure logging system
    ├── ssl_validator.dart    # SSL certificate validation
    └── validators.dart       # Additional validation utilities
```

## 🛠️ Technology Stack

- **Framework**: Flutter
- **State Management**: Custom state management with CampusAppState
- **HTTP Client**: Custom API service with timeout handling
- **Security**: SSL validation, secure storage, encryption
- **Authentication**: JWT-based authentication
- **Environment Configuration**: Flutter dotenv for environment variables
- **Logging**: Secure logging system with debug/release modes

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```
API_BASE_URL=http://your-api-url:5000
ENFORCE_HTTPS=true
API_TIMEOUT_SECONDS=30
ENABLE_DEBUG_LOGGING=true
ENABLE_ANALYTICS=false
ENCRYPTION_KEY=your-encryption-key
JWT_SECRET=your-jwt-secret
```

### Security Features
- HTTPS enforcement in production
- SSL certificate validation
- Secure local storage for sensitive data
- Input validation and sanitization
- Timeout handling for network requests

## 🎨 UI/UX Features

- **Modern Design**: Material 3 design system
- **Theme**: Custom color scheme with primary color (#FF6B6B)
- **Animations**: Smooth transitions and micro-interactions
- **Responsive Design**: Optimized for various screen sizes
- **Accessibility**: Proper semantic labels and navigation

## 📱 App Screens

1. **Splash Screen**: Animated introduction with authentication check
2. **Authentication**: Login and signup screens with form validation
3. **Home**: Main dashboard with featured items and quick actions
4. **Canteens**: Browse all available campus canteens
5. **Menu**: Detailed canteen menus with categories
6. **Product Details**: Comprehensive product information with images
7. **Cart**: Shopping cart with quantity management
8. **Checkout**: Multi-step checkout process
9. **Order Tracking**: Real-time delivery tracking
10. **Profile**: User profile and settings management
11. **Support**: Help center and live chat

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 2.17.0)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd campus_eats
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create environment configuration:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run the app:
```bash
flutter run
```

### Development

For development with local API:
- Update `API_BASE_URL` in `.env` to your local server
- Ensure your server allows connections from your development device
- Use your computer's local IP address (not localhost) for physical device testing

## 🔒 Security Considerations

- All sensitive data is encrypted before storage
- API communication uses HTTPS in production
- Input validation prevents injection attacks
- Secure logging prevents sensitive data exposure
- SSL certificates are validated for all HTTPS requests

## 📝 API Integration

The app integrates with a RESTful API with the following endpoints:
- Authentication: `/api/auth/login`, `/api/auth/register`
- User Profile: `/api/auth/profile`
- Products: `/api/products`
- Orders: `/api/orders`, `/api/orders/myorders`
- File Upload: `/api/upload`
- Admin: `/api/admin/users`, `/api/admin/orders`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Use the in-app help and support feature
- Check the live chat for immediate assistance
- Review the documentation for common issues

---

**UniNest** - Making campus dining convenient and enjoyable! 🍕📱
