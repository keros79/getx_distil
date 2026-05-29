import 'package:flutter/widgets.dart';
import '../../get.dart';

class GetViewElement<T> extends StatelessElement {
  GetViewElement(GetView<T> super.widget);

  @override
  Widget build() {
    GetView._contexts[widget] = this;
    return super.build();
  }

  @override
  void unmount() {
    GetView._contexts[widget] = null;
    super.unmount();
  }
}

abstract class GetView<T> extends StatelessWidget {
  const GetView({super.key});

  static final _contexts = Expando<BuildContext>();

  T get controller {
    final context = _contexts[this];
    if (context == null) {
      throw FlutterError(
        'GetView<$T>.controller was called outside of the build method, or before the build method started.'
      );
    }
    return Get.find<T>(context);
  }

  @override
  StatelessElement createElement() => GetViewElement<T>(this);
}
