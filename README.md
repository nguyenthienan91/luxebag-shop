# 🛍️ LuxeBag — Luxury Bag E-Commerce Mobile App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11.5-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/NestJS-11-E0234E?logo=nestjs&logoColor=white" alt="NestJS" />
  <img src="https://img.shields.io/badge/MongoDB-Mongoose-47A248?logo=mongodb&logoColor=white" alt="MongoDB" />
  <img src="https://img.shields.io/badge/TypeScript-5.7-3178C6?logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Socket.IO-4.8-black?logo=socket.io&logoColor=white" alt="Socket.IO" />
  <img src="https://img.shields.io/badge/License-UNLICENSED-red" alt="License" />
</p>

> **LuxeBag** is a full-stack B2C mobile e-commerce application for a luxury handbag boutique. Customers can browse, search, and purchase premium bags, while admins manage the full product lifecycle — from inventory to order fulfillment — through a dedicated admin panel inside the same app.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Project Structure](#3-project-structure)
4. [Features](#4-features)
5. [Setup Instructions](#5-setup-instructions)
6. [Environment Variables](#6-environment-variables)
7. [API Documentation](#7-api-documentation)
8. [Build & Deployment Guide](#8-build--deployment-guide)
9. [Testing](#9-testing)
10. [Architecture Notes](#10-architecture-notes)
11. [Future Improvements](#11-future-improvements)
12. [Contributing](#12-contributing)

---

## 1. Project Overview

**LuxeBag** is a B2C (Business-to-Consumer) mobile application built for a single luxury bag store. It provides a complete shopping experience — from product discovery to checkout — entirely within a Flutter mobile app, powered by a robust NestJS REST + WebSocket backend.

### Who It is For

| Role | Description |
|---|---|
| **Customer** | Browse products, manage cart, place orders, chat with support |
| **Admin** | Manage products, categories, inventory, orders, and revenue stats |
| **Seller** | Create and update product listings and upload images |

### Why It is Useful

- End-to-end e-commerce flow in a single cross-platform app (Android & iOS)
- Real-time customer support chat using Socket.IO
- Google OAuth 2.0 login for frictionless onboarding
- Secure JWT authentication with automatic token refresh
- In-app store map via Google Maps / flutter_map
- Admin dashboard with revenue analytics and inventory management

---

## 2. Tech Stack

### Frontend — Flutter

| Library | Version | Purpose |
|---|---|---|
| `flutter` | SDK `^3.11.5` | Cross-platform UI framework |
| `provider` | `^6.1.5+1` | State management (MVVM) |
| `dio` | `^5.9.2` | HTTP client with interceptors |
| `go_router` | `^17.2.3` | Declarative navigation |
| `shared_preferences` | `^2.5.5` | Local JWT token storage |
| `cached_network_image` | `^3.4.1` | Network image caching |
| `google_maps_flutter` | `^2.10.0` | Embedded Google Maps |
| `flutter_map` | `^8.3.0` | Alternative map widget |
| `latlong2` | `^0.9.1` | Latitude/longitude coordinates |
| `socket_io_client` | `^3.1.6` | Real-time WebSocket chat |
| `google_sign_in` | `^7.2.0` | Google OAuth 2.0 sign-in |
| `image_picker` | `^1.1.2` | Camera/gallery image picker |
| `fl_chart` | `^0.70.0` | Revenue statistics charts |
| `url_launcher` | `^6.3.1` | Open external links |

### Backend — NestJS

| Package | Version | Purpose |
|---|---|---|
| `@nestjs/core` | `^11.0.1` | NestJS framework core |
| `@nestjs/mongoose` | `^11.0.4` | MongoDB ODM integration |
| `@nestjs/jwt` | `^11.0.2` | JWT token generation & verification |
| `@nestjs/passport` | `^11.0.5` | Authentication middleware |
| `@nestjs/swagger` | `^11.4.4` | Auto-generated OpenAPI docs |
| `@nestjs/websockets` + `@nestjs/platform-socket.io` | `^11.1.27` | WebSocket / Socket.IO gateway |
| `@nestjs/throttler` | `^6.5.0` | Request rate limiting |
| `mongoose` | `^9.6.2` | MongoDB ODM |
| `bcrypt` | `^6.0.0` | Password hashing |
| `cloudinary` | `^2.10.0` | Cloud image storage |
| `google-auth-library` | `^10.9.0` | Google ID token verification |
| `resend` | `^6.12.4` | Transactional email sending |
| `nestjs-zod` | `^5.4.0` | DTO validation with Zod schemas |
| `socket.io` | `^4.8.3` | Real-time WebSocket server |
| `helmet` | `^8.2.0` | HTTP security headers |
| `nest-winston` + `winston` | `^1.10.2` / `^3.19.0` | Structured logging |

### Database

- **MongoDB** (via Mongoose) — document-based database for all entities

### DevTools

- TypeScript `^5.7`, ESLint, Prettier, Jest, ts-jest, Supertest

---

## 3. Project Structure

```
Luxebag/
├── luxebag-fe/                    # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart              # App entry point — MultiProvider setup + auto-login
│   │   ├── models/                # Plain Dart models (fromJson / toJson)
│   │   │   ├── cart_item_model.dart
│   │   │   ├── category_model.dart
│   │   │   ├── inventory_model.dart
│   │   │   ├── message_model.dart
│   │   │   ├── notification_model.dart
│   │   │   ├── order_model.dart
│   │   │   ├── product_model.dart
│   │   │   ├── revenue_stats_model.dart
│   │   │   └── user_model.dart
│   │   ├── repositories/          # HTTP layer — calls API, returns typed models
│   │   │   ├── auth_repository.dart
│   │   │   ├── cart_repository.dart
│   │   │   ├── chat_repository.dart
│   │   │   ├── inventory_repository.dart
│   │   │   ├── notification_repository.dart
│   │   │   ├── order_repository.dart
│   │   │   └── product_repository.dart
│   │   ├── services/              # Infrastructure singletons
│   │   │   ├── api_service.dart   # Dio config + Auth & Refresh interceptors
│   │   │   └── token_service.dart # JWT token CRUD via SharedPreferences
│   │   ├── viewmodels/            # Business logic + UI state (ChangeNotifier)
│   │   │   ├── auth_viewmodel.dart
│   │   │   ├── cart_viewmodel.dart
│   │   │   ├── chat_viewmodel.dart
│   │   │   ├── inventory_viewmodel.dart
│   │   │   ├── notification_viewmodel.dart
│   │   │   ├── order_viewmodel.dart
│   │   │   └── product_viewmodel.dart
│   │   ├── views/
│   │   │   ├── screens/
│   │   │   │   ├── admin/         # Admin panel screens
│   │   │   │   ├── auth/          # Login, Register, Forgot Password
│   │   │   │   ├── cart/          # Shopping cart
│   │   │   │   ├── chat/          # Customer support chat
│   │   │   │   ├── checkout/      # Order placement flow
│   │   │   │   ├── home/          # Product listing / browse
│   │   │   │   ├── main/          # Bottom navigation shell
│   │   │   │   ├── map/           # Store location map
│   │   │   │   ├── notification/  # In-app notifications
│   │   │   │   ├── order/         # Order history & detail
│   │   │   │   ├── product/       # Product detail
│   │   │   │   ├── profile/       # User profile + revenue stats
│   │   │   │   ├── search/        # Search results
│   │   │   │   └── wishlist/      # Saved/favourite products
│   │   │   └── widgets/           # Reusable UI components
│   │   └── utils/
│   │       ├── app_colors.dart    # Global color palette
│   │       ├── app_router.dart    # GoRouter route declarations
│   │       └── app_theme.dart     # Material 3 ThemeData
│   ├── pubspec.yaml
│   └── run_dev.sh                 # Dev startup script (adb reverse + flutter run)
│
├── luxebag-be/                    # NestJS REST + WebSocket backend
│   ├── src/
│   │   ├── main.ts                # Bootstrap — listens on 0.0.0.0:PORT
│   │   ├── init.ts                # CORS, global prefix, Swagger, shutdown hooks
│   │   ├── app.module.ts          # Root module — wires all feature modules
│   │   └── modules/
│   │       ├── auth/              # JWT auth, Google OAuth, password flows
│   │       ├── users/             # User CRUD, avatar upload
│   │       ├── products/          # Product CRUD, image upload (Cloudinary)
│   │       ├── categories/        # Product category management
│   │       ├── cart/              # Shopping cart operations
│   │       ├── orders/            # Checkout, order history, status management
│   │       ├── inventory/         # Stock management (import/deduct)
│   │       ├── wishlist/          # User saved products
│   │       ├── chat/              # REST message history + Socket.IO gateway
│   │       └── notifications/     # In-app notification store & read status
│   ├── common/                    # Guards, decorators, interceptors, utilities
│   ├── logger/                    # Winston logger module
│   ├── .example.env               # Environment variable template
│   └── package.json
│
├── GUIDE.md                       # Onboarding guide for new team members
└── README.md                      # This file
```

---

## 4. Features

### 🔐 Authentication & Authorization

- **Email / Password Sign-Up & Sign-In** — credentials hashed with bcrypt
- **Google OAuth 2.0 Login** — Google ID token verified server-side; auto-creates account on first login
- **JWT Access & Refresh Tokens** — access token auto-attached to every request; expired tokens silently refreshed by `_RefreshInterceptor` in Dio
- **Auto-Login on App Start** — stored token checked via `tryAutoLogin()`, profile restored from `/users/me`
- **Forgot / Reset Password** — time-limited UUID token sent via Resend email service
- **Change Password** — authenticated endpoint verifying old password before update
- **Role-Based Access Control (RBAC)** — four roles: `customer`, `seller`, `delivery`, `admin`; enforced globally by `AuthGuard` + `RolesGuard`

### 🛍️ Product Catalogue

- **Paginated Product Listing** — infinite scroll, configurable `page` & `itemPerPage`
- **Filtering & Search** — filter by `categoryId`, keyword `search`, `minPrice`, `maxPrice`
- **Product Detail** — full description, images hosted on Cloudinary, pricing
- **Multi-Image Upload** — admins/sellers upload up to 10 images per product via multipart form
- **Soft Delete** — deleted products retain their data with a `deletedAt` flag

### 🗂️ Categories

- Public listing (no authentication required)
- Admin-only create, update, and soft-delete

### ❤️ Wishlist

- Add / remove products from a personal wishlist
- Optimistic UI update pattern on the frontend

### 🛒 Shopping Cart

- Add items, update quantity, remove individual items
- Cart persisted per user in MongoDB

### 📦 Order Management

- **Checkout** — creates an order from cart items using a MongoDB transaction (atomically deducts inventory and clears the cart)
- **Order History** — users view own orders, filterable by status
- **Order Detail** — item-level breakdown, payment method, order status
- **Admin Order Fulfillment** — paginated list of all orders, filterable by status / payment method / user; update order status
- **Revenue Statistics** — admin dashboard with flexible period (`7d`, `30d`, `6m`, `12m`, `year`) visualized with `fl_chart`

### 📦 Inventory Management

- Admin-only stock control
- **Set Stock** — directly set absolute quantity for a product
- **Adjust Stock** — `IMPORT` (add) or `DEDUCT` (subtract) by a delta quantity
- **Bulk Init** — create inventory records for all products that do not yet have one

### 💬 Real-Time Chat

- **Socket.IO Gateway** — authenticated connection using JWT in the handshake
- **Chat Rooms** — deterministic room IDs derived from sender + receiver IDs
- **Message Events**: `chat:join`, `chat:send`, `chat:receive`, `chat:read`
- **Read Receipts** — messages marked as read when receiver is in the same room
- **Order Linking** — messages can reference a verified order ID
- **Online / Offline Status** — `chat:user_online` / `chat:user_offline` broadcast events
- **REST Endpoints** — paginated message history, conversation list, mark-as-read

### 🔔 Notifications

- Server-generated notifications triggered by order status changes
- Paginated per-user notification listing
- Mark individual or all notifications as read
- Unread badge count displayed on the frontend

### 🗺️ Store Map

- Interactive map showing the physical store location using `google_maps_flutter` / `flutter_map`
- External navigation link via `url_launcher`

### 👤 User Profile

- View and update display name, phone number
- Upload/change avatar image via `image_picker` + Cloudinary

### 🖥️ Admin Panel (In-App)

- Dedicated admin home with tab navigation
- **Product Management** — full CRUD with image upload form (`ProductFormScreen`)
- **Inventory Management** — stock adjust and bulk init (`InventoryManagementScreen`)
- **Order Fulfillment** — view and update order statuses (`OrderFulfillmentScreen`)
- **Admin Chat List** — view all customer conversations (`AdminChatListScreen`)
- **Revenue Stats** — period-selectable analytics chart (`RevenueStatsScreen`)

---

## 5. Setup Instructions

### Prerequisites

| Tool | Minimum Version | Check |
|---|---|---|
| Flutter SDK | `^3.11.5` | `flutter --version` |
| Dart SDK | Bundled with Flutter | `dart --version` |
| Node.js | `>=18.x` | `node --version` |
| npm | `>=9.x` | `npm --version` |
| MongoDB | `>=6.x` (local or Atlas) | `mongod --version` |
| Android Studio / ADB | Any | `adb version` |
| Git Bash (Windows) | Required for `run_dev.sh` | — |

---

### Step 1 — Clone the Repository

```bash
git clone <repository-url>
cd Luxebag
```

---

### Step 2 — Backend Setup

```bash
cd luxebag-be

# Install Node.js dependencies
npm install

# Create environment file from template
cp .example.env .env
# Edit .env with your actual values (see Environment Variables section)

# Start in development / watch mode
npm run start:dev
```

The backend will be available at: `http://localhost:8888`  
Swagger UI (OpenAPI docs): `http://localhost:8888/api`

---

### Step 3 — Frontend Setup

```bash
cd luxebag-fe

# Install Flutter dependencies
flutter pub get
```

> **Note:** The Flutter app calls `http://10.0.2.2:8888/api` by default, which is the Android Emulator's alias for `localhost` on the host machine.

#### Running on Android Emulator / Device

> ⚠️ **Always** use `run_dev.sh` instead of `flutter run` directly. This script sets up `adb reverse` to tunnel port 8888 between the device and host machine — without it the app cannot reach the backend.

```bash
# From the luxebag-fe/ directory (use Git Bash on Windows)
./run_dev.sh

# Target a specific device (find IDs with: adb devices)
./run_dev.sh emulator-5554
```

#### Running on Chrome / Desktop (development only)

```bash
flutter run -d chrome
flutter run -d windows
```

---

### Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `Connection refused` on device | Backend not running / `adb reverse` not set | Start backend, then use `./run_dev.sh` |
| `adb reverse` fails | Emulator not started | Launch the emulator first, then re-run the script |
| `adb not found` | Android SDK not in PATH | Install Android Studio → SDK Tools → Platform-Tools |
| `401 Unauthorized` on all API calls | Expired or missing JWT token | Log out and log in again |
| `409 Conflict` on sign-up | Email already registered | Use a different email or sign in |

---

## 6. Environment Variables

Create a `.env` file in `luxebag-be/` using `.example.env` as a template:

```dotenv
# ─── Database ────────────────────────────────────────────────────────────────
MONGODB_URI=mongodb://localhost:27017/luxebag
# MongoDB Atlas: mongodb+srv://<user>:<pass>@cluster.mongodb.net/luxebag

# ─── Server ──────────────────────────────────────────────────────────────────
PORT=8888
HOST=localhost
APP_PREFIX=/api
APP_NAME=luxebag
NODE_ENV=development          # development | production

# ─── Frontend URL (CORS allowlist) ───────────────────────────────────────────
FE_URL=                       # Leave empty to allow all origins (dev only)

# ─── Rate Limiting ───────────────────────────────────────────────────────────
THROTTLE_TTL=600000           # Window in ms (10 minutes)
THROTTLE_LIMIT=100            # Max requests per window per IP

# ─── JWT ─────────────────────────────────────────────────────────────────────
JWT_SECRET=your_super_secret_jwt_key

# ─── File Uploads (local temp storage) ───────────────────────────────────────
MULTER_DESTINATION_FILE=./uploads

# ─── Cloudinary (Image Hosting) ──────────────────────────────────────────────
CLOUDINARY_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# ─── Email (via Resend) ──────────────────────────────────────────────────────
MAIL_INCOMING_USER=your_email@example.com
MAIL_INCOMING_PASS=your_email_password
MAIL_HOST=smtp.resend.com
MAIL_PORT=465

# ─── Google OAuth ────────────────────────────────────────────────────────────
AUTH_GOOGLE_ID=your_google_oauth_web_client_id

# ─── Cache ───────────────────────────────────────────────────────────────────
CACHE_INTERNAL_TTL=30000      # Internal cache TTL in ms
```

### Frontend Configuration

The base API URL is hardcoded in `luxebag-fe/lib/services/api_service.dart`:

```dart
static const String _baseUrl = 'http://10.0.2.2:8888/api';
```

Change this to your production backend URL before building a release APK.

The Google Sign-In OAuth client ID is in `luxebag-fe/lib/viewmodels/auth_viewmodel.dart`:

```dart
await GoogleSignIn.instance.initialize(
  serverClientId: '<YOUR_GOOGLE_OAUTH_WEB_CLIENT_ID>',
);
```

---

## 7. API Documentation

All routes are prefixed with `/api`. A full interactive Swagger UI is auto-generated at `http://localhost:8888/api` when the backend is running.

### Authentication — `/api/auth`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `POST` | `/auth/sign-up` | Public | Register a new customer account |
| `POST` | `/auth/sign-in` | Public | Email/password login; sets JWT cookies |
| `POST` | `/auth/google-login` | Public | Google OAuth login with ID token |
| `GET` | `/auth/logout` | Public | Clears JWT cookies |
| `GET` | `/auth/refresh-token` | Public (cookie) | Issues new access + refresh token pair |
| `POST` | `/auth/forgot-password` | Public | Sends password reset link via email |
| `POST` | `/auth/reset-password?token=` | Public | Resets password using the emailed token |
| `POST` | `/auth/change-password` | 🔒 Authenticated | Change password (requires old password) |

### Users — `/api/users`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/users/me` | 🔒 Any | Get the current user's profile |
| `PATCH` | `/users/me` | 🔒 Any | Update display name / phone number |
| `PATCH` | `/users/profile/avatar` | 🔒 Any | Upload a new profile picture |
| `GET` | `/users` | 🔒 Admin | List all users |
| `GET` | `/users/:id` | 🔒 Admin | Get user by ID |
| `POST` | `/users` | 🔒 Admin | Create a user manually |
| `PATCH` | `/users/:id` | 🔒 Admin | Update any user |
| `DELETE` | `/users/:id` | 🔒 Admin | Remove a user |

### Products — `/api/products`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/products` | Public | Paginated listing (`page`, `itemPerPage`, `categoryId`, `search`, `minPrice`, `maxPrice`) |
| `GET` | `/products/:id` | Public | Get single product detail |
| `POST` | `/products` | 🔒 Seller / Admin | Create a new product |
| `PATCH` | `/products/:id` | 🔒 Seller / Admin | Update product data |
| `DELETE` | `/products/:id` | 🔒 Seller / Admin | Soft-delete a product |
| `POST` | `/products/:productId/upload-images` | 🔒 Seller / Admin | Upload up to 10 product images |

### Categories — `/api/categories`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/categories` | Public | List all active categories |
| `GET` | `/categories/:id` | Public | Get category by ID |
| `POST` | `/categories` | 🔒 Admin | Create a category |
| `PATCH` | `/categories/:id` | 🔒 Admin | Update a category |
| `DELETE` | `/categories/:id` | 🔒 Admin | Soft-delete a category |

### Cart — `/api/cart`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/cart` | 🔒 Authenticated | Get the current user's cart |
| `POST` | `/cart/add` | 🔒 Authenticated | Add a product to cart |
| `PUT` | `/cart/update` | 🔒 Authenticated | Update item quantity |
| `DELETE` | `/cart/remove/:productId` | 🔒 Authenticated | Remove an item from cart |

### Orders — `/api/orders`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/orders` | 🔒 Authenticated | Get current user's order history (filter by `status`) |
| `GET` | `/orders/:id` | 🔒 Authenticated | Get a specific order detail |
| `POST` | `/orders/checkout` | 🔒 Authenticated | Place an order from cart (MongoDB transaction) |
| `GET` | `/orders/admin` | 🔒 Admin | All orders with pagination and filters |
| `GET` | `/orders/revenue-stats` | 🔒 Admin | Revenue stats for period (`7d`, `30d`, `6m`, `12m`, `year`) |
| `PATCH` | `/orders/:orderId/status` | 🔒 Admin | Update an order's fulfillment status |

### Inventory — `/api/inventory`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/inventory/:productId` | 🔒 Admin | View stock level for a product |
| `PATCH` | `/inventory/:productId/stock` | 🔒 Admin | Set absolute stock quantity |
| `PATCH` | `/inventory/:productId` | 🔒 Admin | Adjust stock with `IMPORT` or `DEDUCT` action |
| `POST` | `/inventory/bulk-init` | 🔒 Admin | Create inventory records for all unregistered products |

### Wishlist — `/api/wishlist`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/wishlist` | 🔒 Authenticated | Get the current user's wishlist |
| `POST` | `/wishlist` | 🔒 Authenticated | Add a product to wishlist |
| `DELETE` | `/wishlist/:productId` | 🔒 Authenticated | Remove a product from wishlist |

### Chat REST — `/api/messages`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/messages/shop` | 🔒 Authenticated | List all admin accounts (shop contacts) |
| `GET` | `/messages/conversations` | 🔒 Authenticated | List all conversations for current user |
| `GET` | `/messages/:shopId` | 🔒 Authenticated | Paginated message history (`page`, `limit`) |
| `POST` | `/messages/read/:otherUserId` | 🔒 Authenticated | Mark all messages with a user as read |

### Chat WebSocket (Socket.IO)

Connect to `ws://localhost:8888` and pass `auth: { token: '<accessToken>' }` in the handshake options.

**Events to emit:**

| Event | Payload | Description |
|---|---|---|
| `chat:join` | `{ targetId: string }` | Join a chat room with another user |
| `chat:send` | `{ receiverId, messageText, orderId? }` | Send a message (optionally link an order) |

**Events to listen for:**

| Event | Payload | Description |
|---|---|---|
| `chat:receive` | Message object | Incoming message in the room |
| `chat:read` | `{ roomId, readerId }` | Notifies that messages were read |
| `chat:user_online` | `{ userId }` | A user connected |
| `chat:user_offline` | `{ userId }` | A user disconnected |

### Notifications — `/api/notifications`

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| `GET` | `/notifications` | 🔒 Authenticated | Get user notifications (`page`, `limit`) |
| `PUT` | `/notifications/read-all` | 🔒 Authenticated | Mark all notifications as read |
| `PUT` | `/notifications/:id/read` | 🔒 Authenticated | Mark a specific notification as read |

---

## 8. Build & Deployment Guide

### Backend (NestJS)

#### Build

```bash
cd luxebag-be
npm run build          # Compiles TypeScript to dist/
```

#### Production Start

```bash
NODE_ENV=production npm run start:prod
```

#### Docker

A minimal Dockerfile for the backend:

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 8888
CMD ["node", "dist/main"]
```

```bash
docker build -t luxebag-be .
docker run -p 8888:8888 --env-file .env luxebag-be
```

#### Deploy to Render

1. Create a **Web Service** on [render.com](https://render.com)
2. **Build Command**: `npm install && npm run build`
3. **Start Command**: `npm run start:prod`
4. Add all `.env` variables in the Render environment settings
5. Set `NODE_ENV=production` and `FE_URL` to your Flutter app's origin

### Frontend (Flutter)

#### Update API URL Before Building

Edit `luxebag-fe/lib/services/api_service.dart`:

```dart
static const String _baseUrl = 'https://your-production-backend.com/api';
```

#### Android APK (Sideload / Testing)

```bash
cd luxebag-fe
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Android App Bundle (Google Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS (App Store)

```bash
flutter build ios --release
# Open the ios/ folder in Xcode and archive for App Store distribution
```

---

## 9. Testing

### Backend Tests

The backend uses **Jest** + **ts-jest** for unit and end-to-end tests.

```bash
cd luxebag-be

# Run all unit tests
npm run test

# Watch mode (reruns on file change)
npm run test:watch

# Code coverage report
npm run test:cov

# End-to-end tests
npm run test:e2e

# Debug tests with inspector
npm run test:debug
```

Existing test files:

| File | Description |
|---|---|
| `src/app.controller.spec.ts` | App controller smoke test |
| `src/modules/auth/auth.controller.spec.ts` | Auth controller unit tests |
| `src/modules/auth/auth.guard.spec.ts` | Auth guard unit tests |
| `src/modules/auth/auth.service.spec.ts` | Auth service unit tests |
| `src/modules/users/users.controller.spec.ts` | Users controller unit tests |
| `src/modules/users/users.service.spec.ts` | Users service unit tests |

### Frontend Tests

```bash
cd luxebag-fe

# Run all Flutter tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart
```

---

## 10. Architecture Notes

### Frontend: MVVM Pattern

The Flutter app strictly follows **MVVM (Model–View–ViewModel)** with Provider:

```
User Action
    │
    ▼
View (Widget)  ── context.read<VM>().action() ──►  ViewModel (ChangeNotifier)
    │                                                       │
    │  Consumer<VM> / context.watch<VM>()           calls Repository
    │                                                       │
    ◄──── notifyListeners() ◄────────────────  Repository (Dio HTTP calls)
                                                            │
                                                  NestJS Backend API
```

| Layer | Responsibility |
|---|---|
| `models/` | Pure Dart data classes with `fromJson()` factory; no logic |
| `services/` | Singleton infrastructure: `ApiService` (Dio + interceptors), `TokenService` (SharedPreferences) |
| `repositories/` | One class per domain; calls API, returns typed model objects |
| `viewmodels/` | Extends `ChangeNotifier`; manages `isLoading`, `errorMessage`, domain state |
| `views/` | Pure UI widgets; reads state via `Consumer<T>` / `context.watch<T>()`; triggers actions via `context.read<T>()` |

### Backend: NestJS Modular Architecture

Each domain is a self-contained NestJS module with:
- **Controller** — HTTP routing, guards, Swagger decorators
- **Service** — business logic, database operations
- **Entity / Schema** — Mongoose schema definition
- **DTOs** — request/response validation via `nestjs-zod`

Global cross-cutting concerns live in `common/`:
- `AuthGuard` + `RolesGuard` registered globally as `APP_GUARD` providers
- `okResponse()` wrapper for consistent response format
- Pagination utility service
- Cookie & User decorators
- Mail service (Resend integration)

---

## 11. Future Improvements

Based on code analysis and stub implementations found in the source:

| Area | Improvement |
|---|---|
| **Payment Gateway** | Integrate VNPay, Stripe, or MoMo — only Cash on Delivery is functional today |
| **Push Notifications** | Replace the mock push log in `chat.gateway.ts` with Firebase Cloud Messaging (FCM) |
| **SMS OTP** | `sendSMS()` in `auth.service.ts` is a stub — implement via Twilio or a Vietnamese SMS provider |
| **Delivery Role** | `UserRole.DELIVERY` is defined but no delivery module or screen exists |
| **API Versioning** | `VersioningType.HEADER` is commented out in `init.ts` — enable for forward compatibility |
| **Unit Test Coverage** | Existing tests are minimal smoke tests — expand with full service and integration test coverage |
| **Wishlist ViewModel** | No dedicated `wishlist_viewmodel.dart` — wishlist state is managed ad-hoc in screens |
| **Product Reviews / Ratings** | No review system exists — a high-value feature for luxury e-commerce |
| **Flutter Environment Config** | `_baseUrl` is hardcoded — use `--dart-define` flags or `flutter_dotenv` for per-environment builds |
| **iOS Configuration** | Google Maps and Google Sign-In require additional iOS-specific setup (API key, URL scheme, plist) before App Store submission |

---

## 12. Contributing

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Follow the existing code conventions:
   - **Flutter**: `snake_case` files, `PascalCase` classes, `camelCase` methods, no business logic in View layer
   - **NestJS**: one controller + service per module, all DTOs validated with `nestjs-zod`, no raw logic in controllers

3. Run linters before committing:
   ```bash
   # Flutter
   flutter analyze

   # Backend
   cd luxebag-be && npm run lint
   ```

4. Write or update tests for any changed business logic.

5. Open a **Pull Request** with a clear description of what changed and why.

---

<p align="center">
  Built with ❤️ using Flutter & NestJS &nbsp;·&nbsp; FPT University — PRM393 &nbsp;·&nbsp; 2026
</p>
