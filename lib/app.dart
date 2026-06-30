import 'package:flutter/material.dart';
// import 'home_kana.dart';
import 'home_kanji.dart';

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kanji Workshow',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.lightGreen)),
      home: Home(),
    );
  }
}
