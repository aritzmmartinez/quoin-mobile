import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/presentation/providers/sync_providers.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_actions.dart';
import 'package:quoin_core/quoin_core.dart';

Pairing _pc(String name) => Pairing(
  endpoint: SyncEndpoint(host: 'pc.test', port: 1, sha256: name),
  token: 't',
  pcName: name,
  pairedAt: DateTime.utc(2026),
  confirmed: true,
);

PcSync _synced(String name) => PcSync(
  _pc(name),
  const Ok(SyncDone(toPhone: SyncDetail(), toPc: SyncDetail())),
);

PcSync _failed(String name, Failure failure) => PcSync(_pc(name), Err(failure));

void main() {
  test('red only when no PC answered', () {
    final notice = passNotice(
      SyncPass(
        pcs: [
          _failed('Quoin', const PcNotFoundOnNetworkFailure()),
          _failed('PC L', const PcUnreachableFailure()),
        ],
      ),
    );
    expect(notice, isA<PassFailed>());
  });

  test('a PC of another network says nothing once another synced', () {
    final notice = passNotice(
      SyncPass(
        pcs: [
          _synced('Quoin'),
          _failed('PC L', const PcNotFoundOnNetworkFailure()),
        ],
      ),
    );
    expect(notice, isNull);
  });

  test('a PC that refused is told in neutral once another synced', () {
    final notice = passNotice(
      SyncPass(
        pcs: [
          _synced('Quoin'),
          _failed('PC L', const PcNotFoundOnNetworkFailure()),
          _failed('PC M', const PairingRevokedFailure()),
        ],
      ),
    );
    expect(
      notice,
      isA<PcFailed>()
          .having((n) => n.pc.pcName, 'pc', 'PC M')
          .having((n) => n.alone, 'alone', isFalse),
    );
  });

  test('a refusal with no PC synced stays red', () {
    final notice = passNotice(
      SyncPass(
        pcs: [
          _failed('PC L', const PcNotFoundOnNetworkFailure()),
          _failed('PC M', const PairingRevokedFailure()),
        ],
      ),
    );
    expect(
      notice,
      isA<PcFailed>()
          .having((n) => n.pc.pcName, 'pc', 'PC M')
          .having((n) => n.alone, 'alone', isTrue),
    );
  });

  test('the stamp greys only when no PC synced', () {
    const failure = {'pc-l': PcNotFoundOnNetworkFailure()};
    expect(const SyncStatus(failures: failure).failed, isTrue);
    expect(const SyncStatus(failures: failure, synced: true).failed, isFalse);
    expect(const SyncStatus(synced: true).failed, isFalse);
  });
}
