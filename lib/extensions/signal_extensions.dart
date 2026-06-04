import 'package:signals/signals_flutter.dart';
import '../option.dart';

({FlutterSignal<Option<T>> signal, void Function(T) callback}) listen<T>() {
  final signal = FlutterSignal<Option<T>>(None());
  void callback(T event) => signal.value = Some(event);
  return (signal: signal, callback: callback);
}

FlutterSignal<T> merge<T>(List<ReadonlySignal<T>> signals) {
  FlutterSignal<T> self = FlutterSignal<T>.lazy();
  for (final signal in signals) {
    signal.subscribe((value) => self.value = value);
  }

  return self;
}

FlutterSignal<T> loop<T, I>(
  ReadonlySignal<I> signal,
  T Function(T, I) fn,
  T acc,
) {
  FlutterSignal<T> self = FlutterSignal<T>(acc);
  signal.subscribe((input) {
    final value = fn(self.value, input);
    self.value = value;
  });
  return self;
}

extension SignalOps<V> on ReadonlySignal<V> {
  FlutterComputed<R> map<R>(R Function(V value) fn) =>
      computed(() => fn(value));
}
