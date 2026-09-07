import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_distil/get.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

class ImperativeController extends GetxController {
  int count = 0;
  int badge = 0;
}

class LifecycleController extends GetxController {
  static int created = 0;
  bool closed = false;

  LifecycleController() {
    created++;
  }

  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

class ScopedController extends GetxController {
  final String name;
  ScopedController(this.name);
}

void main() {
  setUp(() {
    Get.reset();
    BindingWidgetState.resetAmbiguityWarnings();
    LifecycleController.created = 0;
  });

  // ─── 1. update(ids) + GetBuilder ───────────────────────────────────────────

  group('GetxController.update(ids) & GetBuilder', () {
    test('update() notifies global listeners only, update([id]) only that id',
        () {
      final c = ImperativeController();
      var global = 0, badge = 0, other = 0;
      c.addListener(() => global++);
      c.addListenerId('badge', () => badge++);
      c.addListenerId('other', () => other++);

      c.update();
      expect([global, badge, other], [1, 0, 0]);

      c.update(['badge']);
      expect([global, badge, other], [1, 1, 0]);

      c.update(['badge', 'other']);
      expect([global, badge, other], [1, 2, 1]);

      c.update(['badge'], false); // condition false → no-op
      expect([global, badge, other], [1, 2, 1]);

      c.disposeId('badge');
      c.update(['badge']);
      expect(badge, 2);
    });

    testWidgets('GetBuilder rebuilds on update() and respects ids',
        (tester) async {
      final c = Get.put(ImperativeController());
      var globalBuilds = 0, badgeBuilds = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              GetBuilder<ImperativeController>(
                builder: (ctrl) {
                  globalBuilds++;
                  return Text('count:${ctrl.count}');
                },
              ),
              GetBuilder<ImperativeController>(
                id: 'badge',
                builder: (ctrl) {
                  badgeBuilds++;
                  return Text('badge:${ctrl.badge}');
                },
              ),
            ],
          ),
        ),
      );
      expect([globalBuilds, badgeBuilds], [1, 1]);

      c.count = 5;
      c.update();
      await tester.pump();
      expect(find.text('count:5'), findsOneWidget);
      expect([globalBuilds, badgeBuilds], [2, 1]);

      c.badge = 9;
      c.update(['badge']);
      await tester.pump();
      expect(find.text('badge:9'), findsOneWidget);
      expect([globalBuilds, badgeBuilds], [2, 2]);
    });

    testWidgets('GetBuilder(init:) registers globally and autoRemoves',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GetBuilder<LifecycleController>(
            init: LifecycleController(),
            builder: (_) => const Text('ok'),
          ),
        ),
      );
      expect(Get.isRegistered<LifecycleController>(), isTrue);
      final ctrl = Get.find<LifecycleController>();
      expect(ctrl.initialized, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(Get.isRegistered<LifecycleController>(), isFalse);
      expect(ctrl.closed, isTrue);
    });

    testWidgets('GetBuilder(global: false) owns the controller lifecycle',
        (tester) async {
      final local = LifecycleController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GetBuilder<LifecycleController>(
            global: false,
            init: local,
            builder: (_) => const Text('ok'),
          ),
        ),
      );
      expect(local.initialized, isTrue);
      expect(Get.isRegistered<LifecycleController>(), isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(local.closed, isTrue);
    });

    testWidgets('GetBuilder resolves controllers from a BindingWidget scope',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindingWidget(
            bindings: [Bind<ScopedController>(() => ScopedController('scoped'))],
            child: GetBuilder<ScopedController>(
              builder: (c) => Text(c.name),
            ),
          ),
        ),
      );
      expect(find.text('scoped'), findsOneWidget);
    });
  });

  // ─── 2. RxMap / RxSet / Workers / bindStream ──────────────────────────────

  group('RxMap', () {
    test('.obs on Map returns RxMap and batches writes into one refresh',
        () async {
      final m = <String, int>{}.obs;
      expect(m, isA<RxMap<String, int>>());
      var refreshes = 0;
      m.addListener(() => refreshes++);

      m['a'] = 1;
      m['b'] = 2;
      m.addAll({'c': 3, 'd': 4});
      m.remove('a');
      expect(refreshes, 0); // nothing yet: microtask pending
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 1);
      expect(m.rawMap, {'b': 2, 'c': 3, 'd': 4});
      expect(m.length, 3);
      expect(m.containsKey('b'), isTrue);
    });

    test('no-op mutations do not notify', () async {
      final m = RxMap<String, int>({'a': 1});
      var refreshes = 0;
      m.addListener(() => refreshes++);
      m.remove('zzz');
      m.addAll({});
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 0);
      m.clear();
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 1);
      m.clear(); // already empty
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 1);
    });

    testWidgets('Obx rebuilds when an RxMap entry changes', (tester) async {
      final m = <String, bool>{'dark': false}.obs;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() => Text('dark:${m['dark']}')),
        ),
      );
      expect(find.text('dark:false'), findsOneWidget);
      m['dark'] = true;
      // Drain the batching microtask, then pump the frame.
      await tester.runAsync(() => Future<void>.microtask(() {}));
      await tester.pump();
      expect(find.text('dark:true'), findsOneWidget);
    });

    test('ever worker receives RxMap snapshots', () async {
      final m = <String, int>{}.obs;
      final events = <Map<String, int>>[];
      final w = ever<Map<String, int>>(m, (v) => events.add(Map.of(v)));
      m['x'] = 1;
      await Future<void>.delayed(Duration.zero);
      expect(events, [
        {'x': 1}
      ]);
      w.dispose();
    });
  });

  group('RxSet', () {
    test('.obs on Set returns RxSet and batches writes', () async {
      final s = <int>{}.obs;
      expect(s, isA<RxSet<int>>());
      var refreshes = 0;
      s.addListener(() => refreshes++);

      expect(s.add(1), isTrue);
      expect(s.add(1), isFalse); // duplicate
      s.addAll([2, 3]);
      expect(s.remove(99), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 1);
      expect(s.rawSet, {1, 2, 3});
      expect(s.contains(2), isTrue);
      expect(s.length, 3);
    });

    test('duplicate add / missing remove never notify', () async {
      final s = RxSet<int>({1});
      var refreshes = 0;
      s.addListener(() => refreshes++);
      s.add(1);
      s.remove(2);
      s.addAll([1]);
      await Future<void>.delayed(Duration.zero);
      expect(refreshes, 0);
    });

    testWidgets('Obx rebuilds when an RxSet changes', (tester) async {
      final s = <int>{}.obs;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() => Text('has3:${s.contains(3)}')),
        ),
      );
      expect(find.text('has3:false'), findsOneWidget);
      s.add(3);
      // Drain the batching microtask, then pump the frame.
      await tester.runAsync(() => Future<void>.microtask(() {}));
      await tester.pump();
      expect(find.text('has3:true'), findsOneWidget);
    });
  });

  group('Workers: interval / everAll / bindStream', () {
    test('interval fires at most once per window with the first value',
        () async {
      final rx = 0.obs;
      final received = <int>[];
      final w = interval<int>(rx, received.add,
          time: const Duration(milliseconds: 60));

      rx.value = 1;
      rx.value = 2;
      rx.value = 3;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(received, isEmpty); // window still open
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(received, [1]); // first value of the window, later ones dropped

      rx.value = 4;
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(received, [1, 4]);

      w.dispose();
      rx.value = 5;
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(received, [1, 4]);
    });

    test('everAll fires for any of the listened observables', () async {
      final a = 0.obs;
      final b = 'x'.obs;
      final events = <dynamic>[];
      final w = everAll([a, b], events.add);
      a.value = 1;
      b.value = 'y';
      await Future<void>.delayed(Duration.zero);
      expect(events, [1, 'y']);
      w.dispose();
      a.value = 2;
      await Future<void>.delayed(Duration.zero);
      expect(events, [1, 'y']);
    });

    test('bindStream drives value and is cancelled on close', () async {
      final rx = 0.obs;
      final controller = StreamController<int>();
      rx.bindStream(controller.stream);

      controller.add(7);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 7);

      rx.close();
      controller.add(8);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 7);
      await controller.close();
    });

    test('bindStream works on RxList (value setter override)', () async {
      final list = <int>[].obs;
      final controller = StreamController<List<int>>();
      list.bindStream(controller.stream);
      controller.add([1, 2]);
      await Future<void>.delayed(Duration.zero);
      expect(list.rawList, [1, 2]);
      list.unbindStreams();
      controller.add([3]);
      await Future<void>.delayed(Duration.zero);
      expect(list.rawList, [1, 2]);
      await controller.close();
    });
  });

  // ─── 3. updateSequential error propagation ────────────────────────────────

  group('Rx.updateSequential error handling', () {
    test('error propagates to the awaiting caller and does not stall the queue',
        () async {
      final rx = 0.obs;
      final failing = rx.updateSequential((_) async => throw StateError('boom'));
      await expectLater(failing, throwsA(isA<StateError>()));

      await rx.updateSequential((v) async => v + 1);
      expect(rx.value, 1);
    });

    test('onError callback swallows the error and the future completes',
        () async {
      final rx = 0.obs;
      Object? captured;
      await rx.updateSequential(
        (_) async => throw ArgumentError('bad'),
        onError: (e, _) => captured = e,
      );
      expect(captured, isA<ArgumentError>());
      expect(rx.value, 0);
    });

    test('attached ever worker observes the error via onError', () async {
      final rx = 0.obs;
      Object? seen;
      final w = ever<int>(rx, (_) {}, onError: (Object e) => seen = e);
      await rx.updateSequential(
        (_) async => throw StateError('stream-visible'),
        onError: (_, _) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen, isA<StateError>());
      w.dispose();
    });
  });

  // ─── 4. lazyPut(fenix: true) ───────────────────────────────────────────────

  group('Get.lazyPut fenix', () {
    test('fenix dependency is rebuilt after delete', () {
      Get.lazyPut<LifecycleController>(() => LifecycleController(),
          fenix: true);
      expect(Get.isPrepared<LifecycleController>(), isTrue);

      final first = Get.find<LifecycleController>();
      expect(LifecycleController.created, 1);
      expect(Get.isPrepared<LifecycleController>(), isFalse);

      expect(Get.delete<LifecycleController>(), isTrue);
      expect(first.closed, isTrue);
      expect(Get.isRegistered<LifecycleController>(), isTrue);
      expect(Get.isPrepared<LifecycleController>(), isTrue);

      final second = Get.find<LifecycleController>();
      expect(LifecycleController.created, 2);
      expect(identical(first, second), isFalse);
    });

    test('non-fenix lazyPut is removed on delete', () {
      Get.lazyPut<LifecycleController>(() => LifecycleController());
      Get.find<LifecycleController>();
      Get.delete<LifecycleController>();
      expect(Get.isRegistered<LifecycleController>(), isFalse);
    });

    test('reset(clearFactory: false) keeps builders, reset() drops them', () {
      Get.lazyPut<LifecycleController>(() => LifecycleController());
      final c = Get.find<LifecycleController>();
      Get.reset(clearFactory: false);
      expect(c.closed, isTrue);
      expect(Get.isPrepared<LifecycleController>(), isTrue);
      Get.reset();
      expect(Get.isRegistered<LifecycleController>(), isFalse);
    });

    test('put replaces a pending lazy factory instead of calling it', () {
      Get.lazyPut<ScopedController>(() => ScopedController('from-factory'));
      final put = Get.put(ScopedController('from-put'));
      expect(put.name, 'from-put');
      expect(Get.find<ScopedController>().name, 'from-put');
    });
  });

  // ─── 5/6. Tagged Bind, tag-aware tree lookup, ambiguity ──────────────────

  group('Scoped DI stays tag-free; Get.find(tag:) is global-only', () {
    testWidgets(
        'a tagged lookup skips the widget tree and resolves from the global registry',
        (tester) async {
      var scopedCreated = 0;
      Get.put(ScopedController('global-tagged'), tag: 'x');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindingWidget(
            bindings: [
              Bind<ScopedController>(() {
                scopedCreated++;
                return ScopedController('scoped');
              }),
            ],
            child: Builder(
              builder: (context) {
                final scoped = Get.find<ScopedController>(context: context);
                final tagged =
                    Get.find<ScopedController>(context: context, tag: 'x');
                return Text('${scoped.name}/${tagged.name}');
              },
            ),
          ),
        ),
      );
      expect(find.text('scoped/global-tagged'), findsOneWidget);
      expect(scopedCreated, 1);

      // A tag that only exists as a scoped type must NOT fall back to the scope.
      expect(() => Get.find<ScopedController>(tag: 'missing'),
          throwsA(isA<FlutterError>()));
    });

    test('Get.find(tag:) resolves global tagged registrations (GetX style)',
        () {
      Get.put(ScopedController('a'), tag: 'A');
      Get.put(ScopedController('b'), tag: 'B');
      expect(Get.find<ScopedController>(tag: 'A').name, 'a');
      expect(Get.find<ScopedController>(tag: 'B').name, 'b');
      expect(() => Get.find<ScopedController>(tag: 'C'),
          throwsA(isA<FlutterError>()));
    });

    testWidgets(
        'context-less find does not instantiate bindings in other scopes when a live instance exists',
        (tester) async {
      var outerCreated = 0, innerCreated = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindingWidget(
            bindings: [
              Bind<ScopedController>(() {
                outerCreated++;
                return ScopedController('outer');
              }),
            ],
            child: BindingWidget(
              bindings: [
                Bind<ScopedController>(() {
                  innerCreated++;
                  return ScopedController('inner');
                }),
              ],
              child: Builder(
                builder: (context) =>
                    Text(Get.find<ScopedController>(context: context).name),
              ),
            ),
          ),
        ),
      );
      expect(find.text('inner'), findsOneWidget);
      expect([outerCreated, innerCreated], [0, 1]);

      // Live instance wins; the outer scope must NOT be instantiated.
      expect(Get.find<ScopedController>().name, 'inner');
      expect(outerCreated, 0);
      expect(BindingWidgetState.liveInstanceCount<ScopedController>(), 1);
    });

    testWidgets(
        'ambiguous live instances resolve to the most recent one (deterministic)',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              BindingWidget(
                bindings: [
                  Bind<ScopedController>(() => ScopedController('first'))
                ],
                child: Builder(
                  builder: (context) =>
                      Text(Get.find<ScopedController>(context: context).name),
                ),
              ),
              BindingWidget(
                bindings: [
                  Bind<ScopedController>(() => ScopedController('second'))
                ],
                child: Builder(
                  builder: (context) =>
                      Text(Get.find<ScopedController>(context: context).name),
                ),
              ),
            ],
          ),
        ),
      );
      expect(BindingWidgetState.liveInstanceCount<ScopedController>(), 2);
      expect(Get.find<ScopedController>().name, 'second');
    });
  });

  // ─── 7. Initial data → loaded ─────────────────────────────────────────────

  group('RxS / RxSList initial status', () {
    test('RxS with initial value starts loaded, without starts idle', () {
      expect(RxS<int>(1).status, RxDataStatus.loaded);
      expect(RxS<int>().status, RxDataStatus.idle);
      expect(RxS<int>(null).status, RxDataStatus.idle);
      expect('hello'.ops.status, RxDataStatus.loaded);
    });

    test('RxSList with seeded data starts loaded, empty seed stays idle', () {
      expect(RxSList<int>([1]).status, RxListStatus.loaded);
      expect(RxSList<int>([]).status, RxListStatus.idle);
      expect(RxSList<int>().status, RxListStatus.idle);
      expect([1, 2].ops.status, RxListStatus.loaded);
      expect(<int>[].ops.status, RxListStatus.idle);
    });

    testWidgets('seeded RxS renders the loaded branch immediately',
        (tester) async {
      final user = 'Alice'.ops;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() => user.on(
                idle: () => const Text('idle'),
                loading: () => const Text('loading'),
                loaded: (v) => Text('hi $v'),
              )),
        ),
      );
      expect(find.text('hi Alice'), findsOneWidget);
    });
  });

  // ─── RxS.load / RxSList.load / loadMore ────────────────────────────────────

  group('RxS.load & RxSList.load', () {
    test('RxS.load drives idle → loading → loaded', () async {
      final user = RxS<String?>(null);
      expect(user.status, RxDataStatus.idle);

      final completer = Completer<String?>();
      final future = user.load(() => completer.future);
      expect(user.status, RxDataStatus.loading);

      completer.complete('Alice');
      await future;
      expect(user.status, RxDataStatus.loaded);
      expect(user.value, 'Alice');
      expect(user.error, isNull);
    });

    test('RxS.load captures errors into status and preserves the old value',
        () async {
      final user = RxS<String?>('Alice');
      await user.load(() async => throw StateError('offline'));
      expect(user.status, RxDataStatus.error);
      expect(user.error, contains('offline'));
      expect(user.value, 'Alice'); // previous value kept

      await user.load(
        () async => throw Exception('x'),
        errorMessage: (_) => 'friendly',
      );
      expect(user.error, 'friendly');
    });

    test('RxS.load: a slower earlier call never overwrites a newer result',
        () async {
      final user = RxS<String?>(null);
      final slow = Completer<String?>();
      final fast = Completer<String?>();

      final f1 = user.load(() => slow.future);
      final f2 = user.load(() => fast.future);

      fast.complete('fast');
      await f2;
      expect(user.value, 'fast');

      slow.complete('slow');
      await f1;
      expect(user.value, 'fast'); // stale result discarded
      expect(user.status, RxDataStatus.loaded);
    });

    test('RxS.load forwards errors to ever(onError:) workers', () async {
      final user = RxS<String?>(null);
      Object? seen;
      final worker = ever<String?>(user, (_) {}, onError: (e) => seen = e);

      await user.load(() async => throw StateError('boom'));
      await Future<void>.delayed(Duration.zero);
      expect(seen, isA<StateError>());
      worker.dispose();
    });

    test('RxSList.load drives idle → loading → loaded / empty', () async {
      final items = <int>[].ops;
      final completer = Completer<List<int>>();
      final future = items.load(() => completer.future);
      expect(items.status, RxListStatus.loading);

      completer.complete([1, 2, 3]);
      await future;
      expect(items.status, RxListStatus.loaded);
      expect(items.rawList, [1, 2, 3]);

      await items.load(() async => <int>[]);
      expect(items.status, RxListStatus.empty);
    });

    test('RxSList.load captures errors and keeps existing items', () async {
      final items = [1, 2].ops;
      await items.load(() async => throw 'network');
      expect(items.status, RxListStatus.error);
      expect(items.error, 'network');
      expect(items.rawList, [1, 2]);
    });

    test('RxSList.loadMore appends pages and tracks hasMore', () async {
      final items = <int>[].ops;
      await items.load(() async => [1, 2]);
      expect(items.hasMore, isTrue);

      await items.loadMore(() async => [3, 4]);
      expect(items.rawList, [1, 2, 3, 4]);
      expect(items.status, RxListStatus.loaded);
      expect(items.hasMore, isTrue);

      await items.loadMore(() async => <int>[]); // last page
      expect(items.hasMore, isFalse);
      expect(items.rawList, [1, 2, 3, 4]);

      var called = false;
      await items.loadMore(() async {
        called = true;
        return [5];
      });
      expect(called, isFalse); // no-op once hasMore == false
    });

    test('RxSList.loadMore never flashes loading and reports errors',
        () async {
      final items = [1].ops;
      final statuses = <RxListStatus>[];
      final worker = ever<List<int>>(items, (_) => statuses.add(items.status));

      await items.loadMore(() async => throw 'page failed');
      expect(statuses, isNot(contains(RxListStatus.loading)));
      expect(items.status, RxListStatus.error);
      expect(items.rawList, [1]);
      worker.dispose();
    });
  });
}
