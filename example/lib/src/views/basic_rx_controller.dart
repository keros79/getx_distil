import 'dart:async';
import 'package:getx_distil/get.dart';

class BasicRxController extends GetxController {
  // 1. Simple reactive counter
  final count = 0.obs;

  // 2. State for search and debounce testing
  final searchQuery = ''.obs;
  final searchStatus = 'Idle'.obs;
  final searchResult = ''.obs;
  
  // 3. State for RxList add/remove testing
  final rxListItems = <String>[].obs;
  int _itemIndex = 0;

  // Reactive list to accumulate and display debounce logs
  final workerLogs = <String>[].obs;

  late final Worker _debounceWorker;

  @override
  void onInit() {
    super.onInit();
    addLog('BasicRxController initialized (onInit)');

    // Register debounce Worker (triggered when the user stops typing and waits for 500ms)
    _debounceWorker = debounce<String>(
      searchQuery,
      (query) => _performSearch(query),
      time: const Duration(milliseconds: 500),
    );
  }

  void increment() {
    count.value++;
  }

  // Add an item to RxList
  void addRxItem() {
    _itemIndex++;
    rxListItems.add('Item #$_itemIndex');
    addLog('RxList: Added "Item #$_itemIndex"');
  }

  // Remove an item from RxList
  void removeRxItem(int index) {
    if (index >= 0 && index < rxListItems.length) {
      final removed = rxListItems.removeAt(index);
      addLog('RxList: Removed "$removed"');
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      searchStatus.value = 'Idle';
      searchResult.value = '';
      return;
    }

    searchStatus.value = 'Searching...';
    addLog('Debounce Triggered! Query: "$query"');

    // Simulate search success after 1 second
    Timer(const Duration(seconds: 1), () {
      if (searchQuery.value == query) {
        searchResult.value = 'Result for "${query.toUpperCase()}" (Processed at ${DateTime.now().toString().substring(11, 19)})';
        searchStatus.value = 'Success';
        addLog('Search Finished for "$query"');
      }
    });
  }

  void addLog(String message) {
    final timeStr = DateTime.now().toString().substring(11, 19);
    workerLogs.insert(0, '[$timeStr] $message');
    if (workerLogs.length > 10) {
      workerLogs.removeLast();
    }
  }

  @override
  void onClose() {
    _debounceWorker.dispose();
    super.onClose();
  }
}
