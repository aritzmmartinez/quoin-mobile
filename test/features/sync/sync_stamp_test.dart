import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';

import '../../helpers.dart';

Pairing _pc(String sha, DateTime? at) => Pairing(
  endpoint: SyncEndpoint(host: 'pc.test', port: 1, sha256: sha),
  token: 't',
  pcName: 'PC',
  pairedAt: DateTime.utc(2026),
  lastSyncAt: at,
  confirmed: true,
);

void main() {
  testWidgets('home says when the last sync of any PC was', (tester) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      sample: true,
      overrides: [
        pairingsProvider.overrideWith(
          (ref) async => Ok(
            Pairings(
              pcs: [
                _pc('aa', testNow.subtract(const Duration(hours: 3))),
                _pc('bb', testNow.subtract(const Duration(minutes: 2))),
              ],
            ),
          ),
        ),
      ],
    );
    expect(find.text('Sincronizado hace 2 min'), findsOneWidget);
  });

  testWidgets('with no PC that ever synced it says nothing', (tester) async {
    await pumpApp(
      tester,
      prefs: {'locale': 'es'},
      sample: true,
      overrides: [
        pairingsProvider.overrideWith(
          (ref) async => Ok(Pairings(pcs: [_pc('aa', null)])),
        ),
      ],
    );
    expect(find.textContaining('Sincronizado'), findsNothing);
  });
}
