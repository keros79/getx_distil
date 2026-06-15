abstract class RestApiService {
  Future<String> fetchUserData();
}

class RealRestApiService implements RestApiService {
  @override
  Future<String> fetchUserData() async {
    // 실제 네트워크 통신과 데이터 로딩을 시뮬레이션하기 위해 지연 적용
    await Future.delayed(const Duration(milliseconds: 1500));
    return "실제 서버 데이터 (Real Server Data)";
  }
}
