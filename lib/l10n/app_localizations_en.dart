// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'shredMembers';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressSubtitle => 'Track your fitness journey';

  @override
  String get totalSessions => 'Total Sessions';

  @override
  String get totalVolume => 'Total Volume';

  @override
  String get thisWeek => 'This Week';

  @override
  String get weeklyVolume => 'Weekly Volume';

  @override
  String get strengthKg => 'Strength (kg)';

  @override
  String get cardioMin => 'Cardio (min)';

  @override
  String get cardioScaledNotice => 'Cardio minutes are scaled for visibility';

  @override
  String get personalRecordHistory => 'Personal Record History';

  @override
  String get loadAll => 'Load All';

  @override
  String get recentSessions => 'Recent Sessions';

  @override
  String get deleteWorkoutTitle => 'Delete workout?';

  @override
  String get deleteWorkoutMessage => 'This entry will be permanently deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String tooltipStrengthKg(int value) {
    return 'Strength: $value kg';
  }

  @override
  String tooltipCardioMin(int value) {
    return 'Cardio: $value min';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String get plansTitle => 'Plans';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get athlete => 'Athlete';

  @override
  String get liftingThisWeek => 'Lifting\nthis week';

  @override
  String get cardioThisWeek => 'Cardio\nthis week';

  @override
  String get weeklyTarget => 'Weekly Target';

  @override
  String get todaysWorkout => 'Today\'s Workout';

  @override
  String get allPlans => 'All Plans';

  @override
  String get noActivePlan => 'No active plan';

  @override
  String get noActivePlanDescription =>
      'Browse our workout plans and start training.';

  @override
  String get browsePlans => 'Browse Plans';

  @override
  String get logCardio => 'Log Cardio';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get seeAll => 'See All';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get noWorkoutsYetDescription =>
      'Complete your first workout to see it here!';

  @override
  String targetHitTitle(String type) {
    return 'Weekly $type Target Hit!';
  }

  @override
  String targetHitMessage(String type) {
    return 'Amazing work – you\'ve reached your $type goal for this week! 🎉';
  }

  @override
  String get keepItUp => 'Keep it up! 💪';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get goals => 'Goals';

  @override
  String get personalDetails => 'Personal Details';

  @override
  String get training => 'Training';

  @override
  String get subscription => 'Subscription';

  @override
  String get proSubscription => 'Pro subscription';

  @override
  String trialDaysLeft(int daysLeft) {
    String _temp0 = intl.Intl.pluralLogic(
      daysLeft,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Trial ($daysLeft day$_temp0 left)';
  }

  @override
  String get subscriptionRequired => 'Subscription required';

  @override
  String get account => 'Account';

  @override
  String get aboutApp => 'About shredMembers';

  @override
  String get signOut => 'Sign Out';

  @override
  String get workoutReminders => 'Workout reminders';

  @override
  String get fitnessGoal => 'Fitness Goal';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get gender => 'Gender';

  @override
  String get height => 'Height';

  @override
  String get heightHint => 'cm';

  @override
  String get weight => 'Weight';

  @override
  String get weightHint => 'kg';

  @override
  String get saveDetails => 'Save Details';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'German';

  @override
  String get languageFrench => 'French';

  @override
  String get languageItalian => 'Italian';

  @override
  String get languageSpanish => 'Spanish';
}
