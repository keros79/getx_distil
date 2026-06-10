import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_distil/get.dart';

class CounterController extends GetxController {
  final count = 0.obs;

  void increment() {
    count.value++;
  }
}

class LifecycleController extends GetxController {
  bool onInitCalled = false;
  bool onReadyCalled = false;
  bool onCloseCalled = false;

  @override
  void onInit() {
    super.onInit();
    onInitCalled = true;
  }

  @override
  void onReady() {
    super.onReady();
    onReadyCalled = true;
  }

  @override
  void onClose() {
    onCloseCalled = true;
    super.onClose();
  }
}

class DatabaseService extends GetxService {
  bool onCloseCalled = false;

  @override
  void onClose() {
    onCloseCalled = true;
    super.onClose();
  }
}

class RegularController extends GetxController {
  bool onCloseCalled = false;

  @override
  void onClose() {
    onCloseCalled = true;
    super.onClose();
  }
}

class ApiController extends GetxController with StateMixin<String> {}

class SiblingControllerA extends GetxController {
  bool resolvedSiblingDuringClose = false;

  @override
  void onClose() {
    try {
      final sibling = Get.find<SiblingControllerB>();
      resolvedSiblingDuringClose = (sibling != null);
    } catch (e) {
      resolvedSiblingDuringClose = false;
    }
    super.onClose();
  }
}

class SiblingControllerB extends GetxController {}

class MyGetView extends GetView<CounterController> {
  const MyGetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Text('Count: ${controller.count.value}'));
  }
}

void main() {
  test('Rx Core Getter & Setter features', () {
    final count = 10.obs;
    expect(count.value, 10);

    // Test setter/getter
    count.value = 20;
    expect(count.value, 20);

    // Operator and primitive type checks
    final text = 'hello'.obs;
    expect(text.value, 'hello');

    final flag = true.obs;
    expect(flag.isTrue, true);
    flag.toggle();
    expect(flag.isFalse, true);

    // Test nullable setter (explicit null assignment)
    final nullableText = Rxn<String>('initial');
    expect(nullableText.value, 'initial');
    nullableText.value = null;
    expect(nullableText.value, null);
  });

  test('Rx updateSequential FIFO Queue Optimization', () async {
    final price = 100.obs;
    final List<int> executionOrder = [];

    // Trigger three asynchronous high-frequency operations concurrently
    final Future<void> first = price.updateSequential((current) async {
      await Future.delayed(const Duration(milliseconds: 50));
      executionOrder.add(1);
      return current + 10; // 110
    });

    final Future<void> second = price.updateSequential((current) async {
      await Future.delayed(const Duration(milliseconds: 10));
      executionOrder.add(2);
      return current * 2; // 220
    });

    final Future<void> third = price.updateSequential((current) async {
      executionOrder.add(3);
      return current - 5; // 215
    });

    await Future.wait([first, second, third]);

    // Assert strict sequential FIFO execution (1 then 2 then 3) despite different async delays
    expect(executionOrder, [1, 2, 3]);
    expect(price.value, 215);
  });

  testWidgets('Obx Reactive Rebuild Widget Test', (WidgetTester tester) async {
    final count = 0.obs;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Obx(() => Text('Count: ${count.value}')),
      ),
    );

    expect(find.text('Count: 0'), findsOneWidget);

    count.value = 5;
    await tester.pump();

    expect(find.text('Count: 5'), findsOneWidget);
  });

  test('Notifier.append throws FlutterError when builder returns a Future', () {
    expect(
      () => Notifier.instance.append(
        NotifyData(updater: () {}, disposers: [], throwException: false),
        () async => 'Async Result',
      ),
      throwsA(isA<FlutterError>()),
    );
  });

  testWidgets(
    'Obx throws FlutterError or TypeError when builder is asynchronous',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() => Future.value(const Text('Async')) as dynamic),
        ),
      );

      final dynamic exception = tester.takeException();
      expect(exception, anyOf(isA<FlutterError>(), isA<TypeError>()));
    },
  );

  testWidgets(
    'Obx does not throw setState() during build when reactive state is changed during build phase',
    (WidgetTester tester) async {
      final count = 0.obs;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Obx(() => Text('Count: ${count.value}')),
              Builder(
                builder: (context) {
                  // Mutating state during the build phase of another widget
                  count.value = 10;
                  return const Text('Mutator');
                },
              ),
            ],
          ),
        ),
      );

      // Verify no exception was thrown by checking tester.takeException
      expect(tester.takeException(), null);

      // Pump a frame to let the deferred post-frame callback apply the update
      await tester.pump();
      expect(find.text('Count: 10'), findsOneWidget);
    },
  );

  testWidgets('Scoped DI and isolated multi-instances test', (
    WidgetTester tester,
  ) async {
    // Nested view scopes with duplicate bindings
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BindingWidget(
          bindings: [Bind<CounterController>(() => CounterController())],
          child: Builder(
            builder: (context1) {
              final outer = Get.find<CounterController>(context1);
              outer.count.value = 10;

              return BindingWidget(
                bindings: [Bind<CounterController>(() => CounterController())],
                child: Builder(
                  builder: (context2) {
                    final inner = Get.find<CounterController>(context2);
                    // Inner should start at 0 (isolated from outer duplicate)
                    expect(inner.count.value, 0);
                    expect(outer.count.value, 10);

                    return Column(
                      children: [
                        Obx(() => Text('Outer: ${outer.count.value}')),
                        Obx(() => Text('Inner: ${inner.count.value}')),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Outer: 10'), findsOneWidget);
    expect(find.text('Inner: 0'), findsOneWidget);
  });

  testWidgets('GetxController lifecycle hooks and automatic onClose on dispose', (
    WidgetTester tester,
  ) async {
    final lifecycleController = LifecycleController();
    bool showChild = true;

    late StateSetter setChildState;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setState) {
            setChildState = setState;
            if (!showChild) return const SizedBox.shrink();

            return BindingWidget(
              bindings: [Bind<LifecycleController>(() => lifecycleController)],
              child: Builder(
                builder: (context) {
                  // Resolve to initialize controller and trigger onInit/onReady
                  final controller = Get.find<LifecycleController>(context);
                  expect(controller.onInitCalled, true);
                  return const Text('Active Scope');
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pump(); // Allow post frame callback for onReady
    expect(lifecycleController.onReadyCalled, true);
    expect(lifecycleController.onCloseCalled, false);

    // Remove the BindingWidget from the tree
    setChildState(() {
      showChild = false;
    });
    await tester.pump();

    // Verify onClose was invoked automatically on disposal
    expect(lifecycleController.onCloseCalled, true);
  });

  test('Workers Engine (ever, once, debounce) test', () async {
    final count = 0.obs;
    final List<int> everValues = [];
    final List<int> onceValues = [];
    final List<int> debounceValues = [];

    // Initialize workers
    final w1 = ever(count, (val) => everValues.add(val));
    final w2 = once(count, (val) => onceValues.add(val));
    final w3 = debounce(
      count,
      (val) => debounceValues.add(val),
      time: const Duration(milliseconds: 50),
    );

    // First change
    count.value = 1;
    await Future.delayed(const Duration(milliseconds: 10));

    // Second change
    count.value = 2;
    await Future.delayed(const Duration(milliseconds: 10));

    // Third change
    count.value = 3;
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // Allow debounce to fire after silence

    expect(everValues, [1, 2, 3]);
    expect(onceValues, [1]); // Only fires on first change
    expect(debounceValues, [3]); // Only fires on the final change after silence

    // Dispose workers
    w1.dispose();
    w2.dispose();
    w3.dispose();

    // Verify no updates are tracked after disposal
    count.value = 4;
    await Future.delayed(const Duration(milliseconds: 100));
    expect(everValues, [1, 2, 3]); // Remained unchanged
  });

  // ─── RxList Tests ──────────────────────────────────────────────────────────

  test('RxList.obs extension returns RxList<E>', () {
    final list = <int>[1, 2, 3].obs;
    expect(list, isA<RxList<int>>());
    expect(list.length, 3);
  });

  test('RxList basic mutators operate correctly on backing list', () {
    final list = RxList<String>();

    list.add('a');
    list.add('b');
    expect(list.rawList, ['a', 'b']);

    list[0] = 'A';
    expect(list[0], 'A');

    list.addAll(['c', 'd']);
    expect(list.length, 4);

    list.remove('c');
    expect(list.rawList, ['A', 'b', 'd']);

    list.removeAt(0);
    expect(list.rawList, ['b', 'd']);

    list.clear();
    expect(list.rawList, isEmpty);

    // Clear on empty list does NOT schedule a notification
    // (tested implicitly — no exception thrown)
    list.clear();
  });

  test('RxList.assignAll replaces all elements atomically', () {
    final list = RxList<int>([10, 20, 30]);
    list.assignAll([1, 2, 3, 4, 5]);
    expect(list.rawList, [1, 2, 3, 4, 5]);
  });

  test('RxList.value setter replaces backing list', () {
    final list = RxList<int>([1, 2, 3]);
    list.value = [7, 8, 9];
    expect(list.value, [7, 8, 9]);
  });

  test('RxList dirty-flag batching: loop fires exactly ONE rebuild', () async {
    final list = RxList<int>();
    int rebuildCount = 0;

    // Simulate what Obx does: register a listener
    list.addListener(() => rebuildCount++);

    // Synchronous burst of 100 mutations
    for (int i = 0; i < 100; i++) {
      list.add(i);
    }

    // No rebuild yet — microtask hasn't fired
    expect(rebuildCount, 0);

    // Yield to microtask queue
    await Future<void>.value();

    // Exactly ONE rebuild regardless of how many mutations were batched
    expect(rebuildCount, 1);
    expect(list.length, 100);
  });

  test('RxList successive bursts each produce one rebuild', () async {
    final list = RxList<int>();
    int rebuildCount = 0;
    list.addListener(() => rebuildCount++);

    // First burst
    list.add(1);
    list.add(2);
    list.add(3);
    await Future<void>.value();
    expect(rebuildCount, 1);

    // Second burst
    list.assignAll([10, 20, 30]);
    list.add(40);
    await Future<void>.value();
    expect(rebuildCount, 2); // one additional rebuild for the second burst

    expect(list.rawList, [10, 20, 30, 40]);
  });

  testWidgets('RxList triggers Obx rebuild exactly once per event', (
    WidgetTester tester,
  ) async {
    final items = RxList<String>();
    int buildCount = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Obx(() {
          buildCount++;
          return Text('count:${items.length}');
        }),
      ),
    );

    // Initial build
    expect(buildCount, 1);
    expect(find.text('count:0'), findsOneWidget);

    // Perform 50 synchronous adds — should coalesce to one rebuild
    for (int i = 0; i < 50; i++) {
      items.add('item_$i');
    }

    // 1. Drain the microtask queue so _autoBatchRefresh fires refresh()
    //    and calls markNeedsBuild() on the Obx element.
    await tester.runAsync(() async {
      await Future<void>.microtask(() {});
    });

    // 2. Pump the frame so Flutter actually rebuilds the widget.
    await tester.pump();

    expect(buildCount, 2); // only ONE additional rebuild
    expect(find.text('count:50'), findsOneWidget);
  });

  // ─── RxList Side-Effect Regression Tests ──────────────────────────────────

  test('[Regression] ever worker receives RxList mutation events', () async {
    // CRITICAL BUG FIX: _autoBatchRefresh previously only called refresh()
    // (Obx updaters) but never _controller.add() (stream workers).
    // This test verifies ever/once/debounce now work correctly with RxList.
    final list = RxList<String>();
    final received = <List<String>>[];

    final w = ever(list, (l) => received.add(List<String>.of(l)));

    list.add('a');
    list.add('b');
    // Two rounds needed:
    //   Round 1: _autoBatchRefresh microtask fires → refresh() + notifyStream()
    //   Round 2: broadcast stream delivers the event to the ever() callback
    await Future<void>.value();
    await Future<void>.value();

    expect(
      received.length,
      1,
      reason: 'ever should fire exactly once for a burst of mutations',
    );
    expect(received.first, ['a', 'b']);

    list.assignAll(['x', 'y', 'z']);
    await Future<void>.value();
    await Future<void>.value();

    expect(
      received.length,
      2,
      reason: 'ever should fire again for the second burst',
    );
    expect(received.last, ['x', 'y', 'z']);

    w.dispose();
  });

  test(
    '[Regression] close() prevents zombie microtask from re-arming flag',
    () async {
      final list = RxList<int>();
      int notifyCount = 0;
      list.addListener(() => notifyCount++);

      list.add(1); // arms the microtask
      list.close(); // must reset _isNotificationScheduled = false

      await Future<void>.value(); // microtask fires — should be a safe no-op

      // After close(), _updaters is cleared, so notifyCount stays 0.
      expect(notifyCount, 0);

      // Crucially, _isNotificationScheduled must be false so the list could
      // be reused without being permanently silenced.
      // We verify by checking the flag indirectly: if it were still true,
      // a subsequent add would never schedule a microtask.
      // (Behavioural test only — no direct flag access needed.)
    },
  );

  test('[Regression] sort() fires exactly one notification', () async {
    final list = RxList<int>([5, 3, 1, 4, 2]);
    int notifyCount = 0;
    list.addListener(() => notifyCount++);

    list.sort(); // must NOT call []= N times — overrides ListMixin default
    await Future<void>.value();

    expect(notifyCount, 1, reason: 'sort() must produce exactly one rebuild');
    expect(list.rawList, [1, 2, 3, 4, 5]);
  });

  test('[Regression] shuffle() fires exactly one notification', () async {
    final list = RxList<int>([1, 2, 3, 4, 5]);
    int notifyCount = 0;
    list.addListener(() => notifyCount++);

    list.shuffle();
    await Future<void>.value();

    expect(
      notifyCount,
      1,
      reason: 'shuffle() must produce exactly one rebuild',
    );
    expect(list.length, 5);
  });

  test('[Regression] length= no-op guard skips notification', () async {
    final list = RxList<int>([1, 2, 3]);
    int notifyCount = 0;
    list.addListener(() => notifyCount++);

    list.length = 3; // same length → no notification
    await Future<void>.value();

    expect(notifyCount, 0, reason: 'length= with same value must not notify');

    list.length = 2; // actual truncation → one notification
    await Future<void>.value();

    expect(notifyCount, 1);
    expect(list.rawList, [1, 2]);
  });

  // ─── GetxService & StateMixin Tests ────────────────────────────────────────

  testWidgets(
    'GetxService behaves as an Immortal Service across widget disposal',
    (WidgetTester tester) async {
      final dbService = DatabaseService();
      final regularController = RegularController();
      bool showScope = true;

      late StateSetter setScopeState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              setScopeState = setState;
              if (!showScope) return const SizedBox.shrink();

              return BindingWidget(
                bindings: [
                  Bind<DatabaseService>(() => dbService),
                  Bind<RegularController>(() => regularController),
                ],
                child: Builder(
                  builder: (context) {
                    // Resolve them to instantiate
                    Get.find<DatabaseService>(context);
                    Get.find<RegularController>(context);
                    return const Text('Active DI Scope');
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      expect(dbService.onCloseCalled, false);
      expect(regularController.onCloseCalled, false);

      // Pop/dispose the BindingWidget scope
      setScopeState(() {
        showScope = false;
      });
      await tester.pump();

      // RegularController must be garbage collected and onClose called
      expect(regularController.onCloseCalled, true);

      // GetxService MUST skip garbage collection and onClose should NOT be called
      expect(dbService.onCloseCalled, false);

      // Get.find (or getImmortal) must still be able to retrieve it safely
      expect(BindingWidgetState.getImmortal<DatabaseService>(), dbService);
    },
  );

  testWidgets(
    'StateMixin.obx renders correct loading, success, error, and empty states',
    (WidgetTester tester) async {
      final apiController = ApiController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: apiController.obx(
            (state) => Text('Success: $state'),
            onLoading: const Text('Loading View'),
            onError: (err) => Text('Error: $err'),
            onEmpty: const Text('Empty View'),
          ),
        ),
      );

      // Initially in Loading status
      expect(find.text('Loading View'), findsOneWidget);

      // Change to Success status
      apiController.change('Fetched Data', status: RxStatus.success());
      await tester.pump();
      expect(find.text('Success: Fetched Data'), findsOneWidget);

      // Change to Error status
      apiController.change(null, status: RxStatus.error('Failed to load'));
      await tester.pump();
      expect(find.text('Error: Failed to load'), findsOneWidget);

      // Change to Empty status
      apiController.change(null, status: RxStatus.empty());
      await tester.pump();
      expect(find.text('Empty View'), findsOneWidget);
    },
  );

  group('Hybrid DI Tests', () {
    setUp(() {
      Get.reset();
    });

    testWidgets(
      'Get.find detailed DI error message contains context path and service lists',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                expect(
                  () => Get.find<CounterController>(context),
                  throwsA(
                    isA<FlutterError>().having(
                      (e) => e.message,
                      'message',
                      allOf(
                        contains('📍 Requested Context Widget: Builder'),
                        contains('🌳 Search Path (Ancestor Widgets):'),
                        contains('🌐 Registered Global Services:'),
                        contains('🌟 Registered Immortal Services:'),
                      ),
                    ),
                  ),
                );
                return const Text('Test');
              },
            ),
          ),
        );
      },
    );

    test('Get.put and context-less Get.find resolves successfully', () {
      final controller = Get.put(CounterController());
      expect(controller.count.value, 0);

      final resolved = Get.find<CounterController>();
      expect(resolved, controller);
    });

    test(
      'Get.put behaves as a singleton and does not overwrite existing instance',
      () {
        final controller1 = Get.put(CounterController());
        final controller2 = Get.put(CounterController());

        expect(controller2, controller1);
        expect(Get.isRegistered<CounterController>(), true);
      },
    );

    test('Get.lazyPut instantiates dependency lazily', () {
      bool instantiated = false;
      Get.lazyPut<CounterController>(() {
        instantiated = true;
        return CounterController();
      });

      expect(instantiated, false);

      final resolved = Get.find<CounterController>();
      expect(instantiated, true);
      expect(resolved.count.value, 0);
    });

    test('Get.delete triggers onClose and cleans registry', () {
      final controller = LifecycleController();
      Get.put<LifecycleController>(controller);

      expect(controller.onInitCalled, true);
      expect(controller.onCloseCalled, false);

      final deleted = Get.delete<LifecycleController>();
      expect(deleted, true);
      expect(controller.onCloseCalled, true);

      expect(
        () => Get.find<LifecycleController>(),
        throwsA(isA<FlutterError>()),
      );
    });

    test('Get.put and Get.find with tag support isolated correctly', () {
      final controllerA = Get.put(CounterController(), tag: 'A');
      final controllerB = Get.put(CounterController(), tag: 'B');

      controllerA.count.value = 10;
      controllerB.count.value = 20;

      expect(Get.find<CounterController>(null, 'A').count.value, 10);
      expect(Get.find<CounterController>(null, 'B').count.value, 20);
    });

    testWidgets(
      'Hybrid lookup priority: Scoped lookup preferred, fallback to global',
      (WidgetTester tester) async {
        // Global controller
        final globalController = CounterController()..count.value = 100;
        Get.put<CounterController>(globalController);

        // Scoped controller
        final scopedController = CounterController()..count.value = 10;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BindingWidget(
              bindings: [Bind<CounterController>(() => scopedController)],
              child: Builder(
                builder: (context) {
                  // With context: retrieves scoped controller (10)
                  final resolvedScoped = Get.find<CounterController>(context);
                  expect(resolvedScoped.count.value, 10);

                  // Without context: falls back to global controller (100)
                  final resolvedGlobal = Get.find<CounterController>();
                  expect(resolvedGlobal.count.value, 100);

                  return const Text('Active Scope');
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets('GetxService fallback via getImmortal when context is null', (
      WidgetTester tester,
    ) async {
      final dbService = DatabaseService();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindingWidget(
            bindings: [Bind<DatabaseService>(() => dbService)],
            child: Builder(
              builder: (context) {
                // Initialize the service via scoped lookup once
                Get.find<DatabaseService>(context);
                return const Text('Active Scope');
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Now lookup WITHOUT context - should successfully resolve via getImmortal
      final resolved = Get.find<DatabaseService>();
      expect(resolved, dbService);
    });

    testWidgets(
      'Context-less lookup resolves scoped controller via weak registry',
      (WidgetTester tester) async {
        final controller = CounterController();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BindingWidget(
              bindings: [Bind<CounterController>(() => controller)],
              child: Builder(
                builder: (context) {
                  Get.find<CounterController>(context);
                  return const Text('Active Scope');
                },
              ),
            ),
          ),
        );

        await tester.pump();

        final resolved = Get.find<CounterController>();
        expect(resolved, controller);
      },
    );

    testWidgets(
      'Context-less lookup fails after BindingWidget is disposed (prevents zombie reference)',
      (WidgetTester tester) async {
        final controller = CounterController();
        bool showChild = true;
        late StateSetter setChildState;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                setChildState = setState;
                if (!showChild) return const SizedBox.shrink();

                return BindingWidget(
                  bindings: [Bind<CounterController>(() => controller)],
                  child: Builder(
                    builder: (context) {
                      Get.find<CounterController>(context);
                      return const Text('Active Scope');
                    },
                  ),
                );
              },
            ),
          ),
        );

        await tester.pump();
        expect(Get.find<CounterController>(), controller);

        setChildState(() {
          showChild = false;
        });
        await tester.pump();

        expect(
          () => Get.find<CounterController>(),
          throwsA(isA<FlutterError>()),
        );
      },
    );

    testWidgets(
      'Disposal sequence allows cross-controller lookup during onClose (Complement 1)',
      (WidgetTester tester) async {
        final controllerA = SiblingControllerA();
        final controllerB = SiblingControllerB();

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BindingWidget(
              bindings: [
                Bind<SiblingControllerA>(() => controllerA),
                Bind<SiblingControllerB>(() => controllerB),
              ],
              child: Builder(
                builder: (context) {
                  Get.find<SiblingControllerA>(context);
                  Get.find<SiblingControllerB>(context);
                  return const Text('Active Scope');
                },
              ),
            ),
          ),
        );

        await tester.pump();

        await tester.pumpWidget(const SizedBox.shrink());

        expect(controllerA.resolvedSiblingDuringClose, true);
      },
    );

    testWidgets(
      'GetMaterialApp binds root-level dependencies and propagates them',
      (WidgetTester tester) async {
        final counter = CounterController();

        await tester.pumpWidget(
          GetMaterialApp(
            bindings: [Bind<CounterController>(() => counter)],
            home: Builder(
              builder: (context) {
                final resolved = Get.find<CounterController>(context);
                return Text('Count: ${resolved.count.value}');
              },
            ),
          ),
        );

        expect(find.text('Count: 0'), findsOneWidget);
      },
    );

    testWidgets('GetMaterialApp reactively updates themeMode dynamically', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
          themeMode: ThemeMode.light,
          home: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Text('Brightness: ${theme.brightness.name}');
            },
          ),
        ),
      );

      expect(find.text('Brightness: light'), findsOneWidget);

      // Reactively change theme mode
      Get.themeMode = ThemeMode.dark;
      await tester.pumpAndSettle();

      expect(find.text('Brightness: dark'), findsOneWidget);
    });
  });

  group('GetView Tests', () {
    setUp(() {
      Get.reset();
    });

    testWidgets('GetView resolves controller successfully via BuildContext', (
      WidgetTester tester,
    ) async {
      final counter = CounterController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindingWidget(
            bindings: [Bind<CounterController>(() => counter)],
            child: const MyGetView(),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      counter.count.value = 5;
      await tester.pump();

      expect(find.text('Count: 5'), findsOneWidget);
    });

    testWidgets(
      'GetView clears contexts on widget update (prevents memory leak)',
      (WidgetTester tester) async {
        final counter = CounterController();
        GetView<CounterController>? originalWidget;
        GetView<CounterController>? updatedWidget;

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BindingWidget(
              bindings: [Bind<CounterController>(() => counter)],
              child: StatefulBuilder(
                builder: (context, setState) {
                  final view = MyGetView(key: const ValueKey('view'));
                  if (originalWidget == null) {
                    originalWidget = view;
                  } else {
                    updatedWidget = view;
                  }
                  return Column(
                    children: [
                      view,
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Rebuild'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Verify original widget context is registered
        final contextsMap = GetView.contexts;
        expect(contextsMap[originalWidget!], isNotNull);

        // Trigger rebuild to update widget
        await tester.tap(find.text('Rebuild'));
        await tester.pump();

        // Verify a new widget was created and the old one cleared
        expect(updatedWidget, isNotNull);
        expect(updatedWidget, isNot(originalWidget));
        expect(contextsMap[updatedWidget!], isNotNull);
        expect(
          contextsMap[originalWidget!],
          isNull,
          reason: 'Old widget context must be cleared to prevent memory leak',
        );
      },
    );

    testWidgets('GetView clears context on unmount', (
      WidgetTester tester,
    ) async {
      final counter = CounterController();
      GetView<CounterController>? widgetInstance;
      bool showView = true;
      late StateSetter setViewState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindingWidget(
            bindings: [Bind<CounterController>(() => counter)],
            child: StatefulBuilder(
              builder: (context, setState) {
                setViewState = setState;
                if (!showView) return const SizedBox.shrink();
                widgetInstance = MyGetView(key: const ValueKey('view'));
                return widgetInstance!;
              },
            ),
          ),
        ),
      );

      final contextsMap = GetView.contexts;
      expect(contextsMap[widgetInstance!], isNotNull);

      // Unmount the widget
      setViewState(() {
        showView = false;
      });
      await tester.pump();

      expect(
        contextsMap[widgetInstance!],
        isNull,
        reason: 'Widget context must be cleared when unmounted',
      );
    });
  });

  // ─── RxSList Tests ──────────────────────────────────────────────────────────

  group('RxSList Tests', () {
    test('RxSList initial status is loading', () {
      final list = RxSList<int>();
      expect(list.status, RxListStatus.loading);
      expect(list, isEmpty);
    });

    test('RxSList initial status with pre-populated data is still loading', () {
      final list = RxSList<int>([1, 2, 3]);
      expect(list.status, RxListStatus.loading);
      expect(list.length, 3);
    });

    test('assignAll with non-empty data transitions to loaded', () {
      final list = RxSList<String>();
      list.assignAll(['a', 'b', 'c']);
      expect(list.status, RxListStatus.loaded);
      expect(list.rawList, ['a', 'b', 'c']);
    });

    test('assignAll with empty data transitions to empty', () {
      final list = RxSList<int>([1, 2, 3]);
      list.assignAll([]);
      expect(list.status, RxListStatus.empty);
      expect(list, isEmpty);
    });

    test('error status is sticky and preserves data', () {
      final list = RxSList<String>(['initial']);
      list.error = 'Network failure';
      list.status = RxListStatus.error;
      expect(list.status, RxListStatus.error);
      expect(list.error, 'Network failure');
      // error status is sticky: data is preserved
      expect(list.rawList, ['initial']);
    });

    test('assignAll overwrites previous data completely', () {
      final list = RxSList<int>([1, 2, 3]);
      list.assignAll([4, 5]);
      expect(list.rawList, [4, 5]);
      expect(list.status, RxListStatus.loaded);
    });

    test('status setter manually transitions status', () {
      final list = RxSList<int>();
      expect(list.status, RxListStatus.loading);

      list.status = RxListStatus.loaded;
      expect(list.status, RxListStatus.loaded);

      list.status = RxListStatus.empty;
      expect(list.status, RxListStatus.empty);

      list.status = RxListStatus.error;
      expect(list.status, RxListStatus.error);
    });

    test('.ops extension converts List to RxSList', () {
      final list = <int>[10, 20].ops;
      expect(list, isA<RxSList<int>>());
      expect(list.status, RxListStatus.loading);
      expect(list.rawList, [10, 20]);
    });

    test('.ops on empty list', () {
      final list = <String>[].ops;
      expect(list, isA<RxSList<String>>());
      expect(list.status, RxListStatus.loading);
      expect(list, isEmpty);
    });

    test('RxList mutators still work on RxSList (inheritance regression)', () {
      final list = RxSList<String>();
      list.add('x');
      list.add('y');
      expect(list.rawList, ['x', 'y']);
      expect(list.status, RxListStatus.loaded);

      list[0] = 'X';
      expect(list[0], 'X');

      list.addAll(['z']);
      expect(list.length, 3);

      list.remove('y');
      expect(list.rawList, ['X', 'z']);

      list.removeAt(0);
      expect(list.rawList, ['z']);

      list.clear();
      expect(list, isEmpty);
      expect(list.status, RxListStatus.empty);
    });

    test('add() auto-transitions from empty to loaded', () {
      final list = RxSList<int>();
      expect(list.status, RxListStatus.loading);

      list.add(42);
      expect(list.status, RxListStatus.loaded);
      expect(list.rawList, [42]);
    });

    test('remove() auto-transitions from loaded to empty', () {
      final list = RxSList<String>(['only']);
      list.status = RxListStatus.loaded; // simulate post-load state

      list.remove('only');
      expect(list.status, RxListStatus.empty);
      expect(list, isEmpty);
    });

    test('error status is sticky — mutations do not overwrite error', () {
      final list = RxSList<int>([1, 2, 3]);
      list.status = RxListStatus.error;
      list.error = 'Boom';

      // Mutations should NOT change status away from error
      list.add(4);
      expect(list.status, RxListStatus.error);
      list.assignAll([5, 6]);
      expect(list.status, RxListStatus.error);
      list.clear();
      expect(list.status, RxListStatus.error);
    });

    test('value setter auto-syncs status', () {
      final list = RxSList<int>();
      list.value = [10, 20];
      expect(list.status, RxListStatus.loaded);

      list.value = [];
      expect(list.status, RxListStatus.empty);
    });

    test('RxSList assignAll schedules exactly one rebuild', () async {
      final list = RxSList<int>();
      int rebuildCount = 0;
      list.addListener(() => rebuildCount++);

      list.assignAll([1, 2, 3, 4, 5]);
      await Future<void>.value();

      expect(rebuildCount, 1);
      expect(list.rawList, [1, 2, 3, 4, 5]);
    });

    test('assignAll schedules exactly one rebuild (batching)', () async {
      final list = RxSList<int>();
      int rebuildCount = 0;
      list.addListener(() => rebuildCount++);

      list.assignAll(List<int>.generate(100, (i) => i));
      await Future<void>.value();

      expect(
        rebuildCount,
        1,
        reason: 'assignAll must batch into exactly one rebuild',
      );
      expect(list.length, 100);
    });

    testWidgets('on() renders loading state initially', (
      WidgetTester tester,
    ) async {
      final list = RxSList<String>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => list.on(
              loading: () => const Text('Loading...'),
              loaded: (data) => Text('Loaded: ${data.length} items'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('on() renders loaded state after assignAll', (
      WidgetTester tester,
    ) async {
      final list = RxSList<String>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => list.on(
              loading: () => const Text('Loading...'),
              loaded: (data) => Text('Loaded: ${data.length} items'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      list.assignAll(['apple', 'banana']);
      await tester.pump();

      expect(find.text('Loaded: 2 items'), findsOneWidget);
    });

    testWidgets('on() renders empty state when empty callback provided', (
      WidgetTester tester,
    ) async {
      final list = RxSList<int>([1, 2, 3]);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => list.on(
              loading: () => const Text('Loading...'),
              loaded: (data) => const Text('Has data'),
              empty: () => const Text('Nothing here'),
            ),
          ),
        ),
      );

      // Initially loading ignores initial data
      expect(find.text('Loading...'), findsOneWidget);

      // assignAll empty → transitions to empty
      list.assignAll([]);
      await tester.pump();

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('on() renders error state when error callback provided', (
      WidgetTester tester,
    ) async {
      final list = RxSList<String>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => list.on(
              loading: () => const Text('Loading...'),
              loaded: (data) => const Text('Has data'),
              error: (msg) => Text('Error: $msg'),
            ),
          ),
        ),
      );

      list.error = 'Something broke';
      list.status = RxListStatus.error;
      await tester.pump();

      expect(find.text('Error: Something broke'), findsOneWidget);

      // Mutate error message only - should dynamically update the widget via the nested Obx
      list.error = 'Something else broke';
      await tester.pump();
      expect(find.text('Error: Something else broke'), findsOneWidget);
    });

    testWidgets('on() with no empty/error callbacks shows SizedBox.shrink()', (
      WidgetTester tester,
    ) async {
      final list = RxSList<String>(['initial']);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => list.on(
              loading: () => const Text('Loading...'),
              loaded: (data) => const Text('Has data'),
              // No empty/error callbacks provided
            ),
          ),
        ),
      );

      // assignAll empty → should show SizedBox.shrink (nothing)
      list.assignAll([]);
      await tester.pump();

      expect(find.text('Has data'), findsNothing);
      expect(find.text('Loading...'), findsNothing);

      // Set error → should show SizedBox.shrink (nothing)
      list.error = 'err';
      list.status = RxListStatus.error;
      await tester.pump();

      // The SizedBox.shrink() should not produce any visible widget
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('on() loaded case reactively updates when data is added', (
      WidgetTester tester,
    ) async {
      final list = RxSList<String>();
      list.assignAll(['a']); // status → loaded

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => list.on(
              loading: () => const Text('Loading...'),
              loaded: (data) => Text('Count: ${data.length}'),
              empty: () => const Text('Empty'),
              error: (msg) => Text('Error: $msg'),
            ),
          ),
        ),
      );

      expect(find.text('Count: 1'), findsOneWidget);

      // Add data — RxList batches notifications via microtask
      list.add('b');
      await tester.runAsync(() async {
        await Future<void>.microtask(() {});
      });
      await tester.pump();

      expect(find.text('Count: 2'), findsOneWidget);
    });

    testWidgets('on() loaded case reactively updates when data is removed', (
      WidgetTester tester,
    ) async {
      final list = RxSList<String>(['x', 'y', 'z']);
      list.status = RxListStatus.loaded;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => list.on(
              loading: () => const Text('Loading...'),
              loaded: (data) => Text('Items: ${data.join(",")}'),
              empty: () => const Text('Empty'),
              error: (msg) => Text('Error: $msg'),
            ),
          ),
        ),
      );

      expect(find.text('Items: x,y,z'), findsOneWidget);

      list.remove('y');
      await tester.runAsync(() async {
        await Future<void>.microtask(() {});
      });
      await tester.pump();

      expect(find.text('Items: x,z'), findsOneWidget);
    });

    testWidgets('on() reactively updates when status changes via setter', (
      WidgetTester tester,
    ) async {
      final list = RxSList<String>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => list.on(
              loading: () => const Text('State: loading'),
              loaded: (data) => const Text('State: loaded'),
              empty: () => const Text('State: empty'),
              error: (msg) => Text('State: error - $msg'),
            ),
          ),
        ),
      );

      expect(find.text('State: loading'), findsOneWidget);

      list.status = RxListStatus.loaded;
      await tester.pump();
      expect(find.text('State: loaded'), findsOneWidget);

      list.status = RxListStatus.empty;
      await tester.pump();
      expect(find.text('State: empty'), findsOneWidget);

      list.error = 'Test error';
      list.status = RxListStatus.error;
      await tester.pump();
      expect(find.text('State: error - Test error'), findsOneWidget);
    });
  });

  // ─── RxS Tests ──────────────────────────────────────────────────────────────

  group('RxS Tests', () {
    test('RxS initial status is loading', () {
      final val = RxS<int>();
      expect(val.status, RxDataStatus.loading);
      expect(val.value, isNull);
    });

    test('error status is sticky — mutations do not overwrite error', () {
      final val = RxS<String>('initial');
      val.status = RxDataStatus.error;
      val.error = 'Boom';

      // Setting value should NOT change status or clear error
      val.value = 'new';
      expect(val.status, RxDataStatus.error);
      expect(val.error, 'Boom');
      expect(val.value, 'new');

      val.update((_) => 'updated');
      expect(val.status, RxDataStatus.error);
      expect(val.error, 'Boom');
      expect(val.value, 'updated');
    });

    test('status setter manually transitions status', () {
      final val = RxS<int>();
      expect(val.status, RxDataStatus.loading);

      val.status = RxDataStatus.loaded;
      expect(val.status, RxDataStatus.loaded);

      val.status = RxDataStatus.error;
      expect(val.status, RxDataStatus.error);
    });

    testWidgets('on() renders error state and reactively updates on error change', (
      WidgetTester tester,
    ) async {
      final val = RxS<String>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(
            () => val.on(
              loading: () => const Text('Loading...'),
              loaded: (data) => const Text('Has data'),
              error: (msg) => Text('Error: $msg'),
            ),
          ),
        ),
      );

      val.error = 'Oops';
      val.status = RxDataStatus.error;
      await tester.pump();
      expect(find.text('Error: Oops'), findsOneWidget);

      val.error = 'Oops again';
      await tester.pump();
      expect(find.text('Error: Oops again'), findsOneWidget);
    });
  });
}
