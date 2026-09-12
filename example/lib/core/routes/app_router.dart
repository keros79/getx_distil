import 'package:go_router/go_router.dart';
import 'package:getx_distil/get.dart';

import '../../models/domain/user_repository.dart';
import '../../views/basic_rx/basic_rx_controller.dart';
import '../../views/basic_rx/basic_rx_page.dart';
import '../../views/concurrent/concurrent_controller.dart';
import '../../views/concurrent/concurrent_page.dart';
import '../../views/extra_settings/extra_settings_controller.dart';
import '../../views/extra_settings/extra_settings_page.dart';
import '../../views/home/test_list_controller.dart';
import '../../views/home/test_list_page.dart';
import '../../views/nested_scope/nested_scope_controller.dart';
import '../../views/nested_scope/nested_scope_page.dart';
import '../../views/rx_s/rx_s_controller.dart';
import '../../views/rx_s/rx_s_page.dart';
import '../../views/rx_slist/rx_slist_controller.dart';
import '../../views/rx_slist/rx_slist_page.dart';
import '../../views/rx_slist_paging/rx_slist_paging_controller.dart';
import '../../views/rx_slist_paging/rx_slist_paging_page.dart';
import '../../views/safety/safety_controller.dart';
import '../../views/safety/safety_page.dart';
import '../../views/tdd_test/tdd_test_controller.dart';
import '../../views/tdd_test/tdd_test_page.dart';

/// Single source of truth for GoRouter + per-screen [BindingWidget] scopes.
///
/// App-lifetime services stay in `GetMaterialApp.bindings`; every screen owns
/// its controller through a `BindingWidget` declared here.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 1. Hub Start Page
    GoRoute(
      path: '/',
      builder: (context, state) => BindingWidget(
        bindings: [Bind<TestListController>(() => TestListController())],
        child: const TestListPage(),
      ),
    ),

    // 2. Course 1: Basic Rx & Actions
    GoRoute(
      path: '/basic-rx',
      builder: (context, state) => BindingWidget(
        bindings: [Bind<BasicRxController>(() => BasicRxController())],
        child: const BasicRxPage(),
      ),
    ),

    // 3. Course 2: Scoped DI Stack (dynamic nested push with query param)
    GoRoute(
      path: '/nested-scope',
      builder: (context, state) {
        final depthStr = state.uri.queryParameters['depth'] ?? '1';
        final depth = int.tryParse(depthStr) ?? 1;
        return BindingWidget(
          bindings: [
            Bind<NestedScopeController>(
              () => NestedScopeController(depth: depth),
            ),
          ],
          child: const NestedScopePage(),
        );
      },
    ),

    // 4. Course 3: Safety Guard Simulation
    GoRoute(
      path: '/safety',
      builder: (context, state) => BindingWidget(
        bindings: [Bind<SafetyController>(() => SafetyController())],
        child: const SafetyPage(),
      ),
    ),

    // 5. Course 4: High-Frequency FIFO Queue & RxList Benchmark
    GoRoute(
      path: '/concurrent',
      builder: (context, state) => BindingWidget(
        bindings: [Bind<ConcurrentController>(() => ConcurrentController())],
        child: const ConcurrentPage(),
      ),
    ),

    // 6. RxSList Basic Demo Page
    GoRoute(
      path: '/rx-slist',
      builder: (context, state) => BindingWidget(
        bindings: [Bind<RxSListController>(() => RxSListController())],
        child: const RxSListPage(),
      ),
    ),

    // 7. RxSList Paging Demo Page
    GoRoute(
      path: '/rx-slist-paging',
      builder: (context, state) => BindingWidget(
        bindings: [
          Bind<RxSListPagingController>(() => RxSListPagingController()),
        ],
        child: const RxSListPagingPage(),
      ),
    ),

    // 8. RxS Demo Page
    GoRoute(
      path: '/rx-s',
      builder: (context, state) => BindingWidget(
        bindings: [Bind<RxSController>(() => RxSController())],
        child: const RxSPage(),
      ),
    ),

    // 9. Settings Page
    GoRoute(
      path: '/settings',
      builder: (context, state) => BindingWidget(
        bindings: [
          Bind<ExtraSettingsController>(() => ExtraSettingsController()),
        ],
        child: const ExtraSettingsPage(),
      ),
    ),

    // 10. TDD Test Page
    GoRoute(
      path: '/tdd-test',
      builder: (context, state) => BindingWidget(
        bindings: [
          Bind<TddTestController>(
            () => TddTestController(repository: Get.find<UserRepository>()),
          ),
        ],
        child: const TddTestPage(),
      ),
    ),
  ],
);
