import 'dart:async';
import 'package:flutter/foundation.dart' show immutable;
import 'repository.dart';

sealed class KanaCommand {}

class NullCommand extends KanaCommand {}

class InitializeKana extends KanaCommand {
  final bool force;
  InitializeKana([this.force = false]);
}

class NextKana extends KanaCommand {}

@immutable
class Kana {
  final int count;
  final String current;
  final List<String> remaining;

  const Kana({int? count, String? current, List<String>? remaining})
    : count = count ?? 0,
      current = current ?? '',
      remaining = remaining ?? const [];

  Kana copyWith({int? count, String? current, List<String>? remaining}) => Kana(
    count: count ?? this.count,
    current: current ?? this.current,
    remaining: remaining ?? this.remaining,
  );

  FutureOr<Kana> reduce(KanaCommand command) => switch (command) {
    InitializeKana() => initialize(command),
    NextKana() => next(),
    _ => this,
  };

  Future<Kana> initialize(InitializeKana command) async {
    final repository = await Repository.getInstance();
    // final literals = await repository.hiragana();
    final literals = await repository.katakana();
    final count = literals.length;
    final [current, ...remaining] = literals;

    return copyWith(count: count, current: current, remaining: remaining);
  }

  Kana next() {
    if (remaining.isEmpty) {
      return copyWith(current: '', remaining: []);
    } else {
      final [current, ...remaining] = this.remaining;
      return copyWith(current: current, remaining: remaining);
    }
  }
}
