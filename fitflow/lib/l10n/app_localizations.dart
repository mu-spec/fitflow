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
  /// **'One last check: choose the exercise variations that feel right for you.'**
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
  /// **'Enable reminders'**
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

  /// No description provided for @onboardingIntroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR PERSONAL STARTING POINT'**
  String get onboardingIntroEyebrow;

  /// No description provided for @onboardingIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Training that fits your life.'**
  String get onboardingIntroTitle;

  /// No description provided for @onboardingIntroLevel.
  ///
  /// In en, this message translates to:
  /// **'Your starting point'**
  String get onboardingIntroLevel;

  /// No description provided for @onboardingIntroLevelBody.
  ///
  /// In en, this message translates to:
  /// **'Exercise variations matched to your movement ability.'**
  String get onboardingIntroLevelBody;

  /// No description provided for @onboardingIntroTime.
  ///
  /// In en, this message translates to:
  /// **'Your time, your space'**
  String get onboardingIntroTime;

  /// No description provided for @onboardingIntroTimeBody.
  ///
  /// In en, this message translates to:
  /// **'Sessions shaped around the time and equipment you have.'**
  String get onboardingIntroTimeBody;

  /// No description provided for @onboardingIntroSimple.
  ///
  /// In en, this message translates to:
  /// **'A few choices. A plan for you.'**
  String get onboardingIntroSimple;

  /// No description provided for @onboardingSingleChoice.
  ///
  /// In en, this message translates to:
  /// **'Choose one option to continue.'**
  String get onboardingSingleChoice;

  /// No description provided for @onboardingGoalHelp.
  ///
  /// In en, this message translates to:
  /// **'Your goal helps shape the exercises in your sessions.'**
  String get onboardingGoalHelp;

  /// No description provided for @onboardingExperienceHelp.
  ///
  /// In en, this message translates to:
  /// **'This gives us a starting point. You can fine-tune each movement next.'**
  String get onboardingExperienceHelp;

  /// No description provided for @onboardingTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose your usual session length. You can go lighter when you need to.'**
  String get onboardingTimeHelp;

  /// No description provided for @onboardingEnvironmentHelp.
  ///
  /// In en, this message translates to:
  /// **'We’ll choose exercises that work in your training space.'**
  String get onboardingEnvironmentHelp;

  /// No description provided for @onboardingEquipmentHelp.
  ///
  /// In en, this message translates to:
  /// **'Select all that you have. Choose None to train without equipment.'**
  String get onboardingEquipmentHelp;

  /// No description provided for @onboardingPreferencesHelp.
  ///
  /// In en, this message translates to:
  /// **'Select any that suit you, or continue without a selection.'**
  String get onboardingPreferencesHelp;

  /// No description provided for @onboardingPreferencesNote.
  ///
  /// In en, this message translates to:
  /// **'Preferences guide exercise selection; they are not medical advice.'**
  String get onboardingPreferencesNote;

  /// No description provided for @onboardingReadyHelp.
  ///
  /// In en, this message translates to:
  /// **'Movement Check comes next. Your answers help us choose appropriate exercise variations.'**
  String get onboardingReadyHelp;

  /// No description provided for @onboardingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save your setup. Please try again.'**
  String get onboardingSaveError;

  /// No description provided for @onboardingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving your setup…'**
  String get onboardingSaving;

  /// No description provided for @choiceSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get choiceSelected;

  /// No description provided for @choiceNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get choiceNotSelected;

  /// No description provided for @assessmentIntro.
  ///
  /// In en, this message translates to:
  /// **'Find your starting point'**
  String get assessmentIntro;

  /// No description provided for @assessmentBody.
  ///
  /// In en, this message translates to:
  /// **'Different movements can feel different. Review these suggestions to help FitFlow choose exercise variations that suit you.'**
  String get assessmentBody;

  /// No description provided for @assessmentSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested from your experience'**
  String get assessmentSuggested;

  /// No description provided for @assessmentChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get assessmentChanged;

  /// No description provided for @assessmentChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose what feels right'**
  String get assessmentChoose;

  /// No description provided for @assessmentSummary.
  ///
  /// In en, this message translates to:
  /// **'Your starting points'**
  String get assessmentSummary;

  /// No description provided for @assessmentSave.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get assessmentSave;

  /// No description provided for @assessmentSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving your movement profile…'**
  String get assessmentSaving;

  /// No description provided for @assessmentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your starting points are ready'**
  String get assessmentSuccess;

  /// No description provided for @assessmentLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get assessmentLoading;

  /// No description provided for @assessmentMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'We could not find your fitness profile.'**
  String get assessmentMissingTitle;

  /// No description provided for @assessmentMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Please complete onboarding first.'**
  String get assessmentMissingBody;

  /// No description provided for @assessmentOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Go to Onboarding'**
  String get assessmentOnboarding;

  /// No description provided for @assessmentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please review your movement choices and try again.'**
  String get assessmentInvalid;

  /// No description provided for @assessmentSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save your movement profile. Please try again.'**
  String get assessmentSaveError;

  /// No description provided for @homeBrand.
  ///
  /// In en, this message translates to:
  /// **'FITFLOW'**
  String get homeBrand;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your workout'**
  String get homeTitle;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY’S WORKOUT'**
  String get homeToday;

  /// No description provided for @homeSession.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Full Session'**
  String get homeSession;

  /// No description provided for @homeAdaptation.
  ///
  /// In en, this message translates to:
  /// **'Built around your goal, space, equipment, and current ability.'**
  String get homeAdaptation;

  /// No description provided for @homeBuiltForYou.
  ///
  /// In en, this message translates to:
  /// **'Built for you'**
  String get homeBuiltForYou;

  /// No description provided for @homeSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Workout details & preferences'**
  String get homeSetupHint;

  /// No description provided for @homeAdaptationDetail.
  ///
  /// In en, this message translates to:
  /// **'FitFlow chose exercises that match your movement capabilities and current workout preferences.'**
  String get homeAdaptationDetail;

  /// No description provided for @homeFocus.
  ///
  /// In en, this message translates to:
  /// **'Today’s focus'**
  String get homeFocus;

  /// No description provided for @homeTarget.
  ///
  /// In en, this message translates to:
  /// **'Target time'**
  String get homeTarget;

  /// No description provided for @homeExerciseLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get homeExerciseLabel;

  /// No description provided for @homePlannedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Planned time unavailable'**
  String get homePlannedUnknown;

  /// No description provided for @homePlannedShort.
  ///
  /// In en, this message translates to:
  /// **'Less than 1 min planned'**
  String get homePlannedShort;

  /// No description provided for @homeWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get homeWarmup;

  /// No description provided for @homeMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get homeMain;

  /// No description provided for @homeCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get homeCooldown;

  /// No description provided for @homeMode.
  ///
  /// In en, this message translates to:
  /// **'Workout mode'**
  String get homeMode;

  /// No description provided for @homeAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get homeAdjust;

  /// No description provided for @homeChooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose today\'s workout'**
  String get homeChooseMode;

  /// No description provided for @homeTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary for this workout'**
  String get homeTemporary;

  /// No description provided for @homeComebackSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Returning after some time away? Comeback gives you a shorter, gentler session without changing your movement levels.'**
  String get homeComebackSuggestion;

  /// No description provided for @homeUseComeback.
  ///
  /// In en, this message translates to:
  /// **'Use Comeback'**
  String get homeUseComeback;

  /// No description provided for @homeBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse exercises'**
  String get homeBrowse;

  /// No description provided for @homeBrowseHelp.
  ///
  /// In en, this message translates to:
  /// **'Explore the full exercise library'**
  String get homeBrowseHelp;

  /// No description provided for @homeGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get homeGoal;

  /// No description provided for @homeUsualTime.
  ///
  /// In en, this message translates to:
  /// **'Usual time'**
  String get homeUsualTime;

  /// No description provided for @homeEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get homeEnvironment;

  /// No description provided for @homeEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get homeEquipment;

  /// No description provided for @homePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get homePreferences;

  /// No description provided for @homeNoPreferences.
  ///
  /// In en, this message translates to:
  /// **'No special restrictions'**
  String get homeNoPreferences;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your adaptive workout...'**
  String get homeLoading;

  /// No description provided for @homeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your workout profile.'**
  String get homeErrorTitle;

  /// No description provided for @homeErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved data hasn’t been changed. Try loading it again.'**
  String get homeErrorBody;

  /// No description provided for @homeMissingProfile.
  ///
  /// In en, this message translates to:
  /// **'Your fitness profile is incomplete.'**
  String get homeMissingProfile;

  /// No description provided for @homeMissingProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to generate your adaptive workout.'**
  String get homeMissingProfileBody;

  /// No description provided for @homeCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get homeCompleteProfile;

  /// No description provided for @homeMissingAssessment.
  ///
  /// In en, this message translates to:
  /// **'Your movement assessment is incomplete.'**
  String get homeMissingAssessment;

  /// No description provided for @homeMissingAssessmentBody.
  ///
  /// In en, this message translates to:
  /// **'Complete the movement check to tailor workouts to your current ability.'**
  String get homeMissingAssessmentBody;

  /// No description provided for @homeStartAssessment.
  ///
  /// In en, this message translates to:
  /// **'Start assessment'**
  String get homeStartAssessment;

  /// No description provided for @homeNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No complete workout available'**
  String get homeNoPlan;

  /// No description provided for @homeNoPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Your current environment, equipment, or workout preferences leave too few compatible exercises for a complete session.'**
  String get homeNoPlanBody;

  /// No description provided for @homeReviewProfile.
  ///
  /// In en, this message translates to:
  /// **'Review your profile'**
  String get homeReviewProfile;

  /// No description provided for @onboardingProgress.
  ///
  /// In en, this message translates to:
  /// **'{step} of {total}'**
  String onboardingProgress(int step, int total);

  /// No description provided for @assessmentProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} movements ready'**
  String assessmentProgress(int count, int total);

  /// No description provided for @assessmentSummaryItem.
  ///
  /// In en, this message translates to:
  /// **'{movement} · {choice}'**
  String assessmentSummaryItem(String movement, String choice);

  /// No description provided for @homeDurationTarget.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min target'**
  String homeDurationTarget(int minutes);

  /// No description provided for @homePlanned.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min planned'**
  String homePlanned(int minutes);

  /// No description provided for @homeExercises.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String homeExercises(int count);

  /// No description provided for @assessmentPushTitle.
  ///
  /// In en, this message translates to:
  /// **'Pushing strength'**
  String get assessmentPushTitle;

  /// No description provided for @assessmentPushPrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you with pushing exercises such as push-ups?'**
  String get assessmentPushPrompt;

  /// No description provided for @assessmentPushExamples.
  ///
  /// In en, this message translates to:
  /// **'Wall Push-Up · Knee Push-Up · Standard Push-Up'**
  String get assessmentPushExamples;

  /// No description provided for @assessmentPullTitle.
  ///
  /// In en, this message translates to:
  /// **'Pulling strength'**
  String get assessmentPullTitle;

  /// No description provided for @assessmentPullPrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you with pulling and upper-back exercises?'**
  String get assessmentPullPrompt;

  /// No description provided for @assessmentPullExamples.
  ///
  /// In en, this message translates to:
  /// **'Towel Row · Doorway Row · Reverse Snow Angel'**
  String get assessmentPullExamples;

  /// No description provided for @assessmentSquatTitle.
  ///
  /// In en, this message translates to:
  /// **'Squat strength'**
  String get assessmentSquatTitle;

  /// No description provided for @assessmentSquatPrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you with squat-based lower-body exercises?'**
  String get assessmentSquatPrompt;

  /// No description provided for @assessmentSquatExamples.
  ///
  /// In en, this message translates to:
  /// **'Chair Sit-to-Stand · Bodyweight Squat · Tempo Squat'**
  String get assessmentSquatExamples;

  /// No description provided for @assessmentLungeTitle.
  ///
  /// In en, this message translates to:
  /// **'Lunge strength'**
  String get assessmentLungeTitle;

  /// No description provided for @assessmentLungePrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you with split-stance and lunge movements?'**
  String get assessmentLungePrompt;

  /// No description provided for @assessmentLungeExamples.
  ///
  /// In en, this message translates to:
  /// **'Static Split Squat · Reverse Lunge · Bulgarian Split Squat'**
  String get assessmentLungeExamples;

  /// No description provided for @assessmentHingeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hinge strength'**
  String get assessmentHingeTitle;

  /// No description provided for @assessmentHingePrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you with hip-hinge movements?'**
  String get assessmentHingePrompt;

  /// No description provided for @assessmentHingeExamples.
  ///
  /// In en, this message translates to:
  /// **'Hip Hinge · Good Morning · Single-Leg Hip Hinge'**
  String get assessmentHingeExamples;

  /// No description provided for @assessmentCoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Core stability'**
  String get assessmentCoreTitle;

  /// No description provided for @assessmentCorePrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you with core stability exercises?'**
  String get assessmentCorePrompt;

  /// No description provided for @assessmentCoreExamples.
  ///
  /// In en, this message translates to:
  /// **'Dead Bug · Knee Plank · Forearm Plank'**
  String get assessmentCoreExamples;

  /// No description provided for @assessmentGluteTitle.
  ///
  /// In en, this message translates to:
  /// **'Glute strength'**
  String get assessmentGluteTitle;

  /// No description provided for @assessmentGlutePrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you with glute-focused movements?'**
  String get assessmentGlutePrompt;

  /// No description provided for @assessmentGluteExamples.
  ///
  /// In en, this message translates to:
  /// **'Glute Bridge · Glute Bridge March · Single-Leg Glute Bridge'**
  String get assessmentGluteExamples;

  /// No description provided for @assessmentCardioTitle.
  ///
  /// In en, this message translates to:
  /// **'Cardio endurance'**
  String get assessmentCardioTitle;

  /// No description provided for @assessmentCardioPrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you with sustained home cardio movements?'**
  String get assessmentCardioPrompt;

  /// No description provided for @assessmentCardioExamples.
  ///
  /// In en, this message translates to:
  /// **'March in Place · Step Jack · High Knees'**
  String get assessmentCardioExamples;

  /// No description provided for @assessmentMobilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Mobility'**
  String get assessmentMobilityTitle;

  /// No description provided for @assessmentMobilityPrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you moving through controlled mobility exercises?'**
  String get assessmentMobilityPrompt;

  /// No description provided for @assessmentMobilityExamples.
  ///
  /// In en, this message translates to:
  /// **'Cat-Cow · Hip Flexor Stretch · World\'s Greatest Stretch'**
  String get assessmentMobilityExamples;

  /// No description provided for @assessmentBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get assessmentBalanceTitle;

  /// No description provided for @assessmentBalancePrompt.
  ///
  /// In en, this message translates to:
  /// **'How comfortable are you maintaining control in balance-focused movements?'**
  String get assessmentBalancePrompt;

  /// No description provided for @assessmentBalanceExamples.
  ///
  /// In en, this message translates to:
  /// **'Single-Leg Stand · Standing Knee Raise · Single-Leg Hip Hinge'**
  String get assessmentBalanceExamples;

  /// No description provided for @assessmentChoice1.
  ///
  /// In en, this message translates to:
  /// **'Just starting'**
  String get assessmentChoice1;

  /// No description provided for @assessmentChoice1Body.
  ///
  /// In en, this message translates to:
  /// **'Little or no experience with this movement, or only comfortable with very easy versions.'**
  String get assessmentChoice1Body;

  /// No description provided for @assessmentChoice2.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get assessmentChoice2;

  /// No description provided for @assessmentChoice2Body.
  ///
  /// In en, this message translates to:
  /// **'Comfortable with easier versions and learning consistent form.'**
  String get assessmentChoice2Body;

  /// No description provided for @assessmentChoice3.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get assessmentChoice3;

  /// No description provided for @assessmentChoice3Body.
  ///
  /// In en, this message translates to:
  /// **'Comfortable with standard versions of the movement with reasonable control.'**
  String get assessmentChoice3Body;

  /// No description provided for @assessmentChoice4.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get assessmentChoice4;

  /// No description provided for @assessmentChoice4Body.
  ///
  /// In en, this message translates to:
  /// **'Comfortable with challenging variations and higher training demand.'**
  String get assessmentChoice4Body;

  /// No description provided for @assessmentChoice5.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get assessmentChoice5;

  /// No description provided for @assessmentChoice5Body.
  ///
  /// In en, this message translates to:
  /// **'Comfortable with advanced variations and strong movement control.'**
  String get assessmentChoice5Body;

  /// No description provided for @flowPreview.
  ///
  /// In en, this message translates to:
  /// **'Workout preview'**
  String get flowPreview;

  /// No description provided for @flowPlayer.
  ///
  /// In en, this message translates to:
  /// **'Workout player'**
  String get flowPlayer;

  /// No description provided for @flowCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom workout'**
  String get flowCustom;

  /// No description provided for @flowProgram.
  ///
  /// In en, this message translates to:
  /// **'Program workout'**
  String get flowProgram;

  /// No description provided for @flowWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get flowWarmup;

  /// No description provided for @flowMain.
  ///
  /// In en, this message translates to:
  /// **'Main workout'**
  String get flowMain;

  /// No description provided for @flowCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get flowCooldown;

  /// No description provided for @flowReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to begin'**
  String get flowReady;

  /// No description provided for @flowWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get flowWork;

  /// No description provided for @flowRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get flowRest;

  /// No description provided for @flowNext.
  ///
  /// In en, this message translates to:
  /// **'Next exercise'**
  String get flowNext;

  /// No description provided for @flowPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get flowPaused;

  /// No description provided for @flowSeconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get flowSeconds;

  /// No description provided for @flowRestSeconds.
  ///
  /// In en, this message translates to:
  /// **'sec rest'**
  String get flowRestSeconds;

  /// No description provided for @flowReps.
  ///
  /// In en, this message translates to:
  /// **'{count} reps'**
  String flowReps(int count);

  /// No description provided for @flowSet.
  ///
  /// In en, this message translates to:
  /// **'Set {current} of {total}'**
  String flowSet(int current, int total);

  /// No description provided for @flowNextSet.
  ///
  /// In en, this message translates to:
  /// **'Next: Set {current} of {total}'**
  String flowNextSet(int current, int total);

  /// No description provided for @flowExercisePosition.
  ///
  /// In en, this message translates to:
  /// **'Exercise {current} of {total} in this section'**
  String flowExercisePosition(int current, int total);

  /// No description provided for @flowOverall.
  ///
  /// In en, this message translates to:
  /// **'Workout progress, {current} of {total} sets'**
  String flowOverall(int current, int total);

  /// No description provided for @flowSetsProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} sets'**
  String flowSetsProgress(int current, int total);

  /// No description provided for @flowWorkloadReps.
  ///
  /// In en, this message translates to:
  /// **'{sets, plural, =1{1 set} other{{sets} sets}} × {count} reps'**
  String flowWorkloadReps(int sets, int count);

  /// No description provided for @flowWorkloadTime.
  ///
  /// In en, this message translates to:
  /// **'{sets, plural, =1{1 set} other{{sets} sets}} × {count} sec'**
  String flowWorkloadTime(int sets, int count);

  /// No description provided for @flowCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String flowCount(int count);

  /// No description provided for @flowTarget.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min target'**
  String flowTarget(int minutes);

  /// No description provided for @flowEstimate.
  ///
  /// In en, this message translates to:
  /// **'{duration} planned'**
  String flowEstimate(String duration);

  /// No description provided for @flowDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String flowDuration(int minutes, int seconds);

  /// No description provided for @flowUnknownDuration.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get flowUnknownDuration;

  /// No description provided for @flowModeTemporary.
  ///
  /// In en, this message translates to:
  /// **'{mode} • Temporary for this workout'**
  String flowModeTemporary(String mode);

  /// No description provided for @flowPreviewDetails.
  ///
  /// In en, this message translates to:
  /// **'About this workout'**
  String get flowPreviewDetails;

  /// No description provided for @flowPreviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap an exercise for details. Replace the current exercise in the player, before its first set is complete.'**
  String get flowPreviewHelp;

  /// No description provided for @flowRestBetween.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec rest'**
  String flowRestBetween(int seconds);

  /// No description provided for @flowDetails.
  ///
  /// In en, this message translates to:
  /// **'Exercise details'**
  String get flowDetails;

  /// No description provided for @flowReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace exercise'**
  String get flowReplace;

  /// No description provided for @flowReplaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced {name}'**
  String flowReplaced(String name);

  /// No description provided for @flowCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {name}'**
  String flowCurrent(String name);

  /// No description provided for @flowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original: {name}'**
  String flowOriginal(String name);

  /// No description provided for @flowUse.
  ///
  /// In en, this message translates to:
  /// **'Use this exercise'**
  String get flowUse;

  /// No description provided for @flowReplaceWith.
  ///
  /// In en, this message translates to:
  /// **'Replace with {name}'**
  String flowReplaceWith(String name);

  /// No description provided for @flowMoreReasons.
  ///
  /// In en, this message translates to:
  /// **'Why this fits'**
  String get flowMoreReasons;

  /// No description provided for @flowNoAlternatives.
  ///
  /// In en, this message translates to:
  /// **'No suitable alternatives'**
  String get flowNoAlternatives;

  /// No description provided for @flowNoAlternativesBody.
  ///
  /// In en, this message translates to:
  /// **'No other exercise currently matches this movement, your ability, equipment, environment, and workout preferences.'**
  String get flowNoAlternativesBody;

  /// No description provided for @flowNoEquipment.
  ///
  /// In en, this message translates to:
  /// **'No equipment'**
  String get flowNoEquipment;

  /// No description provided for @flowReasonMovement.
  ///
  /// In en, this message translates to:
  /// **'Same movement focus'**
  String get flowReasonMovement;

  /// No description provided for @flowReasonDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Matches your current difficulty'**
  String get flowReasonDifficulty;

  /// No description provided for @flowReasonEasier.
  ///
  /// In en, this message translates to:
  /// **'Easier variation'**
  String get flowReasonEasier;

  /// No description provided for @flowReasonSetup.
  ///
  /// In en, this message translates to:
  /// **'Fits your equipment and environment'**
  String get flowReasonSetup;

  /// No description provided for @flowReasonPreferences.
  ///
  /// In en, this message translates to:
  /// **'Matches your workout preferences'**
  String get flowReasonPreferences;

  /// No description provided for @flowReasonFamily.
  ///
  /// In en, this message translates to:
  /// **'Same exercise progression family'**
  String get flowReasonFamily;

  /// No description provided for @flowReasonWorkload.
  ///
  /// In en, this message translates to:
  /// **'Keeps the same sets and workload'**
  String get flowReasonWorkload;

  /// No description provided for @flowMute.
  ///
  /// In en, this message translates to:
  /// **'Mute voice'**
  String get flowMute;

  /// No description provided for @flowVoice.
  ///
  /// In en, this message translates to:
  /// **'Enable voice'**
  String get flowVoice;

  /// No description provided for @flowPause.
  ///
  /// In en, this message translates to:
  /// **'Pause workout'**
  String get flowPause;

  /// No description provided for @flowResume.
  ///
  /// In en, this message translates to:
  /// **'Resume workout'**
  String get flowResume;

  /// No description provided for @flowExitTitle.
  ///
  /// In en, this message translates to:
  /// **'End workout?'**
  String get flowExitTitle;

  /// No description provided for @flowExitBody.
  ///
  /// In en, this message translates to:
  /// **'Your current session progress won\'t be saved.'**
  String get flowExitBody;

  /// No description provided for @flowKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Continue workout'**
  String get flowKeepGoing;

  /// No description provided for @flowExit.
  ///
  /// In en, this message translates to:
  /// **'Exit workout'**
  String get flowExit;

  /// No description provided for @flowComplete.
  ///
  /// In en, this message translates to:
  /// **'Workout complete'**
  String get flowComplete;

  /// No description provided for @flowFinished.
  ///
  /// In en, this message translates to:
  /// **'You finished all sets.'**
  String get flowFinished;

  /// No description provided for @flowExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get flowExercises;

  /// No description provided for @flowSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get flowSets;

  /// No description provided for @flowTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target duration'**
  String get flowTargetLabel;

  /// No description provided for @flowEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration'**
  String get flowEstimateLabel;

  /// No description provided for @flowHistory.
  ///
  /// In en, this message translates to:
  /// **'Completed workouts are saved to your history on this device.'**
  String get flowHistory;

  /// No description provided for @flowProgramComplete.
  ///
  /// In en, this message translates to:
  /// **'Program workout completed.'**
  String get flowProgramComplete;

  /// No description provided for @flowCustomNote.
  ///
  /// In en, this message translates to:
  /// **'Custom workouts don\'t change your movement levels.'**
  String get flowCustomNote;

  /// No description provided for @flowTemporaryNote.
  ///
  /// In en, this message translates to:
  /// **'This was a temporary {mode} workout. Your movement levels stay unchanged.'**
  String flowTemporaryNote(String mode);

  /// No description provided for @flowTune.
  ///
  /// In en, this message translates to:
  /// **'Tune next workout'**
  String get flowTune;

  /// No description provided for @flowTuneTitle.
  ///
  /// In en, this message translates to:
  /// **'Tune your next workout'**
  String get flowTuneTitle;

  /// No description provided for @flowTuneHelp.
  ///
  /// In en, this message translates to:
  /// **'Tell FitFlow how each movement felt. Your movement levels adapt independently.'**
  String get flowTuneHelp;

  /// No description provided for @flowApply.
  ///
  /// In en, this message translates to:
  /// **'Apply & finish'**
  String get flowApply;

  /// No description provided for @flowSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get flowSkip;

  /// No description provided for @flowTuneError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your workout tuning. Try again.'**
  String get flowTuneError;

  /// No description provided for @flowWarmupComplete.
  ///
  /// In en, this message translates to:
  /// **'Warm-up complete'**
  String get flowWarmupComplete;

  /// No description provided for @flowMainComplete.
  ///
  /// In en, this message translates to:
  /// **'Main workout complete'**
  String get flowMainComplete;

  /// No description provided for @flowMainNext.
  ///
  /// In en, this message translates to:
  /// **'Main workout is next'**
  String get flowMainNext;

  /// No description provided for @flowCooldownNext.
  ///
  /// In en, this message translates to:
  /// **'Cooldown is next'**
  String get flowCooldownNext;

  /// No description provided for @flowContinueHelp.
  ///
  /// In en, this message translates to:
  /// **'Continue when you are ready.'**
  String get flowContinueHelp;

  /// No description provided for @flowRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining {seconds} seconds'**
  String flowRemaining(int seconds);

  /// No description provided for @flowRestRemaining.
  ///
  /// In en, this message translates to:
  /// **'Rest remaining {seconds} seconds'**
  String flowRestRemaining(int seconds);

  /// No description provided for @flowTransitionRemaining.
  ///
  /// In en, this message translates to:
  /// **'Transition remaining {seconds} seconds'**
  String flowTransitionRemaining(int seconds);

  /// No description provided for @flowTimedWork.
  ///
  /// In en, this message translates to:
  /// **'Timed work'**
  String get flowTimedWork;

  /// No description provided for @flowSectionComplete.
  ///
  /// In en, this message translates to:
  /// **'Section complete.'**
  String get flowSectionComplete;

  /// No description provided for @flowNextFallback.
  ///
  /// In en, this message translates to:
  /// **'the next exercise'**
  String get flowNextFallback;

  /// No description provided for @flowReadyAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Ready. {section}. {name}.'**
  String flowReadyAnnouncement(String section, String name);

  /// No description provided for @flowWorkAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'{paused}{section}. {name}. Set {current} of {total}. {target}.'**
  String flowWorkAnnouncement(String paused, String section, String name,
      int current, int total, String target);

  /// No description provided for @flowRestAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'{paused}Rest. {name}.'**
  String flowRestAnnouncement(String paused, String name);

  /// No description provided for @flowNextAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'{paused}Next exercise. {name}.'**
  String flowNextAnnouncement(String paused, String name);

  /// No description provided for @flowPausedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Paused. '**
  String get flowPausedPrefix;

  /// No description provided for @flowCompleteAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Workout complete.'**
  String get flowCompleteAnnouncement;

  /// No description provided for @flowUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No workout available.'**
  String get flowUnavailable;

  /// No description provided for @flowEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No complete workout available'**
  String get flowEmptyTitle;

  /// No description provided for @flowEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your workout setup in Profile.'**
  String get flowEmptyBody;

  /// No description provided for @flowAdaptiveNote.
  ///
  /// In en, this message translates to:
  /// **'Built from your goal, movement levels, equipment, space, and preferences.'**
  String get flowAdaptiveNote;

  /// No description provided for @flowReadyCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom workout • Your prescription'**
  String get flowReadyCustom;

  /// No description provided for @flowReadyProgram.
  ///
  /// In en, this message translates to:
  /// **'Program workout • Standard'**
  String get flowReadyProgram;

  /// No description provided for @flowDecisionPromoted.
  ///
  /// In en, this message translates to:
  /// **'Two Easy sessions at your current level: ready for the next variation.'**
  String get flowDecisionPromoted;

  /// No description provided for @flowDecisionReduced.
  ///
  /// In en, this message translates to:
  /// **'An easier variation next time, based on your Too hard feedback.'**
  String get flowDecisionReduced;

  /// No description provided for @flowDecisionRight.
  ///
  /// In en, this message translates to:
  /// **'Keep this movement at its current level.'**
  String get flowDecisionRight;

  /// No description provided for @flowDecisionFirst.
  ///
  /// In en, this message translates to:
  /// **'One more Easy session at your current level may progress this movement.'**
  String get flowDecisionFirst;

  /// No description provided for @flowDecisionNotQualified.
  ///
  /// In en, this message translates to:
  /// **'This session did not include qualifying work at your current level; no level change.'**
  String get flowDecisionNotQualified;

  /// No description provided for @flowDecisionMaximum.
  ///
  /// In en, this message translates to:
  /// **'Already at the highest available level; no level change.'**
  String get flowDecisionMaximum;

  /// No description provided for @flowDecisionMinimum.
  ///
  /// In en, this message translates to:
  /// **'Already at the starting level; no level change.'**
  String get flowDecisionMinimum;

  /// No description provided for @trainingWorkoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your workouts'**
  String get trainingWorkoutsTitle;

  /// No description provided for @trainingWorkoutsIntro.
  ///
  /// In en, this message translates to:
  /// **'Follow a program or build a workout of your own.'**
  String get trainingWorkoutsIntro;

  /// No description provided for @trainingAdaptiveHome.
  ///
  /// In en, this message translates to:
  /// **'Today’s workout'**
  String get trainingAdaptiveHome;

  /// No description provided for @trainingAdaptiveAction.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get trainingAdaptiveAction;

  /// No description provided for @trainingPrograms.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get trainingPrograms;

  /// No description provided for @trainingProgramsHelp.
  ///
  /// In en, this message translates to:
  /// **'Structured plans that adapt to your level and setup.'**
  String get trainingProgramsHelp;

  /// No description provided for @trainingCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom workouts'**
  String get trainingCustom;

  /// No description provided for @trainingCreate.
  ///
  /// In en, this message translates to:
  /// **'Create workout'**
  String get trainingCreate;

  /// No description provided for @trainingCreateCustom.
  ///
  /// In en, this message translates to:
  /// **'Create custom workout'**
  String get trainingCreateCustom;

  /// No description provided for @trainingCustomHelp.
  ///
  /// In en, this message translates to:
  /// **'Build your own workout with exercises from your library.'**
  String get trainingCustomHelp;

  /// No description provided for @trainingCustomEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom workouts yet'**
  String get trainingCustomEmpty;

  /// No description provided for @trainingCustomError.
  ///
  /// In en, this message translates to:
  /// **'Could not load custom workouts.'**
  String get trainingCustomError;

  /// No description provided for @trainingDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete custom workout?'**
  String get trainingDeleteTitle;

  /// No description provided for @trainingDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the saved workout. Completed workout history is not deleted.'**
  String get trainingDeleteBody;

  /// No description provided for @trainingDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete this workout. Try again.'**
  String get trainingDeleteError;

  /// No description provided for @trainingExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get trainingExplore;

  /// No description provided for @trainingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get trainingLibrary;

  /// No description provided for @trainingSkills.
  ///
  /// In en, this message translates to:
  /// **'Exercise skill trees'**
  String get trainingSkills;

  /// No description provided for @trainingSkillsHelp.
  ///
  /// In en, this message translates to:
  /// **'Explore exercise progressions from easier to harder variations.'**
  String get trainingSkillsHelp;

  /// No description provided for @trainingView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get trainingView;

  /// No description provided for @trainingEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get trainingEdit;

  /// No description provided for @trainingDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get trainingDelete;

  /// No description provided for @trainingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get trainingCancel;

  /// No description provided for @trainingRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get trainingRetry;

  /// No description provided for @trainingClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get trainingClose;

  /// No description provided for @trainingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get trainingDone;

  /// No description provided for @trainingMoreActions.
  ///
  /// In en, this message translates to:
  /// **'Workout actions'**
  String get trainingMoreActions;

  /// No description provided for @trainingNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get trainingNotStarted;

  /// No description provided for @trainingInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get trainingInProgress;

  /// No description provided for @trainingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trainingCompleted;

  /// No description provided for @trainingUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get trainingUpcoming;

  /// No description provided for @trainingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get trainingNext;

  /// No description provided for @trainingProgramsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load program progress.'**
  String get trainingProgramsError;

  /// No description provided for @trainingProgramsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading program progress…'**
  String get trainingProgramsLoading;

  /// No description provided for @trainingHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Could not load workout history.'**
  String get trainingHistoryError;

  /// No description provided for @trainingHistoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading workout history…'**
  String get trainingHistoryLoading;

  /// No description provided for @trainingTrends.
  ///
  /// In en, this message translates to:
  /// **'Training trends'**
  String get trainingTrends;

  /// No description provided for @trainingTrendsHelp.
  ///
  /// In en, this message translates to:
  /// **'Activity, consistency and movement details'**
  String get trainingTrendsHelp;

  /// No description provided for @trainingMovementSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Current movement levels'**
  String get trainingMovementSnapshot;

  /// No description provided for @trainingRecoveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Training recovery'**
  String get trainingRecoveryDetails;

  /// No description provided for @trainingHistoryMore.
  ///
  /// In en, this message translates to:
  /// **'Show more workouts'**
  String get trainingHistoryMore;

  /// No description provided for @trainingHistoryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed workout'**
  String get trainingHistoryCompleted;

  /// No description provided for @trainingHistoryMissing.
  ///
  /// In en, this message translates to:
  /// **'Workout not found'**
  String get trainingHistoryMissing;

  /// No description provided for @trainingHistoryMissingHelp.
  ///
  /// In en, this message translates to:
  /// **'This workout may have been cleared.'**
  String get trainingHistoryMissingHelp;

  /// No description provided for @trainingPlannedDuration.
  ///
  /// In en, this message translates to:
  /// **'Planned duration'**
  String get trainingPlannedDuration;

  /// No description provided for @trainingEstimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration'**
  String get trainingEstimatedDuration;

  /// No description provided for @trainingTotalExercises.
  ///
  /// In en, this message translates to:
  /// **'Total exercises'**
  String get trainingTotalExercises;

  /// No description provided for @trainingTotalSets.
  ///
  /// In en, this message translates to:
  /// **'Total sets'**
  String get trainingTotalSets;

  /// No description provided for @trainingNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get trainingNoExercises;

  /// No description provided for @trainingUnclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified movement'**
  String get trainingUnclassified;

  /// No description provided for @trainingSavedWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Saved workouts'**
  String get trainingSavedWorkouts;

  /// No description provided for @trainingLast7.
  ///
  /// In en, this message translates to:
  /// **'Workouts — last 7 days'**
  String get trainingLast7;

  /// No description provided for @trainingPlanned7.
  ///
  /// In en, this message translates to:
  /// **'Planned time — last 7 days'**
  String get trainingPlanned7;

  /// No description provided for @trainingPlannedNote.
  ///
  /// In en, this message translates to:
  /// **'Planned time is not elapsed workout time.'**
  String get trainingPlannedNote;

  /// No description provided for @trainingActivity.
  ///
  /// In en, this message translates to:
  /// **'8-week activity'**
  String get trainingActivity;

  /// No description provided for @trainingActivityHelp.
  ///
  /// In en, this message translates to:
  /// **'Completed workouts over eight rolling 7-day periods. Oldest first, current last.'**
  String get trainingActivityHelp;

  /// No description provided for @trainingWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get trainingWorkouts;

  /// No description provided for @trainingSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get trainingSets;

  /// No description provided for @trainingCurrentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Current 7 days'**
  String get trainingCurrentPeriod;

  /// No description provided for @trainingNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No workouts in last 8 weeks.'**
  String get trainingNoActivity;

  /// No description provided for @trainingMovementHelp.
  ///
  /// In en, this message translates to:
  /// **'Your current movement-specific levels used by adaptive workouts.'**
  String get trainingMovementHelp;

  /// No description provided for @trainingMovementLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading movement levels…'**
  String get trainingMovementLoading;

  /// No description provided for @trainingMovementUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Movement levels unavailable.'**
  String get trainingMovementUnavailable;

  /// No description provided for @trainingMovementMissing.
  ///
  /// In en, this message translates to:
  /// **'Complete your movement assessment to see your starting points.'**
  String get trainingMovementMissing;

  /// No description provided for @trainingUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get trainingUnknown;

  /// No description provided for @trainingStanding.
  ///
  /// In en, this message translates to:
  /// **'Standing only'**
  String get trainingStanding;

  /// No description provided for @trainingLowImpact.
  ///
  /// In en, this message translates to:
  /// **'Low impact'**
  String get trainingLowImpact;

  /// No description provided for @trainingClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get trainingClearFilters;

  /// No description provided for @trainingClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get trainingClearAll;

  /// No description provided for @trainingMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement Pattern'**
  String get trainingMovement;

  /// No description provided for @trainingDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get trainingDifficulty;

  /// No description provided for @trainingEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get trainingEquipment;

  /// No description provided for @trainingPosition.
  ///
  /// In en, this message translates to:
  /// **'Body Position'**
  String get trainingPosition;

  /// No description provided for @trainingCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exercises available'**
  String get trainingCatalogEmpty;

  /// No description provided for @trainingCatalogEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'There are no exercises in this catalog.'**
  String get trainingCatalogEmptyHelp;

  /// No description provided for @trainingNoResults.
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get trainingNoResults;

  /// No description provided for @trainingNoResultsHelp.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or adjust your filters.'**
  String get trainingNoResultsHelp;

  /// No description provided for @trainingDetails.
  ///
  /// In en, this message translates to:
  /// **'Exercise details'**
  String get trainingDetails;

  /// No description provided for @trainingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Exercise not found'**
  String get trainingNotFound;

  /// No description provided for @trainingNotFoundHelp.
  ///
  /// In en, this message translates to:
  /// **'This exercise is no longer available.'**
  String get trainingNotFoundHelp;

  /// No description provided for @trainingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get trainingBack;

  /// No description provided for @trainingDefaults.
  ///
  /// In en, this message translates to:
  /// **'Default Prescription'**
  String get trainingDefaults;

  /// No description provided for @trainingMuscles.
  ///
  /// In en, this message translates to:
  /// **'Muscles Worked'**
  String get trainingMuscles;

  /// No description provided for @trainingPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get trainingPrimary;

  /// No description provided for @trainingSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get trainingSecondary;

  /// No description provided for @trainingHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to Perform'**
  String get trainingHowTo;

  /// No description provided for @trainingMistakes.
  ///
  /// In en, this message translates to:
  /// **'Common Mistakes'**
  String get trainingMistakes;

  /// No description provided for @trainingBreathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get trainingBreathing;

  /// No description provided for @trainingProgression.
  ///
  /// In en, this message translates to:
  /// **'Progression'**
  String get trainingProgression;

  /// No description provided for @trainingEasier.
  ///
  /// In en, this message translates to:
  /// **'Easier variation'**
  String get trainingEasier;

  /// No description provided for @trainingCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current exercise'**
  String get trainingCurrent;

  /// No description provided for @trainingHarder.
  ///
  /// In en, this message translates to:
  /// **'Harder variation'**
  String get trainingHarder;

  /// No description provided for @trainingViewExercise.
  ///
  /// In en, this message translates to:
  /// **'View exercise'**
  String get trainingViewExercise;

  /// No description provided for @trainingViewTree.
  ///
  /// In en, this message translates to:
  /// **'View full skill tree'**
  String get trainingViewTree;

  /// No description provided for @trainingCatalogDetails.
  ///
  /// In en, this message translates to:
  /// **'Exercise characteristics'**
  String get trainingCatalogDetails;

  /// No description provided for @trainingNoEquipment.
  ///
  /// In en, this message translates to:
  /// **'No equipment'**
  String get trainingNoEquipment;

  /// No description provided for @trainingLevelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Movement level unavailable'**
  String get trainingLevelUnavailable;

  /// No description provided for @trainingSkillIntro.
  ///
  /// In en, this message translates to:
  /// **'See how exercise variations progress from easier to harder.'**
  String get trainingSkillIntro;

  /// No description provided for @trainingSkillTruth.
  ///
  /// In en, this message translates to:
  /// **'Your movement level helps show which exercises fit your current level. It does not mean every easier exercise is mastered.'**
  String get trainingSkillTruth;

  /// No description provided for @trainingSkillEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exercise skill trees available yet'**
  String get trainingSkillEmpty;

  /// No description provided for @trainingSkillEmptyHelp.
  ///
  /// In en, this message translates to:
  /// **'Exercise progressions will appear here when they are available in the catalog.'**
  String get trainingSkillEmptyHelp;

  /// No description provided for @trainingSkillFitHelp.
  ///
  /// In en, this message translates to:
  /// **'Exercises at or below this difficulty fit your current movement level.'**
  String get trainingSkillFitHelp;

  /// No description provided for @trainingSkillPathTruth.
  ///
  /// In en, this message translates to:
  /// **'This pathway shows exercise difficulty and setup fit, not exercise mastery.'**
  String get trainingSkillPathTruth;

  /// No description provided for @trainingFitsLevel.
  ///
  /// In en, this message translates to:
  /// **'Fits your current level'**
  String get trainingFitsLevel;

  /// No description provided for @trainingAboveLevel.
  ///
  /// In en, this message translates to:
  /// **'Above your current level'**
  String get trainingAboveLevel;

  /// No description provided for @trainingFitsSetup.
  ///
  /// In en, this message translates to:
  /// **'Fits your setup'**
  String get trainingFitsSetup;

  /// No description provided for @trainingNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs setup change'**
  String get trainingNeedsSetup;

  /// No description provided for @trainingSetupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Setup details unavailable'**
  String get trainingSetupUnavailable;

  /// No description provided for @trainingSkillTree.
  ///
  /// In en, this message translates to:
  /// **'Skill tree'**
  String get trainingSkillTree;

  /// No description provided for @trainingSkillMissing.
  ///
  /// In en, this message translates to:
  /// **'Skill tree not found'**
  String get trainingSkillMissing;

  /// No description provided for @trainingSkillMissingHelp.
  ///
  /// In en, this message translates to:
  /// **'This progression is not available in the current exercise catalog.'**
  String get trainingSkillMissingHelp;

  /// No description provided for @trainingBackSkills.
  ///
  /// In en, this message translates to:
  /// **'Back to Skill Trees'**
  String get trainingBackSkills;

  /// No description provided for @trainingBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse {count} exercises'**
  String trainingBrowse(int count);

  /// No description provided for @trainingExerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String trainingExerciseCount(int count);

  /// No description provided for @trainingCustomSummary.
  ///
  /// In en, this message translates to:
  /// **'Target: {duration} • {count, plural, =1{1 exercise} other{{count} exercises}}'**
  String trainingCustomSummary(String duration, int count);

  /// No description provided for @trainingEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated: {duration}'**
  String trainingEstimated(String duration);

  /// No description provided for @trainingSessions.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} sessions'**
  String trainingSessions(int done, int total);

  /// No description provided for @trainingSession.
  ///
  /// In en, this message translates to:
  /// **'Session {number}'**
  String trainingSession(int number);

  /// No description provided for @trainingNextSession.
  ///
  /// In en, this message translates to:
  /// **'Week {week} • Next: {title}'**
  String trainingNextSession(int week, String title);

  /// No description provided for @trainingHistoryCounts.
  ///
  /// In en, this message translates to:
  /// **'{exercises, plural, =1{1 exercise} other{{exercises} exercises}} • {sets, plural, =1{1 set} other{{sets} sets}}'**
  String trainingHistoryCounts(int exercises, int sets);

  /// No description provided for @trainingWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Previous 7 days} other{{count} periods ago}}'**
  String trainingWeeksAgo(int count);

  /// No description provided for @trainingActivityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout} other{{count} workouts}}'**
  String trainingActivityCount(int count);

  /// No description provided for @trainingActivitySets.
  ///
  /// In en, this message translates to:
  /// **'{count} main sets'**
  String trainingActivitySets(int count);

  /// No description provided for @trainingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String trainingStep(int step, int total);

  /// No description provided for @trainingSteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String trainingSteps(int count);

  /// No description provided for @trainingMovementLevel.
  ///
  /// In en, this message translates to:
  /// **'Your {movement} level: {level}'**
  String trainingMovementLevel(String movement, String level);

  /// No description provided for @trainingFitCount.
  ///
  /// In en, this message translates to:
  /// **'{count} fit your current level'**
  String trainingFitCount(int count);

  /// No description provided for @trainingAboveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} above your current level'**
  String trainingAboveCount(int count);

  /// No description provided for @trainingSetupCount.
  ///
  /// In en, this message translates to:
  /// **'{count} fit your current setup'**
  String trainingSetupCount(int count);

  /// No description provided for @trainingEquipmentFor.
  ///
  /// In en, this message translates to:
  /// **'Equipment: {equipment}'**
  String trainingEquipmentFor(String equipment);

  /// No description provided for @trainingRest.
  ///
  /// In en, this message translates to:
  /// **'Rest: {duration}'**
  String trainingRest(String duration);

  /// No description provided for @trainingWorkloadReps.
  ///
  /// In en, this message translates to:
  /// **'{sets} × {reps} reps'**
  String trainingWorkloadReps(int sets, int reps);

  /// No description provided for @trainingWorkloadTimed.
  ///
  /// In en, this message translates to:
  /// **'{sets} × {duration}'**
  String trainingWorkloadTimed(int sets, String duration);

  /// No description provided for @trainingProgramEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get trainingProgramEntryTitle;

  /// No description provided for @trainingProgramEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive multi-week workouts built around your current level and setup.'**
  String get trainingProgramEntrySubtitle;

  /// No description provided for @trainingProgramRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended program'**
  String get trainingProgramRecommendedTitle;

  /// No description provided for @trainingProgramRecommendedMatch.
  ///
  /// In en, this message translates to:
  /// **'Matches your selected goal'**
  String get trainingProgramRecommendedMatch;

  /// No description provided for @trainingProgramRecommendedMissingProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to see a program matched to your selected goal.'**
  String get trainingProgramRecommendedMissingProfile;

  /// No description provided for @trainingProgramViewProgram.
  ///
  /// In en, this message translates to:
  /// **'View program'**
  String get trainingProgramViewProgram;

  /// No description provided for @trainingProgramActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active program'**
  String get trainingProgramActiveTitle;

  /// No description provided for @trainingProgramContinueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get trainingProgramContinueLabel;

  /// No description provided for @trainingProgramOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive programs'**
  String get trainingProgramOverviewTitle;

  /// No description provided for @trainingProgramAbout.
  ///
  /// In en, this message translates to:
  /// **'About this program'**
  String get trainingProgramAbout;

  /// No description provided for @trainingProgramOverviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Multi-week plans that adapt to your level and setup.'**
  String get trainingProgramOverviewIntro;

  /// No description provided for @trainingProgramStartProgram.
  ///
  /// In en, this message translates to:
  /// **'Start program'**
  String get trainingProgramStartProgram;

  /// No description provided for @trainingProgramResumeProgram.
  ///
  /// In en, this message translates to:
  /// **'Resume program'**
  String get trainingProgramResumeProgram;

  /// No description provided for @trainingProgramSwitchProgram.
  ///
  /// In en, this message translates to:
  /// **'Switch to this program'**
  String get trainingProgramSwitchProgram;

  /// No description provided for @trainingProgramRestartProgram.
  ///
  /// In en, this message translates to:
  /// **'Restart program'**
  String get trainingProgramRestartProgram;

  /// No description provided for @trainingProgramProgramComplete.
  ///
  /// In en, this message translates to:
  /// **'Program complete'**
  String get trainingProgramProgramComplete;

  /// No description provided for @trainingProgramViewWorkout.
  ///
  /// In en, this message translates to:
  /// **'View workout'**
  String get trainingProgramViewWorkout;

  /// No description provided for @trainingProgramSwitchDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch active program?'**
  String get trainingProgramSwitchDialogTitle;

  /// No description provided for @trainingProgramSwitchDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress in the current program will be kept.'**
  String get trainingProgramSwitchDialogBody;

  /// No description provided for @trainingProgramSwitchDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get trainingProgramSwitchDialogConfirm;

  /// No description provided for @trainingProgramRestartDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart this program?'**
  String get trainingProgramRestartDialogTitle;

  /// No description provided for @trainingProgramRestartDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Its saved program progress will be cleared. Completed workout history will stay unchanged.'**
  String get trainingProgramRestartDialogBody;

  /// No description provided for @trainingProgramRestartDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get trainingProgramRestartDialogConfirm;

  /// No description provided for @trainingProgramCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get trainingProgramCancel;

  /// No description provided for @trainingProgramActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save program changes. Try again.'**
  String get trainingProgramActionFailed;

  /// No description provided for @trainingProgramPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Program workout'**
  String get trainingProgramPreviewTitle;

  /// No description provided for @trainingProgramAdaptationNote.
  ///
  /// In en, this message translates to:
  /// **'Generated from your current movement levels, equipment, environment, and preferences.'**
  String get trainingProgramAdaptationNote;

  /// No description provided for @trainingProgramGoalUnchangedNote.
  ///
  /// In en, this message translates to:
  /// **'Your saved profile goal is not changed by this program session.'**
  String get trainingProgramGoalUnchangedNote;

  /// No description provided for @trainingProgramGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'This program workout can\'t be generated with your current setup.'**
  String get trainingProgramGenerationFailed;

  /// No description provided for @trainingProgramStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get trainingProgramStartWorkout;

  /// No description provided for @trainingProgramPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Program workout'**
  String get trainingProgramPlayerTitle;

  /// No description provided for @trainingProgramPlayerWorkoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Program workout not found'**
  String get trainingProgramPlayerWorkoutNotFound;

  /// No description provided for @trainingProgramPlayerWorkoutNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This workout isn\'t part of the program. Go back and choose one from the program.'**
  String get trainingProgramPlayerWorkoutNotFoundBody;

  /// No description provided for @trainingProgramBackToPrograms.
  ///
  /// In en, this message translates to:
  /// **'Back to programs'**
  String get trainingProgramBackToPrograms;

  /// No description provided for @trainingProgramBackToProgram.
  ///
  /// In en, this message translates to:
  /// **'Back to program'**
  String get trainingProgramBackToProgram;

  /// No description provided for @trainingProgramProgramWorkoutCompleted.
  ///
  /// In en, this message translates to:
  /// **'Program workout completed.'**
  String get trainingProgramProgramWorkoutCompleted;

  /// No description provided for @trainingProgramProgramNotFound.
  ///
  /// In en, this message translates to:
  /// **'Program not found'**
  String get trainingProgramProgramNotFound;

  /// No description provided for @trainingProgramProgramNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This program isn\'t available. Go back and choose one from the list.'**
  String get trainingProgramProgramNotFoundBody;

  /// No description provided for @trainingProgramSessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found'**
  String get trainingProgramSessionNotFound;

  /// No description provided for @trainingProgramSessionNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This session isn\'t part of the program. Go back and choose one from the program.'**
  String get trainingProgramSessionNotFoundBody;

  /// No description provided for @trainingProgramWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String trainingProgramWeeks(int count);

  /// No description provided for @trainingProgramPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session/week} other{{count} sessions/week}}'**
  String trainingProgramPerWeek(int count);

  /// No description provided for @trainingProgramTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout} other{{count} workouts}}'**
  String trainingProgramTotal(int count);

  /// No description provided for @trainingProgramWeek.
  ///
  /// In en, this message translates to:
  /// **'Week {count}'**
  String trainingProgramWeek(int count);

  /// No description provided for @trainingCustomNeedsUpdate.
  ///
  /// In en, this message translates to:
  /// **'This workout needs updates for your current setup.'**
  String get trainingCustomNeedsUpdate;

  /// No description provided for @trainingCustomReview.
  ///
  /// In en, this message translates to:
  /// **'Edit this workout to review its exercises and setup.'**
  String get trainingCustomReview;

  /// No description provided for @trainingMissingExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise unavailable'**
  String get trainingMissingExercise;

  /// No description provided for @trainingCustomStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get trainingCustomStart;

  /// No description provided for @trainingCustomLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading custom workouts…'**
  String get trainingCustomLoading;

  /// No description provided for @trainingCustomFix.
  ///
  /// In en, this message translates to:
  /// **'Fix the issues above to start this workout.'**
  String get trainingCustomFix;

  /// No description provided for @utilityPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get utilityPreferences;

  /// No description provided for @utilityData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get utilityData;

  /// No description provided for @utilityAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get utilityAbout;

  /// No description provided for @utilityAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get utilityAppearance;

  /// No description provided for @utilitySystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get utilitySystemDefault;

  /// No description provided for @utilitySystemHelp.
  ///
  /// In en, this message translates to:
  /// **'Follow your device setting.'**
  String get utilitySystemHelp;

  /// No description provided for @utilityLightHelp.
  ///
  /// In en, this message translates to:
  /// **'Always use the light theme.'**
  String get utilityLightHelp;

  /// No description provided for @utilityDarkHelp.
  ///
  /// In en, this message translates to:
  /// **'Always use the dark theme.'**
  String get utilityDarkHelp;

  /// No description provided for @utilitySaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get utilitySaving;

  /// No description provided for @utilityUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get utilityUpdating;

  /// No description provided for @utilityMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement levels'**
  String get utilityMovementTitle;

  /// No description provided for @utilityMovementSummary.
  ///
  /// In en, this message translates to:
  /// **'How exercise variations are chosen'**
  String get utilityMovementSummary;

  /// No description provided for @utilityMovementBody.
  ///
  /// In en, this message translates to:
  /// **'FitFlow uses a separate level for each movement to choose exercise variations. These are your current saved levels, not a health score.'**
  String get utilityMovementBody;

  /// No description provided for @utilityMovementMissing.
  ///
  /// In en, this message translates to:
  /// **'No movement levels saved yet.'**
  String get utilityMovementMissing;

  /// No description provided for @utilityMovementError.
  ///
  /// In en, this message translates to:
  /// **'Your movement levels couldn’t be loaded.'**
  String get utilityMovementError;

  /// No description provided for @utilityRetryBody.
  ///
  /// In en, this message translates to:
  /// **'Try loading again.'**
  String get utilityRetryBody;

  /// No description provided for @utilityNoPreferences.
  ///
  /// In en, this message translates to:
  /// **'No special workout preferences'**
  String get utilityNoPreferences;

  /// No description provided for @utilityEditorDraft.
  ///
  /// In en, this message translates to:
  /// **'Changes stay here until you save.'**
  String get utilityEditorDraft;

  /// No description provided for @utilityCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get utilityCancel;

  /// No description provided for @utilitySave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get utilitySave;

  /// No description provided for @utilityDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get utilityDiscardTitle;

  /// No description provided for @utilityDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get utilityDiscardBody;

  /// No description provided for @utilityKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get utilityKeepEditing;

  /// No description provided for @utilityDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get utilityDiscard;

  /// No description provided for @utilityGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get utilityGoal;

  /// No description provided for @utilityExperience.
  ///
  /// In en, this message translates to:
  /// **'Training experience'**
  String get utilityExperience;

  /// No description provided for @utilityDuration.
  ///
  /// In en, this message translates to:
  /// **'Typical workout time'**
  String get utilityDuration;

  /// No description provided for @utilityEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Training environment'**
  String get utilityEnvironment;

  /// No description provided for @utilityLoadingReminders.
  ///
  /// In en, this message translates to:
  /// **'Loading reminders…'**
  String get utilityLoadingReminders;

  /// No description provided for @utilitySavedSchedule.
  ///
  /// In en, this message translates to:
  /// **'Choose days and a time. Changes save as you make them.'**
  String get utilitySavedSchedule;

  /// No description provided for @utilityProfileError.
  ///
  /// In en, this message translates to:
  /// **'Your profile couldn\'t be loaded.'**
  String get utilityProfileError;

  /// No description provided for @utilityProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'Fitness profile not set up'**
  String get utilityProfileMissing;

  /// No description provided for @utilityProfileSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Answer a few quick questions so FitFlow can tailor your workouts.'**
  String get utilityProfileSetupBody;

  /// No description provided for @utilityCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String utilityCurrentValue(String value);

  /// No description provided for @utilitySelectedValue.
  ///
  /// In en, this message translates to:
  /// **'Selected: {value}'**
  String utilitySelectedValue(String value);

  /// No description provided for @utilitySettingsSummary.
  ///
  /// In en, this message translates to:
  /// **'Appearance, reminders, and backups.'**
  String get utilitySettingsSummary;

  /// No description provided for @utilityEditSection.
  ///
  /// In en, this message translates to:
  /// **'Edit {section}'**
  String utilityEditSection(String section);

  /// No description provided for @part6LoadingTuning.
  ///
  /// In en, this message translates to:
  /// **'Loading movement feedback…'**
  String get part6LoadingTuning;

  /// No description provided for @part6RepetitionWork.
  ///
  /// In en, this message translates to:
  /// **'Repetitions'**
  String get part6RepetitionWork;

  /// No description provided for @part6AddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise: {section}'**
  String part6AddExercise(String section);

  /// No description provided for @part6NoSectionExercises.
  ///
  /// In en, this message translates to:
  /// **'No eligible exercises available for this section.'**
  String get part6NoSectionExercises;

  /// No description provided for @v2HomeTargetUnit.
  ///
  /// In en, this message translates to:
  /// **'min target'**
  String get v2HomeTargetUnit;

  /// No description provided for @profileIntro.
  ///
  /// In en, this message translates to:
  /// **'Your setup for future workouts.'**
  String get profileIntro;

  /// No description provided for @profileFitnessEntry.
  ///
  /// In en, this message translates to:
  /// **'Fitness Profile'**
  String get profileFitnessEntry;

  /// No description provided for @profilePreferencesEntry.
  ///
  /// In en, this message translates to:
  /// **'Workout Preferences'**
  String get profilePreferencesEntry;
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
