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

## 🛠️ 기본 사용법 (Usage)

### 1. 반응형 컨트롤러 작성
```dart
import 'package:getx_distil/get.dart';

class CounterController extends GetxController {
  final count = 0.obs;

  void increment() {
    count.value++;
  }
}
```

### 2. 뷰 작성 (GetView & 정밀 Obx 최적화)
```dart
import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';

// GetView를 사용하여 자동으로 컨트롤러 의존성을 획득합니다.
class CounterPage extends GetView<CounterController> {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold는 Obx 외부에 배치하여 1회만 그려집니다.
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            // 값이 변화하는 텍스트 영역만 핀포인트로 Obx 감싸기
            Obx(() => Text(
              '${controller.count.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 3. 라우터 및 의존성 주입 설정 (`BindingWidget`)
```dart
import 'package:flutter/material.dart';
import 'package:getx_distil/get.dart';

void main() {
  runApp(
    GetMaterialApp(
      home: BindingWidget(
        bindings: [
          // 스코프 내에서 사용할 의존성을 레이지 바인딩
          Bind<CounterController>(() => CounterController()),
        ],
        child: const CounterPage(),
      ),
    ),
  );
}
```

### 4. 반응형 구문 확장 (.obs) 및 워커 (Workers) 활용

`getx_distil`은 편의성을 극대화하는 `.obs` 구문 설탕과 강력한 비동기 흐름 제어 장치인 **워커(Workers)** 엔진을 제공합니다.

#### ⚡ `.obs` 구문 확장 (Syntax Sugar)
모든 기본 타입 및 사용자 정의 클래스 뒤에 `.obs`를 붙여 즉시 반응형 변수로 선언할 수 있습니다:
```dart
final intVal = 10.obs;           // Rx<int> (또는 RxInt)
final doubleVal = 50.0.obs;      // Rx<double> (또는 RxDouble)
final stringVal = 'Hello'.obs;   // Rx<String> (또는 RxString)
final boolVal = true.obs;        // Rx<bool> (또는 RxBool)
final user = User().obs;         // Rx<User> (사용자 정의 객체)
```

#### 🛠️ 워커 엔진 (Workers Engine)
컨트롤러의 `onInit()` 단계 등에서 특정 반응형 변수의 변화 흐름을 감시하여 로직을 트리거할 수 있습니다. 

* **`ever(listener, callback)`**: 변수 값이 바뀔 때마다 **무조건 즉시** 콜백을 가동합니다.
* **`once(listener, callback)`**: 변수 값이 처음 바뀔 때 **딱 한 번만** 콜백을 실행하고 리스너를 자동 자원 회수합니다.
* **`debounce(listener, callback, {Duration time})`**: 값 변경 후 특정 대기시간(기본값 800ms) 동안 추가 변경이 없을 때(침묵 상태) 최종적으로 단 한 번만 콜백을 수행합니다. (예: 검색창 자동완성 API 호출 오버헤드 억제)

> [!IMPORTANT]
> **워커 자원 해제 가이드**:
> 워커 함수들은 자원 정리를 위한 `Worker` 객체를 반환합니다. 메모리 누수를 완벽히 방지하기 위해, 컨트롤러가 소멸하는 `onClose()` 단계에서 반드시 `.dispose()` 또는 `.cancel()`을 호출해 주세요.

```dart
class SearchController extends GetxController {
  final searchQuery = ''.obs;
  late final Worker _debounceWorker;

  @override
  void onInit() {
    super.onInit();
    
    // 사용자가 타자를 멈추고 500ms가 지나면 API 검색 실행 (debounce)
    _debounceWorker = debounce(
      searchQuery, 
      (query) => _performSearch(query), 
      time: const Duration(milliseconds: 500),
    );
  }

  void _performSearch(String query) {
    print('서버 검색 실행: $query');
  }

  @override
  void onClose() {
    // 🚨 워커 리스너를 안전하게 정리하여 메모리 누수 방지
    _debounceWorker.dispose();
    super.onClose();
  }
}
```

---

## ⚠️ 대형 프로젝트에서의 아키텍처 가이드 (Enterprise Best Practices)

대형 프로젝트에서 `getx_distil`을 성공적으로 운용하기 위해 다음 핵심 가이드를 반드시 준수해 주세요:

### 🚨 **Scaffold 전체를 Obx로 감싸지 마세요! (Do not wrap the entire Scaffold in Obx)**
* **이유**: `Scaffold` 전체를 `Obx`로 감싸게 되면, 하위의 작은 데이터 하나가 변경될 때마다 화면 전체와 그 안의 수많은 정적 위젯(앱바, 드로어, 폼 필드, 텍스트 스타일 등)이 불필요하게 통째로 리빌드(Rebuild)됩니다. 이는 대규모 페이지에서 프레임 드랍(FPS 저하)과 불필요한 CPU 소모를 일으키는 가장 큰 원인입니다.
* **올바른 사용법**: `Scaffold`와 전체 페이지 골격은 `Obx` 밖에 배치하고, **실제로 값이 바뀌는 최하위 개별 위젯(텍스트, 상태 아이콘, 카운터 보드 등)만 핀포인트로 `Obx`로 감싸서 격리**해야 합니다.

---

## 📁 예제 애플리케이션 (`.\example`)
더욱 고도화된 실제 활용 방법은 `example` 디렉토리에 정의된 **글래스모피즘 주식 대시보드** 앱에서 확인하실 수 있습니다.
- **실시간 가격 피드 디스플레이** (고주파 FIFO 스트림 시연)
- **로컬 다국어 번역 시스템** (`String.tr` 연동)
- **전역 다크 모드 핫 토글** 및 `GoRouter` 통합 연동

자세한 내용은 [Example README](file:///c:/Users/kerbe/Projects/getx_distil/example/README.md) 파일을 참고해 주세요.
