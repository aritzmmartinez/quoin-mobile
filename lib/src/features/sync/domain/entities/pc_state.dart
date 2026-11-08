import 'package:quoin_core/quoin_core.dart';

final class PcState {
  const PcState({required this.exchange, required this.etag});

  final Exchange exchange;
  final String etag;
}

enum PushStatus { applied, upToDate, conflicts }

final class PushResult {
  const PushResult({required this.status, required this.setAside});

  final PushStatus status;
  final List<String> setAside;
}
