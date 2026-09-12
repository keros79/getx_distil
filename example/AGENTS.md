# App architecture (getx_distil)

Feature-First + MVVM layout for Flutter apps that use `getx_distil`.
This is the **recommended architecture** for structuring an app the same way as this example.

The package itself only depends on the Flutter SDK. `go_router` / `dio` / `freezed` / `retrofit` below are **app-side recommended tooling**, not package requirements.

## 1. Overview

- **Architecture**: MVVM + Feature-First
- **State management**: `getx_distil` (micro-state + scoped DI)
- **Routing**: `go_router`
- **DI**: screen/feature scope via `BindingWidget`, only app-lifetime objects are global
- **REST API**: `dio` + `freezed` + `retrofit`
- **Goal**: a structure where ownership is explicit, tests are easy, and screens scale independently

## 2. Folder structure (Feature-First + Layered)



```text
lib/
├── core/                          # app-wide
│   ├── config/
│   ├── constants/
│   ├── routes/                    # GoRouter
│   ├── theme/
│   ├── utils/
│   └── widgets/                   # shared widgets
├── models/
│   ├── data/                      # Data Layer
│   │   ├── datasources/
│   │   └── repositories/
│   └── domain/                    # Domain Layer
│       ├── models/                # Entity
│       └── repositories/          # Abstract Repository
├── services/                      # external services: Api, Auth, ...
├── views/                         # Page + Controller (per screen)
└── main.dart
```

This example follows a minimal version of this tree: `@freezed` DTOs in `models/data/`, the Entity + abstract repository in `models/domain/`, and the Retrofit API client in `services/`. It never uses `lib/src/`.

## 3. Rules

### MVVM

- **Page** (`views/`): extends `GetView`. UI only. When `build()` grows, split it into `_build{Feature}()` methods or separate widget files.
- **Controller** (`views/`): extends `GetxController`. Business logic + state. Same folder as its Page.
- **Model** (`models/`): keep Domain Models and Data Models separate.
- **Service** (`services/`): extends `GetxService`. App-lifetime objects such as external APIs / auth.

Local state of sub-widgets inside a Page does not need a `GetxController`.

```dart
class HomeController extends GetxController {
  final counter = 0.obs;

  void increment() => counter.value++;
}
```

### GoRouter

- All routes live in one place: `core/routes/app_router.dart`.
- Wire `redirect` / `refreshListenable` to getx_distil state.
- Assume deep links and web URLs.

### DI

Scoped DI is the default; keep global singletons minimal.

- Global services: `GetMaterialApp(bindings: …)`
- Screen controllers: `BindingWidget` + `Bind<T>` in the route
- Only objects that must exist before `GetMaterialApp` go through `Get.put()` in `main()`

```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => BindingWidget(
    bindings: [
      Bind<SettingsController>(() => SettingsController()),
    ],
    child: const SettingsPage(),
  ),
)
```

## 4. Coding conventions

- File names: `snake_case.dart`
- Class names: `UpperCamelCase`
- Controller: `[feature]_controller.dart`
- Page: `[feature]_page.dart`
- Service: `[feature]_service.dart`
- Widget: `[feature]_view.dart`
- Model: `freezed` recommended
- Public APIs get doc comments
- No `setState` — use `.obs` / `Obx` / `GetBuilder`

## 5. State management

- UI state: `Rx`, `.obs`, `RxS`, `RxSList`, `.ops`
- Business logic: Controller methods
- Global state: minimize, prefer scoped DI
- `Obx` wraps only the leaf whose value changes. Never wrap a whole `Scaffold`.

## 6. Testing

- Controller: unit tests first
- Repository: mock
- Widget / integration: override with `GoRouter` + a test-only `BindingWidget`. No test branches in production code.

## 7. Don'ts

- Context-less `Get.find()` overuse (screen objects are scoped)
- Controller directly referencing the View
- Business logic in the View
- Direct imports between features (shared code or Repository only)

## 8. REST API (app recommended stack)

Standardize on `Retrofit` + `Dio` + `Freezed` at the app level. They are not getx_distil package dependencies.

1. **DTO (`Freezed`)** — `lib/models/data/`, `@freezed` Request/Response, `fromJson` / `toJson`
2. **API client (`Retrofit`)** — `lib/services/`, `@RestApi` + `@GET` / `@POST` / …
3. **HTTP (`Dio`)** — inject a shared `Dio` (auth/timeout interceptors) into the constructor
4. **Code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```