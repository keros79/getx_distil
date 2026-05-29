class Bind<T> {
  final T Function() factory;
  Type get type => T;
  Bind(this.factory);
}
