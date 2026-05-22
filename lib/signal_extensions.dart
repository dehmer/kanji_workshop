import 'package:signals/signals_flutter.dart';

extension SignalOps<V> on ReadonlySignal<V> {
  FlutterComputed<R> map<R>(R Function(V value) fn) =>
      computed(() => fn(value));
}
