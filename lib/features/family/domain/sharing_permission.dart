/// Transparent, explicit, and revocable permissions for family sharing.
class SharingPermission {
  final bool shareCheckInStatus; // Whether family can see if check-in was completed
  final bool shareSelfReportedMood; // Energy/feeling summary
  final bool shareVitalsMeasurements; // Camera-based spot check numbers
  final bool shareNotes; // Optional personal notes
  final DateTime lastUpdated;

  const SharingPermission({
    this.shareCheckInStatus = true,
    this.shareSelfReportedMood = true,
    this.shareVitalsMeasurements = false, // Private by default
    this.shareNotes = false, // Private by default
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'shareCheckInStatus': shareCheckInStatus,
      'shareSelfReportedMood': shareSelfReportedMood,
      'shareVitalsMeasurements': shareVitalsMeasurements,
      'shareNotes': shareNotes,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory SharingPermission.fromMap(Map<String, dynamic> map) {
    return SharingPermission(
      shareCheckInStatus: map['shareCheckInStatus'] as bool? ?? true,
      shareSelfReportedMood: map['shareSelfReportedMood'] as bool? ?? true,
      shareVitalsMeasurements: map['shareVitalsMeasurements'] as bool? ?? false,
      shareNotes: map['shareNotes'] as bool? ?? false,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  SharingPermission copyWith({
    bool? shareCheckInStatus,
    bool? shareSelfReportedMood,
    bool? shareVitalsMeasurements,
    bool? shareNotes,
    DateTime? lastUpdated,
  }) {
    return SharingPermission(
      shareCheckInStatus: shareCheckInStatus ?? this.shareCheckInStatus,
      shareSelfReportedMood: shareSelfReportedMood ?? this.shareSelfReportedMood,
      shareVitalsMeasurements: shareVitalsMeasurements ?? this.shareVitalsMeasurements,
      shareNotes: shareNotes ?? this.shareNotes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
