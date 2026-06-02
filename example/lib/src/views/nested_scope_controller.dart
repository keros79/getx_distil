import 'package:flutter/foundation.dart';
import 'package:getx_distil/get.dart';

class NestedScopeController extends GetxController {
  final int depth;
  late final String instanceId;
  final localCount = 0.obs;

  NestedScopeController({required this.depth}) {
    instanceId = 'Inst_${hashCode.toString().substring(0, 4)}';
  }

  void increment() {
    localCount.value++;
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('NestedScopeController [$instanceId] (Depth: $depth) initialized');
  }

  @override
  void onClose() {
    debugPrint('NestedScopeController [$instanceId] (Depth: $depth) disposed (GC)');
    super.onClose();
  }
}
