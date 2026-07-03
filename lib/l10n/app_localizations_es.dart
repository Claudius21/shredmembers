// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'shredMembers';

  @override
  String get progressTitle => 'Progreso';

  @override
  String get progressSubtitle => 'Sigue tu progreso fitness';

  @override
  String get totalSessions => 'Sesiones totales';

  @override
  String get totalVolume => 'Volumen total';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get weeklyVolume => 'Volumen semanal';

  @override
  String get strengthKg => 'Fuerza (kg)';

  @override
  String get cardioMin => 'Cardio (min)';

  @override
  String get cardioScaledNotice =>
      'Los minutos de cardio se escalan para visibilidad';

  @override
  String get personalRecordHistory => 'Historial de récords personales';

  @override
  String get loadAll => 'Cargar todo';

  @override
  String get recentSessions => 'Sesiones recientes';

  @override
  String get deleteWorkoutTitle => '¿Eliminar entrenamiento?';

  @override
  String get deleteWorkoutMessage =>
      'Esta entrada se eliminará permanentemente.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String tooltipStrengthKg(int value) {
    return 'Fuerza: $value kg';
  }

  @override
  String tooltipCardioMin(int value) {
    return 'Cardio: $value min';
  }

  @override
  String get homeTitle => 'Inicio';

  @override
  String get plansTitle => 'Planes';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get athlete => 'Atleta';

  @override
  String get liftingThisWeek => 'Levantamiento\nesta semana';

  @override
  String get cardioThisWeek => 'Cardio\nesta semana';

  @override
  String get weeklyTarget => 'Objetivo semanal';

  @override
  String get todaysWorkout => 'Entrenamiento de hoy';

  @override
  String get allPlans => 'Todos los planes';

  @override
  String get noActivePlan => 'Ningún plan activo';

  @override
  String get noActivePlanDescription =>
      'Explora nuestros planes de entrenamiento y empieza a entrenar.';

  @override
  String get browsePlans => 'Explorar planes';

  @override
  String get logCardio => 'Registrar cardio';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get noWorkoutsYet => 'Aún no hay entrenamientos';

  @override
  String get noWorkoutsYetDescription =>
      '¡Completa tu primer entrenamiento para verlo aquí!';

  @override
  String targetHitTitle(String type) {
    return '¡Objetivo $type semanal alcanzado!';
  }

  @override
  String targetHitMessage(String type) {
    return 'Gran trabajo – has alcanzado tu objetivo $type para esta semana! 🎉';
  }

  @override
  String get keepItUp => '¡Sigue así! 💪';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get settings => 'Ajustes';

  @override
  String get goals => 'Objetivos';

  @override
  String get personalDetails => 'Detalles personales';

  @override
  String get training => 'Entrenamiento';

  @override
  String get subscription => 'Suscripción';

  @override
  String get proSubscription => 'Suscripción Pro';

  @override
  String trialDaysLeft(int daysLeft) {
    String _temp0 = intl.Intl.pluralLogic(
      daysLeft,
      locale: localeName,
      other: 'días restantes',
      one: 'día restante',
    );
    return 'Prueba ($daysLeft $_temp0)';
  }

  @override
  String get subscriptionRequired => 'Suscripción requerida';

  @override
  String get account => 'Cuenta';

  @override
  String get aboutApp => 'Acerca de shredMembers';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get workoutReminders => 'Recordatorios de entrenamiento';

  @override
  String get fitnessGoal => 'Objetivo fitness';

  @override
  String get profileUpdated => '¡Perfil actualizado con éxito!';

  @override
  String get profileUpdateFailed => 'Error al actualizar el perfil';

  @override
  String get gender => 'Género';

  @override
  String get height => 'Altura';

  @override
  String get heightHint => 'cm';

  @override
  String get weight => 'Peso';

  @override
  String get weightHint => 'kg';

  @override
  String get saveDetails => 'Guardar detalles';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageGerman => 'Alemán';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageSpanish => 'Español';
}
