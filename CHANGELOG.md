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
