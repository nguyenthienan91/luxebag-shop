# 📖 GUIDE.md – Hướng Dẫn Dành Cho Thành Viên Mới

> **Phiên bản:** 1.0 &nbsp;|&nbsp; **Cập nhật lần cuối:** 2026-06

---

## Mục Lục

1. [Tổng Quan Dự Án](#1-tổng-quan-dự-án)
2. [Tech Stack & Thư Viện Chính](#2-tech-stack--thư-viện-chính)
3. [Kiến Trúc Thư Mục & Quy Định Coding](#3-kiến-trúc-thư-mục--quy-định-coding)
4. [Luồng Dữ Liệu MVVM](#4-luồng-dữ-liệu-mvvm)
5. [Các Màn Hình & Điều Hướng](#5-các-màn-hình--điều-hướng)
6. [Hướng Dẫn Thiết Lập Môi Trường](#6-hướng-dẫn-thiết-lập-môi-trường)
7. [Quy Ước Code](#7-quy-ước-code)
8. [Xử Lý Lỗi & Xác Thực](#8-xử-lý-lỗi--xác-thực)

---

## 1. Tổng Quan Dự Án

**LuxeBag** là ứng dụng di động thương mại điện tử theo mô hình **B2C (Business-to-Consumer)** — một cửa hàng duy nhất bán túi xách xa xỉ (luxury bags) trực tiếp đến tay người tiêu dùng.

### Tính Năng Chính

| Tính năng | Mô tả |
|---|---|
| 🔐 Xác thực | Đăng ký, đăng nhập, quên mật khẩu, tự động đăng nhập lại |
| 🛍️ Sản phẩm | Duyệt, tìm kiếm, lọc theo danh mục & giá, phân trang vô hạn |
| ❤️ Wishlist | Lưu sản phẩm yêu thích, toggle nhanh (Optimistic Update) |
| 🛒 Giỏ hàng | Thêm, sửa số lượng, xóa sản phẩm |
| 📦 Đặt hàng | Thanh toán & xem lịch sử đơn hàng |
| 💬 Chat | Nhắn tin hỗ trợ khách hàng real-time |
| 🔔 Thông báo | Hiển thị thông báo đơn hàng, badge đếm tin chưa đọc |
| 🗺️ Bản đồ | Xem vị trí cửa hàng trên Google Maps |
| 👤 Hồ sơ | Chỉnh sửa thông tin, upload ảnh đại diện |

---

## 2. Tech Stack & Thư Viện Chính

### Frontend (Flutter)

| Thư viện | Phiên bản | Mục đích |
|---|---|---|
| `flutter` | SDK `^3.11.5` | Framework UI đa nền tảng |
| `provider` | `^6.1.5+1` | Quản lý trạng thái (State Management) |
| `dio` | `^5.9.2` | HTTP Client – gọi REST API |
| `go_router` | `^17.2.3` | Điều hướng màn hình (Navigation) |
| `shared_preferences` | `^2.5.5` | Lưu token xác thực cục bộ |
| `cached_network_image` | `^3.4.1` | Hiển thị & cache ảnh từ URL |
| `google_maps_flutter` | `^2.10.0` | Nhúng bản đồ Google Maps |
| `url_launcher` | `^6.3.1` | Mở link ngoài (trình duyệt, điện thoại) |
| `image_picker` | `^1.1.2` | Chọn ảnh từ thư viện / camera |

### Backend (NestJS)

- **Framework:** NestJS (TypeScript)
- **Database:** MongoDB
- **Port mặc định:** `8888`
- **Base URL API:** `http://localhost:8888/api`

---

## 3. Kiến Trúc Thư Mục & Quy Định Coding

Dự án Flutter nằm trong thư mục `luxebag-fe/` và tuân thủ kiến trúc **MVVM (Model – View – ViewModel)**.

```
luxebag-fe/
├── lib/
│   ├── main.dart                  # Entry point – khởi tạo MultiProvider
│   ├── models/                    # Tầng Model
│   │   ├── cart_item_model.dart
│   │   ├── category_model.dart
│   │   ├── message_model.dart
│   │   ├── notification_model.dart
│   │   ├── order_model.dart
│   │   ├── product_model.dart
│   │   └── user_model.dart
│   ├── repositories/              # Tầng Repository (gọi API)
│   │   ├── auth_repository.dart
│   │   ├── cart_repository.dart
│   │   ├── order_repository.dart
│   │   └── product_repository.dart
│   ├── services/                  # Tầng Service (hạ tầng kỹ thuật)
│   │   ├── api_service.dart       # Cấu hình Dio + Interceptors
│   │   └── token_service.dart     # Lưu/đọc JWT token
│   ├── viewmodels/                # Tầng ViewModel (logic nghiệp vụ + state)
│   │   ├── auth_viewmodel.dart
│   │   ├── cart_viewmodel.dart
│   │   ├── chat_viewmodel.dart
│   │   ├── notification_viewmodel.dart
│   │   ├── order_viewmodel.dart
│   │   └── product_viewmodel.dart
│   ├── views/                     # Tầng View (UI thuần túy)
│   │   ├── screens/               # Các màn hình chính
│   │   │   ├── auth/              # Login, Register, Forgot Password
│   │   │   ├── cart/              # Giỏ hàng
│   │   │   ├── chat/              # Chat hỗ trợ
│   │   │   ├── checkout/          # Thanh toán
│   │   │   ├── home/              # Trang chủ (danh sách sản phẩm)
│   │   │   ├── main/              # Shell điều hướng tab chính
│   │   │   ├── map/               # Bản đồ cửa hàng
│   │   │   ├── notification/      # Thông báo
│   │   │   ├── order/             # Lịch sử & chi tiết đơn hàng
│   │   │   ├── product/           # Chi tiết sản phẩm
│   │   │   ├── profile/           # Hồ sơ người dùng
│   │   │   ├── search/            # Tìm kiếm
│   │   │   └── wishlist/          # Danh sách yêu thích
│   │   └── widgets/               # Widget dùng chung
│   │       ├── common/            # Widget tổng quát (buttons, loaders...)
│   │       └── product/           # Widget riêng cho sản phẩm (card, skeleton)
│   └── utils/                     # Tiện ích & cấu hình toàn app
│       ├── app_colors.dart        # Bảng màu toàn cục
│       ├── app_router.dart        # Khai báo tất cả routes (GoRouter)
│       └── app_theme.dart         # ThemeData Material 3
├── run_dev.sh                     # Script khởi chạy dev (bắt buộc dùng)
└── pubspec.yaml                   # Khai báo dependencies
```

### Vai Trò Của Từng Tầng

#### 🔵 `models/` — Tầng Model
Chứa các **Plain Dart Object** đại diện cho dữ liệu từ API. Mỗi model có:
- Constructor với tất cả các trường dữ liệu
- Factory method `fromJson(Map<String, dynamic>)` để parse JSON từ API
- Không chứa logic nghiệp vụ hay state UI

```dart
// Ví dụ: models/product_model.dart
class ProductModel {
  final String id;
  final String title;
  final double currentPrice;
  // ...

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      // ...
    );
  }
}
```

#### 🟢 `services/` — Tầng Service (Hạ tầng kỹ thuật)
Cung cấp các **Singleton** phục vụ hạ tầng kỹ thuật, không liên quan đến business logic:

- **`ApiService`**: Cấu hình Dio với `BaseURL = http://localhost:8888/api`, timeout, và 2 interceptors:
  - `_AuthInterceptor`: Tự động đính kèm `Bearer <accessToken>` vào mỗi request (bỏ qua các endpoint `/auth/`).
  - `_RefreshInterceptor`: Tự động gọi `/auth/refresh-token` khi nhận lỗi `401`, lưu token mới và retry request gốc. Nếu refresh thất bại → xóa token, ném `AuthExpiredException`.
- **`TokenService`**: Lưu/đọc/xóa JWT token qua `SharedPreferences`.

#### 🟡 `repositories/` — Tầng Repository
Là lớp **trung gian giữa ViewModel và API**. Mỗi repository:
- Nhận `ApiService` qua constructor (dễ mock khi test)
- Thực hiện HTTP call qua `_apiService.dio`
- Parse raw JSON thành `Model` object
- **Không chứa state UI hay logic hiển thị**

```dart
// Ví dụ: repositories/product_repository.dart
class ProductRepository {
  final ApiService _apiService;

  Future<List<ProductModel>> fetchProducts({...}) async {
    final response = await _apiService.dio.get('/products', queryParameters: {...});
    final list = (response.data!['data']['list'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
    return list;
  }
}
```

#### 🔴 `viewmodels/` — Tầng ViewModel
**Trái tim của kiến trúc MVVM**. Mỗi ViewModel:
- Kế thừa `ChangeNotifier` để phát tín hiệu UI rebuild
- Gọi `Repository` để lấy/gửi dữ liệu
- Quản lý state: `isLoading`, `errorMessage`, danh sách data
- Gọi `notifyListeners()` sau mỗi thay đổi state
- **Không import bất kỳ widget Flutter nào** (chỉ `package:flutter/foundation.dart` nếu cần)

```dart
// Ví dụ: viewmodels/product_viewmodel.dart
class ProductViewModel extends ChangeNotifier {
  bool _isLoading = false;
  List<ProductModel> _products = [];

  bool get isLoading => _isLoading;
  List<ProductModel> get products => _products;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();          // UI hiển thị loading

    _products = await _repository.fetchProducts();

    _isLoading = false;
    notifyListeners();          // UI rebuild với data mới
  }
}
```

#### 🟣 `views/` — Tầng View
Chỉ chứa code **UI thuần túy**. View:
- **Đọc** state từ ViewModel bằng `Consumer<T>` hoặc `context.watch<T>()`
- **Gọi hành động** bằng `context.read<T>().method()` (không rebuild)
- **Không** chứa logic nghiệp vụ
- **Không** gọi API trực tiếp

---

## 4. Luồng Dữ Liệu MVVM

```
User Action
    │
    ▼
View (Widget)  ──── context.read<VM>().action() ────►  ViewModel
    │                                                       │
    │  Consumer<VM> / context.watch<VM>()           gọi Repository
    │                                                       │
    ◄──── notifyListeners() ◄──── setState ◄────  Repository (HTTP Dio)
                                                            │
                                                      NestJS Backend
```

### Ví Dụ Thực Tế: Màn Hình Trang Chủ

**Bước 1 – Khởi tạo dữ liệu trong `initState`:**
```dart
// views/screens/home/home_screen.dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Dùng context.read để gọi action (không lắng nghe rebuild)
    context.read<ProductViewModel>().loadInitial();
  });
}
```

**Bước 2 – Lắng nghe state bằng `Consumer`:**
```dart
// Mỗi khi ProductViewModel gọi notifyListeners(), builder này chạy lại
Widget _buildBody() {
  return Consumer<ProductViewModel>(
    builder: (context, vm, _) {
      if (vm.isLoading) return const CircularProgressIndicator();
      if (vm.errorMessage != null) return Text(vm.errorMessage!);
      return ListView.builder(
        itemCount: vm.products.length,
        itemBuilder: (_, i) => ProductCard(product: vm.products[i]),
      );
    },
  );
}
```

**Bước 3 – Trigger action từ user:**
```dart
// Gọi action trực tiếp, KHÔNG dùng context.watch (tránh rebuild không cần thiết)
TextField(
  onChanged: (v) => context.read<ProductViewModel>().setSearchQuery(v),
)
```

**Lưu ý quan trọng:**

| Dùng | Khi nào |
|---|---|
| `context.read<T>()` | Gọi method / action — KHÔNG rebuild widget |
| `context.watch<T>()` | Đọc state, widget sẽ rebuild khi state thay đổi |
| `Consumer<T>` | Rebuild một phần UI nhỏ (hiệu quả hơn `context.watch` ở root) |

---

## 5. Các Màn Hình & Điều Hướng

Điều hướng được quản lý bởi **`go_router`**, khai báo tập trung tại `utils/app_router.dart`.

| Route | Tên | Màn hình |
|---|---|---|
| `/home` | `home` | Trang chủ (mặc định) |
| `/login` | `login` | Đăng nhập |
| `/register` | `register` | Đăng ký |
| `/forgot-password` | `forgot-password` | Quên mật khẩu |
| `/product/:id` | `product-detail` | Chi tiết sản phẩm |
| `/cart` | `cart` | Giỏ hàng |
| `/checkout` | `checkout` | Thanh toán |
| `/orders` | `orders` | Lịch sử đơn hàng |
| `/orders/:id` | `order-detail` | Chi tiết đơn hàng |
| `/chat` | `chat` | Chat hỗ trợ |
| `/notifications` | `notifications` | Thông báo |
| `/store-map` | `store-map` | Bản đồ cửa hàng |

**Cách điều hướng:**
```dart
// Push sang màn hình mới (có thể back lại)
context.push('/product/abc123');

// Go (replace, không thêm vào stack)
context.go('/home');

// Truyền object qua extra
context.push('/orders/${order.id}', extra: order);
```

---

## 6. Hướng Dẫn Thiết Lập Môi Trường

### Yêu Cầu Hệ Thống

| Công cụ | Yêu cầu | Kiểm tra |
|---|---|---|
| Flutter SDK | `^3.11.5` | `flutter --version` |
| Dart SDK | Tích hợp trong Flutter | `dart --version` |
| Android Studio / VS Code | Bất kỳ phiên bản nào | — |
| Android SDK & ADB | Tích hợp trong Android Studio | `adb version` |
| Git Bash (Windows) | Bắt buộc để chạy `run_dev.sh` | — |
| Node.js & npm | Để chạy Backend NestJS | `node --version` |

### Bước 1 – Clone & Cài Đặt

```bash
# Clone repository
git clone <url-repo>
cd Luxebag

# Cài đặt dependencies Flutter
cd luxebag-fe
flutter pub get
```

### Bước 2 – Khởi Chạy Backend

```bash
# Di chuyển vào thư mục backend
cd luxebag-be

# Cài đặt dependencies Node.js (nếu chưa có)
npm install

# Khởi động NestJS (lắng nghe ở port 8888)
npm run start:dev
```

> **Lưu ý:** Backend phải đang chạy trước khi mở app Flutter.

### Bước 3 – Chạy Flutter App *(Quan trọng!)*

> ⚠️ **BẮT BUỘC** phải chạy Flutter thông qua script `run_dev.sh`, **KHÔNG** chạy `flutter run` trực tiếp.

**Lý do:** Script này tự động chạy `adb reverse tcp:8888 tcp:8888` để tunnel port từ máy tính vào thiết bị Android/Emulator. Nếu không có bước này, app trên thiết bị sẽ **không thể kết nối được với backend** đang chạy trên `localhost` của máy tính.

#### Cách chạy (dùng Git Bash):

```bash
# Di chuyển vào thư mục Flutter
cd luxebag-fe

# Chạy script (tự động chọn thiết bị/emulator khả dụng)
./run_dev.sh

# Hoặc chỉ định thiết bị cụ thể (lấy ID bằng lệnh: adb devices)
./run_dev.sh emulator-5554
```

#### Script `run_dev.sh` làm gì?

```
1. Kiểm tra ADB có tồn tại không
        ↓
2. Chạy: adb reverse tcp:8888 tcp:8888
   (Mọi request đến localhost:8888 trên thiết bị → chuyển tiếp về localhost:8888 trên máy tính)
        ↓
3. Chạy: flutter run -d <device>
```

#### Xử Lý Lỗi Thường Gặp

| Lỗi | Nguyên nhân | Giải pháp |
|---|---|---|
| `adb reverse` thất bại | Emulator chưa khởi động | Mở Android Emulator trước, sau đó chạy lại `./run_dev.sh` |
| `Connection refused` | Backend chưa chạy | Chạy `npm run start:dev` trong `luxebag-be/` |
| `adb not found` | Android SDK chưa được cài | Cài Android Studio → SDK Tools → Platform Tools |
| Thiết bị không hiện | USB Debugging chưa bật | Bật Developer Options → USB Debugging trên điện thoại |

---

## 7. Quy Ước Code

### Đặt Tên File & Class

| Loại | Quy tắc | Ví dụ |
|---|---|---|
| File | `snake_case` | `product_viewmodel.dart` |
| Class/Widget | `PascalCase` | `ProductViewModel`, `HomeScreen` |
| Biến/Method | `camelCase` | `isLoading`, `fetchProducts()` |
| Hằng số | `camelCase` | `_pageSize`, `_baseUrl` |

### Singleton Pattern
`ApiService` và `TokenService` đều triển khai **Singleton** để đảm bảo chỉ có một instance duy nhất trong app:

```dart
class ApiService {
  ApiService._();                                   // Constructor private
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;               // Luôn trả về instance cũ
}
```

### Dependency Injection Nhẹ
ViewModel và Repository đều nhận dependency qua constructor với giá trị default:

```dart
class ProductViewModel extends ChangeNotifier {
  final ProductRepository _repository;

  // Khi dùng thật: ProductViewModel() → tự tạo ProductRepository()
  // Khi test:     ProductViewModel(repository: MockProductRepository())
  ProductViewModel({ProductRepository? repository})
      : _repository = repository ?? ProductRepository();
}
```

### Khai Báo ViewModel trong `main.dart`
Tất cả ViewModel được khai báo tập trung một lần duy nhất tại root của app:

```dart
// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthViewModel()),
    ChangeNotifierProvider(create: (_) => ProductViewModel()),
    ChangeNotifierProvider(create: (_) => CartViewModel()),
    ChangeNotifierProvider(create: (_) => OrderViewModel()),
    ChangeNotifierProvider(create: (_) => ChatViewModel()),
    ChangeNotifierProvider(create: (_) => NotificationViewModel()),
  ],
  child: const _AppBootstrap(),
)
```

---

## 8. Xử Lý Lỗi & Xác Thực

### Cơ Chế JWT & Auto-Refresh Token

```
App khởi động
      │
      ▼
tryAutoLogin() ── lấy accessToken từ SharedPreferences
      │
      ├─ Không có token ──► Cho phép dùng app (chưa đăng nhập)
      │
      └─ Có token ──► GET /users/me
                          │
                          ├─ Thành công ──► Khôi phục phiên đăng nhập
                          └─ Thất bại  ──► Xóa token, yêu cầu đăng nhập lại
```

**Tự Động Làm Mới Token (trong `_RefreshInterceptor`):**

Khi bất kỳ API nào trả về `401 Unauthorized`:
1. Gọi `POST /auth/refresh-token` với `refreshToken` đang lưu
2. Lưu `accessToken` và `refreshToken` mới vào `SharedPreferences`
3. Retry lại request gốc với token mới
4. Nếu refresh thất bại → ném `AuthExpiredException` → ViewModel bắt và hiển thị thông báo, điều hướng về Login

### Bảng Mã Lỗi HTTP

| Mã | Ý nghĩa | Thông báo hiển thị |
|---|---|---|
| `400` | Dữ liệu không hợp lệ | "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại." |
| `401` | Sai credentials | "Email hoặc mật khẩu không đúng." |
| `403` | Không có quyền | "Bạn không có quyền thực hiện hành động này." |
| `404` | Không tìm thấy | "Không tìm thấy tài nguyên." |
| `409` | Xung đột dữ liệu | "Email này đã được đăng ký." |
| `500` | Lỗi server | "Lỗi server. Vui lòng thử lại sau." |
| Timeout | Hết giờ kết nối | "Không thể kết nối đến server. Vui lòng kiểm tra mạng." |

---

*Nếu có thắc mắc, liên hệ Tech Lead hoặc tạo issue trong repository.*
