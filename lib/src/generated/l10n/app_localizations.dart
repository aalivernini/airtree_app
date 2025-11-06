import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('en'),
    Locale('it')
  ];

  /// No description provided for @forestAreaFull.
  ///
  /// In en, this message translates to:
  /// **'The total of the forest portions cannot exceed 100%'**
  String get forestAreaFull;

  /// No description provided for @forestAreaOnly.
  ///
  /// In en, this message translates to:
  /// **'This is the only forest portion. You can delete it using the map red icon'**
  String get forestAreaOnly;

  /// No description provided for @irrigatedHelp.
  ///
  /// In en, this message translates to:
  /// **'Select this option if the trees are irrigated'**
  String get irrigatedHelp;

  /// No description provided for @textureHelp.
  ///
  /// In en, this message translates to:
  /// **'Select the soil texture for the project. If you have no information please select a mean texture'**
  String get textureHelp;

  /// No description provided for @privateHelp.
  ///
  /// In en, this message translates to:
  /// **'Select this option if you do not want to share the project data with third parties'**
  String get privateHelp;

  /// No description provided for @yearSimulationHelp.
  ///
  /// In en, this message translates to:
  /// **'Pollutant removal by vegetation will be assessed using local meteo data of the selected year'**
  String get yearSimulationHelp;

  /// No description provided for @yearSimulation.
  ///
  /// In en, this message translates to:
  /// **'Reference year'**
  String get yearSimulation;

  /// No description provided for @insertGreen.
  ///
  /// In en, this message translates to:
  /// **'1) Tap on the orange icon and select a new tree/tree row/forest \n\n2) tap on the map to position the vegetation. Use blue buttons to reset, change or confirm the vegetation position'**
  String get insertGreen;

  /// No description provided for @helpLabel.
  ///
  /// In en, this message translates to:
  /// **'Show help labels'**
  String get helpLabel;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// No description provided for @keepGreen.
  ///
  /// In en, this message translates to:
  /// **'Keep existing green option for the next insert'**
  String get keepGreen;

  /// No description provided for @keepSpecies.
  ///
  /// In en, this message translates to:
  /// **'Keep the species for the next insertion'**
  String get keepSpecies;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get close;

  /// The current language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// Terms of Use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get terms;

  /// No description provided for @terms_accept.
  ///
  /// In en, this message translates to:
  /// **'I declare that I have read and understood the Terms of Use and I fully accept them'**
  String get terms_accept;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// No description provided for @privacy_accept.
  ///
  /// In en, this message translates to:
  /// **'I declare that I have read and understood the Privacy Policy'**
  String get privacy_accept;

  /// A programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Hello world'**
  String get helloWorld;

  /// name project
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get nameProject;

  /// No description provided for @nameProjectHelp.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get nameProjectHelp;

  /// date project
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateProject;

  /// date format
  ///
  /// In en, this message translates to:
  /// **'MM.dd.yy'**
  String get formatDate;

  /// name page
  ///
  /// In en, this message translates to:
  /// **'Project List'**
  String get projectList;

  /// new project
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get addNewProject;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Project description'**
  String get descr;

  /// No description provided for @descrHelp.
  ///
  /// In en, this message translates to:
  /// **'Main focus of the project'**
  String get descrHelp;

  /// location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationHelp.
  ///
  /// In en, this message translates to:
  /// **'name of the city, park , road...'**
  String get locationHelp;

  /// dateStart
  ///
  /// In en, this message translates to:
  /// **'Date start'**
  String get dateStart;

  /// dateEnd
  ///
  /// In en, this message translates to:
  /// **'Date end'**
  String get dateEnd;

  /// soilTexture
  ///
  /// In en, this message translates to:
  /// **'Soil texture'**
  String get soilTexture;

  /// submit
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// private
  ///
  /// In en, this message translates to:
  /// **'The project is private'**
  String get private;

  /// irrigated
  ///
  /// In en, this message translates to:
  /// **'The trees are irrigated'**
  String get irrigated;

  /// Mean
  ///
  /// In en, this message translates to:
  /// **'Mean'**
  String get mean;

  /// Sandy
  ///
  /// In en, this message translates to:
  /// **'Sandy?'**
  String get sandy;

  /// Silty
  ///
  /// In en, this message translates to:
  /// **'Silty?'**
  String get silty;

  /// Clay
  ///
  /// In en, this message translates to:
  /// **'Clay?'**
  String get clay;

  /// language
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get soilLanguage;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'AirTree has a maximum range of 15 Km'**
  String get rangeAirTree;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get species;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Diameter of the stem (cm)'**
  String get diameter;

  /// No description provided for @diameterHelp.
  ///
  /// In en, this message translates to:
  /// **'Diameter of the stem (cm) taken at 1.3 m height. If the tree has a multiple stem, take the average of the diameters of the single stems. If the tree does not reach 1.3 m, insert zero'**
  String get diameterHelp;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Height (m)'**
  String get height;

  /// No description provided for @heightHelp.
  ///
  /// In en, this message translates to:
  /// **'Height of the tree (m) taken from the ground to the highest point of the tree'**
  String get heightHelp;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Crown insertion height (m)'**
  String get crownHeight;

  /// No description provided for @crownHeightHelp.
  ///
  /// In en, this message translates to:
  /// **'Height (m) taken from the ground to height of the lowest point of the tree crown. Do not consider small branches ther are not connected to the main body of the crown'**
  String get crownHeightHelp;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Crown diamater (m)'**
  String get crownDiamater;

  /// No description provided for @crownDiamaterHelp.
  ///
  /// In en, this message translates to:
  /// **'Average diameter (m) of the crown projection  on the ground'**
  String get crownDiamaterHelp;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'LAI'**
  String get lai;

  /// No description provided for @laiHelp.
  ///
  /// In en, this message translates to:
  /// **'Leaf Area Index: assess it by using the icon on the left'**
  String get laiHelp;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Number of trees'**
  String get treeNumber;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Canopy cover (%)'**
  String get canopyCover;

  /// No description provided for @canopyCoverHelp.
  ///
  /// In en, this message translates to:
  /// **'The percentage of the ground covered by vertical projection of the tree crowns'**
  String get canopyCoverHelp;

  /// No description provided for @percentArea.
  ///
  /// In en, this message translates to:
  /// **'Represented portion of the forest (%)'**
  String get percentArea;

  /// No description provided for @percentAreaHelp.
  ///
  /// In en, this message translates to:
  /// **'Represented portion of the forest (%) fot the selected species and the parameters inserted'**
  String get percentAreaHelp;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Add information'**
  String get addInformation;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutPage.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutPage;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'insert text app_it.arb e in app_en.arb'**
  String get textAboutPage;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpPage.
  ///
  /// In en, this message translates to:
  /// **'Help Page'**
  String get helpPage;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'insert text app_it.arb e in app_en.arb'**
  String get textHelpPage;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'First Name : {name}'**
  String firstName(String name);

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Last Name : {name}'**
  String lastName(String name);

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Username : {name}'**
  String userName(String name);

  /// descr
  ///
  /// In en, this message translates to:
  /// **'E-mail : {name}'**
  String email(String name);

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get infoPrj;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'GeoJSON downloaded to the download folder'**
  String get geoJson;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Share GeoJSON'**
  String get shareGeo;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Id Project'**
  String get idProject;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdate;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get sortName;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Sort by start date'**
  String get sortDate;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get languagePage;

  /// No description provided for @languageSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species language'**
  String get languageSpecies;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englLang;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get itLang;

  /// No description provided for @scientific.
  ///
  /// In en, this message translates to:
  /// **'scientific'**
  String get scientific;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Hand page'**
  String get handPage;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Right-handed'**
  String get rightHand;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Left-handed'**
  String get leftHand;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get register;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Join Airtree: Register Now!'**
  String get joinAirtree;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Missin First Name'**
  String get missingFirstName;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameRegister;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Missing Last Name'**
  String get missingLastName;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameRegister;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get userNameRegister;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Missing Email'**
  String get missingEmail;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Missing Password'**
  String get missingPassword;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Password is too short, minimum 8 characters'**
  String get passwordShort;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 1 uppercase letter, 1 lowercase letter, and 1 number.'**
  String get passwordPath;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Registration successfull!'**
  String get registrationOk;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Unexpected error during the registration...'**
  String get registrationFailed;

  /// No description provided for @missingUsername.
  ///
  /// In en, this message translates to:
  /// **'Missing Username'**
  String get missingUsername;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get otherPage;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Sign on clicking the Icon on top right!'**
  String get signOnRight;

  /// desce
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLink;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Help Page'**
  String get helpLink;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Dominant Hand Selection Page'**
  String get dominantHand;

  /// No description provided for @languageLink.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLink;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Database export status'**
  String get databaseExportStatus;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get databaseFailed;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get databaseSucces;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Export Database'**
  String get exportDataBase;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get importDataBase;

  /// descr
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}!'**
  String welcome(String name);

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Please enter some text'**
  String get enterText;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Please select a species'**
  String get enterSpecies;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Please enter a number'**
  String get enterNumber;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'no marker selected'**
  String get markerSelected;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'longer press required to edit info'**
  String get longPress;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'New tree'**
  String get tree;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'New Tree row'**
  String get treeRow;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Project Error'**
  String get projectError;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Project Initialized'**
  String get projectInitialized;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Elaboration data'**
  String get elaborationData;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Results are ready'**
  String get resultsReady;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Data have been changed'**
  String get dataChange;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Unknown Status'**
  String get unknow;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'there is no data in the Airtree map'**
  String get noData;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'\nThe project data will be sent to Airtree server for elaboration by pushing the \'get result\' button\n\n.When the results are ready you will receive a notification'**
  String get greyServer;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'\nThe project data has been changed\n'**
  String get orangeServer;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'\nThe project data is waiting to be processed by the Airtree server.\n\nWhen the results are ready you will receive a notification'**
  String get greenServer;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get prj;

  /// No description provided for @changeMap.
  ///
  /// In en, this message translates to:
  /// **'Change map'**
  String get changeMap;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'New forest'**
  String get urbanForest;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Information on vegetation'**
  String get information;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Reposition the vegetation'**
  String get changePosition;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'delete the vegetation'**
  String get delete;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'This is existing vegetation'**
  String get existingGreen;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'further portion of the forest'**
  String get addNewSpecies;

  /// desc
  ///
  /// In en, this message translates to:
  /// **'Select species'**
  String get selectSpecies;

  /// No description provided for @iconAlignment.
  ///
  /// In en, this message translates to:
  /// **'Map icon alignment'**
  String get iconAlignment;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get right;
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
