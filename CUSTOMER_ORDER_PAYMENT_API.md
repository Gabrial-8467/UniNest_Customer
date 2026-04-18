# Customer Order & Payment API Documentation

## Base URL
```
/api/customer
```

All endpoints require **Bearer Token Authentication** in the Authorization header:
```
Authorization: Bearer <token>
```

---

## 1. Create Order

**Endpoint:** `POST /api/customer/orders`  
**Auth:** Required

### Request Body
```json
{
  "items": [
    {
      "productId": "69ddbf386982ae90c03c3dd2",
      "quantity": 1,
      "customizations": []
    }
  ],
  "paymentMethod": "cod|razorpay",
  "deliveryAddress": {
    "address": "Block A, Room 210, 2 Floor",
    "addressType": "campus",
    "location": {
      "building": "Block A",
      "room": "210",
      "floor": "2"
    }
  },
  "fulfillmentType": "delivery|takeaway",
  "offerCode": "optional"
}
```

### Response (Success - 200)
```json
{
  "success": true,
  "data": {
    "orderNumber": "ORD123456",
    "_id": "...",
    "status": "pending",
    "finalAmount": 150.00,
    "paymentStatus": "pending"
  }
}
```

### Response (Error - 400)
```json
{
  "success": false,
  "message": "Validation error message",
  "timestamp": "2026-04-17T16:59:46.265Z"
}
```

---

## 2. Create Razorpay Payment Order

**Endpoint:** `POST /api/customer/orders/:id/payment/razorpay-order`  
**Auth:** Required

### URL Parameters
| Param | Description | Example |
|-------|-------------|---------|
| `:id` | Order Number or MongoDB ObjectId | `ORD123456` or `69ddbf386982ae90c03c3dd2` |

### Response (Success - 200)
```json
{
  "success": true,
  "data": {
    "payment": {
      "orderId": "order_razorpay_id",
      "amount": 15000,
      "key": "rzp_test_..."
    }
  }
}
```

**Note:** `amount` is in **paise** (smallest currency unit). Divide by 100 to get rupees.

---

## 3. Verify Razorpay Payment

**Endpoint:** `POST /api/customer/orders/:id/payment/verify`  
**Auth:** Required

### Request Body
```json
{
  "razorpayOrderId": "order_xxx",
  "razorpayPaymentId": "pay_xxx",
  "razorpaySignature": "signature_hash"
}
```

### Response (Success - 200)
```json
{
  "success": true,
  "data": {
    "orderNumber": "ORD123456",
    "status": "confirmed",
    "paymentStatus": "paid"
  }
}
```

---

## 4. Get Customer Orders

**Endpoint:** `GET /api/customer/orders`  
**Auth:** Required

### Query Parameters
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `page` | integer | No | Page number (min: 1) |
| `limit` | integer | No | Items per page (1-50) |
| `status` | string | No | Filter by status: `pending`, `confirmed`, `preparing`, `ready`, `out_for_delivery`, `delivered`, `cancelled`, `refunded` |
| `sortBy` | string | No | Sort field: `createdAt`, `finalAmount`, `status` |
| `sortOrder` | string | No | `asc` or `desc` |

---

## 5. Get Order by ID

**Endpoint:** `GET /api/customer/orders/:id`  
**Auth:** Required

### URL Parameters
| Param | Description | Example |
|-------|-------------|---------|
| `:id` | Order Number or MongoDB ObjectId | `ORD123456` or `69ddbf386982ae90c03c3dd2` |

---

## 6. Cancel Order

**Endpoint:** `PUT /api/customer/orders/:id/cancel`  
**Auth:** Required

### URL Parameters
| Param | Description | Example |
|-------|-------------|---------|
| `:id` | Order Number or MongoDB ObjectId | `ORD123456` |

### Request Body (Optional)
```json
{
  "reason": "Customer requested cancellation"
}
```

---

## 7. Track Order

**Endpoint:** `GET /api/customer/orders/:id/track`  
**Auth:** Required

### URL Parameters
| Param | Description | Example |
|-------|-------------|---------|
| `:id` | Order Number or MongoDB ObjectId | `ORD123456` |

---

## 8. Add Review

**Endpoint:** `POST /api/customer/orders/:orderId/review`  
**Auth:** Required

### Request Body
```json
{
  "rating": {
    "food": 5,
    "delivery": 4,
    "experience": 5
  },
  "comment": "Great food!",
  "images": []
}
```

### Field Validations
| Field | Type | Min | Max |
|-------|------|-----|-----|
| `rating.food` | integer | 1 | 5 |
| `rating.delivery` | integer | 1 | 5 |
| `rating.experience` | integer | 1 | 5 |
| `comment` | string | - | 500 chars |
| `images` | array | - | - |

---

## Field Validations Reference

| Field | Rules |
|-------|-------|
| `paymentMethod` | **Required.** Must be `cod` or `razorpay` (lowercase only) |
| `items` | **Required.** Array with at least 1 item |
| `items.*.productId` | **Required.** Valid MongoDB ObjectId (24 hex chars) |
| `items.*.quantity` | **Required.** Integer ≥ 1. Accepts number or string numbers |
| `items.*.customizations` | Optional. Must be array |
| `deliveryAddress.address` | **Required.** Non-empty string |
| `deliveryAddress.addressType` | **Required.** Enum: `campus`, `hostel`, `canteen`, `off-campus`, `home`, `work`, `other` |
| `deliveryAddress.location` | Optional. Object with optional `building`, `room`, `floor` (all strings) |
| `fulfillmentType` | Optional. `delivery` or `takeaway`. Default: `delivery` |
| `offerCode` | Optional. Max 50 characters |

---

## Razorpay Payment Flow

### Step 1: Create Order
```http
POST /api/customer/orders
```
Response returns `orderNumber` (e.g., `ORD123456`).

### Step 2: Create Razorpay Order
```http
POST /api/customer/orders/ORD123456/payment/razorpay-order
```
Response returns:
- `orderId` - Razorpay order ID
- `amount` - Amount in paise
- `key` - Razorpay API key

### Step 3: Open Razorpay Checkout
Use Razorpay Flutter SDK with these options:
```dart
{
  'key': key,                    // From step 2
  'amount': amount,              // In paise (from step 2)
  'order_id': orderId,           // From step 2
  'name': 'UniNest',
  'description': 'Order #ORD123456',
  'theme': {'color': '#FF6B6B'}
}
```

### Step 4: Verify Payment (on success callback)
```http
POST /api/customer/orders/ORD123456/payment/verify
```
Request body from Razorpay callback:
```json
{
  "razorpayOrderId": "order_xxx",
  "razorpayPaymentId": "pay_xxx",
  "razorpaySignature": "signature_hash"
}
```

---

## Cash on Delivery (COD) Flow

### Step 1: Create Order with COD
```http
POST /api/customer/orders
```
```json
{
  "items": [...],
  "paymentMethod": "cod",
  "deliveryAddress": {...}
}
```

Order is created immediately with `paymentStatus: "cod_pending"`.

---

## Common Error Messages

| Error | Cause | Fix |
|-------|-------|-----|
| `expected string but provided method` | A string field validator received a non-string value | Check all string fields are sent as strings, not numbers or objects |
| `Invalid payment method` | `paymentMethod` is not `cod` or `razorpay` | Use lowercase: `cod` or `razorpay` |
| `Must have at least one item in order` | `items` array is empty or missing | Ensure items array has at least one product |
| `Invalid product ID` | `productId` is not a valid MongoDB ObjectId | Check productId is 24 hex characters |
| `Quantity must be at least 1` | `quantity` is missing, 0, or less than 1 | Ensure quantity is integer ≥ 1 |
| `Delivery address is required` | `deliveryAddress.address` is empty | Provide non-empty address string |
| `Invalid delivery address type` | `addressType` is not in allowed enum | Use: `campus`, `hostel`, `canteen`, `off-campus`, `home`, `work`, `other` |

---

## Backend Files Reference

| File | Purpose |
|------|---------|
| `src/routes/customer/index.js` | Route definitions and validation rules |
| `src/middleware/validation.js` | Shared validation middleware |
| `src/controllers/customerController.js` | Order creation logic |
| `src/models/Order.js` | Order schema definition |
