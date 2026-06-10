import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:getx_distil/get.dart';

import 'src/config/app_config.dart';

// Import New Controllers and Views
import 'src/views/test_list_page.dart';
import 'src/views/basic_rx_controller.dart';
import 'src/views/basic_rx_page.dart';
import 'src/views/nested_scope_controller.dart';
import 'src/views/nested_scope_page.dart';
import 'src/views/self_healing_safety_controller.dart';
import 'src/views/self_healing_safety_page.dart';
import 'src/views/concurrent_update_controller.dart';
import 'src/views/concurrent_update_page.dart';
import 'src/views/extra_settings_page.dart';
import 'src/views/rx_slist_controller.dart';
import 'src/views/rx_slist_page.dart';
import 'src/views/rx_slist_paging_controller.dart';
import 'src/views/rx_slist_paging_page.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      // 1. Hub Start Page
      'test_list_title': 'Distil Test Bench',
      'test_list_subtitle':
          'Explore lightweight reactive features and safety mechanisms',
      'test_list_basic_rx_title': '1. Basic Rx & Actions',
      'test_list_basic_rx_desc':
          'Observe simple reactive state and debounced triggers',
      'test_list_scoped_di_title': '2. Nested Controller Scope',
      'test_list_scoped_di_desc':
          'Continuous page push test ensuring fully isolated controller instances per tree depth',
      'test_list_safety_title': '3. Engine Safety Guard',
      'test_list_safety_desc':
          'Build phase crash prevention and async Obx checks',
      'test_list_pipeline_title': '4. Pipeline & Performance',
      'test_list_pipeline_desc':
          'updateSequential FIFO streams and RxList benchmarking',
      'test_list_settings_card_title': '5. Extra Settings',
      'test_list_settings_card_desc':
          'Configure application theme and localization preferences',
      'extra_settings_title': 'Extra Settings',

      // 2. Course 1: Basic Rx & Actions
      'basic_rx_appbar_title': 'Basic Rx & Actions',
      'basic_rx_counter_title': 'Point counter',
      'basic_rx_increment_btn': 'Increment Count',
      'basic_rx_obx_badge': 'Obx Rebuild',
      'basic_rx_search_hint': 'Type query (Debounced Search)...',
      'basic_rx_status_label': 'Status:',
      'basic_rx_status_idle': 'Idle',
      'basic_rx_status_searching': 'Searching...',
      'basic_rx_status_success': 'Success',
      'basic_rx_search_result': 'Result for "%s" (Processed at %s)',
      'basic_rx_list_title': 'Reactive RxList',
      'basic_rx_list_add_btn': 'Add Scoped Item',
      'basic_rx_list_empty': 'List is empty. Tap Add Item!',
      'basic_rx_list_item_prefix': 'Item #%s',

      // 3. Course 2: Scoped DI Stack
      'nested_scope_appbar_title': 'DI Stack Level: %s',
      'nested_scope_id_label': 'ID: @id',
      'nested_scope_depth_badge': 'Depth #%s',
      'nested_scope_increment_btn': 'Increment Count',
      'nested_scope_isolated_desc':
          'This counter value is completely isolated from other stack levels.',
      'nested_scope_push_btn': 'Push Next Stack',
      'nested_scope_pop_btn': 'Pop Current Stack (GC)',

      // 4. Course 3: Safety Guard
      'safety_appbar_title': 'Engine Safety Guard',
      'safety_healing_title': 'Self-Healing Layout Engine',
      'safety_healed_val_label': 'Healed Build Value',
      'safety_simulate_build_btn': 'Simulate Build Mutation',
      'safety_async_title': 'Strict Async Obx Verification',
      'safety_trigger_error_btn': 'Trigger async Obx Error',
      'safety_error_caught_label': 'Informative FlutterError Caught',

      // 5. Course 4: High-Frequency FIFO & RxList
      'concurrent_appbar_title': 'Pipeline & Performance',
      'concurrent_fifo_title': 'FIFO updateSequential',
      'concurrent_processing': 'Processing',
      'concurrent_idle': 'Idle',
      'concurrent_spam_btn': 'Spam Clicks!',
      'concurrent_bench_title': 'RxList Loop Benchmark',
      'concurrent_bench_items_badge': '10,000 items',
      'concurrent_standard_loop_btn': 'Standard Loop',
      'concurrent_rx_batch_btn': 'RxList Batch',
      'concurrent_standard_label': 'Standard Loop (1,000 items)',
      'concurrent_rx_label': 'RxList Batch (10,000 items)',

      // 6. Settings Page
      'settings_theme_title': 'Theme Mode',
      'settings_dark_active': 'Dark Mode Active',
      'settings_light_active': 'Light Mode Active',
      'settings_language_title': 'Language',
    },
    'ko_KR': {
      // 1. Hub Start Page
      'test_list_title': 'Distil 테스트 벤치',
      'test_list_subtitle': '경량 반응형 기능 및 엔진 안전장치를 탐색해 보세요',
      'test_list_basic_rx_title': '1. 기본 Rx 및 액션',
      'test_list_basic_rx_desc': '간단한 반응형 상태 및 디바운스 워커(Worker)를 실습합니다',
      'test_list_scoped_di_title': '2. 컨트롤러 중첩 격리 테스트',
      'test_list_scoped_di_desc':
          '동일 페이지를 연속 Push할 때 깊이별로 컨트롤러 인스턴스가 독립 격리 및 자동 수거되는 과정을 검증합니다',
      'test_list_safety_title': '3. 엔진 안전 가드',
      'test_list_safety_desc': '빌드 중 상태 수정 자가 치유와 비동기 Obx 방지 장치를 테스트합니다',
      'test_list_pipeline_title': '4. 파이프라인 및 성능 벤치마크',
      'test_list_pipeline_desc':
          'updateSequential FIFO 큐 보장 및 RxList 1만 건 대량 렌더링을 벤치마크합니다',
      'test_list_settings_card_title': '5. 기타 설정',
      'test_list_settings_card_desc': '화면 테마 및 다국어 등 기타 설정을 구성합니다',
      'extra_settings_title': '기타 설정',

      // 2. Course 1: Basic Rx & Actions
      'basic_rx_appbar_title': '기본 Rx 및 액션',
      'basic_rx_counter_title': '포인트 카운터',
      'basic_rx_increment_btn': '클릭수 증가',
      'basic_rx_obx_badge': 'Obx 리빌드',
      'basic_rx_search_hint': '검색어 입력 (디바운스 검색)...',
      'basic_rx_status_label': '진행 상태:',
      'basic_rx_status_idle': '대기 중',
      'basic_rx_status_searching': '검색 중...',
      'basic_rx_status_success': '검색 성공',
      'basic_rx_search_result': '"%s"에 대한 검색 결과 (%s에 처리됨)',
      'basic_rx_list_title': '반응형 RxList 실습',
      'basic_rx_list_add_btn': '아이템 추가',
      'basic_rx_list_empty': '리스트가 비어 있습니다. 아이템을 추가해 보세요!',
      'basic_rx_list_item_prefix': '아이템 #%s',

      // 3. Course 2: Scoped DI Stack
      'nested_scope_appbar_title': 'DI 스택 깊이: %s단계',
      'nested_scope_id_label': '식별 ID: @id',
      'nested_scope_depth_badge': '깊이 #%s',
      'nested_scope_increment_btn': '카운트 증가',
      'nested_scope_isolated_desc': '이 카운터 값은 다른 스택 단계들과 완벽하게 격리되어 개별 보존됩니다.',
      'nested_scope_push_btn': '다음 스택 페이지 Push',
      'nested_scope_pop_btn': '현재 스택 페이지 Pop (자동 수거)',

      // 4. Course 3: Safety Guard
      'safety_appbar_title': '엔진 안전 가드',
      'safety_healing_title': '빌드 단계 자가 치유 엔진',
      'safety_healed_val_label': '치유된 빌드 상태 값',
      'safety_simulate_build_btn': '빌드 도중 상태 변조 유발',
      'safety_async_title': '엄격한 비동기 Obx 검증',
      'safety_trigger_error_btn': '비동기 Obx 에러 고의 유발',
      'safety_error_caught_label': '안전하게 포착된 개발자용 상세 에러',

      // 5. Course 4: High-Frequency FIFO & RxList
      'concurrent_appbar_title': '파이프라인 및 성능 벤치마크',
      'concurrent_fifo_title': 'FIFO 순차 처리 파이프라인 (updateSequential)',
      'concurrent_processing': '처리 중',
      'concurrent_idle': '대기 중',
      'concurrent_spam_btn': '연타로 스트림 쏟아붓기!',
      'concurrent_bench_title': 'RxList 대량 처리 벤치마크',
      'concurrent_bench_items_badge': '10,000개 데이터',
      'concurrent_standard_loop_btn': '일반 루프 (병목 발생)',
      'concurrent_rx_batch_btn': 'RxList 일괄 갱신 (최적화)',
      'concurrent_standard_label': '일반 루프 (1,000개 순회)',
      'concurrent_rx_label': 'RxList 최적화 루프 (10,000개 일괄)',

      // 6. Settings Page
      'settings_theme_title': '화면 테마 모드',
      'settings_dark_active': '다크 모드 활성화됨',
      'settings_light_active': '라이트 모드 활성화됨',
      'settings_language_title': '애플리케이션 다국어',
    },
  };
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Declarative routing using GoRouter for premium performance
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        // 1. Hub Start Page
        GoRoute(path: '/', builder: (context, state) => const TestListPage()),

        // 2. Course 1: Basic Rx & Actions
        GoRoute(
          path: '/basic-rx',
          builder: (context, state) => BindingWidget(
            bindings: [Bind<BasicRxController>(() => BasicRxController())],
            child: const BasicRxPage(),
          ),
        ),

        // 3. Course 2: Scoped DI Stack (Dynamic nested push page with Query Parameter)
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
            bindings: [
              Bind<SelfHealingSafetyController>(
                () => SelfHealingSafetyController(),
              ),
            ],
            child: const SelfHealingSafetyPage(),
          ),
        ),

        // 5. Course 4: High-Frequency FIFO Queue & RxList Benchmark
        GoRoute(
          path: '/concurrent',
          builder: (context, state) => BindingWidget(
            bindings: [
              Bind<ConcurrentUpdateController>(
                () => ConcurrentUpdateController(),
              ),
            ],
            child: const ConcurrentUpdatePage(),
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

        // 8. Settings Page
        GoRoute(
          path: '/settings',
          builder: (context, state) => const ExtraSettingsPage(),
        ),
      ],
    );

    // Bootstrap root with GetMaterialApp
    return GetMaterialApp(
      routerConfig: router,
      bindings: [Bind<AppConfig>(() => AppConfig())],
      builder: (context, child) {
        // Initialize global dark-mode settings service
        Get.find<AppConfig>(context);
        return child!;
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: Colors.white10),
          ),
        ),
      ),
      translations: AppTranslations(),
      locale: const Locale('ko', 'KR'), // Default to Korean
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
