/// A hybrid logical clock mark: `<ms, 15 digits>-<counter, 4 digits>-<deviceId>`.
/// Plain ASCII and fixed-width up front, so string order is time order on every
/// side that ports it. A mark is only ever compared with marks of the device
/// that wrote it; the device id is there to say which one.
typedef Hlc = ({int ms, int counter, String deviceId});

const _msDigits = 15;
const _counterDigits = 4;
const _maxCounter = 9999;
final _pattern = RegExp(r'^(\d{15})-(\d{4})-(.+)$');

/// A value that is not a sync mark.
class InvalidHlc implements Exception {
  const InvalidHlc(this.value);

  final String value;

  @override
  String toString() => 'Not a sync mark: "$value"';
}

String formatHlc(Hlc mark) => '${mark.ms.toString().padLeft(_msDigits, '0')}-'
    '${mark.counter.toString().padLeft(_counterDigits, '0')}-${mark.deviceId}';

Hlc parseHlc(String value) {
  final match = _pattern.firstMatch(value);
  if (match == null) throw InvalidHlc(value);
  return (
    ms: int.parse(match[1]!),
    counter: int.parse(match[2]!),
    deviceId: match[3]!,
  );
}

bool isHlc(String value) => _pattern.hasMatch(value);

String originOf(String value) => parseHlc(value).deviceId;

/// The next mark after [last], never earlier than it whatever the physical
/// clock says, so a clock set back after a sync cannot hide a change made since.
String tick(String? last, int nowMs, String deviceId) {
  final previous = last == null || last.isEmpty ? null : parseHlc(last);
  if (previous == null || nowMs > previous.ms) {
    return formatHlc((ms: nowMs, counter: 0, deviceId: deviceId));
  }
  if (previous.counter < _maxCounter) {
    return formatHlc(
      (ms: previous.ms, counter: previous.counter + 1, deviceId: deviceId),
    );
  }
  return formatHlc((ms: previous.ms + 1, counter: 0, deviceId: deviceId));
}
