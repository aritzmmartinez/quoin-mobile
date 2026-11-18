import 'package:flutter/services.dart';
import 'package:qrscan/qrscan.dart' as qrscan;

typedef QrScan = ({String? text, bool denied});
typedef QrScanner = Future<QrScan> Function({
  required String title,
  required String hint,
  required Color color,
});

Future<QrScan> scanQr({
  required String title,
  required String hint,
  required Color color,
}) async {
  try {
    return (
      text: await qrscan.scan(
        looks: qrscan.ScanLooks(color: color, hint: hint, title: title),
      ),
      denied: false,
    );
  } on PlatformException catch (e) {
    if (e.code == 'PERMISSION_NOT_GRANTED') return (text: null, denied: true);
    rethrow;
  }
}
