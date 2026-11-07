enum AssistObservationCategory {
  responsiveness,
  breathingObserved,
  physicalComfort,
  actionsTaken,
  note,
}

class AssistObservation {
  final String id;
  final DateTime timestamp;
  final AssistObservationCategory category;
  final String description;

  const AssistObservation({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.description,
  });

  String get categoryTitle {
    switch (category) {
      case AssistObservationCategory.responsiveness:
        return 'Responsiveness';
      case AssistObservationCategory.breathingObserved:
        return 'Breathing Sign';
      case AssistObservationCategory.physicalComfort:
        return 'Posture / Comfort';
      case AssistObservationCategory.actionsTaken:
        return 'Action Taken';
      case AssistObservationCategory.note:
        return 'Field Note';
    }
  }
}

