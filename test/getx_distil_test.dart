import 'package:flutter/widgets.dart';
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

void main() {
  test('Rx Core Getter, Setter & Callable features', () {
    final count = 10.obs;
    expect(count.value, 10);

    // Test callable setter/getter
    count(20);
    expect(count(), 20);
    expect(count.value, 20);

    // Operator and primitive type checks
    final text = 'hello'.obs;
    expect(text.value, 'hello');
    expect(text(), 'hello');

    final flag = true.obs;
    expect(flag.isTrue, true);
    flag.toggle();
    expect(flag.isFalse, true);
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

  testWidgets('Scoped DI and isolated multi-instances test', (WidgetTester tester) async {
    // Nested view scopes with duplicate bindings
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BindingWidget(
          bindings: [
            Bind<CounterController>(() => CounterController()),
          ],
          child: Builder(
            builder: (context1) {
              final outer = Get.find<CounterController>(context1);
              outer.count.value = 10;

              return BindingWidget(
                bindings: [
                  Bind<CounterController>(() => CounterController()),
                ],
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

  testWidgets('GetxController lifecycle hooks and automatic onClose on dispose', (WidgetTester tester) async {
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
              bindings: [
                Bind<LifecycleController>(() => lifecycleController),
              ],
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
    final w3 = debounce(count, (val) => debounceValues.add(val), time: const Duration(milliseconds: 50));

    // First change
    count.value = 1;
    await Future.delayed(const Duration(milliseconds: 10));

    // Second change
    count.value = 2;
    await Future.delayed(const Duration(milliseconds: 10));

    // Third change
    count.value = 3;
    await Future.delayed(const Duration(milliseconds: 100)); // Allow debounce to fire after silence

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
}
