# 🚀 getx_distil

`getx_distil`은 기존 GetX의 강력하고 직관적인 핵심 기능(반응형 상태 관리 및 의존성 주입)만을 극대화하여 정제한 **고성능 마이크로 상태 관리 및 트리 스코프 의존성 주입(DI) 라이브러리**입니다.

불필요하게 무겁고 거대한 네비게이션 오버레이, 라우팅 엔진, 커스텀 글로벌 UI 레이어들을 완전히 걷어내고, **순수 반응형 요소(Reactivity)**와 **계층적 DI(Tree-Scoped Dependency Injection)**에만 100% 집중하여 플러터 공식 생태계 및 `GoRouter` 등과 매끄럽게 호환되도록 설계되었습니다.

---

## ✨ 핵심 기능 (Key Features)

### 1. ⚡️ 초경량 반응형 코어 (`Rx` & Callable Semantics)
- `.obs` 확장자 및 `RxInt`, `RxDouble`, `RxString`, `RxBool`, `Rxn<T>` 완벽 지원.
- 오버헤드 없는 옵저버블 바인딩 및 변경 감지 메커니즘.

### 2. 🛡️ FIFO 비동기 파이프라인 (`updateSequential`)
- 고주파 비동기 상태 업데이트 상황에서 상태 역전(State Inversion) 및 레이스 컨디션(Race Condition)을 방지하는 비동기 순차 대기열(FIFO Queue)을 제공합니다.
- **적용 방식 및 권장 상황**:
  - **`rx.value = newPrice` 또는 `rx(newPrice)` (동기식 할당)**: 덮어쓰기 형태의 단순 조회 데이터 처리에 사용하여 대기열 지연(밀림) 현상 없이 최고의 실시간성을 확보할 때 사용합니다.
  - **`rx.updateSequential((current) async => ...)` (비동기 파이프라인)**: 이전 상태값을 바탕으로 순차적인 비동기 계산이나 API/DB 트랜잭션 처리가 일관되게 보장되어야 할 때 사용합니다.

### 3. 🎯 핀포인트 최적화 반응형 위젯 (`Obx`)
- Scaffold 전체를 다시 그리는 무거운 설계 대신, **상태가 실제로 바뀌는 최하위 개별 위젯만 정밀하게 다시 그리도록** 유도합니다.
- 위젯 트리가 업데이트될 때 사용되지 않는 관찰 대상(Observable)을 자동으로 해제하여 메모리 누수를 완벽하게 방지합니다.
- **기본 사용 예시**:
  ```dart
  Obx(() => Text('카운트: ${controller.count()}')) // Callable 방식
  // 또는: Obx(() => Text('카운트: ${controller.count.value}')) // 오리지널 GetX 호환 방식
  ```

### 4. 🌳 트리 스코프 DI 엔진 (`BindingWidget` & `Get.find`)
- 전역 싱글톤 중심의 원본 GetX와 달리, **Flutter 위젯 트리의 스코프를 준수하는 의존성 주입 계층**을 생성합니다.
- 화면(`Route`)이 언마운트되어 트리에서 제거될 때, 해당 스코프의 컨트롤러들도 **자동으로 `onClose()` 라이프사이클을 수행하며 가비지 컬렉션(GC)**됩니다.
- **기본 사용 예시**:
  ```dart
  BindingWidget(
    bindings: [Bind<MyController>(() => MyController())],
    child: const MyPage(),
  )
  // MyPage 내부 혹은 하위 트리에서는 Get.find<MyController>(context)로 간단히 주입받아 사용합니다.
  ```

### 5. 🧵 스레드 세이프 컨텍스트 룩업 (`GetView` & `Expando`)
- 비동기 빌드 및 중첩된 빌더(`Obx` 등) 구조 속에서도 타이밍 이슈 없이 정확한 컨트롤러 인스턴스를 찾을 수 있도록 `Expando<BuildContext>`를 활용한 스레드 세이프 생명주기 바인딩을 적용했습니다.

### 6. ⚡ Fast-Path 플래그를 통한 렌더링 부하 최소화
- UI 빌드가 일어나지 않는 일반 비즈니스 로직(연산 루프, 데이터 갱신) 중에는 반응형 변수를 조회(`reportRead`)하더라도 복잡한 프록시 및 static 멤버 탐색을 원천 우회하는 **정적 부울 플래그(`Notifier.isTracking`) 고속 트랙**을 적용하여 연산 부하를 최소화하였습니다.

### 7. 📋 고성능 반응형 리스트 (`RxList` — Dirty-Flag Auto-Batching)
- `List<E>`와 완전히 동일한 API(`add`, `remove`, `sort`, `assignAll` 등)를 사용하면서, 동일 동기 이벤트 내 발생한 **N번의 변이를 자동으로 1회의 Obx 리빌드로 압축**합니다.
- 오리지널 GetX의 고주파 쓰기 문제(루프 100회 → 리빌드 100회)를 **더티 플래그 + 마이크로태스크 파이프라인**으로 완전 해결하였습니다.
- `ever`, `once`, `debounce` 워커와 완벽 호환되며, `sort()` / `shuffle()` 등 내부 스왑 연산 역시 단 1회의 알림만 발생합니다.

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

### 4. 📋 RxList (고성능 반응형 리스트)

`RxList<E>`는 Dart 표준 `List<E>` API를 그대로 유지하면서, 고주파 쓰기 연산 시 발생하는 불필요한 UI 리빌드를 **Dirty-Flag + 마이크로태스크 자동 배칭(Auto-Batching)** 으로 원천 차단합니다.

#### 🚨 오리지널 GetX의 문제점

오리지널 GetX의 `RxList`는 루프 내 매 변이마다 즉시 `update()`를 호출하여 UI 리빌드를 폭발적으로 증가시킵니다.

```dart
// ❌ 오리지널 GetX — 루프 100회 = Obx 리빌드 100회 발생
for (final item in newItems) {
  rxList.add(item); // 매 호출마다 즉시 rebuild 발생!
}
```

#### ✅ getx_distil의 해결 방식

`getx_distil`의 `RxList`는 첫 번째 변이 시 마이크로태스크를 **단 1회** 예약합니다. 같은 동기 실행 구간 안의 이후 변이들은 더티 플래그로 인해 중복 예약이 차단되고, 동기 코드가 모두 끝난 후 마이크로태스크가 파이어되어 Obx에 정확히 **1회** 알림을 전달합니다.

```
동기 실행 구간:
  list.add(a)  → _isNotificationScheduled=false → true로 세팅, 마이크로태스크 예약
  list.add(b)  → _isNotificationScheduled=true  → 즉시 반환 (중복 차단)
  list.add(c)  → _isNotificationScheduled=true  → 즉시 반환 (중복 차단)
  ...(N번 반복)
--- 동기 구간 종료 ---
[마이크로태스크 파이어]
  refresh()       → Obx 리빌드 1회
  notifyStream()  → ever/once/debounce 콜백 1회
  _isNotificationScheduled = false  → 다음 버스트 준비 완료
```

#### 📌 선언 및 사용법

`.obs`를 리스트에 붙이면 `RxList<E>`가 반환됩니다. 기존 `List` API를 그대로 사용합니다.

```dart
class ItemController extends GetxController {
  // List<E>.obs → RxList<E> 반환 (RxT<T> on T 보다 더 구체적인 확장이 우선 적용)
  final items = <String>[].obs;

  // 루프 100회 → Obx 리빌드 정확히 1회
  void loadAll(List<String> data) {
    for (final s in data) {
      items.add(s);
    }
  }

  // 전체 교체 — assignAll도 단 1회 알림
  void refresh(List<String> fresh) {
    items.assignAll(fresh);
  }

  // sort / shuffle — ListMixin 기본 구현([]= 반복)을 override하여 1회만 알림
  void sortAZ() => items.sort();
}
```

```dart
// 위젯에서는 기존과 동일하게 사용
Obx(() => ListView.builder(
  itemCount: items.length,
  itemBuilder: (_, i) => Text(items[i]),
))
```

#### 🔧 주요 메서드 일람

| 메서드 | 동작 | 알림 횟수 |
|--------|------|----------|
| `add(e)` | 항목 추가 | 1회 (배칭) |
| `addAll(iter)` | 다수 항목 추가 | 1회 (배칭) |
| `remove(e)` | 항목 제거 (변경 시에만) | 0~1회 |
| `removeAt(i)` | 인덱스 제거 | 1회 |
| `clear()` | 전체 삭제 (비어 있으면 생략) | 0~1회 |
| `assignAll(iter)` | 전체 교체 (clear + addAll) | 1회 (배칭) |
| `list[i] = v` | 인덱스 치환 | 1회 (배칭) |
| `sort([compare])` | 정렬 | 1회 (`[]=` 반복 차단) |
| `shuffle([random])` | 무작위 섞기 | 1회 (`[]=` 반복 차단) |
| `length = n` | 길이 변경 (동일 길이면 생략) | 0~1회 |
| `rawList` | 배킹 리스트 직접 접근 (알림 없음) | 0회 |
| `value` | 전체 리스트 반환 + 의존성 등록 | — |

#### 🔗 Worker 연동

`ever`, `once`, `debounce` 워커는 `RxList`의 스트림과 완벽하게 연동됩니다. 배칭이 완료된 후 단 **1회** 콜백을 수신합니다.

```dart
// 리스트 변경 후 단 1회 ever 콜백 수신 (배치된 버스트 전체가 1회로 묶임)
final w = ever(items, (list) {
  print('변경 후 항목 수: ${list.length}');
});

// 100번 add해도 ever 콜백은 1회만 호출됨
for (int i = 0; i < 100; i++) {
  items.add('item_$i');
}
```

> **🔔 스트림 타이밍 참고:** `ever` 콜백은 마이크로태스크 2단계(배칭 flush → 브로드캐스트 스트림 전달) 후 수신됩니다. `await Future.microtask(() {})` 를 두 번 await하거나 `await Future.delayed(Duration.zero)`를 사용하면 테스트에서 콜백 수신을 보장할 수 있습니다.

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
// 2. 최상위 또는 필요한 위젯 트리 스코프에 바인딩
BindingWidget(
  bindings: [
    Bind<DatabaseService>(() => DatabaseService()),
  ],
  child: const MyApp(),
)
```

```dart
// 3. 앱 내 어디서든 주입 및 사용
// 화면 전환으로 인해 BindingWidget이 소멸되어도 DatabaseService는 메모리에 계속 생존하여 상태를 유지합니다.
final db = Get.find<DatabaseService>(context);
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

