import 'package:getx_distil/get.dart';
import '../../models/domain/user_repository.dart';

class TddTestController extends GetxController {
  TddTestController({required this.repository});

  final UserRepository repository;

  /// Status-aware observable that carries the formatted server response:
  /// `idle → loading → loaded/error` (no separate isLoading/userData flags).
  final user = RxS<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  Future<void> loadUser() => user.load(
    () async {
      final entity = await repository.fetchUser();
      return '${entity.name} (${entity.email})';
    },
    errorMessage: (e) => '에러 발생: ${e.toString().replaceAll('Exception: ', '')}',
  );
}
