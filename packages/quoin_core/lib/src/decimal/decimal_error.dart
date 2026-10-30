sealed class DecimalError implements Exception {
  const DecimalError();
}

final class InvalidDecimal extends DecimalError {
  const InvalidDecimal(this.text);

  final String text;

  @override
  String toString() => 'InvalidDecimal: "$text"';
}

final class DivisionByZero extends DecimalError {
  const DivisionByZero();

  @override
  String toString() => 'DivisionByZero';
}
