# NS Transport 3.0

NS Transport 3.0 is a comprehensive transport management system built with Flutter and Supabase. The application is designed to streamline logistics and fleet operations by providing dedicated modules for both Vehicle Owners and Drivers. It aims to improve transparency, track trips, manage salaries, and handle document storage efficiently.

## 🎉 Recent Updates (v3.0.2)
* **Auth UI Overhaul:** Completely redesigned the Login and Registration pages to a premium, modern light theme featuring clean white cards, subtle drop shadows, and solid blue interactive elements.
* **Native Logo Integration:** Replaced the static image logo with a natively rendered, high-resolution typographic logo (`CustomLogo`) that supports transparent backgrounds and flawless scaling on all devices.
* **Premium Animations:** Added micro-interactions, shimmer effects, and smooth transitions to improve the initial user experience during authentication.
* **Full Tamil Localization:** Fully integrated dynamic Tamil language translation using `flutter_localizations` and custom dictionaries across all modules, including native Flutter widgets.
* **Navigation Polish:** Transitioned to native `MaterialPageRoute` and optimized Drawer routing to eliminate visual glitches and jarring screen transitions.

## 🚀 Full Project Explanation

The project is structured into distinct modules to cater to the specific needs of different user roles:

### Key Features
* **Role-Based Access Control:** Secure authentication and routing for `Owner` and `Driver` roles using Supabase Auth.
* **Owner Dashboard:**
  * **Driver Management:** Monitor and manage driver profiles and assignments.
  * **Trip Review:** Review trip logs, routes, and statuses submitted by drivers.
  * **Salary Management:** Calculate, approve, and track driver salaries and advances.
* **Driver Dashboard:**
  * **Trip Form:** Log new trips, including origin, destination, vehicle details, and expenses.
  * **Salary Tracking:** View earnings, pending payments, and payment history.
* **Shared Capabilities:**
  * **PDF Service:** Generate reports and trip summaries in PDF format.
  * **Storage Service:** Securely store and retrieve documents, receipts, and user avatars via Supabase Storage.
  * **Theme Management:** Dynamic theme switching (Light/Dark mode) supported by a dedicated ThemeProvider.

### Tech Stack
* **Frontend:** Flutter (Cross-platform support for Web, Android, iOS, Windows)
* **Backend as a Service (BaaS):** Supabase (PostgreSQL, Auth, Storage)
* **State Management:** Provider pattern
* **Routing:** Custom route guards for role-based protection

## 🔮 Future Tech Updates

To keep the platform scalable and modern, the following tech updates are planned:
* **Real-time GPS Tracking:** Integration with Google Maps API or Mapbox to track vehicles in real-time.
* **Push Notifications:** Implementing Firebase Cloud Messaging (FCM) or Supabase Realtime to notify drivers of new assignments and owners of completed trips.
* **Offline Support:** Using local databases like Hive or SQLite to allow drivers to log trips offline, syncing with Supabase when connectivity is restored.
* **Advanced Analytics:** Integrating a dashboard with charts (e.g., fl_chart) to visualize expenses, profit margins, and vehicle performance over time.
* **Automated Expense OCR:** Using ML Kit to scan and automatically extract data from toll and fuel receipts.

## 🛠 Handling & Deployment

### Environment Setup
1. **Flutter SDK:** Ensure you have Flutter version 3.x installed (`flutter doctor`).
2. **Supabase Configuration:** 
   * Create a new Supabase project.
   * Run the provided `supabase_setup.sql` in your Supabase SQL Editor to generate the necessary tables and Row Level Security (RLS) policies.
   * Add your Supabase `URL` and `ANON_KEY` to the `lib/core/constants/api_constants.dart` or your `.env` file.

### Running the App
* For Web: `flutter run -d edge` or `flutter run -d chrome`
* For Windows: `flutter run -d windows`
* For Android: `flutter run -d android`

### State & Data Handling
* The app relies on `Provider` for state management. Ensure providers are properly injected at the root of the widget tree in `main.dart`.
* API calls to Supabase are handled via dedicated service classes (`AuthService`, `TripService`, `SalaryService`), keeping the UI code clean and modular.

## ⚠️ Issues and Pendings

* **Form Validation:** Some edge cases in the `trip_form_screen.dart` need stricter validation (e.g., preventing negative odometer readings).
* **Error Handling:** Implement a global error handling wrapper to display user-friendly snackbars for all Supabase network timeouts or authentication failures.
* **Image Compression:** Currently, receipt uploads via `StorageService` are uncompressed. Need to implement `flutter_image_compress` before uploading to reduce bucket storage costs.
* **Pagination:** The Owner's Trip Review screen needs pagination. Fetching all trips at once will cause performance issues as the database grows.
* **Unit/Widget Testing:** The `test/widget_test.dart` file is currently basic. Comprehensive tests for critical business logic (like salary calculation) need to be written.
