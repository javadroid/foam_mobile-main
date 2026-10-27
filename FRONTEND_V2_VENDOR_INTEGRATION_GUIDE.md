# Foam Laundry — Frontend Integration & Migration Guide (v2 Vendor Branch)

This comprehensive guide details every backend update, architectural enhancement, and new endpoint introduced in the **`feat/v2-vendor`** branch compared to the previous **`main`** baseline.

It provides frontend engineers (Flutter Mobile & Web) with the exact contracts, schemas, workflows, error handling patterns, and code implementations needed to fully integrate the platform.

---

## Table of Contents
1. [Executive Summary & Migration Matrix](#1-executive-summary--migration-matrix)
2. [Global Architecture & Model Changes](#2-global-architecture--model-changes)
3. [Authentication & Profile Updates](#3-authentication--profile-updates)
4. [In-App Wallet & Financial Ledger](#4-in-app-wallet--financial-ledger)
5. [Order Placement & Quotation Engine](#5-order-placement--quotation-engine)
6. [Multi-Vendor Operations & Multi-Store Management](#6-multi-vendor-operations--multi-store-management)
7. [Subscription Lifecycle & Quotas](#7-subscription-lifecycle--quotas)
8. [Promotions & Sponsored Ads](#8-promotions--sponsored-ads)
9. [Media & Document Uploads (Cloudinary)](#9-media--document-uploads-cloudinary)
10. [Catalog Hierarchy: Services, SubServices & Dynamic Pricing](#10-catalog-hierarchy-services-subservices--dynamic-pricing)
11. [In-App Notifications](#11-in-app-notifications)
12. [Real-Time WebSockets (Socket.io) & Push Notifications (OneSignal)](#12-real-time-websockets-socketio--push-notifications-onesignal)
13. [Complete API Reference Quick-Sheet](#13-complete-api-reference-quick-sheet)

---

## 1. Executive Summary & Migration Matrix

The `v2-vendor` release evolves Foam from a single-operator laundry platform to a **multi-vendor laundry marketplace** powered by an **in-app wallet ledger**, **tiered subscription plans**, **catalog hierarchy**, and **real-time bi-directional order dispatching**.

### Key Differences at a Glance

| Feature / Domain | Old Backend (`main`) | New Backend (`feat/v2-vendor`) | Impact on Frontend |
| :--- | :--- | :--- | :--- |
| **User ID Type** | Auto-increment `Int` (e.g. `12`) | UUID `String` (e.g. `"f47ac10b-..."`) | **Breaking**: Store & parse `userId` as `String`. |
| **Order Payment** | Client trusted `totalPrice`; paid via Paystack inline | Authoritative pricing; Orders paid primarily via **In-App Wallet** or Dedicated Order Initializer | **Breaking**: Direct order creation debits wallet; returns `402` if underfunded. |
| **Pricing & Fees** | Hardcoded on frontend / client calculations | **Dynamic server-side settings** (`DELIVERY_FEE`, `MINIMUM_ORDER_AMOUNT`, etc.) | Replace client constants with `/api/user/basket/quote` & settings endpoint. |
| **Multi-Vendor** | None (Single operator) | Full multi-vendor support: store creation, pause/live toggles, custom matrix, order offers | New Vendor Portal / Screens in Flutter app. |
| **Wallet System** | None | In-app credit/debit wallet + full audit ledger | New Wallet screen, deposit modal & history view. |
| **Subscriptions** | None | 3 tiered plans (Basic A, Basic B, Standard Pro) with auto-renew, item quotas & pickup tracking | New Billing / Subscription screen. |
| **Catalog Depth** | Flat Service -> Category | 3-Tier: Service -> SubService -> Category (with folding flags) | Enhanced catalog navigation. |
| **Order Offers** | Manual assign | Real-time dispatch to vendor with **300s countdown timer** | Socket listener for `new_order_offer`. |
| **File Storage** | Local static `/uploads` | Cloud-hosted **Cloudinary** CDN with local fallback | Use returned Cloudinary HTTPS URLs. |
| **Notifications** | Polling only | Real-time **Socket.io** + **OneSignal** Push + In-app DB | Connect Socket & register OneSignal external user ID. |

---

## 2. Global Architecture & Model Changes

### 2.1 User ID Migration (Int -> String UUID)
In all data models (`Users`, `Address`, `Order`, `Basket`, `Wallet`, `Notification`), `userId` and `id` are now standard RFC-4122 UUID strings.
- **Dart / Flutter**: Change `int userId` to `String userId` in all models.
- **TypeScript**: `userId: string`.

### 2.2 Standard Error Response Shape
All endpoints now return structured errors in JSON format:
```json
{
  "error": "HUMAN_OR_CODE_STRING",
  "message": "Detailed explanation of what failed (optional)",
  "required": 6660,
  "currentBalance": 2000
}
```
Always check `res.statusCode >= 400` and display `response.data['message'] ?? response.data['error']`.

---

## 3. Authentication & Profile Updates

### 3.1 Seamless Social Auth Linking (Google & Apple)
- `POST /api/auth/google/signin`
- `POST /api/auth/google/register`
- `POST /api/auth/apple/signin`
- `POST /api/auth/apple/register`

**Improvement**: If a user previously registered with email/password and now clicks "Continue with Google" or "Sign in with Apple", the backend now **automatically links** their `socialAuthId` to their account and issues a valid JWT token instead of returning a `400 User already exists` error.

### 3.2 Forgot Password & OTP Flow
- **Request OTP**: `POST /api/auth/forgot-password`
  ```json
  { "email": "customer@example.com" }
  ```
  Generates a 6-digit cryptographic OTP valid for **10 minutes** (previously 5 minutes).
- **Verify OTP**: `POST /api/auth/verify-otp`
  ```json
  {
    "email": "customer@example.com",
    "otp": "492810"
  }
  ```
  *(Sending `email` alongside `otp` is now supported and recommended to prevent collisions).*
- **Reset Password**: `POST /api/auth/reset-password`
  ```json
  {
    "email": "customer@example.com",
    "otp": "492810",
    "password": "NewStrongPassword123!"
  }
  ```

### 3.3 Whitelisted Profile Updates
- `PUT /api/user/update` (Protected)
  Only whitelisted fields are modified to prevent parameter tampering:
  ```json
  {
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+2348012345678",
    "avatarUrl": "https://res.cloudinary.com/.../avatar.jpg",
    "businessName": "Doe Enterprises"
  }
  ```

---

## 4. In-App Wallet & Financial Ledger

The platform features an integrated wallet system for both customers (paying for orders & subscriptions) and vendors (earning payouts & withdrawals).

### 4.1 Get Wallet Balance
`GET /api/wallet`  
**Headers**: `Authorization: Bearer <token>`  
**Response (200 OK)**:
```json
{
  "balance": 25400,
  "pendingBalance": 0,
  "currency": "NGN",
  "status": "ACTIVE"
}
```
- `balance`: Authoritative spendable funds in Naira (₦).
- `pendingBalance`: Funds held in escrow / settlement for vendors.

---

### 4.2 Deposit Funds into Wallet (Paystack Flow)
Users can fund their wallet with any amount between dynamic bounds (default ₦500 – ₦1,000,000).

#### Step 1: Initialize Deposit
`POST /api/wallet/deposit/initialize`  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "amount": 10000
}
```
**Response (200 OK)**:
```json
{
  "message": "Deposit initialized successfully",
  "reference": "wal_dep_1729987200000_a1b2c3d4",
  "authorization_url": "https://checkout.paystack.com/3p81a7k...",
  "access_code": "3p81a7k..."
}
```

#### Step 2: Open Paystack Checkout
Launch `authorization_url` inside an in-app WebView (e.g. `PaystackCheckoutModal`).

#### Step 3: Verify & Credit Wallet
Once user completes payment or modal closes, call:  
`POST /api/wallet/deposit/verify`  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "reference": "wal_dep_1729987200000_a1b2c3d4"
}
```
**Response (200 OK)**:
```json
{
  "message": "Wallet credited successfully",
  "balance": 35400,
  "amount": 10000,
  "ledger": {
    "id": "led_98a72b...",
    "reference": "wal_dep_1729987200000_a1b2c3d4",
    "direction": "CREDIT",
    "type": "DEPOSIT",
    "balanceBefore": 25400,
    "balanceAfter": 35400,
    "createdAt": "2026-10-26T22:30:00.000Z"
  }
}
```

---

### 4.3 Get Transaction Ledger History
`GET /api/wallet/ledger?page=1&limit=20&type=DEPOSIT`  
**Headers**: `Authorization: Bearer <token>`  
**Query Parameters**:
- `page` (optional, default: `1`)
- `limit` (optional, default: `20`, max `100`)
- `type` (optional): `DEPOSIT` | `ORDER_PAYMENT` | `ORDER_REFUND` | `VENDOR_EARNING` | `VENDOR_WITHDRAWAL`

**Response (200 OK)**:
```json
{
  "transactions": [
    {
      "id": "7f2a1b...",
      "amount": 10000,
      "direction": "CREDIT",
      "type": "DEPOSIT",
      "status": "SUCCESS",
      "reference": "wal_dep_...",
      "description": "Paystack wallet deposit of NGN 10,000",
      "balanceBefore": 25400,
      "balanceAfter": 35400,
      "createdAt": "2026-10-26T22:30:00.000Z"
    },
    {
      "id": "3c4d5e...",
      "amount": 6660,
      "direction": "DEBIT",
      "type": "ORDER_PAYMENT",
      "status": "SUCCESS",
      "reference": "wal_ord_...",
      "description": "Payment for laundry order (2 items)",
      "orderId": 48,
      "balanceBefore": 35400,
      "balanceAfter": 28740,
      "createdAt": "2026-10-26T22:45:00.000Z"
    }
  ],
  "total": 24,
  "page": 1,
  "limit": 20,
  "totalPages": 2
}
```

---

## 5. Order Placement & Quotation Engine

### 5.1 Authoritative Basket Quote
Client-side arithmetic must never be trusted for final amounts. Call `/quote` to render itemized breakdowns.

`POST /api/user/basket/quote`  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "noFolding": true
}
```
**Response (200 OK)**:
```json
{
  "items": [
    {
      "itemId": 281,
      "categoryId": 14,
      "name": "Jacket/Coat",
      "quantity": 2,
      "unitPrice": 1100,
      "foldingSurcharge": 660,
      "lineTotal": 2860
    }
  ],
  "subtotal": 2200,
  "foldingSurchargeTotal": 660,
  "deliveryFee": 3000,
  "totalPrice": 5860
}
```

> **Note**: Basket mutation endpoints (`POST /api/user/basket`, `PUT /api/user/basket/:itemId`, `DELETE /api/user/basket/:itemId`, `DELETE /api/user/basket`) now automatically calculate and return this exact `quote` in their response body under `response.data.quote`!

---

### 5.2 Create Order via In-App Wallet (Primary Flow)
`POST /api/order/create`  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "noFolding": false,
  "storeId": 1,
  "pickupDate": "2026-10-30",
  "pickupTime": "09:00 AM - 11:00 AM",
  "pickupAddress": "15 Admiralty Way, Lekki Phase 1, Lagos",
  "deliveryDate": "2026-11-01",
  "deliveryTime": "02:00 PM - 04:00 PM",
  "deliveryAddress": "15 Admiralty Way, Lekki Phase 1, Lagos"
}
```

#### Success Response (201 Created):
```json
{
  "message": "Order placed and paid successfully from in-app wallet",
  "order": {
    "id": 52,
    "userId": "usr_7a8b9c...",
    "status": "ACCEPTED",
    "paymentType": "WALLET",
    "paymentStatus": "SUCCEEDED",
    "totalPrice": 5860,
    "noFolding": false,
    "storeId": 1,
    "vendorId": "vnd_3d4e5f...",
    "vendorStatus": "NEW",
    "pickupDate": "2026-10-30T00:00:00.000Z",
    "pickupTime": "09:00 AM - 11:00 AM",
    "pickupAddress": "15 Admiralty Way, Lekki Phase 1, Lagos",
    "deliveryDate": "2026-11-01T00:00:00.000Z",
    "deliveryTime": "02:00 PM - 04:00 PM",
    "deliveryAddress": "15 Admiralty Way, Lekki Phase 1, Lagos"
  },
  "walletBalance": 19540,
  "ledgerReference": "wal_ord_1729988000000_b2c3d4e5"
}
```

#### Insufficient Balance Handling (402 Payment Required):
If the user does not have enough balance, the server rejects the order with HTTP `402`:
```json
{
  "error": "INSUFFICIENT_WALLET_BALANCE",
  "message": "Insufficient funds in wallet. Required: NGN 5,860, Current Balance: NGN 1,500",
  "required": 5860,
  "currentBalance": 1500
}
```
**Frontend Handling**:
When catching HTTP `402`, prompt the user with a modal:
> "Your wallet balance is ₦1,500, but this order is ₦5,860. Would you like to add ₦4,360 to your wallet and continue?"
Trigger the wallet deposit flow for the difference (`required - currentBalance`).

---

### 5.3 Alternative: Direct Order Payment via Paystack
If the user prefers to pay directly with a Debit Card without pre-funding their wallet:

1. Call `POST /api/payment/paystack/initialize-order`
   ```json
   {
     "noFolding": false,
     "storeId": 1,
     "pickupDate": "2026-10-30",
     "pickupTime": "09:00 AM - 11:00 AM",
     "pickupAddress": "15 Admiralty Way, Lekki, Lagos",
     "deliveryDate": "2026-11-01",
     "deliveryTime": "02:00 PM - 04:00 PM",
     "deliveryAddress": "15 Admiralty Way, Lekki, Lagos"
   }
   ```
2. Open `authorization_url` in Paystack WebView.
3. Call `GET /api/payment/paystack/verify/:reference` upon completion. The backend automatically creates the order, clears the basket, and returns the created `order`.

---

### 5.4 Alternative: Direct Order Payment via Google Pay / Apple Pay
`POST /api/payment/mobile-pay/process`  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "provider": "GOOGLE_PAY",
  "purpose": "ORDER",
  "noFolding": false,
  "storeId": 1,
  "pickupDate": "2026-10-30",
  "pickupTime": "10:00 AM",
  "pickupAddress": "Lekki, Lagos",
  "deliveryDate": "2026-11-01",
  "deliveryTime": "02:00 PM",
  "deliveryAddress": "Lekki, Lagos"
}
```
**Response (200 OK)**:
```json
{
  "status": true,
  "message": "Order paid and placed successfully via GOOGLE_PAY! 🎉",
  "reference": "order_google_pay_...",
  "order": { "id": 53, "status": "ACCEPTED", ... }
}
```

---

## 6. Multi-Vendor Operations & Multi-Store Management

Vendors have a dedicated suite of routes under `/api/vendor`.

### 6.1 Vendor Profile & KYC Verification
`GET /api/vendor/profile`  
**Headers**: `Authorization: Bearer <token>`  
**Response (200 OK)**:
```json
{
  "role": "VENDOR",
  "businessName": "CleanBubble Laundry Hub",
  "vendorStatus": "APPROVED",
  "rejectionReason": null,
  "bankDetails": {
    "bankName": "Guaranty Trust Bank",
    "bankCode": "058",
    "accountNumber": "0123456789",
    "accountName": "CLEANBUBBLE VENTURES"
  },
  "documents": {
    "cacDocUrl": "https://res.cloudinary.com/.../cac.pdf",
    "ownerIdDocUrl": "https://res.cloudinary.com/.../nin.jpg",
    "proofOfAddressDocUrl": "https://res.cloudinary.com/.../bill.jpg"
  },
  "wallet": {
    "balance": 182400,
    "pendingBalance": 35000
  },
  "stores": [
    {
      "id": 1,
      "name": "CleanBubble - Lekki Branch",
      "address": "Block 10, Admiralty Way, Lekki",
      "status": "LIVE",
      "_count": { "orders": 8 }
    }
  ]
}
```
> `vendorStatus` can be: `NOT_STARTED` | `PENDING` | `APPROVED` | `REJECTED`.

---

### 6.2 Save Draft & Submit Onboarding
`POST /api/vendor/onboarding/draft`  
Supports step-by-step drafting across forms.
```json
{
  "businessName": "CleanBubble Laundry Hub",
  "firstName": "Ade",
  "lastName": "Balogun",
  "phone": "+2348033221100",
  "cacDocUrl": "https://res.cloudinary.com/.../cac.pdf",
  "ownerIdDocUrl": "https://res.cloudinary.com/.../id.jpg",
  "proofOfAddressDocUrl": "https://res.cloudinary.com/.../utility.jpg",
  "bankName": "Guaranty Trust Bank",
  "bankCode": "058",
  "bankAccountNumber": "0123456789",
  "bankAccountName": "CLEANBUBBLE VENTURES",
  "isFinalSubmit": true
}
```
Set `isFinalSubmit: true` on the last step to submit the application for admin review.

---

### 6.3 Bank Resolution & Verification
Before saving payout details, use these public helper endpoints:

#### List Active Banks:
`GET /api/payment/banks`  
**Response**:
```json
{
  "status": true,
  "banks": [
    { "id": 9, "name": "Access Bank", "code": "044", "slug": "access-bank" },
    { "id": 18, "name": "Guaranty Trust Bank", "code": "058", "slug": "guaranty-trust-bank" },
    { "id": 174, "name": "OPay Digital Services", "code": "999992", "slug": "paycom" }
  ]
}
```

#### Resolve Account Number:
`POST /api/payment/resolve-account`  
**Body**:
```json
{
  "account_number": "0123456789",
  "bank_code": "058"
}
```
**Response (200 OK)**:
```json
{
  "status": true,
  "accountName": "CLEANBUBBLE VENTURES",
  "accountNumber": "0123456789",
  "bankId": 18
}
```

---

### 6.4 Store Management

#### List Stores & Capacity
`GET /api/vendor/stores`  
**Response (200 OK)**:
```json
{
  "stores": [
    {
      "id": 1,
      "vendorId": "vnd_123",
      "name": "CleanBubble Lekki",
      "address": "12 Admiralty Way, Lekki",
      "latitude": 6.4474,
      "longitude": 3.4723,
      "status": "LIVE",
      "rating": 5.0,
      "operatingHours": {
        "monday": { "open": "08:00", "close": "18:00" },
        "tuesday": { "open": "08:00", "close": "18:00" }
      },
      "photoUrl": "https://res.cloudinary.com/.../store.jpg"
    }
  ],
  "maxStores": 10
}
```

#### Create Store:
`POST /api/vendor/stores`  
```json
{
  "name": "CleanBubble Ikeja Branch",
  "address": "45 Allen Avenue, Ikeja, Lagos",
  "latitude": 6.6018,
  "longitude": 3.3515,
  "photoUrl": "https://res.cloudinary.com/.../ikeja.jpg",
  "operatingHours": {
    "weekdays": "08:00 - 18:00",
    "saturday": "09:00 - 16:00"
  }
}
```

#### Rush Hour Pause / Live Toggle:
`PATCH /api/vendor/stores/:id/status`  
```json
{
  "status": "PAUSED"
}
```
*(Accepts `LIVE`, `PAUSED`, `DRAFT`)*.

#### Custom Store Pricing Matrix:
`PUT /api/vendor/stores/:id/pricing`  
```json
{
  "items": [
    { "serviceType": "LAUNDRY", "foldType": "FOLDING", "itemName": "Shirt", "price": 1200 },
    { "serviceType": "LAUNDRY", "foldType": "NON_FOLDING", "itemName": "Shirt", "price": 1500 },
    { "serviceType": "DRY_CLEANING", "foldType": "FOLDING", "itemName": "Suit (2-Piece)", "price": 4500 }
  ]
}
```

---

### 6.5 Vendor Orders & Workflow

#### Get Vendor Orders:
`GET /api/vendor/orders?status=NEW`  
- `status=NEW`: Incoming offers waiting for acceptance.
- `status=ACTIVE`: Orders currently being processed (`ACCEPTED`, `WASHING`, `READY`, `OUT_FOR_DELIVERY`).
- `status=DONE`: Completed, Delivered, or Cancelled orders.

#### Accept Order Offer:
`PATCH /api/vendor/orders/:id/accept`  
Transitions order to `ONGOING` and vendor status to `ACCEPTED`.

#### Decline Order Offer:
`PATCH /api/vendor/orders/:id/decline`  
```json
{ "reason": "Store at max washing capacity" }
```

#### Advance Order Production Stage:
`PATCH /api/vendor/orders/:id/status`  
```json
{ "vendorStatus": "WASHING" }
```
Sequence of valid statuses:
`ACCEPTED` ➔ `WASHING` ➔ `READY` ➔ `OUT_FOR_DELIVERY` ➔ `COMPLETED`.

> **Automatic Earnings Settlement**: When `vendorStatus: "COMPLETED"` is sent, the backend **automatically credits the vendor's wallet** with their `vendorEarnings` (Order Total minus Foam commission, e.g. 85%) under `LedgerType.VENDOR_EARNING`, and fires a push notification to both customer and vendor.

---

### 6.6 Vendor Wallet Withdrawal
`POST /api/vendor/wallet/withdraw`  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "amount": 50000
}
```
**Response (200 OK)**:
```json
{
  "message": "Withdrawal processed successfully",
  "newBalance": 132350,
  "transaction": {
    "id": 14,
    "vendorId": "vnd_123",
    "amount": 50000,
    "fee": 50,
    "status": "SUCCESS",
    "reference": "wd_1729989000000_c3d4e5f6",
    "bankDetails": "Guaranty Trust Bank - 0123456789 (CLEANBUBBLE VENTURES)"
  }
}
```
*(Flat withdrawal fee of ₦50 is dynamically deducted).*

---

## 7. Subscription Lifecycle & Quotas

Foam offers laundry subscriptions that cover item washing quotas and free pickups.

### 7.1 View Subscription Plans
`GET /api/subscriptions/plans` (Public)  
**Response (200 OK)**:
```json
{
  "plans": [
    {
      "id": 1,
      "name": "Basic Plan A (Heavy)",
      "code": "BASIC_A",
      "subtitle": "Ideal for singles & everyday workwear",
      "price": 32000,
      "billingCycle": "MONTHLY",
      "itemQuota": 35,
      "turnaroundDays": 2,
      "freePickupsCount": 2,
      "extraItemDiscountPercent": 10.0,
      "features": [
        "Up to 35 laundry garments / month",
        "2 Free scheduled doorstep pickups",
        "48-hour standard turnaround",
        "Wash, Dry & Professional Fold"
      ],
      "badge": "Budget Friendly",
      "colorHex": "#0098A6",
      "isPopular": false
    },
    {
      "id": 3,
      "name": "Standard Plan (Pro)",
      "code": "STANDARD_PRO",
      "subtitle": "Complete family care with premium handling",
      "price": 74000,
      "billingCycle": "MONTHLY",
      "itemQuota": 100,
      "turnaroundDays": 2,
      "freePickupsCount": 4,
      "extraItemDiscountPercent": 15.0,
      "features": [
        "Up to 100 garments / month",
        "4 Free pickups & deliveries",
        "Express 24-48h turnaround",
        "Free hanger packaging on demand"
      ],
      "badge": "Most Popular",
      "colorHex": "#1E3A8A",
      "isPopular": true
    }
  ]
}
```

---

### 7.2 Get Active Subscription & Quota Usage
`GET /api/subscriptions/my-subscription`  
**Headers**: `Authorization: Bearer <token>`  
**Response (200 OK)**:
```json
{
  "hasActiveSubscription": true,
  "subscription": {
    "id": "sub_98a72b...",
    "planId": 3,
    "status": "ACTIVE",
    "startDate": "2026-10-01T00:00:00.000Z",
    "endDate": "2026-11-01T00:00:00.000Z",
    "itemsUsed": 42,
    "itemQuota": 100,
    "remainingItems": 58,
    "pickupsUsed": 1,
    "freePickupsCount": 4,
    "remainingPickups": 3,
    "daysRemaining": 6,
    "autoRenew": true,
    "plan": {
      "name": "Standard Plan (Pro)",
      "code": "STANDARD_PRO",
      "price": 74000
    }
  }
}
```
If the user has no active subscription, returns:
`{ "hasActiveSubscription": false, "subscription": null }`.

---

### 7.3 Subscribe using In-App Wallet
`POST /api/subscriptions/subscribe`  
**Headers**: `Authorization: Bearer <token>`  
**Body**:
```json
{
  "planId": 3,
  "paymentMethod": "WALLET"
}
```
Atomically deducts `plan.price` from wallet and activates the subscription.

---

### 7.4 Subscribe via Paystack, Google Pay, or Apple Pay
1. Call `POST /api/subscriptions/initialize-payment`:
   ```json
   {
     "planId": 3,
     "paymentMethod": "PAYSTACK"
   }
   ```
2. Open `authorization_url` in modal WebView.
3. Call `POST /api/subscriptions/verify-payment`:
   ```json
   {
     "reference": "sub_pay_...",
     "planId": 3
   }
   ```
   *For Google Pay / Apple Pay, call `POST /api/subscriptions/mobile-pay` with `{ planId: 3, provider: "GOOGLE_PAY" }`.*

---

## 8. Promotions & Sponsored Ads

Dynamic carousel banners and discount deals for the mobile home screen.

### 8.1 Fetch Active Promotions
`GET /api/promotions/active?type=DISCOUNT_DEAL`  
*(Omit `type` to retrieve all types).*

**Response (200 OK)**:
```json
{
  "promotions": [
    {
      "id": 1,
      "title": "Weekend Laundry Rush: 20% Off",
      "subtitle": "Get all tops and coats cleaned for less this weekend",
      "imageUrl": "https://res.cloudinary.com/.../deal_banner.jpg",
      "type": "DISCOUNT_DEAL",
      "badgeText": "Limited Offer",
      "targetAction": "SERVICE_LAUNDRY",
      "targetPayload": "1",
      "priority": 10
    },
    {
      "id": 2,
      "title": "Subscribe & Save 35%",
      "subtitle": "Switch to Foam Monthly and eliminate wash day worries",
      "imageUrl": "https://res.cloudinary.com/.../sub_banner.jpg",
      "type": "SPONSORED_AD",
      "badgeText": "Hot Deal",
      "targetAction": "SUBSCRIPTION_PLANS",
      "targetPayload": null,
      "priority": 5
    }
  ]
}
```

### 8.2 Frontend Action Routing
Handle `targetAction` when the user taps a carousel card:
- `SERVICE_LAUNDRY`: Navigate to Laundry Service screen (pass `targetPayload` as service ID).
- `SERVICE_DRY_CLEANING`: Navigate to Dry Cleaning screen.
- `SUBSCRIPTION_PLANS`: Navigate to Subscription / Billing screen.
- `URL`: Open in-app browser or external URL from `targetPayload`.

---

## 9. Media & Document Uploads (Cloudinary)

File uploads are automatically routed to Cloudinary CDN with local disk fallback.

### 9.1 Single File Upload
`POST /api/upload`  
**Content-Type**: `multipart/form-data`  
**Form Field**: `image` or `file` or `cacDoc` (any field name accepted).  
**Allowed Types**: JPEG, PNG, WEBP, HEIC, PDF. Max: 10MB.

**Response (200 OK)**:
```json
{
  "status": true,
  "message": "File uploaded successfully",
  "url": "https://res.cloudinary.com/foam-cloud/image/upload/v1729980000/foam_uploads/file-1729980000-123456.jpg",
  "storage": "cloudinary",
  "publicId": "foam_uploads/file-1729980000-123456",
  "filename": "file-1729980000-123456.jpg",
  "mimetype": "image/jpeg",
  "size": 245100
}
```
> Save and send `url` directly to profile, KYC, store photo, or chat endpoints.

---

## 10. Catalog Hierarchy: Services, SubServices & Dynamic Pricing

### 10.1 Hierarchical Services Tree
`GET /api/services?nested=true` (Public)  
Returns the full 3-level catalog structure:
```json
{
  "services": [
    {
      "id": 1,
      "name": "Laundry",
      "description": "Everyday wash, dry, and professional folding",
      "imageUrl": "https://res.cloudinary.com/.../laundry.png",
      "subServices": [
        {
          "id": 101,
          "serviceId": 1,
          "name": "Wash & Fold",
          "code": "LAUNDRY_FOLD",
          "isFoldingAllowed": true,
          "defaultFolding": true,
          "categories": [
            {
              "id": 14,
              "name": "T-Shirt",
              "price": 800,
              "foldingSurchargeRate": 0.15
            }
          ]
        },
        {
          "id": 102,
          "serviceId": 1,
          "name": "Wash & Iron",
          "code": "LAUNDRY_IRON",
          "isFoldingAllowed": false,
          "defaultFolding": false,
          "categories": []
        }
      ]
    }
  ]
}
```

### 10.2 Dynamic Surcharge Settings
`GET /api/services/settings/folding-surcharge` (Public)  
**Response (200 OK)**:
```json
{
  "foldingSurcharge": 300,
  "foldingRatePercent": 15,
  "deliveryFee": 3000
}
```
Use this to display informational badges: *"Flat Delivery: ₦3,000 | Folding Option: +15%"*.

---

## 11. In-App Notifications

### 11.1 Fetch Notifications & Unread Badge
`GET /api/notifications`  
**Headers**: `Authorization: Bearer <token>`  
**Response (200 OK)**:
```json
{
  "unreadCount": 3,
  "notifications": [
    {
      "id": "notif_1a2b3c...",
      "title": "Order Placed! 🧺",
      "body": "Your payment was confirmed. Order #52 is being prepared!",
      "type": "ORDER_UPDATE",
      "referenceId": "52",
      "isRead": false,
      "createdAt": "2026-10-26T22:45:00.000Z"
    },
    {
      "id": "notif_4d5e6f...",
      "title": "Foam Wallet Credited!",
      "body": "Your wallet was credited with NGN 10,000. New balance: NGN 35,400.",
      "type": "WALLET",
      "referenceId": "wal_dep_...",
      "isRead": true,
      "createdAt": "2026-10-26T22:30:00.000Z"
    }
  ]
}
```

### 11.2 Mark Notification as Read
- Single: `PATCH /api/notifications/:id/read`
- All: `PATCH /api/notifications/read-all`

---

## 12. Real-Time WebSockets (Socket.io) & Push Notifications (OneSignal)

### 12.1 Socket.io Connection & Handshake
Connect to the server with JWT in the handshake:

```dart
// Flutter Socket.io Client Example
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io(
  'https://your-backend-api.com',
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .disableAutoConnect()
    .setAuth({'token': userJwtToken}) // Handshake auth
    .setQuery({'token': userJwtToken})
    .build(),
);

socket.connect();

socket.onConnect((_) {
  print('Connected to Foam Real-Time Socket Server');
});
```

### 12.2 Real-Time Event Listeners

| Event Name | Recipient | Payload | UI Action |
| :--- | :--- | :--- | :--- |
| `order_created` | Customer | `{ orderId: 52, status: "ACCEPTED" }` | Show confirmation toast; refresh order list. |
| `order_status_updated` | Customer | `{ orderId: 52, newStatus: "WASHING" }` | Update order tracking stepper in real-time. |
| `wallet_credited` | Customer / Vendor | `{ amount: 10000, newBalance: 35400, reference: "..." }` | Play chime; update wallet badge instantly. |
| `new_order_offer` | Vendor / Store | `{ orderId: 52, totalPrice: 5860, vendorEarnings: 4981, itemCount: 2, countdownSeconds: 300 }` | **Play order ring sound; display full-screen Accept/Decline modal with 300s countdown timer**. |
| `withdrawal_status` | Vendor | `{ amount: 50000, status: "SUCCESS", bankDetails: "..." }` | Show withdrawal status dialog. |
| `notification` | Any User | `{ title: "...", body: "...", data: {} }` | Increment unread badge; show in-app banner. |

### 12.3 OneSignal Push Notification Integration
Synchronize the logged-in Foam user ID with OneSignal:
```dart
// In Flutter splash / login handler:
await OneSignal.login(user.id); // UUID string matching backend user.id
```
When user logs out:
```dart
await OneSignal.logout();
```

---

## 13. Complete API Reference Quick-Sheet

| Method | Endpoint | Auth | Purpose |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/wallet` | Bearer | Get spendable and pending wallet balances |
| `POST` | `/api/wallet/deposit/initialize` | Bearer | Initialize wallet funding via Paystack |
| `POST` | `/api/wallet/deposit/verify` | Bearer | Verify transaction and credit wallet balance |
| `GET` | `/api/wallet/ledger` | Bearer | Paginated transaction audit history |
| `POST` | `/api/user/basket/quote` | Bearer | Authoritative pricing & surcharge breakdown |
| `POST` | `/api/order/create` | Bearer | **Place and pay order directly from in-app wallet** |
| `POST` | `/api/payment/paystack/initialize-order`| Bearer | Initialize Paystack checkout for laundry order |
| `POST` | `/api/payment/mobile-pay/process` | Bearer | Google Pay & Apple Pay universal processor |
| `GET` | `/api/payment/banks` | Public | List Nigerian commercial banks & fintechs |
| `POST` | `/api/payment/resolve-account` | Public | Verify 10-digit NUBAN bank account number |
| `GET` | `/api/vendor/profile` | Bearer | Vendor profile, KYC state, bank details & stores |
| `POST` | `/api/vendor/onboarding/draft` | Bearer | Save draft / submit final vendor KYC onboarding |
| `POST` | `/api/vendor/kyc` | Bearer | Direct KYC document submission |
| `PATCH` | `/api/vendor/payout-bank` | Bearer | Update vendor withdrawal bank account |
| `GET` | `/api/vendor/stores` | Bearer | List vendor stores, pricing & capacity limit |
| `POST` | `/api/vendor/stores` | Bearer | Create a new branch / store (subject to limit) |
| `GET` | `/api/vendor/current-store` | Bearer | Retrieve vendor's active primary store |
| `PUT` | `/api/vendor/stores/:id` | Bearer | Update store details, coordinates & hours |
| `PATCH` | `/api/vendor/stores/:id/status`| Bearer | Toggle store state (`LIVE`, `PAUSED`, `DRAFT`) |
| `PUT` | `/api/vendor/stores/:id/pricing`| Bearer | Update custom pricing matrix for store branch |
| `GET` | `/api/vendor/orders` | Bearer | Get orders filtered by `status=NEW\|ACTIVE\|DONE` |
| `PATCH` | `/api/vendor/orders/:id/accept` | Bearer | Accept incoming order offer |
| `PATCH` | `/api/vendor/orders/:id/decline`| Bearer | Decline incoming order offer with reason |
| `PATCH` | `/api/vendor/orders/:id/status` | Bearer | Advance order status (`WASHING` ➔ `COMPLETED`)|
| `POST` | `/api/vendor/wallet/withdraw` | Bearer | Request bank payout from vendor wallet |
| `GET` | `/api/subscriptions/plans` | Public | List active subscription plans (monthly quotas) |
| `GET` | `/api/subscriptions/my-subscription`| Bearer| Get active subscription, days & quota remaining|
| `GET` | `/api/subscriptions/history` | Bearer | List historical / expired user subscriptions |
| `POST` | `/api/subscriptions/initialize-payment`| Bearer | Initialize Paystack / Google / Apple Pay sub |
| `POST` | `/api/subscriptions/verify-payment` | Bearer | Verify Paystack payment and activate plan |
| `POST` | `/api/subscriptions/mobile-pay` | Bearer | Activate plan via Google Pay / Apple Pay token |
| `POST` | `/api/subscriptions/subscribe` | Bearer | **Activate plan directly from in-app wallet** |
| `POST` | `/api/subscriptions/cancel` | Bearer | Cancel auto-renewal or deactivate plan |
| `GET` | `/api/promotions/active` | Public | Active promo banners and deals for home screen |
| `GET` | `/api/notifications` | Bearer | List recent 50 notifications and `unreadCount` |
| `PATCH` | `/api/notifications/:id/read` | Bearer | Mark single notification as read |
| `PATCH` | `/api/notifications/read-all` | Bearer | Mark all notifications as read |
| `POST` | `/api/upload` | Public | Upload single image/document to Cloudinary CDN |
| `POST` | `/api/upload/multiple` | Public | Upload up to 5 files to Cloudinary CDN |
| `GET` | `/api/services` | Public | Full service catalog with nested `subServices` |
| `GET` | `/api/services/subservices` | Public | List subservices (with folding flags) |
| `GET` | `/api/services/settings/folding-surcharge`| Public| Dynamic surcharge rates and delivery fee |
| `GET` | `/api/operational-areas` | Public | Geofenced active states and LGAs for pickers |

---

*Authored for Foam Laundry engineering team. For questions or API changes, consult backend repository `feat/v2-vendor` branch.*
