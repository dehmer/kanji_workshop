import 'package:signals/signals_flutter.dart' show SignalsObserver;
import 'package:flutter/material.dart' show runApp;
import 'app.dart' show App;

void main() {
  SignalsObserver.instance = null;
  runApp(const App());
}
