class WellnessTrendPoint {
  final DateTime date;
  final double restingPulse;
  final double breathingRate;
  final int calmnessScore; // 1 to 5 self-reflection
  final bool isSimulated;

  const WellnessTrendPoint({
    required this.date,
    required this.restingPulse,
    required this.breathingRate,
    required this.calmnessScore,
    this.isSimulated = true,
  });
}

