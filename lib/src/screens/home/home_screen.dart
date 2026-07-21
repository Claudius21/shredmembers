import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/workout_plan.dart';
import '../../models/workout_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/list_extensions.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_chip.dart';

/// Replaces commas with dots so German users can type `5,3` instead of `5.3`.
class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(',', '.');
    // Prevent more than one decimal point
    final parts = text.split('.');
    if (parts.length > 2) {
      text = '${parts.first}.${parts.sublist(1).join('')}';
    }
    return newValue.copyWith(
      text: text,
      selection: newValue.selection.copyWith(
        baseOffset: newValue.selection.baseOffset.clamp(0, text.length),
        extentOffset: newValue.selection.extentOffset.clamp(0, text.length),
      ),
    );
  }
}

double? _parseDoubleLocalized(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  return double.tryParse(normalized);
}

int? _parseIntLocalized(String value) {
  return int.tryParse(value.trim());
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ConfettiController _confettiCtrl;
  // Tracks 'YYYY-Www-lifting' / 'YYYY-Www-cardio' keys already celebrated
  final Set<String> _celebrated = {};
  late final PageController _pageController;
  int _currentWorkoutIndex = 0;
  List<WorkoutDay> _sortedDays = [];

  String _weekKey(String type) {
    final now = DateTime.now();
    final weekOfYear =
        ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).ceil();
    return '${now.year}-W$weekOfYear-$type';
  }

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _pageController = PageController();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final activePlan = ref.watch(activePlanProvider);
    final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
    final thisWeekSessions = sessions
        .where((s) => s.startedAt
            .isAfter(DateTime.now().toUtc().subtract(const Duration(days: 7))))
        .toList();
    final thisWeekLifting = thisWeekSessions.where((s) => !s.isCardio).length;
    final thisWeekCardio = thisWeekSessions.where((s) => s.isCardio).length;
    final weeklyTarget = user?.weeklyTargetDays ?? 4;

    // Fire confetti once per week when lifting or cardio hits the weekly target
    ref.listen(sessionHistoryProvider, (prev, next) {
      final prevSessions = prev?.valueOrNull ?? [];
      final nextSessions = next.valueOrNull ?? [];
      if (nextSessions.length <= prevSessions.length) return;

      final weekStart =
          DateTime.now().toUtc().subtract(const Duration(days: 7));
      final weekSessions =
          nextSessions.where((s) => s.startedAt.isAfter(weekStart)).toList();
      final lifting = weekSessions.where((s) => !s.isCardio).length;
      final cardio = weekSessions.where((s) => s.isCardio).length;
      final target = user?.weeklyTargetDays ?? 4;

      for (final type in ['Lifting', 'Cardio']) {
        final count = type == 'Lifting' ? lifting : cardio;
        final key = _weekKey(type);
        if (count >= target && !_celebrated.contains(key)) {
          _celebrated.add(key);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _confettiCtrl.play();
              _showTargetDialog(type);
            }
          });
          break;
        }
      }
    });

    final now = DateTime.now();
    final today = DateFormat('EEEE, MMM d').format(now);
    final l10n = AppLocalizations.of(context)!;
    final greeting = now.hour < 12
        ? l10n.goodMorning
        : now.hour < 18
            ? l10n.goodAfternoon
            : l10n.goodEvening;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () => ref.refresh(sessionHistoryProvider.future),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.profile),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting,',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.onSurfaceMuted,
                                          ),
                                    ),
                                    Text(
                                      user?.name ?? l10n.athlete,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.profile),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (user?.name.isNotEmpty == true)
                                          ? user!.name[0].toUpperCase()
                                          : 'A',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            today,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // ── Weekly stats row ──
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  value: '$thisWeekLifting',
                                  label: l10n.liftingThisWeek,
                                  icon: Icons.fitness_center_rounded,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _StatCard(
                                  value: '$thisWeekCardio',
                                  label: l10n.cardioThisWeek,
                                  icon: Icons.directions_run,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _StatCard(
                                  value: '${user?.weeklyTargetDays ?? 4}',
                                  label: l10n.weeklyTarget,
                                  icon: Icons.flag_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // ── Today's Workout card ──
                          SectionHeader(
                            title: l10n.todaysWorkout,
                            actionLabel: l10n.allPlans,
                            onAction: () => context.go(AppRoutes.plans),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                  // ── Resume banner (shown when app was closed during a workout) ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    sliver: _ResumeBanner(),
                  ),
                  if (activePlan != null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: _TodayWorkoutCard(plan: activePlan),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: AppCard(
                          child: Column(
                            children: [
                              const Icon(Icons.add_circle_outline,
                                  color: AppColors.primary, size: 40),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.noActivePlan,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.noActivePlanDescription,
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton(
                                label: l10n.browsePlans,
                                onPressed: () => context.go(AppRoutes.plans),
                                width: 180,
                                height: 44,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogCardio(context, ref),
                        icon: const Icon(Icons.directions_run, size: 18),
                        label: Text(l10n.logCardio),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color: AppColors.primary.withAlpha(120)),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: l10n.recentActivity,
                            actionLabel: l10n.seeAll,
                            onAction: () => context.go(AppRoutes.progress),
                          ),
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
                                l10n.noWorkoutsYet,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.noWorkoutsYetDescription,
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
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _SessionTile(session: session),
                            );
                          },
                          childCount: sessions.length.clamp(0, 10),
                        ),
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              ),
            ),
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            gravity: 0.2,
            colors: const [
              AppColors.primary,
              Colors.white,
              Color(0xFF00E676),
              Color(0xFFFFD700),
              Color(0xFFFF6B6B),
            ],
          ),
        ),
      ],
    );
  }

  void _showTargetDialog(String type) {
    final l10n = AppLocalizations.of(context)!;
    final icon = type == 'Lifting' ? '🏋️' : '🏃';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              l10n.targetHitTitle(type),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.targetHitMessage(type),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.keepItUp,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    if (session == null)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.workoutTracking),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.fitness_center_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout in progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      session.dayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

void _showLogCardio(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LogCardioSheet(ref: ref),
  );
}

class _LogCardioSheet extends StatefulWidget {
  final WidgetRef ref;
  const _LogCardioSheet({required this.ref});

  @override
  State<_LogCardioSheet> createState() => _LogCardioSheetState();
}

class _LogCardioSheetState extends State<_LogCardioSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Running';
  int _minutes = 30;
  double _distanceKm = 0;
  int _calories = 0;
  bool _saving = false;

  static const _cardioTypes = [
    'Running',
    'Cycling',
    'Swimming',
    'Rowing',
    'Elliptical',
    'Jump Rope',
    'Walking',
    'Other',
  ];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);
    final now = DateTime.now();
    final session = WorkoutSession(
      id: 'session-live-${now.millisecondsSinceEpoch}',
      planId: '',
      dayId: '',
      dayName: _type,
      startedAt: now.toUtc(),
      startedAtOffsetMinutes: now.timeZoneOffset.inMinutes,
      finishedAt: now.toUtc(),
      finishedAtOffsetMinutes: now.timeZoneOffset.inMinutes,
      status: SessionStatus.completed,
      exercises: const [],
      totalVolumeKg: 0,
      sessionType: SessionType.cardio,
      cardioMinutes: _minutes,
      distanceKm: _distanceKm > 0 ? _distanceKm : null,
      caloriesBurned: _calories > 0 ? _calories : null,
    );
    await widget.ref.read(sessionHistoryProvider.notifier).addSession(session);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceMuted.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Log Cardio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xl),
            DropdownButtonFormField<String>(
              value: _type,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Activity type',
                prefixIcon:
                    Icon(Icons.directions_run, color: AppColors.onSurfaceMuted),
              ),
              items: _cardioTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: _minutes.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                prefixIcon:
                    Icon(Icons.timer_outlined, color: AppColors.onSurfaceMuted),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid duration';
                return null;
              },
              onSaved: (v) => _minutes = int.tryParse(v ?? '') ?? 30,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: '',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Distance (km) – optional',
                prefixIcon:
                    Icon(Icons.straighten, color: AppColors.onSurfaceMuted),
              ),
              inputFormatters: [_DecimalInputFormatter()],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = _parseDoubleLocalized(v);
                if (n == null || n < 0) return 'Enter a valid distance';
                return null;
              },
              onSaved: (v) => _distanceKm = _parseDoubleLocalized(v ?? '') ?? 0,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories burned – optional',
                prefixIcon: Icon(Icons.local_fire_department_outlined,
                    color: AppColors.onSurfaceMuted),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = _parseIntLocalized(v);
                if (n == null || n < 0) return 'Enter valid calories';
                return null;
              },
              onSaved: (v) => _calories = _parseIntLocalized(v ?? '') ?? 0,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Save',
              onPressed: _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
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
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TodayWorkoutCard extends ConsumerWidget {
  final WorkoutPlan plan;

  const _TodayWorkoutCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];

    final sortedDays = List<WorkoutDay>.from(plan.days)
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    if (sortedDays.isEmpty) return const SizedBox.shrink();

    // Find last completed day index in plan
    final lastDayId = sessions
        .where((s) => s.planId == plan.id)
        .map((s) => s.dayId)
        .firstWhere((_) => true, orElse: () => '');

    final lastIdx = lastDayId.isEmpty
        ? -1
        : sortedDays.indexWhere((d) => d.id == lastDayId);

    final initialIndex = (lastIdx + 1) % sortedDays.length;

    return _TodayWorkoutPageView(
      plan: plan,
      sortedDays: sortedDays,
      initialIndex: initialIndex,
    );
  }
}

class _TodayWorkoutPageView extends ConsumerStatefulWidget {
  final WorkoutPlan plan;
  final List<WorkoutDay> sortedDays;
  final int initialIndex;

  const _TodayWorkoutPageView({
    required this.plan,
    required this.sortedDays,
    required this.initialIndex,
  });

  @override
  ConsumerState<_TodayWorkoutPageView> createState() =>
      _TodayWorkoutPageViewState();
}

class _TodayWorkoutPageViewState extends ConsumerState<_TodayWorkoutPageView> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = widget.sortedDays[_currentIndex];

    // Compute dynamic PageView height based on the day with the most exercises
    final maxExercises = widget.sortedDays
        .map((d) => d.exercises.take(4).length)
        .fold<int>(0, (max, len) => len > max ? len : max);
    // Each exercise chip row ~44px (incl. spacing); minimum 1 row
    final pageHeight = (maxExercises.clamp(1, 4) * 44.0) + 8;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2C24), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadius.fullRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Active Plan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Vertical layout for plan and workout day
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan name
              Text(
                widget.plan.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Today's workout day with navigation
              if (widget.sortedDays.isNotEmpty) ...[
                Row(
                  children: [
                    // Previous day button (for desktop/web)
                    if (widget.sortedDays.length > 1)
                      InkWell(
                        onTap: _currentIndex > 0
                            ? () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                            : null,
                        child: Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: _currentIndex > 0
                              ? AppColors.primary
                              : AppColors.onSurfaceMuted.withOpacity(0.3),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Today: ${currentDay.name}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Navigation hint
                    Text(
                      '${_currentIndex + 1}/${widget.sortedDays.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swipe,
                      size: 16,
                      color: AppColors.onSurfaceMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Next day button (for desktop/web)
                    if (widget.sortedDays.length > 1)
                      InkWell(
                        onTap: _currentIndex < widget.sortedDays.length - 1
                            ? () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                            : null,
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: _currentIndex < widget.sortedDays.length - 1
                              ? AppColors.primary
                              : AppColors.onSurfaceMuted.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // PageView for swipe navigation
          SizedBox(
            height: pageHeight,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) setState(() => _currentIndex = index);
              },
              itemCount: widget.sortedDays.length,
              itemBuilder: (context, index) {
                final day = widget.sortedDays[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: day.exercises
                      .take(4)
                      .map<Widget>((e) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 8, color: AppColors.primary),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    e.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ),

          // Page indicators
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.sortedDays.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: _currentIndex == index ? 8 : 6,
                height: _currentIndex == index ? 8 : 6,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? AppColors.primary
                      : AppColors.onSurfaceMuted.withAlpha(100),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Start Workout',
            onPressed: () {
              ref
                  .read(activeSessionProvider.notifier)
                  .startSession(currentDay, widget.plan.id);
              context.push(AppRoutes.workoutTracking);
            },
            icon: Icons.play_arrow_rounded,
            height: 48,
          ),
        ],
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete workout?'),
        content: const Text('This entry will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionHistoryProvider.notifier).deleteSession(session.id);
    }
  }

  String _getCorrectVolume(WorkoutSession session, double? userWeight) {
    // Use user weight if available, otherwise use default 70kg for backward compatibility
    final effectiveUserWeight = userWeight ?? 70.0;

    // Always recompute so bodyweight sets are counted, even in mixed sessions
    final totalVolume = session.exercises.fold<double>(0, (sum, exercise) {
      return sum +
          exercise.sets.where((s) => s.isCompleted).fold<double>(0,
              (setSum, set) {
            final weight = set.actualWeight ?? 0.0;
            final reps = set.actualReps ?? 0;
            // Use user weight if actual weight is 0 (bodyweight exercise)
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
          borderRadius: AppRadius.mdRadius,
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete workout?'),
            content: const Text('This entry will be permanently deleted.'),
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
                borderRadius: AppRadius.mdRadius,
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

bool _isSynced(String id) => RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(id);

class _SessionDetailsSheet extends ConsumerStatefulWidget {
  final WorkoutSession session;

  const _SessionDetailsSheet({required this.session});

  @override
  ConsumerState<_SessionDetailsSheet> createState() =>
      _SessionDetailsSheetState();
}

class _SessionDetailsSheetState extends ConsumerState<_SessionDetailsSheet> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  String _getCorrectVolume(WorkoutSession session, double? userWeight) {
    // Use user weight if available, otherwise use default 70kg for backward compatibility
    final effectiveUserWeight = userWeight ?? 70.0;

    // Always recompute so bodyweight sets are counted, even in mixed sessions
    final totalVolume = session.exercises.fold<double>(0, (sum, exercise) {
      return sum +
          exercise.sets.where((s) => s.isCompleted).fold<double>(0,
              (setSum, set) {
            final weight = set.actualWeight ?? 0.0;
            final reps = set.actualReps ?? 0;
            // Use user weight if actual weight is 0 (bodyweight exercise)
            final effectiveWeight =
                weight == 0.0 ? effectiveUserWeight : weight;
            return setSum + (effectiveWeight * reps);
          });
    });
    return '${totalVolume.round()}';
  }

  Future<void> _shareWorkout() async {
    setState(() => _isSharing = true);

    try {
      // Capture the share card as an image
      final RenderRepaintBoundary boundary = _shareCardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate image');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/workout_share.png').create();
      await file.writeAsBytes(pngBytes);

      // Get the render box for share position (required for iPad/iOS)
      final RenderBox? renderBox =
          _shareCardKey.currentContext?.findRenderObject() as RenderBox?;
      final sharePositionOrigin = renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : const Rect.fromLTWH(0, 0, 1, 1);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '💪 Workout Complete: ${widget.session.dayName}! \n'
            '⏱️ ${widget.session.duration?.inMinutes ?? 0} min • '
            '🏋️ ${widget.session.completedExercisesCount} exercises • '
            '⚖️ ${_getCorrectVolume(widget.session, ref.read(authProvider).user?.weightKg)} kg volume\n\n'
            '#shredMembers #Fitness #Workout',
        subject: 'Workout Complete!',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final date = widget.session.startedAt.formatWithOffset(
      'EEEE, MMM d, yyyy',
      widget.session.startedAtOffsetMinutes,
    );
    final time = widget.session.startedAt.formatWithOffset(
      'HH:mm',
      widget.session.startedAtOffsetMinutes,
    );
    final duration = widget.session.duration != null
        ? '${widget.session.duration!.inMinutes} min'
        : '—';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                    child: Icon(
                      widget.session.isCardio
                          ? Icons.directions_run
                          : Icons.check_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.session.dayName,
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

              // Share Card (RepaintBoundary for screenshot)
              RepaintBoundary(
                key: _shareCardKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A2C24), Color(0xFF1A1A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withAlpha(100)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'WORKOUT COMPLETE!',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.session.dayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.session.isCardio
                            ? [
                                _ShareStat(
                                  icon: Icons.timer,
                                  value:
                                      '${widget.session.cardioMinutes ?? 0} min',
                                  label: 'Time',
                                ),
                                const SizedBox(width: 20),
                                _ShareStat(
                                  icon: Icons.straighten,
                                  value: widget.session.distanceKm != null &&
                                          widget.session.distanceKm! > 0
                                      ? '${widget.session.distanceKm!.toStringAsFixed(1)} km'
                                      : '—',
                                  label: 'Distance',
                                ),
                                const SizedBox(width: 20),
                                _ShareStat(
                                  icon: Icons.local_fire_department,
                                  value: widget.session.caloriesBurned != null
                                      ? '${widget.session.caloriesBurned} kcal'
                                      : '—',
                                  label: 'Calories',
                                ),
                              ]
                            : [
                                _ShareStat(
                                    icon: Icons.timer,
                                    value: duration,
                                    label: 'Time'),
                                const SizedBox(width: 20),
                                _ShareStat(
                                    icon: Icons.fitness_center,
                                    value:
                                        '${widget.session.completedExercisesCount}',
                                    label: 'Exercises'),
                                const SizedBox(width: 20),
                                _ShareStat(
                                    icon: Icons.monitor_weight,
                                    value: _getCorrectVolume(
                                        widget.session, user?.weightKg),
                                    label: 'kg'),
                              ],
                      ),
                      const SizedBox(height: 12),

                      // PR celebration - show each PR separately
                      Builder(builder: (context) {
                        final allSessions =
                            ref.read(sessionHistoryProvider).valueOrNull ?? [];
                        final priorSessions = allSessions
                            .where((s) =>
                                s.startedAt.isBefore(widget.session.startedAt))
                            .toList();

                        // Find PRs per exercise
                        final prList = <Map<String, dynamic>>[];
                        for (final exercise in widget.session.exercises) {
                          double bestWeight = 0;
                          int bestReps = 0;
                          ExerciseSet? bestSet;

                          // Find best set in current workout
                          for (final set
                              in exercise.sets.where((s) => s.isCompleted)) {
                            final weight = set.actualWeight ?? 0;
                            final reps = set.actualReps ?? 0;
                            if (weight > bestWeight ||
                                (weight == bestWeight && reps > bestReps)) {
                              bestWeight = weight;
                              bestReps = reps;
                              bestSet = set;
                            }
                          }

                          if (bestSet == null || bestWeight == 0) continue;

                          // Find previous best
                          double prevBestWeight = 0;
                          int prevBestReps = 0;
                          for (final priorSession in priorSessions) {
                            final priorExercise = priorSession.exercises
                                .firstWhereOrNull((e) => e.id == exercise.id);
                            if (priorExercise != null) {
                              for (final priorSet in priorExercise.sets
                                  .where((s) => s.isCompleted)) {
                                final w = priorSet.actualWeight ?? 0;
                                final r = priorSet.actualReps ?? 0;
                                if (w > prevBestWeight ||
                                    (w == prevBestWeight && r > prevBestReps)) {
                                  prevBestWeight = w;
                                  prevBestReps = r;
                                }
                              }
                            }
                          }

                          // Check if PR
                          if (bestWeight > prevBestWeight ||
                              (bestWeight == prevBestWeight &&
                                  bestReps > prevBestReps)) {
                            prList.add({
                              'exercise': exercise.name,
                              'weight': bestWeight,
                              'reps': bestReps,
                              'prevWeight': prevBestWeight,
                              'prevReps': prevBestReps,
                            });
                          }
                        }

                        if (prList.isEmpty) return const SizedBox.shrink();

                        return Column(
                          children: [
                            // PR Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.primary.withAlpha(100)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.emoji_events,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${prList.length} PR${prList.length > 1 ? 's' : ''} ACHIEVED!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Individual PRs
                            ...prList.map((pr) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '🏆 ${pr['exercise']}: ${pr['weight'].toStringAsFixed(1)}kg × ${pr['reps']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                )),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),

                      // Exercises list (max 4)
                      if (!widget.session.isCardio) ...[
                        const Divider(color: AppColors.divider, height: 24),
                        ...widget.session.exercises.take(4).map((exercise) {
                          final completedSets =
                              exercise.sets.where((s) => s.isCompleted).length;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '✓ ${exercise.name} ($completedSets/${exercise.sets.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        if (widget.session.exercises.length > 4)
                          Text(
                            '+${widget.session.exercises.length - 4} more',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                      fontSize: 11,
                                    ),
                          ),
                      ],

                      const SizedBox(height: 12),
                      Text(
                        'https://shredmember.app/',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Share Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareWorkout,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share, size: 20),
                  label: Text(_isSharing ? 'Preparing...' : 'Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DetailStat(
                    icon: Icons.timer_outlined,
                    value: widget.session.isCardio
                        ? '${widget.session.cardioMinutes ?? 0} min'
                        : duration,
                    label: 'Duration',
                  ),
                  if (widget.session.isCardio) ...[
                    _DetailStat(
                      icon: Icons.straighten,
                      value: widget.session.distanceKm != null &&
                              widget.session.distanceKm! > 0
                          ? '${widget.session.distanceKm!.toStringAsFixed(1)} km'
                          : '—',
                      label: 'Distance',
                    ),
                    _DetailStat(
                      icon: Icons.local_fire_department_outlined,
                      value: widget.session.caloriesBurned != null
                          ? '${widget.session.caloriesBurned} kcal'
                          : '—',
                      label: 'Calories',
                    ),
                  ] else ...[
                    _DetailStat(
                      icon: Icons.fitness_center,
                      value: '${widget.session.exercises.length}',
                      label: 'Exercises',
                    ),
                    _DetailStat(
                      icon: Icons.monitor_weight_outlined,
                      value: _getCorrectVolume(widget.session, user?.weightKg),
                      label: 'kg Volume',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (!_isSynced(widget.session.id)) {
                          await ref.refresh(sessionHistoryProvider.future);
                          if (context.mounted) Navigator.pop(context);
                          return;
                        }
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) =>
                              _SessionEditSheet(session: widget.session),
                        );
                      },
                      icon: Icon(
                        _isSynced(widget.session.id)
                            ? Icons.edit_outlined
                            : Icons.sync,
                        size: 18,
                      ),
                      label: Text(
                          _isSynced(widget.session.id) ? 'Edit' : 'Sync now'),
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
                              .deleteSession(widget.session.id);
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

              // Exercises (only for strength sessions)
              if (!widget.session.isCardio) ...[
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ...widget.session.exercises
                    .map((exercise) => _ExerciseDetailCard(
                          exercise: exercise,
                          userWeightKg: user?.weightKg,
                        )),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _ShareStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ShareStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
        ),
      ],
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
  final double? userWeightKg;

  const _ExerciseDetailCard({required this.exercise, this.userWeightKg});

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
                      Builder(builder: (context) {
                        final reps = set.actualReps ?? set.targetReps;
                        final weight = set.actualWeight ?? set.targetWeight;
                        final isBodyweight = weight == 0.0;
                        final displayWeight =
                            isBodyweight ? (userWeightKg ?? 0.0) : weight;
                        final suffix = isBodyweight ? ' kg (BW)' : ' kg';
                        return Text(
                          '$reps reps · ${displayWeight.toStringAsFixed(1)}$suffix',
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      }),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _SessionEditSheet extends ConsumerStatefulWidget {
  final WorkoutSession session;
  const _SessionEditSheet({required this.session});

  @override
  ConsumerState<_SessionEditSheet> createState() => _SessionEditSheetState();
}

class _SessionEditSheetState extends ConsumerState<_SessionEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late List<Exercise> _exercises;
  bool _saving = false;

  // Cardio fields
  late TextEditingController _cardioMinutesCtrl;
  late TextEditingController _distanceCtrl;
  late TextEditingController _caloriesCtrl;
  late String _cardioType;

  static const _cardioTypes = [
    'Running',
    'Cycling',
    'Swimming',
    'Rowing',
    'Elliptical',
    'Jump Rope',
    'Walking',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _exercises = widget.session.exercises
        .map((e) => e.copyWith(
              sets: e.sets
                  .map((s) => s.copyWith(
                        actualReps: s.actualReps ?? 0,
                        actualWeight: s.actualWeight ?? 0.0,
                      ))
                  .toList(),
            ))
        .toList();
    _cardioType = _cardioTypes.contains(widget.session.dayName)
        ? widget.session.dayName
        : 'Other';
    _cardioMinutesCtrl = TextEditingController(
        text: (widget.session.cardioMinutes ?? 0).toString());
    _distanceCtrl = TextEditingController(
        text: widget.session.distanceKm != null
            ? widget.session.distanceKm!.toStringAsFixed(1)
            : '');
    _caloriesCtrl = TextEditingController(
        text: widget.session.caloriesBurned != null
            ? widget.session.caloriesBurned.toString()
            : '');
  }

  @override
  void dispose() {
    _cardioMinutesCtrl.dispose();
    _distanceCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  void _updateSet(int exIdx, int setIdx, {int? reps, double? weight}) {
    setState(() {
      final old = _exercises[exIdx].sets[setIdx];
      final updated = old.copyWith(
        actualReps: reps ?? old.actualReps ?? 0,
        actualWeight: weight ?? old.actualWeight ?? 0.0,
      );
      final newSets = List<ExerciseSet>.from(_exercises[exIdx].sets);
      newSets[setIdx] = updated;
      _exercises[exIdx] = _exercises[exIdx].copyWith(sets: newSets);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);
    try {
      final WorkoutSession updated;
      if (widget.session.isCardio) {
        updated = widget.session.copyWith(
          dayName: _cardioType,
          cardioMinutes: _parseIntLocalized(_cardioMinutesCtrl.text) ??
              widget.session.cardioMinutes,
          distanceKm: _parseDoubleLocalized(_distanceCtrl.text),
          caloriesBurned: _parseIntLocalized(_caloriesCtrl.text),
        );
      } else {
        final exercisesWithCompleted = _exercises
            .map((e) => e.copyWith(
                  sets: e.sets
                      .map((s) => s.copyWith(
                            isCompleted: true,
                            actualReps: s.actualReps ?? s.targetReps,
                            actualWeight: s.actualWeight ?? s.targetWeight,
                          ))
                      .toList(),
                ))
            .toList();
        final totalVolume = exercisesWithCompleted
            .expand((e) => e.sets)
            .fold<double>(0,
                (sum, s) => sum + (s.actualReps ?? 0) * (s.actualWeight ?? 0));
        updated = widget.session.copyWith(
          exercises: exercisesWithCompleted,
          totalVolumeKg: totalVolume.round(),
        );
      }
      await ref.read(sessionHistoryProvider.notifier).updateSession(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.session.dayName,
                        style: Theme.of(context).textTheme.headlineSmall),
                    TextButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_rounded),
                      label: const Text('Save'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (widget.session.isCardio) ...[
                  DropdownButtonFormField<String>(
                    value: _cardioType,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                      labelText: 'Activity type',
                      prefixIcon: Icon(Icons.directions_run,
                          color: AppColors.onSurfaceMuted),
                    ),
                    items: _cardioTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _cardioType = v ?? _cardioType),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _cardioMinutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      prefixIcon: Icon(Icons.timer_outlined,
                          color: AppColors.onSurfaceMuted),
                    ),
                    validator: (v) {
                      final n = _parseIntLocalized(v ?? '');
                      if (n == null || n <= 0) return 'Enter a valid duration';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _distanceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Distance (km) – optional',
                      prefixIcon: Icon(Icons.straighten,
                          color: AppColors.onSurfaceMuted),
                    ),
                    inputFormatters: [_DecimalInputFormatter()],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = _parseDoubleLocalized(v);
                      if (n == null || n < 0) return 'Enter a valid distance';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _caloriesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories burned – optional',
                      prefixIcon: Icon(Icons.local_fire_department_outlined,
                          color: AppColors.onSurfaceMuted),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = _parseIntLocalized(v);
                      if (n == null || n < 0) return 'Enter valid calories';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ] else ...[
                  ..._exercises.asMap().entries.map((exEntry) {
                    final exIdx = exEntry.key;
                    final exercise = exEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exercise.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    )),
                            const SizedBox(height: AppSpacing.md),
                            ...exercise.sets.map((set) {
                              final setIdx = exercise.sets.indexWhere(
                                  (s) => s.setNumber == set.setNumber);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: set.isCompleted
                                            ? AppColors.primary.withAlpha(30)
                                            : AppColors.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text('${set.setNumber}',
                                            style: TextStyle(
                                              color: set.isCompleted
                                                  ? AppColors.primary
                                                  : AppColors.onSurfaceMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            )),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: '${set.actualReps ?? 0}',
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Reps',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                        ),
                                        onChanged: (v) => _updateSet(
                                            exIdx, setIdx,
                                            reps: int.tryParse(v)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: (set.actualWeight ?? 0.0)
                                            .toStringAsFixed(1),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'kg',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                        ),
                                        onChanged: (v) => _updateSet(
                                            exIdx, setIdx,
                                            weight: double.tryParse(v)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ], // end else (strength)
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
