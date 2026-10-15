class UniversalConfig {
  final bool isEnabled;
  final bool autoAccept;
  final double minFare;
  final double maxFare;
  final double pickupDistance;
  final double tripDistance;
  final int clickDelayMs;
  final bool soundAlert;
  final bool vibrationAlert;

  const UniversalConfig({
    this.isEnabled = true,
    this.autoAccept = true,
    this.minFare = 50.0,
    this.maxFare = 25000.0,
    this.pickupDistance = 5.0,
    this.tripDistance = 3000.0,
    this.clickDelayMs = 80,
    this.soundAlert = true,
    this.vibrationAlert = true,
  });

  UniversalConfig copyWith({
    bool? isEnabled,
    bool? autoAccept,
    double? minFare,
    double? maxFare,
    double? pickupDistance,
    double? tripDistance,
    int? clickDelayMs,
    bool? soundAlert,
    bool? vibrationAlert,
  }) {
    return UniversalConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      autoAccept: autoAccept ?? this.autoAccept,
      minFare: minFare ?? this.minFare,
      maxFare: maxFare ?? this.maxFare,
      pickupDistance: pickupDistance ?? this.pickupDistance,
      tripDistance: tripDistance ?? this.tripDistance,
      clickDelayMs: clickDelayMs ?? this.clickDelayMs,
      soundAlert: soundAlert ?? this.soundAlert,
      vibrationAlert: vibrationAlert ?? this.vibrationAlert,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'autoAccept': autoAccept,
      'minFare': minFare,
      'maxFare': maxFare,
      'pickupDistance': pickupDistance,
      'tripDistance': tripDistance,
      'clickDelayMs': clickDelayMs,
      'soundAlert': soundAlert,
      'vibrationAlert': vibrationAlert,
    };
  }

  factory UniversalConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UniversalConfig();
    return UniversalConfig(
      isEnabled: map['isEnabled'] as bool? ?? true,
      autoAccept: map['autoAccept'] as bool? ?? true,
      minFare: (map['minFare'] as num?)?.toDouble() ?? 50.0,
      maxFare: (map['maxFare'] as num?)?.toDouble() ?? 25000.0,
      pickupDistance: (map['pickupDistance'] as num?)?.toDouble() ?? 5.0,
      tripDistance: (map['tripDistance'] as num?)?.toDouble() ?? 3000.0,
      clickDelayMs: map['clickDelayMs'] as int? ?? 80,
      soundAlert: map['soundAlert'] as bool? ?? true,
      vibrationAlert: map['vibrationAlert'] as bool? ?? true,
    );
  }
}
