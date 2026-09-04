// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nexora — Career Intelligence';

  @override
  String get brandSubtitle => 'CAREER INTELLIGENCE';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'العربية';

  @override
  String get welcomeEyebrow => 'Welcome to Nexora';

  @override
  String get welcomeTitleCareer => 'Your Career';

  @override
  String get welcomeTitleUnderstood => 'Understood.';

  @override
  String get welcomeTitleElevated => 'Elevated.';

  @override
  String get welcomeBody =>
      'AI-powered career intelligence that understands who you are, what you want, and how to get you there.';

  @override
  String get trustPrivateTitle => '100% Private';

  @override
  String get trustPrivateSubtitle => 'Your data is secure\nand encrypted';

  @override
  String get trustAiTitle => 'AI-Powered';

  @override
  String get trustAiSubtitle => 'Smart insights that\nsave you time';

  @override
  String get trustResultsTitle => 'Results-Driven';

  @override
  String get trustResultsSubtitle => 'Get more interviews\nand opportunities';

  @override
  String get featureMatchingTitle => 'Smart Matching';

  @override
  String get featureMatchingSubtitle =>
      'Find opportunities that\ntruly fit you.';

  @override
  String get featureAtsTitle => 'ATS Optimization';

  @override
  String get featureAtsSubtitle => 'Beat the system with\nAI-powered insights.';

  @override
  String get featureInterviewTitle => 'Interview Ready';

  @override
  String get featureInterviewSubtitle =>
      'Practice with AI and\nbuild your confidence.';

  @override
  String get featureGrowthTitle => 'Career Growth';

  @override
  String get featureGrowthSubtitle => 'Track progress and\nachieve your goals.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get privacySecure => 'Your data is private and secure.';

  @override
  String get privacyShare => 'We never share your information.';

  @override
  String get onboardingSkip => 'SKIP';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingCreateDna => 'Create my career DNA';

  @override
  String get onboardingSlide1Eyebrow => '01 · ANALYZE';

  @override
  String get onboardingSlide1TitleLead => 'Know your match\n';

  @override
  String get onboardingSlide1TitleAccent => 'before you apply.';

  @override
  String get onboardingSlide1Body =>
      'Paste any job, scholarship, or program. Nexora extracts the real requirements and scores them against your Career DNA.';

  @override
  String get onboardingSlide2Eyebrow => '02 · BUILD';

  @override
  String get onboardingSlide2TitleLead => 'CVs engineered\n';

  @override
  String get onboardingSlide2TitleAccent => 'to beat the ATS.';

  @override
  String get onboardingSlide2Body =>
      'The AI CV Studio scores every line against your target role — then rewrites it until the machines say yes.';

  @override
  String get onboardingSlide3Eyebrow => '03 · TRACK';

  @override
  String get onboardingSlide3TitleLead => 'Own your entire\n';

  @override
  String get onboardingSlide3TitleAccent => 'career pipeline.';

  @override
  String get onboardingSlide3Body =>
      'Applications, interviews and offers in one calm dashboard. Practice rounds and smart nudges keep you on target.';

  @override
  String get mockMatchBadge => '91% MATCH';

  @override
  String get mockOpportunityMatch => 'OPPORTUNITY MATCH';

  @override
  String get mockMatch => 'MATCH';

  @override
  String get mockStrong => 'Strong ✓';

  @override
  String get mockMissing => 'Missing ✗';

  @override
  String get mockSkills => 'SKILLS';

  @override
  String get mockExperience => 'EXPERIENCE';

  @override
  String get mockAtsScore => 'ATS SCORE';

  @override
  String get mockTop10 => 'TOP 10%';

  @override
  String get mockUpdatedToday => 'Updated today';

  @override
  String get mockAiRewrite => 'AI REWRITE ✓';

  @override
  String get mockOptimize => 'OPTIMIZE';

  @override
  String get mockApplications => 'APPLICATIONS';

  @override
  String get mockHrRound => 'HR ROUND';

  @override
  String get mockStatusInterview => 'Interview';

  @override
  String get mockStatusOffer => 'OFFER 🎉';

  @override
  String get mockStatusApplied => '91% MATCH';

  @override
  String get mockOnTrack => 'ON TRACK';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createAccountTitle => 'Create your account';

  @override
  String get signInBody => 'Sign in to continue building your Career DNA.';

  @override
  String get signUpBody =>
      'Start with your basics — we will never publish anything.';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get orContinueEmail => 'OR CONTINUE WITH EMAIL';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get forgotPassword => 'FORGOT?';

  @override
  String get passwordHint => 'Your password';

  @override
  String get passwordHintSignUp => 'Min. 8 characters';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccountShort => 'Create account';

  @override
  String get newToNexora => 'New to Nexora? Create an account';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get termsNote =>
      'By continuing you agree to the Terms of Service and Privacy Policy.';

  @override
  String get nameHint => 'Ahmed Al-Rashidi';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifySentCode(String email) {
    return 'We sent a 6-digit code to\n$email';
  }

  @override
  String get verifyDidntGet => 'Didn\'t get it? ';

  @override
  String verifyResendIn(int seconds) {
    return 'Resend in 0:$seconds';
  }

  @override
  String get verifyResend => 'Resend code';

  @override
  String get verifyCta => 'Verify';

  @override
  String get changeEmail => 'Change email';

  @override
  String get emailVerified => 'Email verified';

  @override
  String get settingUpDna =>
      'Your account is ready. Setting up your Career DNA…';

  @override
  String get navHome => 'Home';

  @override
  String get navDna => 'DNA';

  @override
  String get navAnalyze => 'Analyze';

  @override
  String get navStudio => 'Studio';

  @override
  String get navTrack => 'Track';

  @override
  String get homeGoodMorning => '☀️ Good morning';

  @override
  String get homeUserName => 'Ahmed Al-Rashidi';

  @override
  String get guestName => 'Guest';

  @override
  String get homeHealthTitle => 'Career DNA Health';

  @override
  String get homeOnTrack => 'On Track';

  @override
  String get homeProfile => 'Profile';

  @override
  String get homeActivity => 'Activity';

  @override
  String get homeMatchRate => 'Match Rate';

  @override
  String get homeQuickActions => 'Quick Actions';

  @override
  String get homeAnalyzeJob => 'Analyze Job';

  @override
  String get homeMatchGaps => 'Match & gaps';

  @override
  String get homeCreateCv => 'Create CV';

  @override
  String get homeAiPowered => 'AI-powered';

  @override
  String get homePractice => 'Practice';

  @override
  String get homeAiInterview => 'AI interview';

  @override
  String get homeTrackApps => 'Track Apps';

  @override
  String get homeActiveCount => '6 active';

  @override
  String get homeRecentActivity => 'Recent Activity';

  @override
  String get activityMatch => 'New 91% match for Google Flutter role';

  @override
  String get activityCvOptimized => 'CV optimized · +3 ATS points (89→92)';

  @override
  String get activityPractice => 'Interview practice · HR round · Score 78%';

  @override
  String get home2hAgo => '2h ago';

  @override
  String get homeYesterday => 'Yesterday';

  @override
  String get home2dAgo => '2d ago';

  @override
  String get homeUpcoming => 'Upcoming';

  @override
  String get homeUpcomingDetail => 'Interview · Tomorrow 3:00 PM';

  @override
  String get dnaScreenTitle => 'Career DNA';

  @override
  String get dnaAiInterview => 'AI Interview';

  @override
  String get dnaCompleteness => 'Completeness';

  @override
  String get dnaSectionsNeedWork => '2 Sections Need Work';

  @override
  String get dnaAchievementsExp => 'Achievements · 62%\nExperience · 80%';

  @override
  String get dnaTarget95 => '82% · Target 95%';

  @override
  String get dnaEvidenceLead => 'Your profile is ';

  @override
  String get dnaEvidenceAccent => 'evidence-based';

  @override
  String get dnaEvidenceTail =>
      ' — the AI will never fabricate experience or skills. Only verified claims are used.';

  @override
  String get dnaProfileSections => 'PROFILE SECTIONS';

  @override
  String get dnaPersonalProfile => 'Personal Profile';

  @override
  String get dnaPersonalProfileSubtitle => 'Identity & contact details';

  @override
  String get dnaIdentityComplete => '✓ Complete';

  @override
  String dnaIdentityMissing(int count) {
    return '⚠ $count items missing';
  }

  @override
  String get dnaEducation => 'Education';

  @override
  String get dnaExperience => 'Experience';

  @override
  String get dnaProjects => 'Projects';

  @override
  String get dnaSkills => 'Skills';

  @override
  String get dnaCertifications => 'Certifications';

  @override
  String get dnaAchievements => 'Achievements';

  @override
  String get dnaLanguages => 'Languages';

  @override
  String get dnaAddMore => 'Add Volunteering · Publications · Courses';

  @override
  String get dnaAllOnTrack => 'All on Track';

  @override
  String dnaSectionsNeedWorkCount(Object count, Object plural) {
    return '$count Section$plural Need Work';
  }

  @override
  String get dnaAddSection => 'Add a section';

  @override
  String get dnaAddSectionHint =>
      'Sections are evidence-based — you can attach proof later.';

  @override
  String get dnaAddSectionButton => 'Add Section';

  @override
  String get dnaSectionNameHint => 'Section name';

  @override
  String get dnaAlreadyComplete => 'Already Complete';

  @override
  String get dnaMarkComplete => 'Mark as Complete';

  @override
  String dnaSectionAdded(Object label) {
    return '$label added — DNA completeness updated';
  }

  @override
  String dnaSectionMarkedComplete(Object label) {
    return '$label marked complete';
  }

  @override
  String get dnaExperienceSaved => 'Experience saved — match scores updated';

  @override
  String dnaEditorSaved(Object title) {
    return '$title saved — match scores updated';
  }

  @override
  String dnaTargetFormat(Object percent) {
    return '$percent% · Target 95%';
  }

  @override
  String dnaSkillsEntries(Object count) {
    return 'Skills · $count entries';
  }

  @override
  String get dnaVolunteering => 'Volunteering';

  @override
  String get dnaPublications => 'Publications';

  @override
  String get dnaCourses => 'Courses';

  @override
  String get dnaSectionDetailComplete =>
      'Everything in this section is verified. Nice work!';

  @override
  String get dnaSectionDetailAddEvidence =>
      'Add evidence — upload a document, link, or certificate to bring this section up to 100%.';

  @override
  String get facetExperience => 'Experience';

  @override
  String get facetEducation => 'Education';

  @override
  String get facetDirection => 'Direction';

  @override
  String get micPermissionDenied =>
      'Microphone permission denied. Enable it in Settings → Apps → Nexora → Permissions.';

  @override
  String get dnaVisualLabel => 'CAREER DNA';

  @override
  String get dnaVisualSubtitle => 'Your professional identity';

  @override
  String get analyzeTitle => 'Opportunity';

  @override
  String get analyzeMyAnalyses => 'My Analyses';

  @override
  String get analyzeNewAnalysis => 'New Analysis';

  @override
  String get analyzeOverallMatch => 'Overall Match';

  @override
  String get analyzeSkills => 'Skills';

  @override
  String get analyzeExperience => 'Experience';

  @override
  String get analyzeEducation => 'Education';

  @override
  String get analyzeKeywords => 'Keywords';

  @override
  String get analyzeStrongMatches => 'Strong Matches ✓';

  @override
  String get analyzeMissingSkills => 'Missing Skills ✗';

  @override
  String get analyzeWeakEvidence => 'Weak Evidence';

  @override
  String get analyzeAiRecommendation => 'AI Recommendation';

  @override
  String get analyzeAllCovered => 'All required skills are covered ✓';

  @override
  String get analyzeAllBacked =>
      'No weak evidence — every required skill is backed by a verified claim in your Career DNA.';

  @override
  String get analyzeMissingEvidence =>
      'is referenced in your Career DNA but lacks concrete project evidence to support it confidently.';

  @override
  String get analyzeIntro =>
      'Paste a job description, scholarship, or university program. The AI will extract requirements and match them against your Career DNA.';

  @override
  String get analyzeHint =>
      'Paste job description, internship listing, or program requirements here…';

  @override
  String get analyzeYourExperience => 'Your experience';

  @override
  String get analyzeHighestEducation => 'Highest education';

  @override
  String get analyzeYearsHint => 'Years of experience';

  @override
  String get analyzeWithAi => 'Analyze with AI';

  @override
  String get analyzeAnalyzing => 'Analyzing…';

  @override
  String get analyzeRemoveTooltip => 'Remove analysis';

  @override
  String get analyzePasteFirst => 'Paste a job description first';

  @override
  String get analyzeRemoved => 'Analysis removed';

  @override
  String analyzeReady(int score) {
    return 'Analysis ready - match score $score%';
  }

  @override
  String get analyzeTypeFullTime => 'Full-time Job';

  @override
  String get analyzeTypeInternship => 'Internship';

  @override
  String get analyzeTypeMasters => 'Master\'s';

  @override
  String get analyzeTypeScholarship => 'Scholarship';

  @override
  String get analyzeEduHighSchool => 'High School';

  @override
  String get analyzeEduBachelor => 'Bachelor';

  @override
  String get analyzeEduMaster => 'Master';

  @override
  String get analyzeEduPhd => 'PhD';

  @override
  String get studioTitle => 'CV Studio';

  @override
  String get studioNewCv => 'New CV';

  @override
  String get studioMyCvs => 'My CVs';

  @override
  String get studioPurposeJob => 'Job';

  @override
  String get studioPurposeAcademic => 'Academic';

  @override
  String studioUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get studioAtsScore => 'ATS SCORE';

  @override
  String get studioAtsCompatibility => 'ATS Compatibility';

  @override
  String get studioPreview => 'Preview';

  @override
  String get studioOptimize => 'Optimize';

  @override
  String get studioEdit => 'Edit';

  @override
  String get studioBattle => '⚔ CV Battle';

  @override
  String get studioBattleBody => 'Compare versions against a target role';

  @override
  String get studioTemplates => 'Templates';

  @override
  String get templateAtsMinimal => 'ATS Minimal';

  @override
  String get templateModernPro => 'Modern Pro';

  @override
  String get templateAcademic => 'Academic';

  @override
  String get templateTech => 'Tech';

  @override
  String get templateExecutive => 'Executive';

  @override
  String get trackerTitle => 'Applications';

  @override
  String get trackerTotal => 'Total';

  @override
  String get trackerActive => 'Active';

  @override
  String get trackerInterviews => 'Interviews';

  @override
  String get trackerOffers => 'Offers';

  @override
  String get trackerPipeline => 'Pipeline';

  @override
  String get trackerApplied => 'Applied';

  @override
  String get trackerReview => 'Review';

  @override
  String get trackerInterview => 'Interview';

  @override
  String get trackerOffer => 'Offer';

  @override
  String get trackerActiveSection => 'Active';

  @override
  String get trackerCompletedSection => 'Completed';

  @override
  String get trackerStatusUnderReview => 'Under Review';

  @override
  String get trackerStatusAssessment => 'Assessment';

  @override
  String get trackerStatusRejected => 'Rejected';

  @override
  String trackerMatchPct(int match) {
    return '$match% match';
  }

  @override
  String trackerAts(int ats) {
    return 'ATS $ats';
  }

  @override
  String get sbStepEnjoy => 'What do you enjoy?';

  @override
  String get sbStepAim => 'What are you aiming for?';

  @override
  String get sbStepAbout => 'Tell us a bit about you';

  @override
  String get sbStepDna => 'Your Career DNA';

  @override
  String get sbSubEnjoy =>
      'Pick everything that sounds like you. No wrong answers.';

  @override
  String get sbSubAim => 'This shapes how Nexora presents you.';

  @override
  String get sbSubAbout => 'Optional — one line helps us personalize it.';

  @override
  String get sbSubDna =>
      'Review the draft, remove what doesn\'t fit, then save.';

  @override
  String get sbAddOwn => 'Something else? Add your own:';

  @override
  String get sbCustomHint => 'e.g. Robotics, Nursing, Game Dev…';

  @override
  String get sbSentenceHint => 'e.g. I love training and being part of a team…';

  @override
  String get sbInspiration => 'Need inspiration? Tap one:';

  @override
  String get sbDraftedBy => 'Drafted by Nexora — edit anything, then save.';

  @override
  String get sbSummary => 'Summary';

  @override
  String get sbSkills => 'Skills';

  @override
  String get sbExperience => 'Experience';

  @override
  String get sbProjects => 'Projects';

  @override
  String get sbEducation => 'Education';

  @override
  String get sbCertifications => 'Certifications';

  @override
  String get sbAchievements => 'Achievements';

  @override
  String get sbLanguages => 'Languages';

  @override
  String get sbAdd => 'Add';

  @override
  String get sbPlaceholderRole => 'Role';

  @override
  String get sbPlaceholderProject => 'Project';

  @override
  String get sbPlaceholderDegree => 'Degree';

  @override
  String get sbDrafting => 'Drafting your Career DNA';

  @override
  String get sbDraftingSub =>
      'Nexora is turning your taps into a full profile.';

  @override
  String get sbReady => 'Your Career DNA is ready';

  @override
  String get sbReadySub =>
      'We drafted your whole profile from a few taps. Here\'s where to take it next.';

  @override
  String get sbNextAnalyze => 'See your match score';

  @override
  String get sbNextAnalyzeSub => 'Run Analyze on a job you like';

  @override
  String get sbNextCv => 'Build a CV';

  @override
  String get sbNextCvSub => 'Turn this DNA into a CV in Studio';

  @override
  String get sbNextExplore => 'Explore your DNA';

  @override
  String get sbNextExploreSub => 'Review and tweak what we drafted';

  @override
  String get sbIntProgramming => 'Programming';

  @override
  String get sbIntDesign => 'Design';

  @override
  String get sbIntWriting => 'Writing';

  @override
  String get sbIntData => 'Data';

  @override
  String get sbIntMarketing => 'Marketing';

  @override
  String get sbIntTeaching => 'Teaching';

  @override
  String get sbIntBusiness => 'Business';

  @override
  String get sbIntEngineering => 'Engineering';

  @override
  String get sbIntMedicine => 'Medicine';

  @override
  String get sbIntLaw => 'Law';

  @override
  String get sbIntFinance => 'Finance';

  @override
  String get sbIntPsychology => 'Psychology';

  @override
  String get sbIntPhotography => 'Photography';

  @override
  String get sbIntMusic => 'Music';

  @override
  String get sbIntSports => 'Sports';

  @override
  String get sbIntHospitality => 'Hospitality';

  @override
  String get sbIntAgriculture => 'Agriculture';

  @override
  String get sbIntScience => 'Science';

  @override
  String get sbIntSales => 'Sales';

  @override
  String get sbGoalInternship => 'Internship';

  @override
  String get sbGoalScholarship => 'Scholarship';

  @override
  String get sbGoalJob => 'Job';

  @override
  String get sbGoalFreelance => 'Freelance';

  @override
  String get dnaTitle => 'Career DNA';

  @override
  String get dnaEditProfile => 'Edit Profile';

  @override
  String get dnaBuildNexora => 'Build with Nexora';

  @override
  String get dnaBuildNexoraSubEmpty =>
      'No CV yet? Answer a few taps and we draft your profile.';

  @override
  String get dnaRefineNexora => 'Refine with Nexora';

  @override
  String get dnaRefineSub =>
      'Polish your Career DNA with AI — a few quick taps.';

  @override
  String get dnaEmptyTitle => 'Your Career DNA is empty';

  @override
  String get dnaEmptySub =>
      'No CV yet? Answer a few quick taps and Nexora drafts your whole profile — skills, experience, projects and more.';

  @override
  String get sbDone => 'Done';

  @override
  String get sbContinue => 'Continue';

  @override
  String get sbDraft => 'Draft my DNA';

  @override
  String get sbSaveDna => 'Save to my DNA';

  @override
  String get dnaSave => 'Save';

  @override
  String get homeGreetingMorning => '☀️ Good morning';

  @override
  String get homeGreetingAfternoon => '🌤️ Good afternoon';

  @override
  String get homeGreetingEvening => '🌙 Good evening';

  @override
  String get homeDnaHealth => 'Career DNA Health';

  @override
  String get homeSixActive => '6 active';

  @override
  String get analyzeEmptyTitle => 'No analyses yet';

  @override
  String get analyzeEmptySub => 'Run a new analysis to see your match here.';

  @override
  String get studioCvBattle => '⚔ CV Battle';

  @override
  String get studioCvBattleHint => 'Compare versions against a target role';

  @override
  String get studioAtsCompat => 'ATS Compatibility';

  @override
  String get studioCreateNewCv => 'Create a new CV';

  @override
  String get studioNameHint =>
      'Name it after the role or opportunity you are targeting.';

  @override
  String get studioCvTitleHint => 'CV title (e.g. Senior Flutter Engineer)';

  @override
  String get studioPurpose => 'Purpose';

  @override
  String get studioCreateCvBtn => 'Create CV';

  @override
  String get studioRenameCv => 'Rename CV';

  @override
  String get studioCvTitle => 'CV title';

  @override
  String get studioCancel => 'Cancel';

  @override
  String get studioSave => 'Save';

  @override
  String get studioClose => 'Close';

  @override
  String get studioDone => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get studioOptimizing => 'Optimizing…';

  @override
  String get studioOptimizationComplete => 'Optimization complete';

  @override
  String get studioAtsRaised => 'ATS score raised from';

  @override
  String get studioAtsTo => 'to';

  @override
  String get studioPurposeInternship => 'Internship';

  @override
  String studioTemplateSelected(String name) {
    return 'Template · $name selected';
  }

  @override
  String studioCreatedSnack(String title) {
    return '$title created';
  }

  @override
  String studioOptimizedSnack(int ats) {
    return 'Optimized — ATS $ats%';
  }

  @override
  String get studioSummary => 'SUMMARY';

  @override
  String get studioExperience => 'EXPERIENCE';

  @override
  String get trackerCompleted => 'Completed';

  @override
  String get trackerStatusApplied => 'Applied';

  @override
  String get trackerStatusReview => 'Review';

  @override
  String get trackerStatusInterview => 'Interview';

  @override
  String get trackerStatusOffer => 'Offer 🎉';

  @override
  String get trackerAddApp => 'Add Application';

  @override
  String get trackerAddAppSub =>
      'Track a role you applied for or plan to target.';

  @override
  String get trackerCompany => 'Company';

  @override
  String get trackerRole => 'Role';

  @override
  String get trackerStatus => 'Status';

  @override
  String get trackerCurrentStatus => 'Current status';

  @override
  String get trackerMoveTo => 'Move to';

  @override
  String get trackerAddAppBtn => 'Add Application';

  @override
  String get trackerAdded => 'added';

  @override
  String get trackerRemoved => 'Application removed';

  @override
  String get trackerMovedTo => 'Moved to';

  @override
  String trackerCompanyAdded(String company) {
    return '$company added';
  }

  @override
  String get trackerDeleteApplication => 'Delete application';

  @override
  String get trackerPractice => 'Practice for this role';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authSignInSub => 'Sign in to continue building your Career DNA.';

  @override
  String get authCreateSub =>
      'Start with your basics — we will never publish anything.';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authContinueApple => 'Continue with Apple';

  @override
  String get authFullName => 'Full name';

  @override
  String get authFullNameHint => 'Ahmed Al-Rashidi';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPassword => 'Password';

  @override
  String get authForgot => 'FORGOT?';

  @override
  String get authPasswordHint => 'Your password';

  @override
  String get authPasswordHintNew => 'Min. 8 characters';

  @override
  String get authSignInBtn => 'Sign in';

  @override
  String get authCreateBtn => 'Create account';

  @override
  String get authNewToNexora => 'New to Nexora? Create an account';

  @override
  String get authAlreadyHave => 'Already have an account? Sign in';

  @override
  String get authTerms =>
      'By continuing you agree to the Terms of Service and Privacy Policy.';

  @override
  String get authOrEmail => 'OR CONTINUE WITH EMAIL';

  @override
  String get welcomeCareer => 'Your Career\n';

  @override
  String get welcomeUnderstood => 'Understood.\n';

  @override
  String get welcomeElevated => 'Elevated.';

  @override
  String get welcomeSubtitle =>
      'AI-powered career intelligence that understands who you are, what you want, and how to get you there.';

  @override
  String get welcomePrivateTitle => '100% Private';

  @override
  String get welcomePrivateSub => 'Your data is secure\nand encrypted';

  @override
  String get welcomeAiTitle => 'AI-Powered';

  @override
  String get welcomeAiSub => 'Smart insights that\nsave you time';

  @override
  String get welcomeResultsTitle => 'Results-Driven';

  @override
  String get welcomeResultsSub => 'Get more interviews\nand opportunities';

  @override
  String get welcomeMatchingTitle => 'Smart Matching';

  @override
  String get welcomeMatchingSub => 'Find opportunities that\ntruly fit you.';

  @override
  String get welcomeAtsTitle => 'ATS Optimization';

  @override
  String get welcomeAtsSub => 'Beat the system with\nAI-powered insights.';

  @override
  String get welcomeInterviewTitle => 'Interview Ready';

  @override
  String get welcomeInterviewSub =>
      'Practice with AI and\nbuild your confidence.';

  @override
  String get welcomeGrowthTitle => 'Career Growth';

  @override
  String get welcomeGrowthSub => 'Track progress and\nachieve your goals.';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get welcomeAlreadyAccount => 'I already have an account';

  @override
  String get onbSlide1Eyebrow => '01 · ANALYZE';

  @override
  String get onbSlide1Lead => 'Know your match\n';

  @override
  String get onbSlide1Accent => 'before you apply.';

  @override
  String get onbSlide1Body =>
      'Paste any job, scholarship, or program. Nexora extracts the real requirements and scores them against your Career DNA.';

  @override
  String get onbSlide2Eyebrow => '02 · BUILD';

  @override
  String get onbSlide2Lead => 'CVs engineered\n';

  @override
  String get onbSlide2Accent => 'to beat the ATS.';

  @override
  String get onbSlide2Body =>
      'The AI CV Studio scores every line against your target role — then rewrites it until the machines say yes.';

  @override
  String get onbSlide3Eyebrow => '03 · TRACK';

  @override
  String get onbSlide3Lead => 'Own your entire\n';

  @override
  String get onbSlide3Accent => 'career pipeline.';

  @override
  String get onbSlide3Body =>
      'Applications, interviews and offers in one calm dashboard. Practice rounds and smart nudges keep you on target.';

  @override
  String get onbNext => 'Next';

  @override
  String get onbCreateDna => 'Create my career DNA';

  @override
  String get onbAlreadyAccount => 'I already have an account';

  @override
  String get onbSkip => 'SKIP';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsEmail => 'Email';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirm => 'Sign out?';

  @override
  String get settingsSignOutBody =>
      'You\'ll be returned to the sign-in screen.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsSignOutError => 'Couldn\'t sign out. Please try again.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get changeLater => 'You can change this later.';

  @override
  String get optional => 'Optional';

  @override
  String get addLabel => 'Add';

  @override
  String get intakeAboutYou => 'One line about you';

  @override
  String get intakeAboutYouHint =>
      'e.g. I love building apps and learning new tech';

  @override
  String get backLabel => 'Back';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get draftFailed =>
      'Couldn\'t reach the AI. We used your answers instead.';

  @override
  String get goalTitle => 'What are you aiming for?';

  @override
  String get goalSubtitle => 'This shapes the guidance Nexora gives you.';

  @override
  String get goal_job => 'Get a job';

  @override
  String get goal_job_d => 'Find roles that fit you';

  @override
  String get goal_cv => 'Build a CV';

  @override
  String get goal_cv_d => 'A CV ready to send';

  @override
  String get goal_internship => 'Get an internship';

  @override
  String get goal_internship_d => 'Real experience before graduating';

  @override
  String get goal_masters => 'Pursue a master\'s';

  @override
  String get goal_masters_d => 'Strengthen your application';

  @override
  String get goal_scholarship => 'Win a scholarship';

  @override
  String get goal_scholarship_d => 'Stand out to committees';

  @override
  String get goal_careerChange => 'Change careers';

  @override
  String get goal_careerChange_d => 'Pivot into a new field';

  @override
  String get goal_improve => 'Improve my profile';

  @override
  String get goal_improve_d => 'Fill the gaps holding you back';

  @override
  String get goal_unsure => 'Not sure yet';

  @override
  String get goal_unsure_d => 'We\'ll help you explore';

  @override
  String get stageTitle => 'Where are you in your journey?';

  @override
  String get stageSubtitle => 'We\'ll tailor the questions to your stage.';

  @override
  String get stage_student => 'Student';

  @override
  String get stage_student_d => 'Still in school or university';

  @override
  String get stage_freshGraduate => 'Fresh graduate';

  @override
  String get stage_freshGraduate_d => 'Just finished your degree';

  @override
  String get stage_earlyCareer => 'Early career';

  @override
  String get stage_earlyCareer_d => 'A few years of experience';

  @override
  String get stage_experienced => 'Experienced';

  @override
  String get stage_experienced_d => 'Solid track record';

  @override
  String get stage_careerChanger => 'Career changer';

  @override
  String get stage_careerChanger_d => 'Moving into a new field';

  @override
  String get fieldTitle => 'Which field are you targeting?';

  @override
  String get fieldSubtitle => 'Pick the area you want to build your career in.';

  @override
  String get field_programming => 'Programming';

  @override
  String get field_design => 'Design';

  @override
  String get field_writing => 'Writing';

  @override
  String get field_data => 'Data';

  @override
  String get field_marketing => 'Marketing';

  @override
  String get field_teaching => 'Teaching';

  @override
  String get field_business => 'Business';

  @override
  String get field_engineering => 'Engineering';

  @override
  String get field_medicine => 'Medicine';

  @override
  String get field_law => 'Law';

  @override
  String get field_finance => 'Finance';

  @override
  String get field_psychology => 'Psychology';

  @override
  String get field_photography => 'Photography';

  @override
  String get field_music => 'Music';

  @override
  String get field_sports => 'Sports';

  @override
  String get field_hospitality => 'Hospitality';

  @override
  String get field_agriculture => 'Agriculture';

  @override
  String get field_science => 'Science';

  @override
  String get field_sales => 'Sales';

  @override
  String get field_other => 'Other';

  @override
  String get intakeTitle => 'Let\'s build your Career DNA';

  @override
  String get intakeSubtitle =>
      'Answer what you can — you can refine everything later.';

  @override
  String intakeProgress(int answered, int total) {
    return 'Completed $answered of $total';
  }

  @override
  String get intakeTapHint => 'Tap to select';

  @override
  String get intakeTargetRole => 'Target role';

  @override
  String get intakeTargetRoleHint => 'e.g. Flutter Developer';

  @override
  String get intakeTargetIndustry => 'Target industry';

  @override
  String get intakeTargetIndustryHint => 'e.g. Fintech';

  @override
  String get intakeNoExperience => 'I don\'t have experience yet';

  @override
  String get intakeAltEvidence => 'What can you show instead?';

  @override
  String get intakeSkills => 'Your top skills';

  @override
  String get intakeSkillsHint => 'Comma separated, e.g. Flutter, Figma';

  @override
  String get intakeEducation => 'Education';

  @override
  String get intakeAddEducation => 'Add education';

  @override
  String get intakeDegree => 'Degree';

  @override
  String get intakeFieldStudy => 'Field of study';

  @override
  String get intakeExperience => 'Experience';

  @override
  String get intakeAddExperience => 'Add experience';

  @override
  String get intakeProjects => 'Projects';

  @override
  String get intakeAddProject => 'Add project';

  @override
  String get intakeProjectName => 'Project name';

  @override
  String get intakeProjectDesc => 'What did you build?';

  @override
  String get intakeProjectTech => 'Technologies';

  @override
  String get intakeProjectLinks => 'Project links (URLs)';

  @override
  String get intakePlaceholderRole => 'Role';

  @override
  String get intakeCerts => 'Certifications';

  @override
  String get intakeAddCert => 'Add certification';

  @override
  String get intakeAchievements => 'Achievements';

  @override
  String get intakeAddAchievement => 'Add achievement';

  @override
  String get intakeLanguages => 'Languages';

  @override
  String get intakeAddLanguage => 'Add language';

  @override
  String get intakeContinue => 'Continue to AI interview';

  @override
  String get intakeEmptyError =>
      'Add at least a target role or some skills to continue.';

  @override
  String get intakeExpectedGraduation => 'Expected graduation';

  @override
  String get intakeCoursework => 'Coursework';

  @override
  String get intakeInternships => 'Internships';

  @override
  String get intakeGraduationStatus => 'Graduation status';

  @override
  String get intakeCurrentRole => 'Current or recent role';

  @override
  String get intakeCareerDirection => 'Career direction';

  @override
  String get intakeLeadership => 'Leadership';

  @override
  String get intakeMeasurableImpact => 'Measurable impact';

  @override
  String get intakeCareerProgression => 'Career progression';

  @override
  String get intakePreviousCareer => 'Previous career field';

  @override
  String get intakePreviousRole => 'Previous role';

  @override
  String get intakeTransferableSkills => 'Transferable skills';

  @override
  String get intakeReasonTransition => 'Why are you changing careers?';

  @override
  String get intakeCompany => 'Company';

  @override
  String get intakeYears => 'Years';

  @override
  String get intakeDurationMonths => 'Duration (months)';

  @override
  String get intakeBack => 'Back';

  @override
  String get intakeSkip => 'Skip';

  @override
  String get intakeFinish => 'Finish';

  @override
  String get nextActionCompleteDna => 'Complete your Career DNA';

  @override
  String get nextActionCompleteDnaSub =>
      'Add your goal, experience or projects to unlock guidance.';

  @override
  String get nextActionTargetRole => 'Define your target role';

  @override
  String get nextActionTargetRoleSub =>
      'Tell us the role you\'re aiming for so we can tailor everything.';

  @override
  String get nextActionTransferable => 'Highlight your transferable skills';

  @override
  String get nextActionTransferableSub =>
      'Show how your past experience applies to your new field.';

  @override
  String get nextActionRefine => 'Refine your Career DNA';

  @override
  String get nextActionRefineSub =>
      'Polish weak spots — a few quick taps with AI.';

  @override
  String get interviewTitle => 'AI Career Interview';

  @override
  String get interviewSubtitle =>
      'A few quick questions, then we draft your profile.';

  @override
  String get interviewThinking => 'Nexora is drafting your profile…';

  @override
  String get interviewDoneTitle => 'Your profile is drafted';

  @override
  String get interviewDoneSub => 'Review it and continue to your Career DNA.';

  @override
  String get interviewContinue => 'Review my Career DNA';

  @override
  String get interviewFallback =>
      'AI is unavailable — we built a draft from your answers.';

  @override
  String get interviewStart => 'Start interview';

  @override
  String get interviewQ1 =>
      'In a few sentences, tell us about yourself and what you\'ve done.';

  @override
  String get interviewQ2 => 'What are you most proud of building or achieving?';

  @override
  String get interviewQ3 => 'What kind of opportunities are you looking for?';

  @override
  String get interviewGenerating => 'Generating your profile';

  @override
  String get interviewNext => 'Next';

  @override
  String get dnaReviewTitle => 'Your Career DNA';

  @override
  String get dnaReviewSubtitle =>
      'Review what we built. Edit anything, then save.';

  @override
  String get dnaIdentityTitle => 'Career Direction';

  @override
  String get dnaSaveEnter => 'Save & enter Nexora';

  @override
  String get dnaSaved => 'Career DNA saved';

  @override
  String get dnaEdit => 'Edit';

  @override
  String get dnaTarget => 'Target';

  @override
  String get dnaSummary => 'Summary';

  @override
  String get dnaNotAdded => 'Not added yet';

  @override
  String dnaScoreFormat(int percent) {
    return '$percent% complete';
  }

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordBody =>
      'Enter your email and we\'ll send a reset link.';

  @override
  String get resetPasswordSend => 'Send reset link';

  @override
  String get resetPasswordSent =>
      'If that email exists, a reset link is on its way.';

  @override
  String get ciTitle => 'Career Intelligence';

  @override
  String get ciStrongestSkills => 'Strongest skills';

  @override
  String get ciSupportingSkills => 'Supporting skills';

  @override
  String get ciExperience => 'Experience';

  @override
  String get ciEducation => 'Education';

  @override
  String get ciDirection => 'Direction';

  @override
  String get ciMissingInfo => 'What\'s missing';

  @override
  String get ciWeaknesses => 'Weak spots';

  @override
  String get ciClearDirection => 'Focused';

  @override
  String get ciNoDirection => 'Exploring';

  @override
  String get ciAddTargetCta => 'Add a target to focus your guidance';

  @override
  String get strengthNone => 'None';

  @override
  String get strengthLimited => 'Limited';

  @override
  String get strengthModerate => 'Moderate';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get eduBasic => 'Basic';

  @override
  String get eduStandard => 'Standard';

  @override
  String get eduStrong => 'Strong';

  @override
  String get readinessStarter => 'Getting started';

  @override
  String get readinessBuilding => 'Building';

  @override
  String get readinessStrong => 'Strong';

  @override
  String get readinessInterviewReady => 'Interview-ready';

  @override
  String get gapTargetRole => 'Target role';

  @override
  String get gapSummary => 'Summary';

  @override
  String get gapSkills => 'Skills';

  @override
  String get gapExperience => 'Experience';

  @override
  String get gapProjects => 'Projects';

  @override
  String get gapEducation => 'Education';

  @override
  String get gapCertifications => 'Certifications';

  @override
  String get gapAchievements => 'Achievements';

  @override
  String get gapLanguages => 'Languages';

  @override
  String get gapSkillEvidence => 'Skill evidence';

  @override
  String get targetTitle => 'Targets';

  @override
  String get targetListEmpty => 'No targets yet';

  @override
  String get targetListEmptySub =>
      'Add a job, internship, graduate program or scholarship you\'re aiming for to focus your guidance.';

  @override
  String get targetAdd => 'Add target';

  @override
  String get targetEdit => 'Edit target';

  @override
  String get targetType => 'Type';

  @override
  String get targetTypeJob => 'Job';

  @override
  String get targetTypeInternship => 'Internship';

  @override
  String get targetTypeGraduateProgram => 'Graduate Program';

  @override
  String get targetTypeAcademicApplication => 'Academic Application';

  @override
  String get targetTypeCustom => 'Custom';

  @override
  String get targetRoleLabel => 'Role / Title';

  @override
  String get targetRoleHint => 'e.g. Flutter Developer';

  @override
  String get targetIndustryLabel => 'Industry';

  @override
  String get targetIndustryHint => 'e.g. Fintech';

  @override
  String get targetCountryLabel => 'Country / Region';

  @override
  String get targetSeniorityLabel => 'Seniority';

  @override
  String get targetLanguageLabel => 'Language';

  @override
  String get targetCompanyLabel => 'Company / University';

  @override
  String get targetUrlLabel => 'Link';

  @override
  String get targetDescriptionLabel => 'Description / Requirements';

  @override
  String get targetSave => 'Save target';

  @override
  String get targetDelete => 'Delete target';

  @override
  String get targetDeleteConfirm =>
      'Delete this target? This can\'t be undone.';

  @override
  String get targetOpen => 'Open';

  @override
  String get analyzeSubtitle =>
      'Paste a job, internship or program description. We\'ll score it against your Career DNA and explain every result.';

  @override
  String get analyzeDescriptionHint => 'Paste the job description here…';

  @override
  String get analyzeButton => 'Analyze';

  @override
  String get analyzeJustAnalyze => 'Just analyze';

  @override
  String get analyzeNewTarget => 'New target';

  @override
  String get analyzeMatchScore => 'Match score';

  @override
  String get analyzeOverall => 'Overall';

  @override
  String get analyzeRecommendation => 'Recommendation';

  @override
  String get analyzePartialMatches => 'Partial matches';

  @override
  String get analyzeNotEvidenced => 'Not yet evidenced';

  @override
  String get analyzeMismatch => 'Mismatch';

  @override
  String get analyzeUnclear => 'Unclear';

  @override
  String get analyzeRequiredSkills => 'Required skills';

  @override
  String get analyzePreferredSkills => 'Preferred skills';

  @override
  String get analyzeTechnologies => 'Technologies';

  @override
  String get analyzeResponsibilities => 'Responsibilities';

  @override
  String get analyzeCertifications => 'Certifications';

  @override
  String get analyzeLanguages => 'Languages';

  @override
  String get analyzeSoftSkills => 'Soft skills';

  @override
  String get analyzeDomainKnowledge => 'Domain knowledge';

  @override
  String get analyzeKeywordsList => 'Keywords';

  @override
  String get analyzeExperienceReq => 'Experience';

  @override
  String get analyzeEducationReq => 'Education';

  @override
  String get analyzeAgainstTarget => 'Analyzed against target';

  @override
  String get analyzeCreateCv => 'Create CV for this Target';

  @override
  String get analyzeEmpty =>
      'No analysis yet. Paste a job description to begin.';

  @override
  String get analyzeRemove => 'Remove';

  @override
  String get analyzeRequired => 'Required';

  @override
  String get analyzePreferred => 'Preferred';

  @override
  String get analyzeCatStrong => 'Strong match';

  @override
  String get analyzeCatGood => 'Good match';

  @override
  String get analyzeCatModerate => 'Moderate match';

  @override
  String get analyzeCatWeak => 'Weak match';

  @override
  String get cvNoCvs => 'No CVs yet';

  @override
  String get cvCreate => 'Create CV';

  @override
  String get cvTarget => 'Target';

  @override
  String get cvTemplate => 'Template';

  @override
  String get cvGenerate => 'Generate';

  @override
  String get cvUseFactual => 'Use Factual CV';

  @override
  String get cvRetry => 'Retry';

  @override
  String get cvExport => 'Export';

  @override
  String get cvVersions => 'Versions';

  @override
  String cvVersion(Object n) {
    return 'Version $n';
  }

  @override
  String get cvFactualLabel => 'Factual CV';

  @override
  String get cvAiTailored => 'AI Tailored';

  @override
  String get cvGenerating => 'Generating…';

  @override
  String get cvGenerationFailed => 'Generation failed';

  @override
  String get cvSelectTargetFirst => 'Select a target first';

  @override
  String get cvCopy => 'Copy';

  @override
  String get cvExportText => 'Copy this CV as text';

  @override
  String get cvSourceFactual => 'Built only from verified facts';

  @override
  String get cvBack => 'Back';

  @override
  String get cvOpen => 'Open';

  @override
  String get cvConfirmDelete => 'Delete this CV? This can\'t be undone.';

  @override
  String get cvTemplateMinimal => 'Minimal';

  @override
  String get cvTemplateModern => 'Modern';

  @override
  String get cvTemplateCompact => 'Compact';

  @override
  String get cvEditSummary => 'Summary';

  @override
  String get cvEditSkills => 'Skills (comma separated)';

  @override
  String get cvEditName => 'Full name';

  @override
  String get cvEditTitle => 'Headline';

  @override
  String get cvEditEmail => 'Email';

  @override
  String get cvEditPhone => 'Phone';

  @override
  String get cvEditLocation => 'Location';

  @override
  String get cvEditSubtitle => 'Subtitle';

  @override
  String cvSavedToast(int n) {
    return 'Saved as version $n';
  }

  @override
  String get cvFactualToast => 'Showing your Factual CV';

  @override
  String get cvValidationFailed => 'Generated content could not be verified';

  @override
  String get cvPreviewEmpty => 'Nothing to preview yet';

  @override
  String get cvEvaluateTitle => 'CV Evaluation';

  @override
  String get cvScoreOverall => 'Overall';

  @override
  String get cvScoreAts => 'ATS / Parseability';

  @override
  String get cvScoreTarget => 'Target Alignment';

  @override
  String get cvScoreContent => 'Content Strength';

  @override
  String get cvScoreEvidence => 'Evidence Strength';

  @override
  String get cvScoreReadability => 'Readability';

  @override
  String get cvScoreClarity => 'Clarity';

  @override
  String get cvScoreStructure => 'Structure';

  @override
  String get cvScoreKeyword => 'Keyword Alignment';

  @override
  String get cvScoreSkill => 'Skill Alignment';

  @override
  String get cvScoreSection => 'Section Completeness';

  @override
  String get cvDeterministicOnly =>
      'Showing structural checks only (AI explanations are unavailable). Scores are fully deterministic.';

  @override
  String get cvNoSuggestions =>
      'No improvement suggestions — this CV looks strong for the target.';

  @override
  String get cvSuggestionProblem => 'Issue';

  @override
  String get cvSuggestionCurrent => 'Current';

  @override
  String get cvSuggestionSuggested => 'Suggested';

  @override
  String get cvSuggestionWhy => 'Why it helps';

  @override
  String get cvSuggestionTarget => 'Target requirement';

  @override
  String get cvApplySuggestion => 'Apply';

  @override
  String get cvDismissSuggestion => 'Dismiss';

  @override
  String get cvEditSuggestion => 'Edit';

  @override
  String get cvReEvaluate => 'Re-evaluate';

  @override
  String get cvAppliedSuggestion => 'Applied — new version created.';

  @override
  String get cvEvaluateFailed => 'Could not evaluate the CV. Please try again.';

  @override
  String get acLabel => 'Next best action';

  @override
  String get acTitleCompleteDna => 'Complete your Career DNA';

  @override
  String get acDescCompleteDna =>
      'Add your skills, experience, and goals so we can guide your next step.';

  @override
  String get acCtaCompleteDna => 'Complete Profile';

  @override
  String get acTitleDefineTarget => 'Define your target';

  @override
  String get acDescDefineTarget =>
      'Pick the role you\'re aiming for so we can tailor everything to it.';

  @override
  String get acCtaDefineTarget => 'Define Target';

  @override
  String get acTitleAnalyzeOpportunity => 'Analyze an opportunity';

  @override
  String get acDescAnalyzeOpportunity =>
      'Review how well you match a real job and where the gaps are.';

  @override
  String get acCtaAnalyzeOpportunity => 'Analyze Opportunity';

  @override
  String acTitleCreateCv(String role) {
    return 'Create a CV for $role';
  }

  @override
  String acDescCreateCv(String role) {
    return 'Build a targeted CV for $role from your verified Career DNA.';
  }

  @override
  String get acCtaCreateCv => 'Create CV';

  @override
  String get acTitleEvaluateCv => 'Evaluate your CV';

  @override
  String get acDescEvaluateCv =>
      'See how your CV scores and get concrete ways to improve it.';

  @override
  String get acCtaEvaluateCv => 'Evaluate CV';

  @override
  String get acTitleImproveCv => 'Improve your CV';

  @override
  String get acDescImproveCv =>
      'Apply the suggested changes to strengthen your CV.';

  @override
  String get acCtaImproveCv => 'Review Improvements';

  @override
  String get acTitleTrackApplications => 'You\'re ready to apply';

  @override
  String get acDescTrackApplications =>
      'Your CV is strong. Start tracking the roles you apply to.';

  @override
  String get acCtaTrackApplications => 'Track Applications';

  @override
  String get acTitlePrepareInterview => 'Prepare for your interview';

  @override
  String get acDescPrepareInterview =>
      'You have an interview-stage application. Practice the gaps that matter for this role.';

  @override
  String get acCtaPrepareInterview => 'Prepare Interview';

  @override
  String get acTitlePracticeInterview => 'Practice your interview';

  @override
  String get acDescPracticeInterview =>
      'Run a mock interview for this role and get scored, grounded coaching on your answers.';

  @override
  String get acCtaPracticeInterview => 'Practice Interview';

  @override
  String get acLoading => 'Finding your next step…';

  @override
  String get acTarget => 'Target';

  @override
  String get acScore => 'Score';

  @override
  String acPending(int count) {
    return '$count improvements';
  }

  @override
  String get prepTitle => 'Interview Readiness';

  @override
  String get prepDesc =>
      'Focused practice for the gaps that matter in this role.';

  @override
  String prepForRole(String role) {
    return 'for $role';
  }

  @override
  String get prepFocusTitle => 'Focus areas';

  @override
  String get prepWhyLabel => 'Why prepare this';

  @override
  String get prepQuestionLabel => 'Practice question';

  @override
  String get prepCoachingLabel => 'Coaching';

  @override
  String get prepLikelyQuestions => 'Likely questions';

  @override
  String get prepTips => 'Tips';

  @override
  String get prepRegenerate => 'Regenerate';

  @override
  String get prepPractice => 'Practice';

  @override
  String get prepAiUnavailable =>
      'AI is unavailable — showing your key gaps to prepare. Nothing is fabricated.';

  @override
  String get prepNoAnalysis =>
      'No opportunity analysis found for this role. Preparing from your skills; analyze the role for sharper prep.';

  @override
  String get prepEmptyNoInterview =>
      'Nothing to prepare yet. Analyze a role and track your applications to unlock focused practice.';

  @override
  String get practiceTitle => 'Interview Practice';

  @override
  String get practiceDesc =>
      'Building your mock interview from your readiness plan…';

  @override
  String get practiceError =>
      'Something went wrong while preparing the practice session.';

  @override
  String get practiceEmpty => 'No questions available for this role yet.';

  @override
  String practiceProgress(int index, int total) {
    return 'Question $index of $total';
  }

  @override
  String get practiceAnswerHint =>
      'Type your answer here. Use a real example if you can.';

  @override
  String get practiceAnswerHintVoice =>
      'Tap the mic to speak, or type your answer here.';

  @override
  String get practiceTapToSpeak => 'Tap to speak';

  @override
  String get practiceListening => 'Listening...';

  @override
  String get practiceSubmit => 'Submit answer';

  @override
  String get practiceFinish => 'See results';

  @override
  String get practiceNext => 'Next question';

  @override
  String get practiceRelevance => 'Relevance';

  @override
  String get practiceSpecificity => 'Specificity';

  @override
  String get practiceStructure => 'Structure';

  @override
  String get practiceConsistency => 'Profile consistency';

  @override
  String get practiceStrengths => 'What went well';

  @override
  String get practiceImprove => 'Ways to improve';

  @override
  String get practiceCoaching => 'Coaching';

  @override
  String get practiceUnverified => 'Unverified claims';

  @override
  String get practiceStrong => 'Strong answer';

  @override
  String get practiceGood => 'Good answer';

  @override
  String get practiceNeedsImprovement => 'Needs improvement';

  @override
  String get practiceSummaryTitle => 'Practice summary';

  @override
  String practiceSummaryScore(int count) {
    return 'Scored on $count answers';
  }

  @override
  String get practiceRecommended => 'Recommended focus next time';

  @override
  String get practiceAgain => 'Practice again';

  @override
  String get practiceDone => 'Done';

  @override
  String get cvCompleteProfile => 'Complete Profile';

  @override
  String get cvQualityCouldBeBetter => 'CV quality could be better';

  @override
  String get exitConfirm => 'Press back again to exit';

  @override
  String get exitConfirmTitle => 'Exit app?';

  @override
  String get enhanceTitle => 'Enhance Your DNA';

  @override
  String get enhanceAcceptAll => 'Accept All';

  @override
  String get enhanceSuggestionsLeft => 'suggestions to review';

  @override
  String get enhanceAccepted => 'accepted';

  @override
  String get enhanceRejected => 'skipped';

  @override
  String get enhanceBefore => 'Before';

  @override
  String get enhanceAfter => 'After';

  @override
  String get enhanceAccept => 'Accept';

  @override
  String get enhanceReject => 'Skip';

  @override
  String get enhanceApply => 'Apply Changes';

  @override
  String get enhanceApplied => 'CareerDNA updated successfully';

  @override
  String get enhanceError => 'Failed to load suggestions';

  @override
  String get enhanceRetry => 'Retry';

  @override
  String get enhanceBtn => 'Enhance DNA';
}
