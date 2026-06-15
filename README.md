# 🚀 getx_distil

A **high-performance, ultra-lightweight micro state management and tree-scoped dependency injection (DI) library** for Flutter. It extracts, refines, and distills only the most powerful, intuitive core mechanics of GetX—Reactive State (`Rx`) and Dependency Injection—while completely shedding the unnecessary legacy architectural overhead.

---

## 🏛️ Philosophy

As long-time fans and active users of GetX, we deeply admire the unmatched developer experience (DX) it pioneered. The simplicity of `.obs`, the absolute precision of `Obx`, and the friction-free dependency lookup completely revolutionized state management in Flutter.

However, as the Flutter ecosystem matured toward declarative routing (like `GoRouter`) and strict widget-tree-bound lifecycles, the original GetX's heavy global navigation overlays, custom routing engines, and implicit memory management frequently introduced architectural friction, unexpected memory leaks, and edge-case exceptions.

`getx_distil` is born out of this respect and necessity. We removed the bloat, fixed the long-standing concurrency issues, and hardened memory safety.

> **Same Developer Experience. Zero Overhead.**

---

## 📊 Core Enhancements

* 🌳 **100% Tree-Scoped DI Lifecycle**
  Bind controllers directly to their respective Views using `BindingWidget`. This solves the issue of spawning multiple instances of the same View/Controller concurrently, ensuring each controller is isolated, scoped to its specific view, and automatically garbage-collected (Auto-GC) when the widget unmounts. No manual `Get.delete()` calls required.
* 🛡️ **Self-Healing Build-Phase Updates**
  Modifying reactive state during the widget tree’s build or layout phase normally crashes Flutter with a `setState() during build` exception. `getx_distil` automatically intercepts these and safely defers UI updates to the post-frame callback queue.
* 🛑 **Strict Async Obx Validation**
  Mixing `async/await` directly inside `Obx` builders breaks reactive tracking loops. `getx_distil` catches this anti-pattern instantly and throws a descriptive `FlutterError` rather than failing silently.
* 🧵 **FIFO Asynchronous Pipeline (`updateSequential`)**
  Introduces a clean sequential queue to prevent critical race conditions and state inversion during high-frequency async operations.
* 📋 **Batched Loop Mutations (`RxList`)**
  Instead of triggering expensive UI rebuilds on every single mutation inside a loop, `RxList` aggregates changes and schedules a single microtask UI refresh.
* 📋 **Status-Aware Reactive List (`RxSList`)**
  An [`RxList`] subclass that carries its own `idle`/`loading`/`loaded`/`empty`/`error` status, automatically synchronized with every mutation. No separate `isLoading`/`errorMessage` observables needed.
* 📦 **Status-Aware Single Value (`RxS`)**
  An [`Rxn`] subclass that carries its own `idle`/`loading`/`loaded`/`error` status for nullable single-object state. Automatically transitions to `loaded` on value set, with sticky error state.
* 🔍 **High-Visibility DI Debugging**
  When `Get.find` fails, it no longer throws a cryptic message. It prints a comprehensive debug layout showing the requested context name, the exact parent ancestor widget hierarchy path, and active services in memory.
* ⚡ **High-Performance Fast-Path Tracking (`Notifier.isTracking`)**
  In original GetX, reading any reactive variable (even in normal business logic loops or background tasks outside of `Obx` widgets) triggers a lookup of the global tracking proxy. `getx_distil` introduces a lightweight static boolean flag `isTracking`. Outside of active `Obx` build frames, this flag is `false`, bypassing the entire proxy lookup and dependency registration pipeline. This dramatically reduces CPU cycles during heavy calculation loops or traversals.

> **[getx_distil vs GetX vs RiverPod3.0 Comparison](https://getxdistil.web.app/comparison)**

---

## 🛠️ Essential Components & Quick Start

### 1. 🎯 Reactive State Management (`Rx` & `Obx`)
Isolate updates down to the leaf-most widgets with absolute zero boilerplate.

```dart
class User {
  String name;
  User({required this.name});
}

class CounterController extends GetxController {
  // 1. Primitive Observables
  final count = 0.obs;                 // RxInt (equivalent to RxInt(0))
  final isLogged = false.obs;          // RxBool
  final balance = 0.0.obs;             // RxDouble
  final title = 'Hello'.obs;           // RxString

  // 2. Safe Nullable Observables
  final name = Rxn<String>();          // Rxn<String> (initially null)
  final activeIndex = Rxn<int>();      // Rxn<int> (initially null)

  // 3. Collection Observables
  final items = <String>[].obs;        // RxList<String> (mutations are auto-batched)

  // 4. Custom Object Observables
  final user = User(name: 'Guest').obs; // Rx<User>

  void updateState() {
    // Modifying primitives
    count.value++;                     // Triggers update
    isLogged.toggle();                 // Convenient helper for RxBool
    title.value = 'Distilled GetX';    // Triggers update only if value changes

    // Modifying nullables
    name.value = 'Flutter';

    // Modifying list (all mutations in the same microtask are batched into 1 UI update)
    items.add('Item ${items.length}');

    // Modifying custom objects
    user.value = User(name: 'Alice');
  }
}
```

In your View layer (pinpoint rebuilds):
```dart
Obx(() => Text('${controller.count.value}'));
```

> [!WARNING]
> **Best Practice for Obx Conditional Branching**
> 
> If a conditional branch inside `Obx` resolves in a frame where zero reactive variables (`Rx`) are read (e.g., evaluating an external boolean condition), it might skip dependency tracking or output a warning. Therefore, **always wrap only the smallest target widget that actually displays the reactive variable**.
> 
> ```dart
> // ❌ BAD (Skipping Rx access on login failure branch can cause tracking leak or warnings)
> Obx(() => isLoggedIn 
>     ? Text(controller.userName.value) // Accesses Rx only on login success
>     : const Text('Login Required') // No Rx access on login failure -> triggers warning
> )
> 
> // ✅ GOOD (Obx scope is strictly limited to the widget requiring reactivity)
> isLoggedIn 
>     ? Obx(() => Text(controller.userName.value)) // Apply Obx only where reactive state is needed
>     : const Text('Login Required')
> ```

---

### 2. 📋 Status-Aware Reactive List (`RxSList`)
An extended [`RxList`] that carries its own **idle/loading/loaded/empty/error** status, automatically synchronized with list mutations. No more separate `isLoading`/`errorMessage` observables — the list manages itself.

```dart
final items = <String>[].ops; // List<T> → RxSList<T> via .ops extension
print(items.status); // RxListStatus.idle (initial)
```

#### Status Auto-Sync

Every mutating operation (`add`, `assignAll`, `remove`, `clear`, `value` setter) automatically transitions the status:

```dart
items.assignAll(['apple', 'banana']); // status → loaded
items.add('cherry');                  // status stays loaded
items.clear();                        // status → empty
```

The `error` state is **never** set automatically — assign it manually when an error occurs. This prevents accidental status overwrite when the list still holds valid data:

```dart
items.setError('Network failure'); // sets error message and status to RxListStatus.error (data is preserved underneath)
```

#### UI Binding — use `Obx(() => list.on(...))`

Wrap `.on()` with `Obx` for reactive binding — the same DX pattern as `Obx(() => list)`:

```dart
Obx(() => items.on(
  idle:    () => const Center(child: Text('Idle')),
  loading: () => const Center(child: CircularProgressIndicator()),
  loaded:  (data) => ListView.builder(
    itemCount: data.length,
    itemBuilder: (_, i) => Text(data[i]),
  ),
  empty:   () => const Center(child: Text('No items')),
  error:   (msg) => Center(child: Text('Oops: ${msg ?? 'Unknown error'}')),
));
```

The `loaded` callback is internally wrapped with `Obx`, so **data mutations (`add`/`remove`) trigger immediate UI rebuilds** without additional boilerplate.

#### Paging Support

Use `hasMore` + `addAll` for infinite-scroll paging:

```dart
final paged = RxSList<String>();

// First page
paged.assignAll(page1);
paged.hasMore = true;

// Subsequent pages
paged.addAll(page2);
paged.hasMore = page2.isNotEmpty; // false when last page
```

The `hasMore` field is itself reactive (`Rx<bool>`), so it works seamlessly inside `Obx`:

```dart
Obx(() => Text(paged.hasMore ? 'More available' : 'All loaded'));
```

---

### 3. 📦 Status-Aware Single Value (`RxS`)

An extended [`Rxn`] that carries its own **idle/loading/loaded/error** status, automatically synchronized with value mutations. Perfect for single-object state like a User profile or configuration that goes through an async lifecycle.

```dart
final user = RxS<User?>(null); // T? for nullable support
print(user.status); // RxDataStatus.idle (initial)
```

#### Status Auto-Sync

Every value mutation (`value` setter, `update()`) automatically transitions the status to `loaded`:

```dart
user.value = User(name: 'Alice'); // status → loaded
user.update((u) => User(name: 'Bob')); // status stays loaded
user.value = null; // status stays loaded (null is a valid value)
```

The `error` state is **never** set automatically — assign it manually when an error occurs. This preserves the current value underneath:

```dart
user.setError('Network failure'); // sets error message and status to RxDataStatus.error (current user data is preserved)
```

#### UI Binding — use `Obx(() => value.on(...))`

Wrap `.on()` with `Obx` for reactive binding — the same DX pattern as `Obx(() => value)`:

```dart
Obx(() => user.on(
  idle:    () => const Center(child: Text('Idle')),
  loading: () => const Center(child: CircularProgressIndicator()),
  loaded:  (data) => Text('Hello, ${data?.name ?? "Guest"}'),
  error:   (msg) => Center(child: Text('Oops: ${msg ?? 'Unknown error'}')),
));
```

The `loaded` callback is internally wrapped with `Obx`, so **value mutations trigger immediate UI rebuilds** without additional boilerplate.

#### Nullable Convenience

Because `RxS<T>` extends `Rxn<T>`, it fully supports nullable values. The `loaded` callback receives `T?` data, so you can handle both present and null values:

```dart
RxS<String?> message = RxS<String?>(null);

message.value = 'Hello';  // loaded with value
message.value = null;      // loaded, data is null
```

---

### 4. 🚀 Global/Classic Dependency Injection (`Get.put` & `Get.find`)
Classic GetX singleton dependency injection that registers instances into the global registry instantly or lazily, enabling context-less access from anywhere in your codebase.

Registering instances:
```dart
// 1. put: Instantly instantiates and registers a singleton in global memory
final controller = Get.put(CounterController());

// 2. lazyPut: Registers a builder function, instantiating the controller only on its first Get.find call
Get.lazyPut(() => CounterController());

// 3. Register multiple instances of the same type using tags
Get.put(CounterController(), tag: 'special_counter');
```

Finding instances (context-less anywhere in your code):
```dart
// Resolve and retrieve the registered singleton instance
final controller = Get.find<CounterController>();

// Resolve tagged instances
final specialController = Get.find<CounterController>(null, 'special_counter');
```

> [!TIP]
> `getx_distil` features a **Hybrid DI** system. If you provide a `BuildContext` like `Get.find(context)`, it will prioritize widget tree-scoped lookup (`BindingWidget`). If it is not found, it seamlessly falls back to resolving the dependency from the global registry.
> 
> Furthermore, since v1.0.1, if a controller is registered via `BindingWidget` and has already been instantiated in the widget tree, you can retrieve it **without a context** using a simple `Get.find<T>()` call via a safe, non-leaking static weak reference cache.
> 
> **How Get.find() Resolves Dependencies:**
> 
> * **When `BuildContext` is provided (`Get.find<T>(context)`):**
>   1. **Global Immortal:** Checks if the requested type is a global `GetxService` (immortal widget-scoped service).
>   2. **Widget Tree:** Traverses up the widget tree to find a matching `BindingWidget` scope.
>   3. **Global Registry:** Falls back to global registry (`Get.put` / `Get.lazyPut`).
>   4. **Global Weak Registry:** Falls back to matching active/instantiated widget-scoped controllers.
> 
> * **When `BuildContext` is NOT provided (`Get.find<T>()`):**
>   1. **Global Registry:** Prioritizes checking the global registry (`Get.put` / `Get.lazyPut`).
>   2. **Global Immortal:** Checks if the requested type is a global `GetxService` registered via a widget scope.
>   3. **Global Weak Registry / Active States:** Checks the weak reference cache or active `BindingWidget` states to find/instantiate widget-scoped controllers.
> 
> ```dart
> // 1. Context-based Lookup (prioritizes widget tree)
> final localController = Get.find<CounterController>(context);
> 
> // 2. Context-less Lookup (prioritizes global registry)
> final globalController = Get.find<CounterController>();
> ```

> [!WARNING]
> **Best Practice for Context-less Lookups inside Controllers**
> 
> To prevent race conditions or `Could not find any instance...` errors during construction phase, **never** execute context-less `Get.find()` inside class field initializers or constructors (before `onInit` has run). Sibling or parent controllers might not be fully instantiated yet.
> 
> Instead, defer the lookup using **`late` initializers**, **getters**, or perform them inside **`onInit()`**:
> 
> ```dart
> class ChildController extends GetxController {
>   // ❌ BAD: Runs immediately during constructor execution, causing race conditions
>   // final parent = Get.find<ParentController>();
> 
>   // ✅ GOOD (Option 1): Evaluated lazily when first accessed
>   late final parent = Get.find<ParentController>();
> 
>   // ✅ GOOD (Option 2): Evaluated dynamically on demand
>   ParentController get parent => Get.find<ParentController>();
> 
>   // ✅ GOOD (Option 3): Safely resolved during lifecycle hook
>   late final ParentController parent;
> 
>   @override
>   void onInit() {
>     super.onInit();
>     parent = Get.find<ParentController>();
>   }
> }
> ```

---

### 5. 🌳 Widget Tree-Scoped Dependency Injection (`BindingWidget`)
Synchronize your controller's lifetime directly with your screen's visibility. Perfect for `GoRouter` or native `Navigator`.

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

Inside `SettingsPage` (resolves automatically via `BuildContext`):
```dart
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => Text(controller.someData.value)),
    );
  }
}
```

---

### 6. 🌐 Global Persistent Services (`GetxService`)
For infrastructure-level layers that must remain resident as Immortal Singletons (e.g., Databases, Auth Session Managers, Network Clients).

```dart
class DatabaseService extends GetxService {
  Future<void> init() async => print('DB Connected');
}
```

Register at the root of your application:
```dart
GetMaterialApp(
  bindings: [Bind<DatabaseService>(() => DatabaseService())],
  child: const MyApp(),
);
```

Resolve context-less anywhere in your business logic:
```dart
final db = Get.find<DatabaseService>();
```

---

### 7. 🛠️ Background Side-Effects (`Worker`)
Monitor state variations reactively and execute asynchronous validations, API triggers, or debounces cleanly.

```dart
class SearchController extends GetxController {
  final searchQuery = ''.obs;
  late final Worker _worker;

  @override
  void onInit() {
    super.onInit();
    // Triggers API only after 500ms of user typing inactivity
    _worker = debounce(
      searchQuery, 
      (query) => fetchApi(query), 
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _worker.dispose(); // Enforced explicit disposal prevents memory leaks!
    super.onClose();
  }
}
```

---

### 8. 🔄 Declarative Async Branching (`StateMixin`)
Eradicate convoluted `if-else` blocks in your build methods for typical API states: Loading, Success, Empty, and Error.

```dart
class UserController extends GetxController with StateMixin<String> {
  void fetchUser() async {
    change(null, status: RxStatus.loading());
    try {
      final res = await api.getUser();
      res.isEmpty 
          ? change(null, status: RxStatus.empty()) 
          : change(res, status: RxStatus.success());
    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
    }
  }
}
```

Declarative mapping in the View layer:
```dart
controller.obx(
  (state) => Text('Welcome, $state'),
  onLoading: const CircularProgressIndicator(),
  onEmpty: const Text('No user data found.'),
  onError: (error) => Text('Error: $error', style: const TextStyle(color: Colors.red)),
);
```

---

### 9. 🌐 Internationalization & Localization (`Translations` & `tr`)
Manage translation dictionaries reactively and switch UI language dynamically on-the-fly based on user preferences or device locale settings.

Define custom translations:
```dart
class MyTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'hello': 'Hello World',
      'welcome': 'Welcome, @name!',
    },
    'ko_KR': {
      'hello': '안녕하세요',
      'welcome': '안녕하세요, @name님!',
    }
  };
}
```

Register translations at root `GetMaterialApp`:
```dart
GetMaterialApp(
  translations: MyTranslations(),
  locale: const Locale('en', 'US'),
  fallbackLocale: const Locale('en', 'US'),
  child: const MyApp(),
);
```

Render localized text reactively in your View layer:

**Case 1. When extending `GetView` (recommended)**

`GetViewElement.build()` automatically wraps `build()` with the `Notifier` tracking scope, so calling `.tr` inside `build()` automatically subscribes to `Get.locale(Rx)`. No separate `Obx` is needed:

```dart
// Extending GetView<T> wraps build() in a Notifier tracking scope
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('hello'.tr),                   // ← No Obx needed, auto-subscribed
      ),
      body: Text('welcome'.trParams({'name': 'John Doe'})), // ← No Obx needed
    );
  }
}
```

**Case 2. When using `StatelessWidget` / `StatefulWidget`**

`StatelessWidget` has no Notifier tracking scope, so `.tr` must be wrapped with `Obx` to reactively reflect locale changes. Wrapping the entire `Scaffold` with a single `Obx` avoids repeating `Obx` for every widget:

```dart
// StatelessWidget: wrap the entire Scaffold with Obx for locale reactivity
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(                          // ← Single Obx wrapping Scaffold
      appBar: AppBar(
        title: Text('hello'.tr),                       // ← Now reactive
      ),
      body: Text('welcome'.trParams({'name': 'John Doe'})), // ← Now reactive
    ));
  }
}
```

> [!TIP]
> Using a single `Obx` at the top level (direct child of Scaffold) makes every `.tr` call in the page reactive, keeping the code concise.

Switch locale dynamically at runtime (using the BuildContext to refresh active routes):
```dart
// Change locale to Spanish (or Korean)
Get.locale = const Locale('ko', 'KR');

// Change locale to English
Get.locale = const Locale('en', 'US');
```

---

## 🧪 TDD & Testability

`getx_distil`'s `BindingWidget` shines when it comes to **TDD (Test-Driven Development)** and unit/widget testing.

Traditional global singleton DI systems run into state pollution and test leakage when executing multiple test cases concurrently. Since `BindingWidget` provides a **strictly tree-scoped, isolated DI lifecycle**, you can write mock-driven widget and logic tests without polluting global namespaces or worrying about test order execution.

### 💡 Why is this helpful for TDD?
1. **Zero State Pollution**: Each test instantiates and disposes its own `BindingWidget`, ensuring no residues leak into other tests.
2. **No Production Code Modifications**: You don't need to put `isTesting` flags or custom conditional injection logic inside your Controllers or Views. Just declare your mock bindings inside the test's `BindingWidget`.
3. **Declarative Overrides**: Overriding real services with mock implementations is done in a clear, declarative list of `bindings`.

### 🛠️ TDD Widget Test Example

```dart
// 1. Define your API Service interface
abstract class RestApiService {
  Future<String> fetchUserData();
}

// 2. Define a Mock API Service for testing
class MockRestApiService implements RestApiService {
  @override
  Future<String> fetchUserData() async => "Mock Data";
}

// 3. Controller and View implementation
class MyController extends GetxController {
  final RestApiService api;
  MyController(this.api);
  
  final data = "".obs;
  
  void load() async => data.value = await api.fetchUserData();
}

class MyPage extends GetView<MyController> {
  const MyPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => Text(controller.data.value)),
    );
  }
}

// 4. Writing the Widget Test (TDD)
void main() {
  testWidgets('Overriding with Mock service updates UI correctly', (tester) async {
    // Reset DI state before executing the test
    Get.reset();
    
    await tester.pumpWidget(
      MaterialApp(
        home: BindingWidget(
          bindings: [
            // Bind MockRestApiService instead of the real RealRestApiService!
            Bind<RestApiService>(() => MockRestApiService()),
            Bind<MyController>(() => MyController(Get.find<RestApiService>())),
          ],
          child: const MyPage(),
        ),
      ),
    );
    
    // Trigger the load operation on controller
    Get.find<MyController>().load();
    await tester.pump();
    
    // Assert the mocked data is rendered correctly on screen
    expect(find.text('Mock Data'), findsOneWidget);
  });
}
```

For a comprehensive, runnable TDD example, refer to [example/test/tdd_example_test.dart].


---

## 📄 License

This project is licensed under the MIT License.

