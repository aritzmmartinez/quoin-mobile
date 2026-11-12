import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/sync/data/datasources/pc_finder_datasource.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';

final pcSha = 'ab' * 32;
final pc2Sha = 'cd' * 32;

SyncEndpoint saved(String sha256, {String host = '192.168.1.20'}) =>
    SyncEndpoint(host: host, port: 3443, sha256: sha256);

void main() {
  late List<String> phoneIps;
  late DateTime now;
  late Map<String, String> answering;
  late List<String> probed;
  late int open;
  late int mostOpen;
  late int stopped;
  late PcFinderDataSource finder;

  setUp(() {
    phoneIps = ['192.168.1.50'];
    now = DateTime.utc(2026, 11, 12, 10);
    answering = {};
    probed = [];
    open = 0;
    mostOpen = 0;
    stopped = 0;
    finder = PcFinderDataSource(
      localIps: () async => phoneIps,
      now: () => now,
      probe: (host, port, pins, stop) async {
        probed.add(host);
        open += 1;
        if (open > mostOpen) mostOpen = open;
        try {
          if (answering[host] case final sha? when pins.contains(sha)) {
            await Future<void>.delayed(Duration.zero);
            return (sha256: sha, versions: const [1]);
          }
          final cut = await Future.any([
            stop.then((_) => true),
            Future<bool>.delayed(
              const Duration(milliseconds: 200),
              () => false,
            ),
          ]);
          if (cut) stopped += 1;
          return null;
        } finally {
          open -= 1;
        }
      },
    );
  });

  test('the host presenting the certificate, and the sweep stops there with '
      'at most 32 hosts at once', () async {
    answering['192.168.1.70'] = pcSha;

    final found = await finder
        .find([saved(pcSha)], held: true)
        .timeout(const Duration(seconds: 5));

    expect(found[pcSha]?.host, '192.168.1.70');
    expect(found[pcSha]?.versions, [1]);
    expect(mostOpen, 32);
    expect(probed.length, lessThan(253));
    expect(stopped, 31, reason: 'every other probe in flight was cut short');
  });

  test('another certificate on a host is not the PC', () async {
    answering['192.168.1.21'] = 'ef' * 32;
    finder = PcFinderDataSource(
      localIps: () async => phoneIps,
      probe: (host, port, pins, stop) async {
        probed.add(host);
        final sha = answering[host];
        return sha != null && pins.contains(sha)
            ? (sha256: sha, versions: const [1])
            : null;
      },
    );

    expect(await finder.find([saved(pcSha)], held: true), isEmpty);
    expect(probed, hasLength(253));
  });

  test('several PCs: one sweep, each host once, until all are found', () async {
    answering
      ..['192.168.1.70'] = pcSha
      ..['192.168.1.90'] = pc2Sha;

    final found = await finder
        .find([saved(pcSha), saved(pc2Sha)], held: true)
        .timeout(const Duration(seconds: 5));

    expect(found.keys, {pcSha, pc2Sha});
    expect(probed.toSet(), hasLength(probed.length));
  });

  test('a denied connection ends the search at once', () async {
    finder = PcFinderDataSource(
      localIps: () async => phoneIps,
      probe: (host, port, pins, stop) async {
        probed.add(host);
        throw const LocalNetworkDeniedException();
      },
    );

    await expectLater(
      finder.find([saved(pcSha)], held: true),
      throwsA(isA<LocalNetworkDeniedException>()),
    );
    expect(probed.length, lessThanOrEqualTo(32));
  });

  test('no private IPv4 address: no network to search', () async {
    phoneIps = ['127.0.0.1', '100.64.2.3'];

    await expectLater(
      finder.find([saved(pcSha)], held: true),
      throwsA(isA<NoLocalNetworkException>()),
    );
    expect(probed, isEmpty);
  });

  group('a miss holds a held search', () {
    Future<void> miss() async {
      finder = PcFinderDataSource(
        localIps: () async => phoneIps,
        now: () => now,
        probe: (host, port, pins, stop) async {
          probed.add(host);
          final sha = answering[host];
          return sha != null && pins.contains(sha)
              ? (sha256: sha, versions: const [1])
              : null;
        },
      );
      expect(await finder.find([saved(pcSha)], held: true), isEmpty);
      probed.clear();
    }

    test('on the same addresses, for 30 minutes', () async {
      await miss();

      now = now.add(const Duration(minutes: 29));
      expect(await finder.find([saved(pcSha)], held: true), isEmpty);
      expect(probed, isEmpty);

      now = now.add(const Duration(minutes: 1));
      await finder.find([saved(pcSha)], held: true);
      expect(probed, hasLength(253));
    });

    test('not once the phone is on other addresses', () async {
      await miss();

      phoneIps = ['192.168.1.51'];
      await finder.find([saved(pcSha)], held: true);
      expect(probed, isNotEmpty);
    });

    test('not when the user asks for the search', () async {
      await miss();

      answering['192.168.1.70'] = pcSha;
      final found = await finder.find([saved(pcSha)], held: false);
      expect(found[pcSha]?.host, '192.168.1.70');

      answering.clear();
      probed.clear();
      await finder.find([saved(pcSha)], held: true);
      expect(probed, isNotEmpty, reason: 'a find clears the miss');
    });

    test('only for the PC missed', () async {
      await miss();

      answering['192.168.1.70'] = pc2Sha;
      final found = await finder.find([
        saved(pcSha),
        saved(pc2Sha),
      ], held: true);
      expect(found.keys, [pc2Sha]);
    });
  });
}
