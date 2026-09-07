/// Declares how a [BindingWidget] scope should construct a dependency of
/// type [T].
///
/// Scoped DI is identified purely by **type + position in the widget tree**;
/// there are intentionally no tags. If you need two instances of the same
/// type, give each its own `BindingWidget` scope (or wrap them in distinct
/// types). Tags exist only for the global registry (`Get.put(tag:)`).
class Bind<T> {
  final T Function() factory;
  Type get type => T;
  const Bind(this.factory);
}
