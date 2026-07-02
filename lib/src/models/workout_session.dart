import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'exercise.dart';

enum SessionStatus { notStarted, inProgress, completed, skipped }

enum SessionType { strength, cardio }

class WorkoutSession extends Equatable {
  final String id;
  final String planId;
  final String dayId;
  final String dayName;
  final DateTime startedAt;
  final int? startedAtOffsetMinutes;
  final DateTime? finishedAt;
  final int? finishedAtOffsetMinutes;
  final SessionStatus status;
  final List<Exercise> exercises;
  final int totalVolumeKg;
  final SessionType sessionType;
  final int? cardioMinutes;
  final double? distanceKm;
  final int? caloriesBurned;

  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.dayId,
    required this.dayName,
    required this.startedAt,
    this.startedAtOffsetMinutes,
    this.finishedAt,
    this.finishedAtOffsetMinutes,
    required this.status,
    required this.exercises,
    this.totalVolumeKg = 0,
    this.sessionType = SessionType.strength,
    this.cardioMinutes,
    this.distanceKm,
    this.caloriesBurned,
  });

  WorkoutSession copyWith({
    String? id,
    String? planId,
    String? dayId,
    String? dayName,
    DateTime? startedAt,
    int? startedAtOffsetMinutes,
    DateTime? finishedAt,
    int? finishedAtOffsetMinutes,
    SessionStatus? status,
    List<Exercise>? exercises,
    int? totalVolumeKg,
    SessionType? sessionType,
    int? cardioMinutes,
    double? distanceKm,
    int? caloriesBurned,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      dayId: dayId ?? this.dayId,
      dayName: dayName ?? this.dayName,
      startedAt: startedAt ?? this.startedAt,
      startedAtOffsetMinutes: startedAtOffsetMinutes ?? this.startedAtOffsetMinutes,
      finishedAt: finishedAt ?? this.finishedAt,
      finishedAtOffsetMinutes: finishedAtOffsetMinutes ?? this.finishedAtOffsetMinutes,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      sessionType: sessionType ?? this.sessionType,
      cardioMinutes: cardioMinutes ?? this.cardioMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }

  bool get isCardio => sessionType == SessionType.cardio;

  Duration? get duration => finishedAt?.difference(startedAt);

  int get completedExercisesCount => exercises.where((e) => e.isCompleted).length;
  double get completionPercentage =>
      exercises.isEmpty ? 0 : completedExercisesCount / exercises.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        'dayId': dayId,
        'dayName': dayName,
        'startedAt': startedAt.toIso8601String(),
        'startedAtOffsetMinutes': startedAtOffsetMinutes,
        'finishedAt': finishedAt?.toIso8601String(),
        'finishedAtOffsetMinutes': finishedAtOffsetMinutes,
        'status': status.name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'totalVolumeKg': totalVolumeKg,
        'sessionType': sessionType.name,
        'cardioMinutes': cardioMinutes,
        'distanceKm': distanceKm,
        'caloriesBurned': caloriesBurned,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String,
        planId: json['planId'] as String,
        dayId: json['dayId'] as String,
        dayName: json['dayName'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
        startedAtOffsetMinutes: json['startedAtOffsetMinutes'] as int?,
        finishedAt: json['finishedAt'] != null
            ? DateTime.parse(json['finishedAt'] as String).toUtc()
            : null,
        finishedAtOffsetMinutes: json['finishedAtOffsetMinutes'] as int?,
        status: SessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SessionStatus.inProgress,
        ),
        exercises: (json['exercises'] as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalVolumeKg: json['totalVolumeKg'] as int? ?? 0,
        sessionType: SessionType.values.firstWhere(
          (e) => e.name == json['sessionType'],
          orElse: () => SessionType.strength,
        ),
        cardioMinutes: json['cardioMinutes'] as int?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        caloriesBurned: json['caloriesBurned'] as int?,
      );

  String toJsonString() => jsonEncode(toJson());
  static WorkoutSession fromJsonString(String s) =>
      WorkoutSession.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        id, planId, dayId, dayName, startedAt, startedAtOffsetMinutes,
        finishedAt, finishedAtOffsetMinutes, status, exercises, totalVolumeKg,
        sessionType, cardioMinutes, distanceKm, caloriesBurned,
      ];
}
