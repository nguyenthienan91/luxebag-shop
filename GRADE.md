# LUXEBAG — TÀI LIỆU ĐÁNH GIÁ DỰ ÁN (GRADE.md)

> **Môn học:** PRM393 — Mobile Development
> **Học kỳ:** 2026 — Semester 8
> **Trường:** FPT University
> **Tên dự án:** LuxeBag — Ứng dụng di động mua sắm túi xách thời trang cao cấp
> **Kiến trúc:** Flutter (Client) ↔ NestJS REST API + Socket.IO (Server) ↔ MongoDB (Database)

---

## 📁 Cấu Trúc Monorepo

```
Luxebag/
├── luxebag-be/          ← NestJS Backend (REST API + WebSocket Gateway)
│   └── src/
│       ├── modules/     ← auth, users, products, categories, cart, orders,
│       │                   wishlist, inventory, chat, notifications
│       └── common/      ← guards, decorators, interceptors, security
└── luxebag-fe/          ← Flutter Mobile Client
    └── lib/
        ├── models/      ← Data models (ProductModel, OrderModel, ...)
        ├── repositories/ ← API call layer (AuthRepository, CartRepository, ...)
        ├── services/    ← ApiService (Dio), TokenService (SharedPreferences)
        ├── viewmodels/  ← State Management (Provider / ChangeNotifier)
        ├── views/       ← UI Screens & Widgets
        └── utils/       ← AppRouter (GoRouter), AppTheme, AppColors
```

---

## 1. 🗄️ Thiết Kế Database & API Structure (NestJS + MongoDB)

### Collections MongoDB (Mongoose Schemas)

| Collection | Schema File | Mô tả |
|---|---|---|
| `users` | `user.entity.ts` | `email`, `password (bcrypt)`, `displayName`, `avatar`, `role` (customer/seller/admin/delivery), `isActive`, `isVerified`, `resetPasswordToken`, `resetPasswordOtp` |
| `products` | `product.entity.ts` | `title`, `description`, `basePrice`, `currentPrice`, `images[]`, `categoryId`, `isActive`, `_destroy` (soft delete) |
| `categories` | *(categories module)* | `name`, `slug`, `description`, `imageUrl` |
| `carts` | `cart.entity.ts` | `userId (ref)`, `items [ { productId, quantity } ]` — Embedded design |
| `orders` | `order.entity.ts` | `userId (ref)`, `items [ { productId, title, sku, image, priceAtPurchase, quantity } ]` (snapshot), `totalAmount`, `shippingAddress`, `paymentMethod` (COD/CARD), `status` (pending/processing/shipped/completed/cancelled), `createdAt` |
| `inventory` | *(inventory module)* | Quản lý tồn kho sản phẩm độc lập |
| `notifications` | `notification.schema.ts` | `userId (ref)`, `title`, `body`, `isRead (Boolean)`, `createdAt` |
| `messages` | `message.schema.ts` | `senderId (ref)`, `receiverId (ref)`, `messageText`, `roomId`, `isRead`, `orderId (optional ref)`, `orderCodeSnapshot`, `createdAt` |
| `wishlist` | *(wishlist module)* | Danh sách yêu thích của người dùng |

### ✅ Thay đổi so với tài liệu gốc:

- **Inventory tách biệt:** Thay vì lưu `stock` trực tiếp trong `products`, dự án xây dựng module `Inventory` riêng biệt — chuyên nghiệp và dễ mở rộng hơn.
- **Order Item Snapshot:** Trường `priceAtPurchase`, `title`, `sku` được đóng băng tại thời điểm mua.
- **Soft Delete:** Sản phẩm bị xóa dùng cờ `_destroy: true` — bảo toàn lịch sử đơn hàng.
- **Role-Based Access Control (RBAC):** 4 vai trò: `customer`, `seller`, `admin`, `delivery`.
- **Wishlist Module:** Tính năng bổ sung — danh sách yêu thích.
- **Categories Module:** Danh mục sản phẩm được quản lý độc lập thay vì hardcode enum.
- **Revenue Stats API:** Endpoint thống kê doanh thu cho Admin (`7d`, `30d`, `6m`, `12m`, `year`).

---

## 2. 🔐 Login / Register Screen — Xác Thực Người Dùng

**File:** `luxebag-fe/lib/views/screens/auth/login_screen.dart`
**File:** `luxebag-fe/lib/views/screens/auth/register_screen.dart`
**File:** `luxebag-fe/lib/views/screens/auth/forgot_password_screen.dart`
**ViewModel:** `lib/viewmodels/auth_viewmodel.dart`
**Repository:** `lib/repositories/auth_repository.dart`
**Backend:** `luxebag-be/src/modules/auth/auth.controller.ts` & `auth.service.ts`

### Chức năng đã triển khai:

| Tính năng | Trạng thái |
|---|---|
| Form Validation phía client (email, mật khẩu ≥ 6 ký tự, xác nhận mật khẩu) | ✅ |
| Ẩn/Hiện mật khẩu (toggle visibility) | ✅ |
| Đăng nhập bằng Email & Password → JWT Token | ✅ |
| Đăng ký tài khoản mới | ✅ |
| Lưu JWT vào `SharedPreferences` (qua `TokenService`) | ✅ |
| Auto-login khi mở app (`tryAutoLogin()` kiểm tra token) | ✅ |
| Điều hướng theo role: Customer → `/home`, Admin → `/admin-home` | ✅ |
| Xử lý lỗi HTTP (401/400/409/500) hiển thị SnackBar/Dialog | ✅ |
| **Quên mật khẩu** (Forgot Password) — gửi email reset qua `resend` | ✅ *(Bổ sung)* |
| **Đăng nhập bằng Google OAuth** (Google Sign-In) | ✅ *(Bổ sung)* |
| **Thay đổi mật khẩu** (Change Password) | ✅ *(Bổ sung)* |
| **Token Refresh** tự động (Refresh Token Cookie + Interceptor) | ✅ *(Bổ sung)* |

### Chi tiết kỹ thuật nổi bật:

- **Cơ chế token:** Backend dùng **HTTP-only Cookie** cho cả `accessToken` và `refreshToken`. `TokenService` lưu token vào `SharedPreferences`.
- **RefreshInterceptor:** Khi `accessToken` hết hạn, Dio interceptor tự động gọi `GET /auth/refresh-token` và retry — minh bạch với người dùng.
- **bcrypt:** Mật khẩu được băm trước khi lưu MongoDB.
- **Google Sign-In:** Tích hợp `google_sign_in` + backend xác minh `idToken` bằng `google-auth-library`.
- **Passport JWT Guard:** Global `AuthGuard` cho toàn bộ API; route công khai đánh dấu `@SkipAuth()`.

---

## 3. 🏠 Product List / Home Screen — Trang Chủ & Danh Sách Sản Phẩm

**File:** `luxebag-fe/lib/views/screens/home/home_screen.dart`
**ViewModel:** `lib/viewmodels/product_viewmodel.dart`
**Repository:** `lib/repositories/product_repository.dart`
**Backend:** `luxebag-be/src/modules/products/product.controller.ts`

### Chức năng đã triển khai:

| Tính năng | Trạng thái |
|---|---|
| Fetch danh sách sản phẩm từ API (`GET /products`) | ✅ |
| Hiển thị Grid View với ảnh, tên, giá | ✅ |
| `cached_network_image` cho tối ưu bộ nhớ đệm hình ảnh | ✅ |
| Loading state (CircularProgressIndicator) | ✅ |
| Empty State khi không có kết quả tìm kiếm | ✅ |
| **Tìm kiếm** với debounce 500ms (`?search=...`) | ✅ |
| **Lọc theo danh mục** (`?categoryId=...`) | ✅ |
| **Lọc theo khoảng giá** (`?minPrice=...&maxPrice=...`) | ✅ *(Bổ sung)* |
| **Phân trang** (Pagination, lazy load thêm sản phẩm khi cuộn) | ✅ *(Bổ sung)* |
| Nút Yêu thích (Wishlist toggle) | ✅ *(Bổ sung)* |
| Điều hướng sang Product Detail khi tap | ✅ |

### Chi tiết kỹ thuật nổi bật:

- **Debounce 500ms:** `ProductViewModel` dùng `Timer` để delay API call khi gõ tìm kiếm.
- **Server-side filtering:** Tất cả filter đều gửi qua query params — NestJS dùng `$regex` (MongoDB) để tìm kiếm case-insensitive. Không dùng `.where()` phía client.
- **Infinite Scroll:** `isLoadingMore` state riêng biệt, dùng `ScrollController` để lazy-load trang tiếp theo.
- **Categories API:** Danh mục được fetch động từ `GET /categories` — không hardcode.

---

## 4. 🛍️ Product Detail Screen — Chi Tiết Túi Xách

**File:** `luxebag-fe/lib/views/screens/product/product_detail_screen.dart`
**Backend:** `GET /products/:id`

### Chức năng đã triển khai:

| Tính năng | Trạng thái |
|---|---|
| Fetch thông tin sản phẩm từ API theo ID | ✅ |
| Slider hình ảnh sản phẩm (nhiều ảnh) | ✅ |
| Hiển thị tên, giá, mô tả, danh mục, tồn kho | ✅ |
| Widget tăng/giảm số lượng (`- Số +`) | ✅ |
| Chặn vượt quá tồn kho (stock limit) | ✅ |
| Nút "Out of Stock" disabled khi `stock == 0` | ✅ |
| Nút Add to Cart → gọi `CartViewModel.addToCart()` | ✅ |
| SnackBar thông báo thêm vào giỏ thành công/thất bại | ✅ |
| Nút Wishlist (Yêu thích) | ✅ *(Bổ sung)* |
| Nút Chat với Admin từ trang sản phẩm | ✅ *(Bổ sung)* |

---

## 5. 🛒 Shopping Cart Screen — Giỏ Hàng

**File:** `luxebag-fe/lib/views/screens/cart/cart_screen.dart`
**ViewModel:** `lib/viewmodels/cart_viewmodel.dart`
**Repository:** `lib/repositories/cart_repository.dart`
**Backend:** `luxebag-be/src/modules/cart/cart.controller.ts`

### API Endpoints:
- `GET /cart` — Lấy giỏ hàng của user (populated với product info)
- `POST /cart/add` — Thêm sản phẩm vào giỏ
- `PUT /cart/update` — Cập nhật số lượng
- `DELETE /cart/remove/:productId` — Xóa sản phẩm khỏi giỏ

### Chức năng đã triển khai:

| Tính năng | Trạng thái |
|---|---|
| Fetch giỏ hàng từ API (`GET /cart`) — kèm JWT Token | ✅ |
| Hiển thị danh sách sản phẩm: ảnh, tên, đơn giá, số lượng | ✅ |
| Widget tăng/giảm số lượng → `PUT /cart/update` | ✅ |
| Xóa sản phẩm → `DELETE /cart/remove/:productId` | ✅ |
| Tính tổng tiền tự động (`totalAmount`) | ✅ |
| Tính phí vận chuyển (shipping fee logic) | ✅ |
| Empty State khi giỏ hàng trống + nút về trang chủ | ✅ |
| Optimistic Update: cập nhật UI ngay, đồng bộ API ngầm | ✅ |
| `isItemLoading` per-item: khóa nút từng sản phẩm khi đang xử lý | ✅ |
| Nút Checkout → màn hình thanh toán | ✅ |

### Chi tiết kỹ thuật nổi bật:

- **Per-item loading lock:** `Set<String> _loadingItems` trong `CartViewModel` đảm bảo mỗi nút tăng/giảm/xóa chỉ khóa item đó — không ảnh hưởng các item khác.
- **Optimistic Update:** UI cập nhật ngay lập tức; nếu API lỗi thì `fetchCart()` đồng bộ lại.
- **Không full page reload:** `notifyListeners()` chỉ rebuild các widget cần thiết, badge giỏ hàng trên AppBar tự cập nhật.

---

## 6. 💳 Checkout / Billing Screen — Thanh Toán

**File:** `luxebag-fe/lib/views/screens/checkout/checkout_screen.dart`
**ViewModel:** `lib/viewmodels/order_viewmodel.dart`
**Backend:** `POST /orders/checkout`

### Chức năng đã triển khai:

| Tính năng | Trạng thái |
|---|---|
| Tóm tắt đơn hàng (danh sách sản phẩm, tổng tiền, phí ship) | ✅ |
| Form nhập thông tin giao hàng (tên, số điện thoại, địa chỉ) | ✅ |
| Chọn phương thức thanh toán: COD hoặc CARD (mock) | ✅ |
| Form Validation trước khi đặt hàng | ✅ |
| Gọi `POST /orders/checkout` | ✅ |
| Backend: Tạo Order Document (status: `pending`) | ✅ |
| Backend: Trừ stock qua Inventory module | ✅ |
| Backend: Xóa giỏ hàng sau khi đặt hàng thành công | ✅ |
| Flutter: `clearCart()` local state sau khi nhận HTTP 200 | ✅ |
| Điều hướng sang màn hình xác nhận / lịch sử đơn hàng | ✅ |
| `createdAt` và `status` lưu đầy đủ trong MongoDB | ✅ |

---

## 7. 🔔 Notifications Screen — Thông Báo

**File:** `luxebag-fe/lib/views/screens/notification/notifications_screen.dart`
**ViewModel:** `lib/viewmodels/notification_viewmodel.dart`
**Backend:** `luxebag-be/src/modules/notifications/notifications.controller.ts`

### API Endpoints:
- `GET /notifications?page=1&limit=20` — Lấy danh sách thông báo của user
- `PUT /notifications/:id/read` — Đánh dấu một thông báo đã đọc
- `PUT /notifications/read-all` — Đánh dấu tất cả đã đọc

### Chức năng đã triển khai:

| Tính năng | Trạng thái |
|---|---|
| Fetch danh sách thông báo từ API | ✅ |
| Hiển thị ListView: tiêu đề, nội dung, thời gian | ✅ |
| Dấu chấm phân biệt Chưa đọc / Đã đọc (`isRead`) | ✅ |
| Tap vào thông báo → `PUT /notifications/:id/read` → cập nhật UI | ✅ |
| Đánh dấu tất cả đã đọc | ✅ *(Bổ sung)* |
| Phân trang thông báo | ✅ *(Bổ sung)* |
| Thông báo được tạo tự động khi Admin cập nhật trạng thái đơn hàng | ✅ |

### Ghi chú quan trọng:
> Thay vì tích hợp **Firebase Cloud Messaging (FCM)** như tài liệu gốc mô tả, nhóm triển khai hệ thống thông báo **in-app** thông qua REST API (`notifications` collection MongoDB). Thông báo được tạo tự động bởi NestJS backend khi Admin cập nhật trạng thái đơn hàng. Chat gateway có logic ghi log push notification khi receiver offline.

---

## 8. 🗺️ Map Store Location Screen — Bản Đồ Cửa Hàng

**File:** `luxebag-fe/lib/views/screens/map/store_map_screen.dart`

### Chức năng đã triển khai:

| Tính năng | Trạng thái |
|---|---|
| Tích hợp bản đồ với tọa độ cố định của cửa hàng | ✅ |
| Marker ghim vị trí showroom LuxeBag | ✅ |
| Zoom in/out mượt mà | ✅ |
| Bottom Card: tên cửa hàng, địa chỉ, số điện thoại, giờ làm việc | ✅ |
| Nút "Get Directions" → mở Google Maps app | ✅ |

### Chi tiết kỹ thuật:
- **Package:** Sử dụng `flutter_map` + `latlong2` (OpenStreetMap tiles — không cần API key) thay vì `google_maps_flutter`.
- **Tọa độ cửa hàng:** `LatLng(10.8411276, 106.8099619)` — FPT University TP. HCM (Lô E2a-7, Đường D1, Khu CNC, TP. Thủ Đức).
- **url_launcher:** Mở Google Maps navigation qua deep link `https://www.google.com/maps/dir/...`.

---

## 9. 💬 Messaging / Chat Screen — Chat Trực Tiếp (Realtime)

**File:** `luxebag-fe/lib/views/screens/chat/chat_screen.dart`
**File:** `luxebag-fe/lib/views/screens/chat/customer_chat_list_screen.dart`
**ViewModel:** `lib/viewmodels/chat_viewmodel.dart`
**Backend Gateway:** `luxebag-be/src/modules/chat/chat.gateway.ts`
**Backend Service:** `luxebag-be/src/modules/chat/chat.service.ts`

### Chức năng đã triển khai:

| Tính năng | Trạng thái |
|---|---|
| Kết nối Socket.IO với JWT Authentication handshake | ✅ |
| Tải lịch sử tin nhắn từ `GET /chat/history` (phân trang) | ✅ |
| Chat Bubble phân biệt màu sắc, căn lề (user/shop) | ✅ |
| Gửi tin nhắn realtime qua `socket.emit('chat:send', {...})` | ✅ |
| Nhận tin nhắn qua `socket.on('chat:receive', ...)` | ✅ |
| Chặn gửi tin nhắn trống | ✅ |
| Auto-scroll xuống cuối khi có tin mới | ✅ |
| **Optimistic Send:** Tin nhắn hiện ngay với temp ID, replace khi server xác nhận | ✅ |
| **Read Receipts:** `chat:read` event khi tin nhắn được đọc | ✅ *(Bổ sung)* |
| **Online Status:** `chat:user_online` / `chat:user_offline` events | ✅ *(Bổ sung)* |
| **Load More History:** Cuộn lên trên để tải thêm tin nhắn cũ | ✅ *(Bổ sung)* |
| **Order Reference in Chat:** Đính kèm mã đơn hàng vào tin nhắn | ✅ *(Bổ sung)* |
| **Danh sách hội thoại** (Chat List) với unread badge | ✅ *(Bổ sung)* |
| **Admin App tích hợp sẵn:** Admin chat từ cùng Flutter project | ✅ *(Bổ sung)* |

### Chi tiết kỹ thuật nổi bật (Socket.IO Gateway):

- **JWT Authentication:** `handleConnection()` xác thực token từ `client.handshake.auth.token` — từ chối kết nối nếu không hợp lệ.
- **Room-based Chat:** `roomId = sorted([userId1, userId2]).join('-')` — 2 người vào đúng phòng.
- **Instant Read Status:** Khi receiver đang online và trong cùng phòng → `isRead = true` ngay khi lưu.
- **Online Presence:** `userSockets` Map theo dõi socket ID của từng user đang kết nối.
- **Lưu trữ MongoDB:** Mỗi tin nhắn được lưu vào collection `messages` bởi `ChatService.saveMessage()`.

---

## 10. ⚙️ State Management — Provider / ChangeNotifier (MVVM)

### Cấu trúc thư mục tuân thủ MVVM:

```
lib/
├── models/          ← Pure data classes (fromJson / toJson)
├── repositories/    ← Data layer (gọi ApiService/Dio — không có UI logic)
├── services/        ← ApiService (Dio client + interceptors), TokenService
├── viewmodels/      ← ChangeNotifier — Business logic, State management
└── views/           ← UI Screens & Widgets (CHỈ đọc ViewModel, không có logic)
```

### Các ViewModel đã triển khai:

| ViewModel | File | Trách nhiệm |
|---|---|---|
| `AuthViewModel` | `auth_viewmodel.dart` | Trạng thái đăng nhập, thông tin user hiện tại, lưu/xóa JWT Token |
| `ProductViewModel` | `product_viewmodel.dart` | Danh sách sản phẩm, search với debounce, filter, phân trang, wishlist state |
| `CartViewModel` | `cart_viewmodel.dart` | Mảng giỏ hàng, tính tổng tiền, tăng/giảm/xóa item, per-item loading lock |
| `OrderViewModel` | `order_viewmodel.dart` | Tạo đơn hàng, lịch sử đơn hàng, fetch chi tiết đơn |
| `ChatViewModel` | `chat_viewmodel.dart` | Kết nối Socket.IO, lịch sử tin nhắn, gửi/nhận realtime, online status |
| `NotificationViewModel` | `notification_viewmodel.dart` | Danh sách thông báo, đánh dấu đã đọc |
| `InventoryViewModel` | `inventory_viewmodel.dart` | Quản lý tồn kho (Admin) |

### Luồng dữ liệu minh họa (Add to Cart):

```
ProductDetailScreen (UI)
  └─ tap "Add to Cart"
       └─ CartViewModel.addToCart(productId, qty)       [VIEWMODEL]
            └─ CartRepository.addToCart(...)             [REPOSITORY]
                 └─ ApiService.post('/cart/add', ...)    [SERVICE - Dio]
                      └─ NestJS CartController.addItem() [BACKEND]
                           └─ MongoDB: update cart document
                      ← HTTP 200 + updated cart JSON
                 ← parsed CartItemModel list
            └─ fetchCart() → notifyListeners()
       └─ CartIcon Badge tự cập nhật số (không reload trang)
```

### Nguyên tắc MVVM được tuân thủ:
- ✅ **Không** có `http.get()` hoặc `dio.post()` trong bất kỳ hàm `build()` của Widget.
- ✅ **Không** có logic tính toán tiền trong Widget — tất cả ở `CartViewModel.totalAmount`.
- ✅ Các Widget chỉ gọi `context.read<VM>().method()` hoặc `context.watch<VM>().property`.
- ✅ `notifyListeners()` được gọi sau mỗi thay đổi state.
- ✅ **`ChangeNotifierProxyProvider`** cho `ChatViewModel` — phụ thuộc vào `AuthViewModel` để lấy thông tin user khi kết nối Socket.

---

## 11. 👨‍💼 Admin Panel — Tính Năng Quản Trị *(Bổ Sung)*

> Admin đăng nhập bằng tài khoản có `role: 'admin'` → tự động điều hướng sang `/admin-home`.

| Tính năng Admin | File | Mô tả |
|---|---|---|
| Admin Dashboard | `admin_main_screen.dart` | Màn hình chính với tab navigation |
| Quản lý sản phẩm | `product_management_screen.dart` | CRUD sản phẩm: danh sách, tìm kiếm, xóa |
| Tạo/Sửa sản phẩm | `product_form_screen.dart` | Form thêm mới / cập nhật, upload ảnh lên **Cloudinary** |
| Quản lý tồn kho | `inventory_management_screen.dart` | Cập nhật stock, xem lịch sử nhập xuất |
| Xử lý đơn hàng | `order_fulfillment_screen.dart` | Xem đơn hàng, cập nhật trạng thái (pending → processing → shipped → completed) |
| Thống kê doanh thu | `revenue_stats_screen.dart` | Biểu đồ doanh thu theo kỳ (7d, 30d, 6m...) dùng `fl_chart` |
| Chat với khách hàng | `admin_chat_list_screen.dart` | Danh sách hội thoại + chat realtime |

---

## 12. 👤 Profile Screen — Thông Tin Cá Nhân *(Bổ Sung)*

**File:** `luxebag-fe/lib/views/screens/profile/profile_screen.dart`

| Tính năng | Trạng thái |
|---|---|
| Xem thông tin cá nhân (tên, email, số điện thoại) | ✅ |
| Cập nhật tên và số điện thoại (`PATCH /users/me`) | ✅ |
| Upload/thay đổi ảnh đại diện từ thiết bị (`image_picker`) | ✅ |
| Ảnh đại diện lưu trên **Cloudinary**, URL cập nhật trong MongoDB | ✅ |
| Đăng xuất (xóa token, reset state) | ✅ |

---

## 13. ❤️ Wishlist Screen *(Bổ Sung)*

**File:** `luxebag-fe/lib/views/screens/wishlist/wishlist_screen.dart`

- Xem danh sách sản phẩm đã thêm yêu thích.
- Toggle yêu thích từ trang chủ và trang chi tiết.
- Xóa khỏi wishlist trực tiếp trên màn hình.

---

## 🗺️ Bảng Ánh Xạ Màn Hình → Route

| Route | Màn hình | Quyền truy cập |
|---|---|---|
| `/login` | LoginScreen | Public |
| `/register` | RegisterScreen | Public |
| `/forgot-password` | ForgotPasswordScreen | Public |
| `/home` | MainScreen (Home, Search, Wishlist, Orders, Profile tabs) | Customer |
| `/product/:id` | ProductDetailScreen | Public |
| `/cart` | CartScreen | Customer |
| `/checkout` | CheckoutScreen | Customer |
| `/orders` | OrderHistoryScreen | Customer |
| `/orders/:id` | OrderDetailScreen | Customer |
| `/chat-list` | CustomerChatListScreen | Customer |
| `/chat` | ChatScreen | Customer / Admin |
| `/notifications` | NotificationsScreen | Customer |
| `/store-map` | StoreMapScreen | Public |
| `/admin-home` | AdminMainScreen | Admin only |
| `/admin/revenue-stats` | RevenueStatsScreen | Admin only |
| `/admin/product/new` | ProductFormScreen | Admin only |
| `/admin/product/edit` | ProductFormScreen (edit mode) | Admin only |

---

## 🏗️ Điểm Cộng Công Nghệ Vượt Chương Trình

| Công nghệ / Kỹ thuật | Mô tả |
|---|---|
| **NestJS Backend + MongoDB NoSQL** | Thay thế hoàn toàn Firebase, mô hình Enterprise thực tế |
| **Mongoose ODM + Schema Decorators** | Typed schema bằng TypeScript class |
| **JWT với HTTP-only Cookie** | Bảo mật hơn `localStorage` — chống XSS |
| **Access Token + Refresh Token** | Token tự gia hạn minh bạch với người dùng |
| **Role-Based Access Control (RBAC)** | `@Roles()` decorator + `RolesGuard` — 4 vai trò phân quyền |
| **Socket.IO Realtime Gateway** | Kết nối song công (bi-directional), xác thực bằng JWT |
| **Optimistic UI Updates** | UI phản hồi ngay, đồng bộ server ngầm — UX mượt mà |
| **Cloudinary** | Upload và lưu trữ ảnh sản phẩm + avatar trên CDN |
| **Zod Validation** (`nestjs-zod`) | Type-safe validation cho API request body |
| **API Throttling** (`@nestjs/throttler`) | Rate limiting chống spam request |
| **Helmet** | Security headers HTTP |
| **Swagger API Docs** (`@nestjs/swagger`) | Tự động generate tài liệu API |
| **Winston Logger** | Structured logging cho production |
| **Google Sign-In OAuth 2.0** | Đăng nhập bằng tài khoản Google |
| **Resend Email Service** | Gửi email reset mật khẩu |
| **fl_chart** | Biểu đồ doanh thu Admin dashboard |
| **GoRouter** | Declarative routing với deep link support |
| **OpenStreetMap (flutter_map)** | Bản đồ không cần API key, không phát sinh chi phí |
| **Admin Panel tích hợp** | Admin app trong cùng Flutter project, phân biệt qua role |
| **Product Snapshot** trong Order | Đóng băng giá và thông tin sản phẩm tại thời điểm mua |
| **Soft Delete** sản phẩm | `_destroy: true` — bảo toàn lịch sử đơn hàng |

---

## 📦 Dependencies Chính

### Flutter (pubspec.yaml)

| Package | Mục đích |
|---|---|
| `provider ^6.1.5` | State Management (ChangeNotifier) |
| `dio ^5.9.2` | HTTP Client với Interceptor |
| `go_router ^17.2.3` | Declarative Navigation |
| `shared_preferences ^2.5.5` | Lưu JWT Token cục bộ |
| `cached_network_image ^3.4.1` | Cache ảnh từ URL |
| `flutter_map ^8.3.0` | Bản đồ OpenStreetMap |
| `latlong2 ^0.9.1` | Tọa độ địa lý |
| `url_launcher ^6.3.1` | Mở URL, Google Maps navigation |
| `socket_io_client ^3.1.6` | Kết nối Socket.IO WebSocket |
| `google_sign_in ^7.2.0` | Đăng nhập Google OAuth |
| `image_picker ^1.1.2` | Chọn ảnh từ thiết bị |
| `fl_chart ^0.70.0` | Biểu đồ thống kê Admin |

### NestJS Backend (package.json)

| Package | Mục đích |
|---|---|
| `@nestjs/mongoose ^11.0.4` | Mongoose ODM Integration |
| `@nestjs/jwt ^11.0.2` | JWT Sign / Verify |
| `@nestjs/passport ^11.0.5` | Auth Strategy |
| `@nestjs/websockets ^11.1.27` | WebSocket Gateway |
| `@nestjs/platform-socket.io ^11.1.27` | Socket.IO adapter |
| `@nestjs/swagger ^11.4.4` | API Documentation |
| `@nestjs/throttler ^6.5.0` | Rate Limiting |
| `bcrypt ^6.0.0` | Password Hashing |
| `cloudinary ^2.10.0` | Image CDN Upload |
| `nestjs-zod ^5.4.0` | Zod Validation |
| `helmet ^8.2.0` | HTTP Security Headers |
| `resend ^6.12.4` | Email Service |
| `nest-winston ^1.10.2` | Logging |
| `google-auth-library ^10.9.0` | Google OAuth Verify |

---

*Tài liệu này mô tả chính xác những gì đã được triển khai trong dự án LuxeBag tính đến thời điểm nộp báo cáo.*
