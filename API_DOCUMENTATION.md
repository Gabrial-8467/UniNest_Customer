# UniNest Backend API Documentation

## Overview

UniNest is a comprehensive food ordering platform backend built with Node.js, Express, and MongoDB. This API provides endpoints for customers, vendors, and administrators to manage food orders, products, users, and system operations.

### Base URL
```
http://0.0.0.0:5000/api/v1
```

### Authentication
- JWT tokens are used for authentication
- Include `Authorization: Bearer <token>` header for protected routes
- Different user roles: `customer`, `vendor`, `admin`

### Rate Limiting
- Authentication endpoints: 5 requests per 15 minutes
- General endpoints: 20-200 requests per 15 minutes (varies by route)
- Upload endpoints: 20 requests per 15 minutes

### Response Format
All responses follow this structure:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {},
  "requestId": "uuid"
}
```

---

## System Endpoints

### Health Check
```http
GET /health
```
**Description:** Check server health status
**Access:** Public
**Response:**
```json
{
  "success": true,
  "message": "Server is healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 1234,
  "environment": "development",
  "version": "1.0.0",
  "requestId": "uuid"
}
```

### API Information
```http
GET /api
```
**Description:** Get API information and available endpoints
**Access:** Public
**Response:**
```json
{
  "success": true,
  "message": "UniNest Backend API",
  "version": "v1",
  "environment": "development",
  "endpoints": {
    "auth": "/api/v1/auth",
    "customer": "/api/v1/customer",
    "vendor": "/api/v1/vendor",
    "admin": "/api/v1/admin",
    "upload": "/api/v1/upload"
  },
  "requestId": "uuid"
}
```

### Log Access
```http
GET /api/logs
```
**Description:** Get recent system logs
**Access:** Public
**Response:**
```json
{
  "success": true,
  "data": [log_entries],
  "count": 100,
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### Real-time Log Streaming
```http
GET /api/logs/stream
```
**Description:** Server-Sent Events for real-time log streaming
**Access:** Public
**Response:** Event stream with log data

---

## Authentication Routes (`/api/v1/auth`)

### Register User
```http
POST /api/v1/auth/register
```
**Description:** Register a new user (customer or vendor)
**Access:** Public
**Rate Limit:** 5 requests/15min
**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "9876543210",
  "role": "customer"
}
```
**Validation:**
- `name`: 2-100 characters, required
- `email`: Valid email format, required
- `password`: Min 6 characters, required
- `phone`: Indian mobile number format, optional
- `role`: "customer" or "vendor", default: "customer"

### Login
```http
POST /api/v1/auth/login
```
**Description:** Authenticate user and get tokens
**Access:** Public
**Rate Limit:** 5 requests/15min
**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

### Refresh Token
```http
POST /api/v1/auth/refresh
```
**Description:** Refresh access token using refresh token
**Access:** Public
**Rate Limit:** 20 requests/15min
**Request Body:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

### Forgot Password
```http
POST /api/v1/auth/forgot-password
```
**Description:** Request password reset email
**Access:** Public
**Rate Limit:** 5 requests/15min
**Request Body:**
```json
{
  "email": "john@example.com"
}
```

### Reset Password
```http
POST /api/v1/auth/reset-password
```
**Description:** Reset password using token
**Access:** Public
**Rate Limit:** 5 requests/15min
**Request Body:**
```json
{
  "token": "reset_token_here",
  "password": "newpassword123"
}
```

### Verify Email
```http
POST /api/v1/auth/verify-email
```
**Description:** Verify email address
**Access:** Public
**Rate Limit:** 20 requests/15min
**Request Body:**
```json
{
  "token": "verification_token_here"
}
```

### Logout
```http
POST /api/v1/auth/logout
```
**Description:** Logout user and invalidate tokens
**Access:** Protected (Any authenticated user)
**Headers:** `Authorization: Bearer <token>`

### Change Password
```http
POST /api/v1/auth/change-password
```
**Description:** Change user password
**Access:** Protected
**Rate Limit:** 20 requests/15min
**Request Body:**
```json
{
  "currentPassword": "oldpassword123",
  "newPassword": "newpassword123"
}
```

### Get Profile
```http
GET /api/v1/auth/profile
```
**Description:** Get user profile information
**Access:** Protected

### Update Profile
```http
PUT /api/v1/auth/profile
```
**Description:** Update user profile
**Access:** Protected
**Rate Limit:** 20 requests/15min
**Request Body:**
```json
{
  "name": "John Doe",
  "phone": "9876543210",
  "avatar": "https://example.com/avatar.jpg"
}
```

### Get Auth Status
```http
GET /api/v1/auth/status
```
**Description:** Check authentication status
**Access:** Protected

### Resend Verification
```http
POST /api/v1/auth/resend-verification
```
**Description:** Resend email verification
**Access:** Protected
**Rate Limit:** 20 requests/15min

### Delete Account
```http
DELETE /api/v1/auth/account
```
**Description:** Delete user account
**Access:** Protected
**Rate Limit:** 20 requests/15min

---

## Customer Routes (`/api/v1/customer`)

*All customer routes require authentication and customer role*

### Get Vendors
```http
GET /api/v1/customer/vendors
```
**Description:** Get list of vendors
**Query Parameters:**
- `category`: canteen, cafe, mess, food_court, restaurant, bakery
- `search`: Search query (max 100 chars)
- `status`: Filter by status (default: approved)
- `sortBy`: rating, name, createdAt (default: rating)
- `order`: asc, desc (default: desc)
- `isOpen`: true/false
- `longitude`: Longitude for location-based search
- `latitude`: Latitude for location-based search
- `maxDistance`: Maximum distance in meters (100-50000)

### Get Nearby Vendors
```http
GET /api/v1/customer/vendors/nearby
```
**Description:** Get vendors near user's location
**Query Parameters:** Same as `/vendors` but requires coordinates

### Get Vendor by ID
```http
GET /api/v1/customer/vendors/:id
```
**Description:** Get detailed vendor information
**Path Parameters:**
- `id`: Vendor ID (MongoDB ObjectId)

### Get Products
```http
GET /api/v1/customer/products
```
**Description:** Get list of products
**Query Parameters:**
- `vendor`: Vendor ID filter
- `category`: breakfast, lunch, dinner, snacks, beverages, desserts, combos
- `search`: Search query (max 100 chars)
- `minPrice`: Minimum price filter
- `maxPrice`: Maximum price filter
- `dietary`: Array of dietary preferences [vegetarian, vegan, glutenFree, dairyFree]
- `rating`: Minimum rating (0-5)
- `sortBy`: rating, price, name, createdAt (default: rating)
- `order`: asc, desc (default: desc)
- `available`: true/false

### Get Featured Products
```http
GET /api/v1/customer/products/featured
```
**Description:** Get featured products
**Query Parameters:** Same as `/products`

### Get Product by ID
```http
GET /api/v1/customer/products/:id
```
**Description:** Get detailed product information
**Path Parameters:**
- `id`: Product ID (MongoDB ObjectId)

### Create Order
```http
POST /api/v1/customer/orders
```
**Description:** Create a new order
**Rate Limit:** 10 requests/15min
**Request Body:**
```json
{
  "vendor": "vendor_id_here",
  "items": [
    {
      "product": "product_id_here",
      "quantity": 2,
      "customizations": [
        {
          "optionId": "option_id_here",
          "choices": ["choice1", "choice2"],
          "specialInstructions": "Extra cheese"
        }
      ],
      "specialInstructions": "No onions please"
    }
  ],
  "delivery": {
    "type": "delivery",
    "address": {
      "street": "123 Main St",
      "city": "Mumbai",
      "state": "Maharashtra",
      "pincode": "400001",
      "landmark": "Near Park",
      "coordinates": [72.8777, 19.0760]
    },
    "instructions": "Ring doorbell twice"
  },
  "paymentMethod": "cash",
  "couponCode": "SAVE10"
}
```
**Validation:**
- At least one item required
- For delivery type, address is required
- Payment method: cash, card, upi, wallet

### Get User Orders
```http
GET /api/v1/customer/orders
```
**Description:** Get customer's order history
**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)
- `status`: Filter by order status

### Get Order by ID
```http
GET /api/v1/customer/orders/:id
```
**Description:** Get specific order details
**Path Parameters:**
- `id`: Order ID (MongoDB ObjectId)

### Cancel Order
```http
PATCH /api/v1/customer/orders/:id/cancel
```
**Description:** Cancel an order
**Request Body:**
```json
{
  "reason": "Changed my mind"
}
```

### Rate Order
```http
POST /api/v1/customer/orders/:id/rate
```
**Description:** Rate and review an order
**Request Body:**
```json
{
  "food": 5,
  "delivery": 4,
  "overall": 5,
  "review": "Great food and fast delivery!"
}
```
**Validation:**
- `food`: 1-5 rating, required
- `delivery`: 1-5 rating, optional
- `overall`: 1-5 rating, required
- `review`: Max 500 characters, optional

### Get Order Statistics
```http
GET /api/v1/customer/orders/stats
```
**Description:** Get customer's order statistics

### Search
```http
GET /api/v1/customer/search
```
**Description:** Search vendors and products
**Rate Limit:** 30 requests/15min
**Query Parameters:**
- `q`: Search query (required, max 100 chars)
- `type`: all, vendors, products (default: all)

### Get Categories
```http
GET /api/v1/customer/categories
```
**Description:** Get available product categories

---

## Vendor Routes (`/api/v1/vendor`)

*All vendor routes require authentication and vendor role*

### Get Profile
```http
GET /api/v1/vendor/profile
```
**Description:** Get vendor profile information

### Update Profile
```http
PUT /api/v1/vendor/profile
```
**Description:** Update vendor profile
**Rate Limit:** 100 requests/15min
**Request Body:**
```json
{
  "vendorName": "Awesome Canteen",
  "description": "Best food in campus",
  "phone": "9876543210",
  "operatingHours": {
    "open": "09:00",
    "close": "22:00",
    "days": ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
  },
  "settings": {
    "enableDelivery": true,
    "enablePickup": true,
    "minOrderAmount": 100,
    "deliveryRadius": 5000
  }
}
```

### Get Products
```http
GET /api/v1/vendor/products
```
**Description:** Get vendor's products
**Rate Limit:** 100 requests/15min
**Query Parameters:**
- `category`: Product category filter
- `available`: true/false
- `search`: Search query (max 100 chars)
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)

### Create Product
```http
POST /api/v1/vendor/products
```
**Description:** Add new product
**Rate Limit:** 100 requests/15min
**Request Body:**
```json
{
  "name": "Butter Chicken",
  "description": "Delicious butter chicken with rice",
  "price": 250,
  "category": "dinner",
  "images": ["https://example.com/image1.jpg"],
  "availability": {
    "isAvailable": true,
    "stock": 50,
    "outOfStockMessage": "Currently out of stock"
  },
  "preparationTime": 20,
  "tags": ["spicy", "popular"],
  "ingredients": ["chicken", "butter", "cream", "spices"],
  "dietaryInfo": {
    "isVegetarian": false,
    "isVegan": false,
    "isGlutenFree": false,
    "containsNuts": false,
    "isDairyFree": false
  },
  "pricing": {
    "basePrice": 250,
    "discount": 10,
    "discountType": "percentage",
    "validUntil": "2024-12-31T23:59:59.000Z"
  }
}
```

### Get Product by ID
```http
GET /api/v1/vendor/products/:id
```
**Description:** Get specific product details

### Update Product
```http
PUT /api/v1/vendor/products/:id
```
**Description:** Update product information
**Rate Limit:** 100 requests/15min
**Request Body:** Same as create product (all fields optional)

### Delete Product
```http
DELETE /api/v1/vendor/products/:id
```
**Description:** Delete a product
**Rate Limit:** 100 requests/15min

### Toggle Product Availability
```http
PATCH /api/v1/vendor/products/:id/availability
```
**Description:** Toggle product availability status
**Rate Limit:** 100 requests/15min

### Get Orders
```http
GET /api/v1/vendor/orders
```
**Description:** Get vendor's orders
**Rate Limit:** 100 requests/15min
**Query Parameters:**
- `status`: Order status filter
- `startDate`: Filter by start date
- `endDate`: Filter by end date
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)

### Get Order by ID
```http
GET /api/v1/vendor/orders/:id
```
**Description:** Get specific order details

### Update Order Status
```http
PUT /api/v1/vendor/orders/:id/status
```
**Description:** Update order status
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "status": "confirmed",
  "notes": "Order confirmed, preparing now"
}
```
**Status Options:** confirmed, preparing, ready, out_for_delivery, delivered, cancelled

### Get Analytics
```http
GET /api/v1/vendor/analytics
```
**Description:** Get vendor analytics
**Rate Limit:** 100 requests/15min
**Query Parameters:**
- `period`: daily, weekly, monthly (default: daily)
- `startDate`: Custom start date
- `endDate`: Custom end date

### Get Dashboard Stats
```http
GET /api/v1/vendor/dashboard
```
**Description:** Get vendor dashboard statistics

---

## Admin Routes (`/api/v1/admin`)

*All admin routes require authentication and admin role*

### User Management

#### Get Users
```http
GET /api/v1/admin/users
```
**Description:** Get all users
**Rate Limit:** 200 requests/15min
**Query Parameters:**
- `role`: customer, vendor, admin
- `isActive`: true/false
- `emailVerified`: true/false
- `search`: Search query (max 100 chars)
- `startDate`: Filter by start date
- `endDate`: Filter by end date
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)

#### Get User by ID
```http
GET /api/v1/admin/users/:id
```
**Description:** Get specific user details

#### Update User
```http
PUT /api/v1/admin/users/:id
```
**Description:** Update user information
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "name": "John Doe",
  "phone": "9876543210",
  "avatar": "https://example.com/avatar.jpg",
  "isActive": true,
  "role": "customer"
}
```

#### Delete User
```http
DELETE /api/v1/admin/users/:id
```
**Description:** Delete user account
**Rate Limit:** 50 requests/15min

### Vendor Management

#### Get Vendors
```http
GET /api/v1/admin/vendors
```
**Description:** Get all vendors
**Rate Limit:** 200 requests/15min
**Query Parameters:**
- `status`: pending, approved, rejected, suspended
- `category`: canteen, cafe, mess, food_court, restaurant, bakery
- `search`: Search query (max 100 chars)
- `minRating`: Minimum rating filter
- `maxRating`: Maximum rating filter
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)

#### Get Vendor by ID
```http
GET /api/v1/admin/vendors/:id
```
**Description:** Get specific vendor details

#### Update Vendor Status
```http
PUT /api/v1/admin/vendors/:id/status
```
**Description:** Update vendor status
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "status": "approved",
  "rejectionReason": "Does not meet requirements",
  "suspensionReason": "Policy violation"
}
```

### Order Management

#### Get Orders
```http
GET /api/v1/admin/orders
```
**Description:** Get all orders
**Rate Limit:** 200 requests/15min
**Query Parameters:**
- `status`: Order status filter
- `paymentStatus`: Payment status filter
- `vendorId`: Filter by vendor
- `userId`: Filter by customer
- `startDate`: Filter by start date
- `endDate`: Filter by end date
- `minTotal`: Minimum total amount
- `maxTotal`: Maximum total amount
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)

#### Get Order by ID
```http
GET /api/v1/admin/orders/:id
```
**Description:** Get specific order details

### Analytics

#### Get Analytics
```http
GET /api/v1/admin/analytics
```
**Description:** Get system analytics
**Rate Limit:** 200 requests/15min
**Query Parameters:**
- `type`: daily_sales, vendor_performance, user_activity, popular_products, order_metrics, revenue_summary, customer_retention, peak_hours, category_performance, payment_methods
- `period`: daily, weekly, monthly (default: daily)
- `startDate`: Custom start date
- `endDate`: Custom end date
- `vendorId`: Filter by specific vendor

#### Get Dashboard
```http
GET /api/v1/admin/dashboard
```
**Description:** Get admin dashboard statistics

### Notification Management

#### Get Notifications
```http
GET /api/v1/admin/notifications
```
**Description:** Get all notifications
**Rate Limit:** 200 requests/15min
**Query Parameters:**
- `type`: Notification type filter
- `priority`: low, medium, high, urgent
- `status`: sent, pending, draft
- `recipientRole`: customer, vendor, admin
- `startDate`: Filter by start date
- `endDate`: Filter by end date
- `search`: Search query (max 100 chars)
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)

#### Get Notification by ID
```http
GET /api/v1/admin/notifications/:id
```
**Description:** Get specific notification details

#### Create Notification
```http
POST /api/v1/admin/notifications
```
**Description:** Create new notification
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "type": "promotion",
  "title": "Special Offer!",
  "message": "Get 20% off on all orders today",
  "recipients": ["user_id_1", "user_id_2"],
  "recipientRole": "customer",
  "priority": "high",
  "data": {},
  "actionUrl": "https://example.com/offers",
  "actionText": "View Offers"
}
```

#### Update Notification
```http
PUT /api/v1/admin/notifications/:id
```
**Description:** Update notification
**Rate Limit:** 50 requests/15min

#### Delete Notification
```http
DELETE /api/v1/admin/notifications/:id
```
**Description:** Delete notification
**Rate Limit:** 50 requests/15min

#### Send Notification
```http
POST /api/v1/admin/notifications/send
```
**Description:** Send notification to users
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "notificationId": "notification_id_here",
  "recipients": ["user_id_1", "user_id_2"],
  "recipientRole": "customer",
  "sendImmediately": true,
  "scheduledAt": "2024-01-01T12:00:00.000Z"
}
```

### Offers Management

#### Get Offers
```http
GET /api/v1/admin/offers
```
**Description:** Get all offers
**Rate Limit:** 200 requests/15min

#### Create Offer
```http
POST /api/v1/admin/offers
```
**Description:** Create new offer
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "title": "Weekend Special",
  "description": "Get 25% off on all items",
  "type": "percentage",
  "discount": 25,
  "minOrderAmount": 200,
  "maxDiscount": 100,
  "startDate": "2024-01-01T00:00:00.000Z",
  "endDate": "2024-01-07T23:59:59.000Z",
  "applicableItems": ["product_id_1", "product_id_2"],
  "usageLimit": 1000,
  "isActive": true
}
```

#### Update Offer
```http
PUT /api/v1/admin/offers/:id
```
**Description:** Update offer
**Rate Limit:** 50 requests/15min

#### Delete Offer
```http
DELETE /api/v1/admin/offers/:id
```
**Description:** Delete offer
**Rate Limit:** 50 requests/15min

### Product Management

#### Get Products
```http
GET /api/v1/admin/products
```
**Description:** Get all products
**Rate Limit:** 200 requests/15min
**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)
- `category`: Product category filter
- `status`: active, inactive
- `search`: Search query (max 100 chars)
- `vendorId`: Filter by vendor
- `sort`: Sort field (default: createdAt)
- `order`: asc, desc (default: desc)

#### Get Product by ID
```http
GET /api/v1/admin/products/:id
```
**Description:** Get specific product details

#### Create Product
```http
POST /api/v1/admin/products
```
**Description:** Create new product
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "name": "Product Name",
  "description": "Product description",
  "price": 100,
  "categoryId": "category_id_here",
  "vendorId": "vendor_id_here",
  "imageUrl": "https://example.com/image.jpg",
  "status": "active",
  "isAvailable": true,
  "preparationTime": 15,
  "ingredients": ["ingredient1", "ingredient2"],
  "tags": ["tag1", "tag2"]
}
```

#### Update Product
```http
PUT /api/v1/admin/products/:id
```
**Description:** Update product
**Rate Limit:** 50 requests/15min

#### Update Product Status
```http
PATCH /api/v1/admin/products/:id/status
```
**Description:** Update product active status
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "isActive": true
}
```

#### Delete Product
```http
DELETE /api/v1/admin/products/:id
```
**Description:** Delete product
**Rate Limit:** 50 requests/15min

### Categories
```http
GET /api/v1/admin/categories
```
**Description:** Get all product categories
**Rate Limit:** 200 requests/15min

### System Management

#### Get System Health
```http
GET /api/v1/admin/health
```
**Description:** Get system health metrics

#### Bulk Operations
```http
POST /api/v1/admin/bulk-operations
```
**Description:** Perform bulk operations on users or vendors
**Rate Limit:** 50 requests/15min
**Request Body:**
```json
{
  "action": "activate",
  "targetType": "users",
  "targetIds": ["user_id_1", "user_id_2"],
  "reason": "Bulk activation"
}
```

#### Generate Report
```http
POST /api/v1/admin/reports
```
**Description:** Generate system reports
**Rate Limit:** 200 requests/15min
**Request Body:**
```json
{
  "type": "sales",
  "period": "monthly",
  "startDate": "2024-01-01T00:00:00.000Z",
  "endDate": "2024-01-31T23:59:59.000Z",
  "format": "json",
  "includeDetails": false
}
```

---

## Upload Routes (`/api/v1/upload`)

*All upload routes require authentication*

### Upload Product Image
```http
POST /api/v1/upload/product-image
```
**Description:** Upload product image (vendor only)
**Rate Limit:** 20 requests/15min
**Access:** Vendor
**Request:** `multipart/form-data`
- `image`: Image file (max 10MB)

### Upload Vendor Images
```http
POST /api/v1/upload/vendor-images
```
**Description:** Upload multiple vendor images (vendor only)
**Rate Limit:** 20 requests/15min
**Access:** Vendor
**Request:** `multipart/form-data`
- `images`: Array of image files (max 5 files, 10MB each)

### Upload Avatar
```http
POST /api/v1/upload/avatar
```
**Description:** Upload user avatar
**Rate Limit:** 20 requests/15min
**Access:** All authenticated users
**Request:** `multipart/form-data`
- `avatar`: Avatar image file (max 10MB)

### Get File Info
```http
GET /api/v1/upload/file/:filename
```
**Description:** Get file information
**Access:** All authenticated users

### Delete File
```http
DELETE /api/v1/upload/file/:filename
```
**Description:** Delete uploaded file
**Access:** All authenticated users

### Get Upload Statistics
```http
GET /api/v1/upload/stats
```
**Description:** Get upload statistics
**Access:** Admin only

### Clean Up Old Files
```http
DELETE /api/v1/upload/cleanup
```
**Description:** Clean up old uploaded files
**Access:** Admin only

---

## Error Handling

### Error Response Format
```json
{
  "success": false,
  "message": "Error message",
  "error": {
    "code": "ERROR_CODE",
    "details": "Additional error details"
  },
  "requestId": "uuid"
}
```

### Common HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `422` - Validation Error
- `429` - Too Many Requests
- `500` - Internal Server Error

### Validation Errors
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format",
      "code": "invalid_string"
    }
  ],
  "requestId": "uuid"
}
```

---

## WebSocket Events



### Connection
```javascript
const socket = io('http://0.0.0.0:5000');
```

### Order Events
- `order:created` - New order created
- `order:updated` - Order status updated
- `order:cancelled` - Order cancelled

### Notification Events
- `notification:new` - New notification received
- `notification:read` - Notification marked as read

### Real-time Updates
- `vendor:status` - Vendor status changes
- `product:availability` - Product availability changes

---

## Security Features

### Rate Limiting
- Different limits per endpoint type
- IP-based rate limiting
- Time window: 15 minutes

### Authentication
- JWT tokens with expiration
- Refresh token mechanism
- Role-based access control

### Validation
- Zod schema validation
- Input sanitization
- SQL injection prevention

### Security Headers
- Helmet.js for security headers
- CORS configuration
- CSP policies

---

## Development Information

### Environment Variables
```env
NODE_ENV=development
PORT=5000
MONGODB_URI=mongodb://0.0.0.0:27017/uninest
JWT_SECRET=your_jwt_secret
JWT_REFRESH_SECRET=your_refresh_secret
CORS_ORIGIN=http://0.0.0.0:3000
```

### Default Admin Account
- Email: admin@uninest.com
- Password: admin123
- Role: admin

### Database Models
- User (customers, vendors, admins)
- Vendor (vendor profiles)
- Product (menu items)
- Order (customer orders)
- Notification (system notifications)
- Category (product categories)

### Technologies Used
- Node.js with Express
- MongoDB with Mongoose
- JWT for authentication
- Socket.io for real-time features
- Multer for file uploads
- Zod for validation
- Winston for logging
- Helmet for security

---

## API Testing

### Example cURL Commands

#### Register User
```bash
curl -X POST http://0.0.0.0:5000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "role": "customer"
  }'
```

#### Login
```bash
curl -X POST http://0.0.0.0:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

#### Get Products (Authenticated)
```bash
curl -X GET http://0.0.0.0:5000/api/v1/customer/products \
  -H "Authorization: Bearer <token>"
```

#### Create Order
```bash
curl -X POST http://0.0.0.0:5000/api/v1/customer/orders \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "vendor": "vendor_id_here",
    "items": [
      {
        "product": "product_id_here",
        "quantity": 1
      }
    ],
    "delivery": {
      "type": "pickup"
    },
    "paymentMethod": "cash"
  }'
```

---

## Support

For any issues or questions regarding the API, please contact the development team or refer to the project repository.

---

*Last Updated: January 2024*
*Version: 1.0.0*
