# 🌿 Core Screens (2025 Refactor)

This folder contains the **main entry flow** and **core navigation screens** of the Toolxie app.  
It defines the user's journey from splash to full app functionality — covering onboarding, personalization, and main dashboard experience.  

All screens follow the **2025 Toolxie architecture**:
- 🧠 **Riverpod** for state & theming  
- 🌍 **EasyLocalization** for i18n  
- 💾 **SQLite (AppDatabase)** for persistence  
- 🎨 Fully themed UI with `AppPalette` and `AppTextStyles`  

---

## 📂 Files Overview

### `main.dart`
Defines the **root entry point** of the Toolxie app:
- Initializes **EasyLocalization** + **Riverpod**.  
- Cleans and preloads **SQLite favorites table** before app launch.  
- Applies global **Quicksand** typography and `AppPalette` colors.  
- Sets **system bar colors dynamically** (status + navigation).  
- Launches app with `AppRouter.splash` as the initial route.  
- Fully compatible with light / medium / dark themes.  

> 💡 Favorites are preloaded via `FavoritesScreen.init()` for instant sync.

---

### `splash_screen.dart`
Animated **startup splash screen**:
- Displays the Toolxie logo with fade or gradient animation.  
- Calls `AppRouter.decideStartRoute(ref)` to determine next screen.  
- Routes to **Welcome**, **Name**, or **Home** based on onboarding progress.  
- Async-safe navigation (`mounted` check).  
- Background adapts to `AppPalette` and theme brightness.  

---

### `welcome_screen.dart`
First-time **onboarding welcome page**:
- Fade + slide animation introducing the app.  
- Texts loaded from JSON (`welcome.title`, `welcome.body`, etc.).  
- Continue button transitions smoothly to `NameScreen`.  
- Marks onboarding complete in SQLite (`setWelcomeSeen(true)`).  
- Pastel visuals from `AppPalette.surfaceContainerHighest`.  

---

### `name_screen.dart`
Personalization screen for **entering the user's name**:
- Centered text input with validation and responsive scaling.  
- Async-safe save using Riverpod + SQLite (`AppDatabase.user`).  
- Button styled via `AppButtonStyles.primary`.  
- Navigates to `HomeScreen` after saving name.  
- Integrated with `userNameProvider` for global display.  

---

### `home_screen.dart`
Main **app container** with persistent navigation:
- Hosts 4 core tabs: 🏠 Home, 👤 Account, 💖 Favorites, ⚙️ Settings.  
- Uses global `NavBar` and `GlobalAppBar` components.  
- Manages current tab and renders respective child screen.  
- Gradient background via `palette.backgroundGradient`.  
- Central place connecting all tool categories.  

---

### `home_tools.dart`
Displays the **tool grid** for each category:
- Adaptive layout (2–3 columns depending on width).  
- Colors and labels pulled from `ToolDef` and `AppPalette`.  
- Category tabs switch between Organization, Growth, Life.  
- Each `ToolCard` opens a route from `AppRouter`.  
- Responsive typography and shadowed pastel cards.  
- Fully localized using `tools.*` keys.  

---

### `account_screen.dart`
User profile and **personal settings**:
- Displays name, avatar, and recovery code section.  
- Editable via centered `AlertDialog` with accent color.  
- Connected to SQLite (`AppDatabase.user`) and Riverpod providers.  
- Theme switcher, reset options, and logout logic included.  
- Adaptive padding and scaling via MediaQuery.  
- Gradient header matching overall app style.  

---

### `favorites_screen.dart`
Centralized **Favorites Manager**:
- Lists favorite tools grouped as daily / weekly / monthly.  
- Interactive **ReorderableGridView** for rearranging items.  
- Persistent data in SQLite (`favorites` table).  
- Synced with heart icon in `GlobalAppBar`.  
- FAB toggles between compact and relaxed grid density.  
- Gradient background with subtle empty-state animation.  

---

### `settings_screen.dart`
Unified **preferences and configuration screen**:
- Flat minimalist layout (dividers instead of cards).  
- Options: theme mode, localization, favorite management.  
- Buttons styled via `palette.buttonQuaternary`.  
- Gradient background visible beneath content.  
- Integrated with `FavoritesScreen` for navigation.  
- Fully translated via `settings.*` JSON keys.  

---

## 🧠 Summary

All screens together define the **core Toolxie experience**:
- 100% colors from `AppPalette` (no hardcoded values).  
- Complete localization & responsive scaling.  
- Clean data layer via **SQLite**, not SharedPreferences.  
- Riverpod-driven logic for reactive updates.  
- Modular, pastel, and consistent with the 2025 design system.  

> 🌸 These eight files shape the heart of Toolxie — from the first splash animation to a personalized productivity dashboard.
