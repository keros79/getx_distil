# 🚀 getx_distil

Flutter를 위한 **고성능 마이크로 상태 관리 및 트리 스코프 의존성 주입(DI) 라이브러리**입니다. GetX의 가장 강력하고 직관적인 코어 메커니즘인 반응형 상태(`Rx`)와 의존성 주입(DI)만을 추출하고 정제하여, 불필요한 레거시 아키텍처 오버헤드를 완전히 걷어냈습니다.

---

## 🏛️ 개발 철학

오랫동안 GetX를 애용하고 직접 사용해 온 팬으로서, 우리는 GetX가 개척한 독보적인 개발자 경험(DX)을 진심으로 지지합니다. `.obs`를 붙이는 극도의 간결함, `Obx` 기반의 완벽한 핀포인트 리빌드, 그리고 마찰 없는 의존성 탐색은 Flutter의 상태 관리 패러다임을 혁신적으로 이끌었습니다.

하지만 Flutter 생태계가 선언형 라우팅(`GoRouter` 등)과 위젯 트리 기반의 엄격한 수명 주기로 진화함에 따라, 기존 GetX의 무거운 전역 네비게이션 오버레이, 자체 커스텀 라우팅 엔진, 암묵적인 메모리 관리 방식은 아키텍처 설계상의 충돌, 뜻하지 않은 메모리 누수, 그리고 몇몇 예외 시나리오들을 유발하곤 했습니다.

`getx_distil`은 바로 이러한 존중과 필요에 의해 탄생했습니다. 필요한 비대함을 걷어내고, 고질적인 동시성 문제를 해결했으며, 메모리 안정성을 대폭 강화했습니다.

> **동일한 개발자 경험. 오버헤드 제로.**

---

## 📊 핵심 개선 사항

* 🌳 **100% 트리 스코프 DI 라이프사이클**: 수동으로 `Get.delete()`를 호출해야 하는 번거로움을 완전히 없앴습니다. 컨트롤러들은 `BindingWidget`을 사용해 위젯 트리에 수명 주기가 엄격하게 묶입니다. 화면 위젯이 트리에서 내려가면(unmount), 컨트롤러는 자동으로 안전하게 가비지 컬렉션(Auto-GC)됩니다.
* 🛡️ **빌드 단계 상태 변경 자가 치유**: 위젯 트리가 빌드되거나 레이아웃을 잡는 도중에 반응형 상태를 수정하면 일반적으로 Flutter 엔진은 `setState() during build` 치명적 크래시를 유발합니다. `getx_distil`은 이를 스스로 감지하고 UI 업데이트를 다음 포스트 프레임 콜백 큐로 알아서 안전하게 지연 처리합니다.
* 🛑 **엄격한 비동기 Obx 검증**: `Obx` 빌더 콜백 내부에서 직접 `async/await`를 사용하는 것은 반응형 추적 고리를 끊어버리는 안티 패턴입니다. `getx_distil`은 이 실수를 실시간으로 탐지하여, 조용히 오동작하는 대신 명확한 경고가 담긴 `FlutterError`를 던져 줍니다.
* 🧵 **FIFO 비동기 파이프라인 (`updateSequential`)**: 고주파 비동기 데이터 갱신 시 발생하는 크리티컬한 데이터 순서 뒤바뀜 및 레이스 컨디션 문제를 방지하기 위해 정교한 순차 처리 대기 큐를 내장했습니다.
* 📋 **루프 대량 변경 최적화 (`RxList`)**: 루프 반복문 내에서 대량의 요소 변경이 일어날 때 매번 값 변경 이벤트를 발생시켜 화면을 무수히 리빌드하는 대신, 변경점들을 묶어 단 1회의 마이크로태스크 UI 리프레시만 예약 및 수행합니다.
* 🔍 **직관적인 DI 디버깅 가이드**: `Get.find`가 의존성을 찾지 못해 실패할 때 단순한 에러 스택 대신, 요청을 호출한 위젯명, 정확한 상위 조상 위젯 계층 구조 경로(Tree Path), 그리고 현재 메모리에 올라와 있는 전역/불멸 서비스 목록을 한눈에 표시해 줍니다.
* ⚡ **고속 트랙(Fast-Path) 추적 플래그 (`Notifier.isTracking`)**: 오리지널 GetX에서는 `Obx` 외부(일반 비즈니스 로직 루프, 백그라운드 연산 등)에서 반응형 변수를 단순히 읽기만 해도 매번 전역 프록시(`RxInterface.proxy`) 탐색과 null 여부 체크를 거치게 됩니다. `getx_distil`은 정적 부울 플래그 `isTracking`을 도입하여 `Obx` 빌드 중이 아닐 때는 복잡한 프록시 탐색과 등록 파이프라인을 원천적으로 우회(bypass)하도록 개선함으로써, 대량 데이터 순회 및 연산 시의 CPU 부하와 불필요한 탐색 오버헤드를 극적으로 제거했습니다.

---

## 🛠️ 필수 컴포넌트 및 빠른 시작

### 1. 🎯 반응형 상태 관리 (`Rx` & `Obx`)
보일러플레이트가 전혀 없는 극도의 간결함으로 최하위 단말 위젯 단위 리빌드를 제어합니다.

```dart
class CounterController extends GetxController {
  final count = 0.obs;             // RxInt
  final name = Rxn<String>();      // 안전한 Nullable Rx

  void increment() {
    count.value++;                 // 값 갱신 시 알아서 화면 변경 통지
    name.value = 'Flutter';
  }
}
```

뷰 레이어 (특정 텍스트 영역만 정밀 리빌드):
```dart
Obx(() => Text('${controller.count.value}'));
```

---

### 2. 🚀 전역/클래식 의존성 주입 (`Get.put` & `Get.find`)
전역 범위(Global Registry)에 인스턴스를 즉시 혹은 지연 등록하여 앱 어디서든 쉽게 참조할 수 있는 전통적인 GetX 방식의 싱글톤 DI입니다.

인스턴스 등록:
```dart
// 1. put: 인스턴스를 즉시 생성하여 전역 메모리에 등록
final controller = Get.put(CounterController());

// 2. lazyPut: 인스턴스를 등록만 해두고, 최초로 Get.find가 호출되는 시점에 생성 (지연 로딩)
Get.lazyPut(() => CounterController());

// 3. tag를 통한 고유 식별 등록 (동일 타입의 멀티 인스턴스)
Get.put(CounterController(), tag: 'special_counter');
```

인스턴스 조회 (BuildContext가 필요 없는 전역 참조):
```dart
// 전역에 등록된 인스턴스 검색 및 획득
final controller = Get.find<CounterController>();

// tag를 지정해 등록된 인스턴스 검색
final specialController = Get.find<CounterController>(null, 'special_counter');
```

> [!TIP]
> `getx_distil`은 **하이브리드 DI**를 지원합니다. `Get.find(context)`와 같이 `BuildContext`를 함께 전달하면 화면 위젯 트리 범위의 DI(`BindingWidget`)에서 인스턴스를 우선 탐색하며, 존재하지 않을 경우 자동으로 전역 범위(Global Registry)를 찾아 인스턴스를 반환합니다.
> 
> 또한 v1.0.1부터는 `BindingWidget`에 등록된 스코프 컨트롤러라도 위젯 트리에서 한 번 생성되었다면, 메모리 누수가 없는 안전한 약한 참조 캐시(Weak Reference Cache)를 통해 **`BuildContext` 없이 `Get.find<T>()` 호출만으로 조회**할 수 있습니다.

> [!WARNING]
> **컨트롤러 내부에서 Context 없이 의존성 조회 시 권장 사항 (Best Practice)**
> 
> 인스턴스 생성 단계의 레이스 컨디션 및 `Could not find any instance...` 에러를 방지하려면, **멤버 변수 선언 시점이나 생성자 본문 내에서 즉시 context 없이 `Get.find()`를 수행하지 마세요.** (의존하는 다른 컨트롤러가 아직 생성 완료되지 않았을 수 있습니다.)
> 
> 대신 아래와 같이 **`late` 초기화**, **`getter`**, 혹은 **`onInit()`** 생명주기 메서드 안에서 조회를 지연 수행하는 것을 강력히 권장합니다.
> 
> ```dart
> class ChildController extends GetxController {
>   // ❌ 비권장: 생성자 실행 단계에서 즉시 Get.find가 돌아 레이스 컨디션 유발 위험
>   // final parent = Get.find<ParentController>();
> 
>   // ✅ 권장 대안 1: 처음 접근해 사용되는 시점에 지연 평가(Lazy)하여 탐색
>   late final parent = Get.find<ParentController>();
> 
>   // ✅ 권장 대안 2: 호출될 때마다 동적으로 탐색
>   ParentController get parent => Get.find<ParentController>();
> 
>   // ✅ 권장 대안 3: 컨트롤러 생명주기가 안착된 안전한 시점에 탐색
>   late final ParentController parent;
> 
>   @override
>   void onInit() {
>     super.onInit();
>     parent = Get.find<ParentController>();
>   }
> }
> ```

---

### 3. 🌳 위젯 트리 스코프 의존성 주입 (`BindingWidget`)
컨트롤러의 수명 주기를 화면의 가시성(Visibility)과 완벽히 일치시킵니다. `GoRouter`나 네이티브 `Navigator` 환경에 최적화되어 있습니다.

```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => BindingWidget(
    bindings: [
      Bind<SettingsController>(() => SettingsController()),
    ],
    child: const SettingsPage(),
  ),
)
```

`SettingsPage` 내부 (컨텍스트 기반 자동 의존성 해결):
```dart
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => Text(controller.someData.value)),
    );
  }
}
```

---

### 4. 🌐 전역 불멸 서비스 (`GetxService`)
데이터베이스 초기화, 유저 인증 정보 세션 매니저, 네트워크 클라이언트 모듈 등 앱 구동 내내 메모리에 유지(Immortal Singleton)되어야 하는 아키텍처 레이어를 선언합니다.

```dart
class DatabaseService extends GetxService {
  Future<void> init() async => print('DB Connected');
}
```

어플리케이션 최상위 노드에 등록:
```dart
GetMaterialApp(
  bindings: [Bind<DatabaseService>(() => DatabaseService())],
  child: const MyApp(),
);
```

비즈니스 로직 어디서든 BuildContext 없이도 편하게 조회:
```dart
final db = Get.find<DatabaseService>();
```

---

### 5. 🛠️ 백그라운드 부수 효과 (`Worker`)
반응형 변수의 상태를 지켜보다가 비동기 API 데이터 갱신, 디바운스 입력 연동 등 실시간 백그라운드 동작을 깔끔하게 처리합니다.

```dart
class SearchController extends GetxController {
  final searchQuery = ''.obs;
  late final Worker _worker;

  @override
  void onInit() {
    super.onInit();
    // 타자 입력이 멈추고 500ms 동안 대기가 발생할 때만 통신 수행
    _worker = debounce(
      searchQuery, 
      (query) => fetchApi(query), 
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    _worker.dispose(); // 명시적인 dispose 규칙을 도입하여 누수를 완벽히 방지합니다!
    super.onClose();
  }
}
```

---

### 6. 🔄 선언적 비동기 분기 처리 (`StateMixin`)
일반적인 API 통신의 네 가지 단골 상태인 로딩 중, 데이터 성공, 비어있음, 에러 발생 처리를 복잡한 분기문 없이 우아하게 작성합니다.

```dart
class UserController extends GetxController with StateMixin<String> {
  void fetchUser() async {
    change(null, status: RxStatus.loading());
    try {
      final res = await api.getUser();
      res.isEmpty 
          ? change(null, status: RxStatus.empty()) 
          : change(res, status: RxStatus.success());
    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
    }
  }
}
```

뷰 레이어에서 선언적 맵 처리:
```dart
controller.obx(
  (state) => Text('안녕하세요, $state 님'),
  onLoading: const CircularProgressIndicator(),
  onEmpty: const Text('유저 정보를 찾지 못했습니다.'),
  onError: (error) => Text('에러 발생: $error', style: const TextStyle(color: Colors.red)),
);
```

---

### 7. 🌐 다국어 및 로컬라이제이션 (`Translations` & `tr`)
앱의 다국어 번역 리소스를 유연하고 반응형으로 관리하며, 유저의 설정에 따라 화면 언어를 실시간으로 동적 변경합니다.

다국어 번역 사전 정의:
```dart
class MyTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'hello': 'Hello World',
      'welcome': 'Welcome, @name!',
    },
    'ko_KR': {
      'hello': '안녕하세요',
      'welcome': '안녕하세요, @name님!',
    }
  };
}
```

최상위 앱에 번역 등록 및 기본 언어 지정:
```dart
GetMaterialApp(
  translations: MyTranslations(),
  locale: const Locale('ko', 'KR'),
  fallbackLocale: const Locale('en', 'US'),
  child: const MyApp(),
);
```

뷰 레이어에서 반응형으로 다국어 텍스트 사용:
```dart
// 1. 단순 번역 lookup
Obx(() => Text('hello'.tr))

// 2. 파라미터 치환 번역
Obx(() => Text('welcome'.trParams({'name': '홍길동'})))
```

실시간 동적 언어 변경:
```dart
// 한국어로 변경
Get.locale = const Locale('ko', 'KR');

// 영어로 변경
Get.locale = const Locale('en', 'US');
```

---

## 📄 라이선스

이 프로젝트는 MIT 라이선스에 따라 배포됩니다.
