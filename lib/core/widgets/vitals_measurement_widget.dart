import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../../services/vitals/vitals_models.dart';
import 'simulated_banner.dart';

class VitalsMeasurementWidget extends StatelessWidget {
  final VitalsStreamData? streamData;
  final VoidCallback onCancel;
  final bool isMeasuring;

  const VitalsMeasurementWidget({
    super.key,
    required this.streamData,
    required this.onCancel,
    this.isMeasuring = true,
  });

  String _getStatusHeader(MeasurementStatus status) {
    switch (status) {
      case MeasurementStatus.idle:
        return 'Ready to Begin';
      case MeasurementStatus.preparingCamera:
        return 'Preparing Camera Feed';
      case MeasurementStatus.positioningAndLightingGuidance:
        return 'Positioning & Lighting Guidance';
      case MeasurementStatus.measuring:
        return 'Measuring Physiological Signals';
      case MeasurementStatus.waitingForReliableSignal:
        return 'Waiting for Reliable Signal';
      case MeasurementStatus.validMeasurement:
        return 'Valid Measurement';
      case MeasurementStatus.measurementUnavailable:
        return 'Measurement Unavailable';
      case MeasurementStatus.measurementCancelled:
        return 'Measurement Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = streamData?.progress ?? 0.0;
    final isFaceDetected = streamData?.isFaceDetected ?? false;
    final pulse = streamData?.instantaneousPulse;
    final breathing = streamData?.instantaneousBreathing;
    final isSimulated = streamData?.isSimulated ?? true;
    final status = streamData?.status ?? MeasurementStatus.preparingCamera;
    final elapsed = streamData?.elapsedSeconds ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSimulated) ...[
            const SimulatedBanner(),
            const SizedBox(height: AppSpacing.md),
          ],

          // Camera Viewport: Real Android CameraX PreviewView or Mock Animation
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(235),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hardware Camera feed on Android, or ambient gradient simulation for mock/dev
                  if (!isSimulated && defaultTargetPlatform == TargetPlatform.android)
                    const AndroidView(
                      viewType: 'com.caren.app/smartspectra_camera_view',
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            isFaceDetected
                                ? AppColors.primaryLight.withAlpha(60)
                                : Colors.white.withAlpha(20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                  // Face Positioning Oval Guide overlay
                  Container(
                    width: 130,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(70),
                      border: Border.all(
                        color: isFaceDetected ? AppColors.secondary : Colors.white.withAlpha(120),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isFaceDetected ? Icons.face_rounded : Icons.face_retouching_natural,
                        size: 48,
                        color: isFaceDetected
                            ? AppColors.secondary.withAlpha(160)
                            : Colors.white.withAlpha(80),
                      ),
                    ),
                  ),

                  // Real-Time Photoplethysmogram (PPG) Waveform Overlay
                  if (streamData?.waveformValue != null)
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      height: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Colors.black.withAlpha(120),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: CustomPaint(
                            painter: _PpgWaveformPainter(
                              waveformValue: streamData!.waveformValue!,
                              progress: progress,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Status Pill on top of camera
                  Positioned(
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFaceDetected ? Icons.check_circle : Icons.warning_amber_rounded,
                            size: 14,
                            color: isFaceDetected ? AppColors.secondaryLight : Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusHeader(status),
                            style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Metric-Aware Confidence Readouts
          Row(
            children: [
              Expanded(
                child: _LiveMetricTile(
                  icon: Icons.favorite_rounded,
                  label: 'Pulse Rate (12s window)',
                  value: pulse != null
                      ? '${pulse.toInt()} bpm'
                      : elapsed < 12
                          ? 'Window: ${elapsed}s / 12s'
                          : 'Validating signal...',
                  isValid: pulse != null,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _LiveMetricTile(
                  icon: Icons.air_rounded,
                  label: 'Breathing (30s window)',
                  value: breathing != null
                      ? '${breathing.toInt()} br/min'
                      : elapsed < 30
                          ? 'Window: ${elapsed}s / 30s'
                          : 'Validating signal...',
                  isValid: breathing != null,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Detailed guidance & Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  streamData?.statusText ?? 'Positioning camera...',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (streamData?.confidenceScore != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'SDK Confidence: ${(streamData!.confidenceScore! * 100).toInt()}%'
              '${streamData?.stabilityScore != null ? ' • Stability: ${(streamData!.stabilityScore! * 100).toInt()}%' : ''}',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          Center(
            child: TextButton(
              onPressed: onCancel,
              child: const Text('Cancel Measurement', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isValid;
  final Color color;

  const _LiveMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isValid,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isValid ? AppColors.surfaceVariant : AppColors.surfaceVariant.withAlpha(120),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isValid ? color.withAlpha(60) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isValid ? color : AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    color: isValid ? AppColors.primaryDark : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PpgWaveformPainter extends CustomPainter {
  final double waveformValue;
  final double progress;

  _PpgWaveformPainter({
    required this.waveformValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryLight
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2;
    path.moveTo(0, midY);

    for (double x = 0; x <= size.width; x += 4) {
      final normalizedX = x / size.width;
      final wave = (waveformValue * 14.0) * (1.0 - (normalizedX - 0.5).abs());
      final y = midY + (wave * (x % 16 == 0 ? -1 : 1) * 0.5);
      path.lineTo(x, y.clamp(2.0, size.height - 2.0));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PpgWaveformPainter oldDelegate) {
    return oldDelegate.waveformValue != waveformValue || oldDelegate.progress != progress;
  }
}
