import 'package:getx_distil/get.dart';
import '../services/rest_api_service.dart';

class TddTestController extends GetxController {
  late final RestApiService _apiService = Get.find<RestApiService>();


  final userData = "".obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    isLoading.value = true;
    try {
      userData.value = await _apiService.fetchUserData();
    } catch (e) {
      userData.value = "에러 발생: ${e.toString().replaceAll('Exception: ', '')}";
    } finally {
      isLoading.value = false;
    }
  }
}
