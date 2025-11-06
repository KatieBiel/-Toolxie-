# Toolxie – App Bootstrap

This part of the project covers the **app initialization layer**:  
entry point (`main.dart`) + core configuration (`pubspec.yaml`).

---

## File: `main.dart`

This file is the entry point of the Toolxie app.  
It is responsible only for **bootstrapping** the app – no UI or business logic.

### Responsibilities
- ✅ Initialize Flutter binding
- ✅ Setup **EasyLocalization** (EN / PL / NL)
- ✅ Configure **system status & navigation bars**
- ✅ Initialize **Firebase** (`firebase_options.dart`)
- ✅ Load local **Favorites** from SharedPreferences
- ✅ Inject **ThemeController** (Provider)
- ✅ Run `ToolxieApp` (root `MaterialApp`)

### Key Notes
- **Error handling**: `Firebase.initializeApp` wrapped in `try-catch` – replace `debugPrint` with `logger` in production.
- **SystemChrome**: light/dark status/navigation bar styles forced on startup + every rebuild.
- **Themes**: uses centralized `AppTheme.light` / `AppTheme.dark` from `theme.dart`.
- **Localization**: translations loaded from `assets/translations` (`en`, `pl`, `nl`).

### TODO
---

## File: `pubspec.yaml`

Core project configuration and dependencies.

### Key dependencies
- `flutter` – SDK
- `google_fonts` – UI typography
- `shared_preferences` – local storage for small data (e.g., Favorites)
- `reorderable_grid_view` – drag & drop grid layout
- `image_picker` – add photos
- `path_provider` – local file access
- `url_launcher` – open external links
- `pdf` – generate PDF exports
- `font_awesome_flutter` – icons
- `intl` – date/number formatting
- `numberpicker` – picker widget
- `provider` – state management

### Firebase (planned)
- `firebase_core`, `firebase_auth`, `cloud_firestore`

### Translations
- `easy_localization`

### Dev tools
- `flutter_lints` – lint rules
- `flutter_launcher_icons` – generate app icons (currently using single PNG)
- `flutter_native_splash` – splash screen

---

## TODO
- ⚠️ TODO: Dark mode splash colors need to be aligned with `theme.dart`
