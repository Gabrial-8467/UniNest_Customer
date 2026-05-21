# UniNest - Application Documentation

## Overview

**UniNest** (also branded as **UNINEST**) is a comprehensive Flutter-based food ordering mobile application designed for university campuses. The app connects students and faculty with campus canteens, enabling seamless food ordering, delivery tracking, and payment processing.

---

## Table of Contents

1. [App Information](#app-information)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [Core Features](#core-features)
4. [User Flows](#user-flows)
5. [Screens & UI Components](#screens--ui-components)
6. [Backend Integration](#backend-integration)
7. [State Management](#state-management)
8. [Key Services](#key-services)
9. [Security Features](#security-features)
10. [Notifications](#notifications)
11. [Payment Integration](#payment-integration)

---

## App Information

| Property | Value |
|----------|-------|
| **App Name** | UniNest / UNINEST |
| **Version** | 1.0.0+1 |
| **Platform** | Flutter (Cross-platform) |
| **Minimum SDK** | Dart 3.11.1 |
| **Supported Platforms** | Android, Web |
| **App Icon** | assets/uninest.jpeg |

---

## Architecture & Technology Stack

### Framework & Languages
- **Flutter** - UI framework for cross-platform development
- **Dart** - Programming language

### State Management
- **Provider Pattern** - For app-wide state management via `CampusAppState`
- **AnimatedBuilder** - For reactive UI updates

### Key Dependencies
| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `shared_preferences` | Local data persistence |
| `http` | API communication |
| `flutter_secure_storage` | Secure token storage |
| `firebase_core` & `firebase_messaging` | Push notifications |
| `razorpay_flutter` | Payment gateway integration |
| `google_fonts` | Typography |
| `flutter_dotenv` | Environment configuration |
| `crypto` | Cryptographic operations |

---

## Core Features

### 1. Authentication & User Management
- **Login Screen** - Email/password authentication with secure token storage
- **Signup Screen** - User registration with validation
- **Password Security** - Secure storage using `flutter_secure_storage`
- **Session Management** - Automatic token refresh and session persistence

### 2. Home & Product Discovery
- **Home Screen** - Featured products, categories, and promotions
- **Search Functionality** - Real-time product search with filters
- **Product Categories** - Organized browsing by food categories
- **Product Cards** - Rich product display with:
  - Product images
  - Pricing (with discount support)
  - Ratings and reviews
  - Favorite toggle
  - Quick add-to-cart with quantity selector

### 3. Canteen Management
- **All Canteens Screen** - List of available campus canteens
- **Canteen Menu** - Individual canteen product listings
- **Canteen Status** - Real-time open/closed status with polling
- **Operating Hours** - Display of canteen working hours

### 4. Shopping Cart
- **Cart Screen** - Manage selected items
- **Quantity Management** - Add, remove, update quantities
- **Price Calculation** - Automatic total calculation with discounts
- **Persistent Cart** - Cart items saved locally across app sessions

### 5. Checkout & Orders
- **Checkout Screen** - Complete order placement flow
- **Delivery Options**:
  - **Delivery** - To campus location (Block, Room, Floor)
  - **Self Pickup** - Takeaway option
- **Address Validation** - Inline field validation with error messages
- **Order Summary** - Itemized billing with taxes and fees
- **Coupon Support** - Discount code application

### 6. Payment Processing
- **Razorpay Integration** - Secure payment gateway
- **Multiple Payment Methods**:
  - Cash on Delivery (COD)
  - Online Payment (Cards, UPI, Wallets)
- **Payment Verification** - Signature verification for security
- **Transaction History** - Order payment records

### 7. Order Tracking & History
- **Order Tracking Screen** - Real-time order status updates
- **Live Order Status**:
  - Pending
  - Preparing
  - Ready for Pickup
  - Out for Delivery
  - Delivered
  - Cancelled
- **Order History** - Past orders with reorder capability
- **Order Details** - Complete order information

### 8. Wishlist & Favorites
- **Wishlist Screen** - Saved favorite products
- **Favorite Toggle** - Quick add/remove from product cards
- **Persistent Storage** - Favorites saved across sessions

### 9. Notifications
- **Push Notifications** - Firebase Cloud Messaging integration
- **In-App Notifications** - Notification center screen
- **Notification Types**:
  - Order updates
  - Promotional offers
  - System announcements
- **Unread Count** - Badge indicators for unread notifications

### 10. User Profile & Support
- **Profile Screen** - User information and settings
- **Help & Support** - FAQ and support resources
- **Live Chat** - Real-time customer support chat interface
- **Order Support** - Issue reporting for orders

### 11. Security Features
- **Secret Signature Screen** - Admin/debug access with signature verification
- **API Security** - HMAC signature verification for API requests
- **Secure Storage** - Encrypted local storage for sensitive data

---

## User Flows

### First Time User Flow
```
Splash Screen → Login/Signup → Home Screen → Browse Products → Add to Cart → Checkout → Order Tracking
```

### Returning User Flow
```
Splash Screen → Auto Login → Home Screen → (Quick Actions)
```

### Order Placement Flow
```
1. Browse/Search Products
2. Add to Cart (with quantity)
3. Review Cart
4. Select Delivery/Pickup
5. Enter Delivery Address (if delivery)
6. Apply Coupon (optional)
7. Select Payment Method
8. Complete Payment
9. Track Order
```

### Payment Flow
```
1. User confirms order
2. Razorpay checkout opens
3. User completes payment
4. Payment verification (signature check)
5. Order confirmation
6. Notification sent
```

---

## Screens & UI Components

### Authentication Screens
| Screen | File | Description |
|--------|------|-------------|
| Login | `auth/login_screen.dart` | User authentication |
| Signup | `auth/signup_screen.dart` | User registration |

### Main Screens
| Screen | File | Key Features |
|--------|------|--------------|
| Splash | `splash_screen.dart` | Animated logo, auto-navigation |
| Home | `home.dart` | Product grid, categories, search |
| Canteen Menu | `canteen_menu.dart` | Canteen-specific products |
| All Canteens | `all_canteens.dart` | Canteen listing |
| Product Details | `product_details.dart` | Product info, reviews, add to cart |
| Search Results | `search_results_screen.dart` | Search with filters |

### Shopping Screens
| Screen | File | Key Features |
|--------|------|--------------|
| Cart | `cart.dart` | Item management, quantity controls |
| Checkout | `checkout.dart` | Address, payment, order summary |
| Wishlist | `wishlist.dart` | Saved favorites |

### Order Screens
| Screen | File | Key Features |
|--------|------|--------------|
| Order Tracking | `order_tracking.dart` | Live status, timeline view |
| Order History | `order_history.dart` | Past orders list |

### User Screens
| Screen | File | Key Features |
|--------|------|--------------|
| Profile | `profile.dart` | User info, settings |
| Notifications | `notifications_screen.dart` | Notification center |
| Help & Support | `help_support.dart` | FAQ, contact info |
| Live Chat | `live_chat.dart` | Real-time support chat |

### Utility Screens
| Screen | File | Purpose |
|--------|------|---------|
| Main Navigation | `main_navigation_screen.dart` | Bottom navigation wrapper |
| Secret Signature | `secret_signature_screen.dart` | Admin/debug access |

### Reusable Widgets
| Widget | File | Purpose |
|--------|------|---------|
| ProductCard | `widgets/product_card.dart` | Product display with actions |
| ProductGrid | `widgets/product_card.dart` | Grid layout for products |
| ProductList | `widgets/product_card.dart` | List layout for products |

---

## Backend Integration

### API Architecture
- **Base URL Configuration** - Environment-based API endpoints
- **RESTful API** - Standard HTTP methods (GET, POST, PUT, PATCH, DELETE)
- **JSON Data Format** - Request/Response payload format
- **Authentication** - Bearer token-based authentication

### API Service Features
- **Request Caching** - Automatic caching for GET requests
- **Request Deduplication** - Prevents duplicate simultaneous requests
- **Timeout Handling** - Configurable connection timeouts
- **Error Handling** - Comprehensive error responses
- **Debug Logging** - Sanitized request/response logging

### Key API Endpoints
| Endpoint | Purpose |
|----------|---------|
| `/api/auth/login` | User authentication |
| `/api/auth/register` | User registration |
| `/api/products` | Product listings |
| `/api/canteens` | Canteen information |
| `/api/cart` | Cart operations |
| `/api/orders` | Order management |
| `/api/notifications` | User notifications |
| `/api/payments` | Payment processing |

---

## State Management

### CampusAppState
Centralized state management class handling:

#### Cart Management
- `addToCart(productId, quantity)` - Add items to cart
- `removeFromCart(productId)` - Remove items
- `updateCartQuantity(productId, quantity)` - Update quantities
- `getCartQuantity(productId)` - Get current quantity
- `clearCart()` - Empty cart
- Persistent cart storage using SharedPreferences

#### Favorites Management
- `setFavorite(productId, isFavorite)` - Toggle favorite status
- `toggleFavorite(productId)` - Quick toggle
- `isFavorite(productId)` - Check favorite status
- Persistent storage across sessions

#### Order Management
- Active order tracking
- Order status updates
- Order history management

#### Data Fetching
- Product catalog synchronization
- Canteen status polling
- Notification polling
- Optimized background/foreground polling

#### App Lifecycle Management
- Automatic polling pause in background
- Data refresh on app resume
- Resource optimization

---

## Key Services

### 1. ApiService
- HTTP request handling
- Authentication header management
- Request/Response logging
- Error handling and timeout management
- Caching and deduplication

### 2. AuthService
- User authentication
- Token management
- Secure storage of credentials
- Session persistence
- Auto-logout handling

### 3. NotificationService
- Firebase initialization
- Push notification handling
- Token management
- Notification routing

### 4. SecureStorageService
- Encrypted data storage
- Keychain/Keystore integration
- Sensitive data protection

### 5. RequestCacheService
- HTTP response caching
- Cache invalidation
- Deduplication of concurrent requests

---

## Security Features

### Data Security
- **Secure Storage** - Tokens and sensitive data encrypted
- **API Security** - Request signature verification
- **Environment Variables** - Secure configuration management

### Payment Security
- **Razorpay Integration** - PCI-compliant payment processing
- **Signature Verification** - HMAC verification for payment callbacks
- **No Sensitive Data Storage** - No card data stored locally

### Authentication Security
- **JWT Tokens** - Secure session management
- **Token Refresh** - Automatic session renewal
- **Secure Logout** - Complete session cleanup

---

## Notifications

### Push Notifications (Firebase)
- Order status updates
- Promotional offers
- System announcements

### In-App Notifications
- Notification list screen
- Unread count badges
- Mark as read functionality
- Pull-to-refresh support

### Polling Strategy
- Background: Paused to save resources
- Foreground: Active polling with optimized intervals
- Canteen status: 2-minute intervals
- Notifications: 5-minute intervals
- Order status: 1-minute intervals

---

## Payment Integration

### Razorpay Setup
- **Gateway Integration** - Seamless checkout experience
- **Payment Methods** - Cards, UPI, Net Banking, Wallets
- **Test/Live Modes** - Environment-based configuration

### Payment Flow
1. Order creation on backend
2. Razorpay order initialization
3. User payment completion
4. Payment signature verification
5. Order confirmation
6. Notification dispatch

### Security Measures
- Server-side signature verification
- No sensitive payment data in app
- Secure transaction logging

---

## UI/UX Design System

### Color Palette
- **Primary** - Coral/Pink (`#FFFF6B6B`)
- **Background** - Light gray (`#FFF5F5F5`)
- **Surface** - White (`#FFFFFFFF`)
- **Text Primary** - Dark gray (`#FF2D3436`)
- **Text Secondary** - Medium gray (`#FF636E72`)
- **Error** - Red (`#FFE74C3C`)
- **Success** - Green (`#FF4CAF50`)

### Typography
- **Font Family** - Google Fonts (Inter/Poppins)
- **Hierarchy** - Headlines, body, captions, buttons
- **Responsive Sizing** - Adaptive text scaling

### Components
- **Cards** - Product cards with elevation and shadows
- **Buttons** - Elevated and text button variants
- **Input Fields** - Bordered inputs with validation states
- **Loading States** - Animated spinners and skeletons
- **Snackbar** - Actionable feedback messages

---

## Performance Optimizations

### Data Management
- Request caching for API calls
- Image optimization
- Lazy loading for lists
- Pagination for large datasets

### State Optimization
- Selective UI updates via AnimatedBuilder
- Debounced search inputs
- Efficient cart calculations

### Resource Management
- Background polling suspension
- Memory-efficient image handling
- Optimized rebuild strategies

---

## Development & Deployment

### Development Setup
```bash
# Clone repository
git clone <repository-url>

# Install dependencies
flutter pub get

# Setup environment
cp .env.example .env

# Run app
flutter run
```

### Build Commands
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# Web
flutter build web --release
```

### Configuration Files
- `.env` - Environment variables
- `firebase_options.dart` - Firebase configuration
- `app_config.dart` - App settings and API endpoints

---

## Future Enhancements

### Potential Features
- **Multi-language Support** - Internationalization
- **Dark Mode** - Theme switching
- **Advanced Filters** - Dietary preferences, price range
- **Rating System** - User reviews and ratings
- **Social Sharing** - Share products/orders
- **Loyalty Program** - Points and rewards
- **Pre-ordering** - Scheduled orders
- **Group Ordering** - Multiple users, single order

---

## Support & Contact

For technical support or feature requests:
- **In-App Support** - Help & Support screen
- **Live Chat** - Real-time assistance
- **Email** - Support contact via app

---

## Conclusion

UniNest (UNINEST) is a feature-rich, production-ready food ordering application built with Flutter. It provides a seamless experience for campus food ordering with robust backend integration, secure payment processing, and real-time order tracking. The app is designed for scalability and can be extended with additional features as needed.

---

*Document Version: 1.0*  
*Last Updated: May 2026*  
*Platform: Flutter 3.x*  
*Developed for: University Campus Food Services*
