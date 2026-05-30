import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:getx_distil/get.dart';
import 'src/views/dashboard_controller.dart';
import 'src/views/settings_controller.dart';
import 'src/views/dashboard_page.dart';
import 'src/views/settings_page.dart';
import 'src/views/rx_list_bench_controller.dart';
import 'src/views/rx_list_bench_page.dart';

import 'src/config/app_config.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'dashboard_title': 'Distil Dashboard',
          'welcome_msg': 'Welcome to the Future of State Management',
          'app_subtitle': 'Reactive State & Scoped DI',
          'price_feed': 'High-Frequency Price Stream',
          'Bullish': 'Bullish',
          'Bearish': 'Bearish',
          'Stable': 'Stable',
          'high_freq_desc': 'FIFO async queue pipeline via updateSequential prevents race conditions',
          'counter_title': 'Interactive Scoped Counter',
          'click_metric': 'You clicked the button: %s times',
          'btn_increment': 'Increment',
          'settings_title': 'Preferences Settings',
          'pref_section': 'VISUAL & LOCALIZATION PREFERENCES',
          'theme_mode': 'Theme Mode',
          'dark_desc': 'Vibrant glassmorphism active',
          'light_desc': 'Clean light design active',
          'language_sel': 'Application Language',
          'bench_nav': 'RxList Benchmark',
        },
        'ko_KR': {
          'dashboard_title': '디스틸 대시보드',
          'welcome_msg': '상태 관리의 미래에 오신 것을 환영합니다',
          'app_subtitle': '반응형 상태 및 스코프 DI',
          'price_feed': '고주파 실시간 가격 피드',
          'Bullish': '상승세',
          'Bearish': '하락세',
          'Stable': '안정',
          'high_freq_desc': 'updateSequential을 통한 FIFO 비동기 대기열로 레이스 컨디션을 방지합니다',
          'counter_title': '인터랙티브 스코프 카운터',
          'click_metric': '버튼을 클릭한 횟수: %s회',
          'btn_increment': '클릭수 증가',
          'settings_title': '환경 설정',
          'pref_section': '화면 테마 및 다국어 설정',
          'theme_mode': '화면 테마 모드',
          'dark_desc': '다크 글래스모피즘 테마 활성화',
          'light_desc': '깔끔하고 밝은 라이트 테마 활성화',
          'language_sel': '애플리케이션 언어 선택',
          'bench_nav': 'RxList 벤치마크',
        }
      };
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Declarative routing using GoRouter
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            // Scope DashboardController specifically to the Dashboard page
            return BindingWidget(
              bindings: [
                Bind<DashboardController>(() => DashboardController()),
              ],
              child: const DashboardPage(),
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) {
            final userRole = state.uri.queryParameters['user'] ?? 'Guest';
            // Wrap SettingsPage with its own scoped BindingWidget
            return BindingWidget(
              bindings: [
                Bind<SettingsController>(() => SettingsController(userRole: userRole)),
              ],
              child: const SettingsPage(),
            );
          },
        ),
        GoRoute(
          path: '/bench',
          builder: (context, state) {
            return BindingWidget(
              bindings: [
                Bind<RxListBenchController>(() => RxListBenchController()),
              ],
              child: const RxListBenchPage(),
            );
          },
        ),
      ],
    );

    // Bootstrap root with pure GetMaterialApp
    return GetMaterialApp(
      routerConfig: router,
      bindings: [
        Bind<AppConfig>(() => AppConfig()),
      ],
      builder: (context, child) {
        // Force initialization of AppConfig GetxService at app startup
        Get.find<AppConfig>(context);
        return child!;
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
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
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
