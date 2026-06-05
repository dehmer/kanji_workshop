import 'dart:io';
import 'dart:math';
import 'dart:async' show Completer;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'kanji_vg.dart';
import 'polyline.dart' show Polyline, PolylineList;

const databaseName = "jisho.db";

typedef KanjiData = ({
  String literal,
  String meaning,
  String reading,
  String strokes,
});

typedef CompositeData = ({
  String literal,
  String kanji,
  String reading,
  String meaning,
});

class Repository {
  static Repository? _instance;
  Database database;
  static final _completer = Completer<Repository>();
  Repository._(this.database);

  static Future<Repository> getInstance() async {
    if (_instance == null) {
      final database = await _initialize();
      _instance = Repository._(database);
      _completer.complete(_instance);
    }
    return _completer.future;
  }

  static Future<Database> _initialize() async {
    var databasePath = await getDatabasesPath();
    var targetPath = join(databasePath, databaseName);
    var exists = await databaseExists(targetPath);

    if (!exists) {
      var data = await rootBundle.load(join('assets', 'db', databaseName));
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await File(targetPath).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(targetPath, version: 1);
  }

  Future<List<int>> kankenCounts() async {
    final result = await database.rawQuery(
      'SELECT count(*) AS cnt FROM kanken GROUP BY idx ORDER BY idx',
    );

    return result.map((row) => row['cnt']).toList().cast<int>();
  }

  Future<String> randomKankenLiteral(int level) async {
    final counts = await kankenCounts();
    final random = Random();
    final offset = random.nextInt(counts[level - 1]);
    final result = await database.rawQuery(
      'SELECT literal FROM kanken WHERE idx = $level LIMIT 1 OFFSET $offset',
    );
    return result.first['literal'].toString();
  }

  Future<List<String>> randomKankenLiterals(int level) async {
    final result = await database.rawQuery(
      'SELECT literal FROM kanken WHERE idx = $level',
    );

    final x = result.map((row) => row['literal']).toList().cast<String>();
    x.shuffle();

    return x;
  }

  Future<PolylineList> strokes(String literal) async {
    /// parseRow :: (double -> double) -> {k: v} -> [Offset]
    /// Parse a single row from database query containing SVG 'path' column.
    Polyline Function(Map<String, Object?>) parse(
      double Function(double) transform,
    ) {
      return (row) {
        Offset offset(tuple) => Offset(tuple[0], tuple[1]);
        final path = splitPath(row['path']!.toString()).map(transform).toList();
        return splitEvery(2, path).map(offset).toList();
      };
    }

    final query =
        "SELECT path FROM stroke WHERE literal = '$literal' ORDER BY idx";

    final rows = await database.rawQuery(query);
    return rows.map(parse((n) => n / dimension)).toList();
  }

  Future<KanjiData> info(String literal) async {
    final query = "SELECT * FROM kanji WHERE literal = '$literal'";
    final rows = await database.rawQuery(query);
    final row = rows.first;

    String meaning(Map<String, Object?> row) =>
        row['meaning'].toString().toUpperCase();

    String strokes(Map<String, Object?> row) =>
        '${row['strokes'].toString()} ${row['radical'].toString()} (${row['radical_no'].toString()})';

    return (
      literal: row['literal'].toString(),
      meaning: '▶︎ ${meaning(row)}',
      reading: row['yomi'].toString(),
      strokes: strokes(row),
    );
  }

  Future<List<CompositeData>> composite(String literal) async {
    final query = "SELECT * FROM composite WHERE literal = '$literal'";
    final rows = await database.rawQuery(query);

    CompositeData parse(Map<String, Object?> row) {
      return (
        literal: row['literal'].toString(),
        kanji: row['kanji_txt'].toString(),
        reading: row['reading_txt'].toString(),
        meaning: row['meaning_txt'].toString(),
      );
    }

    return rows.map(parse).toList();
  }
}
