class SensorStreamMetadata {
  final String source;
  final String unit;
  final String coordinateFrame;
  final int? requestedSamplingPeriodMicroseconds;
  final int sampleCount;
  final String? error;

  const SensorStreamMetadata({
    required this.source,
    required this.unit,
    required this.coordinateFrame,
    required this.requestedSamplingPeriodMicroseconds,
    required this.sampleCount,
    this.error,
  });

  String get status {
    if (sampleCount > 0) return 'recorded';
    if (error != null) return 'unavailable_or_failed';
    return 'no_data';
  }

  factory SensorStreamMetadata.fromJson(Map<String, dynamic> json) {
    return SensorStreamMetadata(
      source: json['source'] as String,
      unit: json['unit'] as String,
      coordinateFrame: json['coordinateFrame'] as String,
      requestedSamplingPeriodMicroseconds:
          (json['requestedSamplingPeriodMicroseconds'] as num?)?.toInt(),
      sampleCount: (json['sampleCount'] as num).toInt(),
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'unit': unit,
      'coordinateFrame': coordinateFrame,
      'requestedSamplingPeriodMicroseconds':
          requestedSamplingPeriodMicroseconds,
      'sampleCount': sampleCount,
      'status': status,
      'error': error,
    };
  }
}

class SensorRecordingMetadata {
  static const currentFormatVersion = 1;

  final int formatVersion;
  final Map<String, SensorStreamMetadata> streams;

  const SensorRecordingMetadata({
    this.formatVersion = currentFormatVersion,
    required this.streams,
  });

  factory SensorRecordingMetadata.fromJson(Map<String, dynamic> json) {
    final rawStreams = json['streams'] as Map<String, dynamic>;
    return SensorRecordingMetadata(
      formatVersion: (json['formatVersion'] as num).toInt(),
      streams: rawStreams.map(
        (name, value) => MapEntry(
          name,
          SensorStreamMetadata.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formatVersion': formatVersion,
      'streams': streams.map(
        (name, metadata) => MapEntry(name, metadata.toJson()),
      ),
    };
  }
}
