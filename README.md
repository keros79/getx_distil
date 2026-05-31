# 🚀 getx_distil

`getx_distil`은 기존 GetX의 강력하고 직관적인 핵심 기능(반응형 상태 관리 및 의존성 주입)만을 극대화하여 정제한 **고성능 마이크로 상태 관리 및 트리 스코프 의존성 주입(DI) 라이브러리**입니다.

불필요하게 무겁고 거대한 네비게이션 오버레이, 라우팅 엔진, 커스텀 글로벌 UI 레이어들을 완전히 걷어내고, **순수 반응형 요소(Reactivity)**와 **계층적 DI(Tree-Scoped Dependency Injection)**에만 100% 집중하여 플러터 공식 생태계 및 `GoRouter` 등과 매끄럽게 호환되도록 설계되었습니다.

---

## ✨ 핵심 기능 (Key Features)

* ⚡ **초경량 반응형 코어 (`Rx`)**: `.obs` 및 `.value` 형태의 문법으로 보일러플레이트를 최소화합니다.
* 🛡️ **FIFO 비동기 파이프라인 (`updateSequential`)**: 고주파 비동기 업데이트 시 발생하는 상태 역전·레이스 컨디션을 순차 대기열로 방지합니다. 단순 덮어쓰기는 `rx.value = v`, 이전 상태 의존 트랜잭션은 `rx.updateSequential(...)`을 사용합니다.
* 🎯 **핀포인트 반응형 위젯 (`Obx`)**: 변화된 최하위 위젯만 재빌드하고 미사용 구독을 자동 해제합니다.
* 🌳 **트리 스코프 DI (`BindingWidget` & `Get.find`)**: 위젯 트리 스코프를 따르며, 스코프가 제거될 때 컨트롤러가 자동 `onClose()` 후 GC됩니다.
* 🧵 **스레드 세이프 컨텍스트 룩업 (`GetView` & `Expando`)**: 비동기·중첩 `Obx` 환경에서도 타이밍 이슈 없이 정확한 인스턴스를 보장합니다.
* ⚡ **Fast-Path 정적 고속 트랙**: 비UI 로직 수행 중 `Notifier.isTracking` 플래그로 불필요한 프록시 탐색을 우회해 연산 부하를 최소화합니다.
* 📋 **고성능 반응형 리스트 (`RxList`)**: 루프 내 N번의 변이를 Dirty-Flag + 마이크로태스크 배칭으로 1회 리빌드로 압축합니다.

---

## 🛠️ 기본 사용법 및 구성 요소 가이드 (Usage & Components Guide)

`getx_distil`은 오리지널 GetX의 개발 편리성을 최대한 계승하면서도, 위젯 트리 기반의 엄격한 생명주기 관리와 극대화된 렌더링 성능을 보장하도록 각 코어 컴포넌트가 최적화되어 있습니다.

---

### 1. 🎯 Obx & Rx (반응형 상태 관리 및 정밀 리빌드)
`getx_distil`은 보일러플레이트를 극단적으로 제거한 반응형 프로그래밍을 지원하며, 렌더링 부하를 최소화하도록 코어가 설계되어 있습니다.

* **기본 선언 및 `.obs` 확장**:
  ```dart
  final count = 0.obs;             // RxInt (Rx<int>)
  final user = User().obs;         // Rx<User> (사용자 정의 객체)
  final name = Rxn<String>();      // nullable Rx (null 허용)
  ```

#### 📖 값 읽기 / 쓰기

`getx_distil`은 기존 GetX의 `.value` 방식을 통해 반응형 변수의 값을 읽고 씁니다.

```dart
class CounterController extends GetxController {
  final count = 0.obs;
  final name = Rxn<String>();

  void increment() {
    count.value = count.value + 1;
    name.value = 'Flutter';
  }
}
```

#### 💡 오리지널 GetX 대비 핵심 개선점
* **Nullable Rx (`Rxn<T>`) null 처리 완벽 지원**: `name.value = null`로 명시적 null 상태를 안전하게 주입할 수 있습니다.
* **🛡️ Obx 내 비동기(Async/Future) 오용 차단**: `Obx` 빌더 내부에서 `async/await`나 `Future`를 반환하도록 작성하여 반응형 변수 추적 루프가 누락되는 조용한 버그(Silent tracking failures)를 방지하기 위해, `Future` 반환 감지 시 유용한 경고와 함께 명확한 `FlutterError`를 즉시 발생시킵니다.
* **⚡ 빌드 단계 상태 변경 예외 방어 (setState() during build 방지)**: 위젯 트리 빌드/레이아웃 과정 중에 실수로 반응형 변수를 수정하더라도, 플러터 엔진이 충돌하는 대신 `SchedulerBinding`의 스케줄 상태를 자동으로 판별하고 UI 업데이트 스케줄을 다음 프레임 포스트 콜백으로 즉시 이월(Defer)하여 예외를 안전하게 예방합니다.

#### 🚨 Obx 사용 시 정밀 리빌드(Targeted Rebuild) 가이드
* **Scaffold 전체를 Obx로 감싸지 마세요!**: 값이 변하지 않는 정적 UI 뼈대까지 통째로 리빌드되어 프레임 드랍이 발생할 수 있습니다.
* **올바른 최적화 패턴**: `Scaffold`나 공통 레이아웃은 `Obx` 밖에 배치하고, **실제로 값이 변하는 최하위 개별 위젯만 핀포인트로 `Obx`로 감싸서 격리**해야 합니다.

```dart
// 핀포인트 Obx 예시
Obx(() => Text(
  '${controller.count.value}',
  style: Theme.of(context).textTheme.headlineMedium,
))
```

---

### 2. 🧵 GetView & Hybrid DI (글로벌 싱글톤 & 위젯 트리 스코프 DI)
`getx_distil`은 관리하고자 하는 **의존성(Dependency)의 수명과 사용 목적**에 따라 두 가지 DI 영역을 명확하게 구분하여 사용합니다.

* **🌐 전역 글로벌 DI (Global DI)**
  * **대상**: 앱 실행 동안 영구적으로 유지되어야 하는 백그라운드 서비스, 데이터베이스 세션, 공통 API 클라이언트 등.
  * **방식**: `Get.put()` 또는 `Get.lazyPut()`을 통해 등록하며, `BuildContext` 없이 언제 어디서든 바로 조회할 수 있습니다.
* **🌳 지역 트리 DI (Tree-Scoped DI)**
  * **대상**: 특정 화면(Page)이나 개별 UI 컴포넌트 단위에서만 한시적으로 생존해야 하는 컨트롤러 및 뷰모델.
  * **방식**: `BindingWidget(bindings)`을 통해 위젯 트리 스코프와 완전히 결합하며, 해당 위젯이 트리에서 언마운트되면 자동으로 수명이 만료되어 소멸(GC)됩니다.

---
#### 💡 글로벌 DI와 지역 트리 DI의 명확한 역할 분담

##### ① 전역 글로벌 DI (Global DI)
* **등록**: `Get.put(DatabaseService())` 또는 `Get.lazyPut(() => ApiService())`
* **조회**: `final api = Get.find<ApiService>();` (BuildContext 매개변수 생략)
* **특징**:
  * `BuildContext`가 필요 없으므로 UI 외부의 순수 비즈니스 로직, Repository, Background Task 등 어디서든 즉시 조회해올 수 있습니다.
  * **싱글톤 보호 장치 (Singleton Protection)**: 오리지널 GetX와 동일하게 `Get.put`을 중복 실행하더라도 기존에 캐싱된 전역 인스턴스를 무조건 반환(Return Existing)하여 전역 상태 오염을 원천 방지합니다.
  * 이미 특정 타입의 인스턴스가 주입되었는지 검사할 수 있는 `Get.isRegistered<T>()` API를 제공합니다.

##### ② 지역 트리 DI (Tree-Scoped DI)
* **등록**: `BindingWidget(bindings: [Bind<MyController>(() => MyController())], child: ...)`
* **조회**: `Get.find<MyController>(context)` 또는 `GetView<MyController>`를 통한 `controller` 지향 접근.
* **수명**: 플러터 위젯의 Lifecycle과 100% 동기화되어 위젯이 트리에서 제거(`dispose`)될 때 바인딩된 컨트롤러들도 **자동으로 `onClose()` 라이프사이클을 수행하며 GC(가비지 컬렉션)에 의해 완벽하게 수거**됩니다.

---

#### 🚨 왜 지역(화면 단위) DI는 오직 `BindingWidget` 계층으로만 강제되어야 할까요?

수동으로 전역 맵에 집어넣고 뒤로가기 시점에 직접 소멸(Get.delete)시키는 우회로를 열어주면 대형 프로젝트에서 협업 시 심각한 사이드 이펙트가 발생합니다.
1. **메모리 누수 발생**: 개발자가 `onClose()`나 뒤로가기 시점에 해제 코드를 깜빡하는 실수를 하면 객체가 백그라운드에 영구 상주합니다.
2. **동기화 타이밍 문제 (Race Condition)**: 화면이 닫힐 때 비동기 콜백이 잔존하여 소멸된 객체를 호출하다 널 참조나 예기치 않은 크래시가 유발됩니다.
3. **가독성 및 일관성 붕괴**: 누구는 자동으로 수명 주기를 뚫고 누구는 수동으로 관리하여 디버깅 비용이 치솟습니다.

따라서 `getx_distil`은 **"수명이 짧은 화면/컴포넌트 단위의 지역 상태는 반드시 `BindingWidget` 계층을 통해서만 강제한다"**는 일관된 구조적 제약을 부과하여 휴먼 에러를 0%로 만들고 메모리 안정성을 확보합니다.

---

#### 📌 기본 사용법 및 생성자 주입 (Constructor Injection)

```dart
// 1. GoRouter 설정 시점 혹은 화면 진입 시 생성자 주입(Constructor Injection) 추천
// 뷰 진입부(BuildContext가 존재하는 유일한 UI 영역)에서 하위 컨트롤러 생성 시 
// context 기반으로 조상 의존성을 주입하여 컴파일 타임의 완벽한 타입 안전성을 획득합니다.
GoRoute(
  path: '/settings',
  builder: (context, state) {
    final userRole = state.uri.queryParameters['user'] ?? 'Guest';
    return BindingWidget(
      bindings: [
        // SettingsController를 SettingsPage 범위에만 격리하여 바인딩
        Bind<SettingsController>(() => SettingsController(userRole: userRole)),
      ],
      child: const SettingsPage(),
    );
  },
)
```

---

### 3. 🛠️ Worker (비동기 흐름 제어 및 자원 관리)
컨트롤러 생명주기 동안 특정 반응형 변수의 변화를 감지하여 비동기 또는 비즈니스 로직을 제어하는 강력한 워커 엔진을 제공합니다.

* **`ever(listener, callback)`**: 변수 값이 바뀔 때마다 **무조건 즉시** 콜백을 실행합니다.
* **`once(listener, callback)`**: 변수 값이 처음 바뀔 때 **딱 한 번만** 콜백을 실행하고 리스너를 자동 자원 회수합니다.
* **`debounce(listener, callback, {Duration time})`**: 값 변경 후 특정 대기시간(기본값 800ms) 동안 추가 변경이 없을 때(침묵 상태) 최종적으로 단 한 번만 콜백을 수행합니다. (예: 검색창 자동완성 API 호출 디바운싱)

#### 💡 오리지널 GetX 대비 핵심 개선점 및 차이점
* **명시적 리소스 해제 필수화 (Disposer 반환)**:
  * 모든 워커는 백그라운드에서 스트림 리스너를 감시하므로, 메모리 누수를 완전히 방지하기 위해 컨트롤러가 소멸하는 `onClose()` 단계에서 반드시 반환된 `Worker` 객체의 `.dispose()` 또는 `.cancel()`을 호출해 정리해 주어야 합니다.

```dart
class SearchController extends GetxController {
  final searchQuery = ''.obs;
  late final Worker _searchWorker;

  @override
  void onInit() {
    super.onInit();
    
    // 디바운스 워커 등록
    _searchWorker = debounce(
      searchQuery, 
      (query) => _fetchSearchResults(query), 
      time: const Duration(milliseconds: 500),
    );
  }

  void _fetchSearchResults(String query) {
    print('서버 API 요청 송신: $query');
  }

  @override
  void onClose() {
    _searchWorker.dispose(); // 🚨 워커 리스너 해제로 메모리 누수 완벽 차단!
    super.onClose();
  }
}
```


---

### 4. 🏛️ GetMaterialApp & App Bootstrapping (통합 바인딩 및 반응형 테마/언어 설정)

`GetMaterialApp`은 애플리케이션의 초기 설정을 손쉽게 관리하고, 테마 및 언어 변경에 따른 실시간 UI 반영을 안전하게 처리할 수 있도록 설계된 핵심 루트 위젯입니다.

#### 💡 GetMaterialApp 제공 핵심 기능
1. **내장형 반응형 테마/언어 자동 업데이트**:
   * 테마(`theme`, `darkTheme`, `themeMode`) 및 언어(`locale`)를 내부 반응형 스트림으로 자동 구독합니다.
   * `Get.themeMode`나 `Get.locale` 변경 시 별도의 래퍼 위젯 없이도 **앱 전체의 UI가 안전하고 즉각적으로 리빌드**됩니다.
2. **루트 의존성 주입 (`bindings`)**:
   * `bindings` 매개변수를 지원하여 루트 위젯 영역 전체를 자동으로 `BindingWidget`으로 감싸줍니다.
   * 이를 통해 앱 전역에서 컴포넌트 생명주기에 맞게 유지될 전역 서비스(`GetxService`) 등을 일관된 방식으로 등록할 수 있습니다.
3. **안전한 빌드 타임 라이프사이클**:
   * 초기 테마/로케일 설정 또는 변경 작업이 Flutter의 빌드 단계(`setState() during build`)와 충돌하여 예외를 발생시키지 않도록 설계되었습니다.

---


### 5. 🏛️ GetxService (영구 보존 글로벌 서비스)

`GetxService`는 `GetxController`와 동일하게 `GetLifeCycleMixin`을 상속받지만, 위젯 트리의 디스포즈(Dispose) 주기와 연동되지 않고 메모리에 계속 상주하는 **영구 보존 서비스(Immortal Service)**를 만들 때 사용됩니다.

#### 💡 GetxController와의 핵심 차이점
* **자동 소멸(GC) 대상 제외**: 일반 `GetxController`는 자신을 인스턴스화한 `BindingWidget`이 트리에서 언마운트(Unmount)될 때 자동으로 `onClose()`가 호출되고 소멸하지만, `GetxService`는 해당 스코프 위젯이 소멸하더라도 메모리에서 해제되지 않고 글로벌 정적 영역에 유지됩니다.
* **적용 사례**: 로컬 데이터베이스 초기화(SQLite/Hive 등), 사용자 로그인 세션 상태를 유지하는 인증 서비스(AuthService), 공통 API 클라이언트 등 애플리케이션의 시작부터 끝까지 유지되어야 하는 백그라운드 성격의 모듈에 가장 이상적입니다.

#### 📌 사용 방법
```dart
// 1. GetxService 상속을 통한 영구 서비스 정의
class DatabaseService extends GetxService {
  bool _isConnected = false;

  Future<void> initDatabase() async {
    // DB 연결 및 스키마 초기화 로직
    _isConnected = true;
    print('데이터베이스 연결 완료');
  }

  @override
  void onClose() {
    // GetxService는 앱 종료 시점 전까지 자동 호출되지 않습니다.
    super.onClose();
  }
}
```

```dart
// 2. 최상위 GetMaterialApp에 바인딩
GetMaterialApp(
  bindings: [
    Bind<DatabaseService>(() => DatabaseService()),
  ],
  builder: (context, child) {
    // 앱 기동 시 즉각 인스턴스화하여 초기화 실행
    Get.find<DatabaseService>(context);
    return child!;
  },
  child: const MyApp(),
)
```

```dart
// 3. 앱 내 어디서든 주입 및 사용
// 일단 한 번 초기화되면 UI 외부나 BuildContext가 없는 영역에서도 context-less로 안전하게 조회 가능합니다!
final db = Get.find<DatabaseService>();
```

---

### 6. 🔄 StateMixin & RxStatus (선언형 비동기 상태 분기)

`StateMixin<T>`는 컨트롤러에 쉽게 장착하여 **로딩(Loading), 성공(Success), 데이터 없음(Empty), 에러(Error)**와 같은 대표적인 비동기 API 요청 상태를 직관적으로 제어하고, UI 단에서 보일러플레이트 코드 없이 아름다운 화면 분기를 렌더링할 수 있도록 돕는 고성능 선언형 인터페이스입니다.

#### 💡 오리지널 GetX 대비 핵심 개선점
* **원천적인 최적화**: 기존 GetX의 복잡하고 무거운 중첩 스트림 대신, `getx_distil` 고유의 초경량 `Obx` 리빌드 파이프라인을 바탕으로 상태가 전환될 때만 극도로 미세하게 타겟 위젯을 다시 그립니다.
* **직관적인 `change` 메서드**: 상태(`state`) 데이터와 진행 상태(`status`)를 아토믹하게 원자적으로 변경하는 단일 통로를 제공하여 상태 엉킴을 원천 방지합니다.

#### 📌 `RxStatus` 제공 상태
* `RxStatus.loading()`: 비동기 작업이 아직 수행 중인 상태.
* `RxStatus.success()`: 비동기 작업이 성공하고 결과 데이터가 유효한 상태.
* `RxStatus.empty()`: 성공했으나 반환된 데이터가 비어 있는 상태.
* `RxStatus.error(message)`: 작업 중 예외가 발생한 에러 상태 (에러 메시지 포함).

#### 📌 사용 방법

##### 1. 컨트롤러에 `StateMixin<T>` 주입
```dart
class ApiController extends GetxController with StateMixin<String> {
  final ApiRepository repository;

  ApiController(this.repository);

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  void fetchUserData() async {
    // 1. Loading 상태로 변경
    change(null, status: RxStatus.loading());

    try {
      final result = await repository.getUserData();
      
      if (result == null || result.isEmpty) {
        // 2. Empty 상태로 변경
        change(null, status: RxStatus.empty());
      } else {
        // 3. Success 상태 및 데이터 주입
        change(result, status: RxStatus.success());
      }
    } catch (e) {
      // 4. Error 상태 및 메시지 주입
      change(null, status: RxStatus.error(e.toString()));
    }
  }
}
```

##### 2. 뷰에서 `obx()`를 이용한 선언형 UI 매핑
UI 레이어에서 지저분한 `if (isLoading) ... else if (isError) ...` 같은 조건문을 작성할 필요 없이, `obx()` 메서드를 호출하여 상태별 화면을 깨끗하게 바인딩합니다.

```dart
class UserProfilePage extends GetView<ApiController> {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 프로필')),
      body: controller.obx(
        // [Success] 데이터가 준비되었을 때 렌더링할 뷰
        (state) => Center(
          child: Text('데이터 로드 성공: $state', style: const TextStyle(fontSize: 18)),
        ),
        // [Loading] 로딩 중 (기본값: CircularProgressIndicator)
        onLoading: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
        // [Empty] 데이터가 비어 있을 때 (기본값: SizedBox.shrink)
        onEmpty: const Center(
          child: Text('표시할 사용자 정보가 없습니다.'),
        ),
        // [Error] 에러 발생 시 (기본값: 에러 텍스트 표시)
        onError: (error) => Center(
          child: Text('에러 발생: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
```

