# AT Sol Mobile — Android App

Flutter app for **AT Sol – Ahsan Traders Solutions** distribution software.
Connects directly to your hosted AT Sol web software and mirrors its features on mobile.

## Features (parity with desktop software)

| Module | Capabilities |
|---|---|
| Dashboard | Today/month sales, purchases, counts of invoices, vouchers, customers, suppliers, items |
| Sales | Invoice list + search, detail view, create/edit invoice with items, delete |
| Sales Returns | List + detail view |
| Purchases | Purchase list, create purchase, purchase orders |
| Purchase Returns | List + detail view |
| Vouchers | Journal General, Cash/Bank Payments & Receipts — list, filter, double-entry creation |
| Definitions | Customers, Suppliers, Dealers, Items, Item Groups, Godowns, Transporters, Areas, Zones, Measurements, Sale Types, Bank & Cash Accounts |
| Reports | Account Ledger, Party Balances/Status, Stock Position, Income/Expenses, P&L, Trial Balance, Receipts/Payments Registers, Sale/Purchase Registers |
| Admin | User management (admin), change password |

## Server requirements

Upload these two new PHP files to your hosting (they ship with this repo):

- `api/mobile_summary.php` — dashboard stats
- `api/get_sale_returns.php` — sales returns list

No other backend changes needed — the app talks to your existing `/api/*` endpoints.

## Build the APK

### Option A — Automatic (recommended, no tools needed)
1. Create a GitHub repository.
2. Upload the **contents** of this `mobile_app` folder as the repository root
   (`pubspec.yaml`, `lib/`, `.github/` must sit at the root).
3. GitHub Actions automatically builds BOTH installers on every push
   (see the *Actions* tab → artifacts):
   - `AT-Sol-Android-APK` → the Android app (`app-release.apk`)
   - `AT-Sol-Windows-Desktop` → a ZIP you can extract and run on any
     Windows PC to test the app on desktop without installing anything

### Option B — Local build

### Option B — Local build
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) + Android Studio.
2. Then:
   ```bash
   cd mobile_app
   flutter create . --platforms android --org com.ahsantraders --project-name atsol_mobile
   flutter pub get
   flutter build apk --release
   ```
3. APK is at `build/app/outputs/flutter-apk/app-release.apk`.

## First run

1. Install the APK on your Android phone **or** extract and run
   `atsol_mobile.exe` from the Windows ZIP.
2. On the login screen tap the server URL line and enter your hosted software
   address, e.g. `https://yourdomain.com/atsol`.
3. Sign in with the same username/password you use in the desktop software.

### Testing without hosting

You can also point the app at your own PC while testing. With PHP enabled
(e.g. XAMPP or `php.exe`), run this from the software folder:

```
php -S 0.0.0.0:8080
```

Then on the login screen enter: `http://127.0.0.1:8080`
(from another device on the same WiFi, use your PC's IP instead,
e.g. `http://192.168.1.5:8080`).

> The app uses HTTPS in production. Local `http://127.0.0.1` addresses are
> fine for desktop/Windows testing; Android may block plain-http URLs —
> prefer the hosted HTTPS URL on phones.

## Project structure

```
mobile_app/
├── .github/workflows/build-apk.yml   ← cloud APK builder
├── pubspec.yaml
└── lib/
    ├── main.dart                     ← app entry
    ├── config.dart                   ← endpoints + default server URL
    ├── theme.dart                    ← Material 3 brand theme
    ├── services/api_service.dart     ← all HTTP calls + session handling
    ├── widgets/ui.dart               ← shared UI components
    └── screens/
        ├── login_screen.dart
        ├── home_screen.dart          ← dashboard + module grid
        ├── sales/…  purchases/…  transactions/…
        ├── definitions/…  reports/…  admin/…
```
