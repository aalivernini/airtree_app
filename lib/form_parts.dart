import 'package:flutter/material.dart'; //import 'package:flutter/services.dart';

String? validateNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a number';
  }
  if (value.contains(',')) {
    value = value.replaceAll(',', '.');
    print('value: $value');
  }
  try {
    double.parse(value);
  } on FormatException {
    return 'Please enter a number';
  }
  return null;
}

// ----------------------------------------------------------------------------
// Simple service to provide species suggestions
// ----------------------------------------------------------------------------
class SpeciesService {
  final List<String> species2;
  SpeciesService(this.species2);
  List<String> getSuggestions(String query) {
    List<String> matches = <String>[];

    matches.addAll(species2);

    matches.retainWhere((s) => s.toLowerCase().contains(query.toLowerCase()));
    return matches;
  }
}

// ----------------------------------------------------------------------------
// Switch for green data input
// ----------------------------------------------------------------------------
class TruthSwitch extends StatefulWidget {
  bool truth;
  String widgetText;

  TruthSwitch({
    super.key,
    // super.key,
    required this.truth,
    required this.widgetText,
  });

  @override
  State<TruthSwitch> createState() => _TruthSwitchState();
}

class _TruthSwitchState extends State<TruthSwitch> {
  final MaterialStateProperty<Icon?> thumbIcon =
  MaterialStateProperty.resolveWith<Icon?>(
        (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                  widget.widgetText,
                  softWrap: true,

              ),
              Switch(
                value: widget.truth,
                activeColor: Colors.blue,
                onChanged: (bool value) {
                  setState(() {
                    widget.truth = value;
                  });
                },
              ),
            ]),
      ],
    );
  }
}


// ----------------------------------------------------------------------------
// Switch for green data input
// ----------------------------------------------------------------------------
class TruthSwitch2 extends StatefulWidget {
    bool existingG;
    String widgetText;

    TruthSwitch2({
        super.key,
        // super.key,
        required this.existingG,
        required this.widgetText,
    });

    @override
    State<TruthSwitch2> createState() => _TruthSwitchState2();
}

class _TruthSwitchState2 extends State<TruthSwitch2> {
    final MaterialStateProperty<Icon?> thumbIcon =
            MaterialStateProperty.resolveWith<Icon?>(
                (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                        return const Icon(Icons.check);
                    }
                    return const Icon(Icons.close);
                },
            );

    @override
    Widget build(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text(
                            widget.widgetText,
                            softWrap: true,
                        ),
                        Switch(
                            value: widget.existingG,
                            activeColor: Colors.blue,

                            onChanged:  (bool value){
                                setState(() {
                                    widget.existingG = value;
                                });
                            },
                        ),
                    ]),
            ],
        );
    }
}
// ----------------------------------------------------------------------------
// Switches for project input
// ----------------------------------------------------------------------------
//class PrjSwitch extends StatefulWidget {
//    bool privateProject ;
//    bool irrigation     ;
//
//    PrjSwitch({
//        super.key,
//        required this.privateProject,
//        required this.irrigation,
//    });
//
//
//    @override
//    State<PrjSwitch> createState() => _PrjSwitchState();
//}
//
//class _PrjSwitchState extends State<PrjSwitch> {
//
//    final MaterialStateProperty<Icon?> thumbIcon =
//            MaterialStateProperty.resolveWith<Icon?>(
//                (Set<MaterialState> states) {
//                    if (states.contains(MaterialState.selected)) {
//                        return const Icon(Icons.check);
//                    }
//                    return const Icon(Icons.close);
//                },
//            );
//
//
//    @override
//    Widget build(BuildContext context) {
//        return Column(
//            mainAxisAlignment: MainAxisAlignment.center,
//            children: <Widget>[
//                Row(
//                    //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                    children: [
//                        const Text('Private project'),
//                        Switch(
//                            value: widget.privateProject,
//                            onChanged: (bool value) {
//                                setState(() {
//                                    widget.privateProject = value;
//                                });
//                            },
//                        ),
//                    ]),
//                Row(
//                    //mainAxisAlignment: MainAxisAlignment.center,
//                    children: [
//                        const Text('Irrigation'),
//                        Switch(
//                            thumbIcon: thumbIcon,
//                            value: widget.irrigation,
//                            onChanged: (bool value) {
//                                setState(() {
//                                    widget.irrigation = value;
//                                });
//                            },
//                        ),
//                    ],
//                )]);}
//}
