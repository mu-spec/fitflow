import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'FitFlow'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get navWorkouts;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @splashRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your local data.'**
  String get splashRecoveryTitle;

  /// No description provided for @splashRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Your data hasn\'t been changed. Try again.'**
  String get splashRecoveryBody;

  /// No description provided for @splashRecoveryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get splashRecoveryAction;

  /// No description provided for @splashRecoveryHint.
  ///
  /// In en, this message translates to:
  /// **'Reloads local data without changing it'**
  String get splashRecoveryHint;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FitFlow'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your workouts will adapt to your strength, time, space and equipment.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your main goal?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingExperienceTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your current experience?'**
  String get onboardingExperienceTitle;

  /// No description provided for @onboardingTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'How much time do you usually have?'**
  String get onboardingTimeTitle;

  /// No description provided for @onboardingEnvironmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you usually train?'**
  String get onboardingEnvironmentTitle;

  /// No description provided for @onboardingEquipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'What equipment do you have?'**
  String get onboardingEquipmentTitle;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s customize your workouts'**
  String get onboardingPreferencesTitle;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Next, FitFlow will use your preferences to build workouts around you.'**
  String get onboardingReadyBody;

  /// No description provided for @goalGeneralFitness.
  ///
  /// In en, this message translates to:
  /// **'General fitness'**
  String get goalGeneralFitness;

  /// No description provided for @goalBuildStrength.
  ///
  /// In en, this message translates to:
  /// **'Build strength'**
  String get goalBuildStrength;

  /// No description provided for @goalBuildMuscle.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get goalBuildMuscle;

  /// No description provided for @goalLoseWeight.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get goalLoseWeight;

  /// No description provided for @goalImproveEndurance.
  ///
  /// In en, this message translates to:
  /// **'Improve endurance'**
  String get goalImproveEndurance;

  /// No description provided for @goalImproveMobility.
  ///
  /// In en, this message translates to:
  /// **'Improve mobility'**
  String get goalImproveMobility;

  /// No description provided for @goalStayActive.
  ///
  /// In en, this message translates to:
  /// **'Stay active'**
  String get goalStayActive;

  /// No description provided for @experienceCompletelyNew.
  ///
  /// In en, this message translates to:
  /// **'Completely new'**
  String get experienceCompletelyNew;

  /// No description provided for @experienceCompletelyNewHelp.
  ///
  /// In en, this message translates to:
  /// **'You have not trained much before.'**
  String get experienceCompletelyNewHelp;

  /// No description provided for @experienceSome.
  ///
  /// In en, this message translates to:
  /// **'Some experience'**
  String get experienceSome;

  /// No description provided for @experienceSomeHelp.
  ///
  /// In en, this message translates to:
  /// **'You have trained now and then.'**
  String get experienceSomeHelp;

  /// No description provided for @experienceRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular training'**
  String get experienceRegular;

  /// No description provided for @experienceRegularHelp.
  ///
  /// In en, this message translates to:
  /// **'You train most weeks.'**
  String get experienceRegularHelp;

  /// No description provided for @experienceExperienced.
  ///
  /// In en, this message translates to:
  /// **'Experienced'**
  String get experienceExperienced;

  /// No description provided for @experienceExperiencedHelp.
  ///
  /// In en, this message translates to:
  /// **'You train consistently and know your way around.'**
  String get experienceExperiencedHelp;

  /// No description provided for @environmentApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment / quiet space'**
  String get environmentApartment;

  /// No description provided for @environmentNormalHome.
  ///
  /// In en, this message translates to:
  /// **'Normal home'**
  String get environmentNormalHome;

  /// No description provided for @environmentSmallRoom.
  ///
  /// In en, this message translates to:
  /// **'Small room'**
  String get environmentSmallRoom;

  /// No description provided for @environmentLargeRoom.
  ///
  /// In en, this message translates to:
  /// **'Large room'**
  String get environmentLargeRoom;

  /// No description provided for @environmentHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel / travel'**
  String get environmentHotel;

  /// No description provided for @environmentOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get environmentOutdoor;

  /// No description provided for @equipmentNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get equipmentNone;

  /// No description provided for @equipmentMat.
  ///
  /// In en, this message translates to:
  /// **'Exercise mat'**
  String get equipmentMat;

  /// No description provided for @equipmentChair.
  ///
  /// In en, this message translates to:
  /// **'Chair'**
  String get equipmentChair;

  /// No description provided for @equipmentBands.
  ///
  /// In en, this message translates to:
  /// **'Resistance bands'**
  String get equipmentBands;

  /// No description provided for @equipmentDumbbells.
  ///
  /// In en, this message translates to:
  /// **'Dumbbells'**
  String get equipmentDumbbells;

  /// No description provided for @equipmentKettlebell.
  ///
  /// In en, this message translates to:
  /// **'Kettlebell'**
  String get equipmentKettlebell;

  /// No description provided for @equipmentPullUpBar.
  ///
  /// In en, this message translates to:
  /// **'Pull-up bar'**
  String get equipmentPullUpBar;

  /// No description provided for @equipmentBench.
  ///
  /// In en, this message translates to:
  /// **'Bench'**
  String get equipmentBench;

  /// No description provided for @equipmentTowel.
  ///
  /// In en, this message translates to:
  /// **'Towel'**
  String get equipmentTowel;

  /// No description provided for @preferenceNoJumping.
  ///
  /// In en, this message translates to:
  /// **'No jumping'**
  String get preferenceNoJumping;

  /// No description provided for @preferenceLowImpact.
  ///
  /// In en, this message translates to:
  /// **'Low impact'**
  String get preferenceLowImpact;

  /// No description provided for @preferenceNoFloor.
  ///
  /// In en, this message translates to:
  /// **'No floor exercises'**
  String get preferenceNoFloor;

  /// No description provided for @preferenceStandingOnly.
  ///
  /// In en, this message translates to:
  /// **'Standing only'**
  String get preferenceStandingOnly;

  /// No description provided for @preferenceAvoidWrist.
  ///
  /// In en, this message translates to:
  /// **'Avoid wrist-heavy exercises'**
  String get preferenceAvoidWrist;

  /// No description provided for @preferenceAvoidKnee.
  ///
  /// In en, this message translates to:
  /// **'Avoid deep knee bending'**
  String get preferenceAvoidKnee;

  /// No description provided for @patternPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get patternPush;

  /// No description provided for @patternPull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get patternPull;

  /// No description provided for @patternSquat.
  ///
  /// In en, this message translates to:
  /// **'Squat'**
  String get patternSquat;

  /// No description provided for @patternLunge.
  ///
  /// In en, this message translates to:
  /// **'Lunge'**
  String get patternLunge;

  /// No description provided for @patternHinge.
  ///
  /// In en, this message translates to:
  /// **'Hinge'**
  String get patternHinge;

  /// No description provided for @patternCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get patternCore;

  /// No description provided for @patternGlute.
  ///
  /// In en, this message translates to:
  /// **'Glute'**
  String get patternGlute;

  /// No description provided for @patternCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get patternCardio;

  /// No description provided for @patternMobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility'**
  String get patternMobility;

  /// No description provided for @patternBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get patternBalance;

  /// No description provided for @patternWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get patternWarmup;

  /// No description provided for @patternCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get patternCooldown;

  /// No description provided for @modeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get modeStandard;

  /// No description provided for @modeStandardDescription.
  ///
  /// In en, this message translates to:
  /// **'Your normal adaptive workout.'**
  String get modeStandardDescription;

  /// No description provided for @modeLowEnergy.
  ///
  /// In en, this message translates to:
  /// **'Low Energy'**
  String get modeLowEnergy;

  /// No description provided for @modeLowEnergyDescription.
  ///
  /// In en, this message translates to:
  /// **'A shorter, easier workout for today.'**
  String get modeLowEnergyDescription;

  /// No description provided for @modeComeback.
  ///
  /// In en, this message translates to:
  /// **'Comeback'**
  String get modeComeback;

  /// No description provided for @modeComebackDescription.
  ///
  /// In en, this message translates to:
  /// **'A gentler return workout after time away.'**
  String get modeComebackDescription;

  /// No description provided for @modeDoesNotChangeLevels.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t change your movement levels.'**
  String get modeDoesNotChangeLevels;

  /// No description provided for @feedbackTooHard.
  ///
  /// In en, this message translates to:
  /// **'Too hard'**
  String get feedbackTooHard;

  /// No description provided for @feedbackTooHardDescription.
  ///
  /// In en, this message translates to:
  /// **'Felt too difficult'**
  String get feedbackTooHardDescription;

  /// No description provided for @feedbackJustRight.
  ///
  /// In en, this message translates to:
  /// **'Just right'**
  String get feedbackJustRight;

  /// No description provided for @feedbackJustRightDescription.
  ///
  /// In en, this message translates to:
  /// **'Felt about right'**
  String get feedbackJustRightDescription;

  /// No description provided for @feedbackEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get feedbackEasy;

  /// No description provided for @feedbackEasyDescription.
  ///
  /// In en, this message translates to:
  /// **'Felt easy'**
  String get feedbackEasyDescription;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// No description provided for @viewWorkout.
  ///
  /// In en, this message translates to:
  /// **'View workout'**
  String get viewWorkout;

  /// No description provided for @viewWorkoutHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the workout preview'**
  String get viewWorkoutHint;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @beginWorkout.
  ///
  /// In en, this message translates to:
  /// **'Begin workout'**
  String get beginWorkout;

  /// No description provided for @setComplete.
  ///
  /// In en, this message translates to:
  /// **'Set complete'**
  String get setComplete;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @skipRest.
  ///
  /// In en, this message translates to:
  /// **'Skip rest'**
  String get skipRest;

  /// No description provided for @skipTransition.
  ///
  /// In en, this message translates to:
  /// **'Skip transition'**
  String get skipTransition;

  /// No description provided for @startCooldown.
  ///
  /// In en, this message translates to:
  /// **'Start cooldown'**
  String get startCooldown;

  /// No description provided for @exerciseLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get exerciseLibraryTitle;

  /// No description provided for @searchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get searchExercises;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filtersWithCount.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String filtersWithCount(int count);

  /// No description provided for @quickNoEquipment.
  ///
  /// In en, this message translates to:
  /// **'No equipment'**
  String get quickNoEquipment;

  /// No description provided for @quickStandingOnly.
  ///
  /// In en, this message translates to:
  /// **'Standing only'**
  String get quickStandingOnly;

  /// No description provided for @quickLowImpact.
  ///
  /// In en, this message translates to:
  /// **'Low impact'**
  String get quickLowImpact;

  /// No description provided for @quickQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get quickQuiet;

  /// No description provided for @movementCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement Check'**
  String get movementCheckTitle;

  /// No description provided for @backToOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Back to onboarding'**
  String get backToOnboarding;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get yourProfile;

  /// No description provided for @setUpProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up profile'**
  String get setUpProfile;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get yourProgress;

  /// No description provided for @progressDeviceNote.
  ///
  /// In en, this message translates to:
  /// **'Based on workout history stored on this device.'**
  String get progressDeviceNote;

  /// No description provided for @noCompletedWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No completed workouts yet'**
  String get noCompletedWorkouts;

  /// No description provided for @finishWorkoutHint.
  ///
  /// In en, this message translates to:
  /// **'Finish a workout and your progress will appear here.'**
  String get finishWorkoutHint;

  /// No description provided for @startAWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start a workout'**
  String get startAWorkout;

  /// No description provided for @recentWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Recent workouts'**
  String get recentWorkouts;

  /// No description provided for @workoutDetail.
  ///
  /// In en, this message translates to:
  /// **'Workout detail'**
  String get workoutDetail;

  /// No description provided for @lastTrainedNever.
  ///
  /// In en, this message translates to:
  /// **'Never trained'**
  String get lastTrainedNever;

  /// No description provided for @lastTrainedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Last trained just now'**
  String get lastTrainedJustNow;

  /// No description provided for @lastTrainedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Last trained {count} minutes ago'**
  String lastTrainedMinutes(int count);

  /// No description provided for @lastTrainedOneHour.
  ///
  /// In en, this message translates to:
  /// **'Last trained 1 hour ago'**
  String get lastTrainedOneHour;

  /// No description provided for @lastTrainedHours.
  ///
  /// In en, this message translates to:
  /// **'Last trained {count} hours ago'**
  String lastTrainedHours(int count);

  /// No description provided for @lastTrainedToday.
  ///
  /// In en, this message translates to:
  /// **'Last trained today'**
  String get lastTrainedToday;

  /// No description provided for @lastTrainedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Last trained yesterday'**
  String get lastTrainedYesterday;

  /// No description provided for @lastTrainedDays.
  ///
  /// In en, this message translates to:
  /// **'Last trained {count} days ago'**
  String lastTrainedDays(int count);

  /// No description provided for @lastTrainedOn.
  ///
  /// In en, this message translates to:
  /// **'Last trained {date}'**
  String lastTrainedOn(String date);

  /// No description provided for @reminderSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout reminders'**
  String get reminderSectionTitle;

  /// No description provided for @reminderToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout reminders'**
  String get reminderToggleTitle;

  /// No description provided for @reminderToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly local reminders on the days and time you choose.'**
  String get reminderToggleSubtitle;

  /// No description provided for @reminderDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder days'**
  String get reminderDaysLabel;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimeLabel;

  /// No description provided for @reminderSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get reminderSendTest;

  /// No description provided for @reminderOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get reminderOpenSettings;

  /// No description provided for @reminderInexactNote.
  ///
  /// In en, this message translates to:
  /// **'Android may deliver reminders slightly later to reduce battery use.'**
  String get reminderInexactNote;

  /// No description provided for @reminderEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get reminderEveryDay;

  /// No description provided for @reminderNoDays.
  ///
  /// In en, this message translates to:
  /// **'No days selected'**
  String get reminderNoDays;

  /// No description provided for @reminderStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Reminders are off.'**
  String get reminderStatusOff;

  /// No description provided for @reminderStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Workout reminders are scheduled.'**
  String get reminderStatusScheduled;

  /// No description provided for @reminderStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Reminders are enabled in FitFlow, but notifications are blocked by Android.'**
  String get reminderStatusBlocked;

  /// No description provided for @reminderStatusError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t schedule reminders. Try again.'**
  String get reminderStatusError;

  /// No description provided for @reminderPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is needed to send workout reminders.'**
  String get reminderPermissionNeeded;

  /// No description provided for @reminderSelectDay.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day.'**
  String get reminderSelectDay;

  /// No description provided for @reminderSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save reminder settings. Try again.'**
  String get reminderSaveFailed;

  /// No description provided for @reminderTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent.'**
  String get reminderTestSent;

  /// No description provided for @reminderTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send a test notification.'**
  String get reminderTestFailed;

  /// No description provided for @reminderSettingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Notification settings are not available on this device.'**
  String get reminderSettingsUnavailable;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'FitFlow workout reminder'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your workout reminder is ready when you are.'**
  String get reminderNotificationBody;

  /// No description provided for @reminderTestTitle.
  ///
  /// In en, this message translates to:
  /// **'FitFlow test reminder'**
  String get reminderTestTitle;

  /// No description provided for @reminderTestBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications are working.'**
  String get reminderTestBody;

  /// No description provided for @scheduleSummary.
  ///
  /// In en, this message translates to:
  /// **'{days} • {time}'**
  String scheduleSummary(String days, String time);

  /// No description provided for @backupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupScreenTitle;

  /// No description provided for @backupSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a copy of your FitFlow data or restore it on this device.'**
  String get backupSettingsSubtitle;

  /// No description provided for @backupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backupCreate;

  /// No description provided for @backupChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup file'**
  String get backupChooseFile;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestore;

  /// No description provided for @programStart.
  ///
  /// In en, this message translates to:
  /// **'Start program'**
  String get programStart;

  /// No description provided for @programResume.
  ///
  /// In en, this message translates to:
  /// **'Resume program'**
  String get programResume;

  /// No description provided for @programContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get programContinue;

  /// No description provided for @programView.
  ///
  /// In en, this message translates to:
  /// **'View program'**
  String get programView;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String minutes(int count);

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String seconds(int count);

  /// No description provided for @minutesAndSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}} {seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String minutesAndSeconds(int minutes, int seconds);

  /// No description provided for @workoutCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout} other{{count} workouts}}'**
  String workoutCount(int count);

  /// No description provided for @signedWorkoutCount.
  ///
  /// In en, this message translates to:
  /// **'{sign}{count, plural, =1{1 workout} other{{count} workouts}}'**
  String signedWorkoutCount(String sign, int count);

  /// No description provided for @noChange.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get noChange;

  /// Exercise difficulty badge. Level number stays numeric.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String difficultyLevel(String level);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
