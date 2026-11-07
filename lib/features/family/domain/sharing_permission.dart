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

