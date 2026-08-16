import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Nexora — Career Intelligence'**
  String get appTitle;

  /// No description provided for @brandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CAREER INTELLIGENCE'**
  String get brandSubtitle;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @welcomeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Nexora'**
  String get welcomeEyebrow;

  /// No description provided for @welcomeTitleCareer.
  ///
  /// In en, this message translates to:
  /// **'Your Career'**
  String get welcomeTitleCareer;

  /// No description provided for @welcomeTitleUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Understood.'**
  String get welcomeTitleUnderstood;

  /// No description provided for @welcomeTitleElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated.'**
  String get welcomeTitleElevated;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'AI-powered career intelligence that understands who you are, what you want, and how to get you there.'**
  String get welcomeBody;

  /// No description provided for @trustPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Private'**
  String get trustPrivateTitle;

  /// No description provided for @trustPrivateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is secure\nand encrypted'**
  String get trustPrivateSubtitle;

  /// No description provided for @trustAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered'**
  String get trustAiTitle;

  /// No description provided for @trustAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart insights that\nsave you time'**
  String get trustAiSubtitle;

  /// No description provided for @trustResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results-Driven'**
  String get trustResultsTitle;

  /// No description provided for @trustResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get more interviews\nand opportunities'**
  String get trustResultsSubtitle;

  /// No description provided for @featureMatchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Matching'**
  String get featureMatchingTitle;

  /// No description provided for @featureMatchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find opportunities that\ntruly fit you.'**
  String get featureMatchingSubtitle;

  /// No description provided for @featureAtsTitle.
  ///
  /// In en, this message translates to:
  /// **'ATS Optimization'**
  String get featureAtsTitle;

  /// No description provided for @featureAtsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Beat the system with\nAI-powered insights.'**
  String get featureAtsSubtitle;

  /// No description provided for @featureInterviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview Ready'**
  String get featureInterviewTitle;

  /// No description provided for @featureInterviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice with AI and\nbuild your confidence.'**
  String get featureInterviewSubtitle;

  /// No description provided for @featureGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'Career Growth'**
  String get featureGrowthTitle;

  /// No description provided for @featureGrowthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track progress and\nachieve your goals.'**
  String get featureGrowthSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @privacySecure.
  ///
  /// In en, this message translates to:
  /// **'Your data is private and secure.'**
  String get privacySecure;

  /// No description provided for @privacyShare.
  ///
  /// In en, this message translates to:
  /// **'We never share your information.'**
  String get privacyShare;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingCreateDna.
  ///
  /// In en, this message translates to:
  /// **'Create my career DNA'**
  String get onboardingCreateDna;

  /// No description provided for @onboardingSlide1Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'01 · ANALYZE'**
  String get onboardingSlide1Eyebrow;

  /// No description provided for @onboardingSlide1TitleLead.
  ///
  /// In en, this message translates to:
  /// **'Know your match\n'**
  String get onboardingSlide1TitleLead;

  /// No description provided for @onboardingSlide1TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'before you apply.'**
  String get onboardingSlide1TitleAccent;

  /// No description provided for @onboardingSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Paste any job, scholarship, or program. Nexora extracts the real requirements and scores them against your Career DNA.'**
  String get onboardingSlide1Body;

  /// No description provided for @onboardingSlide2Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'02 · BUILD'**
  String get onboardingSlide2Eyebrow;

  /// No description provided for @onboardingSlide2TitleLead.
  ///
  /// In en, this message translates to:
  /// **'CVs engineered\n'**
  String get onboardingSlide2TitleLead;

  /// No description provided for @onboardingSlide2TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'to beat the ATS.'**
  String get onboardingSlide2TitleAccent;

  /// No description provided for @onboardingSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'The AI CV Studio scores every line against your target role — then rewrites it until the machines say yes.'**
  String get onboardingSlide2Body;

  /// No description provided for @onboardingSlide3Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'03 · TRACK'**
  String get onboardingSlide3Eyebrow;

  /// No description provided for @onboardingSlide3TitleLead.
  ///
  /// In en, this message translates to:
  /// **'Own your entire\n'**
  String get onboardingSlide3TitleLead;

  /// No description provided for @onboardingSlide3TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'career pipeline.'**
  String get onboardingSlide3TitleAccent;

  /// No description provided for @onboardingSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Applications, interviews and offers in one calm dashboard. Practice rounds and smart nudges keep you on target.'**
  String get onboardingSlide3Body;

  /// No description provided for @mockMatchBadge.
  ///
  /// In en, this message translates to:
  /// **'91% MATCH'**
  String get mockMatchBadge;

  /// No description provided for @mockOpportunityMatch.
  ///
  /// In en, this message translates to:
  /// **'OPPORTUNITY MATCH'**
  String get mockOpportunityMatch;

  /// No description provided for @mockMatch.
  ///
  /// In en, this message translates to:
  /// **'MATCH'**
  String get mockMatch;

  /// No description provided for @mockStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong ✓'**
  String get mockStrong;

  /// No description provided for @mockMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing ✗'**
  String get mockMissing;

  /// No description provided for @mockSkills.
  ///
  /// In en, this message translates to:
  /// **'SKILLS'**
  String get mockSkills;

  /// No description provided for @mockExperience.
  ///
  /// In en, this message translates to:
  /// **'EXPERIENCE'**
  String get mockExperience;

  /// No description provided for @mockAtsScore.
  ///
  /// In en, this message translates to:
  /// **'ATS SCORE'**
  String get mockAtsScore;

  /// No description provided for @mockTop10.
  ///
  /// In en, this message translates to:
  /// **'TOP 10%'**
  String get mockTop10;

  /// No description provided for @mockUpdatedToday.
  ///
  /// In en, this message translates to:
  /// **'Updated today'**
  String get mockUpdatedToday;

  /// No description provided for @mockAiRewrite.
  ///
  /// In en, this message translates to:
  /// **'AI REWRITE ✓'**
  String get mockAiRewrite;

  /// No description provided for @mockOptimize.
  ///
  /// In en, this message translates to:
  /// **'OPTIMIZE'**
  String get mockOptimize;

  /// No description provided for @mockApplications.
  ///
  /// In en, this message translates to:
  /// **'APPLICATIONS'**
  String get mockApplications;

  /// No description provided for @mockHrRound.
  ///
  /// In en, this message translates to:
  /// **'HR ROUND'**
  String get mockHrRound;

  /// No description provided for @mockStatusInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get mockStatusInterview;

  /// No description provided for @mockStatusOffer.
  ///
  /// In en, this message translates to:
  /// **'OFFER 🎉'**
  String get mockStatusOffer;

  /// No description provided for @mockStatusApplied.
  ///
  /// In en, this message translates to:
  /// **'91% MATCH'**
  String get mockStatusApplied;

  /// No description provided for @mockOnTrack.
  ///
  /// In en, this message translates to:
  /// **'ON TRACK'**
  String get mockOnTrack;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

  /// No description provided for @signInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue building your Career DNA.'**
  String get signInBody;

  /// No description provided for @signUpBody.
  ///
  /// In en, this message translates to:
  /// **'Start with your basics — we will never publish anything.'**
  String get signUpBody;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @continueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueApple;

  /// No description provided for @orContinueEmail.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH EMAIL'**
  String get orContinueEmail;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'FORGOT?'**
  String get forgotPassword;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get passwordHint;

  /// No description provided for @passwordHintSignUp.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get passwordHintSignUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccountShort.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountShort;

  /// No description provided for @newToNexora.
  ///
  /// In en, this message translates to:
  /// **'New to Nexora? Create an account'**
  String get newToNexora;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @termsNote.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the Terms of Service and Privacy Policy.'**
  String get termsNote;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Al-Rashidi'**
  String get nameHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifySentCode.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to\n{email}'**
  String verifySentCode(String email);

  /// No description provided for @verifyDidntGet.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it? '**
  String get verifyDidntGet;

  /// No description provided for @verifyResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in 0:{seconds}'**
  String verifyResendIn(int seconds);

  /// No description provided for @verifyResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get verifyResend;

  /// No description provided for @verifyCta.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCta;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @settingUpDna.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Setting up your Career DNA…'**
  String get settingUpDna;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDna.
  ///
  /// In en, this message translates to:
  /// **'DNA'**
  String get navDna;

  /// No description provided for @navAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get navAnalyze;

  /// No description provided for @navStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get navStudio;

  /// No description provided for @navTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get navTrack;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'☀️ Good morning'**
  String get homeGoodMorning;

  /// No description provided for @homeUserName.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Al-Rashidi'**
  String get homeUserName;

  /// No description provided for @homeHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Career DNA Health'**
  String get homeHealthTitle;

  /// No description provided for @homeOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get homeOnTrack;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfile;

  /// No description provided for @homeActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get homeActivity;

  /// No description provided for @homeMatchRate.
  ///
  /// In en, this message translates to:
  /// **'Match Rate'**
  String get homeMatchRate;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeAnalyzeJob.
  ///
  /// In en, this message translates to:
  /// **'Analyze Job'**
  String get homeAnalyzeJob;

  /// No description provided for @homeMatchGaps.
  ///
  /// In en, this message translates to:
  /// **'Match & gaps'**
  String get homeMatchGaps;

  /// No description provided for @homeCreateCv.
  ///
  /// In en, this message translates to:
  /// **'Create CV'**
  String get homeCreateCv;

  /// No description provided for @homeAiPowered.
  ///
  /// In en, this message translates to:
  /// **'AI-powered'**
  String get homeAiPowered;

  /// No description provided for @homePractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get homePractice;

  /// No description provided for @homeAiInterview.
  ///
  /// In en, this message translates to:
  /// **'AI interview'**
  String get homeAiInterview;

  /// No description provided for @homeTrackApps.
  ///
  /// In en, this message translates to:
  /// **'Track Apps'**
  String get homeTrackApps;

  /// No description provided for @homeActiveCount.
  ///
  /// In en, this message translates to:
  /// **'6 active'**
  String get homeActiveCount;

  /// No description provided for @homeRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get homeRecentActivity;

  /// No description provided for @activityMatch.
  ///
  /// In en, this message translates to:
  /// **'New 91% match for Google Flutter role'**
  String get activityMatch;

  /// No description provided for @activityCvOptimized.
  ///
  /// In en, this message translates to:
  /// **'CV optimized · +3 ATS points (89→92)'**
  String get activityCvOptimized;

  /// No description provided for @activityPractice.
  ///
  /// In en, this message translates to:
  /// **'Interview practice · HR round · Score 78%'**
  String get activityPractice;

  /// No description provided for @home2hAgo.
  ///
  /// In en, this message translates to:
  /// **'2h ago'**
  String get home2hAgo;

  /// No description provided for @homeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get homeYesterday;

  /// No description provided for @home2dAgo.
  ///
  /// In en, this message translates to:
  /// **'2d ago'**
  String get home2dAgo;

  /// No description provided for @homeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get homeUpcoming;

  /// No description provided for @homeUpcomingDetail.
  ///
  /// In en, this message translates to:
  /// **'Interview · Tomorrow 3:00 PM'**
  String get homeUpcomingDetail;

  /// No description provided for @dnaScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Career DNA'**
  String get dnaScreenTitle;

  /// No description provided for @dnaAiInterview.
  ///
  /// In en, this message translates to:
  /// **'AI Interview'**
  String get dnaAiInterview;

  /// No description provided for @dnaCompleteness.
  ///
  /// In en, this message translates to:
  /// **'Completeness'**
  String get dnaCompleteness;

  /// No description provided for @dnaSectionsNeedWork.
  ///
  /// In en, this message translates to:
  /// **'2 Sections Need Work'**
  String get dnaSectionsNeedWork;

  /// No description provided for @dnaAchievementsExp.
  ///
  /// In en, this message translates to:
  /// **'Achievements · 62%\nExperience · 80%'**
  String get dnaAchievementsExp;

  /// No description provided for @dnaTarget95.
  ///
  /// In en, this message translates to:
  /// **'82% · Target 95%'**
  String get dnaTarget95;

  /// No description provided for @dnaEvidenceLead.
  ///
  /// In en, this message translates to:
  /// **'Your profile is '**
  String get dnaEvidenceLead;

  /// No description provided for @dnaEvidenceAccent.
  ///
  /// In en, this message translates to:
  /// **'evidence-based'**
  String get dnaEvidenceAccent;

  /// No description provided for @dnaEvidenceTail.
  ///
  /// In en, this message translates to:
  /// **' — the AI will never fabricate experience or skills. Only verified claims are used.'**
  String get dnaEvidenceTail;

  /// No description provided for @dnaProfileSections.
  ///
  /// In en, this message translates to:
  /// **'PROFILE SECTIONS'**
  String get dnaProfileSections;

  /// No description provided for @dnaPersonalProfile.
  ///
  /// In en, this message translates to:
  /// **'Personal Profile'**
  String get dnaPersonalProfile;

  /// No description provided for @dnaEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get dnaEducation;

  /// No description provided for @dnaExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get dnaExperience;

  /// No description provided for @dnaProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get dnaProjects;

  /// No description provided for @dnaSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get dnaSkills;

  /// No description provided for @dnaCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get dnaCertifications;

  /// No description provided for @dnaAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get dnaAchievements;

  /// No description provided for @dnaLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get dnaLanguages;

  /// No description provided for @dnaAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add Volunteering · Publications · Courses'**
  String get dnaAddMore;

  /// No description provided for @dnaVisualLabel.
  ///
  /// In en, this message translates to:
  /// **'CAREER DNA'**
  String get dnaVisualLabel;

  /// No description provided for @dnaVisualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your professional identity'**
  String get dnaVisualSubtitle;

  /// No description provided for @analyzeTitle.
  ///
  /// In en, this message translates to:
  /// **'Opportunity'**
  String get analyzeTitle;

  /// No description provided for @analyzeMyAnalyses.
  ///
  /// In en, this message translates to:
  /// **'My Analyses'**
  String get analyzeMyAnalyses;

  /// No description provided for @analyzeNewAnalysis.
  ///
  /// In en, this message translates to:
  /// **'New Analysis'**
  String get analyzeNewAnalysis;

  /// No description provided for @analyzeOverallMatch.
  ///
  /// In en, this message translates to:
  /// **'Overall Match'**
  String get analyzeOverallMatch;

  /// No description provided for @analyzeSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get analyzeSkills;

  /// No description provided for @analyzeExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get analyzeExperience;

  /// No description provided for @analyzeEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get analyzeEducation;

  /// No description provided for @analyzeKeywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get analyzeKeywords;

  /// No description provided for @analyzeStrongMatches.
  ///
  /// In en, this message translates to:
  /// **'Strong Matches ✓'**
  String get analyzeStrongMatches;

  /// No description provided for @analyzeMissingSkills.
  ///
  /// In en, this message translates to:
  /// **'Missing Skills ✗'**
  String get analyzeMissingSkills;

  /// No description provided for @analyzeWeakEvidence.
  ///
  /// In en, this message translates to:
  /// **'Weak Evidence'**
  String get analyzeWeakEvidence;

  /// No description provided for @analyzeAiRecommendation.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendation'**
  String get analyzeAiRecommendation;

  /// No description provided for @analyzeAllCovered.
  ///
  /// In en, this message translates to:
  /// **'All required skills are covered ✓'**
  String get analyzeAllCovered;

  /// No description provided for @analyzeAllBacked.
  ///
  /// In en, this message translates to:
  /// **'No weak evidence — every required skill is backed by a verified claim in your Career DNA.'**
  String get analyzeAllBacked;

  /// No description provided for @analyzeMissingEvidence.
  ///
  /// In en, this message translates to:
  /// **'is referenced in your Career DNA but lacks concrete project evidence to support it confidently.'**
  String get analyzeMissingEvidence;

  /// No description provided for @analyzeIntro.
  ///
  /// In en, this message translates to:
  /// **'Paste a job description, scholarship, or university program. The AI will extract requirements and match them against your Career DNA.'**
  String get analyzeIntro;

  /// No description provided for @analyzeHint.
  ///
  /// In en, this message translates to:
  /// **'Paste job description, internship listing, or program requirements here…'**
  String get analyzeHint;

  /// No description provided for @analyzeYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Your experience'**
  String get analyzeYourExperience;

  /// No description provided for @analyzeHighestEducation.
  ///
  /// In en, this message translates to:
  /// **'Highest education'**
  String get analyzeHighestEducation;

  /// No description provided for @analyzeYearsHint.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get analyzeYearsHint;

  /// No description provided for @analyzeWithAi.
  ///
  /// In en, this message translates to:
  /// **'Analyze with AI'**
  String get analyzeWithAi;

  /// No description provided for @analyzeAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get analyzeAnalyzing;

  /// No description provided for @analyzeRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove analysis'**
  String get analyzeRemoveTooltip;

  /// No description provided for @analyzePasteFirst.
  ///
  /// In en, this message translates to:
  /// **'Paste a job description first'**
  String get analyzePasteFirst;

  /// No description provided for @analyzeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Analysis removed'**
  String get analyzeRemoved;

  /// No description provided for @analyzeReady.
  ///
  /// In en, this message translates to:
  /// **'Analysis ready - match score {score}%'**
  String analyzeReady(int score);

  /// No description provided for @analyzeTypeFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time Job'**
  String get analyzeTypeFullTime;

  /// No description provided for @analyzeTypeInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get analyzeTypeInternship;

  /// No description provided for @analyzeTypeMasters.
  ///
  /// In en, this message translates to:
  /// **'Master\'s'**
  String get analyzeTypeMasters;

  /// No description provided for @analyzeTypeScholarship.
  ///
  /// In en, this message translates to:
  /// **'Scholarship'**
  String get analyzeTypeScholarship;

  /// No description provided for @analyzeEduHighSchool.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get analyzeEduHighSchool;

  /// No description provided for @analyzeEduBachelor.
  ///
  /// In en, this message translates to:
  /// **'Bachelor'**
  String get analyzeEduBachelor;

  /// No description provided for @analyzeEduMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get analyzeEduMaster;

  /// No description provided for @analyzeEduPhd.
  ///
  /// In en, this message translates to:
  /// **'PhD'**
  String get analyzeEduPhd;

  /// No description provided for @studioTitle.
  ///
  /// In en, this message translates to:
  /// **'CV Studio'**
  String get studioTitle;

  /// No description provided for @studioNewCv.
  ///
  /// In en, this message translates to:
  /// **'New CV'**
  String get studioNewCv;

  /// No description provided for @studioMyCvs.
  ///
  /// In en, this message translates to:
  /// **'My CVs'**
  String get studioMyCvs;

  /// No description provided for @studioPurposeJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get studioPurposeJob;

  /// No description provided for @studioPurposeAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get studioPurposeAcademic;

  /// No description provided for @studioUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String studioUpdated(String date);

  /// No description provided for @studioAtsScore.
  ///
  /// In en, this message translates to:
  /// **'ATS SCORE'**
  String get studioAtsScore;

  /// No description provided for @studioAtsCompatibility.
  ///
  /// In en, this message translates to:
  /// **'ATS Compatibility'**
  String get studioAtsCompatibility;

  /// No description provided for @studioPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get studioPreview;

  /// No description provided for @studioOptimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize'**
  String get studioOptimize;

  /// No description provided for @studioEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get studioEdit;

  /// No description provided for @studioBattle.
  ///
  /// In en, this message translates to:
  /// **'⚔ CV Battle'**
  String get studioBattle;

  /// No description provided for @studioBattleBody.
  ///
  /// In en, this message translates to:
  /// **'Compare versions against a target role'**
  String get studioBattleBody;

  /// No description provided for @studioTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get studioTemplates;

  /// No description provided for @templateAtsMinimal.
  ///
  /// In en, this message translates to:
  /// **'ATS Minimal'**
  String get templateAtsMinimal;

  /// No description provided for @templateModernPro.
  ///
  /// In en, this message translates to:
  /// **'Modern Pro'**
  String get templateModernPro;

  /// No description provided for @templateAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get templateAcademic;

  /// No description provided for @templateTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get templateTech;

  /// No description provided for @templateExecutive.
  ///
  /// In en, this message translates to:
  /// **'Executive'**
  String get templateExecutive;

  /// No description provided for @trackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get trackerTitle;

  /// No description provided for @trackerTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get trackerTotal;

  /// No description provided for @trackerActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get trackerActive;

  /// No description provided for @trackerInterviews.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get trackerInterviews;

  /// No description provided for @trackerOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get trackerOffers;

  /// No description provided for @trackerPipeline.
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get trackerPipeline;

  /// No description provided for @trackerApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get trackerApplied;

  /// No description provided for @trackerReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get trackerReview;

  /// No description provided for @trackerInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get trackerInterview;

  /// No description provided for @trackerOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get trackerOffer;

  /// No description provided for @trackerActiveSection.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get trackerActiveSection;

  /// No description provided for @trackerCompletedSection.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trackerCompletedSection;

  /// No description provided for @trackerStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get trackerStatusUnderReview;

  /// No description provided for @trackerStatusAssessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get trackerStatusAssessment;

  /// No description provided for @trackerStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get trackerStatusRejected;

  /// No description provided for @trackerMatchPct.
  ///
  /// In en, this message translates to:
  /// **'{match}% match'**
  String trackerMatchPct(int match);

  /// No description provided for @trackerAts.
  ///
  /// In en, this message translates to:
  /// **'ATS {ats}'**
  String trackerAts(int ats);

  /// No description provided for @sbStepEnjoy.
  ///
  /// In en, this message translates to:
  /// **'What do you enjoy?'**
  String get sbStepEnjoy;

  /// No description provided for @sbStepAim.
  ///
  /// In en, this message translates to:
  /// **'What are you aiming for?'**
  String get sbStepAim;

  /// No description provided for @sbStepAbout.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about you'**
  String get sbStepAbout;

  /// No description provided for @sbStepDna.
  ///
  /// In en, this message translates to:
  /// **'Your Career DNA'**
  String get sbStepDna;

  /// No description provided for @sbSubEnjoy.
  ///
  /// In en, this message translates to:
  /// **'Pick everything that sounds like you. No wrong answers.'**
  String get sbSubEnjoy;

  /// No description provided for @sbSubAim.
  ///
  /// In en, this message translates to:
  /// **'This shapes how Nexora presents you.'**
  String get sbSubAim;

  /// No description provided for @sbSubAbout.
  ///
  /// In en, this message translates to:
  /// **'Optional — one line helps us personalize it.'**
  String get sbSubAbout;

  /// No description provided for @sbSubDna.
  ///
  /// In en, this message translates to:
  /// **'Review the draft, remove what doesn\'t fit, then save.'**
  String get sbSubDna;

  /// No description provided for @sbAddOwn.
  ///
  /// In en, this message translates to:
  /// **'Something else? Add your own:'**
  String get sbAddOwn;

  /// No description provided for @sbCustomHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Robotics, Nursing, Game Dev…'**
  String get sbCustomHint;

  /// No description provided for @sbSentenceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I love training and being part of a team…'**
  String get sbSentenceHint;

  /// No description provided for @sbInspiration.
  ///
  /// In en, this message translates to:
  /// **'Need inspiration? Tap one:'**
  String get sbInspiration;

  /// No description provided for @sbDraftedBy.
  ///
  /// In en, this message translates to:
  /// **'Drafted by Nexora — edit anything, then save.'**
  String get sbDraftedBy;

  /// No description provided for @sbSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get sbSummary;

  /// No description provided for @sbSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get sbSkills;

  /// No description provided for @sbExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get sbExperience;

  /// No description provided for @sbProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get sbProjects;

  /// No description provided for @sbEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get sbEducation;

  /// No description provided for @sbCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get sbCertifications;

  /// No description provided for @sbAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get sbAchievements;

  /// No description provided for @sbLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get sbLanguages;

  /// No description provided for @sbAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get sbAdd;

  /// No description provided for @sbPlaceholderRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get sbPlaceholderRole;

  /// No description provided for @sbPlaceholderProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get sbPlaceholderProject;

  /// No description provided for @sbPlaceholderDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get sbPlaceholderDegree;

  /// No description provided for @sbDrafting.
  ///
  /// In en, this message translates to:
  /// **'Drafting your Career DNA'**
  String get sbDrafting;

  /// No description provided for @sbDraftingSub.
  ///
  /// In en, this message translates to:
  /// **'Nexora is turning your taps into a full profile.'**
  String get sbDraftingSub;

  /// No description provided for @sbReady.
  ///
  /// In en, this message translates to:
  /// **'Your Career DNA is ready'**
  String get sbReady;

  /// No description provided for @sbReadySub.
  ///
  /// In en, this message translates to:
  /// **'We drafted your whole profile from a few taps. Here\'s where to take it next.'**
  String get sbReadySub;

  /// No description provided for @sbNextAnalyze.
  ///
  /// In en, this message translates to:
  /// **'See your match score'**
  String get sbNextAnalyze;

  /// No description provided for @sbNextAnalyzeSub.
  ///
  /// In en, this message translates to:
  /// **'Run Analyze on a job you like'**
  String get sbNextAnalyzeSub;

  /// No description provided for @sbNextCv.
  ///
  /// In en, this message translates to:
  /// **'Build a CV'**
  String get sbNextCv;

  /// No description provided for @sbNextCvSub.
  ///
  /// In en, this message translates to:
  /// **'Turn this DNA into a CV in Studio'**
  String get sbNextCvSub;

  /// No description provided for @sbNextExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore your DNA'**
  String get sbNextExplore;

  /// No description provided for @sbNextExploreSub.
  ///
  /// In en, this message translates to:
  /// **'Review and tweak what we drafted'**
  String get sbNextExploreSub;

  /// No description provided for @sbIntProgramming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get sbIntProgramming;

  /// No description provided for @sbIntDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get sbIntDesign;

  /// No description provided for @sbIntWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get sbIntWriting;

  /// No description provided for @sbIntData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get sbIntData;

  /// No description provided for @sbIntMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get sbIntMarketing;

  /// No description provided for @sbIntTeaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get sbIntTeaching;

  /// No description provided for @sbIntBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get sbIntBusiness;

  /// No description provided for @sbIntEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get sbIntEngineering;

  /// No description provided for @sbIntMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get sbIntMedicine;

  /// No description provided for @sbIntLaw.
  ///
  /// In en, this message translates to:
  /// **'Law'**
  String get sbIntLaw;

  /// No description provided for @sbIntFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get sbIntFinance;

  /// No description provided for @sbIntPsychology.
  ///
  /// In en, this message translates to:
  /// **'Psychology'**
  String get sbIntPsychology;

  /// No description provided for @sbIntPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get sbIntPhotography;

  /// No description provided for @sbIntMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get sbIntMusic;

  /// No description provided for @sbIntSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sbIntSports;

  /// No description provided for @sbIntHospitality.
  ///
  /// In en, this message translates to:
  /// **'Hospitality'**
  String get sbIntHospitality;

  /// No description provided for @sbIntAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get sbIntAgriculture;

  /// No description provided for @sbIntScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get sbIntScience;

  /// No description provided for @sbIntSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sbIntSales;

  /// No description provided for @sbGoalInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get sbGoalInternship;

  /// No description provided for @sbGoalScholarship.
  ///
  /// In en, this message translates to:
  /// **'Scholarship'**
  String get sbGoalScholarship;

  /// No description provided for @sbGoalJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get sbGoalJob;

  /// No description provided for @sbGoalFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get sbGoalFreelance;

  /// No description provided for @dnaTitle.
  ///
  /// In en, this message translates to:
  /// **'Career DNA'**
  String get dnaTitle;

  /// No description provided for @dnaEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get dnaEditProfile;

  /// No description provided for @dnaBuildNexora.
  ///
  /// In en, this message translates to:
  /// **'Build with Nexora'**
  String get dnaBuildNexora;

  /// No description provided for @dnaBuildNexoraSubEmpty.
  ///
  /// In en, this message translates to:
  /// **'No CV yet? Answer a few taps and we draft your profile.'**
  String get dnaBuildNexoraSubEmpty;

  /// No description provided for @dnaRefineNexora.
  ///
  /// In en, this message translates to:
  /// **'Refine with Nexora'**
  String get dnaRefineNexora;

  /// No description provided for @dnaRefineSub.
  ///
  /// In en, this message translates to:
  /// **'Polish your Career DNA with AI — a few quick taps.'**
  String get dnaRefineSub;

  /// No description provided for @dnaEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Career DNA is empty'**
  String get dnaEmptyTitle;

  /// No description provided for @dnaEmptySub.
  ///
  /// In en, this message translates to:
  /// **'No CV yet? Answer a few quick taps and Nexora drafts your whole profile — skills, experience, projects and more.'**
  String get dnaEmptySub;

  /// No description provided for @sbDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sbDone;

  /// No description provided for @sbContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get sbContinue;

  /// No description provided for @sbDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft my DNA'**
  String get sbDraft;

  /// No description provided for @sbSaveDna.
  ///
  /// In en, this message translates to:
  /// **'Save to my DNA'**
  String get sbSaveDna;

  /// No description provided for @dnaSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get dnaSave;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'☀️ Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'🌤️ Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'🌙 Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeDnaHealth.
  ///
  /// In en, this message translates to:
  /// **'Career DNA Health'**
  String get homeDnaHealth;

  /// No description provided for @homeSixActive.
  ///
  /// In en, this message translates to:
  /// **'6 active'**
  String get homeSixActive;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI Interview — coming soon'**
  String get homeComingSoon;

  /// No description provided for @analyzeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No analyses yet'**
  String get analyzeEmptyTitle;

  /// No description provided for @analyzeEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Run a new analysis to see your match here.'**
  String get analyzeEmptySub;

  /// No description provided for @studioCvBattle.
  ///
  /// In en, this message translates to:
  /// **'⚔ CV Battle'**
  String get studioCvBattle;

  /// No description provided for @studioCvBattleHint.
  ///
  /// In en, this message translates to:
  /// **'Compare versions against a target role'**
  String get studioCvBattleHint;

  /// No description provided for @studioAtsCompat.
  ///
  /// In en, this message translates to:
  /// **'ATS Compatibility'**
  String get studioAtsCompat;

  /// No description provided for @studioCreateNewCv.
  ///
  /// In en, this message translates to:
  /// **'Create a new CV'**
  String get studioCreateNewCv;

  /// No description provided for @studioNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name it after the role or opportunity you are targeting.'**
  String get studioNameHint;

  /// No description provided for @studioCvTitleHint.
  ///
  /// In en, this message translates to:
  /// **'CV title (e.g. Senior Flutter Engineer)'**
  String get studioCvTitleHint;

  /// No description provided for @studioPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get studioPurpose;

  /// No description provided for @studioCreateCvBtn.
  ///
  /// In en, this message translates to:
  /// **'Create CV'**
  String get studioCreateCvBtn;

  /// No description provided for @studioRenameCv.
  ///
  /// In en, this message translates to:
  /// **'Rename CV'**
  String get studioRenameCv;

  /// No description provided for @studioCvTitle.
  ///
  /// In en, this message translates to:
  /// **'CV title'**
  String get studioCvTitle;

  /// No description provided for @studioCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get studioCancel;

  /// No description provided for @studioSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get studioSave;

  /// No description provided for @studioClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get studioClose;

  /// No description provided for @studioDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get studioDone;

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @studioOptimizing.
  ///
  /// In en, this message translates to:
  /// **'Optimizing…'**
  String get studioOptimizing;

  /// No description provided for @studioOptimizationComplete.
  ///
  /// In en, this message translates to:
  /// **'Optimization complete'**
  String get studioOptimizationComplete;

  /// No description provided for @studioAtsRaised.
  ///
  /// In en, this message translates to:
  /// **'ATS score raised from'**
  String get studioAtsRaised;

  /// No description provided for @studioAtsTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get studioAtsTo;

  /// No description provided for @studioPurposeInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get studioPurposeInternship;

  /// No description provided for @studioCvBattleSoon.
  ///
  /// In en, this message translates to:
  /// **'CV Battle — coming soon'**
  String get studioCvBattleSoon;

  /// No description provided for @studioTemplateSelected.
  ///
  /// In en, this message translates to:
  /// **'Template · {name} selected'**
  String studioTemplateSelected(String name);

  /// No description provided for @studioCreatedSnack.
  ///
  /// In en, this message translates to:
  /// **'{title} created'**
  String studioCreatedSnack(String title);

  /// No description provided for @studioOptimizedSnack.
  ///
  /// In en, this message translates to:
  /// **'Optimized — ATS {ats}%'**
  String studioOptimizedSnack(int ats);

  /// No description provided for @studioSummary.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY'**
  String get studioSummary;

  /// No description provided for @studioExperience.
  ///
  /// In en, this message translates to:
  /// **'EXPERIENCE'**
  String get studioExperience;

  /// No description provided for @trackerCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trackerCompleted;

  /// No description provided for @trackerStatusApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get trackerStatusApplied;

  /// No description provided for @trackerStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get trackerStatusReview;

  /// No description provided for @trackerStatusInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get trackerStatusInterview;

  /// No description provided for @trackerStatusOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer 🎉'**
  String get trackerStatusOffer;

  /// No description provided for @trackerAddApp.
  ///
  /// In en, this message translates to:
  /// **'Add Application'**
  String get trackerAddApp;

  /// No description provided for @trackerAddAppSub.
  ///
  /// In en, this message translates to:
  /// **'Track a role you applied for or plan to target.'**
  String get trackerAddAppSub;

  /// No description provided for @trackerCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get trackerCompany;

  /// No description provided for @trackerRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get trackerRole;

  /// No description provided for @trackerStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get trackerStatus;

  /// No description provided for @trackerCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current status'**
  String get trackerCurrentStatus;

  /// No description provided for @trackerMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to'**
  String get trackerMoveTo;

  /// No description provided for @trackerAddAppBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Application'**
  String get trackerAddAppBtn;

  /// No description provided for @trackerAdded.
  ///
  /// In en, this message translates to:
  /// **'added'**
  String get trackerAdded;

  /// No description provided for @trackerRemoved.
  ///
  /// In en, this message translates to:
  /// **'Application removed'**
  String get trackerRemoved;

  /// No description provided for @trackerMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved to'**
  String get trackerMovedTo;

  /// No description provided for @trackerCompanyAdded.
  ///
  /// In en, this message translates to:
  /// **'{company} added'**
  String trackerCompanyAdded(String company);

  /// No description provided for @trackerDeleteApplication.
  ///
  /// In en, this message translates to:
  /// **'Delete application'**
  String get trackerDeleteApplication;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authSignInSub.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue building your Career DNA.'**
  String get authSignInSub;

  /// No description provided for @authCreateSub.
  ///
  /// In en, this message translates to:
  /// **'Start with your basics — we will never publish anything.'**
  String get authCreateSub;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueApple;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullName;

  /// No description provided for @authFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Al-Rashidi'**
  String get authFullNameHint;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authForgot.
  ///
  /// In en, this message translates to:
  /// **'FORGOT?'**
  String get authForgot;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get authPasswordHint;

  /// No description provided for @authPasswordHintNew.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get authPasswordHintNew;

  /// No description provided for @authSignInBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInBtn;

  /// No description provided for @authCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateBtn;

  /// No description provided for @authNewToNexora.
  ///
  /// In en, this message translates to:
  /// **'New to Nexora? Create an account'**
  String get authNewToNexora;

  /// No description provided for @authAlreadyHave.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authAlreadyHave;

  /// No description provided for @authTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the Terms of Service and Privacy Policy.'**
  String get authTerms;

  /// No description provided for @authOrEmail.
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH EMAIL'**
  String get authOrEmail;

  /// No description provided for @welcomeCareer.
  ///
  /// In en, this message translates to:
  /// **'Your Career\n'**
  String get welcomeCareer;

  /// No description provided for @welcomeUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Understood.\n'**
  String get welcomeUnderstood;

  /// No description provided for @welcomeElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated.'**
  String get welcomeElevated;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered career intelligence that understands who you are, what you want, and how to get you there.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomePrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'100% Private'**
  String get welcomePrivateTitle;

  /// No description provided for @welcomePrivateSub.
  ///
  /// In en, this message translates to:
  /// **'Your data is secure\nand encrypted'**
  String get welcomePrivateSub;

  /// No description provided for @welcomeAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered'**
  String get welcomeAiTitle;

  /// No description provided for @welcomeAiSub.
  ///
  /// In en, this message translates to:
  /// **'Smart insights that\nsave you time'**
  String get welcomeAiSub;

  /// No description provided for @welcomeResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results-Driven'**
  String get welcomeResultsTitle;

  /// No description provided for @welcomeResultsSub.
  ///
  /// In en, this message translates to:
  /// **'Get more interviews\nand opportunities'**
  String get welcomeResultsSub;

  /// No description provided for @welcomeMatchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Matching'**
  String get welcomeMatchingTitle;

  /// No description provided for @welcomeMatchingSub.
  ///
  /// In en, this message translates to:
  /// **'Find opportunities that\ntruly fit you.'**
  String get welcomeMatchingSub;

  /// No description provided for @welcomeAtsTitle.
  ///
  /// In en, this message translates to:
  /// **'ATS Optimization'**
  String get welcomeAtsTitle;

  /// No description provided for @welcomeAtsSub.
  ///
  /// In en, this message translates to:
  /// **'Beat the system with\nAI-powered insights.'**
  String get welcomeAtsSub;

  /// No description provided for @welcomeInterviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Interview Ready'**
  String get welcomeInterviewTitle;

  /// No description provided for @welcomeInterviewSub.
  ///
  /// In en, this message translates to:
  /// **'Practice with AI and\nbuild your confidence.'**
  String get welcomeInterviewSub;

  /// No description provided for @welcomeGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'Career Growth'**
  String get welcomeGrowthTitle;

  /// No description provided for @welcomeGrowthSub.
  ///
  /// In en, this message translates to:
  /// **'Track progress and\nachieve your goals.'**
  String get welcomeGrowthSub;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeAlreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeAlreadyAccount;

  /// No description provided for @onbSlide1Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'01 · ANALYZE'**
  String get onbSlide1Eyebrow;

  /// No description provided for @onbSlide1Lead.
  ///
  /// In en, this message translates to:
  /// **'Know your match\n'**
  String get onbSlide1Lead;

  /// No description provided for @onbSlide1Accent.
  ///
  /// In en, this message translates to:
  /// **'before you apply.'**
  String get onbSlide1Accent;

  /// No description provided for @onbSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Paste any job, scholarship, or program. Nexora extracts the real requirements and scores them against your Career DNA.'**
  String get onbSlide1Body;

  /// No description provided for @onbSlide2Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'02 · BUILD'**
  String get onbSlide2Eyebrow;

  /// No description provided for @onbSlide2Lead.
  ///
  /// In en, this message translates to:
  /// **'CVs engineered\n'**
  String get onbSlide2Lead;

  /// No description provided for @onbSlide2Accent.
  ///
  /// In en, this message translates to:
  /// **'to beat the ATS.'**
  String get onbSlide2Accent;

  /// No description provided for @onbSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'The AI CV Studio scores every line against your target role — then rewrites it until the machines say yes.'**
  String get onbSlide2Body;

  /// No description provided for @onbSlide3Eyebrow.
  ///
  /// In en, this message translates to:
  /// **'03 · TRACK'**
  String get onbSlide3Eyebrow;

  /// No description provided for @onbSlide3Lead.
  ///
  /// In en, this message translates to:
  /// **'Own your entire\n'**
  String get onbSlide3Lead;

  /// No description provided for @onbSlide3Accent.
  ///
  /// In en, this message translates to:
  /// **'career pipeline.'**
  String get onbSlide3Accent;

  /// No description provided for @onbSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Applications, interviews and offers in one calm dashboard. Practice rounds and smart nudges keep you on target.'**
  String get onbSlide3Body;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbCreateDna.
  ///
  /// In en, this message translates to:
  /// **'Create my career DNA'**
  String get onbCreateDna;

  /// No description provided for @onbAlreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get onbAlreadyAccount;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get onbSkip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutConfirm;

  /// No description provided for @settingsSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be returned to the sign-in screen.'**
  String get settingsSignOutBody;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsSignOutError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign out. Please try again.'**
  String get settingsSignOutError;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @changeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this later.'**
  String get changeLater;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @intakeAboutYou.
  ///
  /// In en, this message translates to:
  /// **'One line about you'**
  String get intakeAboutYou;

  /// No description provided for @intakeAboutYouHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I love building apps and learning new tech'**
  String get intakeAboutYouHint;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @draftFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the AI. We used your answers instead.'**
  String get draftFailed;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you aiming for?'**
  String get goalTitle;

  /// No description provided for @goalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This shapes the guidance Nexora gives you.'**
  String get goalSubtitle;

  /// No description provided for @goal_job.
  ///
  /// In en, this message translates to:
  /// **'Get a job'**
  String get goal_job;

  /// No description provided for @goal_job_d.
  ///
  /// In en, this message translates to:
  /// **'Find roles that fit you'**
  String get goal_job_d;

  /// No description provided for @goal_cv.
  ///
  /// In en, this message translates to:
  /// **'Build a CV'**
  String get goal_cv;

  /// No description provided for @goal_cv_d.
  ///
  /// In en, this message translates to:
  /// **'A CV ready to send'**
  String get goal_cv_d;

  /// No description provided for @goal_internship.
  ///
  /// In en, this message translates to:
  /// **'Get an internship'**
  String get goal_internship;

  /// No description provided for @goal_internship_d.
  ///
  /// In en, this message translates to:
  /// **'Real experience before graduating'**
  String get goal_internship_d;

  /// No description provided for @goal_masters.
  ///
  /// In en, this message translates to:
  /// **'Pursue a master\'s'**
  String get goal_masters;

  /// No description provided for @goal_masters_d.
  ///
  /// In en, this message translates to:
  /// **'Strengthen your application'**
  String get goal_masters_d;

  /// No description provided for @goal_scholarship.
  ///
  /// In en, this message translates to:
  /// **'Win a scholarship'**
  String get goal_scholarship;

  /// No description provided for @goal_scholarship_d.
  ///
  /// In en, this message translates to:
  /// **'Stand out to committees'**
  String get goal_scholarship_d;

  /// No description provided for @goal_careerChange.
  ///
  /// In en, this message translates to:
  /// **'Change careers'**
  String get goal_careerChange;

  /// No description provided for @goal_careerChange_d.
  ///
  /// In en, this message translates to:
  /// **'Pivot into a new field'**
  String get goal_careerChange_d;

  /// No description provided for @goal_improve.
  ///
  /// In en, this message translates to:
  /// **'Improve my profile'**
  String get goal_improve;

  /// No description provided for @goal_improve_d.
  ///
  /// In en, this message translates to:
  /// **'Fill the gaps holding you back'**
  String get goal_improve_d;

  /// No description provided for @goal_unsure.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get goal_unsure;

  /// No description provided for @goal_unsure_d.
  ///
  /// In en, this message translates to:
  /// **'We\'ll help you explore'**
  String get goal_unsure_d;

  /// No description provided for @stageTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you in your journey?'**
  String get stageTitle;

  /// No description provided for @stageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tailor the questions to your stage.'**
  String get stageSubtitle;

  /// No description provided for @stage_student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get stage_student;

  /// No description provided for @stage_student_d.
  ///
  /// In en, this message translates to:
  /// **'Still in school or university'**
  String get stage_student_d;

  /// No description provided for @stage_freshGraduate.
  ///
  /// In en, this message translates to:
  /// **'Fresh graduate'**
  String get stage_freshGraduate;

  /// No description provided for @stage_freshGraduate_d.
  ///
  /// In en, this message translates to:
  /// **'Just finished your degree'**
  String get stage_freshGraduate_d;

  /// No description provided for @stage_earlyCareer.
  ///
  /// In en, this message translates to:
  /// **'Early career'**
  String get stage_earlyCareer;

  /// No description provided for @stage_earlyCareer_d.
  ///
  /// In en, this message translates to:
  /// **'A few years of experience'**
  String get stage_earlyCareer_d;

  /// No description provided for @stage_experienced.
  ///
  /// In en, this message translates to:
  /// **'Experienced'**
  String get stage_experienced;

  /// No description provided for @stage_experienced_d.
  ///
  /// In en, this message translates to:
  /// **'Solid track record'**
  String get stage_experienced_d;

  /// No description provided for @stage_careerChanger.
  ///
  /// In en, this message translates to:
  /// **'Career changer'**
  String get stage_careerChanger;

  /// No description provided for @stage_careerChanger_d.
  ///
  /// In en, this message translates to:
  /// **'Moving into a new field'**
  String get stage_careerChanger_d;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Which field are you targeting?'**
  String get fieldTitle;

  /// No description provided for @fieldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the area you want to build your career in.'**
  String get fieldSubtitle;

  /// No description provided for @field_programming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get field_programming;

  /// No description provided for @field_design.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get field_design;

  /// No description provided for @field_writing.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get field_writing;

  /// No description provided for @field_data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get field_data;

  /// No description provided for @field_marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get field_marketing;

  /// No description provided for @field_teaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get field_teaching;

  /// No description provided for @field_business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get field_business;

  /// No description provided for @field_engineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get field_engineering;

  /// No description provided for @field_medicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get field_medicine;

  /// No description provided for @field_law.
  ///
  /// In en, this message translates to:
  /// **'Law'**
  String get field_law;

  /// No description provided for @field_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get field_finance;

  /// No description provided for @field_psychology.
  ///
  /// In en, this message translates to:
  /// **'Psychology'**
  String get field_psychology;

  /// No description provided for @field_photography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get field_photography;

  /// No description provided for @field_music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get field_music;

  /// No description provided for @field_sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get field_sports;

  /// No description provided for @field_hospitality.
  ///
  /// In en, this message translates to:
  /// **'Hospitality'**
  String get field_hospitality;

  /// No description provided for @field_agriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get field_agriculture;

  /// No description provided for @field_science.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get field_science;

  /// No description provided for @field_sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get field_sales;

  /// No description provided for @field_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get field_other;

  /// No description provided for @intakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s build your Career DNA'**
  String get intakeTitle;

  /// No description provided for @intakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer what you can — you can refine everything later.'**
  String get intakeSubtitle;

  /// No description provided for @intakeProgress.
  ///
  /// In en, this message translates to:
  /// **'Completed {answered} of {total}'**
  String intakeProgress(int answered, int total);

  /// No description provided for @intakeTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get intakeTapHint;

  /// No description provided for @intakeTargetRole.
  ///
  /// In en, this message translates to:
  /// **'Target role'**
  String get intakeTargetRole;

  /// No description provided for @intakeTargetRoleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flutter Developer'**
  String get intakeTargetRoleHint;

  /// No description provided for @intakeTargetIndustry.
  ///
  /// In en, this message translates to:
  /// **'Target industry'**
  String get intakeTargetIndustry;

  /// No description provided for @intakeTargetIndustryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fintech'**
  String get intakeTargetIndustryHint;

  /// No description provided for @intakeNoExperience.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have experience yet'**
  String get intakeNoExperience;

  /// No description provided for @intakeAltEvidence.
  ///
  /// In en, this message translates to:
  /// **'What can you show instead?'**
  String get intakeAltEvidence;

  /// No description provided for @intakeSkills.
  ///
  /// In en, this message translates to:
  /// **'Your top skills'**
  String get intakeSkills;

  /// No description provided for @intakeSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'Comma separated, e.g. Flutter, Figma'**
  String get intakeSkillsHint;

  /// No description provided for @intakeEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get intakeEducation;

  /// No description provided for @intakeAddEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education'**
  String get intakeAddEducation;

  /// No description provided for @intakeDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get intakeDegree;

  /// No description provided for @intakeFieldStudy.
  ///
  /// In en, this message translates to:
  /// **'Field of study'**
  String get intakeFieldStudy;

  /// No description provided for @intakeExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get intakeExperience;

  /// No description provided for @intakeAddExperience.
  ///
  /// In en, this message translates to:
  /// **'Add experience'**
  String get intakeAddExperience;

  /// No description provided for @intakeProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get intakeProjects;

  /// No description provided for @intakeAddProject.
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get intakeAddProject;

  /// No description provided for @intakeProjectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get intakeProjectName;

  /// No description provided for @intakeProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'What did you build?'**
  String get intakeProjectDesc;

  /// No description provided for @intakeProjectTech.
  ///
  /// In en, this message translates to:
  /// **'Technologies'**
  String get intakeProjectTech;

  /// No description provided for @intakePlaceholderRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get intakePlaceholderRole;

  /// No description provided for @intakeCerts.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get intakeCerts;

  /// No description provided for @intakeAddCert.
  ///
  /// In en, this message translates to:
  /// **'Add certification'**
  String get intakeAddCert;

  /// No description provided for @intakeAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get intakeAchievements;

  /// No description provided for @intakeAddAchievement.
  ///
  /// In en, this message translates to:
  /// **'Add achievement'**
  String get intakeAddAchievement;

  /// No description provided for @intakeLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get intakeLanguages;

  /// No description provided for @intakeAddLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add language'**
  String get intakeAddLanguage;

  /// No description provided for @intakeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to AI interview'**
  String get intakeContinue;

  /// No description provided for @intakeEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Add at least a target role or some skills to continue.'**
  String get intakeEmptyError;

  /// No description provided for @intakeExpectedGraduation.
  ///
  /// In en, this message translates to:
  /// **'Expected graduation'**
  String get intakeExpectedGraduation;

  /// No description provided for @intakeCoursework.
  ///
  /// In en, this message translates to:
  /// **'Coursework'**
  String get intakeCoursework;

  /// No description provided for @intakeInternships.
  ///
  /// In en, this message translates to:
  /// **'Internships'**
  String get intakeInternships;

  /// No description provided for @intakeGraduationStatus.
  ///
  /// In en, this message translates to:
  /// **'Graduation status'**
  String get intakeGraduationStatus;

  /// No description provided for @intakeCurrentRole.
  ///
  /// In en, this message translates to:
  /// **'Current or recent role'**
  String get intakeCurrentRole;

  /// No description provided for @intakeCareerDirection.
  ///
  /// In en, this message translates to:
  /// **'Career direction'**
  String get intakeCareerDirection;

  /// No description provided for @intakeLeadership.
  ///
  /// In en, this message translates to:
  /// **'Leadership'**
  String get intakeLeadership;

  /// No description provided for @intakeMeasurableImpact.
  ///
  /// In en, this message translates to:
  /// **'Measurable impact'**
  String get intakeMeasurableImpact;

  /// No description provided for @intakeCareerProgression.
  ///
  /// In en, this message translates to:
  /// **'Career progression'**
  String get intakeCareerProgression;

  /// No description provided for @intakePreviousCareer.
  ///
  /// In en, this message translates to:
  /// **'Previous career field'**
  String get intakePreviousCareer;

  /// No description provided for @intakePreviousRole.
  ///
  /// In en, this message translates to:
  /// **'Previous role'**
  String get intakePreviousRole;

  /// No description provided for @intakeTransferableSkills.
  ///
  /// In en, this message translates to:
  /// **'Transferable skills'**
  String get intakeTransferableSkills;

  /// No description provided for @intakeReasonTransition.
  ///
  /// In en, this message translates to:
  /// **'Why are you changing careers?'**
  String get intakeReasonTransition;

  /// No description provided for @intakeCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get intakeCompany;

  /// No description provided for @intakeYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get intakeYears;

  /// No description provided for @intakeBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get intakeBack;

  /// No description provided for @intakeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get intakeSkip;

  /// No description provided for @intakeFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get intakeFinish;

  /// No description provided for @nextActionCompleteDna.
  ///
  /// In en, this message translates to:
  /// **'Complete your Career DNA'**
  String get nextActionCompleteDna;

  /// No description provided for @nextActionCompleteDnaSub.
  ///
  /// In en, this message translates to:
  /// **'Add your goal, experience or projects to unlock guidance.'**
  String get nextActionCompleteDnaSub;

  /// No description provided for @nextActionTargetRole.
  ///
  /// In en, this message translates to:
  /// **'Define your target role'**
  String get nextActionTargetRole;

  /// No description provided for @nextActionTargetRoleSub.
  ///
  /// In en, this message translates to:
  /// **'Tell us the role you\'re aiming for so we can tailor everything.'**
  String get nextActionTargetRoleSub;

  /// No description provided for @nextActionTransferable.
  ///
  /// In en, this message translates to:
  /// **'Highlight your transferable skills'**
  String get nextActionTransferable;

  /// No description provided for @nextActionTransferableSub.
  ///
  /// In en, this message translates to:
  /// **'Show how your past experience applies to your new field.'**
  String get nextActionTransferableSub;

  /// No description provided for @nextActionRefine.
  ///
  /// In en, this message translates to:
  /// **'Refine your Career DNA'**
  String get nextActionRefine;

  /// No description provided for @nextActionRefineSub.
  ///
  /// In en, this message translates to:
  /// **'Polish weak spots — a few quick taps with AI.'**
  String get nextActionRefineSub;

  /// No description provided for @interviewTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Career Interview'**
  String get interviewTitle;

  /// No description provided for @interviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions, then we draft your profile.'**
  String get interviewSubtitle;

  /// No description provided for @interviewThinking.
  ///
  /// In en, this message translates to:
  /// **'Nexora is drafting your profile…'**
  String get interviewThinking;

  /// No description provided for @interviewDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is drafted'**
  String get interviewDoneTitle;

  /// No description provided for @interviewDoneSub.
  ///
  /// In en, this message translates to:
  /// **'Review it and continue to your Career DNA.'**
  String get interviewDoneSub;

  /// No description provided for @interviewContinue.
  ///
  /// In en, this message translates to:
  /// **'Review my Career DNA'**
  String get interviewContinue;

  /// No description provided for @interviewFallback.
  ///
  /// In en, this message translates to:
  /// **'AI is unavailable — we built a draft from your answers.'**
  String get interviewFallback;

  /// No description provided for @interviewStart.
  ///
  /// In en, this message translates to:
  /// **'Start interview'**
  String get interviewStart;

  /// No description provided for @interviewQ1.
  ///
  /// In en, this message translates to:
  /// **'In a few sentences, tell us about yourself and what you\'ve done.'**
  String get interviewQ1;

  /// No description provided for @interviewQ2.
  ///
  /// In en, this message translates to:
  /// **'What are you most proud of building or achieving?'**
  String get interviewQ2;

  /// No description provided for @interviewQ3.
  ///
  /// In en, this message translates to:
  /// **'What kind of opportunities are you looking for?'**
  String get interviewQ3;

  /// No description provided for @interviewGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating your profile'**
  String get interviewGenerating;

  /// No description provided for @interviewNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get interviewNext;

  /// No description provided for @dnaReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Career DNA'**
  String get dnaReviewTitle;

  /// No description provided for @dnaReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review what we built. Edit anything, then save.'**
  String get dnaReviewSubtitle;

  /// No description provided for @dnaIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Career Direction'**
  String get dnaIdentityTitle;

  /// No description provided for @dnaSaveEnter.
  ///
  /// In en, this message translates to:
  /// **'Save & enter Nexora'**
  String get dnaSaveEnter;

  /// No description provided for @dnaSaved.
  ///
  /// In en, this message translates to:
  /// **'Career DNA saved'**
  String get dnaSaved;

  /// No description provided for @dnaEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dnaEdit;

  /// No description provided for @dnaTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get dnaTarget;

  /// No description provided for @dnaSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get dnaSummary;

  /// No description provided for @dnaNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added yet'**
  String get dnaNotAdded;

  /// No description provided for @dnaScoreFormat.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String dnaScoreFormat(int percent);

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send a reset link.'**
  String get resetPasswordBody;

  /// No description provided for @resetPasswordSend.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get resetPasswordSend;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If that email exists, a reset link is on its way.'**
  String get resetPasswordSent;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
