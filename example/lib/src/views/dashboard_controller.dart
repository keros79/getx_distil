import 'dart:async';
import 'package:getx_distil/get.dart';

class DashboardController extends GetxController {
  final counter = 0.obs;
  final price = 50000.0.obs;
  final status = "Stable".obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // Simulate a high-frequency real-time pricing feed
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _simulatePriceUpdate();
    });
  }

  void increment() {
    counter.value++;
  }

  Future<void> _simulatePriceUpdate() async {
    // Concurrent updates chained sequentially using FIFO updateSequential queue
    price.updateSequential((currentValue) async {
      // Add a simulated async delay
      await Future.delayed(const Duration(milliseconds: 50));
      final double change = (0.5 - (timerRandom() % 10) / 10.0) * 100.0;
      final newPrice = currentValue + change;
      status.value = change >= 0 ? "Bullish" : "Bearish";
      return double.parse(newPrice.toStringAsFixed(2));
    });
  }

  int _seed = 45678;
  int timerRandom() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
