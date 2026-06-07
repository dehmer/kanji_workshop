import 'dart:async';
import 'package:flutter/foundation.dart' show immutable;
import 'repository.dart';

const levels = [
  "10",
  "9",
  "8",
  "7",
  "6",
  "5",
  "4",
  "3",
  "Pre-2",
  "2",
  "Pre-1",
  "1",
];

int kankenIndex(String level) => levels.indexOf(level);
String kankenLevel(int index) => levels[index];

sealed class LiteralsCommand {}

class NullCommand extends LiteralsCommand {}

class Initialize extends LiteralsCommand {
  final String level;
  final bool force;
  Initialize(this.level, [this.force = false]);
}

class Next extends LiteralsCommand {}

@immutable
class Literals {
  final String level;
  final int count;
  final String current;
  final List<String> remaining;

  const Literals({
    String? level,
    int? count,
    String? current,
    List<String>? remaining,
  }) : level = level ?? '',
       count = count ?? 0,
       current = current ?? '',
       remaining = remaining ?? const [];

  Literals copyWith({
    String? level,
    int? count,
    String? current,
    List<String>? remaining,
  }) => Literals(
    level: level ?? this.level,
    count: count ?? this.count,
    current: current ?? this.current,
    remaining: remaining ?? this.remaining,
  );

  FutureOr<Literals> reduce(LiteralsCommand command) => switch (command) {
    Initialize() => initialize(command),
    Next() => next(),
    _ => this,
  };

  Future<Literals> initialize(Initialize command) async {
    if (level == command.level && !command.force) return this;

    final repository = await Repository.getInstance();
    final index = kankenIndex(command.level);
    final literals = await repository.randomKankenLiterals(index);
    final count = literals.length;
    final [current, ...remaining] = literals;

    return copyWith(
      level: command.level,
      count: count,
      current: current,
      remaining: remaining,
    );
  }

  Literals next() {
    if (remaining.isEmpty) {
      return copyWith(current: '', remaining: []);
    } else {
      final [current, ...remaining] = this.remaining;
      return copyWith(current: current, remaining: remaining);
    }
  }
}
