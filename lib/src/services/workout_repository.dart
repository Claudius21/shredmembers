import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

class WorkoutRepository {
  final SupabaseClient _client;

  WorkoutRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Convert exercise ID string to valid UUID v5
  /// This ensures consistent UUIDs for the same exercise ID
  String _exerciseIdToUuid(String exerciseId) {
    // Use a fixed namespace UUID for consistency
    const namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // DNS namespace
    final data = utf8.encode('$namespace:$exerciseId');
    final hash = base64Url.encode(data).substring(0, 36);
    // Format as UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    return '${hash.substring(0, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}-${hash.substring(16, 20)}-${hash.substring(20, 32)}';
  }

  // ─── Plans ───────────────────────────────────────────────────

  Future<List<WorkoutPlan>> fetchPlans() async {
    final data = await _client.from('workout_plans').select('''
          *,
          workout_days (
            *,
            day_exercises (
              *,
              exercises (*)
            )
          )
        ''').eq('user_id', _uid).order('created_at');

    return (data as List)
        .map((e) => _planFromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save or update a plan to Supabase for cross-device sync
  /// Also syncs all workout days and exercises
  Future<void> savePlan(WorkoutPlan plan) async {
    // Insert/update the plan
    await _client.from('workout_plans').upsert({
      'id': plan.id,
      'user_id': _uid,
      'name': plan.name,
      'description': plan.description,
      'difficulty': plan.difficulty.name,
      'duration_weeks': plan.durationWeeks,
      'is_active': plan.isActive,
      'created_at': plan.createdAt.toIso8601String(),
    });

    // Sync each workout day
    for (final day in plan.days) {
      await _client.from('workout_days').upsert({
        'id': day.id,
        'plan_id': plan.id,
        'name': day.name,
        'day_of_week': day.dayOfWeek,
      });

      // Sync exercises for this day
      for (final exercise in day.exercises) {
        // First ensure exercise exists in exercises table
        await _client.from('exercises').upsert({
          'id': exercise.id,
          'name': exercise.name,
          'muscle_group': exercise.muscleGroup.name,
          'description': exercise.description,
        });

        // Then link to day
        await _client.from('day_exercises').upsert({
          'day_id': day.id,
          'exercise_id': exercise.id,
          'sets': exercise.sets.length,
          'target_reps': exercise.sets.firstOrNull?.targetReps ?? 10,
          'target_weight': exercise.sets.firstOrNull?.targetWeight ?? 0,
          'rest_seconds': exercise.restSeconds,
        });
      }
    }
  }

  /// Sync all local/mock plans to Supabase
  Future<void> syncAllPlans(List<WorkoutPlan> plans) async {
    for (final plan in plans) {
      await savePlan(plan);
    }
  }

  Future<void> setActivePlan(String planId) async {
    print('[REPO] Setting active plan: $planId for user: $_uid');

    // Store active plan in profile for cross-device sync (works for all plans including mock plans)
    try {
      await _client
          .from('profiles')
          .update({'active_plan_id': planId}).eq('id', _uid);
      print('[REPO] Successfully updated profiles.active_plan_id to: $planId');
    } catch (e) {
      print('[REPO ERROR] Failed to update profiles: $e');
      rethrow;
    }

    // Also update legacy is_active field for Supabase-stored plans (backward compatibility)
    try {
      await _client
          .from('workout_plans')
          .update({'is_active': false}).eq('user_id', _uid);
      await _client
          .from('workout_plans')
          .update({'is_active': true}).eq('id', planId);
      print('[REPO] Successfully updated workout_plans.is_active');
    } catch (e) {
      print('[REPO] Plan $planId might be a mock plan (not in Supabase): $e');
      // That's ok, profile has the active_plan_id
    }
  }

  Future<String?> fetchActivePlanId() async {
    print('[REPO] Fetching active plan ID for user: $_uid');
    try {
      final data = await _client
          .from('profiles')
          .select('active_plan_id')
          .eq('id', _uid)
          .single();
      final activePlanId = data['active_plan_id'] as String?;
      print('[REPO] Found active_plan_id in profile: $activePlanId');
      return activePlanId;
    } catch (e) {
      print('[REPO ERROR] Failed to fetch active plan ID: $e');
      return null;
    }
  }

  // ─── Sessions ────────────────────────────────────────────────

  Future<List<WorkoutSession>> fetchSessions({int limit = 1000}) async {
    final data = await _client
        .from('workout_sessions')
        .select('*, session_sets(*)')
        .eq('user_id', _uid)
        .order('started_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => _sessionFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveSession(WorkoutSession session) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      print('ERROR: No user logged in - cannot save session');
      throw Exception('User not authenticated');
    }

    print('Saving session for user: ${user.id}');
    print('Session: ${session.dayName}, volume: ${session.totalVolumeKg}');

    final result = await _client
        .from('workout_sessions')
        .insert({
          'user_id': user.id,
          'plan_id': session.planId.isNotEmpty ? session.planId : null,
          'day_id': session.dayId.isNotEmpty ? session.dayId : null,
          'day_name': session.dayName,
          'started_at': session.startedAt.toIso8601String(),
          'started_at_offset_minutes': session.startedAtOffsetMinutes,
          'finished_at': session.finishedAt?.toIso8601String(),
          'finished_at_offset_minutes': session.finishedAtOffsetMinutes,
          'status': session.status.name,
          'total_volume_kg': session.totalVolumeKg,
          'session_type': session.sessionType.name,
          if (session.cardioMinutes != null)
            'cardio_minutes': session.cardioMinutes,
          if (session.distanceKm != null) 'distance_km': session.distanceKm,
          if (session.caloriesBurned != null)
            'calories_burned': session.caloriesBurned,
        })
        .select()
        .single();

    print('Session saved with ID: ${result['id']}');

    final sessionId = result['id'] as String;

    // Save all sets (including uncompleted) so exercises are preserved
    final sets = <Map<String, dynamic>>[];
    for (final exercise in session.exercises) {
      for (final s in exercise.sets) {
        sets.add({
          'session_id': sessionId,
          if (_isUuid(exercise.id)) 'exercise_id': exercise.id,
          'exercise_name': exercise.name,
          'set_number': s.setNumber,
          'reps': s.actualReps ?? 0,
          'weight_kg': s.actualWeight ?? 0.0,
          'is_completed': s.isCompleted,
        });
      }
    }
    if (sets.isNotEmpty) {
      await _client.from('session_sets').insert(sets);
    }

    // Update personal records
    await _updatePersonalRecords(session);

    return sessionId;
  }

  Future<void> _updatePersonalRecords(WorkoutSession session) async {
    for (final exercise in session.exercises) {
      double maxWeight = 0;
      int maxReps = 0;
      for (final s in exercise.sets) {
        if (!s.isCompleted || (s.actualReps ?? 0) <= 0) continue;
        final weight = s.actualWeight ?? 0;
        final reps = s.actualReps!;
        if (weight == 0) {
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
      if (maxReps <= 0) continue;

      await savePersonalRecord(
        exerciseId: exercise.name,
        exerciseName: exercise.name,
        weightKg: maxWeight,
        reps: maxReps,
      );
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.from('session_sets').delete().eq('session_id', sessionId);
    await _client.from('workout_sessions').delete().eq('id', sessionId);
  }

  bool _isUuid(String s) => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(s);

  Future<void> updateSessionSets(WorkoutSession session) async {
    if (!_isUuid(session.id)) {
      throw Exception(
          'Session has not been saved to the server yet. Please finish a new workout first.');
    }
    print('updateSessionSets: deleting old sets for session ${session.id}');
    await _client.from('session_sets').delete().eq('session_id', session.id);
    final sets = <Map<String, dynamic>>[];
    for (final exercise in session.exercises) {
      for (final s in exercise.sets) {
        sets.add({
          'session_id': session.id,
          if (_isUuid(exercise.id)) 'exercise_id': exercise.id,
          'exercise_name': exercise.name,
          'set_number': s.setNumber,
          'reps': s.actualReps ?? 0,
          'weight_kg': s.actualWeight ?? 0.0,
          'is_completed': true,
        });
      }
    }
    print('updateSessionSets: inserting ${sets.length} sets');
    if (sets.isNotEmpty) await _client.from('session_sets').insert(sets);
    final totalVolume = sets.fold<double>(
        0, (sum, s) => sum + ((s['reps'] as int) * (s['weight_kg'] as double)));
    await _client.from('workout_sessions').update({
      'total_volume_kg': totalVolume.round(),
      'day_name': session.dayName,
      if (session.cardioMinutes != null)
        'cardio_minutes': session.cardioMinutes,
      if (session.distanceKm != null) 'distance_km': session.distanceKm,
      if (session.caloriesBurned != null)
        'calories_burned': session.caloriesBurned,
    }).eq('id', session.id);
    print('updateSessionSets: done');
  }

  /// Retroactively compute PR history from all sessions chronologically.
  /// Clears existing PRs and rebuilds — each genuine improvement gets its own entry.
  Future<int> rebuildPersonalRecordsFromHistory() async {
    // Clear existing PRs to start fresh
    await _client.from('personal_records').delete().eq('user_id', _uid);

    // Fetch all sessions ordered oldest → newest with their sets
    final sessionData = await _client
        .from('workout_sessions')
        .select('id, started_at')
        .eq('user_id', _uid)
        .order('started_at', ascending: true);

    final sessionIds =
        (sessionData as List).map((e) => e['id'] as String).toList();
    if (sessionIds.isEmpty) return 0;

    final setsData = await _client
        .from('session_sets')
        .select('exercise_name, reps, weight_kg, session_id')
        .eq('is_completed', true)
        .inFilter('session_id', sessionIds);

    // Group sets by session, preserving order
    final Map<String, List<Map<String, dynamic>>> setsBySession = {};
    for (final row in setsData as List) {
      final sid = row['session_id'] as String;
      setsBySession.putIfAbsent(sid, () => []).add(row as Map<String, dynamic>);
    }

    // Walk sessions chronologically, track best 1RM per exercise (weighted) or best reps (BW)
    final Map<String, double> best1rmPerExercise = {};
    final Map<String, int> bestRepsPerBWExercise = {};
    int insertCount = 0;

    for (final session in sessionData) {
      final sid = session['id'] as String;
      final achievedAt = session['started_at'] as String;
      final sets = setsBySession[sid] ?? [];

      // Find best set per exercise in this session
      final Map<String, Map<String, dynamic>> sessionBest = {};
      for (final row in sets) {
        final name = row['exercise_name'] as String;
        final weight = (row['weight_kg'] as num).toDouble();
        final reps = (row['reps'] as num).toInt();
        if (reps <= 0) continue;
        final existing = sessionBest[name];
        if (weight == 0) {
          // BW: pick highest reps in session
          final existingReps = existing != null ? (existing['reps'] as int) : 0;
          if (reps > existingReps) {
            sessionBest[name] = {'weight_kg': weight, 'reps': reps};
          }
        } else {
          final new1rm = weight * (1 + reps / 30);
          final existing1rm = existing != null
              ? (existing['weight_kg'] as double) *
                  (1 + (existing['reps'] as int) / 30)
              : 0.0;
          if (new1rm > existing1rm) {
            sessionBest[name] = {'weight_kg': weight, 'reps': reps};
          }
        }
      }

      // Only insert if this session beats the all-time best for that exercise
      for (final entry in sessionBest.entries) {
        final name = entry.key;
        final weight = entry.value['weight_kg'] as double;
        final reps = entry.value['reps'] as int;
        bool isNewPR;
        if (weight == 0) {
          // BW: compare reps
          final prevBest = bestRepsPerBWExercise[name] ?? 0;
          isNewPR = reps > prevBest;
          if (isNewPR) bestRepsPerBWExercise[name] = reps;
        } else {
          final new1rm = weight * (1 + reps / 30);
          final prev1rm = best1rmPerExercise[name] ?? 0.0;
          isNewPR = new1rm > prev1rm;
          if (isNewPR) best1rmPerExercise[name] = new1rm;
        }
        if (isNewPR) {
          await _client.from('personal_records').insert({
            'user_id': _uid,
            'exercise_id': name,
            'exercise_name': name,
            'weight_kg': weight,
            'reps': reps,
            'achieved_at': achievedAt,
          });
          insertCount++;
        }
      }
    }
    return insertCount;
  }

  Future<List<String>> _getOwnSessionIds() async {
    final data =
        await _client.from('workout_sessions').select('id').eq('user_id', _uid);
    return (data as List).map((e) => e['id'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> fetchPersonalRecords() async {
    final data = await _client
        .from('personal_records')
        .select()
        .eq('user_id', _uid)
        .order('achieved_at', ascending: false);
    final records =
        (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    // ignore: avoid_print
    print(
        '[REPO DEBUG] Fetched ${records.length} records: ${records.map((r) => '${r['exercise_name']}: ${r['weight_kg']}kg x ${r['reps']}').toList()}');
    return records;
  }

  Future<void> savePersonalRecord({
    required String exerciseId,
    required String exerciseName,
    required double weightKg,
    required int reps,
  }) async {
    // Only insert if this genuinely beats the current best 1RM
    final existing = await _client
        .from('personal_records')
        .select('weight_kg, reps')
        .eq('user_id', _uid)
        .eq('exercise_id', exerciseName)
        .order('achieved_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      final prevWeight = (existing['weight_kg'] as num).toDouble();
      final prevReps = (existing['reps'] as num).toInt();
      if (weightKg == 0 && prevWeight == 0) {
        if (reps <= prevReps) return; // not a new BW PR
      } else {
        final new1rm = weightKg * (1 + reps / 30);
        final prev1rm = prevWeight * (1 + prevReps / 30);
        if (new1rm <= prev1rm) return; // not a new PR
      }
    }

    await _client.from('personal_records').insert({
      'user_id': _uid,
      'exercise_id': exerciseName,
      'exercise_name': exerciseName,
      'weight_kg': weightKg,
      'reps': reps,
      'achieved_at': DateTime.now().toIso8601String(),
    });
  }

  /// Cleanup duplicate personal records - keeps only the best one per exercise
  Future<void> cleanupDuplicatePRs() async {
    // ignore: avoid_print
    print('[PR CLEANUP] Starting cleanup...');

    // Get all records
    final allRecords = await _client
        .from('personal_records')
        .select()
        .eq('user_id', _uid)
        .order('achieved_at', ascending: false);

    // Group by exercise_id
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final record in allRecords) {
      final exerciseId = record['exercise_id'] as String;
      grouped.putIfAbsent(exerciseId, () => []);
      grouped[exerciseId]!.add(record);
    }

    // For each exercise, keep only the best record
    for (final entry in grouped.entries) {
      final records = entry.value;
      if (records.length <= 1) continue;

      // Find best record (highest 1RM for weighted, highest reps for BW)
      Map<String, dynamic> bestRecord = records.first;
      double best1RM = _calculate1RM(
        (bestRecord['weight_kg'] as num).toDouble(),
        bestRecord['reps'] as int,
      );

      for (int i = 1; i < records.length; i++) {
        final record = records[i];
        final weight = (record['weight_kg'] as num).toDouble();
        final reps = record['reps'] as int;
        final current1RM = _calculate1RM(weight, reps);

        // For BW exercises (weight == 0), compare reps only
        final isBW = weight == 0;
        final bestIsBW = (bestRecord['weight_kg'] as num).toDouble() == 0;

        bool isBetter;
        if (isBW && bestIsBW) {
          isBetter = reps > (bestRecord['reps'] as int);
        } else if (!isBW && !bestIsBW) {
          isBetter = current1RM > best1RM;
        } else {
          // Mixed (shouldn't happen), prefer weighted
          isBetter = !isBW;
        }

        if (isBetter) {
          bestRecord = record;
          best1RM = current1RM;
        }
      }

      // Delete all except best
      for (final record in records) {
        if (record['id'] != bestRecord['id']) {
          await _client
              .from('personal_records')
              .delete()
              .eq('id', record['id']);
          // ignore: avoid_print
          print(
              '[PR CLEANUP] Deleted duplicate: ${record['exercise_name']} ${record['weight_kg']}kg x ${record['reps']}');
        }
      }
      // ignore: avoid_print
      print(
          '[PR CLEANUP] Kept best: ${bestRecord['exercise_name']} ${bestRecord['weight_kg']}kg x ${bestRecord['reps']} (1RM: ${best1RM.toStringAsFixed(1)})');
    }

    // ignore: avoid_print
    print('[PR CLEANUP] Done!');
  }

  double _calculate1RM(double weight, int reps) {
    if (weight <= 0) return reps.toDouble(); // For BW, just use reps
    return weight * (1 + reps / 30);
  }

  // ─── JSON Mappers ─────────────────────────────────────────────

  WorkoutPlan _planFromJson(Map<String, dynamic> json) {
    final days = (json['workout_days'] as List? ?? [])
        .map((d) => _dayFromJson(d as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      durationWeeks: json['duration_weeks'] as int? ?? 8,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      days: days,
    );
  }

  WorkoutDay _dayFromJson(Map<String, dynamic> json) {
    final exercises = (json['day_exercises'] as List? ?? [])
        .map((e) => _exerciseFromDayJson(e as Map<String, dynamic>))
        .toList();

    return WorkoutDay(
      id: json['id'] as String,
      name: json['name'] as String,
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      exercises: exercises,
    );
  }

  Exercise _exerciseFromDayJson(Map<String, dynamic> json) {
    final ex = json['exercises'] as Map<String, dynamic>;
    final setCount = json['sets'] as int? ?? 3;
    final targetReps = json['target_reps'] as int? ?? 10;
    final targetWeight = (json['target_weight'] as num?)?.toDouble() ?? 0;
    final restSeconds = json['rest_seconds'] as int? ?? 90;

    return Exercise(
      id: ex['id'] as String,
      name: ex['name'] as String,
      muscleGroup: _parseMuscleGroup(ex['muscle_group'] as String?),
      description: ex['description'] as String?,
      restSeconds: restSeconds,
      sets: List.generate(
        setCount,
        (i) => ExerciseSet(
          id: '${ex['id']}-set-$i',
          setNumber: i + 1,
          targetReps: targetReps,
          targetWeight: targetWeight,
        ),
      ),
    );
  }

  WorkoutSession _sessionFromJson(Map<String, dynamic> json) {
    final rawSets = json['session_sets'] as List? ?? [];
    final exercises = _exercisesFromSets(rawSets);
    final typeStr = json['session_type'] as String? ?? 'strength';
    return WorkoutSession(
      id: json['id'] as String,
      planId: json['plan_id'] as String? ?? '',
      dayId: json['day_id'] as String? ?? '',
      dayName: json['day_name'] as String,
      startedAt: DateTime.parse(json['started_at'] as String).toUtc(),
      startedAtOffsetMinutes: json['started_at_offset_minutes'] as int?,
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String).toUtc()
          : null,
      finishedAtOffsetMinutes: json['finished_at_offset_minutes'] as int?,
      status: SessionStatus.completed,
      exercises: exercises,
      totalVolumeKg: json['total_volume_kg'] as int? ?? 0,
      sessionType:
          typeStr == 'cardio' ? SessionType.cardio : SessionType.strength,
      cardioMinutes: json['cardio_minutes'] as int?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      caloriesBurned: json['calories_burned'] as int?,
    );
  }

  List<Exercise> _exercisesFromSets(List rawSets) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final s in rawSets) {
      final row = s as Map<String, dynamic>;
      final exId = row['exercise_id'] as String?;
      final exName = row['exercise_name'] as String? ?? '';
      final key = exId != null ? '$exId||$exName' : 'local||$exName';
      grouped.putIfAbsent(key, () => []).add(row);
    }
    return grouped.entries.map((entry) {
      final parts = entry.key.split('||');
      final exId = parts[0] == 'local'
          ? entry.value.first['exercise_name'] as String
          : parts[0];
      final exName = parts[1];
      final sets = entry.value
        ..sort((a, b) =>
            (a['set_number'] as int).compareTo(b['set_number'] as int));
      return Exercise(
        id: exId,
        name: exName,
        muscleGroup: MuscleGroup.fullBody,
        sets: sets
            .map((s) => ExerciseSet(
                  id: s['id'] as String? ?? '${parts[0]}-${s['set_number']}',
                  setNumber: s['set_number'] as int,
                  targetReps: s['reps'] as int? ?? 0,
                  targetWeight: (s['weight_kg'] as num?)?.toDouble() ?? 0,
                  actualReps: s['reps'] as int?,
                  actualWeight: (s['weight_kg'] as num?)?.toDouble(),
                  isCompleted: s['is_completed'] as bool? ?? true,
                ))
            .toList(),
      );
    }).toList();
  }

  DifficultyLevel _parseDifficulty(String? v) => switch (v) {
        'beginner' => DifficultyLevel.beginner,
        'advanced' => DifficultyLevel.advanced,
        _ => DifficultyLevel.intermediate,
      };

  MuscleGroup _parseMuscleGroup(String? v) => switch (v) {
        'chest' => MuscleGroup.chest,
        'back' => MuscleGroup.back,
        'shoulders' => MuscleGroup.shoulders,
        'arms' => MuscleGroup.arms,
        'legs' => MuscleGroup.legs,
        'core' => MuscleGroup.core,
        'cardio' => MuscleGroup.cardio,
        _ => MuscleGroup.fullBody,
      };

  /// Save a custom exercise to the database
  Future<void> saveCustomExercise(Exercise exercise) async {
    await _client.from('custom_exercises').insert({
      'user_id': _uid,
      'exercise_id': exercise.id,
      'exercise_name': exercise.name,
      'muscle_group': exercise.muscleGroup.name,
      'description': exercise.description,
      'default_sets': exercise.sets.length,
      'default_reps': exercise.sets.first.targetReps,
      'default_weight': exercise.sets.first.targetWeight,
      'default_rest_seconds': exercise.restSeconds,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Fetch custom exercises for the current user
  Future<List<Exercise>> fetchCustomExercises() async {
    final data = await _client
        .from('custom_exercises')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Exercise(
              id: e['exercise_id'] as String,
              name: e['exercise_name'] as String,
              muscleGroup: _parseMuscleGroup(e['muscle_group'] as String?),
              description: e['description'] as String? ?? '',
              sets: List.generate(
                e['default_sets'] as int? ?? 3,
                (i) => ExerciseSet(
                  id: 'set-${e['exercise_id']}-$i',
                  setNumber: i + 1,
                  targetReps: e['default_reps'] as int? ?? 12,
                  targetWeight:
                      (e['default_weight'] as num?)?.toDouble() ?? 20.0,
                ),
              ),
              restSeconds: e['default_rest_seconds'] as int? ?? 60,
            ))
        .toList();
  }

  /// Update a custom exercise
  Future<void> updateCustomExercise(Exercise exercise) async {
    await _client
        .from('custom_exercises')
        .update({
          'exercise_name': exercise.name,
          'muscle_group': exercise.muscleGroup.name,
          'description': exercise.description,
          'default_sets': exercise.sets.length,
          'default_reps': exercise.sets.first.targetReps,
          'default_weight': exercise.sets.first.targetWeight,
          'default_rest_seconds': exercise.restSeconds,
        })
        .eq('user_id', _uid)
        .eq('exercise_id', exercise.id);
  }

  /// Delete a custom exercise
  Future<void> deleteCustomExercise(String exerciseId) async {
    await _client
        .from('custom_exercises')
        .delete()
        .eq('user_id', _uid)
        .eq('exercise_id', exerciseId);
  }
}
