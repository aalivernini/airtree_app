//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;

//import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:flutter_map_line_editor/flutter_map_line_editor.dart';

import 'data.dart' as dat;
import 'database.dart' as db;
import 'enums.dart';
import 'geo.dart' as geo;
import 'geo_info.dart' as gi;
import 'icon.dart' as ic;
import 'io.dart' as io;
import 'package:intl/intl.dart';

class ResultProvider extends ChangeNotifier {
  String result = '';
  int dropdownItemId = -2;
  int pollutantId = 1;
  bool ready = false;

  // temporary storage
  Map<String, db.Result> result4id = {};
  Map<int, db.Result> result4species = {};
  db.Result? resultTotal;

  // widget storage
  Map<String, gi.InfoResult> infoResult4id = {};
  Map<int, gi.InfoResult> infoResult4species = {};
  gi.InfoResult? infoResultTotal;
  Map<int, String> id2species = {};

  void reset() {
    result = '';
    dropdownItemId = -2;
    pollutantId = 1;
    ready = false;
    infoResult4id.clear();
    infoResult4species.clear();
    infoResultTotal = null;
    id2species.clear();
    notifyListeners();
  }

  String getPeriod(String locale) {
    String out = '';
    if (infoResultTotal == null) {
      return out;
    }
    final result = infoResultTotal!.rs;
    final startMillis = result.startDate * 1000;
    final endMillis = result.endDate * 1000;
    final DateFormat formatter = DateFormat('MMMM yyyy', locale);
    final dateStart =
        DateTime.fromMillisecondsSinceEpoch(startMillis, isUtc: true);
    final dateEnd1 = DateTime.fromMillisecondsSinceEpoch(endMillis,
        isUtc: true); // the date is 1 day after the actual end date
    final dateEnd = dateEnd1.subtract(const Duration(days: 1));
    final string0 = locale == 'en' ? 'Period:' : 'Periodo:';
    out =
        '$string0 ${formatter.format(dateStart)} - ${formatter.format(dateEnd)}';
    return out;
  }

  //set ready
  void setReady(bool r) {
    ready = r;
    notifyListeners();
  }

  void setPollutantId(int id) {
    pollutantId = id;
    notifyListeners();
  }

  void setDropdownItemId(int id) {
    dropdownItemId = id;
    notifyListeners();
  }

  Future<String> sendProject(String idProject) async {
    result = await io.sendProject(idProject);
    notifyListeners();
    return result;
  }

  void setResult4id(Map<String, dynamic> result) {
    //Map<String, db.Result> out3 = {};
    final data = result['data'];
    data.forEach((dict) {
      final r1 = db.Result(
        idUser: result['id_user'],
        idProject: result['id_project'],
        idSpecies: dict['id_species'],
        id: dict['id'],
        startDate: result['start_date'],
        endDate: result['end_date'],
        lastUpdate: result['last_update'],
        npp: dict['total']['NPP'],
        o3: dict['total']['O3'],
        pm1: dict['total']['PM1'],
        pm10: dict['total']['PM10'],
        pm25: dict['total']['PM2_5'],
        no2: dict['total']['NO2'],
        so2: dict['total']['SO2'],
        co: dict['total']['CO'],
        canopyArea: dict['canopy_area'],
        tsxnpp: List<double>.from(dict['time_series']['NPP']),
        tsxo3: List<double>.from(dict['time_series']['O3']),
        tsxpm1: List<double>.from(dict['time_series']['PM1']),
        tsxpm10: List<double>.from(dict['time_series']['PM10']),
        tsxpm25: List<double>.from(dict['time_series']['PM2_5']),
        tsxno2: List<double>.from(dict['time_series']['NO2']),
        tsxso2: List<double>.from(dict['time_series']['SO2']),
        tsxco: List<double>.from(dict['time_series']['CO']),
        tsxtime: List<int>.from(dict['time_series']['time']),
      );
      result4id[dict['id']] = r1;
    });
  }

  void setAggregatedResults() {
    result4species.clear();

    //GET AGGREGATED RESULT FOR SPECIES  (ID == -1)
    Set<int> idSpecies2 = {};
    result4id.forEach((key, r1) {
      idSpecies2.add(r1.idSpecies);
    });
    final oneResultKey = result4id.keys.toList().first;
    final one = result4id[oneResultKey];
    if (one == null) {
      return;
    }

    final oneArrLength = one.tsxnpp.length;
    for (var idSpecies in idSpecies2) {
      result4species[idSpecies] = db.Result(
          idUser: one.idUser,
          idProject: one.idProject,
          idSpecies: idSpecies,
          id: '-1',
          startDate: one.startDate,
          endDate: one.endDate,
          lastUpdate: one.lastUpdate,
          npp: 0.0,
          o3: 0.0,
          pm1: 0.0,
          pm10: 0.0,
          pm25: 0.0,
          no2: 0.0,
          so2: 0.0,
          co: 0.0,
          canopyArea: 0.0,
          tsxnpp: List.filled(oneArrLength, 0.0),
          tsxo3: List.filled(oneArrLength, 0.0),
          tsxpm1: List.filled(oneArrLength, 0.0),
          tsxpm10: List.filled(oneArrLength, 0.0),
          tsxpm25: List.filled(oneArrLength, 0.0),
          tsxno2: List.filled(oneArrLength, 0.0),
          tsxso2: List.filled(oneArrLength, 0.0),
          tsxco: List.filled(oneArrLength, 0.0),
          tsxtime: one.tsxtime);
    }
    // iterate over result3 and add values to resultSpecies3
    result4id.forEach((key, r1a) {
      final idSpecies = r1a.idSpecies;
      final r1b = result4species[idSpecies];
      if (r1b != null) {
        final newResult = r1b.add(r1a);
        result4species[idSpecies] = newResult;
      }
    });

    // GET TOTALS  (IDSPECIES == -1; ID == -2)
    resultTotal = db.Result(
        idUser: one.idUser,
        idProject: one.idProject,
        idSpecies: -1,
        id: '-2',
        startDate: one.startDate,
        endDate: one.endDate,
        lastUpdate: one.lastUpdate,
        npp: 0.0,
        o3: 0.0,
        pm1: 0.0,
        pm10: 0.0,
        pm25: 0.0,
        no2: 0.0,
        so2: 0.0,
        co: 0.0,
        canopyArea: 0.0,
        tsxnpp: List.filled(oneArrLength, 0.0),
        tsxo3: List.filled(oneArrLength, 0.0),
        tsxpm1: List.filled(oneArrLength, 0.0),
        tsxpm10: List.filled(oneArrLength, 0.0),
        tsxpm25: List.filled(oneArrLength, 0.0),
        tsxno2: List.filled(oneArrLength, 0.0),
        tsxso2: List.filled(oneArrLength, 0.0),
        tsxco: List.filled(oneArrLength, 0.0),
        tsxtime: one.tsxtime);

    // update flutter_map widgets
    for (var resSpecies1 in result4species.values) {
      resultTotal = resultTotal!.add(resSpecies1);
    }
  }

  Future<int> getResultFromDb(String idProject) async {
    id2species.clear();
    infoResult4id.clear();
    infoResult4species.clear();
    infoResultTotal = null;

    final result2 = await db.Project.getResult2(idProject);
    final id2Param = await dat.Param.getMapId();
    for (var r in result2) {
      final result = db.Result(
        idUser: r['id_user'],
        idProject: r['id_project'],
        idSpecies: r['id_species'],
        id: r['id'],
        startDate: r['start_date'],
        endDate: r['end_date'],
        lastUpdate: r['last_update'],
        npp: r['npp'],
        o3: r['o3'],
        pm1: r['pm1'],
        pm10: r['pm10'],
        pm25: r['pm2_5'],
        no2: r['no2'],
        so2: r['so2'],
        co: r['co'],
        canopyArea: r['canopy_area'],
        tsxnpp: db.Result.blob2listDouble(r['ts_npp']),
        tsxo3: db.Result.blob2listDouble(r['ts_o3']),
        tsxpm1: db.Result.blob2listDouble(r['ts_pm1']),
        tsxpm10: db.Result.blob2listDouble(r['ts_pm10']),
        tsxpm25: db.Result.blob2listDouble(r['ts_pm2_5']),
        tsxno2: db.Result.blob2listDouble(r['ts_no2']),
        tsxso2: db.Result.blob2listDouble(r['ts_so2']),
        tsxco: db.Result.blob2listDouble(r['ts_co']),
        tsxtime: db.Result.blob2listInt(r['ts_time']),
      );
      switch (result.id) {
        case '-2':
          infoResultTotal = gi.InfoResult(rs: result);
          break;
        case '-1':
          final key = result.idSpecies;
          infoResult4species[key] = gi.InfoResult(rs: result);
          if (id2Param[key] != null) {
            id2species[key] = id2Param[key]!.name;
          }
          {}
          break;
        default:
          infoResult4id[result.id] = gi.InfoResult(rs: result);
          break;
      }
    }
    return 0;
  }

  Future<int> getResultFromWeb(
      String idProject,
      String idUser,
      {
          bool setProject = false,
          bool deleteWebProject = false,
      }
  ) async {
    // clear db of previous results
    db.Project.deleteResult(idProject);

    // clear previous widget results
    if (setProject) {
      infoResult4id.clear();
      infoResult4species.clear();
      infoResultTotal = null;
      id2species.clear();
      dropdownItemId = -2;
    }

    // get results from airtree server
    final resultMongo = await io.getResult(idProject, idUser);
    setResult4id(resultMongo);

    // insert result in db and in widget storage
    result4id.forEach((key, result) {
      result.dbInsert();
      if (setProject) {
        infoResult4id[key] = gi.InfoResult(rs: result);
      }
    });

    // get airtree species id2names
    final id2Param = await dat.Param.getMapId();

    // insert result aggregated for species ...
    setAggregatedResults();
    result4species.forEach((key, result) {
      result.dbInsert();
      if (setProject) {
        infoResult4species[key] = gi.InfoResult(rs: result);
        if (id2Param[key] == null) {
          return;
        }
        id2species[key] = id2Param[key]!.name;
      }
    });

    // insert total result ...
    if (setProject) {
      infoResultTotal = gi.InfoResult(rs: resultTotal!);
    }
    resultTotal!.dbInsert();

    // clear current db.Results
    result4id.clear();
    result4species.clear();
    resultTotal = null;

    io.setDelivered(idProject, idUser);

    // update project status
    db.Project.setStatus(idProject, 2);
    notifyListeners();
    return 0;
  }
}

class GlobalProvider extends ChangeNotifier {
    int currentPageIndex = 0;


    String idProject = '';
    String previousIdProject = '';
    String idUser = '';
    String projectName = '';
    int projectStatus = -1;

    double tempPrjLat = 0.0; // temporary project latitude
    double tempPrjLng = 0.0; // temporary project longitude

    dat.Project? project;
    db.UserSetting? userSetting;

    String _languageInterface = "en"; //inglese default
    String get languageInterface => _languageInterface;

    int _languageSpecies = 0; //inglese default
    int get languageSpecies => _languageSpecies;

    int _mapType = 1;
    int get mapType => _mapType;

    int _handness = 0;
    int get idHandness => _handness;

    // index of selected row in DataTable
    int indexPrjTable = -1;

    List<dat.Project> projList = [];

    Future<void> getUserSetting() async {
        userSetting ??= await db.UserSetting.fromDb();
    }

    setMapType(int mapType) {
        switch (mapType) {
            case 1:
                _mapType = 1;
                break;
            case 2:
                _mapType = 2;
                break;
            case 3:
                _mapType = 3;
                break;
            default:
                _mapType = -1;
        }
        notifyListeners();
    }

    setLanguageInterface(int language, {bool notify = true}) {
        switch (language) {
            case 0:
                _languageInterface = "en";
                break;
            case 1:
                _languageInterface = "it";
                break;
            default:
                _languageInterface = "en";
        }
        if (notify) {
            notifyListeners();
        }
    }

    setLanguageSpecies(int language, {bool notify = true}) {
        // 0: scientific; 1: english; 2: italian
        _languageSpecies = language;
        if (notify) {
            notifyListeners();
        }
    }

    setHandness(int idHandness, {bool notify = true}) {
        // 0: right; 1: left
        _handness = idHandness;
        if (notify) {
            notifyListeners();
        }
    }



    GlobalProvider() {
        init();
    }

    void init() async {
        userSetting = await db.UserSetting.fromDb();
        dat.User user = await db.DatabaseManager.getUser();
        idUser = user.idUser;

        setLanguageInterface(userSetting!.idLanguageInterface, notify: false);
        setLanguageSpecies(userSetting!.idLanguageSpecies, notify: false);
        setHandness(userSetting!.idHandness, notify: false);
        projList = await db.DatabaseManager.getProject2();
        notifyListeners();
    }

    // getters
    String get getIdProject => idProject;
    String get getIdUser => idUser;
    String get getPreviousIdProject => previousIdProject;
    int get getIndexPrjTable => indexPrjTable;
    List<dat.Project> get getProjList => projList;

    // setters
    Future<int> getProjects() async {
        projList = await db.DatabaseManager.getProject2();
        notifyListeners();
        return 0;
    }

    //ordinamento per nome
    void sortProjectByName() {
        projList
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        notifyListeners();
    }

    //ordinamento per data
    void sortProjectByDate() {
        projList.sort((a, b) => b.startDate.compareTo(a.startDate));
        notifyListeners();
    }

    void setProject4form(dat.Project newProject) {
        // setting project from form
        previousIdProject = idProject;
        project = newProject;
        indexPrjTable = projList.length;
        _setProjectVars();
    }

    void setProject4table(int newIndexPrjTable) {
        previousIdProject = idProject;
        indexPrjTable = newIndexPrjTable;

        project = projList[indexPrjTable];
        _setProjectVars();
    }

    void _setProjectVars() {
        idProject = project!.idProject;
        projectName = project!.name;
        projectStatus = project!.status;
        notifyListeners();
    }

    //   void setProject4table(String newIdProject) {
    //       previousIdProject = idProject;
    //       idProject = newIdProject;
    //       projectName = projList[indexPrjTable].name;
    //       project = projList[indexPrjTable];
    //       notifyListeners();
    //   }
}

class PanelProvider extends ChangeNotifier {
  Panel panel = Panel.none;
  int indexElement = 0;

  // spedial misc
  IconData lastIcon = Icons.menu;
  Color activeColor = Colors.orange;

  // panel management
  bool showPanel = false;
  int heightMap = 80; // 8
  int heightPanel = 10;

  bool switchInfo = false; // false: show user input; true: show result

  Panel get getPanel => panel;
  bool get getShowPanel => showPanel;

  IconData get getLastIcon => lastIcon;
  Color get getActiveColor => activeColor;
  int get getHeightMap => heightMap;
  int get getHeightPanel => heightPanel;

  set setIndexElement(int newIndexElement) {
    indexElement = newIndexElement;
    notifyListeners();
  }

  void switchInfo2result() {
    switchInfo = !switchInfo;
    notifyListeners();
  }

  // setters
  void setPanel(Panel newPanel) {
    panel = newPanel;
    notifyListeners();
  }

  void setIconAndPanel(Panel panel, IconData newIcon, Color newActiveColor) {
    panel = panel;
    lastIcon = newIcon;
    activeColor = newActiveColor;
    notifyListeners();
  }

  void setHeightMap(int newHeightMap) {
    heightMap = newHeightMap;
    //notifyListeners();
  }

  void setHeightPanel(int newHeightPanel) {
    heightPanel = newHeightPanel;
    //notifyListeners();
  }

  void setShowBottomPanel(bool newShowBottomPanel) {
    showPanel = newShowBottomPanel;
    notifyListeners();
  }
}

class EditorProvider extends ChangeNotifier {
  EditorType editorType = EditorType.point;
  List<Marker> markerTestLayer = [];

  List<mt.LatLng> italy = dat.getItalyCoordinates();
  mt.LatLng projectLatLng = mt.LatLng(0, 0);

  // for geometry re-edit of existing green
  bool showForm = false;
  String selectedId = '';

  // line
  late PolyEditor lineEditor;
  final lineTest = Polyline(color: Colors.deepOrange, points: []);

  // polygon
  late PolyEditor polygonEditor;
  final testPolygon = Polygon(
      color: Colors.deepOrange.withOpacity(0.2), isFilled: true, points: []);

  EditorProvider() {
    init();
  }

  void setProjectLatLng(double lat, double lng) {
    projectLatLng = mt.LatLng(lat, lng);
  }

  void reset() {
    markerTestLayer.clear();
    lineTest.points.clear();
    testPolygon.points.clear();
  }

  void init() {
    // init line editor
    lineEditor = PolyEditor(
      addClosePathMarker: false,
      points: lineTest.points,
      pointIcon:
          const Icon(Icons.circle_outlined, size: 35, color: Colors.yellow),
    );

    // init polygon editor
    polygonEditor = PolyEditor(
      addClosePathMarker: true,
      points: testPolygon.points,
      pointIcon:
          const Icon(Icons.circle_outlined, size: 35, color: Colors.yellow),
    );
  }

  bool isItaly(LatLng pt, String idProject) {
    final pt1 = mt.LatLng(pt.latitude, pt.longitude);
    final check = mt.PolygonUtil.containsLocation(pt1, italy, true);
    if (check) {
      return true;
    } else {
      return false;
    }
  }

  bool isWithinDistance(LatLng pt, {double distance = 15000}) {
    final pt1 = mt.LatLng(pt.latitude, pt.longitude);
    if (mt.SphericalUtil.computeDistanceBetween(projectLatLng, pt1) >
        distance) {
      return false;
    } else {
      return true;
    }
  }

  // setters
  set setEditorType(EditorType newEditorType) {
    editorType = newEditorType;
    notifyListeners();
  }

  void resetEditor() {
    pointEditorReset();
    lineEditorReset();
    polygonEditorReset();
  }

  // POINT METHODS
  void pointEditorAdd(LatLng pt) {
    markerTestLayer.add(Marker(
      width: 35,
      height: 35,
      point: pt,
      child: const Icon(Icons.circle_outlined, size: 35, color: Colors.yellow),
    ));
    notifyListeners();
  }

  List<Marker> get getTestMarkerLayer => markerTestLayer;

  void pointEditorReset({bool notify = true}) {
    markerTestLayer.clear();
    notify ? notifyListeners() : null;
  }

  // LINE METHODS
  void lineEditorAdd(LatLng pt) {
    lineEditor.add(lineTest.points, pt);
    notifyListeners();
  }

  Polyline get getTestPolyline => lineTest;

  void lineEditorReset({bool notify = true}) {
    lineTest.points.clear();
    notify ? notifyListeners() : null;
  }

  void lineEditorPop({bool notify = true}) {
    lineTest.points.removeLast();
    notify ? notifyListeners() : null;
  }

  // POLYGON METHODS
  void polygonEditorAdd(LatLng pt) {
    polygonEditor.add(testPolygon.points, pt);
    notifyListeners();
  }

  Polygon get getTestPolygon => testPolygon;

  void polygonEditorReset({bool notify = true}) {
    testPolygon.points.clear();
    notify ? notifyListeners() : null;
  }

  void polygonEditorPop({bool notify = true}) {
    testPolygon.points.removeLast();
    notify ? notifyListeners() : null;
  }
}

class MapProvider extends ChangeNotifier {
  // map data layers
  var selectedMarker2 =
      <geo.UniqueMarker>[]; // layer showing only the selected marker
  var marker2 = <geo
      .UniqueMarker>[]; // tree markers + ? markers to interact with treeLine2 and forest2
  var treeLine2 = <geo.GeoLine>[];
  var forest2 = <geo.GeoPolygon>[];

  // starting map coords
  double startLat = 0.0;
  double startLon = 0.0;

  void reset() {
    selectedMarker2.clear();
    marker2.clear();
    treeLine2.clear();
    forest2.clear();
    notifyListeners();
  }

  void resetSelectedMarker2() {
    selectedMarker2.clear();
    notifyListeners();
  }

  void deletePoint(String id) {
    marker2.removeWhere((element) => element.id == id);
    resetSelectedMarker2();
    notifyListeners();
  }

  void deleteLine(String id) {
    deletePoint(id);
    treeLine2.removeWhere((element) => element.line.id == id);
    resetSelectedMarker2();
    notifyListeners();
  }

  void deletePolygon(String id) {
    deletePoint(id);
    forest2.removeWhere((element) => element.polygonGeometry.id == id);
    resetSelectedMarker2();
    notifyListeners();
  }

  // getters
  List<geo.UniqueMarker> get getSelectedMarker2 => selectedMarker2;
  List<geo.UniqueMarker> get getMarker2 => marker2;
  List<geo.GeoLine> get getTreeLine2 => treeLine2;
  List<Polygon> get getForest2 => forest2;
  double get getStartLat => startLat;
  double get getStartLon => startLon;

  void addTreeLine(geo.GeoLine newTreeLine) {
    treeLine2.add(newTreeLine);
    notifyListeners();
  }

  void addForest(geo.GeoPolygon newForest) {
    forest2.add(newForest);
    notifyListeners();
  }

  void setStartCoords({double? lat, double? lon}) async {
    // get starting coords
    if (lat != null && lon != null) {
      startLat = lat;
      startLon = lon;
    } else {
      var position = await _determinePosition();
      startLat = position.latitude;
      startLon = position.longitude;
    }
  }

  void changeSelectedMarker(geo.UniqueMarker selectedMarker) {
    selectedMarker2 = <geo.UniqueMarker>[selectedMarker];
    notifyListeners();
  }


  void selectedMarkerFromId(String id) {
      var tmp = marker2.where((element) => element.id == id).toList();
      if (tmp.isEmpty) {
          //tmp = marker2.where((element) => element.infoPolygon!.id == id).toList();
          print('selectedMarker2 empty');
          return;
      }
      print('selectedMarker2 length: ${tmp.length}');
      selectedMarker2 = [tmp[0].copy()];
  }

  void popSelectedMarker() {
    selectedMarker2 = <geo.UniqueMarker>[];
    notifyListeners();
  }

  void addMarker(geo.UniqueMarker newMarker) {
    marker2.add(newMarker);
    notifyListeners();
  }

  Future<void> initGeometries(BuildContext context, String idProject) async {
    // clear geometries
    selectedMarker2.clear();
    marker2.clear();
    treeLine2.clear();
    forest2.clear();

    //// get starting coords
    //var position = await _determinePosition();
    //startLat = position.latitude;
    //startLon = position.longitude;

    // add tree markers
    var tree2 = await db.DatabaseManager.getPoint2(idProject);
    if (!context.mounted) return;
    for (var tree in tree2) {
      var iconTree = tree.truth == 1 ? ic.Air.tree : ic.Air.prjTree;
      marker2.add(geo.UniqueMarker.fromPoint(context, tree, iconTree));
    }

    // add tree lines
    var treeLineStored2 = await db.DatabaseManager.getLine2(idProject);
    for (var line in treeLineStored2) {
      treeLine2.add(geo.GeoLine(line: line));
    }
    if (!context.mounted) return;

    // add tree line placeholders (same layer as tree markers)
    for (var line in treeLine2) {
      var iconLine = line.line.truth == 1 ? ic.Air.treeRow : ic.Air.prjTreeRow;
      marker2.add(geo.UniqueMarker.fromGeoLine(context, line, iconLine));
    }

    // add forest geometries and placeholders  (same layer as tree markers)
    var forestStored2 = await db.DatabaseManager.getPolygonGeometry2(idProject);
    var fData3 = await db.DatabaseManager.getPolygonData3(idProject);

    for (var forest in forestStored2) {
      forest2.add(geo.GeoPolygon(polygonGeometry: forest));
    }
    if (!context.mounted) return;

    for (var forest in forest2) {
      var dbData2 = fData3[forest.polygonGeometry.id];
      if (dbData2 == null) continue;
      var data2 =
          dbData2.map((x) => gi.InfoElementPolygon(polData: x)).toList();
      var truth = true;
      for (var data1 in data2) {
        if (data1.polData.truth == 0) {
          truth = false;
          break;
        }
      }
      var iconForest = truth ? ic.Air.forest : ic.Air.prjForest;
      marker2.add(
          geo.UniqueMarker.fromGeoPolygon(context, forest, data2, iconForest));
    }

    notifyListeners();
    return;
  }

  Future<void>initForest(BuildContext context, String idProject) async{
    forest2.clear();
    var forestStored2 = await db.DatabaseManager.getPolygonGeometry2(idProject);
    var fData3 = await db.DatabaseManager.getPolygonData3(idProject);

    for (var forest in forestStored2) {
      forest2.add(geo.GeoPolygon(polygonGeometry: forest));
    }
    if (!context.mounted) return;

    for (var forest in forest2) {
      var dbData2 = fData3[forest.polygonGeometry.id];
      if (dbData2 == null) continue;
      var data2 =
          dbData2.map((x) => gi.InfoElementPolygon(polData: x)).toList();
      var truth = true;
      for (var data1 in data2) {
        if (data1.polData.truth == 0) {
          truth = false;
          break;
        }
      }
      var iconForest = truth ? ic.Air.forest : ic.Air.prjForest;
      marker2.add(
          geo.UniqueMarker.fromGeoPolygon(context, forest, data2, iconForest));
    }
  }
}

class ParamProvider extends ChangeNotifier {
  Map<int, dat.ParamRow> _par3 = {}; // parameters

  ParamProvider() {
    init();
  }

  void init() async {
    _par3 = await dat.Param.getMapId();
    notifyListeners();
  }

  Map<int, dat.ParamRow> get par3 => {..._par3};

  set par3(Map<int, dat.ParamRow> newPar3) {
    _par3 = newPar3;
    notifyListeners();
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}
