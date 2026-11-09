import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/caren_button.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/simulated_banner.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/vitals_measurement_widget.dart';
import '../../../services/emergency/emergency_dialer_service.dart';
import '../../../services/vitals/vitals_models.dart';
import '../../../services/vitals/vitals_provider.dart';
import '../../assist/data/assist_repository.dart';
import '../../assist/domain/assist_observation.dart';
import '../../assist/domain/assist_session.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';

class EmergencySessionScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const EmergencySessionScreen({super.key, this.sessionId});

  @override
  ConsumerState<EmergencySessionScreen> createState() => _EmergencySessionScreenState();
}

class _EmergencySessionScreenState extends ConsumerState<EmergencySessionScreen> {
  AssistSession? _session;
  final TextEditingController _customNoteController = TextEditingController();
  bool _isConsentedToSpotCheck = false;
  bool _isMeasuring = false;
  MeasurementResult? _consentMeasurement;
  VitalsStreamData? _vitalsStreamData;
  StreamSubscription<VitalsStreamData>? _vitalsSub;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _vitalsSub?.cancel();
    if (_isMeasuring) {
      try {
        ref.read(vitalsProvider).stopMeasurement(
              markInterrupted: true,
              interruptionReason: 'Navigated away from Emergency Session',
            );
      } catch (_) {}
    }
    _customNoteController.dispose();
    super.dispose();
  }

  void _loadSession() async {
    final session = await ref.read(assistRepositoryProvider).getActiveSession();
    if (mounted) {
      setState(() {
        _session = session ??
            AssistSession(
              id: widget.sessionId ?? 'ast_default',
              startTime: DateTime.now(),
              observations: [
                AssistObservation(
                  id: 'obs_0',
                  timestamp: DateTime.now(),
                  category: AssistObservationCategory.actionsTaken,
                  description: 'Assistance session started. Scene safe.',
                ),
              ],
            );
      });
    }
  }

  Future<void> _handleEmergencyCall(
    BuildContext context,
    WidgetRef ref,
    String emergencyNumber,
    String country,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contact Emergency ($emergencyNumber)'),
        content: Text(
          'Are you sure you want to open the dialer for $emergencyNumber ($country)?\n\nCAREN will never place a call automatically.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.phone, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(ctx, true),
            label: Text('Open Dialer ($emergencyNumber)', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (_session != null) {
        await ref.read(assistRepositoryProvider).logEmergencyServicesContacted(_session!.id);
        final updated = await ref.read(assistRepositoryProvider).getActiveSession();
        if (mounted && updated != null) {
          setState(() => _session = updated);
        }
      }

      final result = await ref.read(emergencyDialerServiceProvider).launchDialer(emergencyNumber);
      if (!result.isSuccess && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(result.errorMessage ?? 'Could not launch dialer for $emergencyNumber.'),
          ),
        );
      }
    }
  }

  void _addQuickObservation(AssistObservationCategory category, String text) async {
    if (_session == null) return;
    final obs = AssistObservation(
      id: 'obs_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      category: category,
      description: text,
    );

    await ref.read(assistRepositoryProvider).addObservation(_session!.id, obs);
    setState(() {
      _session = _session!.copyWith(
        observations: [..._session!.observations, obs],
      );
    });
  }

  void _addCustomNote() {
    final note = _customNoteController.text.trim();
    if (note.isEmpty) return;
    _addQuickObservation(AssistObservationCategory.note, note);
    _customNoteController.clear();
  }

  void _startConsentSpotCheck() async {
    final provider = ref.read(vitalsProvider);
    setState(() {
      _isMeasuring = true;
      _vitalsStreamData = null;
    });

    final permResult = await provider.requestCameraPermission();
    if (!permResult.granted) {
      if (mounted) setState(() => _isMeasuring = false);
      return;
    }

    try {
      await provider.initialize();
    } catch (_) {}

    final stream = provider.startMeasurement(
      config: const MeasurementConfig(
        target: MeasurementTarget.pulseOnly,
        durationSeconds: 15,
      ),
    );

    _vitalsSub = stream.listen(
      (data) {
        if (mounted) {
          setState(() => _vitalsStreamData = data);
          if (data.progress >= 1.0) {
            _finishConsentSpotCheck();
          }
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isMeasuring = false);
      },
    );
  }

  void _finishConsentSpotCheck() async {
    _vitalsSub?.cancel();
    final provider = ref.read(vitalsProvider);
    final result = await provider.stopMeasurement();
    if (mounted) {
      setState(() {
        _isMeasuring = false;
        _consentMeasurement = result;
      });
      _addQuickObservation(
        AssistObservationCategory.note,
        'Voluntary camera spot-check recorded: ${result.summaryLabel}. (For observation only)',
      );
    }
  }

  String _generateHandoffSummaryText() {
    if (_session == null) return '';
    final buffer = StringBuffer();
    buffer.writeln('=== CAREN INCIDENT HANDOFF SUMMARY ===');
    buffer.writeln('Start Time: ${AppFormatters.formatTime(_session!.startTime)}');
    buffer.writeln('Emergency Called: ${_session!.calledEmergencyServices ? "YES" : "NO"}');
    buffer.writeln('\nTimeline of Observations:');
    for (final obs in _session!.observations) {
      buffer.writeln('- [${AppFormatters.formatTime(obs.timestamp)}] (${obs.categoryTitle}): ${obs.description}');
    }
    buffer.writeln('\nDisclaimer: Factual observational timeline only. Not a medical diagnosis.');
    return buffer.toString();
  }

  void _showHandoffDialog() {
    if (_session == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: AppSpacing.screenPadding,
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Incident Handoff Summary', style: AppTypography.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Session began at ${AppFormatters.formatTime(_session!.startTime)}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              const SimulatedBanner(
                title: 'OBSERVATIONAL TIMELINE ONLY',
                message:
                    'This summary is a factual record of user notes and observations. It does not constitute a triage recommendation or diagnostic record.',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Timeline of Events:', style: AppTypography.labelLarge),
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Notes'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generateHandoffSummaryText()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Handoff summary copied to clipboard.')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ..._session!.observations.map((obs) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppFormatters.formatTime(obs.timestamp)} - ',
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Expanded(
                          child: Text(
                            '[${obs.categoryTitle}] ${obs.description}',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: AppSpacing.lg),
              CarenButton(
                label: 'Conclude and Archive Session',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  await ref.read(assistRepositoryProvider).completeSession(_session!.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  router.go('/emergency');
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Emergency assistance session concluded and archived.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Active Session • ${AppFormatters.formatTime(_session!.startTime)}'),
        actions: [
          TextButton(
            onPressed: _showHandoffDialog,
            child: const Text('Summary / Handoff'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always-Visible Responsive Emergency Call Card (Guaranteed NO RenderFlex overflow)
            Consumer(
              builder: (context, ref, child) {
                final profileAsync = ref.watch(userProfileProvider);
                final emergencyNumber =
                    profileAsync.asData?.value.emergencyNumber ?? EmergencyDirectory.fallbackNumber;
                final country = profileAsync.asData?.value.country ?? 'India';

                return CarenCard(
                  backgroundColor: AppColors.dangerContainer,
                  borderColor: AppColors.danger,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 28),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Immediate Need? ($emergencyNumber)',
                                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Contact dispatchers ($country) if condition changes.',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.phone_in_talk, size: 18),
                          label: Text(
                            'Call Emergency ($emergencyNumber)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _handleEmergencyCall(context, ref, emergencyNumber, country),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Observation Buttons
            Text('Quick Observation Logging', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.accessibility_new_outlined, size: 16),
                  label: const Text('Responsive & Alert'),
                  onPressed: () => _addQuickObservation(
                    AssistObservationCategory.responsiveness,
                    'Person is alert, oriented, and answering questions.',
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.airline_seat_flat_outlined, size: 16),
                  label: const Text('Resting Comfortably'),
                  onPressed: () => _addQuickObservation(
                    AssistObservationCategory.physicalComfort,
                    'Person seated or lying in safe recovery position.',
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.local_drink_outlined, size: 16),
                  label: const Text('Offered Water'),
                  onPressed: () => _addQuickObservation(
                    AssistObservationCategory.actionsTaken,
                    'Offered a small sip of water while seated.',
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.air_outlined, size: 16),
                  label: const Text('Regular Breathing Observed'),
                  onPressed: () => _addQuickObservation(
                    AssistObservationCategory.breathingObserved,
                    'Breathing appears unlabored and steady.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Add Custom Note
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customNoteController,
                    decoration: InputDecoration(
                      hintText: 'Add timestamped note or action...',
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addCustomNote,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Optional Consented Camera Measurement (Strictly optional, not a prerequisite)
            CarenCard(
              backgroundColor: AppColors.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam_outlined, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Optional Consented Spot Check',
                          style: AppTypography.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Spot check may only be explored when safe, non-critical, and the individual explicitly consents.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Person is comfortable and consented to camera spot-check',
                        style: AppTypography.labelMedium,
                      ),
                      value: _isConsentedToSpotCheck,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isConsentedToSpotCheck = v ?? false),
                    ),
                  ),
                  if (_isConsentedToSpotCheck) ...[
                    if (_isMeasuring) ...[
                      const SizedBox(height: AppSpacing.sm),
                      VitalsMeasurementWidget(
                        streamData: _vitalsStreamData,
                        onCancel: () {
                          _vitalsSub?.cancel();
                          ref.read(vitalsProvider).cancelMeasurement();
                          setState(() => _isMeasuring = false);
                        },
                      ),
                    ] else ...[
                      CarenButton(
                        label: 'Take 15s Voluntary Spot Check (12s window)',
                        variant: CarenButtonVariant.outline,
                        onPressed: _startConsentSpotCheck,
                      ),
                    ],
                  ],
                  if (_consentMeasurement != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    StatusBadge(
                      label: 'Observed: ${_consentMeasurement!.summaryLabel}',
                      type: BadgeType.info,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Observations Timeline
            Text('Session Timeline (${_session!.observations.length})', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _session!.observations.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final obs = _session!.observations.reversed.toList()[index];
                return CarenCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppFormatters.formatTime(obs.timestamp),
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusBadge(label: obs.categoryTitle, type: BadgeType.neutral),
                            const SizedBox(height: 2),
                            Text(obs.description, style: AppTypography.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

