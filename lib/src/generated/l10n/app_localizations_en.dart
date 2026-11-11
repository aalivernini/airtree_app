// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get forestAreaFull =>
      'The total of the forest portions cannot exceed 100%';

  @override
  String get forestAreaOnly =>
      'This is the only forest portion. You can delete it using the map red icon';

  @override
  String get irrigatedHelp => 'Select this option if the trees are irrigated';

  @override
  String get textureHelp =>
      'Select the soil texture for the project. If you have no information please select a mean texture';

  @override
  String get privateHelp =>
      'Select this option if you do not want to share the project data with third parties';

  @override
  String get yearSimulationHelp =>
      'Pollutant removal by vegetation will be assessed using local meteo data of the selected year';

  @override
  String get yearSimulation => 'Reference year';

  @override
  String get insertGreen =>
      '1) Tap on the orange icon and select a new tree/tree row/forest \n\n2) tap on the map to position the vegetation. Use blue buttons to reset, change or confirm the vegetation position';

  @override
  String get helpLabel => 'Show help labels';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get keepGreen => 'Keep existing green option for the next insert';

  @override
  String get keepSpecies => 'Keep the species for the next insertion';

  @override
  String get settings => 'Settings';

  @override
  String get close => 'close';

  @override
  String get language => 'English';

  @override
  String get terms => 'Terms of Use';

  @override
  String get terms_accept =>
      'I declare that I have read and understood the Terms of Use and I fully accept them';

  @override
  String get privacy => 'Privacy Policy';

  @override
  String get privacy_accept =>
      'I declare that I have read and understood the Privacy Policy';

  @override
  String get helloWorld => 'Hello world';

  @override
  String get nameProject => 'Project name';

  @override
  String get nameProjectHelp => 'Project name';

  @override
  String get dateProject => 'Date';

  @override
  String get formatDate => 'MM.dd.yy';

  @override
  String get projectList => 'Project List';

  @override
  String get addNewProject => 'New project';

  @override
  String get descr => 'Project description';

  @override
  String get descrHelp => 'Main focus of the project';

  @override
  String get location => 'Location';

  @override
  String get locationHelp => 'name of the city, park , road...';

  @override
  String get dateStart => 'Date start';

  @override
  String get dateEnd => 'Date end';

  @override
  String get soilTexture => 'Soil texture';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get private => 'The project is private';

  @override
  String get irrigated => 'The trees are irrigated';

  @override
  String get mean => 'Mean';

  @override
  String get sandy => 'Sandy?';

  @override
  String get silty => 'Silty?';

  @override
  String get clay => 'Clay?';

  @override
  String get soilLanguage => 'en';

  @override
  String get rangeAirTree => 'AirTree has a maximum range of 15 Km';

  @override
  String get species => 'Species';

  @override
  String get diameter => 'Diameter of the stem (cm)';

  @override
  String get diameterHelp =>
      'Diameter of the stem (cm) taken at 1.3 m height. If the tree has a multiple stem, take the average of the diameters of the single stems. If the tree does not reach 1.3 m, insert zero';

  @override
  String get height => 'Height (m)';

  @override
  String get heightHelp =>
      'Height of the tree (m) taken from the ground to the highest point of the tree';

  @override
  String get crownHeight => 'Crown insertion height (m)';

  @override
  String get crownHeightHelp =>
      'Height (m) taken from the ground to height of the lowest point of the tree crown. Do not consider small branches ther are not connected to the main body of the crown';

  @override
  String get crownDiamater => 'Crown diamater (m)';

  @override
  String get crownDiamaterHelp =>
      'Average diameter (m) of the crown projection  on the ground';

  @override
  String get lai => 'LAI';

  @override
  String get laiHelp =>
      'Leaf Area Index: assess it by using the icon on the left';

  @override
  String get treeNumber => 'Number of trees';

  @override
  String get canopyCover => 'Canopy cover (%)';

  @override
  String get canopyCoverHelp =>
      'The percentage of the ground covered by vertical projection of the tree crowns';

  @override
  String get percentArea => 'Represented portion of the forest (%)';

  @override
  String get percentAreaHelp =>
      'Represented portion of the forest (%) fot the selected species and the parameters inserted';

  @override
  String get addInformation => 'Add information';

  @override
  String get about => 'About';

  @override
  String get aboutPage => 'About';

  @override
  String get textAboutPage => 'insert text app_it.arb e in app_en.arb';

  @override
  String get help => 'Help';

  @override
  String get helpPage => 'Help Page';

  @override
  String get textHelpPage => 'insert text app_it.arb e in app_en.arb';

  @override
  String firstName(String name) {
    return 'First Name : $name';
  }

  @override
  String lastName(String name) {
    return 'Last Name : $name';
  }

  @override
  String userName(String name) {
    return 'Username : $name';
  }

  @override
  String email(String name) {
    return 'E-mail : $name';
  }

  @override
  String get infoPrj => 'Project';

  @override
  String get geoJson => 'GeoJSON downloaded to the download folder';

  @override
  String get shareGeo => 'Share GeoJSON';

  @override
  String get idProject => 'Id Project';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get sortName => 'Sort by name';

  @override
  String get sortDate => 'Sort by start date';

  @override
  String get languagePage => 'Interface language';

  @override
  String get languageSpecies => 'Species language';

  @override
  String get englLang => 'English';

  @override
  String get itLang => 'Italian';

  @override
  String get scientific => 'scientific';

  @override
  String get handPage => 'Hand page';

  @override
  String get rightHand => 'Right-handed';

  @override
  String get leftHand => 'Left-handed';

  @override
  String get register => 'Sign-in';

  @override
  String get joinAirtree => 'Join Airtree: Register Now!';

  @override
  String get missingFirstName => 'Missin First Name';

  @override
  String get firstNameRegister => 'First Name';

  @override
  String get missingLastName => 'Missing Last Name';

  @override
  String get lastNameRegister => 'Last Name';

  @override
  String get userNameRegister => 'Username';

  @override
  String get missingEmail => 'Missing Email';

  @override
  String get missingPassword => 'Missing Password';

  @override
  String get passwordShort => 'Password is too short, minimum 8 characters';

  @override
  String get passwordPath =>
      'Password must contain at least 1 uppercase letter, 1 lowercase letter, and 1 number.';

  @override
  String get password => 'Password';

  @override
  String get registrationOk => 'Registration successfull!';

  @override
  String get registrationFailed =>
      'Unexpected error during the registration...';

  @override
  String get missingUsername => 'Missing Username';

  @override
  String get otherPage => 'Others';

  @override
  String get signOnRight => 'Sign on clicking the Icon on top right!';

  @override
  String get aboutLink => 'About';

  @override
  String get helpLink => 'Help Page';

  @override
  String get dominantHand => 'Dominant Hand Selection Page';

  @override
  String get languageLink => 'Language';

  @override
  String get databaseExportStatus => 'Database export status';

  @override
  String get databaseFailed => 'Error';

  @override
  String get databaseSucces => 'Export successful';

  @override
  String get exportDataBase => 'Export Database';

  @override
  String get importDataBase => 'Import Database';

  @override
  String welcome(String name) {
    return 'Welcome $name!';
  }

  @override
  String get enterText => 'Please enter some text';

  @override
  String get enterSpecies => 'Please select a species';

  @override
  String get enterNumber => 'Please enter a number';

  @override
  String get markerSelected => 'no marker selected';

  @override
  String get longPress => 'longer press required to edit info';

  @override
  String get tree => 'New tree';

  @override
  String get treeRow => 'New Tree row';

  @override
  String get projectError => 'Project Error';

  @override
  String get projectInitialized => 'Project Initialized';

  @override
  String get elaborationData => 'Elaboration data';

  @override
  String get resultsReady => 'Results are ready';

  @override
  String get dataChange => 'Data have been changed';

  @override
  String get unknow => 'Unknown Status';

  @override
  String get noData => 'there is no data in the Airtree map';

  @override
  String get greyServer =>
      '\nThe project data will be sent to Airtree server for elaboration by pushing the \'get result\' button\n\n.When the results are ready you will receive a notification';

  @override
  String get orangeServer => '\nThe project data has been changed\n';

  @override
  String get greenServer =>
      '\nThe project data is waiting to be processed by the Airtree server.\n\nWhen the results are ready you will receive a notification';

  @override
  String get prj => 'Project';

  @override
  String get changeMap => 'Change map';

  @override
  String get map => 'Map';

  @override
  String get result => 'Result';

  @override
  String get other => 'Other';

  @override
  String get urbanForest => 'New forest';

  @override
  String get information => 'Information on vegetation';

  @override
  String get changePosition => 'Reposition the vegetation';

  @override
  String get delete => 'delete the vegetation';

  @override
  String get existingGreen => 'This is existing vegetation';

  @override
  String get addNewSpecies => 'further portion of the forest';

  @override
  String get selectSpecies => 'Select species';

  @override
  String get iconAlignment => 'Map icon alignment';

  @override
  String get left => 'left';

  @override
  String get right => 'right';

  @override
  String get attributionEsriPowered => 'Powered by Esri';

  @override
  String get attributionEsriSources =>
      'Source: Esri, Vantor, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community';

  @override
  String get attributionEsriWaybackSources =>
      'Source: Esri, Vantor, Earthstar Geographics, and the GIS User Community';

  @override
  String get attributionOsm => '© OpenStreetMap contributors';
}
