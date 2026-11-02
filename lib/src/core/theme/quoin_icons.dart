import 'package:hugeicons/hugeicons.dart';

/// An icon of the set. Screens name icons through [QuoinIcons] and draw them
/// with `QuoinIcon` (ui/atoms); only those two files import the icon package,
/// so the set can be swapped there alone.
extension type const QuoinIconData._(List<List<dynamic>> data) {}

/// Every icon the app uses: Hugeicons, stroke rounded (MIT).
abstract final class QuoinIcons {
  // Bottom bar.
  static const home = QuoinIconData._(HugeIcons.strokeRoundedHome01);
  static const portfolio = QuoinIconData._(HugeIcons.strokeRoundedWallet01);
  static const analysis = QuoinIconData._(HugeIcons.strokeRoundedAnalytics01);
  static const settings = QuoinIconData._(HugeIcons.strokeRoundedSettings01);
  static const add = QuoinIconData._(HugeIcons.strokeRoundedAdd01);

  // Analysis tools.
  static const projection = QuoinIconData._(
    HugeIcons.strokeRoundedChartIncrease,
  );
  static const opportunityCost = QuoinIconData._(
    HugeIcons.strokeRoundedBalanceScale,
  );
  static const ter = QuoinIconData._(HugeIcons.strokeRoundedTag01);
  static const rebalance = QuoinIconData._(
    HugeIcons.strokeRoundedArrowDataTransferHorizontal,
  );

  // Settings.
  static const currency = QuoinIconData._(HugeIcons.strokeRoundedEuro);
  static const language = QuoinIconData._(HugeIcons.strokeRoundedGlobe);
  static const theme = QuoinIconData._(HugeIcons.strokeRoundedMoon02);
  static const dataSources = QuoinIconData._(HugeIcons.strokeRoundedUpload01);
  static const concentration = QuoinIconData._(
    HugeIcons.strokeRoundedDashboardSpeed01,
  );
  static const version = QuoinIconData._(
    HugeIcons.strokeRoundedInformationCircle,
  );
  static const license = QuoinIconData._(HugeIcons.strokeRoundedJusticeScale01);
  static const thirdPartyLicenses = QuoinIconData._(
    HugeIcons.strokeRoundedFile01,
  );
  static const gallery = QuoinIconData._(
    HugeIcons.strokeRoundedDashboardSquare01,
  );
  static const sampleData = QuoinIconData._(
    HugeIcons.strokeRoundedDatabaseImport,
  );
  static const clearData = QuoinIconData._(HugeIcons.strokeRoundedDelete02);

  static const movements = QuoinIconData._(
    HugeIcons.strokeRoundedArrowDataTransferHorizontal,
  );
  static const realized = QuoinIconData._(HugeIcons.strokeRoundedReceiptDollar);

  // Import.
  static const upload = QuoinIconData._(HugeIcons.strokeRoundedUpload04);
  static const csvFile = QuoinIconData._(HugeIcons.strokeRoundedCsv01);
  static const alert = QuoinIconData._(HugeIcons.strokeRoundedAlert02);

  // Generic.
  static const chevronRight = QuoinIconData._(
    HugeIcons.strokeRoundedArrowRight01,
  );
  static const chevronDown = QuoinIconData._(
    HugeIcons.strokeRoundedArrowDown01,
  );
  static const back = QuoinIconData._(HugeIcons.strokeRoundedArrowLeft01);
  static const info = QuoinIconData._(HugeIcons.strokeRoundedInformationCircle);
  static const check = QuoinIconData._(HugeIcons.strokeRoundedTick02);
  static const close = QuoinIconData._(HugeIcons.strokeRoundedCancel01);
  static const search = QuoinIconData._(HugeIcons.strokeRoundedSearch01);
  static const sort = QuoinIconData._(HugeIcons.strokeRoundedArrowUpDown);
}
