import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers.dart' as pr;
import 'privacy_terms.dart' as ter;
import 'dart:io';
import 'package:Airtree/export_import_database.dart' as ex;




typedef VoidFunction = void Function();


class UserSetForm extends StatefulWidget {
    const UserSetForm({Key? key}) : super(key: key);

    @override
    _UserSetFormState createState() => _UserSetFormState();
}

class _UserSetFormState extends State<UserSetForm> {
    @override
    build(BuildContext context) {
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
        final uSetting = gProvider.userSetting;
        final loc = AppLocalizations.of(context)!;
        const spacer = TableRow(
            children: [
                SizedBox(height: 8),
                SizedBox(height: 8)
            ]
        );



        return Scaffold(
            appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.settings),
            ),
            body: SingleChildScrollView(
                child:
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child:
                    Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                            TableRow(
                                children: [
                                    Text(loc.languagePage),
                                    const DropdownLanguageInterface(),
                                ]
                            ),
                            spacer,
                            TableRow(
                                children: [
                                   Text(loc.languageSpecies),
                                   const DropdownLanguageSpecies(),
                                ]
                            ),
                            spacer,
                            TableRow(
                                children: [
                                    Text(loc.iconAlignment),
                                    const DropdownHandness(),
                                ]
                            ),
                            spacer,
                            TableRow(
                                children: [
                                    Text(loc.helpLabel),
                                    const CheckboxLabelHelp(),
                                ]
                            ),
                        ]
                    )
                    )
            ),
        );
    }
}



class OtherWidget extends StatefulWidget {
    const OtherWidget({super.key});

    @override
    _OtherWidgetState createState() => _OtherWidgetState();
}

class _OtherWidgetState extends State<OtherWidget> {
    List<Widget> getWidgetLink(String linkName, Widget widget) {
        return [
            SizedBox(height: 10),
            GestureDetector(
                onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => widget),
                    );
                },
                child: Text(
                           linkName,
                           style: const TextStyle(
                               fontWeight: FontWeight.bold,
                               decoration: TextDecoration.underline,
                               color: Colors.blue),
                       ),
            ),
        ];
    }

    List<Widget> getFunctionLink(String linkName, VoidFunction fun) {
        return [
            SizedBox(height: 15),
            GestureDetector(
                onTap: () {
                    fun();
                },
                child: Text(
                           linkName,
                           style: const TextStyle(
                               fontWeight: FontWeight.bold,
                               decoration: TextDecoration.underline,
                               color: Colors.blue),
                       ),
            ),
        ];
    }

    @override
    Widget build(BuildContext context) {
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
        List<Widget> actionOther = [];
        final loc = AppLocalizations.of(context)!;

        // privacy popup
        final privacyPopUp = getPopup(context, EnumPopup.privacy, isRootNavigator: false);
        final termsPopUp = getPopup(context, EnumPopup.terms, isRootNavigator: false);

        const spacer = SizedBox(height: 15);

        Widget otherWidget = Scaffold(
            appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.otherPage),
                actions: actionOther,
            ),
            body: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.start, // Imposta l'allineamento a sinistra
                    crossAxisAlignment:
                    CrossAxisAlignment.start, // Allinea il testo a sinistra
                    children: [
                        ...getWidgetLink(loc.privacy, privacyPopUp),
                        spacer,
                        ...getWidgetLink(loc.terms, termsPopUp),
                        spacer,
                        ...getWidgetLink(loc.aboutLink, const AboutForm()),
                        spacer,
                        //...getWidgetLink(loc.helpLink, HelpForm()),
                        //spacer,
                        ...getWidgetLink(loc.settings, const UserSetForm()),
                        spacer,
                        ...getFunctionLink(loc.exportDataBase, ex.exportDatabase),
                        spacer,
                        ...getFunctionLink(loc.importDataBase, ex.importDatabase),
                        spacer,
                    ]
            )));
        return otherWidget;
    }
}




class DropdownLanguageInterface extends StatefulWidget {
    const DropdownLanguageInterface({super.key});

    @override
    State<DropdownLanguageInterface> createState() => _DropdownLanguageInterfaceState();
}

class _DropdownLanguageInterfaceState extends State<DropdownLanguageInterface> {
    // late SharedPreferences prefs;
    int idLanguage = 0;

    @override
    Widget build(BuildContext context) {
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
        final uSetting = gProvider.userSetting;
        idLanguage = uSetting!.idLanguageInterface;
        //final eProvider = Provider.of<pr.EditorProvider>(context, listen: false);

        List<DropdownMenuItem<int>> items = [
            DropdownMenuItem(
                value: 0, child: Text(AppLocalizations.of(context)!.englLang)),
            DropdownMenuItem(
                value: 1, child: Text(AppLocalizations.of(context)!.itLang)),
        ];
        return DropdownButton<int>(
            value: idLanguage,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.blue),
            underline: Container(
                height: 2,
                color: Colors.blue,
            ),
            onChanged: (int? value) {
                // This is called when the user selects an item.
                setState(() {
                    idLanguage = value!;
                    uSetting!.idLanguageInterface = idLanguage;
                    uSetting.dbUpdate();
                    gProvider.setLanguageInterface(idLanguage);
                });
            },
            items: items,
        );
    }
}

class DropdownLanguageSpecies extends StatefulWidget {
    const DropdownLanguageSpecies({super.key});

    @override
    State<DropdownLanguageSpecies> createState() => _DropdownLanguageSpeciesState();
}

class _DropdownLanguageSpeciesState extends State<DropdownLanguageSpecies> {
    int idLanguage = 0;

    @override
    Widget build(BuildContext context) {
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
        final uSetting = gProvider.userSetting;
        idLanguage = uSetting!.idLanguageSpecies;

        List<DropdownMenuItem<int>> items = [
            DropdownMenuItem(
                value: 0, child: Text(AppLocalizations.of(context)!.scientific)),
            DropdownMenuItem(
                value: 1, child: Text(AppLocalizations.of(context)!.englLang)),
            DropdownMenuItem(
                value: 2, child: Text(AppLocalizations.of(context)!.itLang)),
        ];
        return DropdownButton<int>(
            value: idLanguage,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.blue),
            underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
            ),
            onChanged: (int? value) {
                // This is called when the user selects an item.
                setState(() {
                    idLanguage = value!;
                    uSetting.idLanguageSpecies = idLanguage;
                    uSetting.dbUpdate();
                    gProvider.setLanguageSpecies(idLanguage);
                });
            },
            items: items,
        );
    }
}


class DropdownHandness extends StatefulWidget {
    const DropdownHandness({super.key});

    @override
    State<DropdownHandness> createState() => _DropdownHandnessState();
}

class _DropdownHandnessState extends State<DropdownHandness> {
    // late SharedPreferences prefs;
    int idHand = 0;


    @override
    Widget build(BuildContext context) {
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
        final uSetting = gProvider.userSetting;
        idHand = uSetting!.idHandness;

        List<DropdownMenuItem<int>> items = [
            DropdownMenuItem(
                value: 0, child: Text(AppLocalizations.of(context)!.right)),
            DropdownMenuItem(
                value: 1, child: Text(AppLocalizations.of(context)!.left)),
        ];
        return DropdownButton<int>(
            value: idHand,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.blue),
            underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
            ),
            onChanged: (int? value) {
                // This is called when the user selects an item.
                setState(() {
                    idHand = value!;
                    uSetting!.idHandness = idHand;
                    uSetting.dbUpdate();
                    gProvider.setHandness(idHand);
                });
            },
            items: items,
        );
    }
}


class CheckboxLabelHelp extends StatefulWidget {
    const CheckboxLabelHelp({super.key});

    @override
    State<CheckboxLabelHelp> createState() => _CheckboxLabelHelpState();
}

class _CheckboxLabelHelpState extends State<CheckboxLabelHelp> {
    int idHelpLabel = 0;
    bool isLabel = false;

    @override
    Widget build(BuildContext context) {
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
        final uSetting = gProvider.userSetting;
        idHelpLabel = uSetting!.idHelpLabel;
        isLabel = idHelpLabel == 1;

        return Checkbox(
            value: isLabel,
            onChanged: (bool? value) {
                setState(() {
                    isLabel = value!;
                    if (isLabel) {
                        idHelpLabel = 1;
                    } else {
                        idHelpLabel = 0;
                    }
                    uSetting.idHelpLabel = idHelpLabel;
                    uSetting.dbUpdate();
                });
            },
            activeColor: Colors.blue,
        );
    }
}





enum EnumPopup {
    privacy,
    terms,
}

Widget getPopupLink(BuildContext context, Widget popup, String title) {
    Widget widget = Align(
        alignment: Alignment.centerLeft,
        child:
        Padding(
            padding: const EdgeInsets.all(5),
            child:
            GestureDetector(
                onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                            return popup;
                        },
                    );
                },
                child: Text(
                           title,
                           style: const TextStyle(color: Colors.blue)
                       ),
            ),
        ),
    );
    return widget;
}


Widget getPopup(BuildContext context, EnumPopup enumPopup, {bool isRootNavigator = true}) {
    String title;
    String content;
    final locale = Localizations.localeOf(context).toString();
    switch (enumPopup) {
        case EnumPopup.privacy:
            title = AppLocalizations.of(context)!.privacy;
            content = locale == 'en'
                    ? ter.privacyEng
                    : ter.privacyIta;
            break;
        case EnumPopup.terms:
            title = AppLocalizations.of(context)!.terms;
            content = locale == 'en'
                    ? ter.termsEng
                    :ter.termsIta;
            break;
    }
    Widget popup = SafeArea(
        child:
        AlertDialog(
        title: Text(title),
        content:
        Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child:  Text(
                    content
                ),
            ),
        ),
        actions: [
            TextButton(
                onPressed: () {
                    //Navigator.of(context).pop();
                    Navigator.of(context, rootNavigator: isRootNavigator).pop();
                },
                child: Text(
                    AppLocalizations.of(context)!.close,
                    style: TextStyle(color: Colors.blue),
                )
            )
        ]
    ));
    return popup;
}





class PrivacyTermsForm extends StatefulWidget {
    const PrivacyTermsForm({super.key});

    @override
    PrivacyTermsFormState createState() {
        return PrivacyTermsFormState();
    }
}



class PrivacyTermsFormState extends State<PrivacyTermsForm> {
    bool privacy = false;
    bool terms = false;

    @override
    Widget build(BuildContext context) {
        sleep(const Duration(milliseconds: 200));

        // privacy popup
        final privacyPopUp = getPopup(context, EnumPopup.privacy);
        final linkPrivacy = getPopupLink(
            context,
            privacyPopUp,
            AppLocalizations.of(context)!.privacy
        );
        final termsPopUp = getPopup(context, EnumPopup.terms);
        final linkTerms = getPopupLink(
            context,
            termsPopUp,
            AppLocalizations.of(context)!.terms
        );

        final privacyRow = Row(
            children: [
                Expanded(
                    flex: 9,
                    child:
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child:
                        Text(
                            AppLocalizations.of(context)!.privacy_accept,
                            softWrap: true,
                        ),
                    ),
                ),
                Checkbox(
                    value: privacy,
                    onChanged: (bool? value) {
                        setState(() {
                            privacy = value!;
                        });
                    },
                    activeColor: Colors.blue,
                ),
                ]
        );

        final termsRow = Row(
            children: [
                Expanded(
                    flex: 9,
                    child:
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child:
                        Text(
                            AppLocalizations.of(context)!.terms_accept,
                            softWrap: true,
                        ),
                    ),
                ),
                Checkbox(
                    value: terms,
                    onChanged: (bool? value) {
                        setState(() {
                            terms = value!;
                        });
                    },
                    activeColor: Colors.blue,
                ),
                ]
        );


        final status = privacy && terms;
        final color = status ? Colors.blue : Colors.grey;
        const textStyle = TextStyle(color: Colors.black);
        final buttons = Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                ElevatedButton(
                    onPressed: () {
                        exit(0);
                    },
                    child: Text(
                        AppLocalizations.of(context)!.close,
                        style: textStyle,
                    ),
                ),
                ElevatedButton(
                    onPressed: () {
                        if (status) {
                            Navigator.pop(context, true);
                        }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                    ),
                    child: Text(
                        AppLocalizations.of(context)!.submit,
                        style: textStyle,
                    ),
                ),
            ],
        );

        return Scaffold(
            appBar: AppBar(
                title: Text(
                    'Airtree'
                ),
                actions:  [
                    Container(
                        margin: const EdgeInsets.only(right: 10),
                        child:
                        const DropdownLanguageInterface(),
                    )
                ],
            ),
            body: Column(
                children: [
                    linkPrivacy,
                    privacyRow,
                    linkTerms,
                    termsRow,
                    buttons,
                    ],
                ),
        );
    }

}


class AboutForm extends StatelessWidget {
    const AboutForm({Key? key});


    @override
    Widget build(BuildContext context) {
        const title = 'Airtree (Android)';
        const subtEn = 'Team of Airtree model';
        const subtIt = 'Team del modello Airtree';
        const textEn = '''
Copyright (c) 2023 Council for Agricultural Research and Economics (CREA)

Developed by: Alessandro Alivernini

Fundings:  POR FESR Lazio 2014-2020 (POR), project TECNOVERDE, CUP B85F20003230006

Description: the application allows you to survey and plan urban green within the Italian territory, with the possibility of geographically representing trees, rows and groves, and recording the species and various biometric characteristics, eg: trunk diameter, tree height. This information can be transmitted to the CNR servers to estimate the quantities of carbon dioxide and air pollutants (e.g. particulate matter and ground-level ozone) removed by the trees. The estimates are carried out with the Airtree model, developed in collaboration between CREA and CNR, which systematizes structural information of the trees (e.g. height of the tree, width of the crown), eco-physiological information (e.g. the speed of the chemical reactions involved in photosynthesis) and time series of climate data and air pollutants. With this information, Airtree estimates the amount of light that is captured by the tree's canopy, simulates the opening of the stomata on the leaves (the pores through which trees breathe) and then calculates the amount of carbon and pollutants removed from the atmosphere.
''';
        const textIta = '''
Copyright (c) 2023 Consiglio per la ricerca in agricoltura e l'analisi dell'economia agraria
Sviluppatore: Alessandro Alivernini

Finanziamenti:  POR FESR Lazio 2014-2020 (POR), progetto TECNOVERDE, CUP B85F20003230006

Descrizione: l'applicazione consente di censire e progettare il verde urbano all’interno del territorio nazionale, con la possibilità di rappresentare geograficamente alberi, filari e boschetti, e di registrare la specie e varie caratteristiche biometriche, eg: diametro del fusto, altezza dell’albero. Queste informazioni possono essere trasmesse ai server del CNR per stimare le quantità di anidride carbonica e di inquinanti atmosferici (eg. particolato e ozono troposferico) rimossi dagli alberi. Le stime sono svolte con il modello Airtree, sviluppato in collaborazione tra CREA e CNR,  che mette a sistema informazioni strutturali degli alberi (eg. altezza dell'albero, larghezza della chioma), informazioni ecofisiologiche (eg. la velocità delle reazioni chimiche coinvolte nella fotosintesi) e serie temporali di dati climatici e di inquinanti atmosferici. Con queste informazioni  Airtree stima la quantità di luce che viene catturata dalla chioma dell'albero, simula l'apertura degli stomi sulle foglie (i pori attraverso cui respirano gli alberi) e quindi calcola la quantità di carbonio e di inquinanti rimossi dall'atmosfera.
                ''';

        const devEn = '''
Main developers:
- Alessandro Alivernini [CREA]
- Silvano Fares [CNR]

Collaborators:
- Federico Franchi [CREA]
- Giorgia Di Domenico [CREA]
- Adriano Conte [CNR]
- Ilaria Zappitelli [CNR]
- Luciano Bosso [CNR]
                ''';

        const devIt = '''
Sviluppatori
- Alessandro Alivernini [CREA]
- Silvano Fares [CNR]

Collaboratori
- Federico Franchi [CREA]
- Giorgia Di Domenico [CREA]
- Adriano Conte [CNR]
- Ilaria Zappitelli [CNR]
- Luciano Bosso [CNR]
                ''';

const paperTitleEn = 'Scientific publications';
const paperTitleIt = 'Pubblicazioni scientifiche';

const paper = '''
- Zappitelli, I., Conte, A., Alivernini, A., Finardi, S., & Fares, S. (2023). Species-Specific Contribution to Atmospheric Carbon and Pollutant Removal: Case Studies in Two Italian Municipalities. Atmosphere, 14(2), 285. https://doi.org/10.3390/atmos14020285
- Conte, A., Zappitelli, I., Fusaro, L., Alivernini, A., Moretti, V., Sorgi, T., Recanatesi, F., Fares, S., 2022. Significant Loss of Ecosystem Services by Environmental Changes in the Mediterranean Coastal Area. Forests 2022, 13, 689. https://doi.org/10.3390/f13050689
- Conte, A., Otu-Larbi, F., Alivernini, A., Hoshika, Y., Paoletti, E., Ashworth, K., Fares, S., 2021. Exploring new strategies for ozone-risk assessment: A dynamic-threshold case study. Environ. Pollut. 287, 117620. https://doi.org/10.1016/j.envpol.2021.117620
- Fares, S., Conte, A., Alivernini, A., Chianucci, F., Grotti, M., Zappitelli, I., Petrella, F., Corona, P., 2020. Testing Removal of Carbon Dioxide, Ozone, and Atmospheric Particles by Urban Parks in Italy. Environ. Sci. Technol. 54, 14910–14922. https://doi.org/10.1021/acs.est.0c04740
- Fares, S., Alivernini, A., Conte, A., Maggi, F., 2019. Ozone and particle fluxes in a Mediterranean forest predicted by the AIRTREE model. Sci. Total Environ. 682, 494–504. https://doi.org/10.1016/j.scitotenv.2019.05.109
        ''';


const acknowledgementsTitleIt = 'Ringraziamenti';
const acknowledgementsTitleEn = 'Acknowledgements';
const acknowledgementsEn = '''
- legal and administrative supervision: Valerio Di Stefano [CREA]
- scientific supervision for Leaf Area Index assessment: Francesco Chianucci [CREA]
''';
const acknowledgementsIt = '''
- supervisione legale e amministrativa: Valerio Di Stefano [CREA]
- supervisione scientifica per la stima dell'indice di area fogliare: Francesco Chianucci [CREA]
''';
        final language = Localizations.localeOf(context).toString();
        const titleStyle = TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
        );
        const sep = SizedBox(height: 8.0);

        return Scaffold(
            appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.about),
            ),
            body: SingleChildScrollView(
                // Aggiunto SingleChildScrollView qui
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            title,
                            style: titleStyle,
                        ),
                        Text(
                            language == 'en' ? textEn : textIta,
                        ),
                        sep,
                        Text(
                            language == 'en' ? acknowledgementsTitleEn : acknowledgementsTitleIt,
                            style: titleStyle,
                        ),
                        Text(
                            language == 'en' ? acknowledgementsEn : acknowledgementsIt,
                        ),
                        sep,
                        Text(
                            language == 'en' ? subtEn : subtIt,
                            style: titleStyle,
                        ),
                        Text(
                            language == 'en' ? devEn : devIt,
                        ),
                        sep,
                        Text(
                            language == 'en' ? paperTitleEn : paperTitleIt,
                            style: titleStyle,
                        ),
                        const Text(paper),
                    ],
                ),
            ),
        );
    }
}

class HelpForm extends StatelessWidget {
    const HelpForm({Key? key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.help),
            ),
            body: SingleChildScrollView(
                // Aggiunto SingleChildScrollView qui
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            AppLocalizations.of(context)!.helpPage,
                            style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                            AppLocalizations.of(context)!.textHelpPage,
                            style: TextStyle(fontSize: 16.0),
                        ),
                    ],
                ),
            ),
        );
    }
}






