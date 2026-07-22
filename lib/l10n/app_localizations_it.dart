// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'shredMembers';

  @override
  String get progressTitle => 'Progressi';

  @override
  String get progressSubtitle => 'Tieni traccia del tuo percorso fitness';

  @override
  String get totalSessions => 'Sessioni totali';

  @override
  String get totalVolume => 'Volume totale';

  @override
  String get thisWeek => 'Questa settimana';

  @override
  String get weeklyVolume => 'Volume settimanale';

  @override
  String get strengthKg => 'Forza (kg)';

  @override
  String get cardioMin => 'Cardio (min)';

  @override
  String get cardioScaledNotice =>
      'I minuti di cardio sono scalati per la visibilità';

  @override
  String get personalRecordHistory => 'Storico record personali';

  @override
  String get loadAll => 'Carica tutto';

  @override
  String get recentSessions => 'Sessioni recenti';

  @override
  String get deleteWorkoutTitle => 'Eliminare l\'allenamento?';

  @override
  String get deleteWorkoutMessage =>
      'Questa voce verrà eliminata definitivamente.';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String tooltipStrengthKg(int value) {
    return 'Forza: $value kg';
  }

  @override
  String tooltipCardioMin(int value) {
    return 'Cardio: $value min';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String get plansTitle => 'Piani';

  @override
  String get goodMorning => 'Buongiorno';

  @override
  String get goodAfternoon => 'Buon pomeriggio';

  @override
  String get goodEvening => 'Buonasera';

  @override
  String get athlete => 'Atleta';

  @override
  String get liftingThisWeek => 'Sollevamento\nquesta settimana';

  @override
  String get cardioThisWeek => 'Cardio\nquesta settimana';

  @override
  String get weeklyTarget => 'Obiettivo settimanale';

  @override
  String get todaysWorkout => 'Allenamento di oggi';

  @override
  String get allPlans => 'Tutti i piani';

  @override
  String get noActivePlan => 'Nessun piano attivo';

  @override
  String get noActivePlanDescription =>
      'Sfoglia i nostri piani di allenamento e inizia ad allenarti.';

  @override
  String get browsePlans => 'Sfoglia piani';

  @override
  String get logCardio => 'Registra cardio';

  @override
  String get recentActivity => 'Attività recente';

  @override
  String get seeAll => 'Vedi tutto';

  @override
  String get noWorkoutsYet => 'Ancora nessun allenamento';

  @override
  String get noWorkoutsYetDescription =>
      'Completa il tuo primo allenamento per vederlo qui!';

  @override
  String targetHitTitle(String type) {
    return 'Obiettivo $type settimanale raggiunto!';
  }

  @override
  String targetHitMessage(String type) {
    return 'Ottimo lavoro – hai raggiunto il tuo obiettivo $type per questa settimana! 🎉';
  }

  @override
  String get keepItUp => 'Continua così! 💪';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get settings => 'Impostazioni';

  @override
  String get goals => 'Obiettivi';

  @override
  String get personalDetails => 'Dettagli personali';

  @override
  String get training => 'Allenamento';

  @override
  String get subscription => 'Abbonamento';

  @override
  String get proSubscription => 'Abbonamento Pro';

  @override
  String trialDaysLeft(int daysLeft) {
    String _temp0 = intl.Intl.pluralLogic(
      daysLeft,
      locale: localeName,
      other: 'giorni rimasti',
      one: 'giorno rimasto',
    );
    return 'Prova ($daysLeft $_temp0)';
  }

  @override
  String get subscriptionRequired => 'Abbonamento richiesto';

  @override
  String get account => 'Account';

  @override
  String get aboutApp => 'Informazioni su shredMembers';

  @override
  String get signOut => 'Disconnetti';

  @override
  String get workoutReminders => 'Promemoria allenamento';

  @override
  String get fitnessGoal => 'Obiettivo fitness';

  @override
  String get profileUpdated => 'Profilo aggiornato con successo!';

  @override
  String get profileUpdateFailed => 'Impossibile aggiornare il profilo';

  @override
  String get gender => 'Genere';

  @override
  String get height => 'Altezza';

  @override
  String get heightHint => 'cm';

  @override
  String get weight => 'Peso';

  @override
  String get weightHint => 'kg';

  @override
  String get saveDetails => 'Salva dettagli';

  @override
  String get save => 'Salva';

  @override
  String get editName => 'Modifica nome';

  @override
  String get nameHint => 'Il tuo nome';

  @override
  String get tapToSetName => 'Tocca per impostare il nome';

  @override
  String get language => 'Lingua';

  @override
  String get languageEnglish => 'Inglese';

  @override
  String get languageGerman => 'Tedesco';

  @override
  String get languageFrench => 'Francese';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageSpanish => 'Spagnolo';
}
