import 'package:flutter/foundation.dart';
import 'package:getx_distil/get.dart';

class SelfHealingSafetyController extends GetxController {
  // 1. State for self-healing test
  final healingCount = 0.obs;
  final healingLogs = <String>[].obs;

  // 2. State for async Obx error test
  final asyncErrorCaught = false.obs;
  final errorStack = ''.obs;
  final errorGuide = ''.obs;

  void triggerBuildMutation() {
    addHealingLog('Triggering build-phase state mutation...');
    // Trigger state mutation
    healingCount.value++;
  }

  void resetAsyncError() {
    asyncErrorCaught.value = false;
    errorStack.value = '';
    errorGuide.value = '';
  }

  void simulateAsyncObxError() {
    resetAsyncError();
    
    // Simulate FlutterError being thrown when async is used inside Obx
    try {
      // Throw and catch a mock error to simulate an async call breaking the reactive tracking chain inside Obx
      throw FlutterError(
        'GetX-Distil Error: Detected an async/await call inside an Obx builder callback!\n'
        'Using await inside Obx will break the reactive tracking chain because the reactive dependencies are evaluated synchronously.\n\n'
        '👉 [Fix]: Calculate async values inside the controller, assign them to a synchronous Rx variable, and then let Obx synchronously display the Rx value.'
      );
    } catch (e) {
      asyncErrorCaught.value = true;
      errorStack.value = e.toString();
      errorGuide.value = 'Make sure all Obx functions return synchronously and avoid any await within the builder callback.';
    }
  }

  void addHealingLog(String message) {
    final timeStr = DateTime.now().toString().substring(11, 19);
    healingLogs.insert(0, '[$timeStr] $message');
    if (healingLogs.length > 5) {
      healingLogs.removeLast();
    }
  }
}
