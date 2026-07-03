import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/personal_records_provider.dart';
import '../../models/personal_record.dart';
import '../../models/exercise.dart';
import '../../models/workout_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_time_utils.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';
import '../../routing/app_router.dart';
import 'package:go_router/go_router.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _showAllPRs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(personalRecordsProvider.notifier).fetchRecords();
      }
    });
  }

  List<Map<String, dynamic>> _buildWeeklyVolume(List<WorkoutSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return days.map((day) {
      final strengthVolume = sessions.where((s) => !s.isCardio).where((s) {
        final offset = Duration(minutes: s.startedAtOffsetMinutes ?? 0);
        final local = s.startedAt.toUtc().add(offset);
        return DateTime(local.year, local.month, local.day)
            .isAtSameMomentAs(day);
      }).fold<int>(0, (sum, s) => sum + s.totalVolumeKg);
      final cardioMinutes = sessions.where((s) => s.isCardio).where((s) {
        final offset = Duration(minutes: s.startedAtOffsetMinutes ?? 0);
        final local = s.startedAt.toUtc().add(offset);
        return DateTime(local.year, local.month, local.day)
            .isAtSameMomentAs(day);
      }).fold<int>(0, (sum, s) => sum + (s.cardioMinutes ?? 0));
      return {
        'day': DateFormat.E().format(day).substring(0, 2),
        'strength': strengthVolume,
        'cardio': cardioMinutes,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
    final weeklyData = _buildWeeklyVolume(sessions);
    final totalVolume =
        sessions.fold<int>(0, (acc, s) => acc + s.totalVolumeKg);
    final maxStrength = weeklyData.fold<int>(0, (max, d) {
      final strength = d['strength'] as int;
      return strength > max ? strength : max;
    });
    final maxCardio = weeklyData.fold<int>(0, (max, d) {
      final cardio = d['cardio'] as int;
      return cardio > max ? cardio : max;
    });
    // Scale cardio minutes so they are visible next to much larger strength volumes.
    final cardioScale = maxCardio > 0 ? (maxStrength / maxCardio) * 0.3 : 0.0;
    final chartMaxY = weeklyData.fold<double>(0, (max, d) {
      final strength = d['strength'] as int;
      final cardio = (d['cardio'] as int) * cardioScale;
      final total = strength + cardio;
      return total > max ? total : max;
    });
    final finalChartMaxY =
        (chartMaxY * 1.2).clamp(1000, double.infinity).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.progressTitle,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppLocalizations.of(context)!.progressSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Summary Cards ──
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: AppLocalizations.of(context)!.totalSessions,
                            value: sessions.length.toString(),
                            icon: Icons.fitness_center_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _SummaryCard(
                            label: AppLocalizations.of(context)!.totalVolume,
                            value:
                                '${(totalVolume / 1000).toStringAsFixed(1)}t',
                            icon: Icons.monitor_weight_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _SummaryCard(
                            label: AppLocalizations.of(context)!.thisWeek,
                            value: sessions
                                .where((s) => s.startedAt.isAfter(DateTime.now()
                                    .toUtc()
                                    .subtract(const Duration(days: 7))))
                                .length
                                .toString(),
                            icon: Icons.calendar_view_week_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Weekly Volume Chart ──
                    SectionHeader(
                        title: AppLocalizations.of(context)!.weeklyVolume),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    AppCard(
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: finalChartMaxY,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final data = weeklyData[groupIndex];
                                  final strength = data['strength'] as int;
                                  final cardio = data['cardio'] as int;
                                  return BarTooltipItem(
                                    '${AppLocalizations.of(context)!.tooltipStrengthKg(strength)}\n${AppLocalizations.of(context)!.tooltipCardioMin(cardio)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final idx = v.toInt();
                                    if (idx < 0 || idx >= weeklyData.length) {
                                      return const SizedBox();
                                    }
                                    return Text(
                                      weeklyData[idx]['day'] as String,
                                      style: const TextStyle(
                                        color: AppColors.onSurfaceMuted,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => const FlLine(
                                color: AppColors.divider,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: weeklyData.asMap().entries.map((e) {
                              final strength =
                                  (e.value['strength'] as int).toDouble();
                              final cardio =
                                  (e.value['cardio'] as int).toDouble();
                              final displayCardio = cardio * cardioScale;
                              final total = strength + displayCardio;
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: total,
                                    color: AppColors.surfaceVariant,
                                    width: 24,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                    rodStackItems: [
                                      BarChartRodStackItem(
                                        0,
                                        strength,
                                        AppColors.primary,
                                      ),
                                      if (displayCardio > 0)
                                        BarChartRodStackItem(
                                          strength,
                                          total,
                                          Colors.blueAccent,
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(
                            color: AppColors.primary,
                            label: AppLocalizations.of(context)!.strengthKg),
                        const SizedBox(width: AppSpacing.md),
                        _LegendDot(
                            color: Colors.blueAccent,
                            label: AppLocalizations.of(context)!.cardioMin),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppLocalizations.of(context)!.cardioScaledNotice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 11,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SectionHeader(
                            title: AppLocalizations.of(context)!
                                .personalRecordHistory),
                        if (!_showAllPRs)
                          TextButton(
                            onPressed: () => setState(() => _showAllPRs = true),
                            child: Text(AppLocalizations.of(context)!.loadAll),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _PRHistoryList(limit: _showAllPRs ? null : 5),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                        title: AppLocalizations.of(context)!.recentSessions),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            if (sessions.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: AppCard(
                    child: Column(
                      children: [
                        const Icon(Icons.history,
                            color: AppColors.onSurfaceMuted, size: 40),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No workouts yet',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.onSurfaceMuted,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Complete your first workout to see it here!',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final session = sessions[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _SessionTile(session: session),
                      );
                    },
                    childCount: sessions.length,
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PRHistoryList extends ConsumerWidget {
  final int? limit;

  const _PRHistoryList({this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prState = ref.watch(personalRecordsProvider);

    if (prState.isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (prState.records.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No personal records yet. Complete sets to start tracking your PRs!',
            style: TextStyle(color: AppColors.onSurfaceMuted),
          ),
        ),
      );
    }

    // Sort by date (newest first)
    final sortedRecords = List<PersonalRecord>.from(prState.records)
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    // Apply limit if specified
    final displayRecords =
        limit != null ? sortedRecords.take(limit!).toList() : sortedRecords;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final record = displayRecords[i];
          final date = record.achievedAt.formatWithOffset('EEE, MMM d', null);
          final isBodyweight = record.weightKg == 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.exerciseName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isBodyweight
                            ? '${record.reps} reps'
                            : '${record.weightKg.toStringAsFixed(0)} kg × ${record.reps}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                      if (!isBodyweight)
                        Text(
                          '1RM: ${record.estimatedOneRepMax.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: displayRecords.length,
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  final WorkoutSession session;

  const _SessionTile({required this.session});

  void _showSessionDetails(BuildContext context, WorkoutSession current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SessionDetailsSheet(session: current),
    );
  }

  String _getCorrectVolume(WorkoutSession session, double? userWeight) {
    final effectiveUserWeight = userWeight ?? 70.0;
    final totalVolume = session.exercises.fold<double>(0, (sum, exercise) {
      return sum +
          exercise.sets.where((s) => s.isCompleted).fold<double>(0,
              (setSum, set) {
            final weight = set.actualWeight ?? 0.0;
            final reps = set.actualReps ?? 0;
            final effectiveWeight =
                weight == 0.0 ? effectiveUserWeight : weight;
            return setSum + (effectiveWeight * reps);
          });
    });
    return '${totalVolume.round()} kg';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final live = ref
            .watch(sessionHistoryProvider)
            .valueOrNull
            ?.firstWhere((s) => s.id == session.id, orElse: () => session) ??
        session;
    final date = live.startedAt
        .formatWithOffset('EEE, MMM d', live.startedAtOffsetMinutes);
    final duration = live.isCardio
        ? '${live.cardioMinutes ?? 0} min'
        : (live.duration != null ? '${live.duration!.inMinutes} min' : '—');

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(AppLocalizations.of(context)!.deleteWorkoutTitle),
            content: Text(AppLocalizations.of(context)!.deleteWorkoutMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!.delete,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) =>
          ref.read(sessionHistoryProvider.notifier).deleteSession(session.id),
      child: AppCard(
        onTap: () => _showSessionDetails(context, live),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                live.isCardio ? Icons.directions_run : Icons.fitness_center,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(live.dayName,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '$date · $duration',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  live.isCardio
                      ? (live.distanceKm != null && live.distanceKm! > 0
                          ? '${live.distanceKm!.toStringAsFixed(1)} km'
                          : '${live.cardioMinutes ?? 0} min')
                      : _getCorrectVolume(live, user?.weightKg),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                Text('volume', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionDetailsSheet extends ConsumerWidget {
  final WorkoutSession session;

  const _SessionDetailsSheet({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = session.startedAt.formatWithOffset(
      'EEEE, MMM d, yyyy',
      session.startedAtOffsetMinutes,
    );
    final time = session.startedAt.formatWithOffset(
      'HH:mm',
      session.startedAtOffsetMinutes,
    );
    final duration =
        session.duration != null ? '${session.duration!.inMinutes} min' : '—';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.dayName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$date at $time',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DetailStat(
                    icon: Icons.timer_outlined,
                    value: duration,
                    label: 'Duration',
                  ),
                  _DetailStat(
                    icon: Icons.fitness_center,
                    value: '${session.exercises.length}',
                    label: 'Exercises',
                  ),
                  _DetailStat(
                    icon: Icons.monitor_weight_outlined,
                    value: '${session.totalVolumeKg}',
                    label: 'kg Volume',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to HomeScreen where Edit functionality exists
                        context.go(AppRoutes.home);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side:
                            BorderSide(color: AppColors.primary.withAlpha(120)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Delete workout?'),
                            content: const Text(
                                'This entry will be permanently deleted.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await ref
                              .read(sessionHistoryProvider.notifier)
                              .deleteSession(session.id);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Exercises
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ...session.exercises
                  .map((exercise) => _ExerciseDetailCard(exercise: exercise)),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseDetailCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final completedSets = exercise.sets.where((s) => s.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        backgroundColor: AppColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: completedSets == exercise.sets.length
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completedSets == exercise.sets.length
                        ? Icons.check
                        : Icons.fitness_center,
                    color: completedSets == exercise.sets.length
                        ? Colors.black
                        : AppColors.onSurfaceMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '$completedSets/${exercise.sets.length} sets completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Sets
            ...exercise.sets.where((s) => s.isCompleted).map((set) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 52),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${set.setNumber}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${set.actualReps ?? set.targetReps} reps · ${(set.actualWeight ?? set.targetWeight).toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceMuted,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
