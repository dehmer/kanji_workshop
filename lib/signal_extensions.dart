import 'package:signals/signals_flutter.dart';

extension SignalOps<V> on ReadonlySignal<V> {
  FlutterComputed<R> map<R>(R Function(V value) fn) =>
      computed(() => fn(value));

  FlutterSignal<V> filter(bool Function(V value)) {
    FlutterSignal<V> self = FlutterSignal<V>.lazy();
    return self;
  }
}
