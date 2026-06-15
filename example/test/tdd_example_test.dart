import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_distil/get.dart';
import 'package:example/main.dart';
import 'package:example/src/services/rest_api_service.dart';
import 'package:example/src/views/tdd_test_controller.dart';
import 'package:example/src/views/tdd_test_page.dart';

/// Mock API service returning instant mock data without network calls for test environments.
class MockRestApiService implements RestApiService {
  String stubbedValue = "Mocked User Data";

  @override
  Future<String> fetchUserData() async {
    // Returns mock value instantly without network latency
    return stubbedValue;
  }
}

/// Mock API service throwing an exception to simulate network errors.
class ErrorMockRestApiService implements RestApiService {
  @override
  Future<String> fetchUserData() async {
    throw Exception("Network Error");
  }
}

void main() {
  group('TDD & Dependency Isolation using BindingWidget', () {
    late MockRestApiService mockApiService;

    setUp(() {
      mockApiService = MockRestApiService();
      // Reset global dependency injection state before each test
      Get.reset();
      // Initialize translation keys and default locale to prevent UI overflows and test localization
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('ko', 'KR');
    });

    testWidgets('1. Verifies that data is successfully loaded and rendered on screen using MockRestApiService', (
      WidgetTester tester,
    ) async {
      mockApiService.stubbedValue = "TDD-driven widget verification success!";

      await tester.pumpWidget(
        MaterialApp(
          // Use MaterialApp instead of GetMaterialApp for lightweight unit/widget testing.
          // Pass the mock bindings locally using BindingWidget.
          home: BindingWidget(
            bindings: [
              // (Important) Bind MockRestApiService to RestApiService
              Bind<RestApiService>(() => mockApiService),
              // Bind controller
              Bind<TddTestController>(
                () => TddTestController(),
              ),
            ],
            child: const TddTestPage(),
          ),
        ),
      );

      // Step 1: Ensure loading indicator is rendered during the initial async fetch call
      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);

      // Pump 1st frame to complete the asynchronous future (fetchUserData)
      await tester.pump();
      // Pump 2nd frame to trigger the UI rebuild (Obx) after state change
      await tester.pump();

      // Step 2: Verify that loading indicator disappears and mock data is rendered
      expect(find.byKey(const Key('loading_indicator')), findsNothing);
      expect(find.text('TDD-driven widget verification success!'), findsOneWidget);
    });

    testWidgets('2. Verifies that error text is rendered correctly when API service throws an exception', (
      WidgetTester tester,
    ) async {
      final errorApiService = ErrorMockRestApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: BindingWidget(
            bindings: [
              Bind<RestApiService>(() => errorApiService),
              Bind<TddTestController>(
                () => TddTestController(),
              ),
            ],
            child: const TddTestPage(),
          ),
        ),
      );

      // Pump 1st frame to throw and process the async exception
      await tester.pump();
      // Pump 2nd frame to render the error layout (Obx)
      await tester.pump();

      // Verify that the exception message is caught and rendered in the text widget
      expect(find.text('에러 발생: Network Error'), findsOneWidget);
    });
  });
}
