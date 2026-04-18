# Customer API Documentation

## Health Check
- **GET** `/customer/health` – Customer service health check (No authentication required)

## Authentication & Account Management
- **POST** `/customer/auth/register` – Register a new customer (No authentication required)
  - Request Body: `name`, `email`, `password`, `phone`
  - Response: User data + JWT token
- **POST** `/customer/auth/login` – Log in a customer (No authentication required)
  - Request Body: `email`, `password`
  - Response: User data + JWT token
- **POST** `/customer/auth/change-password` – Change the authenticated customer's password (requires JWT)
  - Request Body: `currentPassword`, `newPassword`

## Profile Management
- **GET** `/customer/profile` – Retrieve the authenticated customer's profile (requires JWT)
  - Response: User data (excluding password)
- **PUT** `/customer/profile` – Update the authenticated customer's profile (requires JWT)
  - Request Body: `name`, `phone`, `avatar`, `addresses` (all optional)
  - Response: Updated user data

## Order Management
- **POST** `/customer/orders` – Create a new order (requires JWT)
  - Request Body: `items[]`, `deliveryAddress`, `paymentMethod`, `fulfillmentType`, `offerCode`
  - Response: Order data + payment details (if online payment)
- **POST** `/customer/orders/checkout` – Checkout alias for production payment flow (requires JWT)
  - Request Body: Same as create order
  - Response: Order data + payment details
- **GET** `/customer/orders` – List the customer's orders (requires JWT)
  - Query Parameters: `page`, `limit`, `status`, `sortBy`, `sortOrder`
  - Response: Paginated orders list with vendor and product details
- **GET** `/customer/orders/:id` – Get details for a specific order (requires JWT)
  - Parameter: Order ID or Order Number (ORD-XXXXX)
  - Response: Complete order details with vendor, products, and timeline
- **PUT** `/customer/orders/:id/cancel` – Cancel an order (requires JWT)
  - Parameter: Order ID or Order Number (ORD-XXXXX)
  - Request Body: `reason` (optional)
  - Response: Cancelled order details
- **GET** `/customer/orders/:id/track` – Track the delivery status of an order (requires JWT)
  - Parameter: Order ID or Order Number (ORD-XXXXX)
  - Response: Order tracking information with timeline and delivery details

## Payment Management
- **POST** `/customer/orders/:id/payment/razorpay-order` – Create or refresh a Razorpay payment order (requires JWT)
  - Parameter: Order ID or Order Number (ORD-XXXXX)
  - Response: Razorpay payment order details including gateway key, amount, and order ID
- **POST** `/customer/orders/:id/payment/verify` – Verify a Razorpay payment (requires JWT)
  - Parameter: Order ID or Order Number (ORD-XXXXX)
  - Request Body: `razorpayOrderId`, `razorpayPaymentId`, `razorpaySignature`
  - Response: Updated order status after payment verification

## Review Management
- **POST** `/customer/orders/:orderId/review` – Submit a review for a completed order (requires JWT)
  - Parameter: Order ID or Order Number (ORD-XXXXX)
  - Request Body: `rating{food, delivery, experience}`, `comment`, `images[]`
  - Response: Success message

## Notifications
- **GET** `/customer/notifications` – Retrieve a paginated list of notifications (requires JWT)
  - Query Parameters: `page`, `limit`, `isRead`, `type`
  - Response: Paginated notifications list
- **PUT** `/customer/notifications/read` – Mark all notifications as read (requires JWT)
  - Response: Success message

---

## Authentication Requirements
- **No Authentication Required**: `/health`, `/auth/register`, `/auth/login`
- **JWT Authentication Required**: All other endpoints (Bearer token in Authorization header)

## Payment Methods Supported
- **COD** (Cash on Delivery)
- **Razorpay** (Online payment gateway)

## Order Statuses
- `pending` – Order created, awaiting payment (for online orders)
- `confirmed` – Order confirmed and being prepared
- `preparing` – Food is being prepared
- `ready` – Order ready for pickup/delivery
- `out_for_delivery` – Order is with delivery partner
- `delivered` – Order successfully delivered
- `cancelled` – Order cancelled by customer or vendor
- `refunded` – Order refunded (for cancelled paid orders)

## Address Types Supported
- `campus` – Campus location
- `hostel` – Hostel address
- `canteen` – Canteen location
- `off-campus` – Off-campus address
- `home` – Home address
- `work` – Work address
- `other` – Other address type

## Fulfillment Types
- `delivery` – Door delivery
- `takeaway` – Self-pickup from vendor

---

