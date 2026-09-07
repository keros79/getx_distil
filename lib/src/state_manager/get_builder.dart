import 'package:flutter/widgets.dart';
import '../instance/get_find.dart';
import 'getx_controller.dart';

typedef GetControllerBuilder<T extends GetxController> = Widget Function(
  T controller,
);

/// Imperative counterpart of `Obx`: rebuilds when the bound [GetxController]
/// calls `update()`.
///
/// ```dart
/// // Rebuilds on any `update()` without ids.
/// GetBuilder<CounterController>(
///   builder: (c) => Text('${c.count}'),
/// );
///
/// // Rebuilds only on `update(['badge'])`.
/// GetBuilder<CounterController>(
///   id: 'badge',
///   builder: (c) => Text('${c.badge}'),
/// );
/// ```
///
/// ### Controller resolution
/// * [init] + `global: true` (default): the controller is registered with
///   `Get.put` if `T`/[tag] is not registered yet, and deleted again on
///   dispose when this widget created it and [autoRemove] is `true`.
/// * [init] + `global: false`: the controller lives only as long as this
///   widget; `onStart` / `onDelete` are invoked here.
/// * No [init]: the controller is resolved through the hybrid
///   `Get.find<T>(context: context, tag: tag)` (nearest `BindingWidget`
///   scope first, then the global registry).
class GetBuilder<T extends GetxController> extends StatefulWidget {
  final GetControllerBuilder<T> builder;
  final bool global;
  final Object? id;
  final String? tag;
  final bool autoRemove;
  final T? init;
  final void Function(GetBuilderState<T> state)? initState;
  final void Function(GetBuilderState<T> state)? dispose;

  const GetBuilder({
    super.key,
    required this.builder,
    this.init,
    this.global = true,
    this.id,
    this.tag,
    this.autoRemove = true,
    this.initState,
    this.dispose,
  });

  @override
  GetBuilderState<T> createState() => GetBuilderState<T>();
}

class GetBuilderState<T extends GetxController> extends State<GetBuilder<T>> {
  T? _controller;
  VoidCallback? _removeListener;
  bool _isCreator = false;

  /// The resolved controller. Throws before the first `didChangeDependencies`.
  T get controller {
    final c = _controller;
    if (c == null) {
      throw FlutterError(
        'GetBuilder<$T>.controller accessed before it was resolved.',
      );
    }
    return c;
  }

  @override
  void initState() {
    super.initState();
    final init = widget.init;
    if (!widget.global) {
      if (init == null) {
        throw FlutterError(
          'GetBuilder<$T>(global: false) requires an `init` controller.',
        );
      }
      _isCreator = true;
      init.onStart();
      _attach(init);
    } else if (init != null && !Get.isRegistered<T>(tag: widget.tag)) {
      _isCreator = true;
      _attach(Get.put<T>(init, tag: widget.tag));
    }
    // Otherwise resolve via the hybrid lookup in didChangeDependencies, where
    // depending on inherited elements (BindingWidget) is permitted.
    widget.initState?.call(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _attach(Get.find<T>(context: context, tag: widget.tag));
    }
  }

  void _attach(T controller) {
    _removeListener?.call();
    _controller = controller;
    final id = widget.id;
    _removeListener = id == null
        ? controller.addListener(_onUpdate)
        : controller.addListenerId(id, _onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(GetBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id && _controller != null) {
      _attach(_controller!);
    }
  }

  @override
  void dispose() {
    widget.dispose?.call(this);
    _removeListener?.call();
    _removeListener = null;
    final c = _controller;
    if (c != null && _isCreator) {
      if (widget.global) {
        if (widget.autoRemove) Get.delete<T>(tag: widget.tag);
      } else {
        c.onDelete();
      }
    }
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(controller);
}
