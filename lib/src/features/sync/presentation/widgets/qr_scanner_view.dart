import 'package:flutter/services.dart';
import 'package:qrscan/qrscan.dart' as qrscan;

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';

typedef QrScan = ({String? text, bool denied});
typedef QrScanner = Future<QrScan> Function(AppLocalizations l10n);

qrscan.ScanLabels scanLabels(AppLocalizations l10n) => qrscan.ScanLabels(
  step: l10n.quoinStepOf(2, 3),
  title: l10n.pairScannerTitle,
  subtitle: l10n.pairScannerHint,
  searching: l10n.pairScannerSearching,
  close: l10n.pairScannerClose,
  torch: l10n.pairScannerTorch,
  torchOn: l10n.pairScannerTorchOn,
  torchOff: l10n.pairScannerTorchOff,
  torchUnavailable: l10n.pairScannerTorchUnavailable,
);

Future<QrScan> scanQr(AppLocalizations l10n) async {
  try {
    return (
      text: await qrscan.scan(
        color: QuoinColors.dark.accent,
        labels: scanLabels(l10n),
        fonts: const qrscan.ScanFonts(
          regular: 'assets/fonts/Geist-Regular.ttf',
          medium: 'assets/fonts/Geist-Medium.ttf',
          semiBold: 'assets/fonts/Geist-SemiBold.ttf',
        ),
      ),
      denied: false,
    );
  } on PlatformException catch (e) {
    if (e.code == qrscan.CameraAccessDenied) return (text: null, denied: true);
    rethrow;
  }
}
