import 'dart:async';
import 'package:getx_distil/get.dart';

/// 각 벤치마크 실행 결과 로그 항목
class BenchLog {
  final String label;
  final int mutations;
  final int rebuilds;
  final Duration elapsed;

  BenchLog({
    required this.label,
    required this.mutations,
    required this.rebuilds,
    required this.elapsed,
  });

  /// rebuilds / mutations 비율 (낮을수록 좋음)
  double get efficiency => mutations == 0 ? 0 : rebuilds / mutations;
}

class RxListBenchController extends GetxController {
  // ─── Observable state ──────────────────────────────────────────────────────

  /// 벤치마크 대상 반응형 리스트
  final items = <String>[].obs;

  /// Obx 가 items 를 읽을 때마다 증가
  final rebuildCount = 0.obs;

  /// 현재 실행 중 여부
  final isBusy = false.obs;

  /// 누적 로그
  final logs = <BenchLog>[].obs;

  /// ever 워커가 받은 이벤트 수
  final workerEventCount = 0.obs;

  // ─── Internal ──────────────────────────────────────────────────────────────
  Worker? _everWorker;

  // 벤치마크 배치 크기 선택지
  static const List<int> batchSizes = [10, 100, 500, 1000];
  final selectedBatch = 100.obs;

  @override
  void onInit() {
    super.onInit();
    // ever 워커 — 배칭이 올바르게 동작하면 N번 add 해도 1회만 수신
    _everWorker = ever<List<String>>(items, (_) {
      workerEventCount.value++;
    });
  }

  @override
  void onClose() {
    _everWorker?.dispose();
    super.onClose();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  /// [count]번 add() — 배칭 덕분에 Obx rebuild 1회
  Future<void> runBatchedAdd(int count) async {
    if (isBusy.value) return;
    isBusy.value = true;

    items.clear();
    rebuildCount.value = 0;
    final sw = Stopwatch()..start();

    for (int i = 0; i < count; i++) {
      items.add('item_$i');
    }

    // 마이크로태스크가 flush 될 때까지 대기 (2 라운드)
    await Future<void>.value();
    await Future<void>.value();
    sw.stop();

    logs.insert(
      0,
      BenchLog(
        label: 'add() ×$count (batched)',
        mutations: count,
        rebuilds: rebuildCount.value,
        elapsed: sw.elapsed,
      ),
    );
    if (logs.length > 20) logs.removeRange(20, logs.length);

    isBusy.value = false;
  }

  /// assignAll — 단 1회 알림
  Future<void> runAssignAll(int count) async {
    if (isBusy.value) return;
    isBusy.value = true;

    rebuildCount.value = 0;
    final sw = Stopwatch()..start();

    final newItems = List.generate(count, (i) => 'item_$i');
    items.assignAll(newItems);

    await Future<void>.value();
    await Future<void>.value();
    sw.stop();

    logs.insert(
      0,
      BenchLog(
        label: 'assignAll() ×$count',
        mutations: 1,
        rebuilds: rebuildCount.value,
        elapsed: sw.elapsed,
      ),
    );
    if (logs.length > 20) logs.removeRange(20, logs.length);
    isBusy.value = false;
  }

  /// sort — []= 반복 차단, 1회 알림
  Future<void> runSort() async {
    if (isBusy.value) return;
    isBusy.value = true;

    // 역순으로 채우고 정렬
    final count = items.isEmpty ? selectedBatch.value : items.length;
    items.assignAll(List.generate(count, (i) => 'item_${count - i}'));
    await Future<void>.value();
    await Future<void>.value();

    rebuildCount.value = 0;
    final sw = Stopwatch()..start();
    items.sort();
    await Future<void>.value();
    await Future<void>.value();
    sw.stop();

    logs.insert(
      0,
      BenchLog(
        label: 'sort() ×$count items',
        mutations: 1,
        rebuilds: rebuildCount.value,
        elapsed: sw.elapsed,
      ),
    );
    if (logs.length > 20) logs.removeRange(20, logs.length);
    isBusy.value = false;
  }

  void clearAll() {
    items.clear();
    logs.clear();
    rebuildCount.value = 0;
    workerEventCount.value = 0;
  }

  void notifyRebuild() {
    rebuildCount.value++;
  }
}
