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
* ⏳ **One-line Async Loading (`load()` / `loadMore()`)**
  `await users.load(() => api.fetch())` drives `idle → loading → loaded/empty/error` on `RxSList` and `RxS` automatically, keeps previous data on failure, ignores stale overlapping responses and forwards errors to Workers. `loadMore()` appends the next page without flashing `loading`.
* 📦 **Status-Aware Single Value (`RxS`)**
  An [`Rxn`] subclass that carries its own `idle`/`loading`/`loaded`/`error` status for nullable single-object state. Automatically transitions to `loaded` on value set, with sticky error state.
* 🗺️ **Reactive Collections (`RxList` / `RxMap` / `RxSet`)**
  All three collections share the same dirty-flag microtask batching, read fast-path and Worker compatibility. `<K, V>{}.obs` and `<E>{}.obs` work just like `<E>[].obs`.
* 🧱 **Imperative Rebuilds (`GetBuilder` + `update(ids)`)**
  For controllers that prefer `update()` over `Rx`, `GetBuilder` rebuilds on `update()`, and `GetBuilder(id: 'x')` rebuilds only on `update(['x'])`.
* ⏱️ **Complete Worker Set**
  `ever`, `everAll`, `once`, `debounce`, `interval`, plus `Rx.bindStream` to drive any observable from a `Stream`. Errors from `updateSequential` reach `ever(onError:)` and the awaiting caller — nothing is silently dropped.
* 🔥 **Fenix & GetX-style `tag:`**
  `Get.lazyPut(fenix: true)` re-creates a deleted dependency on the next `find`. `Get.find<T>(tag: 'x')` uses GetX's named `tag:` for the global registry. Scoped DI (`BindingWidget`) stays deliberately tag-free: type + widget-tree position is the identifier.
* 🔍 **High-Visibility DI Debugging**
  When `Get.find` fails, it no longer throws a cryptic message. It prints a comprehensive debug layout showing the requested context name, the exact parent ancestor widget hierarchy path, and active services in memory.
* ⚡ **High-Performance Fast-Path Tracking (`Notifier.isTracking`)**
  In original GetX, reading any reactive variable (even in normal business logic loops or background tasks outside of `Obx` widgets) triggers a lookup of the global tracking proxy. `getx_distil` introduces a lightweight static boolean flag `isTracking`. Outside of active `Obx` build frames, this flag is `false`, bypassing the entire proxy lookup and dependency registration pipeline. This dramatically reduces CPU cycles during heavy calculation loops or traversals.

> **[getx_distil vs GetX vs RiverPod3.0 Comparison](https://getxdistil.web.app/comparison)**

> [!IMPORTANT]
> **Migrating from 1.3.x to 1.4**
>
> `Get.find` now takes **named** parameters, matching GetX's `tag:` style:
>
> ```dart
> Get.find<T>(context)          →  Get.find<T>(context: context)
> Get.find<T>(null, 'tag')      →  Get.find<T>(tag: 'tag')
> ```
>
> Behaviour changes: `RxS(value)` / `RxSList([...])` seeded with data now start as `loaded` (empty/null still start `idle`); `updateSequential` rethrows to the awaiting caller unless `onError:` is given; `Get.delete` on a `fenix` dependency keeps its builder; `Get.put` replaces a pending lazy factory instead of calling it.

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

  // 3. Collection Observables (mutations are auto-batched into one rebuild)
  final items = <String>[].obs;        // RxList<String>
  final prefs = <String, bool>{}.obs;  // RxMap<String, bool>
  final selected = <int>{}.obs;        // RxSet<int>

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

#### Imperative alternative — `GetBuilder` & `update(ids)`

If a controller keeps plain fields and calls `update()`, bind it with `GetBuilder`. Ids scope rebuilds exactly like GetX: `update()` rebuilds every `GetBuilder` **without** an id, `update(['badge'])` rebuilds only `GetBuilder(id: 'badge')`.

```dart
class CartController extends GetxController {
  int total = 0;
  int badge = 0;

  void addItem() {
    total += 1;
    badge += 1;
    update();          // → GetBuilder without id
    update(['badge']); // → GetBuilder(id: 'badge') only
  }
}

GetBuilder<CartController>(builder: (c) => Text('Total: ${c.total}'));
GetBuilder<CartController>(id: 'badge', builder: (c) => Badge(count: c.badge));

// Controller resolution: `init:` registers via Get.put (auto-removed on dispose),
// otherwise the hybrid Get.find(context: ..., tag: ...) lookup is used.
GetBuilder<CartController>(init: CartController(), builder: ...);
```

#### Streams & sequential async updates

```dart
final ticks = 0.obs;
ticks.bindStream(Stream.periodic(const Duration(seconds: 1), (i) => i)); // cancelled on close()

// FIFO queue — errors are never swallowed:
await balance.updateSequential((v) async => v + await fetchDelta()); // throws to the caller on failure
balance.updateSequential(refresh, onError: (e, s) => log(e));       // or handle in place
ever(balance, print, onError: (e) => log(e));                        // Workers see it too
```

---

### 2. 📋 Status-Aware Reactive List (`RxSList`)
An extended [`RxList`] that carries its own **idle/loading/loaded/empty/error** status, automatically synchronized with list mutations. No more separate `isLoading`/`errorMessage` observables — the list manages itself.

```dart
final items = <String>[].ops; // List<T> → RxSList<T> via .ops extension
print(items.status); // RxListStatus.idle — nothing has been loaded yet

final seeded = ['apple', 'banana'].ops;
print(seeded.status); // RxListStatus.loaded — data is already present
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
#### Async loading — `load()` / `loadMore()`

Instead of hand-writing `setLoading()` / `assignAll()` / `setError()` around every API call, let the list drive its own status:

```dart
final users = <User>[].ops;

// idle → loading → loaded (or empty). Errors are captured into the status —
// the future never throws, and the previous items are kept underneath.
await users.load(() => api.fetchUsers());

// Map raw exceptions to a friendly message
await users.load(() => api.fetchUsers(), errorMessage: (e) => 'Could not load users');

// Paging: appends the next page WITHOUT flashing `loading`, and sets hasMore
await users.loadMore(() => api.fetchUsers(page: ++page)); // hasMore = page.isNotEmpty
```

Overlapping `load()` calls are safe: only the most recent call may apply its result, so a slow, stale response can never overwrite fresh data. Errors are also forwarded to Workers attached via `ever(users, ..., onError: ...)`.

---

### 3. 📦 Status-Aware Single Value (`RxS`)

An extended [`Rxn`] that carries its own **idle/loading/loaded/error** status, automatically synchronized with value mutations. Perfect for single-object state like a User profile or configuration that goes through an async lifecycle.

```dart
final user = RxS<User?>(null); // T? for nullable support
print(user.status); // RxDataStatus.idle — no data yet

final profile = User(name: 'Alice').ops; // T → RxS<T> via .ops extension
print(profile.status); // RxDataStatus.loaded — seeded with data
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
#### Async loading — `load()`

The same one-liner exists for single values. `load()` moves the status to `loading`, assigns the fetched value (→ `loaded`), or calls `setError()` on failure while keeping the previous value:

```dart
final user = RxS<User?>(null);

await user.load(() => api.fetchUser());                       // idle → loading → loaded
await user.load(() => api.fetchUser(), errorMessage: (e) => 'Offline'); // → error('Offline')

// UI stays declarative:
Obx(() => user.on(
  loading: () => const CircularProgressIndicator(),
  loaded:  (u) => Text('Hello, ${u?.name}'),
  error:   (msg) => Text(msg ?? 'Unknown error'),
));
```

Concurrent `load()` calls follow last-write-wins: a stale response never overwrites a newer one.

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

// 4. fenix: survives Get.delete — the instance is disposed (onClose runs) but the
//    builder stays registered, so the next Get.find re-creates it.
Get.lazyPut(() => SessionController(), fenix: true);
Get.delete<SessionController>();          // onClose() runs, isRegistered stays true
final fresh = Get.find<SessionController>(); // brand-new instance
```

Finding instances (context-less anywhere in your code):
```dart
// Resolve and retrieve the registered singleton instance
final controller = Get.find<CounterController>();

// Resolve tagged instances
final specialController = Get.find<CounterController>(tag: 'special_counter');
```

> [!TIP]
> `getx_distil` features a **Hybrid DI** system. If you provide a `BuildContext` like `Get.find(context: context)`, it will prioritize widget tree-scoped lookup (`BindingWidget`). If it is not found, it seamlessly falls back to resolving the dependency from the global registry. A `tag:` is a **global-registry-only** concept: a tagged lookup goes straight to `Get.put(tag:)` registrations and skips the widget tree, because scoped DI is identified by type + tree position, never by a string.
> 
> Furthermore, since v1.0.1, if a controller is registered via `BindingWidget` and has already been instantiated in the widget tree, you can retrieve it **without a context** using a simple `Get.find<T>()` call via a safe, non-leaking static weak reference cache.
> 
> **How Get.find() Resolves Dependencies:**
> 
> * **When `BuildContext` is provided (`Get.find<T>(context: context)`):**
>   1. **Global Immortal:** Checks if the requested type is a global `GetxService` (immortal widget-scoped service).
>   2. **Widget Tree:** Traverses up the widget tree to find a matching `BindingWidget` scope.
>   3. **Global Registry:** Falls back to global registry (`Get.put` / `Get.lazyPut`).
>   4. **Global Weak Registry:** Falls back to matching active/instantiated widget-scoped controllers.
> 
> * **When `BuildContext` is NOT provided (`Get.find<T>()`):**
>   1. **Global Registry:** Prioritizes checking the global registry (`Get.put` / `Get.lazyPut`).
>   2. **Global Immortal:** Checks if the requested type is a global `GetxService` registered via a widget scope.
>   3. **Global Weak Registry / Active States:** Checks the weak reference cache for a **live** scoped instance first; only if none exists does it instantiate the binding in an active `BindingWidget` scope. If several scopes match the same `T`, the most recently created/mounted one is used and a **one-time debug warning** is printed — pass a `BuildContext` so the widget tree decides which scope you mean.
> 
> ```dart
> // 1. Context-based Lookup (prioritizes widget tree)
> final localController = Get.find<CounterController>(context: context);
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

> [!NOTE]
> Scoped DI is intentionally **tag-free**. The widget tree already answers "which instance?" by position, so `Bind` has no `tag` and `GetView` has no `tag`. Need two instances of the same type? Give each its own `BindingWidget` scope. Tags belong to the global registry only (`Get.put(tag:)` / `Get.find(tag:)`).

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

The full worker set:

```dart
ever(rx, (v) => ..., onError: (e) => ...); // every change (+ errors from updateSequential)
everAll([rxA, rxB], (v) => ...);            // any of several observables changed
once(rx, (v) => ...);                       // first change only, then auto-disposes
debounce(rx, (v) => ..., time: const Duration(milliseconds: 500)); // after a quiet period
interval(rx, (v) => ..., time: const Duration(seconds: 1));        // at most once per window (first value wins)
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

## 🚦 GoRouter & Reactive Route Guard

Instead of providing a proprietary custom routing engine, `getx_distil` promotes using standard declarative routing packages like **`GoRouter`**. Since all `Rx` types in `getx_distil` (e.g. `RxBool`, `Rxn`, etc.) implement Flutter's native `ValueListenable` interface, they can be directly passed to `GoRouter`'s `refreshListenable` parameter to build reactive route guards (authentication and permission middlewares) in a declarative manner.

### 1. Defining the Global AuthController

The global controller tracks session load status (`isInitialized`) and user authentication status (`isLoggedIn`).

```dart
class AuthController extends GetxController {
  final isLoggedIn = false.obs;
  final isInitialized = false.obs; // Tracks if session verification is complete

  @override
  void onInit() {
    super.onInit();
    checkAuthSession(); // Check session asynchronously in the background (non-blocking)
  }

  Future<void> checkAuthSession() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulating secure storage lookup
    isLoggedIn.value = true; // Set based on session existence
    isInitialized.value = true; // Flip initialization flag
  }
}
```

### 2. main() & GoRouter Configuration (Proper Initialization Timing)

Declaring `GoRouter` as a top-level global or static variable and calling `Get.find<AuthController>()` within its `refreshListenable` initializer can trigger dependency lookup failures if the router is evaluated before the dependency is registered.

To prevent this, you should **register the global controller in `main()` using `Get.put(AuthController(), permanent: true)`** before starting the widget tree.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register AuthController globally before the app and router start
  Get.put(AuthController(), permanent: true);
  
  runApp(const MyApp());
}

// Top-level GoRouter declaration
final auth = Get.find<AuthController>();

final goRouter = GoRouter(
  initialLocation: '/splash',
  // Reactive Binding: whenever these Rx values change, GoRouter automatically re-evaluates redirect()
  refreshListenable: Listenable.merge([
    auth.isLoggedIn,
    auth.isInitialized,
  ]),
  redirect: (context, state) {
    // 1. Maintain splash screen until session loading is complete
    if (!auth.isInitialized.value) {
      return '/splash';
    }

    final loggedIn = auth.isLoggedIn.value;
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToSplash = state.matchedLocation == '/splash';

    // Force redirect to login page if unauthenticated
    if (!loggedIn) {
      return '/login';
    }

    // Redirect to home if logged in but trying to access login/splash
    if (loggedIn && (isGoingToLogin || isGoingToSplash)) {
      return '/';
    }

    return null; // Proceed to destination route
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(), // Loading/Splash widget
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const BindingWidget(
        bindings: [Bind(HomeController.new)],
        child: HomePage(),
      ),
    ),
  ],
);
```

### ⚠️ Initialization Timing Caveat (Crash Example)

The `bindings` parameter in `GetMaterialApp` registers dependencies during the widget build phase. If you declare `GoRouter` as a top-level global variable that references `Get.find`, while defining the controller under `GetMaterialApp(bindings: [...])`, **the router is evaluated before `GetMaterialApp` builds, resulting in a lookup failure crash**.

```dart
// ❌ Incorrect: GoRouter tries to find AuthController before it is registered
final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: Listenable.merge([
    Get.find<AuthController>().isLoggedIn, // 🚨 CRASH: AuthController is not registered yet!
  ]),
  routes: [...],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      routerConfig: router, // Evaluates 'router' statically during build config
      bindings: [
        Bind<AuthController>(() => AuthController()), // ◀ Too late! Registered after GoRouter is built
      ],
    );
  }
}
```

For global authentication services linked to route guards, you must register them in the entry point **`main()` using `Get.put(..., permanent: true)`** to guarantee that the dependency exists before the router starts.

---

## 📄 License

This project is licensed under the MIT License.

