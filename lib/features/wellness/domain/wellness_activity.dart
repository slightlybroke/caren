import 'package:flutter/material.dart';

/// Categories of personal relaxation experiences in caren Me.
enum WellnessCategory { breathing, mindfulness, bodyRelaxation, quietMoments }

extension WellnessCategoryExtension on WellnessCategory {
  String get displayName {
    switch (this) {
      case WellnessCategory.breathing:
        return 'Guided Breathing';
      case WellnessCategory.mindfulness:
        return 'Mindfulness & Grounding';
      case WellnessCategory.bodyRelaxation:
        return 'Body Relaxation';
      case WellnessCategory.quietMoments:
        return 'Quiet Moments';
    }
  }

  IconData get icon {
    switch (this) {
      case WellnessCategory.breathing:
        return Icons.air_rounded;
      case WellnessCategory.mindfulness:
        return Icons.psychology_outlined;
      case WellnessCategory.bodyRelaxation:
        return Icons.accessibility_new_rounded;
      case WellnessCategory.quietMoments:
        return Icons.bedtime_outlined;
    }
  }
}

/// A discrete step or phase in a relaxation exercise.
class WellnessActivityStep {
  final String title;
  final String instruction;
  final String spokenCue;
  final int durationSeconds;

  const WellnessActivityStep({
    required this.title,
    required this.instruction,
    required this.spokenCue,
    this.durationSeconds = 20,
  });
}

/// Model representing a structured personal relaxation activity.
class WellnessActivity {
  final String id;
  final String title;
  final String subtitle;
  final WellnessCategory category;
  final String description;
  final IconData icon;
  final int defaultDurationMinutes;
  final List<WellnessActivityStep> steps;
  final List<String> reflectionPrompts;

  const WellnessActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    required this.icon,
    required this.defaultDurationMinutes,
    required this.steps,
    this.reflectionPrompts = const [],
  });

  int get calculatedTotalSeconds =>
      steps.fold(0, (sum, step) => sum + step.durationSeconds);
}

/// Pre-configured relaxation activities for caren Me.
class WellnessCatalog {
  WellnessCatalog._();

  static const WellnessActivity fiveSensesGrounding = WellnessActivity(
    id: 'mindfulness_5_senses',
    title: '5-4-3-2-1 Grounding',
    subtitle: 'Anchor your attention in your immediate surroundings',
    category: WellnessCategory.mindfulness,
    description: 'A clinically recognized grounding technique to gently anchor yourself in the present moment by noticing sensory details around you.',
    icon: Icons.nature_people_outlined,
    defaultDurationMinutes: 3,
    steps: [
      WellnessActivityStep(
        title: 'Preparation',
        instruction: 'Sit comfortably and let your shoulders drop. Take one gentle breath.',
        spokenCue: 'Find a comfortable seat. Let your shoulders drop, and take one slow breath.',
        durationSeconds: 12,
      ),
      WellnessActivityStep(
        title: '5 Things You Can See',
        instruction:
            'Look around and notice 5 distinct objects, patterns, or colors.',
        spokenCue: 'Notice five things you can see around you. Observe their shapes and colors.',
        durationSeconds: 24,
      ),
      WellnessActivityStep(
        title: '4 Things You Can Feel',
        instruction: 'Notice 4 physical textures (your clothes, the floor under your feet, the chair).',
        spokenCue: 'Notice four things you can physically feel. The fabric of your clothes, or the ground beneath your feet.',
        durationSeconds: 24,
      ),
      WellnessActivityStep(
        title: '3 Things You Can Hear',
        instruction: 'Listen carefully for 3 distinct ambient sounds nearby or in the distance.',
        spokenCue: 'Listen closely for three different sounds. Near or far.',
        durationSeconds: 22,
      ),
      WellnessActivityStep(
        title: '2 Things You Can Smell',
        instruction: 'Notice 2 scents or the natural fresh quality of the air you breathe.',
        spokenCue: 'Notice two things you can smell, or simply the cool sensation of incoming air.',
        durationSeconds: 18,
      ),
      WellnessActivityStep(
        title: '1 Thing You Are Grateful For',
        instruction: 'Bring to mind one small comfort or moment from today.',
        spokenCue:
            'Bring to mind one small thing you are grateful for right now.',
        durationSeconds: 18,
      ),
    ],
  );

  static const WellnessActivity presentMomentMindfulness = WellnessActivity(
    id: 'mindfulness_present_moment',
    title: 'Present-Moment Awareness',
    subtitle: 'Calm mental chatter and rest in the now',
    category: WellnessCategory.mindfulness,
    description: 'Gentle attention training to step back from rushing thoughts and cultivate spacious calm.',
    icon: Icons.spa_outlined,
    defaultDurationMinutes: 3,
    steps: [
      WellnessActivityStep(
        title: 'Arrival',
        instruction: 'Allow your attention to rest on the physical feeling of breathing.',
        spokenCue: "Let's begin. Allow your attention to rest gently on the feeling of breathing.",
        durationSeconds: 20,
      ),
      WellnessActivityStep(
        title: 'Releasing Tension',
        instruction: 'Notice if your brow, jaw, or shoulders are holding tension. Soften them.',
        spokenCue: 'Soften your jaw, your brow, and let your shoulders rest naturally.',
        durationSeconds: 30,
      ),
      WellnessActivityStep(
        title: 'Observing Thoughts',
        instruction:
            'Let thoughts come and go like clouds passing through an open sky.',
        spokenCue: 'Let thoughts drift by like clouds in an open sky. You do not need to follow them.',
        durationSeconds: 35,
      ),
      WellnessActivityStep(
        title: 'Returning',
        instruction:
            'Take one deep, appreciative breath as you prepare to return.',
        spokenCue: 'Take one deep, appreciative breath, and gently return your awareness.',
        durationSeconds: 20,
      ),
    ],
  );

  static const WellnessActivity progressiveMuscleRelaxation = WellnessActivity(
    id: 'body_pmr',
    title: 'Progressive Muscle Relaxation',
    subtitle: 'Systematically release physical tension throughout the body',
    category: WellnessCategory.bodyRelaxation,
    description: 'Guided tension and release cycles that signal deep safety to the autonomic nervous system.',
    icon: Icons.self_improvement_rounded,
    defaultDurationMinutes: 4,
    steps: [
      WellnessActivityStep(
        title: 'Begin',
        instruction:
            'Settle into a supported chair or lie down. Uncross your legs.',
        spokenCue:
            'Settle comfortably into your seat. Uncross your legs and relax.',
        durationSeconds: 15,
      ),
      WellnessActivityStep(
        title: 'Hands & Arms',
        instruction: 'Gently clench both fists for 5 seconds... now open and release completely.',
        spokenCue: 'Clench your fists gently for five seconds. Now open your hands and let all tension melt away.',
        durationSeconds: 25,
      ),
      WellnessActivityStep(
        title: 'Shoulders & Neck',
        instruction: 'Raise shoulders toward your ears gently... hold... and drop them completely.',
        spokenCue: 'Raise your shoulders gently toward your ears. Hold briefly. Now drop them completely down.',
        durationSeconds: 25,
      ),
      WellnessActivityStep(
        title: 'Face & Jaw',
        instruction: 'Squeeze your eyes and clench jaw gently... now soften your entire face.',
        spokenCue: 'Scrunch your face and jaw gently. And now, let your jaw unclench and your face soften.',
        durationSeconds: 25,
      ),
      WellnessActivityStep(
        title: 'Full Body Ease',
        instruction: 'Feel the warm, heavy sensation of relaxation flowing from head to toes.',
        spokenCue:
            'Feel a wave of calm and ease flowing through your entire body.',
        durationSeconds: 30,
      ),
    ],
  );

  static const WellnessActivity shoulderJawRelease = WellnessActivity(
    id: 'body_shoulder_jaw',
    title: 'Shoulder & Jaw Decompression',
    subtitle: 'Targeted physical reset for screen fatigue and posture',
    category: WellnessCategory.bodyRelaxation,
    description: 'A quick 2-minute targeted release for the areas that accumulate daily stress and screen posture fatigue.',
    icon: Icons.accessibility_outlined,
    defaultDurationMinutes: 2,
    steps: [
      WellnessActivityStep(
        title: 'Shoulder Roll',
        instruction:
            'Roll your shoulders backward in slow, deliberate circles 3 times.',
        spokenCue: 'Roll your shoulders backward in slow, deliberate circles.',
        durationSeconds: 25,
      ),
      WellnessActivityStep(
        title: 'Jaw Unclenching',
        instruction: 'Part your lips slightly. Let your tongue rest gently behind your upper teeth.',
        spokenCue:
            'Part your lips slightly. Let your jaw drop open comfortably.',
        durationSeconds: 25,
      ),
      WellnessActivityStep(
        title: 'Neck Elongation',
        instruction: 'Gently tilt your head right, then left, stretching comfortably without strain.',
        spokenCue: 'Gently tilt your head to the side, feeling a mild, pleasant stretch.',
        durationSeconds: 30,
      ),
      WellnessActivityStep(
        title: 'Reset',
        instruction: 'Take one smooth breath in and let everything settle.',
        spokenCue: 'Breathe in smoothly, and let your body settle into ease.',
        durationSeconds: 20,
      ),
    ],
  );

  static const WellnessActivity quietReflection = WellnessActivity(
    id: 'quiet_timed_moment',
    title: 'Quiet Reflection',
    subtitle: 'A quiet, unhurried interval with gentle contemplation',
    category: WellnessCategory.quietMoments,
    description: 'A peaceful interval free of demands. Minimalist timer with soothing contemplative prompts.',
    icon: Icons.nights_stay_outlined,
    defaultDurationMinutes: 3,
    steps: [
      WellnessActivityStep(
        title: 'Quiet Beginning',
        instruction: 'Give yourself permission to pause. There is nowhere else you need to be.',
        spokenCue:
            'Give yourself permission to pause. Enjoy this quiet moment.',
        durationSeconds: 30,
      ),
      WellnessActivityStep(
        title: 'Peaceful Space',
        instruction:
            'Notice the quiet rhythm of your breath as time unfolds gently.',
        spokenCue: 'Notice the gentle stillness around you.',
        durationSeconds: 60,
      ),
      WellnessActivityStep(
        title: 'Renewal',
        instruction: 'Acknowledge this time you gave yourself with gratitude.',
        spokenCue: 'Take a gentle breath as this quiet moment comes to a peaceful close.',
        durationSeconds: 30,
      ),
    ],
    reflectionPrompts: [
      'Notice the natural rhythm of your breath.',
      'There is nowhere else you need to be right now.',
      'Give yourself permission to pause and reset.',
      'Let each breath anchor you in this moment.',
      'Rest in the quiet stillness of right now.',
    ],
  );

  static List<WellnessActivity> get allActivities => [
    fiveSensesGrounding,
    presentMomentMindfulness,
    progressiveMuscleRelaxation,
    shoulderJawRelease,
    quietReflection,
  ];

  static List<WellnessActivity> getActivitiesByCategory(WellnessCategory cat) =>
      allActivities.where((a) => a.category == cat).toList();

  static WellnessActivity? findById(String id) {
    try {
      return allActivities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
