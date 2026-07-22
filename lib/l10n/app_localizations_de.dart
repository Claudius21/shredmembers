// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'shredMembers';

  @override
  String get progressTitle => 'Fortschritt';

  @override
  String get progressSubtitle => 'Verfolge deine Fitness-Reise';

  @override
  String get totalSessions => 'Trainingseinheiten';

  @override
  String get totalVolume => 'Gesamtvolumen';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get weeklyVolume => 'Wöchentliches Volumen';

  @override
  String get strengthKg => 'Kraft (kg)';

  @override
  String get cardioMin => 'Cardio (min)';

  @override
  String get cardioScaledNotice =>
      'Cardio-Minuten sind zur besseren Sichtbarkeit skaliert';

  @override
  String get personalRecordHistory => 'Rekord-Historie';

  @override
  String get loadAll => 'Alle laden';

  @override
  String get recentSessions => 'Letzte Einheiten';

  @override
  String get deleteWorkoutTitle => 'Training löschen?';

  @override
  String get deleteWorkoutMessage => 'Dieser Eintrag wird dauerhaft gelöscht.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String tooltipStrengthKg(int value) {
    return 'Kraft: $value kg';
  }

  @override
  String tooltipCardioMin(int value) {
    return 'Cardio: $value min';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String get plansTitle => 'Pläne';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get athlete => 'Athlet';

  @override
  String get liftingThisWeek => 'Kraft\ndiese Woche';

  @override
  String get cardioThisWeek => 'Cardio\ndiese Woche';

  @override
  String get weeklyTarget => 'Wöchentliches Ziel';

  @override
  String get todaysWorkout => 'Heutiges Training';

  @override
  String get allPlans => 'Alle Pläne';

  @override
  String get noActivePlan => 'Kein aktiver Plan';

  @override
  String get noActivePlanDescription =>
      'Durchsuche unsere Trainingspläne und starte dein Training.';

  @override
  String get browsePlans => 'Pläne durchsuchen';

  @override
  String get logCardio => 'Cardio eintragen';

  @override
  String get recentActivity => 'Letzte Aktivität';

  @override
  String get seeAll => 'Alle anzeigen';

  @override
  String get noWorkoutsYet => 'Noch keine Trainings';

  @override
  String get noWorkoutsYetDescription =>
      'Schliesse dein erstes Training ab, um es hier zu sehen!';

  @override
  String targetHitTitle(String type) {
    return 'Wöchentliches $type-Ziel erreicht!';
  }

  @override
  String targetHitMessage(String type) {
    return 'Toll gemacht – du hast dein $type-Ziel für diese Woche erreicht! 🎉';
  }

  @override
  String get keepItUp => 'Weiter so! 💪';

  @override
  String get profileTitle => 'Profil';

  @override
  String get settings => 'Einstellungen';

  @override
  String get goals => 'Ziele';

  @override
  String get personalDetails => 'Persönliche Daten';

  @override
  String get training => 'Training';

  @override
  String get subscription => 'Abonnement';

  @override
  String get proSubscription => 'Pro-Abonnement';

  @override
  String trialDaysLeft(int daysLeft) {
    String _temp0 = intl.Intl.pluralLogic(
      daysLeft,
      locale: localeName,
      other: 'e',
      one: '',
    );
    return 'Testphase ($daysLeft Tag$_temp0 übrig)';
  }

  @override
  String get subscriptionRequired => 'Abonnement erforderlich';

  @override
  String get account => 'Konto';

  @override
  String get aboutApp => 'Über shredMembers';

  @override
  String get signOut => 'Abmelden';

  @override
  String get workoutReminders => 'Trainingserinnerungen';

  @override
  String get fitnessGoal => 'Fitness-Ziel';

  @override
  String get profileUpdated => 'Profil erfolgreich aktualisiert!';

  @override
  String get profileUpdateFailed => 'Profil konnte nicht aktualisiert werden';

  @override
  String get gender => 'Geschlecht';

  @override
  String get height => 'Grösse';

  @override
  String get heightHint => 'cm';

  @override
  String get weight => 'Gewicht';

  @override
  String get weightHint => 'kg';

  @override
  String get saveDetails => 'Details speichern';

  @override
  String get save => 'Speichern';

  @override
  String get editName => 'Name bearbeiten';

  @override
  String get nameHint => 'Dein Name';

  @override
  String get tapToSetName => 'Tippe, um Namen zu setzen';

  @override
  String get language => 'Sprache';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageItalian => 'Italienisch';

  @override
  String get languageSpanish => 'Spanisch';
}
