import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../../get.dart';

class GetViewElement<T> extends StatelessElement {
  GetViewElement(GetView<T> super.widget);

  @override
  Widget build() {
    GetView.contexts[widget] = this;
    return super.build();
  }

  @override
  void update(StatelessWidget newWidget) {
    final oldWidget = widget;
    GetView.contexts[oldWidget] = null;
    super.update(newWidget);
    GetView.contexts[newWidget] = this;
  }

  @override
  void unmount() {
    GetView.contexts[widget] = null;
    super.unmount();
  }
}

abstract class GetView<T> extends StatelessWidget {
  const GetView({super.key});

  @visibleForTesting
  static final contexts = Expando<BuildContext>();

  T get controller {
    final context = contexts[this];
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
