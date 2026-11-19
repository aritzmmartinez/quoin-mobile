library qrscan;

import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/services.dart';

const String CameraAccessDenied = 'PERMISSION_NOT_GRANTED';
const String CameraStartFailed = 'CAMERA_START_FAILED';
const String CameraInUse = 'CAMERA_IN_USE';
const String NoActivity = 'NO_ACTIVITY';

const MethodChannel _channel = MethodChannel('qr_scan');

class ScanLooks {
  const ScanLooks({required this.color, this.hint, this.title});

  final Color color;
  final String? hint;
  final String? title;

  /// WeChat green. 「扫一扫」
  static const ScanLooks wechat = ScanLooks(
    color: Color(0xFF07C160),
    hint: '将二维码/条码放入框内，即可自动扫描',
    title: '扫一扫',
  );

  /// Alipay blue. 「扫码」
  static const ScanLooks alipay = ScanLooks(
    color: Color(0xFF1677FF),
    hint: '对准二维码/条码',
    title: '扫码',
  );
}

class ScanLabels {
  const ScanLabels({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.searching,
    required this.close,
    required this.torch,
    required this.torchOn,
    required this.torchOff,
    required this.torchUnavailable,
  });

  final String step;
  final String title;
  final String subtitle;
  final String searching;
  final String close;
  final String torch;
  final String torchOn;
  final String torchOff;
  final String torchUnavailable;

  Map<String, String> toMap() => <String, String>{
        'step': step,
        'title': title,
        'subtitle': subtitle,
        'searching': searching,
        'close': close,
        'torch': torch,
        'torchOn': torchOn,
        'torchOff': torchOff,
        'torchUnavailable': torchUnavailable,
      };
}

class ScanFonts {
  const ScanFonts({
    required this.regular,
    required this.medium,
    required this.semiBold,
  });

  final String regular;
  final String medium;
  final String semiBold;

  Map<String, String> toMap() => <String, String>{
        'regular': regular,
        'medium': medium,
        'semiBold': semiBold,
      };
}

Future<String?> scan({
  Color? color,
  String? hint,
  ScanLooks? looks,
  ScanLabels? labels,
  ScanFonts? fonts,
}) async {
  final Color? tint = color ?? looks?.color;
  final String? copy = hint ?? looks?.hint;
  final Map<String, Object> args = <String, Object>{};
  if (labels != null) {
    args['labels'] = labels.toMap();
  }
  if (fonts != null) {
    args['fonts'] = fonts.toMap();
  }
  if (tint != null) {
    args['color'] = tint.value;
  }
  if (copy != null) {
    args['hint'] = copy;
  }
  if (looks?.title != null) {
    args['title'] = looks!.title!;
  }
  return await _channel.invokeMethod<String>('scan', args);
}

Future<String?> scanPhoto() async =>
    await _channel.invokeMethod<String>('scan_photo');

Future<String?> scanPath(String path) async {
  if (path.isEmpty) {
    throw ArgumentError.value(path, 'path', 'must not be empty');
  }
  return await _channel.invokeMethod<String>('scan_path', {'path': path});
}

Future<String?> scanBytes(Uint8List uint8list) async {
  if (uint8list.isEmpty) {
    throw ArgumentError.value(uint8list, 'uint8list', 'must not be empty');
  }
  return await _channel
      .invokeMethod<String>('scan_bytes', {'bytes': uint8list});
}

Future<Uint8List> generateBarCode(String code) async {
  if (code.isEmpty) {
    throw ArgumentError.value(code, 'code', 'must not be empty');
  }
  final Uint8List? data = await _channel
      .invokeMethod<Uint8List>('generate_barcode', {'code': code});
  if (data == null) {
    throw StateError('Failed to generate QR code');
  }
  return data;
}
