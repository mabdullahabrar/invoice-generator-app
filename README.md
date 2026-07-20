<div align="center">

# 🧾 Invoice Generator App

### A full-featured Flutter app to create, manage, and export professional invoices

<p>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/status-completed-brightgreen?style=for-the-badge" />
</p>

</div>

---

## 📱 Project Overview

Invoice Generator is a Flutter app for small businesses and freelancers to
create, manage, and share professional invoices entirely offline. It
covers the full invoice lifecycle: building an invoice with line items
and automatic totals, tracking its payment status, exporting it as a
polished PDF, and reviewing overall business performance from a
dashboard — all backed by a local database, with no server required.

It runs on **both Android and Web (Chrome)** from the same codebase, which
shaped a few architecture decisions below (see "Why Hive instead of
SQLite" and "Why byte-based PDFs/exports").

<!--
  📸 Add screenshots once you have them — see the Screenshots section below.
  ![Dashboard](docs/screenshots/dashboard.png)
-->

## ✨ Features

### Core
- Create invoices with auto-generated, sequential invoice numbers (e.g. `INV-001`)
- Pick Invoice Date and Due Date
- Business info (name, address, email, phone) — pre-filled from Settings, editable per invoice
- Customer info (name, address, email, phone)
- Multiple product/service line items, each with quantity, unit price, and an optional discount %
- Automatic Subtotal, Tax, and Grand Total calculation, live as you type
- Notes / payment instructions field
- All invoices saved locally (via `hive`)

### Invoice Management
- View all invoices in a searchable, filterable list
- Search by invoice number or customer name
- Filter by status (All / Paid / Unpaid / Overdue)
- Edit any invoice
- Delete an invoice, with a confirmation dialog (swipe-to-delete or menu)
- Duplicate an invoice (generates a fresh invoice number and resets status)
- Mark invoices as **Paid**, **Unpaid**, or **Overdue**

### Export & Sharing
- Generate a clean, professional invoice PDF
- Download/save the PDF
- Share the PDF through the OS share sheet (WhatsApp, Email, Drive, etc.)
- Print directly from the app (or the browser's print dialog on Web)

### Dashboard
- Gradient hero card with Total Revenue and a quick "New Invoice" action
- Total Invoices, Paid, Unpaid, and Overdue counts at a glance
- Monthly income summary (last 6 months, paid invoices only)
- Recent invoices list with quick access

### Settings
- Upload a company logo (shown on generated PDFs)
- Configure company details (name, address, email, phone)
- Select currency (USD, EUR, GBP, PKR, INR, AED, SAR, CAD, AUD)
- Set a default tax percentage applied to new invoices
- Customize the invoice number prefix (e.g. `INV-`, `2026-`)

### Bonus
- 🌙 **Dark Mode** — toggle in Settings, applied app-wide instantly
- 📷 **Company Logo Upload** — picked from gallery, embedded into PDFs
- 📊 **Monthly Income Summary** — revenue-by-month visualization on the dashboard
- 💾 **Backup & Restore** — export all invoices to a JSON file and restore from any such file later
- 📤 **Export Invoice List as CSV** — spreadsheet-friendly export of every invoice

## 🛠️ Packages Used

| Package | Purpose |
|---|---|
| [`provider`](https://pub.dev/packages/provider) | App-wide state management (settings, theme) |
| [`hive`](https://pub.dev/packages/hive) / [`hive_flutter`](https://pub.dev/packages/hive_flutter) | Local storage for invoices — works on Android, iOS, desktop, **and Web** |
| [`pdf`](https://pub.dev/packages/pdf) | Generating the invoice PDF document |
| [`printing`](https://pub.dev/packages/printing) | Printing/downloading the generated PDF — cross-platform incl. Web |
| [`share_plus`](https://pub.dev/packages/share_plus) | Sharing the PDF/backup/CSV through the OS share sheet |
| [`file_picker`](https://pub.dev/packages/file_picker) | Picking a backup file back in for Restore |
| [`image_picker`](https://pub.dev/packages/image_picker) | Picking a company logo (read as bytes, Web-safe) |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | App typography |
| [`intl`](https://pub.dev/packages/intl) | Date formatting |
| [`uuid`](https://pub.dev/packages/uuid) | Unique IDs for invoice line items |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Persisting company/app settings (also Web-supported) |

### Why Hive instead of SQLite?

The task suggested `sqflite` or `hive`. `sqflite` has **no Web
implementation at all** — it only works on Android/iOS/desktop — so an
app built on it can't run in a browser. Hive is pure Dart and ships a
real Web backend (IndexedDB), so the exact same database code runs
unmodified on both Android and Chrome.

### Why byte-based PDFs/exports?

Similarly, `dart:io` (`File`, `Directory`) and `path_provider` don't
exist on Web. Every export in this app — PDF, JSON backup, CSV — is
built as raw bytes and handed to `printing`/`share_plus`, which know how
to turn bytes into "download this file" on Web and "open the native
share sheet" on mobile, from the same call site.

## 📂 Project Structure

```
lib/
├── screens/     # All app screens (dashboard, invoice list/form/detail, settings)
├── widgets/     # Reusable UI pieces (stat cards, invoice cards, status badges, item rows)
├── models/      # Invoice, InvoiceItem, InvoiceStatus data classes
├── services/    # Business logic: invoice CRUD, settings, PDF export, backup/CSV
├── database/    # Hive-backed storage helper (single source of truth for the schema)
├── pdf/         # PDF document layout/generation logic
├── utils/       # Constants, validators, currency formatting, theming
└── main.dart    # App entry point, Hive init, Provider setup, theming
```

## 🚀 Setup Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) with the Flutter and Dart plugins
- Chrome (for Web)

### Run it locally

```bash
git clone https://github.com/<your-username>/<your-repo-name>.git
cd <your-repo-name>
flutter pub get
```

**Run on Chrome (Web):**
```bash
flutter run -d chrome
```
Or in Android Studio: pick **Chrome** from the device dropdown at the
top, then hit ▶️ Run.

**Run on an Android emulator/device:**
```bash
flutter run
```
Or pick an Android emulator/device from the same dropdown in Android
Studio.

### Build a release APK

```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build for Web deployment

```bash
flutter build web --release
```
Output: `build/web/` (deployable to any static host — Firebase Hosting,
GitHub Pages, Netlify, etc.)

## 📸 Screenshots

<!-- Replace these with real screenshots before submitting.
     Suggested shots: Dashboard, Invoice List, Invoice Form, Invoice
     Detail (with PDF/Share buttons), Settings. -->

| Dashboard | Invoice List | Invoice Form |
|---|---|---|
| _screenshot_ | _screenshot_ | _screenshot_ |

| Invoice Detail | Settings |
|---|---|
| _screenshot_ | _screenshot_ |

## 👤 Author

**Muhammad Abdullah Abrar**

📧 [mabdullahabrar21@gmail.com](mailto:mabdullahabrar21@gmail.com)

<p>
  <a href="mailto:mabdullahabrar21@gmail.com">
    <img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" />
  </a>
</p>

## 📄 License

This project was created for educational purposes as part of an
internship task. Feel free to fork and build on it.

---

<div align="center">
Made with 💙 and Flutter
</div>
