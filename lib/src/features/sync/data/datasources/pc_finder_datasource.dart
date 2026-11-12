import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/exceptions.dart';
import 'package:quoin/src/features/sync/data/datasources/pinned_client.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';

final pcFinderDataSourceProvider = Provider((ref) => PcFinderDataSource());

typedef Hello = ({String sha256, List<int> versions});

typedef Probe = Future<Hello?> Function(
  String host,
  int port,
  Set<String> pins,
  Future<void> stop,
);

class PcFinderDataSource {
  PcFinderDataSource({
    Future<List<String>> Function()? localIps,
    Probe? probe,
    DateTime Function()? now,
    this.concurrency = 32,
    this.connectTimeout = const Duration(seconds: 1),
    this.hostTimeout = const Duration(seconds: 3),
  }) : _localIps = localIps ?? _interfaces,
       _now = now ?? DateTime.now {
    _probe = probe ?? _hello;
  }

  final Future<List<String>> Function() _localIps;
  late final Probe _probe;
  final DateTime Function() _now;
  final int concurrency;
  final Duration connectTimeout;
  final Duration hostTimeout;

  static const holdFor = Duration(minutes: 30);

  final _misses = <String, ({String network, DateTime at})>{};

  Future<Map<String, FoundPc>> find(
    List<SyncEndpoint> lost, {
    required bool held,
  }) async {
    final ips = [
      for (final ip in await _localIps())
        if (isPrivateIpv4(ip)) ip,
    ]..sort();
    if (ips.isEmpty) throw const NoLocalNetworkException();
    final network = ips.join(' ');
    final now = _now();
    final sought = [
      for (final pc in lost)
        if (!held || !_holds(pc.sha256, network, now)) pc,
    ];

    final plans = {
      for (final pc in sought) pc.sha256: scanCandidates(ips, pc.host),
    };
    final pins = <int, Set<String>>{};
    for (final pc in sought) {
      (pins[pc.port] ??= {}).add(pc.sha256);
    }
    final probes = <(String, int)>{
      for (final pc in sought)
        for (final host in plans[pc.sha256]!) (host, pc.port),
    }.toList();
    final wanted = {for (final pc in sought) pc.sha256};

    final answers = <int, Map<String, String>>{};
    final versions = <String, List<int>>{};
    final stop = Completer<void>();
    var next = 0;
    var denied = false;
    Future<void> worker() async {
      while (!stop.isCompleted && next < probes.length) {
        final (host, port) = probes[next++];
        try {
          final hello = await _probe(host, port, pins[port]!, stop.future);
          if (hello == null) continue;
          (answers[port] ??= {})[host] = hello.sha256;
          versions[hello.sha256] ??= hello.versions;
          if (wanted.every(versions.containsKey) && !stop.isCompleted) {
            stop.complete();
          }
        } on LocalNetworkDeniedException {
          denied = true;
          if (!stop.isCompleted) stop.complete();
        }
      }
    }

    await Future.wait([
      for (var i = 0; i < min(concurrency, probes.length); i++) worker(),
    ]);
    if (denied) throw const LocalNetworkDeniedException();

    final found = <String, FoundPc>{};
    for (final pc in sought) {
      final host = pickByFingerprint(
        plans[pc.sha256]!,
        answers[pc.port] ?? const {},
        pc.sha256,
      );
      if (host == null) {
        _misses[pc.sha256] = (network: network, at: now);
      } else {
        _misses.remove(pc.sha256);
        found[pc.sha256] = (host: host, versions: versions[pc.sha256]!);
      }
    }
    return found;
  }

  bool _holds(String sha256, String network, DateTime now) =>
      switch (_misses[sha256]) {
        (network: final seen, :final at) =>
          seen == network && now.difference(at) < holdFor,
        null => false,
      };

  Future<Hello?> _hello(
    String host,
    int port,
    Set<String> pins,
    Future<void> stop,
  ) async {
    final client = PinnedClient.anyOf(pins, connectTimeout: connectTimeout);
    unawaited(stop.then((_) => client.close()));
    try {
      final response = await client
          .get(
            Uri(scheme: 'https', host: host, port: port, path: '/v1/hello'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(hostTimeout);
      final sha = client.presented;
      if (response.statusCode != 200 || sha == null || !pins.contains(sha)) {
        return null;
      }
      return switch (jsonDecode(utf8.decode(response.bodyBytes))) {
        {'versions': final List<Object?> versions} => (
          sha256: sha,
          versions: [
            for (final v in versions)
              if (v is int) v,
          ],
        ),
        _ => null,
      };
    } on SocketException catch (e) {
      if (e.osError?.errorCode case _eperm || _eacces) {
        throw const LocalNetworkDeniedException();
      }
      return null;
    } on Exception {
      return null;
    } finally {
      client.close();
    }
  }
}

const _eperm = 1;
const _eacces = 13;

Future<List<String>> _interfaces() async {
  try {
    return [
      for (final interface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      ))
        for (final address in interface.addresses) address.address,
    ];
  } on SocketException {
    return const [];
  }
}
