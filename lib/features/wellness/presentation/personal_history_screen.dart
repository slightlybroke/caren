import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/caren_card.dart';
import '../../../core/widgets/simulated_banner.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/wellness_repository.dart';

class PersonalHistoryScreen extends ConsumerWidget {
  const PersonalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(personalTrendsProvider);
    final sessionsAsync = ref.watch(recentBreathingSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal History & Trends'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Private by default reassurance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'All trends and history here are stored privately and never shared with family circles.',
                      style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const SimulatedBanner(
              title: 'SIMULATED HISTORICAL TRENDS',
              message: 'The sample trend chart below uses mock data for demonstration.',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Weekly Trend Chart
            Text(
              '7-Day Resting Pulse Trend',
              style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.xs),
            CarenCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Resting Pulse (bpm)', style: AppTypography.caption),
                      StatusBadge(label: '7-Day View', type: BadgeType.neutral),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 180,
                    child: trendsAsync.when(
                      data: (trends) {
                        final spots = trends.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value.restingPulse);
                        }).toList();

                        return LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final index = val.toInt();
                                    if (index >= 0 && index < trends.length) {
                                      final date = trends[index].date;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          '${date.month}/${date.day}',
                                          style: AppTypography.caption,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (val, meta) {
                                    if (val % 5 == 0) {
                                      return Text('${val.toInt()}', style: AppTypography.caption);
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minY: 60,
                            maxY: 85,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.primaryContainer.withAlpha(90),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Chart error: $e')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Past Relaxation Sessions List
            Text(
              'Past Relaxation Sessions',
              style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.xs),
            sessionsAsync.when(
              data: (sessions) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return CarenCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(session.cadenceTitle, style: AppTypography.titleMedium),
                              Text(AppFormatters.formatDateTime(session.startTime), style: AppTypography.caption),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${session.durationMinutes} minutes • Completed peacefully',
                            style: AppTypography.bodyMedium,
                          ),
                          if (session.preSessionVitals != null && session.postSessionVitals != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Observed pulse change: ${session.preSessionVitals!.pulseRateBpm?.toInt() ?? "--"} → ${session.postSessionVitals!.pulseRateBpm?.toInt() ?? "--"} bpm',
                              style: AppTypography.caption.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

