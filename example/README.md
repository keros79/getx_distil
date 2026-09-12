# getx_distil Example App

This demo app verifies and showcases `getx_distil` in a real Flutter project:

- **Element-level reactivity** — `.obs` / `Obx` track only the leaf widgets whose values change.
- **Widget tree-scoped DI (Scoped DI)** — every screen owns its controller via `BindingWidget` + `Bind<T>`; app-lifetime objects stay in `GetMaterialApp.bindings`.
- **RxS / RxSList status-aware state** — async screens use `idle/loading/loaded/error` instead of separate boolean flags.
- **Recommended REST stack** — the TDD screen demonstrates `dio` + `retrofit` + `freezed` (`DTO -> client -> repository -> Controller`) and is mock-overridable with `BindingWidget`.

App architecture (Feature-First + MVVM, scoped `BindingWidget`, recommended REST stack): **[docs/architecture.md](docs/architecture.md)**. Copy that file to your app's `AGENTS.md` if you want an AI agent to follow the same rules.

---

## Screens

| Route | Demo |
| --- | --- |
| `/` | Hub / test bench menu |
| `/basic-rx` | `.obs` + debounce Worker + `RxList` |
| `/nested-scope` | Nested `BindingWidget` scopes (isolated controller per push) |
| `/safety` | Build-phase self-healing + async `Obx` guard |
| `/concurrent` | `updateSequential` FIFO + `RxList` batch benchmark |
| `/rx-slist` | `RxSList` basic add/assign/clear + auto status |
| `/rx-slist-paging` | `RxSList` `addAll` + `hasMore` infinite scroll |
| `/rx-s` | `RxS` single-value status |
| `/settings` | Theme + locale (scoped `ExtraSettingsController`, global `AppConfig`) |
| `/tdd-test` | TDD target: `dio`/`retrofit`/`freezed` + `RxS` + mock repository override |

## How DI is layered

- **App lifetime** (`main.dart` -> `GetMaterialApp.bindings`): `AppConfig` (GetxService), shared `Dio`, `RestApiClient`, `UserRepository`.
- **Screen lifetime** (`core/routes/app_router.dart` -> each `GoRoute`'s `BindingWidget`): screen controllers.
- **Tests** override a screen dependency by binding a mock to the same `BindingWidget` — no production branches.

## Project structure

```text
example/
├── lib/
│   ├── main.dart                       # runApp + GetMaterialApp (bindings/theme/translations)
│   ├── core/
│   │   ├── config/app_config.dart      # global theme preference (GetxService)
│   │   ├── routes/app_router.dart      # GoRouter + per-screen BindingWidget
│   │   ├── theme/app_theme.dart        # light/dark ThemeData
│   │   └── translations/app_translations.dart
│   ├── models/
│   │   ├── data/user_dto.dart          # @freezed DTO (plus generated .g/.freezed)
│   │   └── domain/                     # UserEntity + UserRepository contract
│   ├── services/
│   │   ├── rest_api_client.dart        # @RestApi client + shared Dio
│   │   └── user_repository_impl.dart   # DTO -> Entity mapping
│   └── views/                          # one folder per feature: page + controller
│       ├── home/  basic_rx/  nested_scope/  safety/  concurrent/
│       ├── rx_slist/  rx_slist_paging/  rx_s/  extra_settings/  tdd_test/
└── test/
    ├── widget_test.dart                # smoke test
    └── tdd_example_test.dart           # BindingWidget mock override + RxS state checks
```

## Running

```bash
cd example
flutter pub get
flutter run          # e.g. -d chrome / -d edge
```

Regenerate the DTO/Retrofit code when the models or client change:

```bash
dart run build_runner build
```

## Tests

```bash
flutter analyze
flutter test
```