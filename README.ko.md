# getx_distil

**Flutter를 위한 간결한 반응형 상태관리 및 하이브리드 의존성 주입(DI) 아키텍처입니다.**

`getx_distil`은 GetX를 생산적으로 만들었던 개발자 경험인 `.obs`, `Obx`, `Get.find`, Worker, Controller를 유지하면서, **기능의 소유권, 위젯 트리의 수명, 의존성의 scope를 명확하게 표현**하도록 설계되었습니다.

이 라이브러리는 다음과 같은 실무 질문에서 출발합니다.

> **이 상태는 어느 View가 소유하는가? 이 기능에는 어떤 의존성이 필요한가? 해당 객체는 언제 dispose되어야 하는가?**

`getx_distil`은 단순히 Widget과 Provider를 연결하는 데 그치지 않고, 하나의 기능을 다음과 같은 composition 단위로 표현할 수 있습니다.

```text
Route / Feature
 ├─ View
 ├─ Controller
 ├─ Dependencies
 └─ Lifetime
```

앱 전체에서 사용하는 서비스는 전역으로 유지하고, 화면 전용 Controller는 위젯 트리에 scope할 수 있습니다. 애플리케이션 전체에 하나의 수명 관리 모델만 강제하지 않습니다.

## 왜 getx_distil인가?

### 1. View와 Controller의 소유권을 한눈에 표현합니다

많은 Provider 기반 아키텍처에서는 View와 View를 구동하는 상태가 여러 파일에 나뉘고, 여러 Provider 선언을 통해 연결됩니다. 이 분리는 재사용 가능한 상태 그래프를 만들 때 유용하지만, 하나의 기능이 어떤 객체를 소유하고 언제 종료되는지 파악하기 어렵게 만들 수 있습니다.

`getx_distil`은 기능 경계에서 이 관계를 선언할 수 있게 합니다.

```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => BindingWidget(
    bindings: [
      Bind<SettingsController>(() => SettingsController()),
    ],
    child: const SettingsPage(),
  ),
),
```

이 route 정의만으로 기능의 핵심 구조를 즉시 확인할 수 있습니다.

| 관심사 | 선언 위치 |
|---|---|
| View | `SettingsPage` |
| 상태 소유자 | `SettingsController` |
| Scope | `BindingWidget` 하위 트리 |
| Dispose 경계 | `BindingWidget` unmount |

Binding은 단순한 factory 등록이 아닙니다. **객체의 소유권과 수명을 정의하는 경계**입니다.

### 2. 전역 DI와 Tree-scope DI를 함께 사용합니다

실제 애플리케이션은 하나의 수명만으로 구성되지 않습니다. 인증, 저장소, API client, analytics는 보통 앱 전체에서 사용됩니다. 반면 검색 상태, 폼 상태, 상세 화면 Controller, 임시 workflow는 특정 기능이나 화면 인스턴스에 속하는 경우가 많습니다.

`getx_distil`은 두 모델을 모두 지원합니다.

```text
Application lifetime
 └─ GetMaterialApp bindings / Get.put / Get.lazyPut

Feature or screen lifetime
 └─ BindingWidget tree scope
```

이는 전역 DI에서 scoped DI로 강제 전환하는 구조가 아닙니다. 두 lifetime 모델을 실제 객체의 수명에 맞춰 함께 사용하는 **하이브리드 DI 아키텍처**입니다.

### 3. 상태 코드를 작고 직접적으로 유지합니다

```dart
class CounterController extends GetxController {
  final count = 0.obs;

  void increment() => count.value++;
}

class CounterPage extends GetView<CounterController> {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Text('${controller.count.value}'));
  }
}
```

전체 상태 변경 경로가 코드에 직접 드러납니다.

```text
count 변경 → count를 읽은 Obx만 rebuild
```

이러한 낮은 보일러플레이트는 단순히 작성 편의성만 높이지 않습니다. 계층을 줄이면 팀이 상태의 소유권, 코드 리뷰 범위, 디버깅 경로를 더 쉽게 이해할 수 있습니다.

### 4. 비동기 UI 상태를 하나의 상태 객체로 관리합니다

`RxS`와 `RxSList`은 데이터와 일반적인 UI 상태를 함께 관리합니다. 데이터, loading, empty, error를 각각 별도의 Observable로 만들 필요가 없습니다.

```dart
final users = <User>[].ops;

await users.load(() => api.fetchUsers());
```

리스트는 다음 상태 전이를 관리합니다.

```text
idle → loading → loaded / empty
                 └→ error, 이전 데이터는 유지
```

이 구조는 서로 독립적으로 변경되는 flag의 수를 줄입니다. 따라서 `isLoading == false`인데 현재 상태가 empty인지 error인지 불명확한 식의 모순된 상태 조합도 줄일 수 있습니다.

## 설치

`pubspec.yaml`에 패키지를 추가합니다.

```yaml
dependencies:
  getx_distil: ^1.4.1
```

그리고 패키지를 import합니다.

```dart
import 'package:getx_distil/getx_distil.dart';
```

## 빠른 시작

### `Rx`와 `Obx`를 사용한 반응형 상태

```dart
class User {
  User({required this.name});
  String name;
}

class HomeController extends GetxController {
  final count = 0.obs;
  final isLoggedIn = false.obs;
  final user = User(name: 'Guest').obs;
  final tags = <String>[].obs;

  void increment() => count.value++;

  void addTag(String tag) => tags.add(tag);
}
```

`Obx`는 실제로 필요한 최소 영역에 사용하는 것이 좋습니다.

```dart
Obx(() => Text('${controller.count.value}'));

Obx(() => Switch(
  value: controller.isLoggedIn.value,
  onChanged: (value) => controller.isLoggedIn.value = value,
));
```

`Obx`는 동기적인 build 과정에서 읽힌 반응형 값을 추적합니다. 비동기 작업은 `Obx` builder가 아니라 Controller나 별도 service에서 실행하세요.

### `GetBuilder`를 사용한 명령형 업데이트

Controller가 일반 필드를 소유하고 rebuild 시점을 직접 결정해야 한다면 `GetBuilder`를 사용합니다.

```dart
class CartController extends GetxController {
  int total = 0;
  int badge = 0;

  void addItem() {
    total++;
    badge++;
    update();
    update(['badge']);
  }
}

GetBuilder<CartController>(
  builder: (controller) => Text('Total: ${controller.total}'),
);

GetBuilder<CartController>(
  id: 'badge',
  builder: (controller) => Text('${controller.badge}'),
);
```

`update()`는 id가 없는 builder를 알립니다. `update(['badge'])`는 해당 id 그룹만 알립니다.

## 하이브리드 의존성 주입

### 앱 전체에서 사용하는 전역 Binding

애플리케이션 수명을 가져야 하는 의존성은 `GetMaterialApp.bindings`에 등록합니다. 이 Binding은 앱 루트에서 eager하게 설치됩니다.

```dart
class AppConfig extends GetxService {
  final apiBaseUrl = 'https://api.example.com';
}

class AuthService extends GetxService {
  bool isSignedIn = false;
}

void main() {
  runApp(
    GetMaterialApp(
      bindings: [
        Bind<AppConfig>(() => AppConfig()),
        Bind<AuthService>(() => AuthService()),
      ],
      home: const AppRoot(),
    ),
  );
}
```

전역 service는 `BuildContext` 없이 조회할 수 있습니다.

```dart
final auth = Get.find<AuthService>();
```

기존 GetX와 같은 전역 registry도 사용할 수 있습니다.

```dart
Get.put<ApiClient>(ApiClient());
Get.lazyPut<AnalyticsService>(() => AnalyticsService());
Get.lazyPut<SessionService>(() => SessionService(), fenix: true);

final api = Get.find<ApiClient>();
```

전역 등록은 애플리케이션 수명이 실제로 필요한 객체에 의도적으로 사용하세요. 전역 참조 자체가 항상 메모리 누수인 것은 아닙니다. 중요한 것은 해당 객체의 의도된 lifetime이 정말 앱 전체인지 여부입니다.

### 화면·기능 단위의 scoped Binding

특정 위젯 하위 트리, route, feature, 화면 인스턴스에 속하는 의존성은 `BindingWidget`에 등록합니다.

```dart
GoRoute(
  path: '/profile/edit',
  builder: (context, state) => BindingWidget(
    bindings: [
      Bind<EditProfileController>(() => EditProfileController()),
    ],
    child: const EditProfilePage(),
  ),
),
```

Controller는 가장 가까운 tree scope에서 조회할 수 있습니다.

```dart
class EditProfilePage extends GetView<EditProfileController> {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Text(controller.status.value));
  }
}
```

`BindingWidget`이 dispose되면 scoped `GetxController` 인스턴스에 lifecycle teardown이 실행되고 active scoped registry에서 제거됩니다. 일반적인 화면 단위 scope에서는 짝이 되는 수동 `Get.delete()`를 작성할 필요가 없습니다.

Scope가 mount될 때 모든 Binding을 즉시 생성하려면 `eager`를 사용합니다.

```dart
BindingWidget(
  eager: true,
  bindings: [
    Bind<FeatureController>(() => FeatureController()),
  ],
  child: const FeaturePage(),
),
```

기본값에서는 처음 조회될 때 Binding이 생성됩니다.

### 하이브리드 조회 규칙

`Get.find`는 scope-aware 조회와 전역 조회를 모두 지원합니다.

```dart
// 가장 가까운 BindingWidget을 우선하고, 없으면 전역 등록을 조회합니다.
final local = Get.find<EditProfileController>(context: context);

// context가 없으면 전역 registry를 우선합니다.
final service = Get.find<AuthService>();
```

실무적인 기준은 다음과 같습니다.

| 의존성 | 권장 등록 방식 |
|---|---|
| `AuthService`, `ApiClient`, storage, analytics | `GetMaterialApp.bindings` 또는 전역 registry |
| 하나의 feature에서 공유하는 repository | feature-level `BindingWidget` 또는 전역 registry |
| 목록·상세·폼 Controller | screen-level `BindingWidget` |
| 임시 wizard 또는 workflow 상태 | local tree scope |
| 동일 화면의 여러 인스턴스 | 각각 별도의 `BindingWidget` scope |

Scoped DI는 의도적으로 tag를 사용하지 않습니다. 위젯 트리의 위치가 인스턴스를 식별하기 때문입니다. `tag:`는 전역 registry에서 사용할 수 있습니다.

```dart
Get.put<Logger>(Logger(), tag: 'payments');
final logger = Get.find<Logger>(tag: 'payments');
```

여러 active scope에 같은 타입이 등록되어 context 없는 scoped 조회가 모호해지는 경우에는 `context:`를 전달하여 위젯 트리가 올바른 인스턴스를 결정하도록 하세요.

## 상태 인지형 반응형 상태

### `RxSList`

`RxSList`은 `idle`, `loading`, `loaded`, `empty`, `error` 상태를 함께 가지는 `RxList`입니다.

```dart
final products = <Product>[].ops;

await products.load(
  () => api.fetchProducts(),
  errorMessage: (error) => '상품을 불러올 수 없습니다',
);
```

상태를 선언적으로 바인딩합니다.

```dart
Obx(() => products.on(
  idle: () => const Text('검색을 시작하세요'),
  loading: () => const CircularProgressIndicator(),
  loaded: (items) => ProductList(items),
  empty: () => const Text('상품이 없습니다'),
  error: (message) => Text(message ?? '알 수 없는 오류'),
));
```

`load()`가 실패해도 기존 리스트 데이터는 유지됩니다. `load()`는 단조 증가 request token을 사용하므로 오래된 overlapping 응답이 최신 응답을 덮어쓰지 않습니다.

페이징은 다음과 같이 사용할 수 있습니다.

```dart
await products.loadMore(() => api.fetchProducts(page: nextPage));
```

`loadMore()`는 기존 리스트를 초기 `loading` 상태로 전환하지 않고 반환된 페이지를 이어 붙입니다. 반복적인 paging 호출은 사용하는 페이지 프로토콜에 맞게 호출자에서 조정하거나 guard하세요.

### `RxS`

비동기 lifecycle을 가지는 nullable 또는 non-nullable 단일 값에는 `RxS`를 사용합니다.

```dart
final profile = RxS<User?>(null);

await profile.load(() => api.fetchProfile());

Obx(() => profile.on(
  idle: () => const Text('프로필을 불러오지 않음'),
  loading: () => const CircularProgressIndicator(),
  loaded: (user) => Text(user?.name ?? 'Guest'),
  error: (message) => Text(message ?? '오류'),
));
```

`value`를 설정하면 상태는 `loaded`로 전환됩니다. `setError`를 호출하면 error 상태 아래에 현재 값이 유지됩니다.

## 반응형 컬렉션과 batching

`RxList`, `RxMap`, `RxSet`은 같은 반응형 컬렉션 모델을 지원합니다.

```dart
final items = <String>[].obs;
final preferences = <String, bool>{}.obs;
final selectedIds = <int>{}.obs;
```

동기적인 컬렉션 변경은 하나의 microtask 알림으로 합쳐집니다.

```dart
for (final item in incomingItems) {
  items.add(item);
}
```

이 기능은 대량 변경과 초기화에 유용합니다. 이 batching 최적화는 반응형 컬렉션에 적용되며, 일반 primitive Rx 대입은 각각 별도의 알림으로 관찰됩니다.

## Worker와 Stream

Worker는 반응형 상태를 side effect와 연결합니다.

```dart
class SearchController extends GetxController {
  final query = ''.obs;
  late final Worker queryWorker;

  @override
  void onInit() {
    super.onInit();
    queryWorker = debounce(
      query,
      (value) => search(value),
      time: const Duration(milliseconds: 400),
    );
  }

  @override
  void onClose() {
    queryWorker.dispose();
    super.onClose();
  }

  Future<void> search(String value) async {
    // 여기서 검색 결과를 가져옵니다.
  }
}
```

사용 가능한 Worker는 다음과 같습니다.

```dart
ever(rx, (value) => ...);
everAll([rxA, rxB], (value) => ...);
once(rx, (value) => ...);
debounce(rx, (value) => ..., time: const Duration(milliseconds: 500));
interval(rx, (value) => ..., time: const Duration(seconds: 1));
```

Stream의 소유권이 Observable에 속하는 경우 Stream을 Observable에 연결할 수 있습니다.

```dart
final ticks = 0.obs;
ticks.bindStream(Stream.periodic(
  const Duration(seconds: 1),
  (index) => index,
));
```

연결된 subscription은 `close()` 또는 `unbindStreams()`에서 취소됩니다.

## 순차 비동기 업데이트

여러 비동기 업데이트를 FIFO 순서로 적용해야 한다면 `updateSequential`을 사용합니다.

```dart
final balance = 0.0.obs;

await balance.updateSequential(
  (current) async => current + await fetchDelta(),
);
```

오류는 await 중인 호출자에게 전달됩니다. `onError`로 현장에서 처리할 수도 있으며, 호환되는 Worker에서도 관찰할 수 있습니다.

## Lifecycle과 메모리 ownership

`getx_distil`은 DI container가 모든 참조 순환을 자동으로 제거한다고 주장하지 않습니다. 애플리케이션이 전역 service의 callback, timer, stream subscription, static collection 등에 Controller를 직접 등록하면 해당 전역 service가 Controller를 계속 참조할 수 있습니다.

`getx_distil`이 제공하는 구조적 보장은 더 구체적이며 실용적입니다.

> **화면·기능 소유 dependency에는 명시적인 위젯 트리 owner가 있으며, scope teardown은 일반적인 strong reference를 제거하고 Controller lifecycle cleanup을 호출합니다.**

의도된 lifetime이 아키텍처에 드러납니다.

```text
GetMaterialApp bindings
  → application lifetime

Feature BindingWidget
  → feature lifetime

Page BindingWidget
  → page-instance lifetime
```

결과적으로 “모든 객체가 자동으로 garbage collection된다”는 의미는 아닙니다. 전역 registry에 의존하고 모든 화면 Controller마다 수동 삭제를 기억하는 대신, 개발자가 객체의 ownership boundary를 선택할 수 있다는 의미입니다.

## Build 단계 안전성과 `Obx` 검증

Flutter의 build/layout callback 단계에서 반응형 알림이 발생하면 `getx_distil`은 UI updater를 post-frame callback으로 지연합니다. 이는 안전장치이며, build method 안에서 상태 변경하는 패턴을 권장한다는 뜻은 아닙니다.

`Obx` builder는 동기적으로 유지하세요.

```dart
// 올바른 방식: 비동기 작업은 builder 밖에서 실행합니다.
Obx(() => Text(controller.title.value));
```

`Obx` builder가 `Future`를 반환하면 잘못된 tracking scope를 조용히 만들지 않고 설명이 포함된 `FlutterError`를 발생시킵니다.

## Scoped override를 사용한 테스트

Tree-scoped Binding을 사용하면 production code에 test 전용 분기를 추가하지 않고도 격리된 widget test를 작성할 수 있습니다.

```dart
abstract class UserApi {
  Future<String> fetchName();
}

class FakeUserApi implements UserApi {
  @override
  Future<String> fetchName() async => 'Test User';
}

class UserController extends GetxController {
  UserController(this.api);
  final UserApi api;
  final name = ''.obs;
}

await tester.pumpWidget(
  MaterialApp(
    home: BindingWidget(
      bindings: [
        Bind<UserApi>(() => FakeUserApi()),
        Bind<UserController>(() => UserController(Get.find<UserApi>())),
      ],
      child: const UserPage(),
    ),
  ),
);
```

각 테스트는 자체 scope를 생성하고 위젯 트리와 함께 dispose할 수 있습니다. 애플리케이션 수준 동작이 필요한 테스트에서는 전역 dependency를 명시적으로 reset하거나 교체할 수 있습니다.

## getx_distil의 목표와 적용 범위

`getx_distil`은 애플리케이션이 주로 route·feature 중심의 화면 단위로 개발되고 다음을 원하는 경우에 적합합니다.

- 직접적이고 간결한 `.obs`와 `Obx` 경험;
- View–Controller–Dependency 관계의 가시성;
- 하나의 앱에서 전역 service와 화면 scoped Controller를 함께 사용;
- 문자열 tag 없이 화면 인스턴스 격리;
- loading/error/empty 상태 코드의 간결한 표현;
- 명시적 invalidation이 더 적합한 경우의 `GetBuilder` 사용.

깊게 계층화된 파생 상태, 대규모 parameterized cache, provider 수준의 override와 invalidation workflow가 애플리케이션의 중심이라면 provider graph 아키텍처가 더 적합할 수 있습니다. `getx_distil`은 모든 provider 추상화를 모방해야 유용한 것이 아닙니다. Route·Feature의 ownership 문제를 직접 해결하는 데 목적이 있습니다.

## API 개요

| 필요 사항 | API |
|---|---|
| primitive 또는 객체 반응형 상태 | `Rx`, `.obs`, `Rxn` |
| 반응형 Widget binding | `Obx` |
| 명시적인 Controller rebuild | `GetBuilder`, `update(ids)` |
| 화면·기능 scope | `BindingWidget`, `Bind<T>` |
| 앱 전체 eager binding | `GetMaterialApp(bindings: ...)` |
| 전역 또는 lazy DI | `Get.put`, `Get.lazyPut`, `Get.find` |
| 이름이 있는 전역 등록 | `tag:` |
| 상태 인지형 리스트 | `RxSList`, `.ops` |
| 상태 인지형 단일 값 | `RxS` |
| 컬렉션 batching | `RxList`, `RxMap`, `RxSet` |
| Side effect | `ever`, `everAll`, `once`, `debounce`, `interval` |
| Stream 연동 | `bindStream` |
| FIFO 비동기 mutation | `updateSequential` |
| Controller lifecycle | `GetxController`, `GetxService` |

## 1.3.x에서 1.4로 마이그레이션

`Get.find`는 named parameter를 사용합니다.

```dart
Get.find<T>(context)          // 이전
Get.find<T>(context: context) // 현재

Get.find<T>(null, 'tag')       // 이전
Get.find<T>(tag: 'tag')        // 현재
```

그 외 1.4의 동작 변경 사항은 다음과 같습니다. 초기값이 있는 `RxS`/`RxSList`는 `loaded`로 시작하며, `updateSequential`은 `onError`가 없으면 await 중인 호출자에게 예외를 다시 전달합니다. `fenix` builder는 `Get.delete` 이후에도 유지되고, `Get.put`은 대기 중인 lazy factory를 교체합니다.

## License

MIT License입니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 확인하세요.

## References

[1]: https://pub.dev/packages/getx_distil "pub.dev의 getx_distil"
[2]: https://github.com/keros79/getx_distil "getx_distil 소스 저장소"
[3]: https://getxdistil.web.app "getx_distil 프로젝트 홈페이지"
[4]: https://riverpod.dev/docs/concepts2/auto_dispose "Riverpod automatic disposal 문서"
[5]: https://riverpod.dev/docs/how_to/select "Riverpod select 및 rebuild 최적화 문서"

프로젝트 링크: [pub.dev][1] · [소스 저장소][2] · [홈페이지][3]
