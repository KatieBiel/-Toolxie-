# 🧩 Common Widgets & Themes

This folder contains shared UI components, routing logic, and theming used across the Toolxie app.  
These elements ensure a consistent look & feel, smooth navigation, and unified user experience across all screens.  

---

## 📂 Files Overview

### `theme.dart`
Defines the **global theming system** for Toolxie:
- Centralized **light / medium / dark** palettes.  
- Global color constants in `AppColors`.  
- `AppPalette` handles colors for AppBar, NavBar, buttons, and ToolCards.  
- `AppTextStyles` defines Quicksand-based typography.  
- `AppShadows` and `AppButtonStyles` provide reusable UI styles.  
- Integrated with **Riverpod** via `themeControllerProvider` and `currentPaletteProvider`.  
- All colors and text styles are theme-driven (no magic values).  

> 🧠 Former `appthemes.dart` file has been **merged into this single theme system** during the 2025 refactor.

---

### `appbar.dart`
Global **AppBar widget** used throughout the app:
- **Back arrow**  
  - Visible if `Navigator.canPop` or `onBack` callback is provided.  
  - Defaults to `Navigator.maybePop()` if no custom handler exists.  
- **Tool icon**  
  - Displayed next to the title when a matching `toolId` is available.  
  - Uses `ToolDef` metadata for consistent iconography.  
- **Dynamic title**  
  - Uses `titleKey` (via `easy_localization`) or an explicit `title` string.  
- **Favorite toggle (heart icon)**  
  - Shown only when the current screen maps to a `ToolDef`.  
  - Synced with the favorites table in **SQLite (AppDatabase)**.  
  - Active color → `palette.lifeColor` (pink); inactive → translucent `navBarText`.  
- Accepts **custom `actions`** via parameter for screen-specific controls.

---

### `navbar.dart`
Global **bottom navigation bar**:
- Contains 4 main sections: 🏠 Home, 👤 Account, 💖 Favorites, ⚙️ Settings.  
- Uses icons from `font_awesome_flutter` (`house`, `circleUser`, `heart`, `gear`).  
- iOS-style floating **glass blur design** with rounded corners and shadows.  
- **Colors & Typography**:  
  - Background → `palette.navBar`  
  - Active icons/text → `palette.navBarText`  
  - Inactive → `palette.navBarText` with reduced opacity.  
- Fully localized labels (`navbar.home`, `navbar.account`, etc.) via `easy_localization`.  
- SafeArea padding ensures proper layout on all devices.  
- Responsive scaling adjusts icon sizes based on screen width.  

---

### `router.dart`
Centralized **navigation and startup logic**:
- Defines all **static route constants** for core and tool screens (`/home`, `/tools/journal`, etc.).  
- `onGenerateRoute()` maps every route to its respective widget.  
- `_page()` wraps each route in a `MaterialPageRoute` with `RouteSettings`.  
- `decideStartRoute()` (SQLite-based):  
  - Reads onboarding progress from `AppDatabase`.  
  - Determines whether to show **Welcome**, **Name**, or **Home** screen.  
  - Fully replaces previous `SharedPreferences` implementation.  
- Provides helper functions such as `goHome()` for consistent navigation.  

---

### `tools.dart`
Central registry for **all Toolxie modules**:
- Each tool is defined as a `ToolDef` object containing:  
  - `id` → unique internal key.  
  - `titleKey` → localization reference.  
  - `icon` → FontAwesome icon.  
  - `route` → path from `AppRouter`.  
  - `category` → one of `organization`, `growth`, or `life`.  
  - `favoriteGroup` → grouping used in Favorites (daily / weekly / monthly).  
- Provides utility selectors for filtered access:  
  - `toolsOrganization`, `toolsGrowth`, `toolsLife`.  
- Integrated with theming via `AppPalette` for card colors and text.  
- All tool names localized using the `tools.*` keys in translation JSONs.  
- Ready for extension with future flags (e.g., `isPremium`, `isComingSoon`).  

---

## 🧠 Summary

All components in this folder follow the **2025 Toolxie Design System**:
- Single source of truth for theming and routing.  
- 100% colors from `AppPalette` (no hardcoded values).  
- Consistent Quicksand typography.  
- Full i18n support with `easy_localization`.  
- Data persistence via **SQLite**, not `SharedPreferences`.  
- Modular and scalable architecture across all modules.  
