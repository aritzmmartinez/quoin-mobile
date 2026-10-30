/// A stored code and the value it names, spelt as the web stores it.
mixin Coded on Enum {
  String get code;
}

T byCode<T extends Coded>(List<T> values, String code) => values.firstWhere(
      (value) => value.code == code,
      orElse: () => throw ArgumentError.value(code, 'code', 'Unknown code'),
    );
