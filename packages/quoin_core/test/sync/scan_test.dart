import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  group('scanCandidates', () {
    test('walks the /24 from the saved octet outwards, one step at a time', () {
      final hosts = scanCandidates(['192.168.1.50'], '192.168.1.20');
      expect(hosts.take(5), [
        '192.168.1.20',
        '192.168.1.21',
        '192.168.1.19',
        '192.168.1.22',
        '192.168.1.18',
      ]);
    });

    test('leaves out the network, the broadcast and the phone', () {
      final hosts = scanCandidates(['192.168.1.50'], '192.168.1.20');
      expect(hosts, hasLength(253));
      expect(hosts.toSet(), hasLength(253));
      expect(hosts, isNot(contains('192.168.1.0')));
      expect(hosts, isNot(contains('192.168.1.255')));
      expect(hosts, isNot(contains('192.168.1.50')));
      expect(hosts.last, '192.168.1.254');
    });

    test('at the edge of the range, it keeps going the one way left', () {
      final hosts = scanCandidates(['10.0.0.9'], '10.0.0.1');
      expect(hosts.take(4), ['10.0.0.1', '10.0.0.2', '10.0.0.3', '10.0.0.4']);
      expect(hosts, hasLength(253));
    });

    test('walks only the /24 of the phone that holds the saved host', () {
      final hosts = scanCandidates([
        '10.71.4.8',
        '192.168.1.50',
      ], '192.168.1.20');
      expect(hosts.every((h) => h.startsWith('192.168.1.')), isTrue);
    });

    test(
        'nothing when no /24 of the phone holds the saved host, or the '
        'host is not an IPv4 address', () {
      expect(scanCandidates(['192.168.0.5'], '192.168.1.20'), isEmpty);
      expect(scanCandidates(['192.168.1.5'], 'pc.lan'), isEmpty);
      expect(scanCandidates(const [], '192.168.1.20'), isEmpty);
    });

    test('a public address of the phone is never walked', () {
      expect(scanCandidates(['84.12.3.7'], '84.12.3.9'), isEmpty);
    });
  });

  test('isPrivateIpv4', () {
    for (final ip in [
      '10.1.2.3',
      '172.16.0.1',
      '172.31.255.1',
      '192.168.0.1'
    ]) {
      expect(isPrivateIpv4(ip), isTrue, reason: ip);
    }
    for (final ip in [
      '127.0.0.1',
      '172.15.0.1',
      '172.32.0.1',
      '100.64.0.1',
      '8.8.8.8',
      '192.168.1',
      '192.168.01.1',
    ]) {
      expect(isPrivateIpv4(ip), isFalse, reason: ip);
    }
  });

  group('pickByFingerprint', () {
    final candidates = ['192.168.1.20', '192.168.1.21', '192.168.1.19'];

    test('the host that presented the fingerprint', () {
      expect(
        pickByFingerprint(
            candidates,
            {
              '192.168.1.21': 'aa',
              '192.168.1.19': 'bb',
            },
            'bb'),
        '192.168.1.19',
      );
    });

    test('the first in walking order when it answered on two hosts', () {
      expect(
        pickByFingerprint(
            candidates,
            {
              '192.168.1.19': 'aa',
              '192.168.1.21': 'aa',
            },
            'aa'),
        '192.168.1.21',
      );
    });

    test('none when no host presented it', () {
      expect(
        pickByFingerprint(candidates, {'192.168.1.21': 'aa'}, 'bb'),
        isNull,
      );
    });
  });
}
