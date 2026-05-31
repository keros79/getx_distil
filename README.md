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

* 🌳 **100% Tree-Scoped DI Lifecycle**: Eliminates manual `Get.delete()` calls. Controllers are strictly bound to the Flutter widget tree using `BindingWidget`. When a widget unmounts, its controllers are automatically and cleanly garbage-collected (Auto-GC).
* 🛡️ **Self-Healing Build-Phase Updates**: Modifying reactive state during the widget tree’s build or layout phase normally crashes Flutter with a `setState() during build` exception. `getx_distil` automatically intercepts these and safely defers UI updates to the post-frame callback queue.
* 🛑 **Strict Async Obx Validation**: Mixing `async/await` directly inside `Obx` builders breaks reactive tracking loops. `getx_distil` catches this anti-pattern instantly and throws a descriptive `FlutterError` rather than failing silently.
* 🧵 **FIFO Asynchronous Pipeline (`updateSequential`)**: Introduces a clean sequential queue to prevent critical race conditions and state inversion during high-frequency async operations.
* 📋 **Batched Loop Mutations (`RxList`)**: Instead of triggering expensive UI rebuilds on every single mutation inside a loop, `RxList` aggregates changes and schedules a single microtask UI refresh.
* 🔍 **High-Visibility DI Debugging**: When `Get.find` fails, it no longer throws a cryptic message. It prints a comprehensive debug layout showing the requested context name, the exact parent ancestor widget hierarchy path, and active services in memory.

---

## 🛠️ Essential Components & Quick Start

### 1. 🎯 Reactive State Management (`Rx` & `Obx`)
Isolate updates down to the leaf-most widgets with absolute zero boilerplate.

```dart
class CounterController extends GetxController {
  final count = 0.obs;             // RxInt
  final name = Rxn<String>();      // Safe Nullable Rx

  void increment() {
    count.value++;                 // Simple Overwrite
    name.value = 'Flutter';
  }
}
```

In your View layer (pinpoint rebuilds):
```dart
Obx(() => Text('${controller.count.value}'));
```

---

### 2. 🌳 Widget Tree-Scoped Dependency Injection (`BindingWidget`)
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

### 3. 🌐 Global Persistent Services (`GetxService`)
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

### 4. 🛠️ Background Side-Effects (`Worker`)
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

### 5. 🔄 Declarative Async Branching (`StateMixin`)
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

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](file:///c:/Users/kerbe/Projects/getx_distil/LICENSE) file for details.