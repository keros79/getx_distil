# 📊 getx_distil 예제 애플리케이션 (Example App)

이 프로젝트는 `getx_distil` 패키지의 뛰어난 **요소 단위 반응성(Element-Level Reactivity)**과 **위젯 계층 스코프 의존성 주입(Scoped DI)** 기능들을 실생활 비즈니스 화면에 적용하여 검증할 수 있도록 제작된 **고품질 글래스모피즘 주식 대시보드 데모 앱**입니다.

---

## 🎨 화면 디자인 및 특징 (Design & Key Specs)

1. **프리미엄 다크 글래스모피즘 (Glassmorphism)**: 
   - 네온 광택 효과가 적용된 현대적이고 세련된 대시보드 카드 UI.
   - `Theme.of(context)`에 완벽히 연동되는 동적 다크/라이트 테마 변경 모드.
2. **선택적 위젯 리빌드 기법 (Targeted Obx)**:
   - 전체 화면(`Scaffold`) 대신, 상태 변화가 일어나는 텍스트 및 개별 버튼 카드 내부만 `Obx`로 정밀 바인딩하여 렌더링 리소스를 극도로 절약합니다.
3. **선언적 라우팅 및 계층 스코프 의존성 주입**:
   - `GoRouter`를 이용한 멀티 라우트 세팅.
   - 각 페이지 단위로 필요한 컨트롤러를 독립적으로 주입하는 `BindingWidget` 구조 시연.

---

## 💻 주요 구현 기능 (Key Features implemented)

- **실시간 고주파 시세 스트림 (Price Stream)**:
  - 1초 이하의 매우 빠른 주기로 변동하는 가상 주식 가격 피드.
  - `updateSequential` 비동기 FIFO 큐 파이프라인을 통하여 상태 불일치 없이 시세를 안전하고 안정적으로 출력합니다.
- **반응형 테마 스위치 (Visual Preferences)**:
  - 앱바 및 설정 카드에서 라이트/다크 모드를 실시간으로 교차 토글합니다.
- **동적 로컬라이제이션 번역 스위치 (Localization)**:
  - `Translations` 사전과 `String.tr` 메서드를 결합하여 영어(US)와 한국어(KR) 간의 애플리케이션 번역을 새로고침 없이 즉시 교체합니다.

---

## 🚀 실행 및 디버깅 방법 (Running & Debugging)

### 1. 패키지 의존성 설치
터미널에서 `example` 폴더로 진입한 후 의존성을 다운로드합니다:
```bash
cd example
flutter pub get
```

### 2. VS Code에서 Microsoft Edge로 디버깅 실행 (추천)
작업 공간 루트에 구성된 `.vscode/launch.json` 설정을 통하여 웹 브라우저에서 편리하게 디버깅 및 핫 리로드(Hot Reload)를 테스트할 수 있습니다.
- VS Code의 **실행 및 디버그 (Ctrl + Shift + D)** 탭으로 이동합니다.
- 상단 드롭다운 구성 메뉴에서 **`example (Edge)`** 또는 **`example (Chrome)`**을 선택합니다.
- `F5` 키를 눌러 디버깅 세션을 가동합니다.

### 3. 터미널 명령어로 직접 실행
```bash
flutter run -d edge
```

---

# 📂 프로젝트 구조 (Directory Structure)

```
example/
├── lib/
│   ├── main.dart                 # GoRouter 및 앱 최상위 GetMaterialApp 구성
│   └── src/
│       ├── config/
│       │   └── app_config.dart   # 전역 라이트/다크 모드 상태 (isDarkMode.obs)
│       └── views/
│           ├── dashboard_controller.dart # 고주파 피드 및 카운터 비즈니스 로직
│           ├── dashboard_page.dart       # 실시간 시세 및 메트릭 화면 (GetView)
│           ├── settings_controller.dart  # 언어 교체 및 테마 토글 제어 로직
│           └── settings_page.dart        # 시스템 환경설정 제어 카드 뷰 (GetView)
└── test/
    └── widget_test.dart          # 예제 앱 단위 렌더링 연동 스모크 테스트
```

---

## ⚠️ 대형 프로젝트에서의 아키텍처 가이드 (Enterprise Best Practices)

대형 프로젝트에서 `getx_distil`을 성공적으로 운용하기 위해 다음 핵심 가이드를 반드시 준수해 주세요:

### 🚨 **Scaffold 전체를 Obx로 감싸지 마세요! (Do not wrap the entire Scaffold in Obx)**
* **이유**: `Scaffold` 전체를 `Obx`로 감싸게 되면, 하위의 작은 데이터 하나가 변경될 때마다 화면 전체와 그 안의 수많은 정적 위젯(앱바, 드로어, 폼 필드, 텍스트 스타일 등)이 불필요하게 통째로 리빌드(Rebuild)됩니다. 이는 대규모 페이지에서 프레임 드랍(FPS 저하)과 불필요한 CPU 소모를 일으키는 가장 큰 원인입니다.
* **올바른 사용법**: `Scaffold`와 전체 페이지 골격은 `Obx` 밖에 배치하고, **실제로 값이 바뀌는 최하위 개별 위젯(텍스트, 상태 아이콘, 카운터 보드 등)만 핀포인트로 `Obx`로 감싸서 격리**해야 합니다.

