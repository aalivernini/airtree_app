import 'package:flutter/material.dart'; //import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:objectid/objectid.dart';
import 'package:latlong2/latlong.dart';
import 'package:datepicker_dropdown/datepicker_dropdown.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'camera/provider_lai.dart' as pr_lai;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';



import 'form_parts.dart';
import 'enums.dart' as en;
import 'database.dart' as db;
import 'data.dart' as dat;
import 'providers.dart' as pr;

const Duration tooltipDuration = Duration(seconds: 8);

List<DropdownMenuItem<int>> getDropdownTexture(String language) {
    List<DropdownMenuItem<int>> menuItems = [];
    Map<int, String> texture3 = {};
    switch (language) {
        case "en":
            texture3 = dat.Soil.getEnglish();
            break;
        case "it":
            texture3 = dat.Soil.getItalian();
            break;
        default:
            break;
    }
    texture3.forEach((key, value) {
        menuItems.add(DropdownMenuItem(
            value: key,
            child: Text(value),
        ));
    });
    return menuItems;
}

Widget getInfoButton(String text) {
    return Tooltip(
        showDuration: tooltipDuration,
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: false,
        verticalOffset: -15,
        margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
        message: text,
        child: const Icon(Icons.info)
    );
}


class GreenFormArgs {
    final String idGeometry;
    final String idProject;
    final String idUser;
    final en.EditorType type;
    final List<LatLng> coords;
    final int maxAreaPercent;
    final double area;
    dat.Point?   pnt;
    dat.Line?    line;
    dat.PolygonData? polData;
    bool? updateData; // if not null update tabular data
    bool? addPolygonData;


    GreenFormArgs(
        {
        required this.idGeometry,
        required this.idProject,
        required this.idUser,
        required this.type,
        required this.coords,
        required this.maxAreaPercent,
        required this.area,
        this.pnt,
        this.line,
        this.polData,
        this.updateData,
        this.addPolygonData,
        }
    );
}

class GreenForm extends StatefulWidget {
    GreenForm({super.key});

    Map<String, dat.ParamRow> par3 = {}; // parameters
    List<String> species = []; // species

    late SpeciesService speciesService;
    String? typeAheadTextOnchange; //backup value for typeAheadController

    @override
    State<GreenForm> createState() => GreenFormState();
}

class GreenFormState extends State<GreenForm> {
    final _formKey = GlobalKey<FormState>();

    static bool keepSpecies = false;
    static String lastSpecies = '';


    static bool existingG = false;
    // variables to restore widget values after a setState
    double onChangeHeight = 100000;
    double onChangeCrownHeight = 0;
    bool onChangeAddNext = false;

    @override
    void initState()  {
        dat.Param.getMapName().then((value) {
            setState(() {
                widget.par3 = value;
                widget.species = widget.par3.keys.toList();
                widget.speciesService = SpeciesService(widget.species);
            });
        });
        super.initState();
    }


    // Esegui qui le azioni desiderate in base alla lingua selezionata
    @override
    Widget build(BuildContext context) {
        final args = ModalRoute.of(context)!.settings.arguments as GreenFormArgs;
        final String idGeometry = args.idGeometry;
        final String idProject = args.idProject;
        final String idUser = args.idUser;
        final int maxAreaPercent = args.maxAreaPercent;
        final double area = args.area;
        en.EditorType type = args.type;
        List<LatLng> coords = args.coords;
        final laiProvider = Provider.of<pr_lai.ProviderLai>(context, listen: false);
        final pProvider = Provider.of<pr.ParamProvider>(context, listen: false);
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);

        // Build a Form widget using the _formKey created above.
        // variables set in the form
        int idSpecies = 0;
        int diameter = 0;
        double height = 0.0;
        double crownHeight = 0.0;
        double crownDiameter = 0.0;
        double lai = 0.0;
        // only for tree rows
        int treeNumber = 0;

        // only for forests
        int canopyCover = 0; // max 100
        int percentArea = 0; // max 100 - sum(percentArea) of previous records for the same geometry
        String idPolygonData = '';


        if (args.updateData != null) {
            switch (type) {
                case en.EditorType.point:
                    var pnt = args.pnt;
                    if (pnt != null) {
                        idSpecies = pnt.idSpecies;
                        diameter = pnt.diameter;
                        height = pnt.height;
                        crownHeight = pnt.crownHeight;
                        crownDiameter = pnt.crownDiameter;
                        lai = pnt.lai;
                        existingG = pnt.truth == 1;
                    }
                    break;
                case en.EditorType.line:
                    var line = args.line;
                    if (line != null) {
                        idSpecies = line.idSpecies;
                        diameter = line.diameter;
                        height = line.height;
                        crownHeight = line.crownHeight;
                        crownDiameter = line.crownDiameter;
                        lai = line.lai;
                        existingG = line.truth == 1;
                        treeNumber = line.treeNumber;
                    }
                    break;
                case en.EditorType.polygon:
                    var polData = args.polData;
                    if (polData != null) {
                        idPolygonData = polData.id;
                        idSpecies = polData.idSpecies;
                        diameter = polData.diameter;
                        height = polData.height;
                        crownHeight = polData.crownHeight;
                        crownDiameter = polData.crownDiameter;
                        lai = polData.lai;
                        existingG = polData.truth == 1;
                        canopyCover = polData.percentCover;
                        percentArea = polData.percentArea;
                    }
                    break;
                default:
                    break;
            }
        }


        var truthSwitch =
                TruthSwitch2(existingG: existingG, widgetText: AppLocalizations.of(context)!.existingGreen);
        var addNext =
                TruthSwitch(truth: onChangeAddNext ,widgetText: AppLocalizations.of(context)!.addNewSpecies);

        final keepSpeciesWid = Row(
            children: [
                Expanded(
                    flex: 9,
                    child:
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child:
                        Text(
                            AppLocalizations.of(context)!.keepSpecies,
                            softWrap: true,
                        ),
                    ),
                ),
                Checkbox(
                    value: keepSpecies,
                    onChanged: (bool? value) {
                        setState(() {
                            existingG = truthSwitch.existingG;
                            keepSpecies = value!;
                        });
                    },
                ),
                ]
        );

        if (keepSpecies == true) {
            widget.typeAheadTextOnchange = lastSpecies;
        }
        if (args.updateData != null) {
            widget.typeAheadTextOnchange = pProvider.par3[idSpecies]!.name;
        }

        final loc = AppLocalizations.of(context)!;

        // SPECIES
        final TextEditingController _typeAheadController = TextEditingController(text: widget.typeAheadTextOnchange);
        final speciesForm = TypeAheadFormField(
            validator: (value) {
                if(
                    value == null || value.isEmpty || !widget.species.contains(value)
                ) {
                    return AppLocalizations.of(context)!.enterSpecies;
                } else { return null; }
            },
            onSaved: (String? value) {
                idSpecies=(widget.par3[value!])!.airtreeId;
            },
            textFieldConfiguration: TextFieldConfiguration(
                                        controller: _typeAheadController,
                                        decoration: InputDecoration(
                                            labelText: loc.species,
                                            suffixIcon: Tooltip(
                                                showDuration: tooltipDuration,
                                                triggerMode: TooltipTriggerMode.tap,
                                                preferBelow: false,
                                                verticalOffset: -15,
                                                margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                                                message: loc.selectSpecies,
                                                child: const Icon(Icons.info)
                                            ),
                                        )
                                    ),
        suggestionsCallback: (pattern) {
            return widget.speciesService.getSuggestions(pattern);
        },
        itemBuilder: (context, suggestion) {
            return ListTile(title: Text(suggestion));
        },
                                        transitionBuilder: (context, suggestionsBox, controller) {
                                            return suggestionsBox;
                                        },
        onSuggestionSelected: (suggestion) {
            _typeAheadController.text = suggestion;
            lastSpecies = suggestion;
            widget.typeAheadTextOnchange = suggestion;
        }
        );

        // LAI FORM
        // required for table update
        if (lai != 0) {
            laiProvider.laiValue = lai;
        }

        final laiController = TextEditingController(
            text: laiProvider.laiValue == 0
            ? null
            : laiProvider.laiValue.toStringAsFixed(1)
        );
        final laiFormField =  TextFormField(
                        controller: laiController,
                        inputFormatters: [
                            NumericalRangeFormatter(min: 0, max: 10, type: en.NumberType.double)
                        ],
                        decoration: InputDecoration(
                            labelText: loc.lai,
                            suffixIcon: Tooltip(
                                showDuration: tooltipDuration,
                                triggerMode: TooltipTriggerMode.tap,
                                preferBelow: false,
                                verticalOffset: -15,
                                margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                                message: loc.laiHelp,
                                child: const Icon(Icons.info),
                            )),
                        keyboardType: TextInputType.number,
                        validator: validateNumber,
                        onSaved: (String? value) {
                            lai = double.parse(value!);
                        });

        // LAI ROW WIDGET
        final laiForm = Row(
            children: [
                Expanded(
                    flex: 2,
                    child:
                    IconButton(
                        icon: const Icon(Icons.camera),
                        onPressed: () {
                            Navigator.pushNamed(context, '/camera').then((value) {
                                setState(() {});
                            });
                        }
                    )),
                Expanded(
                    flex: 8,
                    child:
                        laiFormField
                )
                        ]);


        List<Widget> form2 = [
            truthSwitch,
            speciesForm,
            keepSpeciesWid,
            TextFormField(
                initialValue: diameter != 0
                ? diameter.toString()
                : "",
                inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    NumericalRangeFormatter(
                        min: 1, max: 1000, type: en.NumberType.integer)
                ],
                // The validator receives the text that the user has entered.
                decoration: InputDecoration(
                    labelText: loc.diameter,
                    suffixIcon: Tooltip(
                        showDuration: tooltipDuration,
                        triggerMode: TooltipTriggerMode.tap,
                        preferBelow: false,
                        verticalOffset: -15,
                        margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                        message: loc.diameterHelp,
                        child: const Icon(Icons.info)
                    )),
                keyboardType: TextInputType.number,
                validator: validateNumber,
                onSaved: (String? value) {
                    diameter = int.parse(value!);
                }),
            TextFormField(
                initialValue: height != 0
                ? height.toString()
                : "",
                inputFormatters: [
                    NumericalRangeFormatter(
                        min: 0.2, max: 100, type: en.NumberType.double)
                ],
                decoration: InputDecoration(

                    labelText: loc.height,
                    suffixIcon: Tooltip(
                        showDuration: tooltipDuration,
                        triggerMode: TooltipTriggerMode.tap,
                        preferBelow: false,
                        verticalOffset: -15,
                        margin: const  EdgeInsets.fromLTRB(30, 0, 30, 0),
                        message: loc.heightHelp,
                        child: const Icon(Icons.info)
                    )),
                onChanged: (text) {
                    try {
                        onChangeHeight = double.parse(text);
                        onChangeAddNext = addNext.truth;
                        existingG = truthSwitch.existingG;
                        setState(() {});
                    } catch (e) {
                        // not valid value
                    }
                },
                keyboardType: TextInputType.number,
                validator: validateNumber,
                onSaved: (String? value) {
                    height = double.parse(value!);
                }),
                TextFormField(
                    initialValue: crownHeight != 0
                    ? crownHeight.toString()
                    : "",
                    inputFormatters: [
                        NumericalRangeFormatter(
                            min: 0.1, max: onChangeHeight - 0.1, type: en.NumberType.double)
                    ],
                    decoration: InputDecoration(
                        labelText: loc.crownHeight,
                        suffixIcon: Tooltip(
                            showDuration: tooltipDuration,
                            triggerMode: TooltipTriggerMode.tap,
                            preferBelow: false,
                            verticalOffset: -15,
                            margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                            message: loc.crownHeightHelp,
                            child: const Icon(Icons.info)
                        )),
                    keyboardType: TextInputType.number,
                    validator: validateNumber,
                    onSaved: (String? value) {
                        crownHeight = double.parse(value!);
                        if (onChangeHeight <=crownHeight) {
                            crownHeight = onChangeHeight - 0.1;
                        }
                        //crownHeight = double.parse(value!);
                    },
                    ),
                    TextFormField(
                        initialValue: crownDiameter != 0
                        ? crownDiameter.toString()
                        : "",
                        inputFormatters: [
                            NumericalRangeFormatter(
                                min: 0.1, max: 100, type: en.NumberType.double)
                        ],
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.crownDiamater,
                            suffixIcon: Tooltip(
                                showDuration: tooltipDuration,
                                triggerMode: TooltipTriggerMode.tap,
                                preferBelow: false,
                                verticalOffset: -15,
                                margin: EdgeInsets.fromLTRB(30, 0, 30, 0),
                                message: loc.crownDiamaterHelp,
                                child: const Icon(Icons.info)
                            )),
                        keyboardType: TextInputType.number,
                        validator: validateNumber,
                        onSaved: (String? value) {
                            crownDiameter = double.parse(value!);
                        }),
                    laiForm,
        ];

        if (type == en.EditorType.line) {
      form2.add(TextFormField(
              initialValue: treeNumber != 0 ? treeNumber.toString() : "",
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            NumericalRangeFormatter(
                min: 0, max: 100000000, type: en.NumberType.integer)
          ],
          decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.treeNumber,
              suffixIcon: Tooltip(
                showDuration: tooltipDuration,
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: false,
                verticalOffset: -15,
                margin: EdgeInsets.fromLTRB(30, 0, 30, 0),
                message: "Number of trees",
                child: const Icon(Icons.info)
              )),
          keyboardType: TextInputType.number,
          validator: validateNumber,
          onSaved: (String? value) {
            treeNumber = int.parse(value!);
          }));
    } else if (type == en.EditorType.polygon) {
      form2.add(TextFormField(
              initialValue: canopyCover != 0 ? canopyCover.toString() : "",
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            NumericalRangeFormatter(
                min: 1, max: 100, type: en.NumberType.integer)
          ],
          decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.canopyCover,
              suffixIcon: Tooltip(
                  showDuration: tooltipDuration,
                  triggerMode: TooltipTriggerMode.tap,
                preferBelow: false,
                verticalOffset: -15,
                margin: EdgeInsets.fromLTRB(30, 0, 30, 0),
                message: loc.canopyCoverHelp,
                child: const Icon(Icons.info)
              )),
          keyboardType: TextInputType.number,
          validator: validateNumber,
          onSaved: (String? value) {
            canopyCover = int.parse(value!);
          }));
      form2.add(TextFormField(
              initialValue: percentArea != 0 ? percentArea.toString() : "",
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            NumericalRangeFormatter(
                min: 1,
                max: maxAreaPercent.toDouble(),
                type: en.NumberType.integer)
          ],
          decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.percentArea,
              suffixIcon: Tooltip(
                  showDuration: tooltipDuration,
                  triggerMode: TooltipTriggerMode.tap,
                preferBelow: false,
                verticalOffset: -15,
                margin: EdgeInsets.fromLTRB(30, 0, 30, 0),
                message: "%",
                child: const Icon(Icons.info)
              )),
          keyboardType: TextInputType.number,
          validator: validateNumber,
          onSaved: (String? value) {
            percentArea = int.parse(value!);
          }));
      if (args.addPolygonData != null && args.updateData != null) {
        form2.add(addNext);
      }
      //form2.add(addNext);
    }

        return Scaffold(
            appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.addInformation),
            ),
            body: SingleChildScrollView(
                child: Form(
                    key: _formKey,
                    child: Column(
                        //crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            ...form2,
                            Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                        ElevatedButton(
                                            onPressed: (){
                                                //savePreferencesOnlyGreen(truthSwitch.existingG);

                                                laiProvider.laiValue = 0;
                                                var lastUpdate =
                                                        DateTime.now().millisecondsSinceEpoch ~/ 1000;
                                                if (_formKey.currentState!.validate()) {
                                                    existingG = truthSwitch.existingG;
                                                    _formKey.currentState!.save();
                                                    if (args.updateData != null || args.addPolygonData != null) {
                                                        db.Project.setStatus(idProject, 3);
                                                        gProvider.getProjects();
                                                        gProvider.project!.status = 3;
                                                    }
                                                    switch (type) {
                                                        case en.EditorType.point:
                                                            print('update point');
                                                            var tree = db.Point(
                                                                id: idGeometry,
                                                                idProject: idProject,
                                                                idUser: idUser,
                                                                lastUpdate: lastUpdate,
                                                                idSpecies: idSpecies,
                                                                diameter: diameter,
                                                                height: height,
                                                                crownHeight: crownHeight,
                                                                crownDiameter: crownDiameter,
                                                                lai: lai,
                                                                truth: truthSwitch.existingG ? 1 : 0,
                                                                latlng: LatLng(coords[0].latitude,
                                                                    coords[0].longitude),
                                                            );
                                                            if (args.updateData != null) {
                                                                tree.dbTableUpdate();
                                                            }
                                                            Navigator.pop(context, tree);
                                                            break;
                                                        case en.EditorType.line:
                                                            var row = db.Line(
                                                                id: idGeometry,
                                                                idProject: idProject,
                                                                idUser: idUser,
                                                                lastUpdate: lastUpdate,
                                                                idSpecies: idSpecies,
                                                                diameter: diameter,
                                                                height: height,
                                                                crownHeight: crownHeight,
                                                                crownDiameter: crownDiameter,
                                                                lai: lai,
                                                                truth: truthSwitch.existingG ? 1 : 0,
                                                                treeNumber: treeNumber,
                                                                coords: coords,
                                                            );
                                                            if (args.updateData != null) {
                                                                row.dbTableUpdate();
                                                                print('update row');

                                                            }
                                                            Navigator.pop(context, row);
                                                            break;
                                                        case en.EditorType.polygon:
                                                            String id;
                                                            if (args.updateData != null) {
                                                                id = idPolygonData;
                                                            } else {
                                                                id = ObjectId().hexString;
                                                            }

                                                            var forestSpecies1 = db.PolygonData(
                                                                id: id,
                                                                idGeometry: idGeometry,
                                                                idProject: idProject,
                                                                idUser: idUser,
                                                                lastUpdate: lastUpdate,
                                                                idSpecies: idSpecies,
                                                                diameter: diameter,
                                                                height: height,
                                                                crownHeight: crownHeight,
                                                                crownDiameter: crownDiameter,
                                                                lai: lai,
                                                                truth: truthSwitch.existingG ? 1 : 0,
                                                                percentCover: canopyCover,
                                                                percentArea: percentArea,
                                                                area: area,
                                                                //coords: widget.coords,
                                                            );
                                                            var nextMaxAreaPercent =
                                                                    maxAreaPercent - percentArea;
                                                            //var nextInput = false;
                                                            var out = {
                                                                'data': forestSpecies1,
                                                                'nextMaxAreaPercent': nextMaxAreaPercent,
                                                                'nextInput': addNext.truth,
                                                            };
                                                            if (args.updateData != null) {
                                                                forestSpecies1.dbTableUpdate();
                                                            }
                                                            if (args.addPolygonData != null) {
                                                                forestSpecies1.dbInsert();
                                                            }
                                                            Navigator.pop(context, out);
                                                            break;
                                                        default:
                                                            break;
                                                    }
                                                }
                                            },
                                style: ElevatedButton.styleFrom(
                                           foregroundColor: Colors.black,
                                           // backgroundColor: Colors.red, // Background color
                                       ),
                                child: const Text('Submit'),
                                ),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                       // backgroundColor: Colors.red, // Background color
                                    ),
                                    onPressed: () {
                                        // TODO: clear form
                                        laiProvider.laiValue = 0;
                                        Navigator.pop(context, null);

                                    },
                                    child: const Text('Cancel'),
                                ),
                                ],
                                ),
                                ),
                                ]
                                        .map((widget) => Padding(
                                                padding: const EdgeInsets.all(5),
                                                child: widget,
                                        ))
                                        .toList(),
                                ),
                                )));
    }
}

// create a form widget for the project
class MyCustomFormProject extends StatefulWidget {
    const MyCustomFormProject({super.key, required this.idUser, this.project});
    final String idUser;
    final dat.Project? project;

    @override
    MyCustomFormProjectState createState() {
        return MyCustomFormProjectState();
    }
}

class MyCustomFormProjectState extends State<MyCustomFormProject> {
    final _formKey = GlobalKey<FormState>();
    int soilTextureId = 1;
    bool privateProject = false;
    bool irrigation = false;

    int yearStart = 2021;
    int yearEnd = 2022;
    int selectedYear = 2022;
    String name = "";
    String location = "";
    String description = "";

    int status = 0;
    double lat = 0;
    double lon = 0;

    @override
    Widget build(BuildContext context) {
        final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
        final loc = AppLocalizations.of(context)!;
        const textStyle = TextStyle(color: Colors.black);
        String titleScaffold = widget.project == null
                ? AppLocalizations.of(context)!.addNewProject
                : "${loc.infoPrj} ${widget.project!.idProject}";
        if (widget.project != null) {
            final project = widget.project;
            name = project!.name;
            final dateStart = DateTime.fromMillisecondsSinceEpoch(project!.startDate * 1000, isUtc: true);
            selectedYear = dateStart.year;
            location       = project.location;
            description    = project.description;
            privateProject = project.privateProject == 1;
            irrigation     = project.irrigation     == 1;
            soilTextureId  = project.idSoilTexture;
            status         = project.status;
            lat            = project.lat;
            lon           = project.lon;
        }

        // Build a Form widget using the _formKey created above.

        // variables set in the form
        //int lastUpdate;
        //int startDate;
        //int endDate;

        var switchPrivateProject = TruthSwitch(
            truth: privateProject,
            widgetText: ""); //AppLocalizations.of(context)!.private);
        var switchIrrigation = TruthSwitch(
            truth: irrigation,
            widgetText: ""); //AppLocalizations.of(context)!.irrigated

        // soil dictionary
        var textureItems =
        getDropdownTexture(AppLocalizations.of(context)!.soilLanguage);

        // add year items the years in the range yearStart2 to yearEnd2
        final yearItems = List.generate(yearEnd - yearStart + 1, (index) {
            return DropdownMenuItem(
                value: yearStart + index,
                child: Text((yearStart + index).toString()),
            );
        });

        final dropdownYear = DropdownButton<int>(
            value: selectedYear,
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
                    selectedYear = value!;
                    if (widget.project != null) {
                        var startDate = DateTime.utc(selectedYear, 1).millisecondsSinceEpoch ~/ 1000;
                        var endDate = DateTime.utc(selectedYear, 13).millisecondsSinceEpoch ~/ 1000;
                        widget.project!.startDate = startDate;
                        widget.project!.endDate = endDate;
                    }
                });
            },
            items: yearItems,
        );
        final textureButton =  DropdownButton(
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.blue),
            underline: Container(
                height: 2,
                color: Colors.blue,
            ),
            value: soilTextureId,
            onChanged: (int? newValue) {
                setState(() {
                    privateProject = switchPrivateProject.truth;
                    irrigation = switchIrrigation.truth;
                    soilTextureId = newValue!;
                    if (widget.project != null) {
                        widget.project!.idSoilTexture = newValue;
                    }
                });
            },
            items: textureItems);


        final deleteProject = Visibility(
            visible: widget.project != null,
            child:
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Text(
                        AppLocalizations.of(context)!.deleteProject,
                        style: const TextStyle(color: Colors.red, fontSize: 17.0),
                    ),
                    // DELETE PROJECT
                    InkWell(
                        onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('long press to delete project'),
                                    duration: Duration(seconds: 4),
                                ),
                            );
                        },
                        onLongPress: () {
                            db.Project.dbDelete(widget.project!.idProject);
                            setState(() {
                                gProvider.getProjects();
                            });
                            Navigator.pop(context);
                        },
                        child: Icon(MdiIcons.delete, size: 30.0, color: Colors.red),
                    ),
                    ]));


        const spacer = TableRow(
            children: [
                SizedBox(height: 8),
                SizedBox(height: 8),
                SizedBox(height: 8),
            ]
        );
        final tableWidget = Table(
            columnWidths: const {
                0: FlexColumnWidth(60),
                1: FlexColumnWidth(25),
                2: FlexColumnWidth(15),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
                TableRow(
                    children: [
                        Text(loc.yearSimulation),
                        dropdownYear,
                        getInfoButton(loc.yearSimulationHelp),
                    ]
                ),
                spacer,
                TableRow(
                    children: [
                        Text(loc.soilTexture),
                        textureButton,
                        getInfoButton(loc.textureHelp),
                    ]
                ),
                spacer,
                TableRow(
                    children: [
                        Text(loc.private),
                        switchPrivateProject,
                        getInfoButton(loc.privateHelp),
                    ]
                ),
                spacer,
                TableRow(
                    children: [
                        Text(loc.irrigated),
                        switchIrrigation,
                        getInfoButton(loc.irrigatedHelp),
                    ]
                ),
            ]
        );



        return Scaffold(
            appBar: AppBar(
                title: Text(
                    titleScaffold,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17.0,
                    ),
                ),
            ),

            body: SingleChildScrollView(
                child: Form(
                    key: _formKey,
                    child: Column(
                        //crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            deleteProject,
                            TextFormField(
                                initialValue: name,
                                decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.nameProject,
                                    suffixIcon: Tooltip(
                                        showDuration: tooltipDuration,
                                        triggerMode: TooltipTriggerMode.tap,
                                        preferBelow: false,
                                        verticalOffset: -15,
                                        margin: EdgeInsets.fromLTRB(30, 0, 30, 0),
                                        message: AppLocalizations.of(context)!.nameProjectHelp,
                                        child: const Icon(Icons.info)
                                    )),
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enterText;
                    }
                                    return null;
                                },
                                onSaved: (String? value) {
                                    name = value!;
                                }),
                            TextFormField(
                                initialValue: location,
                                decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.location,
                                    suffixIcon: Tooltip(
                                        showDuration: tooltipDuration,
                                        triggerMode: TooltipTriggerMode.tap,
                                        preferBelow: false,
                                        verticalOffset: -15,
                                        margin: EdgeInsets.fromLTRB(30, 0, 30, 0),
                                        message: AppLocalizations.of(context)!.locationHelp,
                                        child: const Icon(Icons.info)
                                    )),
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enterText;
                    }
                                    return null;
                                },
                                onSaved: (String? value) {
                                    location = value!;
                                }),
                            TextFormField(
                                initialValue: description,
                                decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.descr,
                                    suffixIcon: Tooltip(
                                        showDuration: tooltipDuration,
                                        triggerMode: TooltipTriggerMode.tap,
                                        preferBelow: false,
                                        verticalOffset: -15,
                                        margin: EdgeInsets.fromLTRB(30, 0, 30, 0),
                                        message: AppLocalizations.of(context)!.descr,
                                        child: const Icon(Icons.info)
                                    ),
                                ),
                                validator: (value) {
                                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enterText;
                    }
                                    return null;
                                },
                                onSaved: (String? value) {
                                    description = value!;
                                }),
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 0),
                            ),
                            tableWidget,
                            Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                        ElevatedButton(
                                            onPressed: () {
                                                if (_formKey.currentState!.validate()) {
                                                    _formKey.currentState!.save();
                                                    String id;
                                                    int hasData = 0;
                                                    if (widget.project != null) {
                                                        id = widget.project!.idProject;
                                                        hasData = widget.project!.hasData;
                                                    } else {
                                                        id = ObjectId().hexString;
                                                    }
                                                    var lastUpdate =
                                                            DateTime.now().millisecondsSinceEpoch ~/ 1000;
                                                    var startDate = DateTime.utc(selectedYear, 1).millisecondsSinceEpoch ~/ 1000;
                                                    var endDate = DateTime.utc(selectedYear, 13).millisecondsSinceEpoch ~/ 1000;
                                                    var project = dat.Project(
                                                        idProject: id,
                                                        idUser: widget.idUser,
                                                        lastUpdate: lastUpdate,
                                                        name: name,
                                                        location: location,
                                                        description: description,
                                                        startDate: startDate,
                                                        endDate: endDate,
                                                        privateProject: switchPrivateProject.truth ? 1 : 0,
                                                        irrigation: switchIrrigation.truth ? 1 : 0,
                                                        status: status,
                                                        lat: lat,
                                                        lon: lon,
                                                        idSoilTexture: soilTextureId,
                                                        hasData: hasData,
                                                    );
                                                    if (widget.project != null) {
                                                        db.Project.updateData(
                                                            project
                                                        );
                                                        setState(() {
                                                            gProvider.getProjects();
                                                        });
                                                        Navigator.pop(context);

                                                    } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                            content: Text(loc.insertGreen),
                                                            duration: const Duration(seconds: 12),
                                                            // semitrasparent colout
                                                            backgroundColor: Colors.black.withOpacity(0.5),

                                                        ),
                                                    );
                                                    Navigator.pop(context, project);
                                                    }
                                                }
                                            },
                                child: Text(
                                           AppLocalizations.of(context)!.submit,
                                           style: textStyle,
                                       ),
                                ),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        //backgroundColor: Colors.red, // Background color
                                    ),
                                    onPressed: () {
                                        // TODO: clear form
                                        Navigator.pop(context, null);
                                    },
                                    child: Text(
                                               AppLocalizations.of(context)!.cancel,
                                               style: textStyle,
                                           ),
                                ),
                                ],
                                ),
                                ),
                                ]
                                        .map((widget) => Padding(
                                                padding: const EdgeInsets.all(5),
                                                child: widget,
                                        ))
                                        .toList(),
                                ),
                                )));
    }
}

class NumericalRangeFormatter extends TextInputFormatter {
    final double min;
    final double max;
    final en.NumberType type;
    String minString = "";
    String maxString = "";

    NumericalRangeFormatter(
    {required this.min, required this.max, required this.type}) {
        switch (type) {
            case en.NumberType.integer:
                minString = min.toStringAsFixed(0);
                maxString = max.toStringAsFixed(0);
                break;
            default:
                minString = min.toStringAsFixed(2);
                maxString = max.toStringAsFixed(2);
                break;
        }
    }

    @override
    TextEditingValue formatEditUpdate(
        TextEditingValue oldValue,
        TextEditingValue newValue,
    ) {
        var value = newValue.text;
        if (value == '') {
            return newValue;
        }
        if (value.contains(',')) {
            value = value.replaceAll(',', '.');
      }


        if (double.parse(value) < min) {
            return const TextEditingValue().copyWith(text: minString);
        } else if (double.parse(value) > max) {
            return const TextEditingValue().copyWith(text: maxString);
        } else {
            return const TextEditingValue().copyWith(text: value);
        }
    }
}




