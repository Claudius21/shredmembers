import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// App title shown in the task switcher
  ///
  /// In en, this message translates to:
  /// **'shredMembers'**
  String get appTitle;

  /// Title of the progress screen
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// Subtitle of the progress screen
  ///
  /// In en, this message translates to:
  /// **'Track your fitness journey'**
  String get progressSubtitle;

  /// Label for total sessions summary card
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessions;

  /// Label for total volume summary card
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolume;

  /// Label for this week summary card
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Title of the weekly volume chart
  ///
  /// In en, this message translates to:
  /// **'Weekly Volume'**
  String get weeklyVolume;

  /// Legend label for strength volume in kilograms
  ///
  /// In en, this message translates to:
  /// **'Strength (kg)'**
  String get strengthKg;

  /// Legend label for cardio minutes
  ///
  /// In en, this message translates to:
  /// **'Cardio (min)'**
  String get cardioMin;

  /// Notice that cardio minutes are scaled in the chart
  ///
  /// In en, this message translates to:
  /// **'Cardio minutes are scaled for visibility'**
  String get cardioScaledNotice;

  /// Title of the personal record history section
  ///
  /// In en, this message translates to:
  /// **'Personal Record History'**
  String get personalRecordHistory;

  /// Button to load all personal records
  ///
  /// In en, this message translates to:
  /// **'Load All'**
  String get loadAll;

  /// Title of the recent sessions section
  ///
  /// In en, this message translates to:
  /// **'Recent Sessions'**
  String get recentSessions;

  /// Title of the delete workout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete workout?'**
  String get deleteWorkoutTitle;

  /// Message of the delete workout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This entry will be permanently deleted.'**
  String get deleteWorkoutMessage;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Tooltip showing strength volume in kilograms
  ///
  /// In en, this message translates to:
  /// **'Strength: {value} kg'**
  String tooltipStrengthKg(int value);

  /// Tooltip showing cardio minutes
  ///
  /// In en, this message translates to:
  /// **'Cardio: {value} min'**
  String tooltipCardioMin(int value);

  /// Bottom navigation label for home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Bottom navigation label for plans screen
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plansTitle;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// Default user name when no name is set
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get athlete;

  /// Label for lifting sessions this week
  ///
  /// In en, this message translates to:
  /// **'Lifting\nthis week'**
  String get liftingThisWeek;

  /// Label for cardio sessions this week
  ///
  /// In en, this message translates to:
  /// **'Cardio\nthis week'**
  String get cardioThisWeek;

  /// Label for weekly target selector
  ///
  /// In en, this message translates to:
  /// **'Weekly Target'**
  String get weeklyTarget;

  /// Title of the today's workout section
  ///
  /// In en, this message translates to:
  /// **'Today\'s Workout'**
  String get todaysWorkout;

  /// Action label to view all plans
  ///
  /// In en, this message translates to:
  /// **'All Plans'**
  String get allPlans;

  /// Message shown when no workout plan is active
  ///
  /// In en, this message translates to:
  /// **'No active plan'**
  String get noActivePlan;

  /// Description shown when no workout plan is active
  ///
  /// In en, this message translates to:
  /// **'Browse our workout plans and start training.'**
  String get noActivePlanDescription;

  /// Button label to browse workout plans
  ///
  /// In en, this message translates to:
  /// **'Browse Plans'**
  String get browsePlans;

  /// Button label to log a cardio session
  ///
  /// In en, this message translates to:
  /// **'Log Cardio'**
  String get logCardio;

  /// Title of the recent activity section
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// Action label to see all entries
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Message shown when there are no workouts
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get noWorkoutsYet;

  /// Description shown when there are no workouts
  ///
  /// In en, this message translates to:
  /// **'Complete your first workout to see it here!'**
  String get noWorkoutsYetDescription;

  /// Title of the weekly target hit dialog
  ///
  /// In en, this message translates to:
  /// **'Weekly {type} Target Hit!'**
  String targetHitTitle(String type);

  /// Message of the weekly target hit dialog
  ///
  /// In en, this message translates to:
  /// **'Amazing work – you\'ve reached your {type} goal for this week! 🎉'**
  String targetHitMessage(String type);

  /// Button label in the weekly target hit dialog
  ///
  /// In en, this message translates to:
  /// **'Keep it up! 💪'**
  String get keepItUp;

  /// Bottom navigation label for profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Title of the settings section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Title of the goals settings section
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// Title of the personal details section
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// Title of the training settings section
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// Title of the subscription section
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Label shown when user has active pro subscription
  ///
  /// In en, this message translates to:
  /// **'Pro subscription'**
  String get proSubscription;

  /// Label shown during trial period
  ///
  /// In en, this message translates to:
  /// **'Trial ({daysLeft} day{daysLeft, plural, =1{} other{s}} left)'**
  String trialDaysLeft(int daysLeft);

  /// Label shown when subscription is required
  ///
  /// In en, this message translates to:
  /// **'Subscription required'**
  String get subscriptionRequired;

  /// Title of the account section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Label for the about dialog
  ///
  /// In en, this message translates to:
  /// **'About shredMembers'**
  String get aboutApp;

  /// Button label for signing out
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Label for workout reminders toggle
  ///
  /// In en, this message translates to:
  /// **'Workout reminders'**
  String get workoutReminders;

  /// Label for fitness goal selector
  ///
  /// In en, this message translates to:
  /// **'Fitness Goal'**
  String get fitnessGoal;

  /// Success message after profile update
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// Error message when profile update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// Label for gender selector
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Label for height input
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// Hint text for height input in centimeters
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get heightHint;

  /// Label for weight input
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// Hint text for weight input in kilograms
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get weightHint;

  /// Button label to save personal details
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get saveDetails;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Dialog title for editing the user name
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// Hint text for name input
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameHint;

  /// Placeholder text when no name is set
  ///
  /// In en, this message translates to:
  /// **'Tap to set name'**
  String get tapToSetName;

  /// Label for language selector
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// German language name
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// French language name
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// Italian language name
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageItalian;

  /// Spanish language name
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
