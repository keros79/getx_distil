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
