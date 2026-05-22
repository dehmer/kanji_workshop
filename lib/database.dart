import 'dart:io';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

const databaseName = "jisho.db";

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

  Future<List<List<Offset>>> strokes(
    String literal, {
    double targetDimension = 180.0,
  }) async {
    final sourceDimension = 110.0;
    final factor = targetDimension / sourceDimension;
    double scale(double num) => num * factor;
    Offset offset(tuple) => Offset(tuple[0], tuple[1]);

    final delimiter = RegExp(r'[ ML]');
    List<double> split(String s) {
      final [_, ...tokens] = s.split(delimiter);
      return tokens.map((token) => double.parse(token)).toList();
    }

    List<List<T>> splitEvery<T>(int n, List<T> list) {
      int idx = 0;
      List<List<T>> acc = [];

      while (idx < list.length) {
        acc.add(list.sublist(idx, idx += n));
      }

      return acc;
    }

    final database = await instance.database;
    final result = await database.rawQuery(
      "SELECT path FROM stroke WHERE literal = '$literal' ORDER BY idx",
    );

    List<Offset> parse(Map<String, Object?> row) {
      final path = split(row['path']!.toString()).map(scale).toList();
      return splitEvery(2, path).map(offset).toList();
    }

    return result.map(parse).toList();
  }
}
