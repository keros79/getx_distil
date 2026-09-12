import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_distil/get.dart';
import 'package:example/core/translations/app_translations.dart';
import 'package:example/models/domain/user_entity.dart';
import 'package:example/models/domain/user_repository.dart';
import 'package:example/views/tdd_test/tdd_test_controller.dart';
import 'package:example/views/tdd_test/tdd_test_page.dart';

/// Mock repository returning instant mock data without network calls.
class MockUserRepository implements UserRepository {
  UserEntity stubbedUser = const UserEntity(
    id: 1,
    name: 'Mocked User Data',
    email: 'mock@example.com',
  );

  @override
  Future<UserEntity> fetchUser() async => stubbedUser;
}

/// Mock repository throwing an exception to simulate network errors.
class ErrorMockUserRepository implements UserRepository {
  @override
  Future<UserEntity> fetchUser() async {
    throw Exception('Network Error');
  }
}

void main() {
  group('TDD & Dependency Isolation using BindingWidget', () {
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
      // Reset global dependency injection state before each test.
      Get.reset();
      // Initialize translation keys and default locale.
      Get.addTranslations(AppTranslations().keys);
      Get.locale = const Locale('ko', 'KR');
    });

    testWidgets('1. Verifies data loads into RxS state via a mock repository', (
      WidgetTester tester,
    ) async {
      mockRepository.stubbedUser = const UserEntity(
        id: 1,
        name: 'TDD-driven widget verification success!',
        email: 'tdd@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BindingWidget(
            bindings: [
              // Override the production repository with the mock.
              Bind<UserRepository>(() => mockRepository),
              // Bind the controller with the same pattern the router uses.
              Bind<TddTestController>(
                () => TddTestController(repository: Get.find<UserRepository>()),
              ),
            ],
            child: const TddTestPage(),
          ),
        ),
      );

      // Loading indicator is shown while the future is pending.
      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);

      // 1st pump completes the future, 2nd pump rebuilds the leaf Obx.
      await tester.pump();
      await tester.pump();

      // Data rendered by the RxS loaded state.
      expect(find.byKey(const Key('loading_indicator')), findsNothing);
      expect(
        find.text('TDD-driven widget verification success! (tdd@example.com)'),
        findsOneWidget,
      );
    });

    testWidgets(
      '2. Verifies the error state renders when the repository throws',
      (WidgetTester tester) async {
        final errorRepository = ErrorMockUserRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: BindingWidget(
              bindings: [
                Bind<UserRepository>(() => errorRepository),
                Bind<TddTestController>(
                  () =>
                      TddTestController(repository: Get.find<UserRepository>()),
                ),
              ],
              child: const TddTestPage(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        // RxS exposes the captured error message in the error state.
        expect(find.text('에러 발생: Network Error'), findsOneWidget);
      },
    );
  });
}
