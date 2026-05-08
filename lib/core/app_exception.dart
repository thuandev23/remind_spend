/// Typed exception hierarchy for the app.
/// All exceptions cross system boundaries (bridge, DB) — internal logic
/// should use assertions, not exceptions.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Native bridge returned an error (platform channel fault).
class BridgePullException extends AppException {
  const BridgePullException(super.message);
}

/// Drift DB write or read failed.
class DatabaseWriteException extends AppException {
  const DatabaseWriteException(super.message);
}
