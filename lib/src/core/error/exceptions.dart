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
