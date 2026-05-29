import 'rx_types.dart';

extension RxT<T> on T {
  Rx<T> get obs => Rx<T>(this);
}
