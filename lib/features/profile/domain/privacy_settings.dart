class PrivacySettings {
  final bool shareCheckInStatusWithFamily;
  final bool shareSelfReportedWellness;
  final bool shareCameraMeasurementsWithFamily;
  final bool storeMeasurementsLocallyOnly;
  final bool enableSmartSpectraSimulatedMock;
  final DateTime lastUpdated;

  const PrivacySettings({
    this.shareCheckInStatusWithFamily = true,
    this.shareSelfReportedWellness = true,
    this.shareCameraMeasurementsWithFamily = false,
    this.storeMeasurementsLocallyOnly = true,
    this.enableSmartSpectraSimulatedMock = false,
    required this.lastUpdated,
  });

  factory PrivacySettings.defaultSettings() => PrivacySettings(
        shareCheckInStatusWithFamily: true,
        shareSelfReportedWellness: true,
        shareCameraMeasurementsWithFamily: false,
        storeMeasurementsLocallyOnly: true,
        enableSmartSpectraSimulatedMock: false,
        lastUpdated: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'shareCheckInStatusWithFamily': shareCheckInStatusWithFamily,
        'shareSelfReportedWellness': shareSelfReportedWellness,
        'shareCameraMeasurementsWithFamily': shareCameraMeasurementsWithFamily,
        'storeMeasurementsLocallyOnly': storeMeasurementsLocallyOnly,
        'enableSmartSpectraSimulatedMock': enableSmartSpectraSimulatedMock,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  PrivacySettings copyWith({
    bool? shareCheckInStatusWithFamily,
    bool? shareSelfReportedWellness,
    bool? shareCameraMeasurementsWithFamily,
    bool? storeMeasurementsLocallyOnly,
    bool? enableSmartSpectraSimulatedMock,
    DateTime? lastUpdated,
  }) {
    return PrivacySettings(
      shareCheckInStatusWithFamily:
          shareCheckInStatusWithFamily ?? this.shareCheckInStatusWithFamily,
      shareSelfReportedWellness:
          shareSelfReportedWellness ?? this.shareSelfReportedWellness,
      shareCameraMeasurementsWithFamily:
          shareCameraMeasurementsWithFamily ?? this.shareCameraMeasurementsWithFamily,
      storeMeasurementsLocallyOnly:
          storeMeasurementsLocallyOnly ?? this.storeMeasurementsLocallyOnly,
      enableSmartSpectraSimulatedMock:
          enableSmartSpectraSimulatedMock ?? this.enableSmartSpectraSimulatedMock,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

