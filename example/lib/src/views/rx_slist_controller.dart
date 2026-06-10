import 'package:getx_distil/get.dart';

/// Controller demonstrating basic usage of [RxSList] with auto-status tracking.
class RxSListController extends GetxController {
  final list = RxSList<String>();

  void loadData() {
    list.assignAll(['Apple', 'Banana', 'Cherry']);
  }

  void addItem() {
    final idx = list.length + 1;
    list.add('Item #$idx');
  }

  void clear() {
    list.clear();
  }
}
