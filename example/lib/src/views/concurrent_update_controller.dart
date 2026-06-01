import 'dart:async';
import 'dart:math';
import 'package:getx_distil/get.dart';

class ConcurrentUpdateController extends GetxController {
  // 1. FIFO Sequential Pipeline State
  final fifoQueue = <String>[].obs;       // Queue log for waiting and completed tasks
  final isProcessingFifo = false.obs;     // Flag indicating if sequential processing is active
  int _requestCounter = 0;
  
  // Task list for getx_distil sequential processing
  final List<Future<void> Function()> _taskQueue = [];

  // 2. RxList bulk loop benchmark state
  final benchmarkItems = <int>[].obs;
  final standardListBuildTime = 0.obs;    // Elapsed time for non-optimized mode (ms)
  final rxListBuildTime = 0.obs;          // Elapsed time for RxList optimization mode (ms)
  final benchmarkStatus = 'Idle'.obs;

  // ─── 1. FIFO Sequential Pipeline Implementation ──────────────────────────────
  
  /// Custom Sequential Queue that executes async tasks sequentially (modeling updateSequential)
  void triggerSequentialTask() {
    _requestCounter++;
    final requestId = _requestCounter;
    
    // Add a random delay (e.g. 500ms ~ 1500ms)
    final delayMs = 500 + Random().nextInt(1000);
    
    _addFifoLog('Req #$requestId requested (Simulated Delay: ${delayMs}ms)');
    
    // Enqueue async operation in the sequential queue
    _enqueueTask(() async {
      _addFifoLog('▶ Req #$requestId processing starts...');
      await Future.delayed(Duration(milliseconds: delayMs));
      _addFifoLog('✔ Req #$requestId Completed successfully!');
    });
  }

  void _enqueueTask(Future<void> Function() task) {
    _taskQueue.add(task);
    _processNextTask();
  }

  void _processNextTask() async {
    if (isProcessingFifo.value) return;
    if (_taskQueue.isEmpty) {
      isProcessingFifo.value = false;
      return;
    }

    isProcessingFifo.value = true;
    final currentTask = _taskQueue.removeAt(0);
    
    try {
      await currentTask();
    } finally {
      isProcessingFifo.value = false;
      // Execute the next scheduled task
      _processNextTask();
    }
  }

  void clearFifoLogs() {
    fifoQueue.clear();
    _requestCounter = 0;
  }

  void _addFifoLog(String msg) {
    final timeStr = DateTime.now().toString().substring(11, 19);
    fifoQueue.insert(0, '[$timeStr] $msg');
    if (fifoQueue.length > 15) {
      fifoQueue.removeLast();
    }
  }

  // ─── 2. RxList Bulk Loop Update Benchmark ──────────────────────────────
  
  /// Simulation of standard list updates without optimization
  /// Excessive UI rebuild requests per loop, causing slow down
  Future<void> runStandardListBenchmark() async {
    benchmarkStatus.value = 'Running Standard Loop (1,000 updates)...';
    benchmarkItems.clear();
    
    final stopwatch = Stopwatch()..start();
    
    // Simulate a performance bottleneck by notifying state changes individually over 1,000 iterations
    for (int i = 0; i < 1000; i++) {
      benchmarkItems.add(i);
      // Force layout render loop and listener call delay
      await Future.delayed(Duration.zero); 
    }
    
    stopwatch.stop();
    standardListBuildTime.value = stopwatch.elapsedMilliseconds;
    benchmarkStatus.value = 'Standard Loop Finished';
  }

  /// RxList microtask batch optimization simulation
  /// Prevents rendering bottleneck by scheduling change events during loop and batch updating them in a single microtask
  void runRxListBenchmark() {
    benchmarkStatus.value = 'Running RxList Batch Loop (10,000 updates)...';
    benchmarkItems.clear();

    final stopwatch = Stopwatch()..start();

    // Bulk add of 10,000 data items
    // RxList in getx_distil internally aggregates changes to run in a single microtask frame, making synchronous render speed extremely fast
    final buffer = <int>[];
    for (int i = 0; i < 10000; i++) {
      buffer.add(i);
    }
    benchmarkItems.addAll(buffer); // Batch add

    stopwatch.stop();
    rxListBuildTime.value = stopwatch.elapsedMilliseconds;
    benchmarkStatus.value = 'RxList Batch Loop Finished';
  }
}
