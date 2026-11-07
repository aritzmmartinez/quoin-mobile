import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

String pairingCode(String token, String deviceId) {
  final digest =
      Hmac(sha256, utf8.encode(token)).convert(utf8.encode(deviceId));
  final first =
      ByteData.sublistView(Uint8List.fromList(digest.bytes)).getUint32(0);
  return (first % 1000000).toString().padLeft(6, '0');
}
