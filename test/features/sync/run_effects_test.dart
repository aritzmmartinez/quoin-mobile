import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/app/dependencies.dart';
import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/error/result.dart';
import 'package:quoin/src/features/import/domain/repositories/fx_repository.dart';
import 'package:quoin/src/features/import/domain/usecases/ensure_rates.dart';
import 'package:quoin/src/features/sync/domain/entities/effect_outcome.dart';
import 'package:quoin/src/features/sync/domain/usecases/run_effects.dart';
import 'package:quoin_core/quoin_core.dart';

const rates = RatesEffect(currency: 'USD', since: '2026-03-31T23:30:00.000Z');
const prices = PricesEffect(instrumentId: 'XX00TEST0001', symbol: 'TEST.DE');

void main() {
  group('run effects', () {
    test(
      'asks for the rates from the day of the instant in the zone',
      () async {
        final asked = <(Map<String, String>, String)>[];
        final run = RunEffects((needs, {required zone}) async {
          asked.add((needs, zone));
          return const Ok([]);
        }, _keep);

        final outcomes = await run([rates], zone: const Ok('Europe/Madrid'));

        expect(asked.single.$1, {'USD': '2026-04-01'});
        expect(asked.single.$2, 'Europe/Madrid');
        expect(outcomes.single, isA<EffectDone>());
      },
    );

    test('reports a currency it could not reach, and goes on', () async {
      final run = RunEffects(
        (needs, {required zone}) async =>
            Ok(needs.keys.contains('USD') ? ['USD'] : []),
        _keep,
      );

      final outcomes = await run([
        rates,
        const RatesEffect(currency: 'GBP', since: '2026-02-01T10:00:00.000Z'),
      ], zone: const Ok('Europe/Madrid'));

      expect(outcomes[0], isA<EffectFailed>());
      expect((outcomes[0] as EffectFailed).failure, isA<NetworkFailure>());
      expect(outcomes[1], isA<EffectDone>());
    });

    test('reports a failure of the service for that effect only', () async {
      final run = RunEffects(
        (needs, {required zone}) async => const Err(StorageFailure()),
        _keep,
      );

      final outcomes = await run([
        rates,
        prices,
      ], zone: const Ok('Europe/Madrid'));

      expect((outcomes[0] as EffectFailed).failure, isA<StorageFailure>());
    });

    test(
      'drops the series of a new quote symbol, without asking for rates',
      () async {
        var asked = false;
        final dropped = <String>[];
        final run = RunEffects(
          (needs, {required zone}) async {
            asked = true;
            return const Ok([]);
          },
          (id) async {
            dropped.add(id);
            return const Ok(null);
          },
        );

        final outcomes = await run([prices], zone: const Ok('Europe/Madrid'));

        expect(asked, isFalse);
        expect(dropped, ['XX00TEST0001']);
        expect(outcomes.single, isA<EffectDone>());
        expect(outcomes.single.effect, same(prices));
      },
    );

    test(
      'without a known residence the rates fail, the prices still drop',
      () async {
        final run = RunEffects(
          (needs, {required zone}) => throw StateError('no zone, no rates'),
          _keep,
        );

        final outcomes = await run([
          rates,
          prices,
        ], zone: const Err(UnsupportedResidenceFailure('araba')));

        expect(
          (outcomes[0] as EffectFailed).failure,
          isA<UnsupportedResidenceFailure>(),
        );
        expect(outcomes[1], isA<EffectDone>());
      },
    );
  });

  group('rates for sync', () {
    test(
      'answers with the currencies the ECB could not be reached for',
      () async {
        final ask = ratesForSync(
          const EnsureRates(_Offline()),
          now: () => DateTime.utc(2026, 5, 1, 12),
        );

        final result = await ask({'USD': '2026-04-01'}, zone: 'Europe/Madrid');

        expect(
          switch (result) {
            Ok(:final value) => value,
            Err() => null,
          },
          ['USD'],
        );
      },
    );
  });
}

Future<Result<void>> _keep(String instrumentId) async => const Ok(null);

class _Offline implements FxRepository {
  const _Offline();

  @override
  Future<Result<({String? first, String? last})>> span(String quote) async =>
      const Ok((first: null, last: null));

  @override
  Future<Result<List<FxRate>>> fetch(String q, String f, String t) async =>
      const Err(NetworkFailure());

  @override
  Future<Result<FxWritePlan>> save(String quote, List<FxRate> rates) =>
      throw UnimplementedError();

  @override
  Future<Result<RateBook>> book(List<String> quotes) async => const Ok({});
}
