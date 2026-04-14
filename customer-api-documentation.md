# UniNest Customer API Documentation

## Base URL
```
http://localhost:{PORT}/api
```

## Authentication

All customer APIs (except registration and login) require JWT Bearer token authentication:
```
Authorization: Bearer {token}
```

---

## 1. Authentication Endpoints

### 1.1 Register Customer
**Endpoint:** `POST /api/customer/auth/register`

**Request Body:**
```json
{
  "name": "string (required, max 50 chars)",
  "email": "string (required, valid email)",
  "password": "string (required, min 6 chars)",
  "phone": "string (required, 10 digits)"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Customer registered successfully",
  "data": {
    "user": {
      "_id": "string",
      "name": "string",
      "email": "string",
      "phone": "string",
      "role": "customer",
      "isBlocked": false,
      "isActive": true,
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    },
    "token": "jwt_token_string"
  }
}
```

**Error Codes:**
- `400`: User already exists, validation errors

---

### 1.2 Login Customer
**Endpoint:** `POST /api/customer/auth/login`

**Request Body:**
```json
{
  "email": "string (required, valid email)",
  "password": "string (required)"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Customer login successful",
  "data": {
    "user": {
      "_id": "string",
      "name": "string",
      "email": "string",
      "phone": "string",
      "role": "customer",
      "isBlocked": false,
      "isActive": true,
      "lastLogin": "timestamp",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    },
    "token": "jwt_token_string"
  }
}
```

**Error Codes:**
- `401`: Invalid credentials, account blocked, account inactive

---

### 1.3 Change Password
**Endpoint:** `POST /api/customer/auth/change-password`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "currentPassword": "string (required)",
  "newPassword": "string (required, min 6 chars)"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

## 2. Profile Endpoints

### 2.1 Get Customer Profile
**Endpoint:** `GET /api/customer/profile`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "_id": "string",
    "name": "string",
    "email": "string",
    "phone": "string",
    "role": "customer",
    "avatar": "string (URL)",
    "isBlocked": false,
    "isActive": true,
    "emailVerified": false,
    "lastLogin": "timestamp",
    "addresses": [
      {
        "type": "home|work|other",
        "address": "string",
        "landmark": "string",
        "isDefault": true
      }
    ],
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

---

### 2.2 Update Customer Profile
**Endpoint:** `PUT /api/customer/profile`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "name": "string (optional, non-empty)",
  "phone": "string (optional, 10 digits)",
  "avatar": "string (optional, valid URL)",
  "addresses": [
    {
      "type": "home|work|other",
      "address": "string",
      "landmark": "string",
      "isDefault": "boolean"
    }
  ]
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "_id": "string",
    "name": "string",
    "email": "string",
    "phone": "string",
    "avatar": "string",
    "addresses": [...],
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

---

## 3. Product Endpoints (Public - No Auth Required)

### 3.1 Get Public Products
**Endpoint:** `GET /api/public/products`

**Query Parameters:**
- `q` - Search query string (optional)
- `category` - Filter by category (optional)
- `vendor` - Filter by vendor ID (optional)
- `featured` - "true" to get featured products only (optional)
- `limit` - Number of results (default: 50, max: 100)
- `skip` - Skip for pagination (default: 0)

**Response (200):**
```json
{
  "success": true,
  "message": "Products retrieved",
  "data": [
    {
      "_id": "string",
      "name": "string",
      "description": "string",
      "price": 0.00,
      "category": "string",
      "vendor": "vendor_object",
      "images": [
        {
          "url": "string",
          "alt": "string"
        }
      ],
      "status": "pending|approved|rejected",
      "availability": "in_stock|out_of_stock",
      "stock": 0,
      "isFeatured": false,
      "isVisible": true,
      "primaryImage": {
        "url": "string",
        "alt": "string"
      },
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  ]
}
```

---

### 3.2 Search Public Products
**Endpoint:** `GET /api/public/search`

**Query Parameters:**
- `q` - Search query string (optional)
- `category` - Filter by category (optional)
- `vendor` - Filter by vendor ID (optional)
- `featured` - "true" to get featured products only (optional)
- `limit` - Number of results (default: 20, max: 100)
- `skip` - Skip for pagination (default: 0)

**Response:** Same as Get Public Products

---

## 4. Order Endpoints

### 4.1 Create Order
**Endpoint:** `POST /api/customer/orders`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "items": [
    {
      "productId": "string (MongoDB ObjectId, required)",
      "productVendor": "string (optional, MongoDB ObjectId)",
      "quantity": 1,
      "customizations": [
        {
          "name": "string",
          "option": "string",
          "price": 0
        }
      ]
    }
  ],
  "deliveryAddress": {
    "address": "string (required)",
    "type": "campus|hostel|canteen|off-campus|home|work|other",
    "landmark": "string",
    "location": {
      "building": "string",
      "room": "string",
      "floor": "string"
    }
  },
  "paymentMethod": "cod|card|upi|wallet",
  "fulfillmentType": "delivery|takeaway (default: delivery)",
  "offerCode": "string (optional, max 50 chars)"
}
```

**Response (201) - COD Order:**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "_id": "string",
    "orderNumber": "ORDXXXXXX",
    "customer": "string",
    "vendor": "string",
    "items": [...],
    "status": "confirmed",
    "paymentStatus": "cod_pending",
    "paymentMethod": "cod",
    "totalAmount": 0.00,
    "discountAmount": 0.00,
    "deliveryFee": 0.00,
    "taxAmount": 0.00,
    "finalAmount": 0.00,
    "pricing": {...},
    "deliveryAddress": {...},
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

**Response (201) - Online Payment Order:**
```json
{
  "success": true,
  "message": "Order created. Complete Razorpay payment to confirm it",
  "data": {
    "_id": "string",
    "orderNumber": "ORDXXXXXX",
    "status": "pending",
    "paymentStatus": "pending",
    "paymentMethod": "card|upi|wallet",
    "payment": {
      "gateway": "razorpay",
      "keyId": "string",
      "currency": "INR",
      "amount": 100,
      "amountInRupees": 1.00,
      "orderId": "razorpay_order_id",
      "receipt": "string",
      "customer": {
        "name": "string",
        "email": "string",
        "contact": "string"
      }
    }
  }
}
```

---

### 4.2 Checkout (Alias for Create Order)
**Endpoint:** `POST /api/customer/orders/checkout`

Same as Create Order endpoint.

---

### 4.3 Create Razorpay Payment Order
**Endpoint:** `POST /api/customer/orders/:id/payment/razorpay-order`

**Headers:**
```
Authorization: Bearer {token}
```

**URL Parameters:**
- `id` - Order ID (MongoDB ObjectId) or Order Number (starts with ORD)

**Response (200):**
```json
{
  "success": true,
  "message": "Razorpay order created successfully",
  "data": {
    "orderId": "string",
    "orderNumber": "ORDXXXXXX",
    "payment": {
      "gateway": "razorpay",
      "keyId": "string",
      "currency": "INR",
      "amount": 100,
      "amountInRupees": 1.00,
      "orderId": "razorpay_order_id",
      "receipt": "string",
      "customer": {
        "name": "string",
        "email": "string",
        "contact": "string"
      }
    }
  }
}
```

---

### 4.4 Verify Razorpay Payment
**Endpoint:** `POST /api/customer/orders/:id/payment/verify`

**Headers:**
```
Authorization: Bearer {token}
```

**URL Parameters:**
- `id` - Order ID (MongoDB ObjectId) or Order Number (starts with ORD)

**Request Body:**
```json
{
  "razorpayOrderId": "string (required)",
  "razorpayPaymentId": "string (required)",
  "razorpaySignature": "string (required)"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "data": {
    "_id": "string",
    "orderNumber": "ORDXXXXXX",
    "status": "confirmed",
    "paymentStatus": "paid",
    "paidAt": "timestamp",
    "paymentId": "string",
    ...
  }
}
```

---

### 4.5 Get Customer Orders
**Endpoint:** `GET /api/customer/orders`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `page` - Page number (default: 1, min: 1)
- `limit` - Items per page (default: 10, max: 50)
- `status` - Filter by status: `pending|confirmed|preparing|ready|out_for_delivery|delivered|cancelled|refunded`
- `sortBy` - Sort field: `createdAt|finalAmount|status` (default: createdAt)
- `sortOrder` - Sort order: `asc|desc` (default: desc)

**Response (200):**
```json
{
  "success": true,
  "message": "Orders retrieved successfully",
  "data": {
    "orders": [
      {
        "_id": "string",
        "orderNumber": "ORDXXXXXX",
        "vendor": {
          "businessName": "string",
          "location": {...},
          "contactInfo": {...}
        },
        "items": [
          {
            "product": {
              "name": "string",
              "images": [...]
            },
            "name": "string",
            "price": 0.00,
            "quantity": 1,
            "subtotal": 0.00
          }
        ],
        "status": "string",
        "paymentStatus": "string",
        "paymentMethod": "string",
        "finalAmount": 0.00,
        "createdAt": "timestamp"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 100,
      "pages": 10
    }
  }
}
```

---

### 4.6 Get Order by ID
**Endpoint:** `GET /api/customer/orders/:id`

**Headers:**
```
Authorization: Bearer {token}
```

**URL Parameters:**
- `id` - Order ID (MongoDB ObjectId) or Order Number (starts with ORD)

**Response (200):**
```json
{
  "success": true,
  "message": "Order retrieved successfully",
  "data": {
    "_id": "string",
    "orderNumber": "ORDXXXXXX",
    "customer": "string",
    "vendor": {
      "businessName": "string",
      "location": {...},
      "contactInfo": {...},
      "businessHours": {...}
    },
    "items": [
      {
        "product": {
          "name": "string",
          "images": [...],
          "description": "string",
          "customizations": [...]
        },
        "name": "string",
        "price": 0.00,
        "quantity": 1,
        "customizations": [...],
        "subtotal": 0.00
      }
    ],
    "status": "string",
    "paymentStatus": "string",
    "paymentMethod": "string",
    "totalAmount": 0.00,
    "discountAmount": 0.00,
    "deliveryFee": 0.00,
    "taxAmount": 0.00,
    "finalAmount": 0.00,
    "pricing": {...},
    "deliveryAddress": {...},
    "estimatedDeliveryTime": "timestamp",
    "timeline": [
      {
        "status": "string",
        "timestamp": "timestamp",
        "note": "string",
        "updatedBy": {...}
      }
    ],
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

---

### 4.7 Cancel Order
**Endpoint:** `PUT /api/customer/orders/:id/cancel`

**Headers:**
```
Authorization: Bearer {token}
```

**URL Parameters:**
- `id` - Order ID (MongoDB ObjectId) or Order Number (starts with ORD)

**Request Body:**
```json
{
  "reason": "string (optional, max 200 chars)"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Order cancelled successfully",
  "data": {
    "_id": "string",
    "orderNumber": "ORDXXXXXX",
    "status": "cancelled",
    "cancellation": {
      "cancelledAt": "timestamp",
      "cancelledBy": "string",
      "reason": "string"
    }
  }
}
```

**Note:** Orders can only be cancelled if status is one of: `pending`, `confirmed`, `preparing`, `ready`

---

### 4.8 Track Order
**Endpoint:** `GET /api/customer/orders/:id/track`

**Headers:**
```
Authorization: Bearer {token}
```

**URL Parameters:**
- `id` - Order ID (MongoDB ObjectId) or Order Number (starts with ORD)

**Response (200):**
```json
{
  "success": true,
  "message": "Order tracking retrieved successfully",
  "data": {
    "_id": "string",
    "orderNumber": "ORDXXXXXX",
    "status": "string",
    "timeline": [...],
    "estimatedDeliveryTime": "timestamp",
    "deliveryPartner": {
      "name": "string",
      "phone": "string",
      "vehicleNumber": "string"
    },
    "trackingLink": "string"
  }
}
```

---

## 5. Review Endpoints

### 5.1 Add Review for Order
**Endpoint:** `POST /api/customer/orders/:orderId/review`

**Headers:**
```
Authorization: Bearer {token}
```

**URL Parameters:**
- `orderId` - Order ID (MongoDB ObjectId) or Order Number (starts with ORD)

**Request Body:**
```json
{
  "rating": {
    "food": 5,
    "delivery": 5,
    "experience": 5
  },
  "comment": "string (optional, max 500 chars)",
  "images": ["string (URLs)"]
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Review added successfully"
}
```

**Note:** Order must have status `delivered` and not already reviewed.

---

## 6. Notification Endpoints

### 6.1 Get Customer Notifications
**Endpoint:** `GET /api/customer/notifications`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `page` - Page number (default: 1, min: 1)
- `limit` - Items per page (default: 20, max: 50)
- `isRead` - Filter by read status: `true|false`
- `type` - Filter by type: `order|payment|review|system|promotion|account_alert`

**Response (200):**
```json
{
  "success": true,
  "message": "Notifications retrieved successfully",
  "data": {
    "notifications": [
      {
        "_id": "string",
        "recipient": "string",
        "recipientRole": "customer",
        "type": "order|payment|review|system|promotion|account_alert",
        "title": "string",
        "message": "string",
        "isRead": false,
        "data": {
          "orderId": "string",
          "orderNumber": "string"
        },
        "createdAt": "timestamp"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "pages": 5
    }
  }
}
```

---

### 6.2 Mark All Notifications as Read
**Endpoint:** `PUT /api/customer/notifications/read`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Notifications marked as read"
}
```

---

## Data Models

### User Model
```json
{
  "_id": "MongoDB ObjectId",
  "name": "String (max 50 chars)",
  "email": "String (unique)",
  "password": "String (hashed, min 6 chars)",
  "role": "customer|vendor|admin",
  "phone": "String (10 digits)",
  "avatar": "String (URL)",
  "isBlocked": "Boolean",
  "isActive": "Boolean",
  "emailVerified": "Boolean",
  "lastLogin": "Date",
  "addresses": [
    {
      "type": "home|work|other",
      "address": "String",
      "landmark": "String",
      "isDefault": "Boolean"
    }
  ],
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

### Product Model
```json
{
  "_id": "MongoDB ObjectId",
  "name": "String (max 150 chars)",
  "description": "String (max 1000 chars)",
  "price": "Number",
  "category": "String (max 50 chars)",
  "vendor": "Vendor ObjectId",
  "images": [{ "url": "String", "alt": "String" }],
  "status": "pending|approved|rejected",
  "availability": "in_stock|out_of_stock",
  "stock": "Number",
  "isFeatured": "Boolean",
  "changeLogs": [...],
  "createdAt": "Date",
  "updatedAt": "Date",
  "isVisible": "Boolean (virtual)",
  "primaryImage": "Object (virtual)"
}
```

### Order Model
```json
{
  "_id": "MongoDB ObjectId",
  "orderNumber": "String (unique, format: ORDXXXXXX)",
  "customer": "User ObjectId",
  "vendor": "Vendor ObjectId",
  "items": [
    {
      "product": "Product ObjectId",
      "name": "String",
      "price": "Number",
      "quantity": "Number",
      "customizations": [{ "name": "String", "option": "String", "price": "Number" }],
      "subtotal": "Number"
    }
  ],
  "fulfillmentType": "delivery|takeaway",
  "totalAmount": "Number",
  "discountAmount": "Number",
  "deliveryFee": "Number",
  "taxAmount": "Number",
  "finalAmount": "Number",
  "status": "pending|confirmed|preparing|ready|out_for_delivery|delivered|cancelled|refunded",
  "paymentStatus": "pending|paid|failed|refund_pending|refunded|cod_pending|cod_collected",
  "paymentMethod": "cod|card|upi|wallet",
  "paymentGateway": "razorpay",
  "paymentId": "String",
  "pricing": { "detailed pricing breakdown" },
  "deliveryAddress": {
    "type": "campus|hostel|canteen|off-campus|home|work|other",
    "address": "String",
    "landmark": "String",
    "location": { "building": "String", "room": "String", "floor": "String" },
    "coordinates": { "latitude": "Number", "longitude": "Number" }
  },
  "timeline": [
    { "status": "String", "timestamp": "Date", "note": "String", "updatedBy": "User ObjectId" }
  ],
  "rating": { "food": "Number (1-5)", "delivery": "Number (1-5)", "experience": "Number (1-5)", "comment": "String", "images": ["String"] },
  "isReviewed": "Boolean",
  "createdAt": "Date",
  "updatedAt": "Date"
}
```

---

## Order Status Flow

```
pending → confirmed → preparing → ready → out_for_delivery → delivered
   ↓
cancelled
```

### Status Definitions:
- `pending` - Order created but payment not confirmed (online) or awaiting vendor acceptance
- `confirmed` - Order confirmed and accepted by vendor
- `preparing` - Vendor is preparing the order
- `ready` - Order is ready for pickup/delivery
- `out_for_delivery` - Order is out for delivery
- `delivered` - Order delivered to customer
- `cancelled` - Order cancelled by customer/vendor
- `refunded` - Order refunded

---

## Payment Status Flow

### Online Payments:
```
pending → paid (success) OR failed (failure)
         ↓
    refund_pending → refunded
```

### Cash on Delivery (COD):
```
cod_pending → cod_collected
```

---

## Error Response Format

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message (optional)"
}
```

### Common HTTP Status Codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Internal Server Error

---

## Socket.IO Events (Real-time)

The backend supports Socket.IO for real-time notifications.

### Connection:
```javascript
const socket = io('ws://localhost:{PORT}');

// Join personal room
socket.emit('join', userId);

// Listen for notifications
socket.on('notification', (data) => {
  console.log('New notification:', data);
});
```

### Events:
- `notification` - New notification received
- `order_update` - Order status update
- `payment_update` - Payment status update

---

## Flutter Implementation Notes

### 1. HTTP Client Setup
Use `dio` package with interceptors for automatic token handling:

```dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:PORT/api',
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
  ));

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken(); // Get from secure storage
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }
}
```

### 2. Token Storage
Use `flutter_secure_storage` to store JWT tokens securely:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'token', value: token);
String? token = await storage.read(key: 'token');
```

### 3. Razorpay Integration
For online payments, use the `razorpay_flutter` package:

```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';

void openRazorpay(Map<String, dynamic> paymentData) {
  var options = {
    'key': paymentData['keyId'],
    'amount': paymentData['amount'],
    'order_id': paymentData['orderId'],
    'name': 'UniNest',
    'description': 'Order Payment',
    'prefill': {
      'contact': paymentData['customer']['contact'],
      'email': paymentData['customer']['email'],
      'name': paymentData['customer']['name'],
    },
  };
  
  _razorpay.open(options);
}

// Handle success
_razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
  // Call verify payment API
  verifyPayment(response.orderId, response.paymentId, response.signature);
});
```

### 4. Pagination Handling
For paginated lists (orders, notifications):

```dart
Future<List<Order>> fetchOrders({int page = 1, int limit = 10}) async {
  final response = await _dio.get('/customer/orders?page=$page&limit=$limit');
  final data = response.data['data'];
  return {
    'orders': (data['orders'] as List).map((o) => Order.fromJson(o)).toList(),
    'pagination': data['pagination'],
  };
}
```

### 5. Models
Create Dart models with `json_serializable`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final String id;
  final String orderNumber;
  final String status;
  final double finalAmount;
  
  Order({required this.id, required this.orderNumber, required this.status, required this.finalAmount});
  
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
```
