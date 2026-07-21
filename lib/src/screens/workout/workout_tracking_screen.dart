import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/exercise.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';
import '../../providers/rest_timer_provider.dart';
import '../../providers/personal_records_provider.dart';
import '../../providers/supabase_providers.dart';
import '../../routing/app_router.dart';
import '../../services/mock_data.dart';
import '../../utils/list_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/exercise/create_custom_exercise_dialog.dart';

class WorkoutTrackingScreen extends ConsumerStatefulWidget {
  const WorkoutTrackingScreen({super.key});

  @override
  ConsumerState<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends ConsumerState<WorkoutTrackingScreen> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    final session = ref.read(activeSessionProvider);
    _elapsed = session != null
        ? DateTime.now().toUtc().difference(session.startedAt.toUtc())
        : Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force reload PRs with cleanup (outside build phase)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceReloadPRs();
    });
  }

  Future<void> _forceReloadPRs() async {
    // ignore: avoid_print
    print('[PR DEBUG] Force reloading PRs with cleanup...');
    if (mounted) {
      await ref.read(personalRecordsProvider.notifier).fetchRecords();
    }
    // ignore: avoid_print
    print('[PR DEBUG] Force reload complete');
  }

  @override
  void dispose() {
    _timer.cancel();
    // Cancel rest timer if widget is still mounted
    if (mounted) {
      ref.read(restTimerProvider.notifier).cancelTimer();
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _finishWorkout() {
    final session = ref.read(activeSessionProvider);
    if (session == null) return;

    final incomplete = session.exercises
        .where((e) => e.sets.any((s) => !s.isCompleted))
        .map((e) => e.name)
        .toList();

    if (incomplete.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Incomplete exercises'),
          content: Text(
            'The following exercises have unchecked sets:\n\n'
            '${incomplete.map((n) => '• $n').join('\n')}\n\n'
            'Finish anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Go back'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _doFinish();
              },
              child: const Text('Finish anyway',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    } else {
      _doFinish();
    }
  }

  void _doFinish() {
    final session = ref.read(activeSessionProvider.notifier).finishSession(ref);
    if (session != null && mounted) {
      _timer.cancel();
      _showCompletionSheet(session);
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              ref.read(activeSessionProvider.notifier).cancelSession();
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
            child: const Text('Cancel Workout',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showExercisePicker(BuildContext context, {int? insertAfterIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExercisePickerSheet(
        onAdd: (exercise) {
          ref.read(activeSessionProvider.notifier).addExercise(
            exercise.copyWith(
              sets: exercise.sets
                  .map((s) => s.copyWith(isCompleted: false))
                  .toList(),
            ),
            insertAfterIndex: insertAfterIndex,
          );
        },
        alreadyAdded: ref.read(activeSessionProvider)?.exercises
                .map((e) => e.id)
                .toSet() ??
            {},
      ),
    );
  }

  void _showRestTimerSheet(BuildContext context, RestTimerState timerState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RestTimerSheet(
        timerState: timerState,
        onSkip: () {
          ref.read(restTimerProvider.notifier).skipTimer();
          Navigator.pop(ctx);
        },
        onAddTime: (seconds) {
          ref.read(restTimerProvider.notifier).addTime(seconds);
        },
      ),
    );
  }

  void _showCompletionSheet(WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CompletionSheet(
        session: session,
        elapsed: _elapsed,
        onDone: () {
          context.go(AppRoutes.home);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);
    // Watch PRs for detection - auto-load if needed via initState

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.home);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final completedSets = session.exercises.fold<int>(
      0,
      (acc, e) => acc + e.sets.where((s) => s.isCompleted).length,
    );
    final totalSets = session.exercises.fold<int>(
      0,
      (acc, e) => acc + e.sets.length,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Column(
          children: [
            Text(session.dayName, style: Theme.of(context).textTheme.titleMedium),
            Text(
              _formatDuration(_elapsed),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmCancel,
        ),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text(
              'Finish',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.onSurfaceMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changes here apply to this session only. To permanently modify a plan, go to Workout Plans.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedSets / $totalSets sets',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      totalSets > 0
                          ? '${((completedSets / totalSets) * 100).toInt()}%'
                          : '0%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: AppRadius.fullRadius,
                  child: LinearProgressIndicator(
                    value: totalSets > 0 ? completedSets / totalSets : 0,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: session.exercises.length + 1, // +1 finish button
              itemBuilder: (ctx, i) {
                if (i == session.exercises.length) {
                  // Finish Workout button at the bottom
                  return Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 32),
                    child: ElevatedButton.icon(
                      onPressed: _finishWorkout,
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text(
                        'Finish Workout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _TrackingExerciseCard(
                        exercise: session.exercises[i],
                        index: i,
                      ),
                    ),
                    _InsertExerciseButton(
                      onTap: () => _showExercisePicker(context, insertAfterIndex: i),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final int index;

  const _TrackingExerciseCard({required this.exercise, required this.index});

  void _confirmDeleteExercise(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove Exercise?'),
        content: Text('"${exercise.name}" will be removed from this workout.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(activeSessionProvider.notifier).removeExercise(exercise.id);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFullyDone = exercise.isCompleted;
    final timerState = ref.watch(restTimerProvider);
    final isThisExerciseResting = timerState.isRunning &&
        timerState.exerciseName == exercise.name;

    String formatRestTime(int seconds) {
      final m = (seconds ~/ 60).toString().padLeft(2, '0');
      final s = (seconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return AppCard(
      backgroundColor: isFullyDone
          ? AppColors.primaryContainer.withAlpha(80)
          : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isFullyDone ? AppColors.primary : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFullyDone ? Icons.check_rounded : Icons.fitness_center,
                  size: 16,
                  color: isFullyDone ? Colors.black : AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isFullyDone
                                ? AppColors.primary
                                : AppColors.onBackground,
                          ),
                    ),
                    Text(
                      '${exercise.completedSets}/${exercise.sets.length} sets · ${exercise.restSeconds}s rest',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Rest timer chip
              if (isThisExerciseResting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatRestTime(timerState.remainingSeconds),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDeleteExercise(context, ref),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Set rows
          ...exercise.sets.asMap().entries.map((entry) {
            final s = entry.value;
            final setIndex = entry.key;
            return _SetRow(
              set: s,
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              restSeconds: exercise.restSeconds,
              canRemove: exercise.sets.length > 1,
              onToggle: () {
                // Start rest timer when completing a set (not uncompleting)
                if (!s.isCompleted) {
                  ref.read(restTimerProvider.notifier).startTimer(
                    seconds: exercise.restSeconds,
                    exerciseName: exercise.name,
                    setNumber: setIndex + 1,
                  );
                }
                ref.read(activeSessionProvider.notifier).toggleSet(exercise.id, s.id);
              },
              onRemove: () => ref
                  .read(activeSessionProvider.notifier)
                  .removeSet(exercise.id, s.id),
              onEditReps: (reps) => ref
                  .read(activeSessionProvider.notifier)
                  .updateSetValues(exercise.id, s.id, reps: reps),
              onEditWeight: (weight) => ref
                  .read(activeSessionProvider.notifier)
                  .updateSetValues(exercise.id, s.id, weight: weight),
              onSetPR: (wasPR) => ref
                  .read(activeSessionProvider.notifier)
                  .updateSetValues(exercise.id, s.id, wasPR: wasPR),
            );
          }),
          // Add set button
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => ref
                  .read(activeSessionProvider.notifier)
                  .addSet(exercise.id),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Set'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final ExerciseSet set;
  final String exerciseId;
  final String exerciseName;
  final int restSeconds;
  final bool canRemove;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final Function(int) onEditReps;
  final Function(double) onEditWeight;
  final Function(bool) onSetPR; // Persist PR status to model

  const _SetRow({
    required this.set,
    required this.exerciseId,
    required this.exerciseName,
    required this.restSeconds,
    required this.canRemove,
    required this.onToggle,
    required this.onRemove,
    required this.onEditReps,
    required this.onEditWeight,
    required this.onSetPR,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  void _showEditDialog(BuildContext context, {bool isReps = true}) {
    final controller = TextEditingController(
      text: isReps
          ? (widget.set.actualReps ?? widget.set.targetReps).toString()
          : (widget.set.actualWeight ?? widget.set.targetWeight).toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isReps ? 'Edit Reps' : 'Edit Weight (kg)'),
        content: TextField(
          controller: controller,
          keyboardType: isReps ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: isReps ? 'Enter reps' : 'Enter weight in kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isReps) {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  widget.onEditReps(value);
                }
              } else {
                final value = double.tryParse(controller.text.replaceAll(',', '.'));
                if (value != null && value > 0) {
                  widget.onEditWeight(value);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actualReps = widget.set.actualReps ?? widget.set.targetReps;
    final actualWeight = widget.set.actualWeight ?? widget.set.targetWeight;
    
    // Check if this set would be a PR (for display purposes)
    final prNotifier = ref.read(personalRecordsProvider.notifier);
    final isCurrentlyPR = widget.set.isCompleted && 
                 actualWeight > 0 && 
                 actualReps > 0 && 
                 prNotifier.wouldBePersonalRecord(
                   exerciseId: widget.exerciseName,
                   weightKg: actualWeight,
                   reps: actualReps,
                 );
    
    // Use the PERSISTED PR status from the model (survives scrolling)
    final showTrophy = widget.set.wasPR || isCurrentlyPR;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Checkbox with PR trophy
          GestureDetector(
            onTap: () {
              // If completing the set, check for PR
              if (!widget.set.isCompleted && actualWeight >= 0 && actualReps > 0) {
                // Check immediately - will only show if PRs are loaded and it's a real PR
                final wouldBePR = prNotifier.wouldBePersonalRecord(
                  exerciseId: widget.exerciseName,
                  weightKg: actualWeight,
                  reps: actualReps,
                );
                if (wouldBePR) {
                  _showMiniPRCelebration(context, widget.exerciseName, actualWeight, actualReps);
                  // Persist PR status to the model (survives scrolling)
                  widget.onSetPR(true);
                  // Save PR immediately so next sets don't trigger another celebration
                  prNotifier.checkAndSavePotentialRecord(
                    exerciseId: widget.exerciseName,
                    exerciseName: widget.exerciseName,
                    weightKg: actualWeight,
                    reps: actualReps,
                  );
                }
                widget.onToggle();
              } else {
                widget.onToggle();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.set.isCompleted ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.set.isCompleted ? AppColors.primary : AppColors.divider,
                  width: 2,
                ),
              ),
              child: widget.set.isCompleted
                  ? (showTrophy 
                      ? const Icon(Icons.emoji_events, size: 18, color: Color(0xFFFFD700))
                      : const Icon(Icons.check, size: 16, color: Colors.black))
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Set number
          Expanded(
            child: Text(
              'Set ${widget.set.setNumber}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // Reps - editable
          GestureDetector(
            onTap: () => _showEditDialog(context, isReps: true),
            child: _ValueBadge(
              value: '${actualReps} reps',
              isDone: widget.set.isCompleted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Weight - editable
          GestureDetector(
            onTap: () => _showEditDialog(context, isReps: false),
            child: _ValueBadge(
              value: actualWeight > 0
                  ? '${actualWeight.toStringAsFixed(1)} kg'
                  : 'BW',
              isDone: widget.set.isCompleted,
              isAccent: true,
            ),
          ),
          // Remove button (if more than 1 set)
          if (widget.canRemove) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: widget.onRemove,
              child: const Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsertExerciseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _InsertExerciseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.divider,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final void Function(Exercise) onAdd;
  final Set<String> alreadyAdded;

  const ExercisePickerSheet({
    super.key,
    required this.onAdd,
    required this.alreadyAdded,
  });

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  MuscleGroup? _selectedGroup;
  String _search = '';
  List<Exercise> _customExercises = [];
  bool _isLoadingCustom = false;

  static final List<Exercise> _standardExercises = [
    ...MockData.chestExercises,
    ...MockData.backExercises,
    ...MockData.legExercises,
    ...MockData.shoulderExercises,
    ...MockData.coreExercises,
    ...MockData.armsExercises,
    ...MockData.cardioExercises,
  ];

  List<Exercise> get _allExercises => [..._standardExercises, ..._customExercises];

  List<Exercise> get _filtered {
    return _allExercises.where((e) {
      final matchesGroup = _selectedGroup == null || e.muscleGroup == _selectedGroup;
      final matchesSearch =
          _search.isEmpty || e.name.toLowerCase().contains(_search.toLowerCase());
      return matchesGroup && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCustomExercises();
  }

  Future<void> _loadCustomExercises() async {
    setState(() => _isLoadingCustom = true);
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final custom = await repository.fetchCustomExercises();
      if (mounted) {
        setState(() {
          _customExercises = custom;
          _isLoadingCustom = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCustom = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadius.fullRadius,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add Exercise',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCreateCustomExerciseDialog(),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Create Custom Exercise'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Alle',
                    selected: _selectedGroup == null,
                    onTap: () => setState(() => _selectedGroup = null),
                  ),
                  ...MuscleGroup.values.map((g) => _FilterChip(
                        label: g.label,
                        selected: _selectedGroup == g,
                        onTap: () => setState(() => _selectedGroup = g),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final ex = _filtered[i];
                  final isAdded = widget.alreadyAdded.contains(ex.id);
                  return _ExercisePickerTile(
                    exercise: ex,
                    isAdded: isAdded,
                    onAdd: () {
                      widget.onAdd(ex);
                      Navigator.pop(context);
                    },
                    onEdit: _isCustomExercise(ex) ? () => _showEditExerciseDialog(ex) : null,
                    onDelete: _isCustomExercise(ex) ? () => _showDeleteExerciseDialog(ex) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCustomExerciseDialog() {
    showDialog(
      context: context,
      builder: (_) => CreateCustomExerciseDialog(
        onExerciseCreated: () {
          // Refresh custom exercises after creating a new one
          _loadCustomExercises();
        },
      ),
    );
  }

  bool _isCustomExercise(Exercise exercise) {
    return exercise.id.startsWith('custom-');
  }

  void _showEditExerciseDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder: (_) => CreateCustomExerciseDialog(
        exercise: exercise,
        onExerciseCreated: () {
          // Refresh custom exercises after editing
          _loadCustomExercises();
        },
      ),
    );
  }

  void _showDeleteExerciseDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Are you sure you want to delete "${exercise.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(workoutRepositoryProvider).deleteCustomExercise(exercise.id);
                _loadCustomExercises(); // Refresh the list
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exercise deleted successfully!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete exercise: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: AppRadius.fullRadius,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : AppColors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _ExercisePickerTile extends StatelessWidget {
  final Exercise exercise;
  final bool isAdded;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ExercisePickerTile({
    required this.exercise,
    required this.isAdded,
    required this.onAdd,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppRadius.mdRadius,
        ),
        child: const Icon(Icons.fitness_center, size: 18, color: AppColors.primary),
      ),
      title: Text(exercise.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
      subtitle: Text(
        '${exercise.muscleGroup.label} · ${exercise.sets.length} sets · ${exercise.restSeconds}s rest',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null || onDelete != null) ...[
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: 8),
            ],
            if (isAdded)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
            else
              TextButton(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Add'),
              ),
          ],
        ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  final String value;
  final bool isDone;
  final bool isAccent;

  const _ValueBadge({
    required this.value,
    required this.isDone,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.primary.withAlpha(20)
            : AppColors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDone
                  ? AppColors.primary
                  : isAccent
                      ? AppColors.primary
                      : AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _RestTimerSheet extends StatelessWidget {
  final RestTimerState timerState;
  final VoidCallback onSkip;
  final void Function(int) onAddTime;

  const _RestTimerSheet({
    required this.timerState,
    required this.onSkip,
    required this.onAddTime,
  });

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = timerState.progress.clamp(0.0, 1.0);
    final remaining = timerState.remainingSeconds;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Exercise info
          Text(
            timerState.exerciseName ?? 'Rest',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set ${timerState.setNumber} completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          const SizedBox(height: 32),
          // Progress ring with timer
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background circle
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation(Colors.transparent),
                ),
                // Progress circle
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
                // Timer text
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(remaining),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBackground,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'seconds remaining',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Quick add time buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeButton(
                seconds: -30,
                onTap: () => onAddTime(-30),
              ),
              const SizedBox(width: 16),
              _TimeButton(
                seconds: -10,
                onTap: () => onAddTime(-10),
              ),
              const SizedBox(width: 16),
              _TimeButton(
                seconds: 10,
                onTap: () => onAddTime(10),
              ),
              const SizedBox(width: 16),
              _TimeButton(
                seconds: 30,
                onTap: () => onAddTime(30),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Skip button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onSkip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.onSurface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Skip Rest',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final int seconds;
  final VoidCallback onTap;

  const _TimeButton({
    required this.seconds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSubtract = seconds < 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${isSubtract ? '' : '+'}${seconds}s',
          style: TextStyle(
            color: isSubtract ? AppColors.error : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CompletionSheet extends ConsumerStatefulWidget {
  final WorkoutSession session;
  final Duration elapsed;
  final VoidCallback onDone;

  const _CompletionSheet({
    required this.session,
    required this.elapsed,
    required this.onDone,
  });

  @override
  ConsumerState<_CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends ConsumerState<_CompletionSheet> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareTo() async {
    setState(() => _isSharing = true);
    
    try {
      // Capture the share card as an image
      final RenderRepaintBoundary boundary = _shareCardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to generate image');
      }
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/workout_share.png').create();
      await file.writeAsBytes(pngBytes);
      
      // Get the render box for share position (required for iPad/iOS)
      final RenderBox? renderBox = _shareCardKey.currentContext?.findRenderObject() as RenderBox?;
      final sharePositionOrigin = renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : const Rect.fromLTWH(0, 0, 1, 1);
      
      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '💪 Just crushed ${widget.session.dayName}! \n'
              '⏱️ ${widget.elapsed.inMinutes} min • '
              '🏋️ ${widget.session.completedExercisesCount} exercises • '
              '⚖️ ${widget.session.totalVolumeKg} kg volume\n\n'
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
    final m = widget.elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (widget.elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Share Preview Card (hidden but capturable)
          RepaintBoundary(
            key: _shareCardKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2C24), Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(100)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'WORKOUT COMPLETE!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.session.dayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ShareStat(icon: Icons.timer, value: '$m:$s', label: 'Time'),
                      const SizedBox(width: 24),
                      _ShareStat(icon: Icons.fitness_center, value: '${widget.session.completedExercisesCount}', label: 'Exercises'),
                      const SizedBox(width: 24),
                      _ShareStat(icon: Icons.monitor_weight, value: '${widget.session.totalVolumeKg}', label: 'kg'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // PR celebration - show each PR separately
                  Builder(builder: (context) {
                    final allSessions = ref.read(sessionHistoryProvider).valueOrNull ?? [];
                    final priorSessions = allSessions
                        .where((s) => s.startedAt.isBefore(widget.session.startedAt))
                        .toList();
                    
                    // Find PRs per exercise
                    final prList = <Map<String, dynamic>>[];
                    for (final exercise in widget.session.exercises) {
                      double bestWeight = 0;
                      int bestReps = 0;
                      
                      // Find best set in current workout
                      for (final set in exercise.sets.where((s) => s.isCompleted)) {
                        final weight = set.actualWeight ?? 0;
                        final reps = set.actualReps ?? 0;
                        if (weight > bestWeight || (weight == bestWeight && reps > bestReps)) {
                          bestWeight = weight;
                          bestReps = reps;
                        }
                      }
                      
                      if (bestWeight == 0) continue;
                      
                      // Find previous best
                      double prevBestWeight = 0;
                      int prevBestReps = 0;
                      for (final priorSession in priorSessions) {
                        final priorExercise = priorSession.exercises
                            .firstWhereOrNull((e) => e.id == exercise.id);
                        if (priorExercise != null) {
                          for (final priorSet in priorExercise.sets.where((s) => s.isCompleted)) {
                            final w = priorSet.actualWeight ?? 0;
                            final r = priorSet.actualReps ?? 0;
                            if (w > prevBestWeight || (w == prevBestWeight && r > prevBestReps)) {
                              prevBestWeight = w;
                              prevBestReps = r;
                            }
                          }
                        }
                      }
                      
                      // Check if PR
                      if (bestWeight > prevBestWeight || 
                          (bestWeight == prevBestWeight && bestReps > prevBestReps)) {
                        prList.add({
                          'exercise': exercise.name,
                          'weight': bestWeight,
                          'reps': bestReps,
                        });
                      }
                    }
                    
                    if (prList.isEmpty) return const SizedBox.shrink();
                    
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withAlpha(100)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events, color: AppColors.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${prList.length} PR${prList.length > 1 ? 's' : ''} ACHIEVED!',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      final completedSets = exercise.sets.where((s) => s.isCompleted).length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '✓ ${exercise.name} ($completedSets/${exercise.sets.length})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 11,
                            ),
                      ),
                  ],
                  
                  const SizedBox(height: 16),
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
          
          // Preview indicator
          Text(
            'Your share preview',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Share button (Instagram style)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _shareTo,
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              label: Text(_isSharing ? 'Preparing...' : 'Share to Instagram'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Done button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: widget.onDone,
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
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

/// Show a mini celebration when achieving a PR
void _showMiniPRCelebration(BuildContext context, String exerciseName, double weight, int reps) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Text('🏆 ', style: TextStyle(fontSize: 24)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERSONAL RECORD!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$exerciseName: ${weight.toStringAsFixed(1)}kg x $reps',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
