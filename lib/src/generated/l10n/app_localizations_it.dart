// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get forestAreaFull =>
      'Il totale delle porzioni di bosco non può superare il 100%';

  @override
  String get forestAreaOnly =>
      'Questa è l\'unica porzione di bosco. Puoi eliminarla utilizzando l\'icona rossa sulla mappa';

  @override
  String get irrigatedHelp =>
      'Seleziona questa opzione se gli alberi sono irrigati';

  @override
  String get textureHelp =>
      'Seleziona la tessitura del suolo. Se non hai informazioni puoi indicare una tessitura media';

  @override
  String get privateHelp =>
      'Seleziona questa opzione se non intendi condividere i dati del tuo progetto con terzi';

  @override
  String get yearSimulationHelp =>
      'La rimozione di inquinanti da parte della vegetazione verrà valutata utilizzando i dati meteo locali dell\'anno selezionato';

  @override
  String get yearSimulation => 'Anno di riferimento';

  @override
  String get insertGreen =>
      '1) Usa l\'icona arancione per selezionare un nuovo albero/filare/bosco\n\n2) Tocca la mappa per posizionare la vegetazione (tocchi multipli sono necessari per posizionare filari e boschi\n\n3) Usa i pulsanti blu per cancellare, cambiare o confermare la posizione della vegetazione';

  @override
  String get helpLabel => 'Mostra testo d\'aiuto';

  @override
  String get deleteProject => 'Elimina progetto';

  @override
  String get keepGreen =>
      'Mantieni l\'opzione del verde esistente per il prossimo inserimento';

  @override
  String get keepSpecies => 'Mantieni la specie per il prossimo inserimento';

  @override
  String get settings => 'Impostazioni';

  @override
  String get close => 'chiudi';

  @override
  String get language => 'Italiano';

  @override
  String get terms => 'Termini e Condizioni d\'uso';

  @override
  String get terms_accept =>
      'Dichiaro di aver letto e compreso i Termini e le Condizioni d\'uso e di accettarli senza riserve';

  @override
  String get privacy => 'Privacy policy';

  @override
  String get privacy_accept =>
      'Dichiaro di aver letto e compreso l\'informativa sulla Privacy Policy';

  @override
  String get helloWorld => 'Ciao mondo!';

  @override
  String get nameProject => 'Nome del progetto';

  @override
  String get nameProjectHelp => 'Nome del progetto';

  @override
  String get dateProject => 'Data';

  @override
  String get formatDate => 'dd.MM.yy';

  @override
  String get projectList => 'Progetti';

  @override
  String get addNewProject => 'Nuovo progetto';

  @override
  String get descr => 'Descrizione del progetto';

  @override
  String get descrHelp => 'Principale obiettivo/caratteristica del progetto';

  @override
  String get location => 'Luogo';

  @override
  String get locationHelp => 'nome di città, parco, strada ...  ';

  @override
  String get dateStart => 'Data iniziale';

  @override
  String get dateEnd => 'Data finale';

  @override
  String get soilTexture => 'Tessitura del suolo';

  @override
  String get submit => 'Invia';

  @override
  String get cancel => 'Cancella';

  @override
  String get private => 'Il progetto è privato';

  @override
  String get irrigated => 'Gli alberi sono irrigati';

  @override
  String get mean => 'Media';

  @override
  String get sandy => 'Sabbiosa';

  @override
  String get silty => 'Limosa';

  @override
  String get clay => 'Argillosa';

  @override
  String get soilLanguage => 'it';

  @override
  String get rangeAirTree => 'Raggio massimo di 15 km';

  @override
  String get species => 'Specie';

  @override
  String get diameter => 'Diametro del fusto (cm)';

  @override
  String get diameterHelp =>
      'Diametro del fusto (cm) preso a 1.3 m di altezza. Se l\'albero ha un fusto multiplo, prendi la media dei diametri dei singoli fusti. Se l\'albero non raggiunge 1.3 m, inserisci zero';

  @override
  String get height => 'Altezza (m)';

  @override
  String get heightHelp =>
      'Altezza totale dell\'albero (m) misurata dal suolo fino alla cima dell\'albero';

  @override
  String get crownHeight => 'Altezza di inserzione della chioma (m)';

  @override
  String get crownHeightHelp =>
      'Altezza (m) misurata dal suolo fino al punto più basso della chioma. Non considerare rami che non sono connessi alla parte principale della chioma';

  @override
  String get crownDiamater => 'Diametro della chioma (m)';

  @override
  String get crownDiamaterHelp =>
      'Diametro medio della proiezione della chioma (m) al suolo';

  @override
  String get lai => 'LAI';

  @override
  String get laiHelp =>
      'Indice di area fogliare: puoi stimarlo tramite l\'icona a sinistra';

  @override
  String get treeNumber => 'Numero di alberi';

  @override
  String get canopyCover => 'Grado di copertura delle chiome (%) ';

  @override
  String get canopyCoverHelp =>
      'Percentuale di suolo coperto dalla proiezione verticale delle chiome degli alberi';

  @override
  String get percentArea => 'Porzione di bosco rappresentata (%)';

  @override
  String get percentAreaHelp =>
      'Porzione di bosco rappresentata (%) dalla specie selezionata e dai parametri inseriti';

  @override
  String get addInformation => 'Inserisci informazioni';

  @override
  String get about => 'About';

  @override
  String get aboutPage => 'Informazioni';

  @override
  String get textAboutPage => 'inserisco testo in app_it.arb e in app_en.arb';

  @override
  String get help => 'Help';

  @override
  String get helpPage => 'Pagina help';

  @override
  String get textHelpPage => 'inserisco testo in app_it.arb e in app_en.arb';

  @override
  String firstName(String name) {
    return 'Nome : $name';
  }

  @override
  String lastName(String name) {
    return 'Cognome : $name';
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
  String get infoPrj => 'Progetto';

  @override
  String get geoJson => 'GeoJSON scaricato nella cartella download';

  @override
  String get shareGeo => 'Condividi GeoJSON';

  @override
  String get idProject => 'Id Progetto';

  @override
  String get lastUpdate => 'Ultimo aggiornamento';

  @override
  String get sortName => 'Ordina per nome';

  @override
  String get sortDate => 'Ordina per data di inizio';

  @override
  String get languagePage => 'Lingua dell\'interfaccia';

  @override
  String get languageSpecies => 'Lingua delle specie';

  @override
  String get englLang => 'Inglese';

  @override
  String get itLang => 'Italiano';

  @override
  String get scientific => 'scientifico';

  @override
  String get handPage => 'Scegli mano';

  @override
  String get rightHand => 'Destrorso';

  @override
  String get leftHand => 'Mancino';

  @override
  String get register => 'Registrati';

  @override
  String get joinAirtree => 'Unisciti a Airtree: Registrati ora!';

  @override
  String get missingFirstName => 'Nome non inserito';

  @override
  String get firstNameRegister => 'Nome';

  @override
  String get missingLastName => 'Cognome non inserito';

  @override
  String get lastNameRegister => 'Cognome';

  @override
  String get userNameRegister => 'Username';

  @override
  String get missingEmail => 'Manca l\'email';

  @override
  String get missingPassword => 'Manca la password';

  @override
  String get passwordShort => 'Password troppo corta, minimo 8 caratteri';

  @override
  String get passwordPath =>
      'Password deve contenere almeno una lettera maiuscola, una lettera minuscola, un numero';

  @override
  String get password => 'Password';

  @override
  String get registrationOk => 'Registrazione avvenuta!';

  @override
  String get registrationFailed =>
      'Errore inaspettato durante la registrazione';

  @override
  String get missingUsername => 'Manca l\'Username';

  @override
  String get otherPage => 'Altro';

  @override
  String get signOnRight =>
      'Clicca sull\'icona in alto a destra per registrarti';

  @override
  String get aboutLink => 'Informazioni';

  @override
  String get helpLink => 'Pagina help';

  @override
  String get dominantHand => 'Pagina per scegliere mano dominante';

  @override
  String get languageLink => 'Lingua';

  @override
  String get databaseExportStatus => 'Stato dell\'esportazione del database';

  @override
  String get databaseFailed => 'Errore';

  @override
  String get databaseSucces => 'Database esportato con successo';

  @override
  String get exportDataBase => 'Esporta database';

  @override
  String get importDataBase => 'Importa database';

  @override
  String welcome(String name) {
    return 'Benvenuto $name';
  }

  @override
  String get enterText => 'Per favore inserisci il testo';

  @override
  String get enterSpecies => 'Per favore seleziona una specie';

  @override
  String get enterNumber => 'Per favore inserisci un numero';

  @override
  String get markerSelected => 'Nessun marcatore selezionato';

  @override
  String get longPress => 'tenere premuto per modificare i dati';

  @override
  String get tree => 'Nuovo albero';

  @override
  String get treeRow => 'Nuovo filare';

  @override
  String get projectError => 'errore';

  @override
  String get projectInitialized => 'Progetto inizializzato';

  @override
  String get elaborationData => 'eleborazione dati';

  @override
  String get resultsReady => 'risultati pronti';

  @override
  String get dataChange => 'dati modificati';

  @override
  String get unknow => 'sconosciuto';

  @override
  String get noData => 'nessun dato nella mappa di Airtree';

  @override
  String get greyServer =>
      'I dati di questo progetto verranno inviati al server di Airtree per l\'elaborazione premendo il tasto \'get result\'. Quando i dati sono pronti, riceverai una notifica.';

  @override
  String get orangeServer => 'I dati del progetto sono stati cambiati';

  @override
  String get greenServer =>
      '\nI dati del progetto sono in attesa di essere elaborati dal server Airtree.\n\nQuando i risultati saranno pronti, riceverai una notifica.';

  @override
  String get prj => 'Progetto';

  @override
  String get changeMap => 'Cambia mappa';

  @override
  String get map => 'Mappa';

  @override
  String get result => 'Risultati';

  @override
  String get other => 'Altro';

  @override
  String get urbanForest => 'Nuovo bosco';

  @override
  String get information => 'Informazioni sulla vegetazione';

  @override
  String get changePosition => 'Riposiziona la vegetazione';

  @override
  String get delete => 'Cancella la vegetazione';

  @override
  String get existingGreen => 'Questa vegetazione è esistente';

  @override
  String get addNewSpecies => 'Ulteriori porzioni di bosco?';

  @override
  String get selectSpecies => 'Seleziona la specie';

  @override
  String get iconAlignment => 'Allineamento icona mappa';

  @override
  String get left => 'sinistra';

  @override
  String get right => 'destra';
}
