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
  static const residence = QuoinIconData._(HugeIcons.strokeRoundedLocation01);
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

  static const movements = QuoinIconData._(HugeIcons.strokeRoundedHistory);
  static const realized = QuoinIconData._(HugeIcons.strokeRoundedReceiptDollar);

  // An instrument's mark: a fund's tile by its category, a coin.
  static const equityFund = QuoinIconData._(_globe);
  static const bondFund = QuoinIconData._(HugeIcons.strokeRoundedCertificate01);
  static const commodityFund = QuoinIconData._(
    HugeIcons.strokeRoundedGoldIngots,
  );
  static const crypto = QuoinIconData._(_coin);
  static const fund = QuoinIconData._(HugeIcons.strokeRoundedPieChart);

  // Import.
  static const upload = QuoinIconData._(HugeIcons.strokeRoundedUpload04);
  static const csvFile = QuoinIconData._(HugeIcons.strokeRoundedCsv01);
  static const exportInApp = QuoinIconData._(HugeIcons.strokeRoundedSmartphone);
  static const exportOnWeb = QuoinIconData._(HugeIcons.strokeRoundedBrowser);
  static const recognized = QuoinIconData._(
    HugeIcons.strokeRoundedCheckmarkCircle02,
  );
  static const alert = QuoinIconData._(HugeIcons.strokeRoundedAlert02);

  // Sync.
  static const toPhone = QuoinIconData._(HugeIcons.strokeRoundedArrowDown02);
  static const toPc = QuoinIconData._(HugeIcons.strokeRoundedArrowUp02);
  static const computer = QuoinIconData._(HugeIcons.strokeRoundedComputer);
  static const phone = QuoinIconData._(HugeIcons.strokeRoundedSmartphoneWifi);
  static const sync = QuoinIconData._(
    HugeIcons.strokeRoundedArrowReloadHorizontal,
  );
  static const pair = QuoinIconData._(HugeIcons.strokeRoundedQrCode);
  static const unpair = QuoinIconData._(HugeIcons.strokeRoundedUnlink01);
  static const offline = QuoinIconData._(HugeIcons.strokeRoundedWifiError01);
  static const certificate = QuoinIconData._(
    HugeIcons.strokeRoundedSecurityLock,
  );

  // How a figure is worked out.
  static const averageCost = QuoinIconData._(
    HugeIcons.strokeRoundedCalculator01,
  );
  static const fees = QuoinIconData._(HugeIcons.strokeRoundedTag01);
  static const taxRule = QuoinIconData._(
    HugeIcons.strokeRoundedLegalDocument01,
  );
  static const oldestFirst = QuoinIconData._(
    HugeIcons.strokeRoundedSortByDown02,
  );
  static const buyBack = QuoinIconData._(HugeIcons.strokeRoundedRepeat);
  static const swap = QuoinIconData._(
    HugeIcons.strokeRoundedArrowDataTransferHorizontal,
  );
  static const earlierYears = QuoinIconData._(
    HugeIcons.strokeRoundedCalendar03,
  );
  static const cashFlow = QuoinIconData._(
    HugeIcons.strokeRoundedMoneyExchange01,
  );

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
  static const exclamation = QuoinIconData._(
    HugeIcons.strokeRoundedExclamationMark,
  );
  static const close = QuoinIconData._(HugeIcons.strokeRoundedCancel01);
  static const search = QuoinIconData._(HugeIcons.strokeRoundedSearch01);
  static const sort = QuoinIconData._(HugeIcons.strokeRoundedArrowUpDown);
}

// Drawn here, on the set's 24 grid with its stroke, where the set has no
// glyph that reads at tile size.
const _stroke = {
  'stroke': 'currentColor',
  'strokeWidth': '1.5',
  'strokeLinecap': 'round',
  'strokeLinejoin': 'round',
};

const _ring = [
  'circle',
  {..._stroke, 'cx': '12', 'cy': '12', 'r': '9.25'},
];

/// The Earth from the Atlantic: the Americas, and a coast on each side.
const _globe = <List<dynamic>>[
  _ring,
  [
    'path',
    {
      ..._stroke,
      'd': 'M7.6 3.7C6.6 4.6 5.8 5.2 6.4 6.2C7 7.2 6.6 8 7.2 8.8C7.6 9.4 7.4 10 8.2 10.4C9 10.8 9.6 11.2 10.2 11.8C10.6 12.2 10.4 12.8 10.8 13.4C11.4 14.4 11.6 15.6 12 16.8C12.4 17.8 12.8 18.8 13.4 19.6C14.2 18.6 14.6 17.4 15.6 16.6C16.6 15.8 17.2 14.6 17.6 13.4C17.8 12.6 17.2 12 16.2 11.8C15.2 11.6 14.4 11.4 13.6 11C12.8 10.6 12 10.8 11.6 10.2C11.4 9.6 11.8 9 12.6 9C13.4 9 13.8 8.4 14.6 7.8C15.4 7.2 16.4 7 17 6.2C17.4 5.6 17.8 5.4 18.4 5.3',
    },
  ],
  [
    'path',
    {
      ..._stroke,
      'd': 'M20.6 8.5C19.6 9 19 10 19.4 11.2C19.7 12 20.4 12.6 21.1 13.4',
    },
  ],
  [
    'path',
    {..._stroke, 'd': 'M3 10C4 10.2 4.8 11 5 12C5.2 13 4.6 14 3.6 15.8'},
  ],
];

/// «₿» in a coin, for any crypto; the ring is the globe's, so both match.
const _coin = <List<dynamic>>[
  _ring,
  [
    'path',
    {
      ..._stroke,
      'd': 'M8.64 12H13.34M8.64 12V8.97C8.64 8.44 8.64 8.18 8.8 8.02C8.97 7.85 9.23 7.85 9.76 7.85H13.34C14.46 7.85 15.36 8.78 15.36 9.93C15.36 11.07 14.46 12 13.34 12M8.64 12V15.03C8.64 15.56 8.64 15.82 8.8 15.98C8.97 16.15 9.23 16.15 9.76 16.15H13.34C14.46 16.15 15.36 15.22 15.36 14.07C15.36 12.93 14.46 12 13.34 12M10.31 7.85V6.4M10.31 17.6V16.15M13.01 7.85V6.4M13.01 17.6V16.15',
    },
  ],
];
