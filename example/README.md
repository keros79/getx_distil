# 📊 getx_distil Example Application

This project is a **high-quality dark glassmorphism stock dashboard demo app** designed to verify and demonstrate `getx_distil`'s outstanding **element-level reactivity** and **widget tree-scoped dependency injection (Scoped DI)** in a real-world business scenario.

---

## 🎨 UI Design & Key Specifications

1. **Premium Dark Glassmorphism UI**: 
   - Modern, high-fidelity dashboard card interfaces styled with subtle neon glow accents.
   - Dynamic dark/light theme switching fully synchronized with `Theme.of(context)`.
2. **Targeted Widget Rebuilds (Targeted Obx)**:
   - Instead of wrapping the entire viewport (`Scaffold`), we wrap only the specific text elements and inner card nodes whose state actually changes with highly targeted `Obx` observers, keeping rendering overhead near zero.
3. **Declarative Routing & Scoped Dependency Injection**:
   - Multi-route configuration powered by `GoRouter`.
   - Direct demonstration of injecting screen-specific controllers independently using `BindingWidget`.

---

## 💻 Implemented Key Features

- **Real-Time High-Frequency Price Feed (Price Stream)**:
  - A highly volatile stock market ticker price feed changing at sub-second intervals.
  - Implements the `updateSequential` FIFO async queue pipeline to stream price ticks safely without state desynchronization or race conditions.
- **Reactive Theme Toggle (Visual Preferences)**:
  - Instantly toggles light/dark modes across the app from either the app bar or the settings dashboard card.
- **Dynamic In-App Localization Switch**:
  - Integrates classic `Translations` dictionary along with the `String.tr` extension method to transition between English (US) and Korean (KR) instantaneously without reloading the application.

---

## 🚀 Running & Debugging the App

### 1. Install Dependencies
Navigate into the `example` folder inside your terminal and fetch packages:
```bash
cd example
flutter pub get
```

### 2. Run and Debug in VS Code with Microsoft Edge/Chrome (Recommended)
You can quickly test dynamic changes and hot-reloads inside a browser using the configured `.vscode/launch.json` file in the workspace root.
- Open the **Run and Debug** panel in VS Code (`Ctrl + Shift + D`).
- Choose either **`example (Edge)`** or **`example (Chrome)`** from the configuration dropdown at the top.
- Press `F5` to start debugging.

### 3. Direct Run via CLI
```bash
flutter run -d edge
```

---

# 📂 Project Structure

```
example/
├── lib/
│   ├── main.dart                 # GoRouter and top-level GetMaterialApp setup
│   └── src/
│       ├── config/
│       │   └── app_config.dart   # Global theme mode preference state (isDarkMode.obs)
│       └── views/
│           ├── dashboard_controller.dart # Price feed logic and main counter controllers
│           ├── dashboard_page.dart       # Real-time analytics view extending GetView
│           ├── settings_controller.dart  # Visual preferences and localization controllers
│           └── settings_page.dart        # System settings interface extending GetView
└── test/
    └── widget_test.dart          # Smoke tests validating example app integration
```

---

## ⚠️ Enterprise Architectural Guidelines

To successfully scale `getx_distil` in large-scale professional applications, please strictly follow these core development standards:

### 🚨 **Do not wrap the entire Scaffold in Obx!**
* **The Problem**: Wrapping a massive widget hierarchy (like the outer `Scaffold` or whole page) in a single `Obx` forces Flutter to completely rebuild static, non-changing elements (such as `AppBar`, `Drawer`, static form fields, custom layouts, and text styles) whenever a minor leaf state updates. This is the single biggest cause of frame drops, CPU spikes, and sluggish UI performance in large-scale apps.
* **The Correct Pattern**: Keep your structural `Scaffold` outside of `Obx`, and wrap **only the leaf-most widgets whose values actually change (individual Text labels, metric numbers, indicators, count badges)** with pinpointed, isolated `Obx` instances.
