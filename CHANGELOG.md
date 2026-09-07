## 2.0.0

### ⚠️ Breaking Changes

* **`Get.find` uses named parameters** (GetX-style `tag:`): `Get.find<T>(context)` → `Get.find<T>(context: context)`, `Get.find<T>(null, 'tag')` → `Get.find<T>(tag: 'tag')`. Tags remain a **global-registry-only** concept: a tagged lookup resolves from `Get.put(tag:)` registrations and skips scoped DI by design (scoped instances are identified by type + widget-tree position, never by a string).
* **Seeded `RxS` / `RxSList` start as `loaded`**: `RxS(value)` with a non-null value and `RxSList([...])` / `[...].ops` with a non-empty list start in `loaded`. Empty/null initial data still starts `idle`.
* **`Rx.updateSequential` no longer swallows errors**: an exception inside `action` completes the returned future with that error (an `await` rethrows; fire-and-forget surfaces as an unhandled Zone error). Pass `onError:` to handle it in place. Errors are still forwarded to attached stream consumers (`ever(onError:)`, `listen`), but only when one exists — no more `addError` into an empty broadcast stream.
* **`Get.put` replaces a pending lazy factory**: when the key only holds an un-instantiated `lazyPut` builder, the provided instance is registered instead of calling the old factory. A live instance is still preserved (singleton behaviour unchanged).

### ✨ New

* **`RxS.load()` / `RxSList.load()` / `RxSList.loadMore()`**: one-line async loading that drives `idle → loading → loaded/empty/error` automatically. Errors are captured into the status (the future never throws), previous data is preserved on failure, overlapping calls follow last-write-wins so stale responses are discarded, and errors are forwarded to `ever(onError:)` Workers. `loadMore()` appends a page without switching to `loading` and updates `hasMore`.
* **`GetBuilder<T>`** widget with `id`, `init`, `global`, `tag`, `autoRemove`, `initState`, `dispose`. Resolves controllers through the hybrid `Get.find(context:, tag:)` lookup, so it works with `BindingWidget` scopes as well as the global registry.
* **`GetxController.update(ids)` honours ids**: `update()` notifies global listeners, `update(['x'])` notifies only listeners registered via `addListenerId('x', …)`. Added `refresh()`, `refreshGroup(id)`, `addListenerId`, `removeListenerId`, `disposeId`, `hasListeners`.
* **`RxMap<K, V>` and `RxSet<E>`** with the same dirty-flag microtask batching, `Notifier.isTracking` read fast-path and Worker compatibility as `RxList`. `Map.obs` / `Set.obs` extensions, `assignAll`, `rawMap` / `rawSet`. Shared batching logic extracted into the `RxBatchNotifier` mixin.
* **Workers**: `interval` (rate-limit, first value per window), `everAll` (multiple observables), `ever(onError:)`. **`GetListenable.bindStream(stream)`** drives any observable from a `Stream`; subscriptions are cancelled on `close()` or `unbindStreams()`.
* **`Get.lazyPut(fenix: true)` now works**: `Get.delete` disposes the instance (`onClose` runs) but keeps the builder registered, so the next `find` re-creates it. `Get.reset(clearFactory: false)` keeps lazy/fenix builders. Added `Get.isPrepared<T>()`.

### 🛠️ Fixed

* **Context-less `Get.find<T>()` ambiguity**: live scoped instances are always preferred over instantiating a binding in another active `BindingWidget`; instantiation only happens when no live instance exists. When several live instances or several declaring scopes match the same type, the most recent one is used and a **one-time debug warning** tells you to pass `context:` so the widget tree decides. Added `BindingWidgetState.liveInstanceCount<T>()` for diagnostics.

## 1.3.2

* **TDD Documentation & Example**: Added comprehensive TDD (Test-Driven Development) documentation in both `README.md` and `README.ko.md`, covering mock service injection patterns with `GetxService` and `BindingWidget`. Includes a full example app (`tdd_test_page.dart`, `tdd_test_controller.dart`) and a corresponding widget test suite (`tdd_example_test.dart`) demonstrating how to write testable controllers with injectable mock services.

## 1.3.1

* **`GetMaterialApp` Root Service Auto-Initialization**: Global services registered via `bindings` in `GetMaterialApp` are now automatically initialized at app startup. Previously, services such as `GetxService` subclasses required a manual `builder` callback workaround (`Get.find<T>(context)`) to trigger initialization; this is no longer necessary.
* **`BindingWidget` Instant Initialization Support**: `BindingWidget` now supports immediate binding initialization at mount time, enabling parent-scoped services to be fully ready before any child widget builds.

## 1.3.0

* **Idle State Support for RxS & RxSList**: Introduced a new `idle` status in both `RxS` and `RxSList`, representing the initial state before any loading or data operation begins. This enables more precise UI branching for lazy-initialized or pre-fetch scenarios.
* **Nullable Error Message Support**: Updated `RxS.setError()` and `RxSList.setError()` to accept nullable error messages, providing greater flexibility when error details are optional.
* **Null Error Message Handling**: Fixed widget builders in both `RxS` and `RxSList` to gracefully handle null error messages without crashing.

## 1.2.1

* **Correction of Localization API Usage in Documentation**: Updated runtime localization examples in both `README.md` and `README.ko.md` to use the reactive `Get.locale` setter property instead of the deprecated `Get.updateLocale` method.

## 1.2.0

* **Localization Documentation Refinement**: Updated localization examples in both `README.md` and `README.ko.md` to cover two distinct use cases:
  - `GetView` pages: `build()` is auto-wrapped by `GetViewElement` with a `Notifier` tracking scope, so `.tr` calls directly inside `build()` automatically subscribe to `Get.locale(Rx)` without needing `Obx`.
  - `StatelessWidget`/`StatefulWidget` pages: No tracking scope exists, so the entire `Scaffold` must be wrapped with a single `Obx` to make all `.tr` calls reactive.
* **Documentation Clarity**: Added a `[!TIP]` admonition recommending a single top-level `Obx` wrapping `Scaffold` for concise StatelessWidget localization.

## 1.1.4

* **Introduced `Get.updateLocale`**: Added a new static method `Get.updateLocale(BuildContext context, Locale val)` that dynamically updates `Get.locale` and safely refreshes the active `GoRouter` configuration (without a compile-time dependency on `go_router`) to immediately apply translations on the current screen without resetting navigation or widget states.
* **Avoided Const Optimization Issues**: Updated localization guides in both `README.md` and `README.ko.md` to recommend using `updateLocale` and removing `const` from page-level router builders to guarantee UI updates when reloading routes.

## 1.1.3

* **Fixed Sticky Error Status**: Resolved an issue in both `RxSList` and `RxS` where the `error` state was sticky and failed to transition back to `loaded` or `empty` when subsequent data mutations or reload attempts occurred.

## 1.1.2

* **Documentation Reordering**: Moved `RxSList` and `RxS` sections higher in both `README.md` and `README.ko.md` to be sections 2 and 3 under Quick Start, reflecting their core importance.
* **Markdown Formatting Polish**: Added newlines between item titles and descriptions under the "Core Enhancements" section for a cleaner layout.
* **HTML/Markdown Parser Warning Fix**: Escaped the angle brackets `<T>` in the `RxSList` class documentation to ensure perfect parser compatibility.

## 1.1.1

* **Reactive Error Messages in RxS & RxSList**: Refactored the `error` property in both `RxS` and `RxSList` to be reactive using an underlying `Rxn<String>` backing variable while maintaining the standard `String?` getter/setter API.
* **Declarative Error Branch Reactivity**: Wrapped the `error` widget builder branch in the `.on()` extension with `Obx` to automatically rebuild the UI whenever the error message changes.
* **Testing Suite Upgrades**: Expanded widget and unit tests in `getx_distil_test.dart` to verify that dynamic mutations to the error message update the rendering tree instantly.

## 1.1.0

* **RxS\<T\> — Status-Aware Single Value**: New [`RxS`] class extending [`Rxn`] that carries its own `loading`/`loaded`/`error` status. Value mutations auto-sync to `loaded`; error state is sticky. Includes `.ops` extension for `T → RxS<T>` conversion and `.on()` widget builder for declarative UI branching.
* **RxSList, RxS Enhancements**: Added core enhancements documentation in README for both `RxSList` (status-aware list) and `RxS` (status-aware single value).
* **Example App — RxS Demo Page**: New RxS controller (`RxSController`) and page (`RxSPage`) demonstrating loading, updating, null-setting, error simulation, and reset.
* **README & Documentation**: Added section 9 "Status-Aware Single Value (`RxS`)" with full usage guide, status auto-sync rules, UI binding patterns, and nullable convenience. Updated Core Enhancements list.

## 1.0.4

* update homepage

## 1.0.3

* **Obx Missing Rx Warning**: Converted the `Obx` missing reactive variable exception to a debug warning to avoid unnecessary crashes.
* **BindingWidget Documentation Refinement**: Documented `BindingWidget`'s core design goal of isolating controllers for concurrent multi-instance child views.
* **Expanded Rx Examples**: Added comprehensive documentation for various Rx types (primitives, nullables, collection auto-batching, custom objects) to READMEs.

## 1.0.2

* **GetView Memory Leak Resolution**: Overrode the `update` lifecycle in `GetViewElement` to clear the `Expando` build context reference of the old widget, preventing unmounted element trees from leaking.
* **Enhanced Testing Support**: Promoted `GetView.contexts` to testing-visible API (`@visibleForTesting`) and added comprehensive test cases verifying resolution, update, and unmount lifecycles.

## 1.0.1

* **Context-less Lookup via Weak References**: Supported context-less `Get.find<T>()` fallback for widget tree-scoped controllers by storing weak references in a static registry (`_weakRegistry`).
* **Memory Safety & Zombie Prevention**: Automated explicit unregistration inside `BindingWidgetState.dispose()` to ensure GC timing does not return dead/zombie controllers, preventing memory leaks.
* **Disposal Sequence Safe Teardown**: Updated disposal order to invoke all controllers' `onDelete()` hooks first before removing them from the weak registry, enabling safe cross-controller lookups during onClose/destruction.

## 1.0.0

* **Initial Stable Release** of `getx_distil`!
* **Core Micro-State Management**: Ultra-lightweight reactive state (`.obs`, `Obx`) engineered for maximum rendering precision and zero overhead.
* **100% Tree-Scoped DI Stack (`BindingWidget`)**: Native Flutter widget-tree synchronized dependency lifecycle with automated garbage collection (Auto-GC).
* **Self-Healing Build-Phase Engine**: Automatically defers state mutations triggered during Flutter's build/layout phases to safe post-frame queues to prevent rendering crashes.
* **Strict Async Obx Verification**: Instantly flags hazardous `async/await` anti-patterns inside `Obx` builders and throws helpful `FlutterError` guides.
* **FIFO Sequential Pipeline (`updateSequential`)**: High-frequency sequential event queue that enforces race-free reactive state ordering.
* **RxList Microtask Batching**: Automatically throttles consecutive loop updates into a single microtask frame, unlocking extreme rendering performance for bulk list mutations.
* **Interactive Localization System (`Translations`, `tr`, `trArgs`)**: Advanced, reactive multi-language translation bindings with parameter injection support.
* **High-Visibility Contextual DI Debugging**: Provides precise parent ancestor path traces and active registry dumps when resolving services fails.
