import 'package:flutter/services.dart';
import 'package:qrscan/qrscan.dart' as qrscan;

typedef QrScan = ({String? text, bool denied});
typedef QrScanner = Future<QrScan> Function({required String hint});

Future<QrScan> scanQr({required String hint}) async {
  try {
    return (text: await qrscan.scan(hint: hint), denied: false);
  } on PlatformException catch (e) {
    if (e.code == 'PERMISSION_NOT_GRANTED') return (text: null, denied: true);
    rethrow;
  }
}
