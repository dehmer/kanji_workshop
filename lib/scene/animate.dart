import 'dart:async' show Timer;

typedef LerpCallback = void Function(double t);
typedef VoidFunction = void Function();

void animate({required LerpCallback callback, required VoidFunction end}) {
  var t = 0.0;
  Timer.periodic(Duration(milliseconds: 16), (timer) {
    if (t < 1.0)
      callback((t += 0.2).clamp(0.0, 1.0));
    else {
      timer.cancel();
      end();
    }
  });
}
