import 'dart:io';
import 'dart:math';
import 'package:kanji_workshop/kanji_vg.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:kanji_workshop/polyline.dart' show PolylineList;

const databaseName = "jisho.db";

typedef KanjiInfoData = ({
  String literal,
  String meaning,
  String reading,
  String strokes,
});

Future<Database> _init() async {
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

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  factory DatabaseService() => instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _init();
    return _database!;
  }

  Future<List<int>> kankenCounts() async {
    final database = await instance.database;
    final result = await database.rawQuery(
      'SELECT count(*) AS cnt FROM kanken GROUP BY idx ORDER BY idx',
    );

    return result.map((row) => row['cnt']).toList().cast<int>();
  }

  Future<String> randomKankenLiteral(int level) async {
    final database = await instance.database;
    final counts = await kankenCounts();
    final random = Random();
    final offset = random.nextInt(counts[level - 1]);
    final result = await database.rawQuery(
      'SELECT literal FROM kanken WHERE idx = $level LIMIT 1 OFFSET $offset',
    );
    return result.first['literal'].toString();
  }

  Future<List<String>> randomKankenLiterals(int level) async {
    final database = await instance.database;
    final result = await database.rawQuery(
      'SELECT literal FROM kanken WHERE idx = $level',
    );

    final x = result.map((row) => row['literal']).toList().cast<String>();
    x.shuffle();

    return x;
  }

  Future<PolylineList> strokes(String literal) async {
    final query =
        "SELECT path FROM stroke WHERE literal = '$literal' ORDER BY idx";

    final database = await instance.database;
    final rows = await database.rawQuery(query);
    return rows.map(parseRow((n) => n / dimension)).toList();
  }

  Future<KanjiInfoData> info(String literal) async {
    final query = "SELECT * FROM kanji WHERE literal = '$literal'";

    final database = await instance.database;
    final rows = await database.rawQuery(query);
    final row = rows.first;

    // TODO: remove trailing line feed (0x0a) from database.
    String meaning(Map<String, Object?> row) => row['meaning']
        .toString()
        .substring(0, row['meaning'].toString().length - 1)
        .toUpperCase();

    String strokes(Map<String, Object?> row) =>
        '${row['strokes'].toString()} ${row['radical'].toString()} (${row['radical_no'].toString()})';

    return (
      literal: row['literal'].toString(),
      meaning: '▶︎ ${meaning(row)}',
      reading: row['yomi'].toString(),
      strokes: strokes(row),
    );
  }
}
