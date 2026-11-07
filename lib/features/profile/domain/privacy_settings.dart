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
    this.enableSmartSpectraSimulatedMock = true,
    required this.lastUpdated,
  });

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

