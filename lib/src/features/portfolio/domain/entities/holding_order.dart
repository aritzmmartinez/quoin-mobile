import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/features/portfolio/domain/entities/portfolio_overview.dart';

enum HoldingOrder { value, gain, name }

/// [holdings] in [order]. By value and by gain the largest come first and a
/// position with no figure goes last; ties fall back to the name.
List<Holding> sortHoldings(List<Holding> holdings, HoldingOrder order) {
  int byName(Holding a, Holding b) => compareNamesEs(a.name, b.name);
  int descending<T extends Comparable<T>>(T? a, T? b) =>
      a == null ? (b == null ? 0 : 1) : (b == null ? -1 : b.compareTo(a));

  return stableSorted(holdings, switch (order) {
    HoldingOrder.value => (a, b) {
      final byValue = descending(a.value.marketValue, b.value.marketValue);
      return byValue != 0 ? byValue : byName(a, b);
    },
    HoldingOrder.gain => (a, b) {
      final byGain = descending(a.unrealizedPnLPct, b.unrealizedPnLPct);
      return byGain != 0 ? byGain : byName(a, b);
    },
    HoldingOrder.name => byName,
  });
}

/// Names in Spanish alphabetical order, as a primary-strength es-ES collator
/// reads them: case and accents ignored, «ñ» a letter of its own after «n».
/// Pure Dart has no ICU; ties fall back to code units so the order is total.
int compareNamesEs(String a, String b) {
  final byKey = _collationKey(a).compareTo(_collationKey(b));
  return byKey != 0 ? byKey : compareCodeUnits(a, b);
}

const _folded = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ý': 'y', 'ÿ': 'y',
  // Sorts after every «n…» and before «o».
  'ñ': 'n\u{7f}',
};

String _collationKey(String name) =>
    name.toLowerCase().split('').map((char) => _folded[char] ?? char).join();
