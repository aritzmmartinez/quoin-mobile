class StorageException implements Exception {
  const StorageException(this.cause);

  final Object cause;

  @override
  String toString() => 'StorageException: $cause';
}

/// A file the user picked that could not be opened or read.
class FileException implements Exception {
  const FileException(this.cause);

  final Object cause;

  @override
  String toString() => 'FileException: $cause';
}

/// A file whose bytes are not UTF-8 text.
class EncodingException implements Exception {
  const EncodingException(this.cause);

  final Object cause;

  @override
  String toString() => 'EncodingException: $cause';
}

/// A remote service that could not be reached, answered with an error or
/// sent a body that could not be read.
class NetworkException implements Exception {
  const NetworkException(this.cause, {this.statusCode});

  final Object cause;
  final int? statusCode;

  @override
  String toString() => 'NetworkException ($statusCode): $cause';
}

/// A local state that holds the invented sample data, which never syncs.
class SampleDataException implements Exception {
  const SampleDataException();

  @override
  String toString() => 'SampleDataException';
}

/// A stored residence this version does not know, such as a territory a newer
/// Quoin added and sync brought over. Kept as it came, so it still syncs.
class UnsupportedResidenceException implements Exception {
  const UnsupportedResidenceException(this.residence);

  final String residence;

  @override
  String toString() => 'UnsupportedResidenceException: $residence';
}

/// The PC answered over TLS with a certificate whose SHA-256 is not the one
/// paired with. Nothing was sent: the pin is checked during the handshake.
/// [presented] is the SHA-256 of the certificate that answered.
class PinMismatchException implements Exception {
  const PinMismatchException([this.presented]);

  final String? presented;

  @override
  String toString() => 'PinMismatchException';
}

/// The PC refused a request: [status] and the `error` code of its body
/// (`{ "error": code }`), with the fields some codes carry.
class SyncHttpException implements Exception {
  const SyncHttpException(
    this.status,
    this.code, {
    this.retryAfter,
    this.update,
  });

  final int status;
  final String code;

  /// `Retry-After` of a 429 or a 503.
  final Duration? retryAfter;

  /// `update` of `unsupported-schema-version`: `client` or `server`.
  final String? update;

  @override
  String toString() => 'SyncHttpException ($status): $code';
}

/// The phone has no private IPv4 address to look for a PC from.
class NoLocalNetworkException implements Exception {
  const NoLocalNetworkException();

  @override
  String toString() => 'NoLocalNetworkException';
}

/// The system refused a connection on the local network (EPERM or EACCES),
/// as Android does without the local network permission.
class LocalNetworkDeniedException implements Exception {
  const LocalNetworkDeniedException();

  @override
  String toString() => 'LocalNetworkDeniedException';
}
