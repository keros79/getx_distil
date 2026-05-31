# 🚀 getx_distil

`getx_distil` is a **high-performance, micro state management and tree-scoped dependency injection (DI) library**. It maximizes and refines only the powerful, intuitive core features of GetX (reactive state management and dependency injection) while completely shedding unnecessary overhead.

By stripping away the heavy global navigation overlay, custom routing engines, and custom global UI layers of the original GetX, `getx_distil` focuses 100% on **pure reactivity (`Rx`)** and **hierarchical, tree-scoped dependency injection (DI)**. It is meticulously designed to work seamlessly with the official Flutter ecosystem and modern routing packages like `GoRouter`.

---

## 📊 Quick Comparison: Original GetX vs. getx_distil

| Feature | Original GetX | getx_distil |
| :--- | :--- | :--- |
| **Core Footprint** | Heavy (includes Navigation, Routing, custom UI overlays, etc.) | **Ultra-lightweight** (100% pure Reactivity & Tree-Scoped DI) |
| **Routing Interoperability** | Dictated by a custom navigator, often clashing with standard routes | **100% compatible** with standard Flutter routing and `GoRouter` |
| **DI Lifecycle Management** | Managed globally, requires manual deletion (frequent memory leaks) | **Strictly bound to the Widget Tree** via `BindingWidget` + Auto GC |
| **Async Obx Safety** | Silent failures when mixing `async/await` inside `Obx` builders | **Strict validation**: instantly throws a descriptive `FlutterError` |
| **Build-Phase State Changes** | Often crashes the engine with `setState() during build` exceptions | **Self-healing**: automatically defers updates to the next frame callback |
| **Reactive Lists (`RxList`)** | Triggers rebuilds on *every* individual loop mutation | **Batched**: aggregates loop mutations into a single microtask rebuild |

---

## ✨ Key Features

* ⚡ **Ultra-lightweight Reactive Core (`Rx`)**: Minimize boilerplate code using intuitive `.obs` and `.value` syntax.
* 🛡️ **FIFO Asynchronous Pipeline (`updateSequential`)**: Prevent race conditions and state inversion during high-frequency async updates via sequential queues. Use `rx.value = v` for simple overwrites, and `rx.updateSequential(...)` for transactions dependent on the previous state.
* 🎯 **Pinpoint Reactive Widget (`Obx`)**: Automatically track dependencies and rebuild only the leaf-most widgets whose values actually changed, auto-disposing unused subscriptions.
* 🌳 **Tree-Scoped DI (`BindingWidget` & `Get.find`)**: Automatically manage the lifecycle of your controllers by syncing them with the widget tree. When a scope is removed, controllers automatically trigger `onClose()` and are garbage-collected (GC).
* 🧵 **Thread-Safe Context Lookup (`GetView` & `Expando`)**: Guarantee highly accurate instance resolution using Dart `Expando` even under nested `Obx` and asynchronous environments without timing anomalies.
* ⚡ **Fast-Path Static Express Track**: Bypass costly reactive proxy lookups during pure non-UI logical calculations using the `Notifier.isTracking` flag to achieve absolute peak computational efficiency.
* 📋 **High-Performance Reactive List (`RxList`)**: Batch multiple mutations inside a loop and collapse them into a single UI rebuild using a dirty-flag and microtask scheduler.

---

## 🛠️ Usage & Components Guide

`getx_distil` preserves the signature developer convenience of the original GetX while enforcing strict widget tree-based lifecycle boundaries and top-tier rendering performance.

---

### 1. 🎯 Obx & Rx (Reactive State Management & Pinpoint Rebuilds)

`getx_distil` supports reactive programming with zero boilerplate while ensuring the core reactive engine maintains a minimal rendering overhead.

* **Reactive Declarations & `.obs` extension**:
  ```dart
  final count = 0.obs;             // RxInt (Rx<int>)
  final user = User().obs;         // Rx<User> (Custom model class)
  final name = Rxn<String>();      // Nullable Rx (allows safe null values)
  ```

#### 📖 Reading and Writing Values

You can read and update the values of reactive variables using the standard `.value` syntax:

```dart
class CounterController extends GetxController {
  final count = 0.obs;
  final name = Rxn<String>();

  void increment() {
    count.value = count.value + 1;
    name.value = 'Flutter';
  }
}
```

#### 💡 Key Enhancements Over Original GetX

* **Full Support for Nullable Rx (`Rxn<T>`)**: Safely reset or explicitly assign null status (`name.value = null`) without unexpected type crashes.
* **🛡️ Prevent Asynchronous (Async/Future) Misuse in `Obx`**:
  Writing `async/await` or returning `Future` values directly inside an `Obx` builder callback breaks the reactive tracking loop, resulting in silent tracking failures. `getx_distil` immediately intercepts such actions and throws a descriptive `FlutterError` with helpful warnings.
* **⚡ Defend Against Build-Phase State Changes**:
  Modifying a reactive state during the widget tree's build or layout phases normally triggers a fatal Flutter engine exception (`setState() or markNeedsBuild() called during build`). `getx_distil` automatically intercepts build-phase updates, checks `SchedulerBinding`, and **defers the UI update to the post-frame callback queue**, preventing runtime crashes seamlessly.
* **🌳 High-Visibility Debugging for DI Failures**:
  If `Get.find` fails because you forgot to declare a `BindingWidget` or due to a typo in a tag, instead of throwing a generic "dependency not found" message, `getx_distil` generates a detailed error layout containing the **requested context widget name**, the **exact parent ancestor widget hierarchy path**, and the **currently active global/immortal services in memory** to drastically lower debugging cost.

#### 🚨 Best Practice: Targeted Rebuilds with `Obx`

> [!WARNING]
> **Do not wrap a massive widget tree or an entire Scaffold in a single Obx!**
> Doing so forces the static structural parts of the UI to rebuild repeatedly, causing frame drops and degrading UI responsiveness.

* **Recommended Pattern**: Place common layouts and structural wrappers (e.g., `Scaffold`, `AppBar`) *outside* of `Obx`, and wrap **only the specific, leaf-most widgets whose values actually change** with `Obx`.

```dart
// Pinpoint Rebuild Example: Isolate only the changing text
Obx(() => Text(
  '${controller.count.value}',
  style: Theme.of(context).textTheme.headlineMedium,
))
```

---

### 2. 🧵 GetView & Hybrid DI (Global Singletons vs. Widget Tree-Scoped DI)

`getx_distil` cleanly separates dependencies into two distinct scopes based on their **lifecycle, lifetime, and business scope**:

* **🌐 Global DI**
  * **Target**: Background processes, databases, global API clients, authentication services, etc., which must persist for the entire duration of the app session.
  * **Method**: Registered using `Get.put()` or `Get.lazyPut()`. These can be resolved instantly anywhere, without a `BuildContext`.
* **🌳 Tree-Scoped DI**
  * **Target**: Page-specific controllers and ViewModels that should only exist as long as their corresponding UI view is active.
  * **Method**: Bound to the widget tree using `BindingWidget(bindings: ...)`. When the associated widget is unmounted from the tree, its scoped controllers are automatically disposed of and garbage-collected.

---

#### 💡 Architectural Separation: Global DI vs. Tree-Scoped DI

##### ① Global DI (Global Singletons)
* **Registration**: `Get.put(DatabaseService())` or `Get.lazyPut(() => ApiService())`
* **Resolution**: `final api = Get.find<ApiService>();` (Notice the absence of `BuildContext`)
* **Key Attributes**:
  * Because it doesn't require a `BuildContext`, you can safely lookup and resolve services inside pure business logic, background workers, or repositories.
  * **Singleton Protection**: Invoking `Get.put` multiple times for the same type returns the existing cached singleton, preserving global memory state.
  * Check type registration status at runtime using `Get.isRegistered<T>()`.

##### ② Tree-Scoped DI (Context-Bound Controllers)
* **Registration**: `BindingWidget(bindings: [Bind<MyController>(() => MyController())], child: ...)`
* **Resolution**: `Get.find<MyController>(context)` or via `GetView<MyController>`'s auto-resolved `controller` getter.
* **Lifecycle**: 100% synchronized with the Flutter widget tree. When the widget is removed (`dispose`), all scoped controllers **automatically execute their `onClose()` lifecycle hook and are marked for immediate Garbage Collection (GC)**.

---

#### 🚨 Why does getx_distil enforce short-lived local states strictly via `BindingWidget`?

Allowing developers to manually inject page-level controllers into a global map and call teardown methods (`Get.delete`) manually during navigation transitions is highly error-prone and leads to:
1. **Severe Memory Leaks**: Developers routinely forget to clean up manual dependencies on edge-case navigations, leading to persistent background memory bloat.
2. **Timing Race Conditions**: Async network operations or animation callbacks from closed screens may invoke methods on a deleted controller, triggering sudden null-pointer errors or crashes.
3. **Inconsistent Architecture**: With half the project managing lifecycles automatically and the other half manually, debugging costs escalate.

To eliminate human error and secure absolute memory safety, `getx_distil` enforces a structural constraint: **short-lived, local view controllers must only be registered within the `BindingWidget` layer.**

---

#### 📌 Implementation: Basic Usage & Constructor Injection

```dart
// 1. Recommended: Use Constructor Injection during GoRouter configuration or screen navigation boundaries.
// Instantiating the controller at the entry point of your route (where BuildContext is natively available)
// allows you to resolve ancestor dependencies using context, ensuring compile-time type safety.
GoRoute(
  path: '/settings',
  builder: (context, state) {
    final userRole = state.uri.queryParameters['user'] ?? 'Guest';
    return BindingWidget(
      bindings: [
        // Bind and isolate SettingsController exclusively within the scope of SettingsPage
        Bind<SettingsController>(() => SettingsController(userRole: userRole)),
      ],
      child: const SettingsPage(),
    );
  },
)
```

---

### 3. 🛠️ Worker (Asynchronous Flow Control & Resource Management)

Workers monitor reactive variables during the controller's lifecycle and handle side-effects such as calling asynchronous endpoints or running business validations.

* **`ever(listener, callback)`**: Triggers the callback **immediately, every single time** the reactive variable changes.
* **`once(listener, callback)`**: Triggers the callback **exactly once** on the first change, then automatically shuts down the stream listener.
* **`debounce(listener, callback, {Duration time})`**: Invokes the callback **only once** after a specified period of inactivity (default: 800ms). Perfect for implementing search auto-complete APIs.

#### 💡 Key Enhancements Over Original GetX

> [!IMPORTANT]
> **Explicit Worker Disposal is Mandatory!**
> Because workers monitor reactive streams in the background, to completely eliminate memory leaks, you **must** call `.dispose()` or `.cancel()` on your `Worker` objects within the controller's `onClose()` hook.

```dart
class SearchController extends GetxController {
  final searchQuery = ''.obs;
  late final Worker _searchWorker;

  @override
  void onInit() {
    super.onInit();
    
    // Register the debounce worker
    _searchWorker = debounce(
      searchQuery, 
      (query) => _fetchSearchResults(query), 
      time: const Duration(milliseconds: 500),
    );
  }

  void _fetchSearchResults(String query) {
    print('Sending server API request for: $query');
  }

  @override
  void onClose() {
    // 🚨 Always cancel workers in onClose() to secure memory!
    _searchWorker.dispose(); 
    super.onClose();
  }
}
```

---

### 4. 🏛️ GetMaterialApp & App Bootstrapping (Integrated Binding & Reactive Configuration)

`GetMaterialApp` is the core bootstrap widget designed to effortlessly orchestrate the application's startup configuration, dynamic reactive theme shifts, and locales in real time.

#### 💡 Core Features of `GetMaterialApp`
1. **Dynamic Reactive Theme/Locale Interceptor**:
   * Listens to dynamic configurations (`theme`, `darkTheme`, `themeMode`, and `locale`) via highly optimized reactive streams.
   * Modifying `Get.themeMode` or `Get.locale` immediately updates the entire application's interface **without needing any root state wrapper widgets**.
2. **Root Dependencies Injection (`bindings`)**:
   * Supports an optional `bindings` parameter to automatically wrap your entire application under a top-level `BindingWidget`.
   * This provides a clean, unified interface to register persistent global services (`GetxService`).
3. **Safe Initialization Pipeline**:
   * Guarantees that initializing themes, configurations, or locales during startup will never trigger Flutter build conflicts (`setState() during build`).

---

### 5. 🏛️ GetxService (Persistent Global Services)

`GetxService` shares the same underlying reactive lifecycle interface (`GetLifeCycleMixin`) as `GetxController`, but is structurally distinct: it bypasses the widget tree's dispose routines and remains resident in memory indefinitely as an **Immortal Service**.

#### 💡 Key Differences Between `GetxController` and `GetxService`
* **Immunized Against Automatic Garbage Collection (GC)**:
  A normal `GetxController` is automatically disposed of and garbage collected when the `BindingWidget` that constructed it is removed from the widget tree. `GetxService` bypasses this mechanism, remaining safely cached within the global static memory context.
* **Common Use Cases**: Local databases (SQLite, Hive, Isar), Authentication status managers (`AuthService`) keeping user session flags, global logging services, or default network client modules.

#### 📌 Usage Example

```dart
// 1. Extend GetxService to define a persistent, immortal service
class DatabaseService extends GetxService {
  bool _isConnected = false;

  Future<void> initDatabase() async {
    // Perform database connection and migration routines
    _isConnected = true;
    print('Database initialization complete.');
  }

  @override
  void onClose() {
    // GetxService onClose() is only invoked when the application terminates
    super.onClose();
  }
}
```

```dart
// 2. Register it in the root GetMaterialApp bindings
GetMaterialApp(
  bindings: [
    Bind<DatabaseService>(() => DatabaseService()),
  ],
  builder: (context, child) {
    // Instantiate immediately upon app initialization
    Get.find<DatabaseService>(context);
    return child!;
  },
  child: const MyApp(),
)
```

```dart
// 3. Resolve context-less anywhere in the app
// Once initialized, look up DatabaseService anywhere—even outside UI widgets or where BuildContext is unavailable!
final db = Get.find<DatabaseService>();
```

---

### 6. 🔄 StateMixin & RxStatus (Declarative Asynchronous State Branching)

`StateMixin<T>` is a highly optimized mixin that can be added to your controllers to elegantly represent typical asynchronous API states: **Loading, Success, Empty, and Error**. It enables clean, boilerplate-free declarative view mappings on the UI layer.

#### 💡 Key Enhancements Over Original GetX
* **Highly Optimized Engine**:
  Instead of utilizing original GetX's complex nested stream listeners, `getx_distil` drives changes directly through its ultra-lightweight `Obx` rebuild pipeline, ensuring that only the specific leaf widgets redraw during state transitions.
* **Unified Atomic `change` Method**:
  Updates both the backing data (`state`) and the status (`status`) in a single atomic transaction, preventing typical state desynchronization.

#### 📌 Statuses Exposed by `RxStatus`
* `RxStatus.loading()`: Asynchronous task is currently running.
* `RxStatus.success()`: Async task completed successfully and returned valid, non-empty data.
* `RxStatus.empty()`: Task succeeded, but returned an empty dataset.
* `RxStatus.error(message)`: An error or exception occurred (contains a detailed error string).

#### 📌 Usage Example

##### 1. Mix `StateMixin<T>` into Your Controller
```dart
class ApiController extends GetxController with StateMixin<String> {
  final ApiRepository repository;

  ApiController(this.repository);

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  void fetchUserData() async {
    // 1. Transition to Loading state
    change(null, status: RxStatus.loading());

    try {
      final result = await repository.getUserData();
      
      if (result == null || result.isEmpty) {
        // 2. Transition to Empty state
        change(null, status: RxStatus.empty());
      } else {
        // 3. Transition to Success state along with data payload
        change(result, status: RxStatus.success());
      }
    } catch (e) {
      // 4. Transition to Error state with error details
      change(null, status: RxStatus.error(e.toString()));
    }
  }
}
```

##### 2. Map Status Declaratively in the View with `obx()`
Rather than polluting your widget `build` methods with convoluted `if (isLoading) ... else if (isError) ...` statements, call the `obx()` method to map states to clear UI layouts:

```dart
class UserProfilePage extends GetView<ApiController> {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: controller.obx(
        // [Success] Renders when valid data is successfully loaded
        (state) => Center(
          child: Text('Data Loaded: $state', style: const TextStyle(fontSize: 18)),
        ),
        // [Loading] Displays loading spinner (Defaults to a CircularProgressIndicator)
        onLoading: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
        // [Empty] Renders when returning an empty result (Defaults to SizedBox.shrink())
        onEmpty: const Center(
          child: Text('No profile information matches this user.'),
        ),
        // [Error] Renders when an exception is thrown (Defaults to showing the error string)
        onError: (error) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
```
