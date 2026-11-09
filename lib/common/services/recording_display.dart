/// Scoped to the visible recording route; analysis keeps the system default.
abstract interface class RecordingDisplay {
  Future<void> setKeepAwake(bool enabled);
}

class SystemManagedRecordingDisplay implements RecordingDisplay {
  const SystemManagedRecordingDisplay();

  @override
  Future<void> setKeepAwake(bool enabled) async {}
}
