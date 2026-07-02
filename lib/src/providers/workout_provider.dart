import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/mock_data.dart';
import '../services/workout_repository.dart';
import 'personal_records_provider.dart';
import 'supabase_providers.dart';

// ─── Plans Provider ───────────────────────────────────────────────────────────
class WorkoutPlansNotifier extends AsyncNotifier<List<WorkoutPlan>> {
  @override
  Future<List<WorkoutPlan>> build() async {
    final repo = ref.read(workoutRepositoryProvider);
    
    try {
      // Fetch plans and active plan ID from Supabase in parallel
      final results = await Future.wait([
        repo.fetchPlans(),
        repo.fetchActivePlanId(),
      ]);
      final plans = results[0] as List<WorkoutPlan>;
      final profileActivePlanId = results[1] as String?;
      
      // Also get locally stored active plan ID (offline fallback)
      final localActivePlanId = LocalStorageService.getActivePlanId();
      
      // Determine which active plan ID to use (Supabase profile takes priority)
      final activePlanId = profileActivePlanId ?? localActivePlanId;
      
      print('[PLAN SYNC] Supabase plans: ${plans.length}, Profile active: $profileActivePlanId, Local active: $localActivePlanId');
      print('[PLAN SYNC] Using active plan ID: $activePlanId');
      
      if (plans.isEmpty) {
        // If no plans from server, use mock data but respect active plan
        final mockPlans = MockData.allPlans;
        if (activePlanId != null) {
          return mockPlans.map((p) => p.copyWith(isActive: p.id == activePlanId)).toList();
        }
        return mockPlans;
      }
      
      // Merge with fresh mock data (exercise updates)
      final mockPlans = MockData.allPlans;
      final mergedPlans = plans.map((p) {
        // Replace with fresh mock data if available
        final mockVersion = mockPlans.firstWhere(
          (m) => m.id == p.id,
          orElse: () => p,
        );
        return mockVersion.id == p.id ? mockVersion : p;
      }).toList();
      
      // Add any mock plans not yet in Supabase
      for (final mockPlan in mockPlans) {
        if (!mergedPlans.any((p) => p.id == mockPlan.id)) {
          mergedPlans.add(mockPlan);
        }
      }
      
      // Sync any mock plans to Supabase for cross-device availability
      for (final plan in mockPlans) {
        final existsInSupabase = plans.any((p) => p.id == plan.id);
        if (!existsInSupabase) {
          repo.savePlan(plan).catchError((e) {
            print('[SYNC ERROR] Failed to save plan ${plan.id}: $e');
          });
        }
      }
      
      // If Supabase profile has active_plan_id, use it for all plans (including mock plans)
      if (activePlanId != null) {
        // Sync to local storage for offline support
        await LocalStorageService.setActivePlan(activePlanId);
        // Apply active status to matching plan
        final result = mergedPlans.map((p) => p.copyWith(isActive: p.id == activePlanId)).toList();
        final activePlan = result.firstWhere((p) => p.isActive, orElse: () => result.first);
        print('[PLAN SYNC] Final plan count: ${result.length}, Active: ${activePlan.name} (${activePlan.id})');
        return result;
      }
      
      // No active plan set yet - use legacy is_active from workout_plans table
      final hasSupabaseActivePlan = mergedPlans.any((p) => p.isActive);
      if (hasSupabaseActivePlan) {
        final supabaseActivePlanId = mergedPlans.firstWhere((p) => p.isActive).id;
        await LocalStorageService.setActivePlan(supabaseActivePlanId);
      }
      
      return mergedPlans;
    } catch (_) {
      // Offline: use mock data with locally stored active plan
      final mockPlans = MockData.allPlans;
      final localActivePlanId = LocalStorageService.getActivePlanId();
      if (localActivePlanId != null) {
        return mockPlans.map((p) => p.copyWith(isActive: p.id == localActivePlanId)).toList();
      }
      return mockPlans;
    }
  }

  Future<void> setActive(String planId) async {
    // Always save locally first for immediate persistence
    await LocalStorageService.setActivePlan(planId);
    
    try {
      await ref.read(workoutRepositoryProvider).setActivePlan(planId);
    } catch (_) {
      // offline: already saved locally, will sync on next connection
    }
    
    state = AsyncData(
      state.valueOrNull?.map((p) => p.copyWith(isActive: p.id == planId)).toList() ?? [],
    );
  }

  void updatePlan(WorkoutPlan updated) {
    final plans = state.valueOrNull ?? [];
    state = AsyncData(
      plans.map((p) => p.id == updated.id ? updated : p).toList(),
    );
  }

  Future<void> refresh() => ref.refresh(workoutPlansProvider.future);
}

final workoutPlansProvider = AsyncNotifierProvider<WorkoutPlansNotifier, List<WorkoutPlan>>(
  WorkoutPlansNotifier.new,
);

final activePlanProvider = Provider<WorkoutPlan?>((ref) {
  final plans = ref.watch(workoutPlansProvider).valueOrNull ?? [];
  try {
    return plans.firstWhere((p) => p.isActive);
  } catch (_) {
    return null;
  }
});

// ─── Session History Provider ─────────────────────────────────────────────────
class SessionHistoryNotifier extends AsyncNotifier<List<WorkoutSession>> {
  @override
  Future<List<WorkoutSession>> build() async {
    try {
      final sessions = await ref.read(workoutRepositoryProvider).fetchSessions();
      return sessions; // Return actual data or empty list, no mock fallback
    } catch (_) {
      return []; // Empty list on error, no mock data
    }
  }

  Future<void> addSession(WorkoutSession session) async {
    WorkoutSession saved = session;
    try {
      print('addSession: Saving to Supabase...');
      final realId = await ref.read(workoutRepositoryProvider).saveSession(session);
      print('addSession: Successfully saved with ID $realId');
      // Reload from Supabase so exercise IDs are real UUIDs
      final refreshed = await ref.read(workoutRepositoryProvider).fetchSessions(limit: 1);
      saved = refreshed.isNotEmpty ? refreshed.first : session.copyWith(id: realId);
    } catch (e, stack) {
      print('addSession: ERROR saving to Supabase: $e');
      print('Stack trace: $stack');
      saved = session; // keeps session-live-... id → shows "Not synced"
    }
    final existing = state.valueOrNull ?? [];
    final merged = [saved, ...existing.where((s) => s.id != saved.id).toList()]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    state = AsyncData(merged);
  }

  Future<void> deleteSession(String sessionId) async {
    await ref.read(workoutRepositoryProvider).deleteSession(sessionId);
    state = AsyncData(
      (state.valueOrNull ?? []).where((s) => s.id != sessionId).toList(),
    );
  }

  Future<void> updateSession(WorkoutSession updated) async {
    await ref.read(workoutRepositoryProvider).updateSessionSets(updated);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((s) => s.id == updated.id ? updated : s)
          .toList(),
    );
  }
}

final sessionHistoryProvider = AsyncNotifierProvider<SessionHistoryNotifier, List<WorkoutSession>>(
  SessionHistoryNotifier.new,
);

// ─── Active Workout Session Provider ─────────────────────────────────────────
class ActiveSessionNotifier extends Notifier<WorkoutSession?> {
  @override
  WorkoutSession? build() {
    final saved = LocalStorageService.getActiveSession();
    if (saved != null) {
      try {
        return WorkoutSession.fromJsonString(saved);
      } catch (_) {
        LocalStorageService.clearActiveSession();
      }
    }
    return null;
  }

  void _persist() {
    if (state != null) {
      LocalStorageService.saveActiveSession(state!.toJsonString());
    } else {
      LocalStorageService.clearActiveSession();
    }
  }

  void startSession(WorkoutDay day, String planId) {
    final now = DateTime.now();
    state = WorkoutSession(
      id: 'session-live-${now.millisecondsSinceEpoch}',
      planId: planId,
      dayId: day.id,
      dayName: day.name,
      startedAt: now.toUtc(),
      startedAtOffsetMinutes: now.timeZoneOffset.inMinutes,
      status: SessionStatus.inProgress,
      exercises: day.exercises.map((e) => e.copyWith(
        sets: e.sets.map((s) => s.copyWith(isCompleted: false)).toList(),
      )).toList(),
    );
    _persist();
    NotificationService.scheduleWorkoutReminder();
  }

  void toggleSet(String exerciseId, String setId) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final updatedSets = exercise.sets.map((s) {
        if (s.id != setId) return s;
        final newCompleted = !s.isCompleted;
        return s.copyWith(
          isCompleted: newCompleted,
          // Only set actual values to target if not yet set by user
          actualReps: newCompleted
              ? (s.actualReps ?? s.targetReps)
              : null,
          actualWeight: newCompleted
              ? (s.actualWeight ?? s.targetWeight)
              : null,
        );
      }).toList();
      return exercise.copyWith(sets: updatedSets);
    }).toList();
    state = state!.copyWith(exercises: updatedExercises);
    _persist();
  }

  void updateSetValues(String exerciseId, String setId, {int? reps, double? weight, bool? wasPR}) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final updatedSets = exercise.sets.map((s) {
        if (s.id != setId) return s;
        return s.copyWith(
          actualReps: reps ?? s.actualReps,
          actualWeight: weight ?? s.actualWeight,
          wasPR: wasPR ?? s.wasPR,
        );
      }).toList();
      return exercise.copyWith(sets: updatedSets);
    }).toList();
    state = state!.copyWith(exercises: updatedExercises);
    _persist();
  }

  void addSet(String exerciseId) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final lastSet = exercise.sets.lastOrNull;
      final newSet = ExerciseSet(
        id: 'set-${DateTime.now().millisecondsSinceEpoch}-${exercise.sets.length}',
        setNumber: exercise.sets.length + 1,
        targetReps: lastSet?.targetReps ?? 10,
        targetWeight: lastSet?.targetWeight ?? 0,
      );
      return exercise.copyWith(sets: [...exercise.sets, newSet]);
    }).toList();
    state = state!.copyWith(exercises: updatedExercises);
    _persist();
  }

  void removeExercise(String exerciseId) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: state!.exercises.where((e) => e.id != exerciseId).toList(),
    );
    _persist();
  }

  void addExercise(Exercise exercise, {int? insertAfterIndex}) {
    if (state == null) return;
    if (state!.exercises.any((e) => e.id == exercise.id)) return;
    final list = [...state!.exercises];
    if (insertAfterIndex != null && insertAfterIndex < list.length) {
      list.insert(insertAfterIndex + 1, exercise);
    } else {
      list.add(exercise);
    }
    state = state!.copyWith(exercises: list);
    _persist();
  }

  void removeSet(String exerciseId, String setId) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final updatedSets = exercise.sets.where((s) => s.id != setId).toList();
      // Renumber sets
      for (var i = 0; i < updatedSets.length; i++) {
        updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
      }
      return exercise.copyWith(sets: updatedSets);
    }).toList();
    state = state!.copyWith(exercises: updatedExercises);
    _persist();
  }

  WorkoutSession? finishSession(WidgetRef ref) {
    if (state == null) return null;
    final volume = state!.exercises.fold<int>(0, (acc, e) {
      return acc + e.sets.fold<int>(0, (setAcc, s) {
        if (!s.isCompleted) return setAcc;
        return setAcc + ((s.actualWeight ?? 0) * (s.actualReps ?? 0)).toInt();
      });
    });
    final now = DateTime.now();
    final finished = state!.copyWith(
      finishedAt: now.toUtc(),
      finishedAtOffsetMinutes: now.timeZoneOffset.inMinutes,
      status: SessionStatus.completed,
      totalVolumeKg: volume,
    );
    
    // Check for personal records
    _checkAndSavePersonalRecords(ref, finished);
    
    // Fire-and-forget: saves to Supabase + updates local list
    ref.read(sessionHistoryProvider.notifier).addSession(finished);
    state = null;
    _persist();
    NotificationService.cancelWorkoutReminder();
    return finished;
  }

  void _checkAndSavePersonalRecords(WidgetRef ref, WorkoutSession session) async {
    // Ensure personal records are loaded
    final prNotifier = ref.read(personalRecordsProvider.notifier);
    if (ref.read(personalRecordsProvider).records.isEmpty) {
      await prNotifier.fetchRecords();
    }
    
    for (final exercise in session.exercises) {
      double maxWeight = 0;
      int maxReps = 0;
      
      for (final set in exercise.sets) {
        if (set.isCompleted && (set.actualWeight ?? 0) >= 0 && (set.actualReps ?? 0) > 0) {
          final weight = set.actualWeight ?? 0;
          final reps = set.actualReps!;
          if (weight == 0) {
            // BW: just track highest reps
            if (reps > maxReps) maxReps = reps;
          } else {
            final estimated1RM = weight * (1 + reps / 30);
            final currentBest1RM = maxWeight * (1 + maxReps / 30);
            if (estimated1RM > currentBest1RM) {
              maxWeight = weight;
              maxReps = reps;
            }
          }
        }
      }
      
      if (maxReps > 0) {
        await prNotifier.checkAndSavePotentialRecord(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          weightKg: maxWeight,
          reps: maxReps,
        );
      }
    }
  }

  void cancelSession() {
    state = null;
    _persist();
    NotificationService.cancelWorkoutReminder();
  }
}

final activeSessionProvider = NotifierProvider<ActiveSessionNotifier, WorkoutSession?>(
  ActiveSessionNotifier.new,
);
