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

* 🌳 **100% 트리 스코프 DI 라이프사이클**
  `BindingWidget`을 통해 컨트롤러를 각각의 뷰(View)에 직접 종속시킵니다. 이는 동일한 자식 뷰/컨트롤러 쌍을 동시에 여러 개 띄워야 하는 경우, 각 컨트롤러가 서로 간섭하지 않고 독립적으로 동작하도록 설계되었습니다. 또한 수동 `Get.delete()` 없이 위젯이 트리에서 제거될 때 자동으로 안전하게 가비지 컬렉션(Auto-GC)됩니다.
* 🛡️ **빌드 단계 상태 변경 자가 치유**
  위젯 트리가 빌드되거나 레이아웃을 잡는 도중에 반응형 상태를 수정하면 일반적으로 Flutter 엔진은 `setState() during build` 치명적 크래시를 유발합니다. `getx_distil`은 이를 스스로 감지하고 UI 업데이트를 다음 포스트 프레임 콜백 큐로 알아서 안전하게 지연 처리합니다.
* 🛑 **엄격한 비동기 Obx 검증**
  `Obx` 빌더 콜백 내부에서 직접 `async/await`를 사용하는 것은 반응형 추적 고리를 끊어버리는 안티 패턴입니다. `getx_distil`은 이 실수를 실시간으로 탐지하여, 조용히 오동작하는 대신 명확한 경고가 담긴 `FlutterError`를 던져 줍니다.
* 🧵 **FIFO 비동기 파이프라인 (`updateSequential`)**
  고주파 비동기 데이터 갱신 시 발생하는 크리티컬한 데이터 순서 뒤바뀜 및 레이스 컨디션 문제를 방지하기 위해 정교한 순차 처리 대기 큐를 내장했습니다.
* 📋 **루프 대량 변경 최적화 (`RxList`)**
  루프 반복문 내에서 대량의 요소 변경이 일어날 때 매번 값 변경 이벤트를 발생시켜 화면을 무수히 리빌드하는 대신, 변경점들을 묶어 단 1회의 마이크로태스크 UI 리프레시만 예약 및 수행합니다.
* 📋 **상태 인지 반응형 리스트 (`RxSList`)**
  [`RxList`]를 확장하여 `idle`/`loading`/`loaded`/`empty`/`error` 상태를 자체 관리합니다. 모든 변경 연산이 자동으로 상태를 동기화하므로 별도의 `isLoading`/`errorMessage` 옵저버블이 필요 없습니다.
* 📦 **상태 인지 단일 값 (`RxS`)**
  [`Rxn`]을 확장하여 `idle`/`loading`/`loaded`/`error` 상태를 자체 관리합니다. nullable 단일 객체 상태에 적합하며, 값 설정 시 자동으로 `loaded`로 전환되고 error는 sticky하게 유지됩니다.
* 🔍 **직관적인 DI 디버깅 가이드**
  `Get.find`가 의존성을 찾지 못해 실패할 때 단순한 에러 스택 대신, 요청을 호출한 위젯명, 정확한 상위 조상 위젯 계층 구조 경로(Tree Path), 그리고 현재 메모리에 올라와 있는 전역/불멸 서비스 목록을 한눈에 표시해 줍니다.
* ⚡ **고속 트랙(Fast-Path) 추적 플래그 (`Notifier.isTracking`)**
  오리지널 GetX에서는 `Obx` 외부(일반 비즈니스 로직 루프, 백그라운드 연산 등)에서 반응형 변수를 단순히 읽기만 해도 매번 전역 프록시(`RxInterface.proxy`) 탐색과 null 여부 체크를 거치게 됩니다. `getx_distil`은 정적 부울 플래그 `isTracking`을 도입하여 `Obx` 빌드 중이 아닐 때는 복잡한 프록시 탐색과 등록 파이프라인을 원천적으로 우회(bypass)하도록 개선함으로써, 대량 데이터 순회 및 연산 시의 CPU 부하와 불필요한 탐색 오버헤드를 극적으로 제거했습니다.

> **[getx_distil vs GetX vs RiverPod3.0 비교](https://getxdistil.web.app/comparison)**

---

## 🛠️ 필수 컴포넌트 및 빠른 시작

### 1. 🎯 반응형 상태 관리 (`Rx` & `Obx`)
보일러플레이트가 전혀 없는 극도의 간결함으로 최하위 단말 위젯 단위 리빌드를 제어합니다.

```dart
class User {
  String name;
  User({required this.name});
}

class CounterController extends GetxController {
  // 1. 기본 타입 반응형 변수 (Primitive Observables)
  final count = 0.obs;                 // RxInt (RxInt(0)와 동일)
  final isLogged = false.obs;          // RxBool
  final balance = 0.0.obs;             // RxDouble
  final title = 'Hello'.obs;           // RxString

  // 2. 안전한 Nullable 반응형 변수 (Safe Nullable Observables)
  final name = Rxn<String>();          // Rxn<String> (초기값 null)
  final activeIndex = Rxn<int>();      // Rxn<int> (초기값 null)

  // 3. 컬렉션 타입 반응형 변수 (Collection Observables)
  final items = <String>[].obs;        // RxList<String> (변경 사항 자동 일괄 업데이트)

  // 4. 커스텀 객체 반응형 변수 (Custom Object Observables)
  final user = User(name: 'Guest').obs; // Rx<User>

  void updateState() {
    // 기본 타입 값 변경
    count.value++;                     // 업데이트 발생
    isLogged.toggle();                 // RxBool 전용 편리한 토글 헬퍼
    title.value = 'Distilled GetX';    // 값이 변경될 때만 업데이트 발생

    // Nullable 값 변경
    name.value = 'Flutter';

    // 리스트 변경 (동일 마이크로태스크 내의 모든 변경사항은 묶여서 단 1회만 UI 업데이트 트리거)
    items.add('Item ${items.length}');

    // 커스텀 객체 변경
    user.value = User(name: 'Alice');
  }
}
```

뷰 레이어 (특정 텍스트 영역만 정밀 리빌드):
```dart
Obx(() => Text('${controller.count.value}'));
```

> [!WARNING]
> **주의 (Obx 분기 처리 팁)**: `Obx` 내부에 반응형 변수(`Rx`)가 전혀 호출되지 않는 분기(예: 외부 일반 변수에 의한 조건문 분기)가 실행될 경우, 의존성 감지 누수나 예외가 발생할 수 있습니다. 따라서 **`Obx`는 실제 반응형 변수를 표현하는 최소한의 영역에만 감싸는 것**을 강력히 권장합니다.
> 
> ```dart
> // ❌ 피해야 할 패턴 (로그인 실패 분기 시 Rx 접근이 없어 에러 발생 가능)
> Obx(() => isLoggedIn 
>     ? Text(controller.userName.value) // 로그인 성공 시에만 Rx 엑세스
>     : const Text('로그인이 필요합니다.') // 로그인 안 됐을 때 Rx 엑세스 없음 -> 에러 유발
> )
> 
> //  권장 패턴 (Obx의 역할을 반응형 바인딩 위젯으로 국한)
> isLoggedIn 
>     ? Obx(() => Text(controller.userName.value)) // 반응형 필요한 곳만 Obx 적용
>     : const Text('로그인이 필요합니다.')
> ```

---

### 2. 📋 상태 인지 반응형 리스트 (`RxSList`)
[`RxList`]를 확장하여 **idle/loading/loaded/empty/error** 상태를 자체 관리하는 리스트입니다. 별도의 `isLoading`/`errorMessage` 옵저버블이 필요 없습니다 — 리스트 스스로 상태를 추적합니다.

```dart
final items = <String>[].ops; // List<T> → RxSList<T> via .ops extension
print(items.status); // RxListStatus.idle (초기값)
```

#### 상태 자동 동기화

모든 변경 연산(`add`, `assignAll`, `remove`, `clear`, `value` setter)이 자동으로 상태를 전환합니다:

```dart
items.assignAll(['apple', 'banana']); // status → loaded
items.add('cherry');                  // status stays loaded
items.clear();                        // status → empty
```

`error` 상태는 **절대 자동으로 설정되지 않습니다** — 에러 발생 시 수동으로 할당합니다. 기존 데이터가 보존된 상태에서 의도치 않게 상태가 덮어쓰여지는 것을 방지합니다:

```dart
items.setError('Network failure'); // 에러 설정 및 status를 RxListStatus.error로 변경 (데이터는 그대로 보존됩니다)
```

#### UI 바인딩 — `Obx(() => list.on(...))` 사용

`.on()`을 `Obx`로 감싸서 반응형 바인딩 — `Obx(() => list)`와 동일한 DX 패턴:

```dart
Obx(() => items.on(
  idle:    () => const Center(child: Text('대기 상태')),
  loading: () => const Center(child: CircularProgressIndicator()),
  loaded:  (data) => ListView.builder(
    itemCount: data.length,
    itemBuilder: (_, i) => Text(data[i]),
  ),
  empty:   () => const Center(child: Text('No items')),
  error:   (msg) => Center(child: Text('Oops: ${msg ?? 'Unknown error'}')),
));
```

`loaded` 콜백은 내부적으로 `Obx`로 감싸져 있어, **데이터 추가/삭제 시 추가 보일러플레이트 없이 즉시 UI가 갱신**됩니다.

#### 페이징 지원

`hasMore` + `addAll`을 조합하여 무한 스크롤 페이징 구현:

```dart
final paged = RxSList<String>();

// 첫 페이지
paged.assignAll(page1);
paged.hasMore = true;

// 이후 페이지
paged.addAll(page2);
paged.hasMore = page2.isNotEmpty; // 마지막 페이지면 false
```

`hasMore` 필드는 자체적으로 반응형(`Rx<bool>`)이므로 `Obx` 내부에서 자연스럽게 사용 가능:

```dart
Obx(() => Text(paged.hasMore ? 'More available' : 'All loaded'));
```

---

### 3. 📦 상태 인지 단일 값 (`RxS`)

[`Rxn`]을 확장하여 **idle/loading/loaded/error** 상태를 자체 관리하는 단일 값 반응형 객체입니다. 비동기 라이프사이클을 거치는 User 프로필이나 설정 같은 단일 객체 상태에 적합합니다.

```dart
final user = RxS<User?>(null); // T?로 nullable 지원
print(user.status); // RxDataStatus.idle (초기값)
```

#### 상태 자동 동기화

모든 값 변경 연산(`value` setter, `update()`)이 자동으로 상태를 `loaded`로 전환합니다:

```dart
user.value = User(name: '김철수');   // status → loaded
user.update((u) => User(name: '영희')); // status stays loaded
user.value = null;                    // status stays loaded (null도 유효한 값)
```

`error` 상태는 **절대 자동으로 설정되지 않습니다** — 에러 발생 시 수동으로 할당합니다. 기존 값이 보존된 상태에서 의도치 않게 상태가 덮어쓰여지는 것을 방지합니다:

```dart
user.setError('네트워크 연결에 실패했습니다'); // 에러 설정 및 status를 RxDataStatus.error로 변경 (현재 user 데이터는 그대로 보존됩니다)
```

#### UI 바인딩 — `Obx(() => value.on(...))` 사용

`.on()`을 `Obx`로 감싸서 반응형 바인딩 — `Obx(() => value)`와 동일한 DX 패턴:

```dart
Obx(() => user.on(
  idle:    () => const Center(child: Text('대기 상태')),
  loading: () => const Center(child: CircularProgressIndicator()),
  loaded:  (data) => Text('안녕하세요, ${data?.name ?? "게스트"}'),
  error:   (msg) => Center(child: Text('오류: ${msg ?? '알 수 없는 오류'}')),
));
```

`loaded` 콜백은 내부적으로 `Obx`로 감싸져 있어, **값 변경 시 추가 보일러플레이트 없이 즉시 UI가 갱신**됩니다.

#### Nullable 편의성

`RxS<T>`는 `Rxn<T>`를 상속받았기 때문에 nullable 값을 완벽히 지원합니다. `loaded` 콜백은 `T?` 데이터를 받으므로, 값이 있거나 null인 경우를 모두 처리할 수 있습니다:

```dart
RxS<String?> message = RxS<String?>(null);

message.value = '안녕하세요'; // loaded with value
message.value = null;          // loaded, data is null
```

---

### 4. 🚀 전역/클래식 의존성 주입 (`Get.put` & `Get.find`)
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
> 
> **Get.find() 의존성 탐색 순서:**
> 
> * **`BuildContext`가 있을 때 (`Get.find<T>(context)`):**
>   1. **전역 불멸 서비스 (Global Immortal):** 요청한 타입이 전역 `GetxService`(소멸되지 않는 위젯 스코프 서비스)인지 먼저 확인합니다.
>   2. **위젯 트리 (Widget Tree):** 위젯 트리를 상위로 거슬러 올라가며 일치하는 `BindingWidget` 스코프를 탐색합니다.
>   3. **전역 레지스트리 (Global Registry):** 전역 레지스트리(`Get.put` / `Get.lazyPut`)에서 탐색을 시도합니다.
>   4. **전역 약한 레지스트리 (Global Weak Registry):** 위젯 스코프 내에서 이미 실체화된 적이 있는 컨트롤러를 약한 참조로 매칭합니다.
> 
> * **`BuildContext`가 없을 때 (`Get.find<T>()`):**
>   1. **전역 레지스트리 (Global Registry):** 전역 레지스트리(`Get.put` / `Get.lazyPut`) 조회를 우선합니다.
>   2. **전역 불멸 서비스 (Global Immortal):** 위젯 스코프를 통해 등록된 전역 `GetxService` 인스턴스 중 일치하는 항목이 있는지 확인합니다.
>   3. **전역 약한 레지스트리 및 활성 상태 (Global Weak Registry / Active States):** 약한 참조 캐시나 활성화되어 있는 `BindingWidget` 상태를 뒤져 매칭되는 위젯 스코프 컨트롤러를 찾아(혹은 온디맨드로 생성하여) 반환합니다.
> 
> ```dart
> // 1. 컨텍스트 기반 조회 (위젯 트리 우선 탐색)
> final localController = Get.find<CounterController>(context);
> 
> // 2. 컨텍스트 없는 조회 (전역 레지스트리 우선 탐색)
> final globalController = Get.find<CounterController>();
> ```

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

### 5. 🌳 위젯 트리 스코프 의존성 주입 (`BindingWidget`)
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

### 6. 🌐 전역 불멸 서비스 (`GetxService`)
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

### 7. 🛠️ 백그라운드 부수 효과 (`Worker`)
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

### 8. 🔄 선언적 비동기 분기 처리 (`StateMixin`)
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

### 9. 🌐 다국어 및 로컬라이제이션 (`Translations` & `tr`)
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

**Case 1. `GetView`를 상속하는 페이지 (권장)**

`GetViewElement.build()`가 자동으로 `Notifier` 추적 스코프를 적용하므로, `build()` 내부에서 `.tr`을 바로 호출해도 `Get.locale(Rx)`이 자동 구독됩니다. 별도의 `Obx`가 필요 없습니다:

```dart
// GetView<T>를 상속하면 build() 전체가 Notifier 추적 스코프로 감싸집니다
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('hello'.tr),                   // ← Obx 불필요, 자동 구독
      ),
      body: Text('welcome'.trParams({'name': '홍길동'})), // ← Obx 불필요
    );
  }
}
```

**Case 2. `StatelessWidget` / `StatefulWidget` 사용 시**

`StatelessWidget`에는 Notifier 추적 스코프가 없으므로, `.tr`이 locale 변경 시 반응형으로 갱신되려면 `Obx`로 감싸야 합니다. `Scaffold` 전체를 `Obx`로 감싸면 개별 위젯마다 `Obx`를 반복하지 않아도 됩니다:

```dart
// StatelessWidget은 Scaffold 전체를 Obx로 감싸서 locale 변경 감지
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(                          // ← Scaffold 전체 Obx
      appBar: AppBar(
        title: Text('hello'.tr),                       // ← 반응형 동작
      ),
      body: Text('welcome'.trParams({'name': '홍길동'})), // ← 반응형 동작
    ));
  }
}
```

> [!TIP]
> `Obx`를 최상위 레벨(Scaffold 직계 자식)에 한 번만 사용하면 페이지 전체의 `.tr`이 모두 반응형으로 동작하므로 코드가 간결해집니다.

실시간 동적 언어 변경 (BuildContext를 통해 활성 라우트 갱신):
```dart
// 한국어로 변경
Get.locale = const Locale('ko', 'KR');

// 영어로 변경
Get.locale = const Locale('en', 'US');
```

---

## 🧪 TDD 및 테스트 용이성 (Testability)

`getx_distil`의 `BindingWidget`은 **TDD(테스트 주도 개발)** 환경에서 강력한 진가를 발휘합니다. 

기존 GetX나 전역 싱글톤 중심의 DI 라이브러리들은 테스트 환경에서 전역 메모리를 공유하기 때문에, 병렬 테스트나 다수의 테스트 케이스 실행 시 상태가 오염(State Pollution)되거나 의존성이 꼬이는 문제가 자주 발생했습니다.

`BindingWidget`은 **완전한 위젯 트리 단위의 격리된 DI 스코프**를 보장하므로, 테스트 코드에서 실제 네트워크 통신을 유발하는 API 서비스 대신 모의 객체(Mock)를 동적으로 손쉽게 갈아 끼울 수 있습니다.

### 💡 왜 TDD에 유용한가요?
1. **전역 오염 없는 독립된 테스트**: 각 테스트마다 새로운 `BindingWidget` 인스턴스가 생성되고 소멸되므로, 전역 싱글톤의 잔재가 다른 테스트에 악영향을 주지 않습니다.
2. **프로덕션 코드 변경 없음**: 테스트를 위해 View나 Controller 내부에 `isTesting` 같은 플래그 분기 코드를 추가할 필요가 없습니다. 오직 테스트 빌드 단계의 `bindings` 정의만 다르게 지정하면 됩니다.
3. **간결한 선언적 오버라이드**: 모의 서비스(Mock)를 바인딩하고 컨트롤러에 전달하는 과정이 `BindingWidget` 선언부 내에서 직관적으로 표현됩니다.

### 🛠️ TDD 위젯 테스트 작성 예시

```dart
// 1. API 서비스 인터페이스 정의
abstract class RestApiService {
  Future<String> fetchUserData();
}

// 2. 테스트용 Mock 서비스 정의
class MockRestApiService implements RestApiService {
  @override
  Future<String> fetchUserData() async => "모의(Mock) 데이터";
}

// 3. Controller 및 View 정의
class MyController extends GetxController {
  final RestApiService api;
  MyController(this.api);
  
  final data = "".obs;
  
  void load() async => data.value = await api.fetchUserData();
}

class MyPage extends GetView<MyController> {
  const MyPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => Text(controller.data.value)),
    );
  }
}

// 4. 위젯 테스트 작성 (TDD)
void main() {
  testWidgets('Mock 서비스를 주입하여 UI가 올바르게 갱신되는지 테스트', (tester) async {
    // 테스트 실행 전 DI 상태 리셋
    Get.reset();
    
    await tester.pumpWidget(
      MaterialApp(
        home: BindingWidget(
          bindings: [
            // 실제 RealRestApiService 대신 MockRestApiService 바인딩!
            Bind<RestApiService>(() => MockRestApiService()),
            Bind<MyController>(() => MyController(Get.find<RestApiService>())),
          ],
          child: const MyPage(),
        ),
      ),
    );
    
    // 컨트롤러 데이터 로드 트리거
    Get.find<MyController>().load();
    await tester.pump();
    
    // UI에 모의 데이터가 정상적으로 표시되는지 단언(Assert)
    expect(find.text('모의(Mock) 데이터'), findsOneWidget);
  });
}
```

더 구체적이고 바로 실행해 볼 수 있는 TDD 실습 코드는 [example/test/tdd_example_test.dart] 파일에서 확인하실 수 있습니다.


---

## 🚦 GoRouter와 반응형 라우트 가드 (GoRouter & Reactive Route Guard)

`getx_distil`은 자체적인 라우팅 시스템 대신 Flutter 표준 라우터 패키지인 **`GoRouter`**와의 완벽한 연동을 지향합니다. `getx_distil`의 모든 `Rx` 변수(예: `RxBool`, `Rxn` 등)는 Flutter의 표준 `ValueListenable`을 구현하고 있으므로, `GoRouter`의 `refreshListenable`에 직접 바인딩하여 반응형 라우트 가드(인증 및 권한 미들웨어)를 매우 선언적으로 구현할 수 있습니다.

### 1. 전역 인증 컨트롤러 정의

인증 세션 체크 여부(`isInitialized`)와 로그인 여부(`isLoggedIn`)를 추적하는 전역 컨트롤러입니다.

```dart
class AuthController extends GetxController {
  final isLoggedIn = false.obs;
  final isInitialized = false.obs; // 인증 검사가 완료되었는지 여부

  @override
  void onInit() {
    super.onInit();
    checkAuthSession(); // 백그라운드에서 비동기 체크 시작 (앱 구동을 블로킹하지 않음)
  }

  Future<void> checkAuthSession() async {
    await Future.delayed(const Duration(seconds: 1)); // 로컬 저장소 토큰 체크 시뮬레이션
    isLoggedIn.value = true; // 세션 존재 여부에 따라 세팅
    isInitialized.value = true; // 검사 완료 플래그 활성화
  }
}
```

### 2. main() 및 GoRouter 설정 (올바른 초기화 타이밍)

`GoRouter`를 파일 최상단 전역 변수나 클래스 static 변수로 선언하고 `refreshListenable`에서 `Get.find<AuthController>()`를 바로 호출하는 경우, 의존성 등록 시점과의 타이밍 이슈가 생길 수 있습니다. 

이를 방지하기 위해 **앱 구동 시작점인 `main()`에서 `Get.put(AuthController(), permanent: true)`을 호출하여 최우선적으로 전역 주입**한 뒤, `GoRouter`를 연동해야 합니다.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 구동 즉시 AuthController 등록 (onInit 비동기 체크가 백그라운드에서 시작됨)
  Get.put(AuthController(), permanent: true);
  
  runApp(const MyApp());
}

// GoRouter 정의
final auth = Get.find<AuthController>();

final goRouter = GoRouter(
  initialLocation: '/splash',
  // 리액티브 바인딩: 아래 Rx 값들이 바뀔 때마다 GoRouter가 자동으로 redirect()를 재호출합니다.
  refreshListenable: Listenable.merge([
    auth.isLoggedIn,
    auth.isInitialized,
  ]),
  redirect: (context, state) {
    // 1. 아직 인증 데이터 로딩이 완료되지 않았다면 스플래시 화면 유지
    if (!auth.isInitialized.value) {
      return '/splash';
    }

    final loggedIn = auth.isLoggedIn.value;
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToSplash = state.matchedLocation == '/splash';

    // 로그인 안 됨 -> 로그인 페이지로 강제 이동
    if (!loggedIn) {
      return '/login';
    }

    // 로그인 완료되었는데 스플래시나 로그인 페이지에 머물고 있다면 -> 홈으로 이동
    if (loggedIn && (isGoingToLogin || isGoingToSplash)) {
      return '/';
    }

    return null; // 리다이렉트 안 함 (목적지 그대로 이동)
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(), // 로딩 스피너 등을 띄우는 스플래시 위젯
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const BindingWidget(
        bindings: [Bind(HomeController.new)],
        child: HomePage(),
      ),
    ),
  ],
);
```

### ⚠️ 초기화 타이밍 주의 (크래시가 발생하는 예시)

`GetMaterialApp`의 `bindings` 프로퍼티는 위젯이 빌드되는 단계에서 의존성을 주입합니다. 전역 변수로 `GoRouter`를 선언하고 `refreshListenable`에서 `Get.find`를 수행하면서, `GetMaterialApp(bindings: [...])`에 의존성을 정의하면 **의존성 등록 전에 GoRouter가 평가(Evaluation)되면서 탐색 실패 크래시가 발생**합니다.

```dart
// ❌ 잘못된 예시: 의존성이 주입되기 전에 GoRouter가 먼저 Get.find를 시도하여 크래시 발생
final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: Listenable.merge([
    Get.find<AuthController>().isLoggedIn, // 🚨 여기서 에러 발생 (Not registered yet!)
  ]),
  routes: [...],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      routerConfig: router, // GetMaterialApp 빌드 시 전역 변수 router를 참조함
      bindings: [
        Bind<AuthController>(() => AuthController()), // ◀ 아직 빌드 전이라 등록 안 됨!
      ],
    );
  }
}
```

따라서 인증 컨트롤러처럼 라우트 가드에 연동되어 앱 최극초기 구동 시점에 조회되어야 하는 글로벌 핵심 서비스는 **`main()` 함수 내에서 `Get.put(..., permanent: true)`을 호출해 가장 먼저 수동 등록**하는 것이 좋습니다.

---

## 📄 라이선스

이 프로젝트는 MIT 라이선스에 따라 배포됩니다.

