# CARTA - Inventory Management System
## Final Project Report

---

### 1. Project Overview

**Carta** is a mobile inventory management application designed for retail store owners and managers. It enables them to manage stock across multiple stores, categorize products by type and brand, update stock levels based on deliveries, and verify product authenticity via barcode/QR code scanning — all available offline.

**Target Platform:** Android 8.1.0 (API Level 27) and above  
**Version:** 1.0.0

---

### 2. Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | Flutter 3.x | Cross-platform mobile UI framework |
| **Language** | Dart | Application programming language |
| **Database** | SQLite (via `sqflite`) | Local offline relational database |
| **State Management** | Provider (`provider`) | Reactive state management |
| **Barcode/QR Scanner** | `mobile_scanner` | Camera-based barcode & QR code scanning |
| **Notifications** | `flutter_local_notifications` | Local push notifications with sound |
| **Date Formatting** | `intl` | Date/time formatting utilities |
| **File System** | `path_provider`, `path` | Local file system path resolution |
| **Build System** | Gradle (Kotlin DSL) | Android build configuration |
| **Min SDK** | Android API 27 (8.1 Oreo) | Minimum supported Android version |

---

### 3. Application Architecture

```
lib/
├── main.dart                          # App entry point, routes, theme
├── models/
│   ├── store.dart                     # Store data model
│   ├── category.dart                  # Category data model
│   └── product.dart                   # Product data model
├── services/
│   ├── database_service.dart          # SQLite database CRUD operations
│   └── notification_service.dart      # Local notification management
├── providers/
│   └── inventory_provider.dart        # Centralized state management
└── screens/
    ├── splash_screen.dart             # Animated launch screen
    ├── stores_screen.dart             # Store listing & management
    ├── store_detail_screen.dart       # Categories, stats overview
    ├── products_screen.dart           # Product list, search, filter
    ├── scanner_screen.dart            # Barcode/QR code scanner
    └── low_stock_screen.dart          # Low stock alerts & restock
```

**Design Pattern:** Provider pattern (a simplified variant of MVVM)
- **Models** — Plain Dart classes with serialization (toMap/fromMap)
- **Services** — Singleton services for database and notifications
- **Providers** — ChangeNotifier-based reactive state holders
- **Screens** — Stateful/Stateless widgets consuming provider state

---

### 4. Database Schema (SQLite)

Three normalized tables with foreign key constraints:

**`stores`**
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| name | TEXT | Store name |
| address | TEXT | Store address |
| phone | TEXT | Contact phone (nullable) |
| created_at | TEXT | ISO 8601 timestamp |

**`categories`**
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| store_id | INTEGER FK | References stores(id) |
| name | TEXT | Category name |
| description | TEXT | Category description (nullable) |

**`products`**
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| store_id | INTEGER FK | References stores(id) |
| category_id | INTEGER FK | References categories(id) |
| name | TEXT | Product name |
| brand | TEXT | Product brand |
| barcode | TEXT | Barcode/QR code value (nullable) |
| quantity | INTEGER | Current stock count |
| restock_threshold | INTEGER | Low-stock threshold (default: 10) |
| price | REAL | Unit price |
| verified | INTEGER | Authenticity flag (0/1) |
| last_updated | TEXT | ISO 8601 timestamp |

---

### 5. Features Implementation

#### 5.1 Splash Screen
- Animated launch screen with fade-in and elastic scale animations
- Gradient background (navy blue) with Carta branding
- Auto-navigates to Stores screen after 3 seconds
- Loading indicator during initialization

#### 5.2 Multi-Store Management
- View all stores in a card-based list
- Add new stores with name, address, and phone
- Delete stores via long-press context menu
- Select a store to enter its detail view

#### 5.3 Category Management
- Grid view of categories within each store
- Dynamic category icons based on name (Beverages, Snacks, etc.)
- Add/delete categories
- Tap a category to filter products

#### 5.4 Product Management
- Full CRUD (Create, Read, Update, Delete) for products
- Quick quantity update dialog
- Detailed product view in a bottom sheet
- Stock level indicators (color-coded: green = healthy, orange = low)
- Verified product badge (green checkmark)

#### 5.5 Search & Filter
- **Text search:** Search products by name, brand, or barcode
- **Category filter:** Tap a category to see only its products
- **Brand filter:** Horizontal filter chips for brand-based filtering
- **Combined filters:** Category + brand + text search work together
- **Clear all:** One-tap filter reset

#### 5.6 Barcode/QR Code Scanning
- Real-time camera-based scanning via `mobile_scanner`
- Supports 1D barcodes (EAN, UPC, Code128) and 2D codes (QR, Data Matrix)
- Torch (flashlight) toggle and camera switch
- Scanning overlay with visual guide frame
- Product lookup: Scanned code matched against store inventory
- Displays product details, stock level, and verification status
- "Product Not Found" handling for unknown barcodes

#### 5.7 Push Notifications
- **Restock alerts:** Triggered when product quantity drops to/below threshold
- **Verification results:** Notification when a product is verified or fails verification
- Separate notification channels with sound and vibration
- Uses `flutter_local_notifications` — works fully offline

#### 5.8 Low Stock Dashboard
- Dedicated screen showing all products below restock threshold
- Visual progress bars indicating stock depletion
- Quick restock dialog (add delivered units)
- Bulk notification button to alert on all low-stock items
- Color coding: orange for low, red for zero stock

#### 5.9 Offline Use
- **100% offline-capable** — all data stored locally in SQLite
- No internet connection required for any feature
- Database seeded with sample data on first launch
- Data persists across app restarts

---

### 6. Seed Data

The app ships with sample data for immediate testing:

**Stores:**
1. Downtown Mart (123 Main Street, Downtown)
2. Campus Corner Shop (45 University Ave)

**Sample Products:**
- Coca-Cola 500ml, Fanta Orange 500ml, Voltic Water 1.5L (Beverages)
- Pringles Original, McVities Digestive (Snacks)
- Dettol Soap (Personal Care)
- A4 Notebook, BIC Cristal Pen (Stationery)
- Sprite 500ml (Beverages)

Several products are intentionally set below their restock thresholds to demonstrate the low-stock alert system.

---

### 7. User Flow

```
App Launch → Splash Screen (3s)
  └→ Stores List
      └→ Select Store → Store Detail
          ├→ View Stats (products, categories, low stock)
          ├→ Select Category → Products List (filtered)
          ├→ "All Products" → Products List (unfiltered)
          ├→ QR/Barcode Scanner → Product Lookup / Verification
          └→ Low Stock Alerts → Restock Products
```

---

### 8. Android Configuration

- **Application ID:** `com.carta.inventory`
- **Minimum SDK:** 27 (Android 8.1 Oreo)
- **Permissions:**
  - `CAMERA` — barcode/QR scanning
  - `VIBRATE` — notification vibration
  - `POST_NOTIFICATIONS` — push notifications (Android 13+)
- **Build:** Release APK signed with debug keys

---

### 9. APK Output

The release APK is located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

To install on a device:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or transfer the APK file directly to the Android device and install from the file manager.

---

### 10. Dependencies Summary

| Package | Version | License | Purpose |
|---------|---------|---------|---------|
| `flutter` | SDK | BSD-3 | UI framework |
| `sqflite` | ^2.4.2 | BSD-2 | SQLite database |
| `path` | ^1.9.1 | BSD-3 | Path manipulation |
| `path_provider` | ^2.1.5 | BSD-3 | File system paths |
| `mobile_scanner` | ^6.0.5 | BSD-3 | Barcode/QR scanning |
| `flutter_local_notifications` | ^18.0.1 | BSD-3 | Local notifications |
| `provider` | ^6.1.2 | MIT | State management |
| `intl` | ^0.20.2 | BSD-3 | Internationalization |
| `cupertino_icons` | ^1.0.8 | MIT | iOS-style icons |

---

### 11. How to Build

```bash
# Install dependencies
flutter pub get

# Run in debug mode (with device connected)
flutter run

# Build release APK
flutter build apk --release

# The APK is at: build/app/outputs/flutter-apk/app-release.apk
```

---

*Report generated for Carta v1.0.0 — April 2026*
