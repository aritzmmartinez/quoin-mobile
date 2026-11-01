import '../calendar/day.dart';
import '../decimal/decimal_error.dart';
import '../domain/instrument.dart';
import '../domain/ledger.dart';
import '../fx/rates.dart';
import 'reasons.dart';

sealed class MappedItem {
  const MappedItem();
}

final class DomainItem extends MappedItem {
  const DomainItem(this.instrument, this.event);

  final Instrument? instrument;
  final LedgerEvent event;
}

final class DiscardItem extends MappedItem {
  const DiscardItem(
    this.reason, {
    this.detail,
    this.instrument,
    this.related = const [],
  });

  final DiscardReason reason;
  final DiscardDetail? detail;
  final Instrument? instrument;
  final List<Instrument> related;
}

final class NoticeItem extends MappedItem {
  const NoticeItem(this.reason, this.detail);

  final NoticeReason reason;
  final DiscardDetail detail;
}

final class MappedBatch {
  const MappedBatch({
    required this.total,
    required this.instruments,
    required this.events,
    required this.operationOf,
    required this.discarded,
    required this.discardedDetails,
    required this.noticed,
    required this.errors,
    required this.ratesNeeded,
  });

  final int total;
  final List<Instrument> instruments;
  final List<LedgerEvent> events;

  final List<int> operationOf;
  final Map<DiscardReason, int> discarded;
  final Map<DiscardReason, List<DiscardDetail>> discardedDetails;
  final Map<NoticeReason, List<DiscardDetail>> noticed;
  final List<RowError> errors;
  final Map<String, String> ratesNeeded;

  MappedBatch withInstruments(List<Instrument> instruments) => MappedBatch(
        total: total,
        instruments: instruments,
        events: events,
        operationOf: operationOf,
        discarded: discarded,
        discardedDetails: discardedDetails,
        noticed: noticed,
        errors: errors,
        ratesNeeded: ratesNeeded,
      );
}

typedef RateAt = FxRate? Function(String currency, DateTime at);

FxRate? noRates(String currency, DateTime at) => null;

RateAt rateLookupFrom(RateBook book, String zone) =>
    (currency, at) => bookingRate(book, currency, dayOf(at, zone));

String isoInstant(DateTime instant) {
  final utc = instant.toUtc();
  return DateTime.fromMillisecondsSinceEpoch(
    utc.millisecondsSinceEpoch,
    isUtc: true,
  ).toIso8601String();
}

final class BatchBuilder {
  BatchBuilder(this.zone, [this.rateAt = noRates]);

  final String zone;
  final RateAt rateAt;

  InvalidLedgerEvent? _invalid;
  final _events = <LedgerEvent>[];
  final _operationOf = <int>[];
  var _operations = 0;
  final _instruments = <String, Instrument>{};
  final _discarded = <DiscardReason, int>{};
  final _discardedDetails = <DiscardReason, List<DiscardDetail>>{};
  final _noticed = <NoticeReason, List<DiscardDetail>>{};
  final _errors = <RowError>[];
  final _ratesNeeded = <String, String>{};

  void add(MappedItem item) => addOperation([item]);

  void addOperation(List<MappedItem> items) {
    final operation = _operations;
    _operations += 1;

    final converted = <MappedItem>[];
    for (final item in items) {
      if (item is! DomainItem || !isUnconvertedForeign(item.event)) {
        converted.add(item);
        continue;
      }
      final event = item.event;
      final rate = rateAt(event.currency, event.ts);
      if (rate == null) {
        _needRate(event.currency, dayOf(event.ts, zone));
        _addItem(_unrated(item), operation);
        return;
      }
      converted.add(
        DomainItem(
          item.instrument,
          convertedAt(
            event,
            source: FxSource.of(rate.source),
            rate: rate.rate,
            day: rate.day,
          ),
        ),
      );
    }

    for (final item in converted) {
      if (item is DomainItem &&
          _invalid == null &&
          ledgerWriteIssues(item.event).isNotEmpty) {
        _invalid = InvalidLedgerEvent(
          dayOf(item.event.ts, zone),
          ledgerTypeOf(item.event),
          item.event.currency,
        );
      }
      _addItem(item, operation);
    }
  }

  void addNotice(NoticeReason reason, DiscardDetail detail) =>
      _noticed.putIfAbsent(reason, () => []).add(detail);

  void addError(RowError error) => _errors.add(error);

  void _addItem(MappedItem item, int operation) {
    switch (item) {
      case NoticeItem(:final reason, :final detail):
        addNotice(reason, detail);
      case DiscardItem(:final reason, :final detail):
        _discarded[reason] = (_discarded[reason] ?? 0) + 1;
        if (detail != null) {
          _discardedDetails.putIfAbsent(reason, () => []).add(detail);
        }
        for (final instrument in [item.instrument, ...item.related]) {
          if (instrument != null) _instruments[instrument.id] = instrument;
        }
      case DomainItem(:final instrument, :final event):
        if (instrument != null) _instruments[instrument.id] = instrument;
        _events.add(event);
        _operationOf.add(operation);
    }
  }

  void _needRate(String currency, String day) {
    final held = _ratesNeeded[currency];
    if (held == null || day.compareTo(held) < 0) _ratesNeeded[currency] = day;
  }

  MappedBatch build(int total) {
    final invalid = _invalid;
    if (invalid != null) throw invalid;
    return MappedBatch(
      total: total,
      instruments: [..._instruments.values],
      events: _events,
      operationOf: _operationOf,
      discarded: _discarded,
      discardedDetails: _discardedDetails,
      noticed: _noticed,
      errors: _errors,
      ratesNeeded: _ratesNeeded,
    );
  }
}

DiscardItem _unrated(DomainItem item) {
  final event = item.event;
  final name = item.instrument?.name ?? '';
  return DiscardItem(
    DiscardReason.fxUnavailable,
    detail: DiscardDetail(
      date: isoInstant(event.ts),
      type: ledgerTypeOf(event),
      instrument: name.isEmpty ? event.currency : '$name (${event.currency})',
    ),
  );
}

({int imported, int duplicates}) countOperations(
  MappedBatch batch,
  Set<(String, String)> existing,
) {
  final writes = <int, bool>{};
  for (var i = 0; i < batch.events.length; i += 1) {
    final event = batch.events[i];
    final operation = i < batch.operationOf.length ? batch.operationOf[i] : i;
    final id = event.externalId ?? '';
    final isNew = id.isEmpty || !existing.contains((event.source, id));
    writes[operation] = (writes[operation] ?? false) || isNew;
  }
  final imported = writes.values.where((writes) => writes).length;
  return (imported: imported, duplicates: writes.length - imported);
}

RowErrorReason rowErrorReason(Object error) => switch (error) {
      MissingInstrument() => RowErrorReason.missingInstrument,
      DecimalError() => RowErrorReason.invalidNumber,
      _ => RowErrorReason.unexpected,
    };
