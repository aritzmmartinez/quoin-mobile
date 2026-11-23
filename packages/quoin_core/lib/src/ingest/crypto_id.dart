final _assetCode = RegExp(r'^[A-Z0-9]+$');
final _isinShape = RegExp(r'^[A-Z]{2}[A-Z0-9]{9}[0-9]$');

String? cryptoInstrumentId(String code) =>
    _assetCode.hasMatch(code) && !_isinShape.hasMatch(code) ? code : null;
