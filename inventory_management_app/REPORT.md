# CARTA - Inventory Management System
## Updated Project Report (v1.2.0)

---

### 1. Project Overview

**Carta** is a mobile inventory management application designed for retail store owners and managers. It enables them to manage stock across multiple stores, categorize products by type and brand, track incoming inventory through purchase orders and deliveries, manually flag low-stock items, verify product authenticity via barcode/QR code scanning, and receive time-based reorder suggestions — all available offline.

**Target Platform:** Android 8.1.0 (API Level 27) through Android 15 (API Level 35)  
**Version:** 1.2.0

---

### 2. What's New in v1.1.0

This update implements all features from both the **Implementation Activity** (Activity 1) and the **Team Progress Update** (Activity 2) specifications.

#### New Features Added

**Dashboard (Decision Center)**
- Signal-based dashboard integrated into the Store Detail screen
- Products flagged as "Low Stock" with visual count cards
- "Reorder Soon" alerts based on time since last delivery
- Recent deliveries list with supplier and date info
- Quick actions: "Add Purchase Order", "Flag Low Stock", "Scan"
- Pending purchase order count displayed

**Purchase Orders System**
- New `purchase_orders` SQLite table with full CRUD operations
- Create new purchase orders with product, supplier, quantity, and notes
- Mark orders as delivered (auto-updates product quantity and last delivery date)
- Tab-filtered views: All, Pending, Delivered
- Supplier and date tracking on every order

**Product Enhancements**
- `supplier` field added to products
- `last_delivery_date` tracking for time-based reorder logic
- `low_stock_flagged` boolean for manual low-stock flagging by store managers
- `reorder_interval_days` for customizable reorder frequency per product
- Status badges: "Low Stock" (manual flag or threshold), "Reorder Soon" (time-based), "OK"

**Manual Low Stock Flagging**
- "Mark as Low Stock" button in product detail view
- "Remove Low Stock Flag" button to clear manual flags
- Flagged items appear in the Low Stock dashboard with a flag indicator
- Marking an order as delivered automatically clears the low stock flag

**Time-Based "Reorder Soon" Logic**
- Tracks days since last delivery vs. typical reorder interval
- Products exceeding their reorder interval show "Reorder Soon" status
- Dashboard displays reorder-soon products as alerts
- Notifications can be sent for all reorder-soon items

**Haptic Feedback**
- Light impact on taps and selections
- Medium impact on create/add actions
- Heavy impact on delete/deliver/bulk notification actions
- Integrated throughout all screens using Flutter's `HapticFeedback` API

**Sound Alerts**
- Notification sounds enabled on all notification channels
- Separate channels: restock alerts, verification results, delivery updates, reorder reminders
- All channels configured with `playSound: true` and vibration

**Android Compatibility**
- `compileSdk` set to 35 (Android 15 — latest)
- `targetSdk` set to 35 (Android 15 — latest)
- `minSdk` remains 27 (Android 8.1 Oreo)
- `enableOnBackInvokedCallback` enabled in manifest for Android 14+ predictive back gesture
- Core library desugaring maintained for Java 8+ API compatibility on older devices

**UI Modernization**
- Updated color scheme: Navy/Slate (`#0F172A`, `#1E3A5F`, `#0EA5E9`)
- Cards with zero elevation and subtle background color for a cleaner look
- Rounded corners (16px cards, 12px buttons, 20px dialogs)
- Bottom sheets instead of dialogs for creation forms (better mobile UX)
- Improved typography with weight hierarchy
- Status-colored badges throughout (green=OK, amber=reorder, red=low)
- Corner-accented scanner overlay
- Consistent icon usage with `_rounded` variant
- FAB extended style with labels for primary actions

---

### 3. Updated Architecture

```
lib/
├── main.dart                          # App entry point, routes, Material 3 theme
├── models/
│   ├── store.dart                     # Store data model
│   ├── category.dart                  # Category data model
│   ├── product.dart                   # Product model (+ supplier, delivery, flag fields)
│   └── purchase_order.dart            # NEW: Purchase order data model
├── services/
│   ├── database_service.dart          # SQLite CRUD (+ purchase orders, new columns)
│   └── notification_service.dart      # Notifications (+ delivery, reorder channels)
├── providers/
│   └── inventory_provider.dart        # State management (+ PO, flagging, haptics)
└── screens/
    ├── splash_screen.dart             # Animated launch screen
    ├── stores_screen.dart             # Store listing & management
    ├── store_detail_screen.dart       # Dashboard + categories + quick actions
    ├── products_screen.dart           # Product list with status badges & flags
    ├── scanner_screen.dart            # Barcode/QR code scanner
    ├── low_stock_screen.dart          # Low stock alerts, flags & restock
    └── purchase_orders_screen.dart    # NEW: Purchase order management
```

---

### 4. Updated Database Schema (SQLite)

**`products`** (updated columns marked with ★)
| Column | Type | Description |
|--------|------|-------------|
| supplier ★ | TEXT | Supplier name (nullable) |
| last_delivery_date ★ | TEXT | ISO 8601 timestamp of last delivery |
| low_stock_flagged ★ | INTEGER | Manual low-stock flag (0/1) |
| reorder_interval_days ★ | INTEGER | Typical days between deliveries (default: 7) |

**`purchase_orders`** (new table)
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment |
| store_id | INTEGER FK | References stores(id) |
| product_id | INTEGER FK | References products(id) |
| product_name | TEXT | Product display name |
| supplier | TEXT | Supplier name |
| quantity | INTEGER | Order quantity |
| order_date | TEXT | ISO 8601 order creation date |
| delivery_date | TEXT | ISO 8601 delivery date (nullable) |
| delivered | INTEGER | Delivery status (0/1) |
| notes | TEXT | Optional order notes |

Database version upgraded to v2 with migration support from v1.

---

### 5. Updated User Flow

```
App Launch → Splash Screen (3s)
  └→ Stores List
      └→ Select Store → Store Detail (Dashboard)
          ├→ View Stats (products, low stock, pending orders)
          ├→ Quick Actions (Add Order, Low Stock, Scan)
          ├→ View Reorder Soon / Flagged Low Stock alerts
          ├→ View Recent Deliveries
          ├→ Select Category → Products List (filtered)
          ├→ "View All Products" → Products List (unfiltered)
          │   ├→ Product Detail → Mark/Remove Low Stock Flag
          │   └→ Product Detail → Delete
          ├→ QR/Barcode Scanner → Product Lookup / Verification
          ├→ Low Stock Alerts → Restock Products / Remove Flags
          └→ Purchase Orders → Create / Mark Delivered / Delete
```

---

### 6. Feature Checklist (vs. PDF Specifications)

| Feature | Implementation Activity | Team Progress Update | Status |
|---------|------------------------|---------------------|--------|
| Splash Screen | ✓ Required | - | ✅ Implemented |
| Multi-Store Management | ✓ Required | - | ✅ Implemented |
| Category Management | ✓ Required | - | ✅ Implemented |
| Product CRUD | ✓ Required | - | ✅ Implemented |
| Search & Filter | ✓ Required | Search Screen | ✅ Implemented |
| Barcode/QR Scanning | ✓ Required | Camera | ✅ Implemented |
| Push Notifications | ✓ Required | Sound | ✅ Implemented |
| Low Stock Dashboard | ✓ Required | Low Stock Flag Screen | ✅ Implemented |
| Offline Use | ✓ Required | - | ✅ Implemented |
| Dashboard (Decision Center) | - | ✓ Required | ✅ **NEW** |
| Purchase Orders | - | ✓ Required | ✅ **NEW** |
| Supplier Tracking | - | ✓ Required | ✅ **NEW** |
| Last Delivery Date | - | ✓ Required | ✅ **NEW** |
| Reorder Soon (Time-Based) | - | ✓ Required | ✅ **NEW** |
| Manual Low Stock Flag | - | ✓ Required | ✅ **NEW** |
| Status Badges (Low/Reorder/OK) | - | ✓ Required | ✅ **NEW** |
| Haptic Feedback | - | ✓ Required | ✅ **NEW** |
| Sound Alerts | - | ✓ Required | ✅ **NEW** |
| Cloud Database Backup | - | ✓ Required | ✅ **NEW** |
| Authentication System | - | ✓ Required | ✅ **NEW** |

---

### 7. What's New in v1.2.0 (Cloud & Security Update)

This update drastically evolves the application architecture from a purely local tool into a robust, cloud-backed **Offline-First Application**.

**Authentication System**
- Complete Email/Password user authentication integrated with Supabase Auth.
- Brand new `login_screen.dart` and `signup_screen.dart` utilizing modern frosted-glass aesthetics.
- Secured application routing: Animated `SplashScreen` silently checks `Supabase.instance.client.auth.currentSession` before granting access to the persistent Dashboard.
- Secure standard logout functionality inside the main Application Bar.

**Hybrid Cloud Architecture (Supabase x SQLite)**
- Strict **Separation of Concerns**: The high-speed local engine (`sqflite`) remains completely decoupled from the cloud layer, guaranteeing lightning-fast scans and offline usability if network connections drop.
- **Auto-Sync Engine**: The centralized `InventoryProvider` orchestrates state. Every successful local write operation instantly fires a background HTTP upsert to the remote Supabase PostgreSQL database.
- **Manual Sync**: An explicitly requested "Sync to Cloud" feature is embedded as a designated Quick Action. It sequentially iterates all local tables (Stores, Categories, Products, Purchase Orders) and guarantees 1:1 mirroring to the cloud.
- Environment variables secured using `flutter_dotenv` (`.env`).

---

*Report generated for Carta v1.2.0 — April 2026*
