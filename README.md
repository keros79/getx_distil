# 🚀 getx_distil

`getx_distil`은 기존 GetX의 강력하고 직관적인 핵심 기능(반응형 상태 관리 및 의존성 주입)만을 극대화하여 정제한 **고성능 마이크로 상태 관리 및 트리 스코프 의존성 주입(DI) 라이브러리**입니다.

불필요하게 무겁고 거대한 네비게이션 오버레이, 라우팅 엔진, 커스텀 글로벌 UI 레이어들을 완전히 걷어내고, **순수 반응형 요소(Reactivity)**와 **계층적 DI(Tree-Scoped Dependency Injection)**에만 100% 집중하여 플러터 공식 생태계 및 `GoRouter` 등과 매끄럽게 호환되도록 설계되었습니다.

---

## ✨ 핵심 기능 (Key Features)

### 1. ⚡️ 초경량 반응형 코어 (`Rx` & Callable Semantics)
- `.obs` 확장자 및 `RxInt`, `RxDouble`, `RxString`, `RxBool`, `Rxn<T>` 완벽 지원.
- 오버헤드 없는 옵저버블 바인딩 및 변경 감지 메커니즘.

### 2. 🛡️ FIFO 비동기 파이프라인 (`updateSequential`)
- `Rx` 변수에 대한 급격하고 빈번한 비동기 업데이트 상황에서 상태 역전(State Inversion) 및 레이스 컨디션(Race Condition)을 방지하기 위해 **순차적 비동기 대기열(FIFO Queue)**을 기본 제공합니다.
- 데이터 버스트 상황에서도 최신 상태가 순서대로 안전하게 화면에 반영됩니다.

### 3. 🎯 핀포인트 최적화 반응형 위젯 (`Obx`)
- Scaffold 전체를 다시 그리는 무거운 설계 대신, **상태가 실제로 바뀌는 최하위 개별 위젯만 정밀하게 다시 그리도록** 유도합니다.
- 위젯 트리가 업데이트될 때 사용되지 않는 관찰 대상(Observable)을 자동으로 해제하여 메모리 누수를 완벽하게 방지합니다.

### 4. 🌳 트리 스코프 DI 엔진 (`BindingWidget` & `Get.find`)
- 전역 싱글톤 중심의 원본 GetX와 달리, **Flutter 위젯 트리의 스코프를 준수하는 의존성 주입 계층**을 생성합니다.
- 화면(`Route`)이 언마운트되어 트리에서 제거될 때, 해당 스코프의 컨트롤러들도 **자동으로 `onClose()` 라이프사이클을 수행하며 가비지 컬렉션(GC)**됩니다.

### 5. 🧵 스레드 세이프 컨텍스트 룩업 (`GetView` & `Expando`)
- 비동기 빌드 및 중첩된 빌더(`Obx` 등) 구조 속에서도 타이밍 이슈 없이 정확한 컨트롤러 인스턴스를 찾을 수 있도록 `Expando<BuildContext>`를 활용한 스레드 세이프 생명주기 바인딩을 적용했습니다.

### 6. ⚡ Fast-Path 플래그를 통한 렌더링 부하 최소화
- UI 빌드가 일어나지 않는 일반 비즈니스 로직(연산 루프, 데이터 갱신) 중에는 반응형 변수를 조회(`reportRead`)하더라도 복잡한 프록시 및 static 멤버 탐색을 원천 우회하는 **정적 부울 플래그(`Notifier.isTracking`) 고속 트랙**을 적용하여 연산 부하를 최소화하였습니다.

---

## 📦 시작하기 (Getting Started)

`pubspec.yaml` 파일에 `getx_distil` 의존성을 추가합니다:

```yaml
dependencies:
  flutter:
    sdk: flutter
  getx_distil:
    path: ../getx_distil # 로컬 개발용 경로 설정
```

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

#### 📖 값 읽기 / 쓰기 — 두 가지 방식 모두 지원

`getx_distil`은 기존 GetX의 `.value` 방식을 그대로 지원하면서, 더 간결한 **Callable Rx** 방식을 추가로 제공합니다. 어느 쪽을 사용해도 동작은 완전히 동일합니다.

| 동작 | 기존 `.value` 방식 (오리지널 GetX 호환) | Callable 방식 (getx_distil 추가) |
|------|--------------------------------------|----------------------------------|
| 읽기 | `count.value` | `count()` |
| 쓰기 | `count.value = 10` | `count(10)` |
| null 쓰기 | `name.value = null` | `name(null)` |

```dart
class CounterController extends GetxController {
  final count = 0.obs;
  final name = Rxn<String>();

  void incrementByValue() {
    // 기존 .value 방식 — 오리지널 GetX와 동일
    count.value = count.value + 1;
    name.value = 'Flutter';
  }

  void incrementByCallable() {
    // Callable 방식 — 더 간결하게 동일한 동작 수행
    count(count() + 1);
    name('Flutter');
  }
}
```

#### 💡 오리지널 GetX 대비 핵심 개선점
* **Callable Rx**: getter/setter를 별도로 선언하지 않고 `count()` / `count(10)` 으로 바로 읽고 씁니다.
* **Nullable Rx (`Rxn<T>`) null 처리 완벽 지원**: `name(null)` 또는 `name.value = null`로 명시적 null 상태를 안전하게 주입할 수 있습니다.
* **Fast-Path 플래그를 통한 렌더링 부하 최소화**:
  * UI 리빌드가 일어나지 않는 일반 비즈니스 로직(연산, 데이터 가공 루프 등) 중에는 반응형 변수를 조회하더라도 복잡한 프록시 및 static 멤버 탐색을 우회하는 **`Notifier.isTracking` 고속 트랙**을 적용하여 연산 부하를 최소화했습니다.

#### 🚨 Obx 사용 시 정밀 리빌드(Targeted Rebuild) 가이드
* **Scaffold 전체를 Obx로 감싸지 마세요!**: 값이 변하지 않는 정적 UI 뼈대까지 통째로 리빌드되어 프레임 드랍이 발생할 수 있습니다.
* **올바른 최적화 패턴**: `Scaffold`나 공통 레이아웃은 `Obx` 밖에 배치하고, **실제로 값이 변하는 최하위 개별 위젯만 핀포인트로 `Obx`로 감싸서 격리**해야 합니다.

```dart
// 핀포인트 Obx 예시 — .value 방식과 Callable 방식 모두 Obx 안에서 동작
Obx(() => Text(
  '${controller.count.value}',   // .value 방식
  // 또는: '${controller.count()}' — Callable 방식
  style: Theme.of(context).textTheme.headlineMedium,
))
```

---

### 2. 🧵 GetView & Scoped DI (의존성 주입 및 뷰)
전역 싱글톤 중심의 오리지널 GetX와 달리, `getx_distil`은 Flutter 위젯 트리의 스코프를 철저히 따르며 타입 안전한 의존성 주입을 지향합니다.

#### 💡 오리지널 GetX 대비 핵심 개선점 및 차이점
* **Expando를 통한 Context 캡처 및 스레드 세이프 룩업**:
  * `GetView<T>` 내부에서 비동기 빌드나 중첩된 `Obx` 빌더 구조 속에서도 타이밍 이슈 없이 정확한 부모 `BindingWidget`의 컨트롤러 인스턴스를 찾을 수 있도록 내부적으로 `Expando<BuildContext>`를 도입하여 스레드 세이프한 생명주기 바인딩을 적용했습니다.
* **위젯 트리 기반의 자동 생명주기 제어**:
  * 전역 메모리에 무기한 상주하는 싱글톤 방식과 달리, 페이지(`Route`)가 닫혀 위젯 트리에서 해제되면 해당 스코프를 담당하던 `BindingWidget`에 묶여 있던 컨트롤러들도 **자동으로 `onClose()` 라이프사이클을 수행하며 GC(가비지 컬렉션)에 의해 완전히 수거**됩니다.
* **생성자 주입 (Constructor Injection) 기반의 Type-Safe DI**:
  * 오리지널 GetX의 글로벌 지연 주입(`Get.lazyPut`, `Get.put`) 대신, 라우팅 시점(예: `GoRouter` builder)에서 추출한 매개변수를 `Bind` 공장을 통해 **컨트롤러 생성자에 직접 전달(Constructor Injection)**하는 구조를 권장합니다. 이를 통해 컴파일 타임에 완벽한 타입 안전성을 획득할 수 있습니다.

```dart
// GoRouter 쿼리 파라미터를 컨트롤러 생성자에 직접 안전하게 주입
GoRoute(
  path: '/settings',
  builder: (context, state) {
    final userRole = state.uri.queryParameters['user'] ?? 'Guest';
    return BindingWidget(
      bindings: [
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

## 📁 예제 애플리케이션 (`.\example`)
더욱 고도화된 실제 활용 방법은 `example` 디렉토리에 정의된 **글래스모피즘 주식 대시보드** 앱에서 확인하실 수 있습니다.
- **실시간 가격 피드 디스플레이** (고주파 FIFO 스트림 시연)
- **로컬 다국어 번역 시스템** (`String.tr` 연동)
- **전역 다크 모드 핫 토글** 및 `GoRouter` 통합 연동

자세한 내용은 [Example README](file:///c:/Users/kerbe/Projects/getx_distil/example/README.md) 파일을 참고해 주세요.
