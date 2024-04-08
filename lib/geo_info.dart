/// Info classes for geo.UniqueMarker
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data.dart' as dat;
import 'providers.dart' as pr;
import 'enums.dart' as en;
import 'database.dart' as db;
import 'dart:math';
import 'chart.dart' as cha;
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

double log10(num x) => x == 0 ? 0 : log(x) / ln10;

abstract class InfoGreen {
  List<List<String>> getFields(Map<int, dat.ParamRow> mapInt);

  // get a list combining fields and values and converting them to Text
  List<TableRow> getTableRows(en.EditorType type, Map<int, dat.ParamRow> mapInt,
      {int? patchNumber, int? patchIndex}) {
    String header;
    switch (type) {
      case en.EditorType.point:
        header = "Tree";
        break;
      case en.EditorType.line:
        header = 'Tree row';
        break;
      case en.EditorType.polygon:
        if (patchNumber != null && patchIndex != null) {
          header = 'Forest - zone $patchIndex/$patchNumber';
        } else {
          header = 'Patch';
        }
        break;
      default:
        header = 'Unknown';
    }

    final List<TableRow> fieldsAndValues = [];
    var fields = getFields(mapInt);
    fieldsAndValues.add(TableRow(
      decoration: const BoxDecoration(color: Colors.blue),
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(header,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
        const Text('')
      ],
    ));

    for (int i = 0; i < fields.length; i++) {
      fieldsAndValues
          .add(TableRow(children: [Text(fields[i][0]), Text(fields[i][1])]));
    }
    return fieldsAndValues;
  }
}

class Value {
  final String unit;
  final double value;
  const Value(this.unit, this.value);
}

abstract class Measure {
  abstract Map<String, double> reference;
  Value get(double value, {String? unit});
}

class Area implements Measure {
  @override
  final reference = {
    'm\u00B2': 1, // m2
    'ha': 0.0001, // ha
    'km\u00B2': 0.000001, // km2
  };

  @override
  set reference(Map<String, double> newReference) => reference = newReference;

  @override
  Value get(double value, {String? unit}) {
    int vl = log10(value).round();
    String u;
    if (unit != null) {
      u = unit;
    } else {
      if (vl <= 3) {
        u = 'm\u00B2';
      } else if (vl <= 6) {
        u = 'ha';
      } else {
        u = 'km\u00B2';
      }
    }
    return Value(u, value * reference[u]!);
  }
}

class Weight implements Measure {
  @override
  final reference = {
    'ng': 1000000000,
    'ug': 1000000,
    'mg': 1000,
    'g': 1,
    'kg': 0.001,
    't': 0.000001,
  };

  @override
  set reference(Map<String, double> newReference) => reference = newReference;

  @override
  Value get(double value, {String? unit}) {
    // get log10 of value
    //double vl = value == 0 ? 0 : log10(value);
    int sign = 1;
    if (value < 0) {
      sign = -1;
      value = value.abs();
    }
    int vl = log10(value).round();
    String u;
    if (unit != null) {
      u = unit;
    } else {
      if (vl <= -7) {
        u = 'ng';
      } else if (vl <= -4) {
        u = 'ug';
      } else if (vl <= -1) {
        u = 'mg';
      } else if (vl <= 2) {
        u = 'g';
      } else if (vl <= 5) {
        u = 'kg';
      } else {
        u = 't';
      }
    }
    return Value(u, sign * value * reference[u]!);
  }

  List<Value> getArray(List<double> values) {
    double maxValue = values.reduce(max);
    Value vl = get(maxValue);
    final List<Value> result = [];
    for (var value in values) {
      result.add(get(value, unit: vl.unit));
    }
    return result;
  }
}

// https://stackoverflow.com/questions/54254516/how-can-we-use-superscript-and-subscript-text-in-flutter-text-or-richtext
class InfoResult {
  final db.Result rs; // result
  String unitArray = '';
  String nameArray = '';

  InfoResult({
    required this.rs,
  });

  // get a list combining fields and values and converting them to Text
  @override
  List<TableRow> getTableRows(Map<int, dat.ParamRow> mapInt, String locale) {
    //String header;

    final List<TableRow> fieldsAndValues = [];
    var total = false;
    if (rs.idSpecies == -1) {
      //header = 'Total';
      total = true;
    } else {
      //header = 'unknown';
    }
    var strName = 'Name';
    var strUnit = 'Unit';
    var strValue = 'Value';
    if (locale != 'en') {
      strName = 'Nome';
      strUnit = 'Unità';
      strValue = 'Valore';
    }
    var fields = getFields(mapInt, locale);
    fieldsAndValues.add(TableRow(
      decoration: const BoxDecoration(color: Colors.blue),
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(strName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
        Text(strUnit,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(strValue,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center)
      ],
    ));

    for (int i = 0; i < fields.length; i++) {
      fieldsAndValues.add(TableRow(children: [
        Text(fields[i][0]),
        Text(fields[i][1]),
        Text(fields[i][2], textAlign: TextAlign.right)
      ]));
    }
    return fieldsAndValues;
  }

  @override
  List<List<String>> getFields(
      Map<int, dat.ParamRow> mapInt,
      String locale,
      {bool total = false}
  ) {
    List<List<String>> out = [];
    var strSpecies = 'Species';
    var strCanopyArea = 'Canopy area';
    if (locale != 'en') {
      strSpecies = 'Specie';
      strCanopyArea = 'Area chiome';
    }


    if (total) {
      var speciesName = mapInt[rs.idSpecies]!.name;
      speciesName ??= 'unknown';
      out.add([strSpecies, speciesName]);
    }
    final ar = Area();
    final we = Weight();
    final area = ar.get(rs.canopyArea);
    final npp = we.get(rs.npp);
    final o3 = we.get(rs.o3);
    final pm1 = we.get(rs.pm1);
    final pm25 = we.get(rs.pm25);
    final pm10 = we.get(rs.pm10);
    final no2 = we.get(rs.no2);
    final so2 = we.get(rs.so2);
    final co = we.get(rs.co);
    return out +
        [
          [strCanopyArea, (area.unit), area.value.toStringAsFixed(2)],
          ['NPP', '${npp.unit} C', npp.value.toStringAsFixed(2)],
          ['O\u2083', (o3.unit), o3.value.toStringAsFixed(2)],
          ['PM\u2081', (pm1.unit), pm1.value.toStringAsFixed(2)],
          ['PM\u2082\u2085', (pm25.unit), pm25.value.toStringAsFixed(2)],
          ['PM\u2081\u2080', (pm10.unit), pm10.value.toStringAsFixed(2)],
          ['NO\u2082', (no2.unit), no2.value.toStringAsFixed(2)],
          ['SO\u2082', (so2.unit), so2.value.toStringAsFixed(2)],
          ['CO', (so2.unit), co.value.toStringAsFixed(2)],
        ];
  }

  List<String> getGraphDate2(int timeStart, int timeEnd, String locale) {
    final startMillis = timeStart * 1000;
    final endMillis = timeEnd * 1000;
    final DateFormat formatter = DateFormat('MMM\nyyyy', locale);
    List<String> date2s = [];
    var millis = startMillis;
    while (millis <= endMillis) {
      final date = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
      date2s.add(formatter.format(date));
      millis = DateTime.utc(date.year, date.month + 1, date.day)
          .toUtc()
          .millisecondsSinceEpoch;
    }
    return date2s;
  }

  Widget getGraph(int pollutantId, String locale) {
    List<int> timeInt = rs.tsxtime;
    List<String> date2s =
        getGraphDate2(timeInt[0], timeInt[timeInt.length - 1],locale);
    final time = List<double>.generate(date2s.length, (int index) => index + 0);
    List<double> pollutantValues;

    switch (pollutantId) {
      case 1:
        pollutantValues = rs.tsxnpp;
        nameArray = 'NPP';
        break;
      case 2:
        pollutantValues = rs.tsxo3;
        nameArray = 'O\u2083';
        break;
      case 3:
        pollutantValues = rs.tsxpm1;
        nameArray = 'PM\u2081';
        break;
      case 4:
        pollutantValues = rs.tsxpm25;
        nameArray = 'PM\u2082\u2085';
        break;
      case 5:
        pollutantValues = rs.tsxpm10;
        nameArray = 'PM\u2081\u2080';
        break;
      case 6:
        pollutantValues = rs.tsxno2;
        nameArray = 'NO\u2082';
        break;
      case 7:
        pollutantValues = rs.tsxso2;
        nameArray = 'SO\u2082';
        break;
      case 8:
        pollutantValues = rs.tsxco;
        nameArray = 'CO';
        break;
      default:
        pollutantValues = rs.tsxnpp;
        nameArray = 'NPP';
        break;
    }
    final we = Weight();
    List<Value> values = we.getArray(pollutantValues);
    unitArray = values[0].unit;
    pollutantValues = values.map((e) => e.value).toList();
    double maxValue = pollutantValues.reduce(max);
    maxValue = maxValue + (maxValue * 0.1);
    double minValue = pollutantValues.reduce(min) - 0.5;
    List<cha.GraphPoint> graphPt2 = [];
    if (minValue > 0) {
      minValue = 0;
    }
    for (int i = 0; i < pollutantValues.length; i++) {
      graphPt2.add(cha.GraphPoint(x: time[i], y: pollutantValues[i]));
    }
    return cha.LineChartWidget(graphPt2, maxValue, minValue, date2s);
  }
}

class InfoPoint extends InfoGreen {
  en.EditorType type = en.EditorType.point;
  final db.Point pnt;

  InfoPoint({
    required this.pnt,
  });

  void delete(BuildContext context) {
    final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
    mProvider.deletePoint(pnt.id);
    pnt.dbDelete();
  }

  @override
  List<List<String>> getFields(Map<int, dat.ParamRow> mapInt) {
    var speciesName = mapInt[pnt.idSpecies]!.name;
    String truthString = pnt.truth == 1 ? 'vegetation' : 'green design';
    speciesName ??= 'unknown';

    return [
      ['species', speciesName],
      ['diameter (cm)', pnt.diameter.toString()],
      ['tree height (m)', pnt.height.toString()],
      ['crown height (m)', pnt.crownHeight.toString()],
      ['crown diameter (m)', pnt.crownDiameter.toString()],
      ['leaf area index', pnt.lai.toString()],
      ['type', truthString],
    ];
  }
}

class InfoLine extends InfoGreen {
  en.EditorType type = en.EditorType.line;
  final db.Line line;

  InfoLine({
    required this.line,
  });

  void delete(BuildContext context) {
    final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
    line.dbDelete();
    mProvider.deleteLine(line.id);
  }

  @override
  List<List<String>> getFields(Map<int, dat.ParamRow> mapInt) {
    var speciesName = mapInt[line.idSpecies]!.name;
    String truthString = line.truth == 1 ? 'vegetation' : 'green design';
    speciesName ??= 'unknown';
    return [
      ['species', speciesName],
      ['diameter (cm)', line.diameter.toString()],
      ['tree height (m)', line.height.toString()],
      ['crown height (m)', line.crownHeight.toString()],
      ['crown diameter (m)', line.crownDiameter.toString()],
      ['leaf area index', line.lai.toString()],
      ['type', truthString],
      ['tree number', line.treeNumber.toString()],
      ['length (m)', line.length.toStringAsFixed(0)],
    ];
  }
}

class InfoElementPolygon extends InfoGreen {
  en.EditorType type = en.EditorType.polygon;

  final db.PolygonData polData;

  InfoElementPolygon({
    required this.polData,
  });

  @override
  List<List<String>> getFields(Map<int, dat.ParamRow> mapInt) {
    final ar = Area();
    final area = ar.get(polData.area);
    var speciesName = mapInt[polData.idSpecies]!.name;
    String truthString = polData.truth == 1 ? 'vegetation' : 'green design';
    speciesName ??= 'unknown';
    return [
      ['species', speciesName],
      ['diameter (cm)', polData.diameter.toString()],
      ['tree height (m)', polData.height.toString()],
      ['crown height (m)', polData.crownHeight.toString()],
      ['crown diameter (m)', polData.crownDiameter.toString()],
      ['leaf area index', polData.lai.toString()],
      ['type', truthString],
      ['forest area (${area.unit})', area.value.toStringAsFixed(2)],
      ['zone percent area (%)', polData.percentArea.toString()],
      ['zone canopy cover (%)', polData.percentCover.toString()],
    ];
  }
}

class InfoPolygon {
  final String id;
  final List<InfoElementPolygon> element2;
  int indexElement = 0;

  InfoPolygon({
    required this.id,
    required this.element2,
  });

  @override
  void delete(BuildContext context) {
    final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
    // get PolygonGeometry from provider and delete it in the database (both data and geometry)
    var pol = mProvider.forest2.firstWhere((p) => p.polygonGeometry.id == id);
    pol.polygonGeometry.dbDelete();
    for (var element in element2) {
      element.polData.dbDelete();
    }
    // update the provider
    mProvider.deletePolygon(id);
  }

  List<TableRow> getTableRows(
    Map<int, dat.ParamRow> mapInt,
  ) {
    return element2[indexElement].getTableRows(en.EditorType.polygon, mapInt,
        patchNumber: element2.length, patchIndex: indexElement + 1);
  }
}
