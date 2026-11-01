import '../decimal/dec.dart';

const String baseCurrency = 'EUR';

final class Money implements Comparable<Money> {
  const Money._(this.amount);

  final Dec amount;

  static final Money zero = Money._(Dec.zero);

  static Money parse(String text) => Money._(Dec.parse(text));

  factory Money.of(Dec amount) => Money._(amount);

  static Money? tryParse(String text) {
    final value = Dec.tryParse(text);
    return value == null ? null : Money._(value);
  }

  Money add(Money other) => Money._(amount + other.amount);

  Money subtract(Money other) => Money._(amount - other.amount);

  Money scaleBy(Dec factor) => Money._(amount * factor);

  Money divideBy(Dec divisor) => Money._(amount.dividedBy(divisor));

  Money negate() => Money._(-amount);

  bool get isZero => amount.isZero;

  bool get isNegative => amount.isNegative;

  bool get isPositive => amount.isPositive;

  @override
  int compareTo(Money other) => amount.compareTo(other.amount);

  @override
  bool operator ==(Object other) => other is Money && other.amount == amount;

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => amount.toString();

  String get text => amount.text;

  double toDouble() => amount.toDouble();
}
