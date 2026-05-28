import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>集</title>
</head>
<style>
  body {
    font-family: sans-serif;
    font-size: 105%;
  }

  grid-container {
    display: grid;
    grid-template-columns: 120px 1fr;
    grid-template-rows: repeat(3, 1fr);
    /* grid-gap: 4px; */
  }

  grid-item:first-child {
    grid-row: 1 / 4;
    font-size: 400%;
    padding-left: 0;
    justify-content: center;
  }

  /* non-essential decorative styles */
  grid-item {
    padding-left: 8px;
    display: flex;
    /* background-color: red; */
    justify-content: left;
    align-items: center;
  }
</style>

<body>
  <!--
  literal: 集
  radical: 隹
  strokes: 12-8-4
  onyomi: シュウ
  kunyomi: あつ.まる, あつ.める, つど.う
  yomi: シュウ, あつ.まる, あつ.める, つど.う
  meaning: GATHER, MEET, CONGREGATE, SWARM, FLOCK
  -->
  <grid-container>
    <grid-item>集</grid-item>
    <grid-item>▶︎ GATHER, MEET, CONGREGATE, SWARM, FLOCK</grid-item>
    <grid-item>シュウ、あつ.まる、あつ.める、つど.う</grid-item>
    <grid-item>12-8-4 隹 (106)</grid-item>
  </grid-container>
</body>
</html>
''';

final controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..loadHtmlString(html);

class Home extends StatelessWidget {
  Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfefdfa),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfefdfa),
        title: Text('Kanji Workshop'),
      ),

      body: WebViewWidget(controller: controller),
    );
  }
}
