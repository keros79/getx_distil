import 'package:flutter/widgets.dart';
import '../rx/rx_core.dart';

abstract class ObxStatelessWidget extends StatelessWidget {
  const ObxStatelessWidget({super.key});

  @override
  StatelessElement createElement() => ObxElement(this);
}

class ObxElement extends StatelessElement {
  ObxElement(super.widget);

  final List<VoidCallback> disposers = [];

  void getUpdate() {
    if (mounted) {
      markNeedsBuild();
    }
  }

  @override
  Widget build() {
    _cleanup();
    return Notifier.instance.append(
      NotifyData(updater: getUpdate, disposers: disposers),
      super.build,
    );
  }

  void _cleanup() {
    for (final disposer in disposers) {
      disposer();
    }
    disposers.clear();
  }

  @override
  void unmount() {
    _cleanup();
    super.unmount();
  }
}

abstract class ObxWidget extends ObxStatelessWidget {
  const ObxWidget({super.key});
}

typedef WidgetCallback = Widget Function();

class Obx extends ObxWidget {
  final WidgetCallback builder;

  const Obx(this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    return builder();
  }
}
