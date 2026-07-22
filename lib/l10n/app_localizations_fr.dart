// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'shredMembers';

  @override
  String get progressTitle => 'Progrès';

  @override
  String get progressSubtitle => 'Suivez votre parcours fitness';

  @override
  String get totalSessions => 'Séances totales';

  @override
  String get totalVolume => 'Volume total';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get weeklyVolume => 'Volume hebdomadaire';

  @override
  String get strengthKg => 'Force (kg)';

  @override
  String get cardioMin => 'Cardio (min)';

  @override
  String get cardioScaledNotice =>
      'Les minutes de cardio sont mises à l\'échelle pour la visibilité';

  @override
  String get personalRecordHistory => 'Historique des records personnels';

  @override
  String get loadAll => 'Tout charger';

  @override
  String get recentSessions => 'Séances récentes';

  @override
  String get deleteWorkoutTitle => 'Supprimer l\'entraînement ?';

  @override
  String get deleteWorkoutMessage =>
      'Cette entrée sera définitivement supprimée.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String tooltipStrengthKg(int value) {
    return 'Force : $value kg';
  }

  @override
  String tooltipCardioMin(int value) {
    return 'Cardio : $value min';
  }

  @override
  String get homeTitle => 'Accueil';

  @override
  String get plansTitle => 'Plans';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get athlete => 'Athlète';

  @override
  String get liftingThisWeek => 'Musculation\ncette semaine';

  @override
  String get cardioThisWeek => 'Cardio\ncette semaine';

  @override
  String get weeklyTarget => 'Objectif hebdomadaire';

  @override
  String get todaysWorkout => 'Entraînement d\'aujourd\'hui';

  @override
  String get allPlans => 'Tous les plans';

  @override
  String get noActivePlan => 'Aucun plan actif';

  @override
  String get noActivePlanDescription =>
      'Parcourez nos plans d\'entraînement et commencez à vous entraîner.';

  @override
  String get browsePlans => 'Parcourir les plans';

  @override
  String get logCardio => 'Enregistrer du cardio';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get noWorkoutsYet => 'Pas encore d\'entraînements';

  @override
  String get noWorkoutsYetDescription =>
      'Terminez votre premier entraînement pour le voir ici !';

  @override
  String targetHitTitle(String type) {
    return 'Objectif $type hebdomadaire atteint !';
  }

  @override
  String targetHitMessage(String type) {
    return 'Excellent travail – vous avez atteint votre objectif $type pour cette semaine ! 🎉';
  }

  @override
  String get keepItUp => 'Continuez comme ça ! 💪';

  @override
  String get profileTitle => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get goals => 'Objectifs';

  @override
  String get personalDetails => 'Détails personnels';

  @override
  String get training => 'Entraînement';

  @override
  String get subscription => 'Abonnement';

  @override
  String get proSubscription => 'Abonnement Pro';

  @override
  String trialDaysLeft(int daysLeft) {
    String _temp0 = intl.Intl.pluralLogic(
      daysLeft,
      locale: localeName,
      other: 'jours restants',
      one: 'jour restant',
    );
    return 'Essai ($daysLeft $_temp0)';
  }

  @override
  String get subscriptionRequired => 'Abonnement requis';

  @override
  String get account => 'Compte';

  @override
  String get aboutApp => 'À propos de shredMembers';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get workoutReminders => 'Rappels d\'entraînement';

  @override
  String get fitnessGoal => 'Objectif fitness';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès !';

  @override
  String get profileUpdateFailed => 'Échec de la mise à jour du profil';

  @override
  String get gender => 'Genre';

  @override
  String get height => 'Taille';

  @override
  String get heightHint => 'cm';

  @override
  String get weight => 'Poids';

  @override
  String get weightHint => 'kg';

  @override
  String get saveDetails => 'Enregistrer les détails';

  @override
  String get save => 'Enregistrer';

  @override
  String get editName => 'Modifier le nom';

  @override
  String get nameHint => 'Ton nom';

  @override
  String get tapToSetName => 'Appuie pour définir ton nom';

  @override
  String get language => 'Langue';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageItalian => 'Italien';

  @override
  String get languageSpanish => 'Espagnol';
}
