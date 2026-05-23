/// Represents an optional value that may or may not exist.
sealed class Option<T> {
  const Option();

  /// Creates a [Some] instance containing a value.
  factory Option.some(T value) = Some<T>;

  /// Creates a [None] instance representing the absence of a value.
  factory Option.none() = None<T>;

  /// Returns true if the option is [Some].
  bool get isSome;

  /// Returns true if the option is [None].
  bool get isNone;

  /// Transforms the value inside [Some] using [fn], or returns [None].
  /// This is the 'map' operation.
  Option<R> map<R>(R Function(T value) fn);

  /// Transforms the value inside [Some] into another [Option] using [fn].
  /// This is the monadic 'bind' (flatMap) operation.
  Option<R> flatMap<R>(Option<R> Function(T value) fn);

  /// Returns the value if [Some], otherwise returns [defaultValue].
  T getOrElse(T defaultValue);

  /// Executes [onSome] if a value is present, otherwise executes [onNone].
  /// This pattern matches the underlying implementation.
  R fold<R>(R Function() onNone, R Function(T value) onSome);
}

/// Represents the presence of a value.
final class Some<T> extends Option<T> {
  final T value;

  const Some(this.value);

  @override
  bool get isSome => true;

  @override
  bool get isNone => false;

  @override
  Option<R> map<R>(R Function(T value) fn) => Some<R>(fn(value));

  @override
  Option<R> flatMap<R>(Option<R> Function(T value) fn) => fn(value);

  @override
  T getOrElse(T defaultValue) => value;

  @override
  R fold<R>(R Function() onNone, R Function(T value) onSome) => onSome(value);

  @override
  bool operator ==(Object other) => other is Some<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Some($value)';
}

/// Represents the absence of a value.
final class None<T> extends Option<T> {
  const None();

  @override
  bool get isSome => false;

  @override
  bool get isNone => true;

  @override
  Option<R> map<R>(R Function(T value) fn) => None<R>();

  @override
  Option<R> flatMap<R>(Option<R> Function(T value) fn) => None<R>();

  @override
  T getOrElse(T defaultValue) => defaultValue;

  @override
  R fold<R>(R Function() onNone, R Function(T value) onSome) => onNone();

  @override
  bool operator ==(Object other) => other is None<T>;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'None';
}
