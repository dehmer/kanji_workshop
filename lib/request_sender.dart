import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LineStringSender {
  final String _url = 'http://192.168.178.51:3000/';

  /// Sends a list of linestrings (lists of Offsets) to the local web service.
  Future<void> sendEvents(
    String literal,
    Offset Function(Offset) scalePosition,
    List<PointerEvent> raw,
  ) async {
    final scaledPositions = raw.map(
      (event) => scalePosition(event.localPosition),
    );

    final now = raw[0].timeStamp;
    final xs = scaledPositions.map((p) => p.dx);
    final ys = scaledPositions.map((p) => p.dy);
    final fs = raw.map((event) => event.down ? 1 : 0);
    final ts = raw.map((event) => (event.timeStamp - now).inMilliseconds);
    final ps = raw.map((event) => event.pressure);

    // 2. Wrap payload in a map container if your backend expects a key
    final String body = jsonEncode({
      'literal': literal,
      'xs': xs.toList(),
      'ys': ys.toList(),
      'fs': fs.toList(),
      'ts': ts.toList(),
      'ps': ps.toList(),
    });

    // // 3. Make the HTTP POST request
    final response = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    // // 4. Check if the server received it successfully
    if (response.statusCode != 200) {
      debugPrint('Server error: ${response.statusCode} - ${response.body}');
    }
  }
}
