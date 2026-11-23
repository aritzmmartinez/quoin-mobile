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
    required this.failed,
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
  final int failed;
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
        failed: failed,
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
        _addDiscard(_unrated(item), null);
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

    _Lead? lead;
    for (final item in converted) {
      if (item is DiscardItem) {
        lead = _addDiscard(item, lead);
        continue;
      }
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

  void addError(RowError error, [List<RowError> others = const []]) {
    _operations += 1;
    _errors.add(
      others.isEmpty
          ? error
          : RowError(error.row, error.reason, rows: [...error.rows, ...others]),
    );
  }

  _Lead _addDiscard(DiscardItem item, _Lead? lead) {
    for (final instrument in [item.instrument, ...item.related]) {
      if (instrument != null) _instruments[instrument.id] = instrument;
    }
    final detail = item.detail;
    if (lead != null) {
      if ((lead.index, detail) case (final index?, final detail?)) {
        final list = _discardedDetails[lead.reason]!;
        list[index] = list[index].withRow(detail);
      }
      return lead;
    }
    final reason = item.reason;
    _discarded[reason] = (_discarded[reason] ?? 0) + 1;
    if (detail == null) return (reason: reason, index: null);
    final list = _discardedDetails.putIfAbsent(reason, () => [])..add(detail);
    return (reason: reason, index: list.length - 1);
  }

  void _addItem(MappedItem item, int operation) {
    switch (item) {
      case NoticeItem(:final reason, :final detail):
        addNotice(reason, detail);
      case DiscardItem():
        throw StateError('Discards go through _addDiscard');
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

  MappedBatch build() {
    final invalid = _invalid;
    if (invalid != null) throw invalid;
    return MappedBatch(
      total: _operations,
      failed: _errors.length,
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

typedef _Lead = ({DiscardReason reason, int? index});
typedef OperationCounts = ({int imported, int completed, int duplicates});

OperationCounts countOperations(
  MappedBatch batch,
  Set<(String, String)> existing,
) {
  final operations = <int, ({bool stored, bool fresh})>{};
  for (var i = 0; i < batch.events.length; i += 1) {
    final event = batch.events[i];
    final operation = i < batch.operationOf.length ? batch.operationOf[i] : i;
    final id = event.externalId ?? '';
    final isNew = id.isEmpty || !existing.contains((event.source, id));
    final seen = operations[operation] ?? (stored: false, fresh: false);
    operations[operation] = (
      stored: seen.stored || !isNew,
      fresh: seen.fresh || isNew,
    );
  }
  var imported = 0, completed = 0, duplicates = 0;
  for (final (:stored, :fresh) in operations.values) {
    if (!fresh) {
      duplicates += 1;
    } else if (stored) {
      completed += 1;
    } else {
      imported += 1;
    }
  }
  return (imported: imported, completed: completed, duplicates: duplicates);
}

int operationsToWrite(OperationCounts counts) =>
    counts.imported + counts.completed;

enum NothingToImport { alreadyStored, nothingToSave }

NothingToImport nothingToImport({
  required int total,
  required int duplicates,
}) =>
    total > 0 && duplicates == total
        ? NothingToImport.alreadyStored
        : NothingToImport.nothingToSave;

RowErrorReason rowErrorReason(Object error) => switch (error) {
      MissingInstrument() => RowErrorReason.missingInstrument,
      DecimalError() => RowErrorReason.invalidNumber,
      _ => RowErrorReason.unexpected,
    };
