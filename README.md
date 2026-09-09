# getx_distil

**A concise reactive state-management and hybrid dependency-injection architecture for Flutter.**

`getx_distil` preserves the developer experience that made GetX productive—`.obs`, `Obx`, `Get.find`, workers, and controllers—while making **feature ownership, widget-tree lifetime, and dependency scope explicit**.

It is designed around a practical Flutter question:

> **Which View owns this state, which dependencies does the feature need, and when should they be disposed?**

Unlike a state-management library that only connects widgets to providers, `getx_distil` can describe a feature as one composition unit:

```text
Route / Feature
 ├─ View
 ├─ Controller
 ├─ Dependencies
 └─ Lifetime
```

You can keep application-wide services globally available and scope screen-specific controllers to the widget tree. You do not have to choose one lifetime model for the whole application.

## Why getx_distil?

### 1. Make View–Controller ownership visible

In many provider-based architectures, a View and the state that drives it may be declared in separate files and connected through several provider definitions. That separation is useful for reusable state graphs, but it can make a feature's ownership and lifetime harder to discover.

`getx_distil` lets you declare the relationship at the feature boundary:

```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => BindingWidget(
    bindings: [
      Bind<SettingsController>(() => SettingsController()),
    ],
    child: const SettingsPage(),
  ),
),
```

From this route definition, the feature's essential structure is visible immediately:

| Concern | Declaration |
|---|---|
| View | `SettingsPage` |
| State owner | `SettingsController` |
| Scope | the `BindingWidget` subtree |
| Disposal boundary | `BindingWidget` unmount |

A binding is not only a factory registration. It is an **ownership and lifetime boundary**.

### 2. Use global and tree-scoped DI together

Real applications need more than one lifetime. Authentication, storage, API clients, and analytics are normally application-wide. Search state, form state, detail controllers, and temporary workflows usually belong to a feature or screen instance.

`getx_distil` supports both models:

```text
Application lifetime
 └─ GetMaterialApp bindings / Get.put / Get.lazyPut

Feature or screen lifetime
 └─ BindingWidget tree scope
```

This is a hybrid DI architecture, not a forced migration from global DI to scoped DI.

### 3. Keep state code small and directly readable

```dart
class CounterController extends GetxController {
  final count = 0.obs;

  void increment() => count.value++;
}

class CounterPage extends GetView<CounterController> {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Text('${controller.count.value}'));
  }
}
```

The code shows the complete path directly:

```text
count changes → the Obx that read count rebuilds
```

This low ceremony is not only convenient. Fewer layers can make state ownership, review, and debugging easier for teams that prefer explicit screen-oriented features.

### 4. Treat asynchronous UI state as one state object

`RxS` and `RxSList` combine the data and its common UI status instead of requiring separate observables for data, loading, empty, and error states.

```dart
final users = <User>[].ops;

await users.load(() => api.fetchUsers());
```

The list manages:

```text
idle → loading → loaded / empty
                 └→ error, while preserving previous data
```

This reduces the number of independently mutable flags and therefore reduces contradictory combinations such as `isLoading == false` with an unclear empty/error state.

## Installation

Add the package to `pubspec.yaml`:

```yaml
dependencies:
  getx_distil: ^1.4.1
```

Then import it:

```dart
import 'package:getx_distil/getx_distil.dart';
```

## Quick start

### Reactive state with `Rx` and `Obx`

```dart
class User {
  User({required this.name});
  String name;
}

class HomeController extends GetxController {
  final count = 0.obs;
  final isLoggedIn = false.obs;
  final user = User(name: 'Guest').obs;
  final tags = <String>[].obs;

  void increment() => count.value++;

  void addTag(String tag) => tags.add(tag);
}
```

Use the smallest practical `Obx` scope:

```dart
Obx(() => Text('${controller.count.value}'));

Obx(() => Switch(
  value: controller.isLoggedIn.value,
  onChanged: (value) => controller.isLoggedIn.value = value,
));
```

`Obx` tracks the reactive values read during its synchronous build. Keep asynchronous work in the controller or another service rather than returning a `Future` from the `Obx` builder.

### Imperative updates with `GetBuilder`

Use `GetBuilder` when a controller owns ordinary fields and explicitly decides when to rebuild.

```dart
class CartController extends GetxController {
  int total = 0;
  int badge = 0;

  void addItem() {
    total++;
    badge++;
    update();
    update(['badge']);
  }
}

GetBuilder<CartController>(
  builder: (controller) => Text('Total: ${controller.total}'),
);

GetBuilder<CartController>(
  id: 'badge',
  builder: (controller) => Text('${controller.badge}'),
);
```

`update()` notifies id-less builders. `update(['badge'])` notifies only the matching id group.

## Hybrid dependency injection

### Application-wide bindings

Use `GetMaterialApp.bindings` for dependencies whose lifetime is the application lifetime. The bindings are installed eagerly at the app root.

```dart
class AppConfig extends GetxService {
  final apiBaseUrl = 'https://api.example.com';
}

class AuthService extends GetxService {
  bool isSignedIn = false;
}

void main() {
  runApp(
    GetMaterialApp(
      bindings: [
        Bind<AppConfig>(() => AppConfig()),
        Bind<AuthService>(() => AuthService()),
      ],
      home: const AppRoot(),
    ),
  );
}
```

Global services can be resolved without a `BuildContext`:

```dart
final auth = Get.find<AuthService>();
```

You can also use the familiar global registry directly:

```dart
Get.put<ApiClient>(ApiClient());
Get.lazyPut<AnalyticsService>(() => AnalyticsService());
Get.lazyPut<SessionService>(() => SessionService(), fenix: true);

final api = Get.find<ApiClient>();
```

Use global registration deliberately for application-lifetime objects. A global reference is not inherently a leak; the important question is whether the object's intended lifetime is truly application-wide.

### Screen- or feature-scoped bindings

Use `BindingWidget` when a dependency belongs to a widget subtree, route, feature, or screen instance.

```dart
GoRoute(
  path: '/profile/edit',
  builder: (context, state) => BindingWidget(
    bindings: [
      Bind<EditProfileController>(() => EditProfileController()),
    ],
    child: const EditProfilePage(),
  ),
),
```

The controller can be resolved from the nearest tree scope:

```dart
class EditProfilePage extends GetView<EditProfileController> {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Text(controller.status.value));
  }
}
```

When the `BindingWidget` is disposed, its scoped `GetxController` instances receive their lifecycle teardown and are removed from the active scoped registry. This removes the need for a matching manual `Get.delete()` in the normal screen-scoped case.

The `eager` option creates every binding when the scope mounts:

```dart
BindingWidget(
  eager: true,
  bindings: [
    Bind<FeatureController>(() => FeatureController()),
  ],
  child: const FeaturePage(),
),
```

By default, bindings are created when first resolved.

### Hybrid lookup rules

`Get.find` supports both scope-aware and global lookup:

```dart
// Prefer the nearest BindingWidget, then fall back to global registration.
final local = Get.find<EditProfileController>(context: context);

// Prefer the global registry when no context is supplied.
final service = Get.find<AuthService>();
```

The practical rule is simple:

| Dependency | Recommended registration |
|---|---|
| `AuthService`, `ApiClient`, storage, analytics | `GetMaterialApp.bindings` or global registry |
| Feature repository shared by one feature | feature-level `BindingWidget` or global registry |
| List/detail/form controller | screen-level `BindingWidget` |
| Temporary wizard or workflow state | local tree scope |
| Multiple instances of the same screen | separate `BindingWidget` scopes |

Scoped DI is intentionally tag-free. The widget-tree position identifies the instance. Tags remain available for the global registry:

```dart
Get.put<Logger>(Logger(), tag: 'payments');
final logger = Get.find<Logger>(tag: 'payments');
```

If multiple active scopes contain the same type and a context-less scoped lookup is ambiguous, pass `context:` so the widget tree determines the correct instance.

## Status-aware state

### `RxSList`

`RxSList` is an `RxList` with `idle`, `loading`, `loaded`, `empty`, and `error` status.

```dart
final products = <Product>[].ops;

await products.load(
  () => api.fetchProducts(),
  errorMessage: (error) => 'Could not load products',
);
```

Bind the state declaratively:

```dart
Obx(() => products.on(
  idle: () => const Text('Start searching'),
  loading: () => const CircularProgressIndicator(),
  loaded: (items) => ProductList(items),
  empty: () => const Text('No products'),
  error: (message) => Text(message ?? 'Unknown error'),
));
```

The previous list data is preserved when `load()` fails. `load()` uses a monotonic request token so a stale overlapping response does not overwrite a newer response.

For paging:

```dart
await products.loadMore(() => api.fetchProducts(page: nextPage));
```

`loadMore()` appends the returned page without switching the existing list to the initial `loading` state. Coordinate repeated paging calls in the caller or guard them according to your pagination protocol.

### `RxS`

Use `RxS` for a single nullable or non-nullable value with an asynchronous lifecycle.

```dart
final profile = RxS<User?>(null);

await profile.load(() => api.fetchProfile());

Obx(() => profile.on(
  idle: () => const Text('No profile loaded'),
  loading: () => const CircularProgressIndicator(),
  loaded: (user) => Text(user?.name ?? 'Guest'),
  error: (message) => Text(message ?? 'Error'),
));
```

Setting `value` transitions the state to `loaded`. Calling `setError` preserves the current value underneath the error state.

## Reactive collections and batching

`RxList`, `RxMap`, and `RxSet` support the same reactive collection model:

```dart
final items = <String>[].obs;
final preferences = <String, bool>{}.obs;
final selectedIds = <int>{}.obs;
```

Synchronous collection mutations are coalesced into one microtask notification:

```dart
for (final item in incomingItems) {
  items.add(item);
}
```

This is useful for bulk updates and initialization. The batching optimization applies to reactive collections; ordinary primitive Rx assignments remain individually observable.

## Workers and streams

Workers connect reactive state to side effects:

```dart
class SearchController extends GetxController {
  final query = ''.obs;
  late final Worker queryWorker;

  @override
  void onInit() {
    super.onInit();
    queryWorker = debounce(
      query,
      (value) => search(value),
      time: const Duration(milliseconds: 400),
    );
  }

  @override
  void onClose() {
    queryWorker.dispose();
    super.onClose();
  }

  Future<void> search(String value) async {
    // Fetch results here.
  }
}
```

Available workers include:

```dart
ever(rx, (value) => ...);
everAll([rxA, rxB], (value) => ...);
once(rx, (value) => ...);
debounce(rx, (value) => ..., time: const Duration(milliseconds: 500));
interval(rx, (value) => ..., time: const Duration(seconds: 1));
```

Bind a stream to an observable when stream ownership belongs to that observable:

```dart
final ticks = 0.obs;
ticks.bindStream(Stream.periodic(
  const Duration(seconds: 1),
  (index) => index,
));
```

Bound subscriptions are cancelled by `close()` or `unbindStreams()`.

## Sequential asynchronous updates

Use `updateSequential` when multiple asynchronous updates must be applied in FIFO order.

```dart
final balance = 0.0.obs;

await balance.updateSequential(
  (current) async => current + await fetchDelta(),
);
```

Errors are delivered to the awaiting caller. They can also be handled with `onError` and observed by compatible workers.

## Lifecycle and memory ownership

`getx_distil` does not claim that a DI container can eliminate every possible reference cycle. A global service can still retain a controller through a callback, timer, stream subscription, or static collection if the application registers that reference explicitly.

Its structural guarantee is more specific and practical:

> **Screen- and feature-owned dependencies have an explicit widget-tree owner, and the scope teardown removes the normal strong references and invokes controller lifecycle cleanup.**

This makes the intended lifetime visible in the architecture:

```text
GetMaterialApp bindings
  → application lifetime

Feature BindingWidget
  → feature lifetime

Page BindingWidget
  → page-instance lifetime
```

The result is not “all objects are automatically garbage-collected.” The result is that developers can choose an ownership boundary instead of relying on a global registry and remembering a matching manual deletion call for every screen controller.

## Build-phase safety and `Obx` validation

If a reactive notification occurs during Flutter's build/layout callback phases, `getx_distil` defers the UI updater to a post-frame callback. This is a safety mechanism, not an endorsement of mutating state from a build method.

Keep `Obx` builders synchronous:

```dart
// Correct: perform asynchronous work outside the builder.
Obx(() => Text(controller.title.value));
```

An `Obx` builder that returns a `Future` produces a descriptive `FlutterError` instead of silently creating an invalid tracking scope.

## Testing with scoped overrides

Tree-scoped bindings make widget tests isolated without changing production code to add test-only branches.

```dart
abstract class UserApi {
  Future<String> fetchName();
}

class FakeUserApi implements UserApi {
  @override
  Future<String> fetchName() async => 'Test User';
}

class UserController extends GetxController {
  UserController(this.api);
  final UserApi api;
  final name = ''.obs;
}

await tester.pumpWidget(
  MaterialApp(
    home: BindingWidget(
      bindings: [
        Bind<UserApi>(() => FakeUserApi()),
        Bind<UserController>(() => UserController(Get.find<UserApi>())),
      ],
      child: const UserPage(),
    ),
  ),
);
```

Each test can create its own scope and dispose it with the widget tree. Global dependencies can still be reset or replaced explicitly when a test requires application-level behavior.

## What getx_distil is—and is not

`getx_distil` is a good fit when your application is primarily developed as route- and feature-oriented screens, and you want:

- direct `.obs` and `Obx` ergonomics;
- a visible View–Controller–Dependency relationship;
- global services and screen-scoped controllers in the same application;
- screen-instance isolation without string tags;
- compact loading/error/empty state code;
- imperative `GetBuilder` updates when explicit invalidation is preferable.

A provider-graph architecture may be a better fit when your application is dominated by deeply layered derived state, large parameterized caches, or extensive provider-level override and invalidation workflows. `getx_distil` does not need to imitate every provider abstraction to be useful; it solves the route/feature ownership problem directly.

## API overview

| Need | API |
|---|---|
| Primitive or object reactive state | `Rx`, `.obs`, `Rxn` |
| Reactive widget binding | `Obx` |
| Explicit controller rebuild | `GetBuilder`, `update(ids)` |
| Screen/feature scope | `BindingWidget`, `Bind<T>` |
| App-wide eager bindings | `GetMaterialApp(bindings: ...)` |
| Global or lazy DI | `Get.put`, `Get.lazyPut`, `Get.find` |
| Named global registrations | `tag:` |
| Status-aware list | `RxSList`, `.ops` |
| Status-aware single value | `RxS` |
| Collection batching | `RxList`, `RxMap`, `RxSet` |
| Side effects | `ever`, `everAll`, `once`, `debounce`, `interval` |
| Stream integration | `bindStream` |
| FIFO async mutation | `updateSequential` |
| Controller lifecycle | `GetxController`, `GetxService` |

## Migration from 1.3.x to 1.4

`Get.find` now uses named parameters:

```dart
Get.find<T>(context)       // old
Get.find<T>(context: context) // new

Get.find<T>(null, 'tag')    // old
Get.find<T>(tag: 'tag')     // new
```

Other 1.4 behavior changes include seeded `RxS`/`RxSList` starting as `loaded`, `updateSequential` rethrowing to the awaiting caller unless `onError` is provided, `fenix` builders surviving `Get.delete`, and `Get.put` replacing a pending lazy factory.

## License

MIT License. See the [LICENSE](LICENSE) file.

## References

[1]: https://pub.dev/packages/getx_distil "getx_distil on pub.dev"
[2]: https://github.com/keros79/getx_distil "getx_distil source repository"
[3]: https://getxdistil.web.app "getx_distil project homepage"
[4]: https://riverpod.dev/docs/concepts2/auto_dispose "Riverpod automatic disposal documentation"
[5]: https://riverpod.dev/docs/how_to/select "Riverpod select and rebuild optimization documentation"

Project links: [pub.dev][1] · [source repository][2] · [homepage][3]
