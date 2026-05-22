import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'app.dart';

void main() {
  SignalsObserver.instance = null;
  runApp(const App());
}
