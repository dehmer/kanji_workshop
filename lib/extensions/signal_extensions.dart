import 'dart:async';
import 'package:signals/signals_flutter.dart';

FlutterSignal<T> loop<T, I>(
  ReadonlySignal<I> signal,
  FutureOr<T> Function(T, I) fn,
  T acc,
) {
  FlutterSignal<T> self = FlutterSignal<T>(acc);
  signal.subscribe((input) async {
    self.value = await fn(self.value, input);
  });
  effect(() => self.value);
  return self;
}

extension SignalOps<V> on ReadonlySignal<V> {
  FlutterComputed<R> map<R>(R Function(V value) fn) =>
      computed(() => fn(value));
}
