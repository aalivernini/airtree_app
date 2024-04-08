// import 'dart:html';

// ignore_for_file: prefer_const_constructors, sort_child_properties_last, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:objectid/objectid.dart';

import 'form.dart' as inp;
import 'providers.dart' as pr;
import 'database.dart' as db;
import 'data.dart' as dat;
import 'enums.dart' as en;
import 'geo.dart' as geo;
import 'geo_info.dart' as info;
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'icon.dart' as ic;
import 'geo_info.dart' as gi;
import 'io.dart' as io;
import 'dart:async';
import 'dart:convert';
import 'env.dart';
import 'package:http/http.dart' as http;
import 'widget_other.dart' as oth;


const bool isMobile = true;

Future<int> downloadResults(BuildContext context) async {
  final rProvider = Provider.of<pr.ResultProvider>(context, listen: false);
  final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
  int result = 0;
  for (var prj in gProvider.projList) {
        //print('prj status : ${prj.status}');

    if (prj.status == 1) {
        bool privatePrj = prj.privateProject == 1;

      // project sent to airtree server
      // check if results are are ready
      bool webResultReady = false;
      int webStatus = 0;
      try {   // avoid server errors
          webStatus = int.parse(await io.getProjectStatus(prj.idProject, gProvider.idUser));
      } catch (e) {
          print(e);
          continue;
      }
      if (webStatus == 4) {
        webResultReady = true;
      }

      if (webResultReady) {
          bool setProject =
                  false; // check if this is the current project. In this case the data will be directly loaded
          if (prj.idProject == gProvider.idProject) {
              setProject = true;
          }
          await rProvider.getResultFromWeb(prj.idProject, gProvider.idUser, setProject: setProject, deleteWebProject: privatePrj);
          await db.Project.setStatus(prj.idProject, 2);
          gProvider
                  .projList[gProvider.projList
                  .indexWhere((element) => element.idProject == prj.idProject)]
                  .status = 2;
          await gProvider
                  .getProjects(); // project status set to 2: results downloaded

          if (setProject) {
              // this is the current project
              rProvider.dropdownItemId = -2;
              rProvider.getResultFromDb(gProvider.idProject).then((value) {
                  rProvider.setReady(true);
              });
              gProvider.projectStatus = 2;
              gProvider.project!.status = 2;
          }

          result = 1;
      }
    }
  }
  return result;
}

List<Widget> getPollutantButtonList(BuildContext context) {
  final rProvider = Provider.of<pr.ResultProvider>(context, listen: true);
  Map<int, String> pol3 = {
    1: 'NPP',
    2: 'O\u2083',
    3: 'PM\u2081',
    4: 'PM\u2082\u2085',
    5: 'PM\u2081\u2080',
    6: 'NO\u2082',
    7: 'SO\u2082',
    8: 'CO'
  };
  const style = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontSize: 12,
  );
  final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
  );
  final ButtonStyle buttonStyleDisabled = ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
  );
  return pol3.entries
      .map((e) => Row(children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
            ),
            ElevatedButton(
              style: e.key == rProvider.pollutantId
                  ? buttonStyle
                  : buttonStyleDisabled,
              child: Text(
                e.value,
                style: style,
                textAlign: TextAlign.center,
              ),
              onPressed: () {
                rProvider.setPollutantId(e.key);
              },
            ),
          ]))
      .toList();
}

void updateGeometryGreen(BuildContext context, en.EditorType type) async {
  final eProvider = Provider.of<pr.EditorProvider>(context, listen: false);
  final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
  final pProvider = Provider.of<pr.PanelProvider>(context, listen: false);
  geo.UniqueMarker? newMarker;
  geo.UniqueMarker? sMarker; // select circle

  switch (type) {
    case en.EditorType.point:
      var newLatLng = eProvider.markerTestLayer[0].point;
      var index =
          mProvider.marker2.indexWhere((p) => p.id == eProvider.selectedId);
      var marker = mProvider.marker2[index];
      var pnt = marker.getNewPoint(context, newLatLng);
      var iconTree = pnt.truth == 1 ? ic.Air.tree : ic.Air.prjTree;
      newMarker = geo.UniqueMarker.fromPoint(context, pnt, iconTree);
      sMarker = geo.UniqueMarker.fromPoint(context, pnt, ic.Air.selected);
      newMarker.infoPoint!.pnt.dbUpdate();
      mProvider.marker2[index] = newMarker;

      break;
    case en.EditorType.line:
      var coords = [...eProvider.lineTest.points];
      var line = mProvider.treeLine2
          .firstWhere((p) => p.line.id == eProvider.selectedId);
      line.points.clear();
      line.points.addAll(coords);
      line.line.dbUpdate();

      // update placeholder
      var index =
          mProvider.marker2.indexWhere((p) => p.id == eProvider.selectedId);
      var iconLine = line.line.truth == 1 ? ic.Air.treeRow : ic.Air.prjTreeRow;
      newMarker = geo.UniqueMarker.fromGeoLine(context, line, iconLine);
      mProvider.marker2[index] = newMarker;
      sMarker = geo.UniqueMarker.fromGeoLine(context, line, ic.Air.selected);
      break;
    case en.EditorType.polygon:
      var coords = [...eProvider.testPolygon.points];
      var pol = mProvider.forest2
          .firstWhere((p) => p.polygonGeometry.id == eProvider.selectedId);
      pol.points.clear();
      pol.points.addAll(coords);
      pol.polygonGeometry.dbUpdate();

      // update placeholder
      var index =
          mProvider.marker2.indexWhere((p) => p.id == eProvider.selectedId);
      var iconForest =
          pol.polygonGeometry.truth == 1 ? ic.Air.forest : ic.Air.prjForest;
      var prevMarker = mProvider.marker2[index];
      var infoPolygon = [
        ...prevMarker.infoPolygon!.element2
      ]; // get data from old marker
      newMarker = geo.UniqueMarker.fromGeoPolygon(
          context, pol, infoPolygon, iconForest);
      mProvider.marker2[index] = newMarker;
      sMarker = geo.UniqueMarker.fromGeoPolygon(
          context, pol, infoPolygon, ic.Air.selected);
      break;
    default:
      break;
  }

  eProvider.resetEditor();
  // update selection
  if (sMarker != null) {
    mProvider.changeSelectedMarker(sMarker);
    pProvider.showPanel = true;
  }
  pProvider.setPanel(en.Panel.resetGeometry);
}

void addGreen(BuildContext context, en.EditorType type) async {
  final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
  final eProvider = Provider.of<pr.EditorProvider>(context, listen: false);
  final mProvider = Provider.of<pr.MapProvider>(context, listen: false);

  var idGeometry = ObjectId().hexString;

  List<LatLng> coords = [];
  double area = 0;
  switch (type) {
    case en.EditorType.point:
      coords = [eProvider.markerTestLayer[0].point];
      break;
    case en.EditorType.line:
      coords = [...eProvider.lineTest.points];
      break;
    case en.EditorType.polygon:
      coords = [...eProvider.testPolygon.points];
      var points = eProvider.testPolygon.points;
      List<mt.LatLng> mtCoords = [];
      for (int i = 0; i < points.length; i++) {
        mtCoords.add(mt.LatLng(points[i].latitude, points[i].longitude));
      }
      area = mt.SphericalUtil.computeArea(mtCoords) as double;
      break;
  }

  int maxAreaPercent = 100;
  dynamic green;

  List<db.PolygonData> greenData2 = [];

  switch (type) {
    case en.EditorType.polygon:
      while (true) {
          var green3 =  await Navigator.pushNamed(
              context,
              '/greenForm',
              arguments: inp.GreenFormArgs(
                  idGeometry:     idGeometry,
                  idUser:         gProvider.idUser,
                  idProject:      gProvider.idProject,
                  type:           type,
                  coords:         coords,
                  maxAreaPercent: maxAreaPercent,
                  area:           area,
              ),
          ) as Map?;
        if (green3 == null) {  // cancel
          return;
        }

        greenData2.add(green3['data']);
        if (green3['nextInput'] != true || green3['nextMaxAreaPercent'] < 1) {
          break;
        }
        maxAreaPercent = green3['nextMaxAreaPercent'];
      }
      break;
    default:
      if (!context.mounted) return;
      green = await Navigator.pushNamed(
              context,
              '/greenForm',
              arguments: inp.GreenFormArgs(
                  idGeometry:     idGeometry,
                  idUser:         gProvider.idUser,
                  idProject:      gProvider.idProject,
                  type:           type,
                  coords:         coords,
                  maxAreaPercent: maxAreaPercent,
                  area:           area,
              ),
          );
      if (green == null) { // cancel
        return;
      }
      break;
  }
  if (!context.mounted) return;

  Container icon;
  switch (type) {
    case en.EditorType.point:
      icon = green.truth == 1 ? ic.Air.tree : ic.Air.prjTree;
      var marker = geo.UniqueMarker.fromPoint(context, green, icon);
      mProvider.addMarker(marker);
      marker.infoPoint!.pnt.dbInsert();
      break;
    case en.EditorType.line:
      icon = green.truth == 1 ? ic.Air.treeRow : ic.Air.prjTreeRow;
      var mapLine = geo.GeoLine(line: green);
      mProvider.addTreeLine(mapLine);
      var marker = geo.UniqueMarker.fromGeoLine(context, mapLine, icon);
      mProvider.addMarker(marker); // placeholder
      marker.infoLine!.line.dbInsert();
      break;
    case en.EditorType.polygon:
      // forest polygon
      // define truth (real vegetation or green project)
      int truth = 0;
      for (var greenData in greenData2) {
        if (greenData.truth == 1) {
          truth = 1;
          break;
        }
      }
      var mapPolygon = geo.GeoPolygon(
          polygonGeometry: db.PolygonGeometry(
        id: idGeometry,
        idUser: gProvider.idUser,
        idProject: gProvider.idProject,
        lastUpdate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        setTruth: truth,
        coords: coords,
      ));

      mProvider.addForest(mapPolygon);
      mapPolygon.polygonGeometry.dbInsert();

      List<info.InfoElementPolygon> data2 = [];
      for (var greenData in greenData2) {
        greenData.dbInsert();
        data2.add(info.InfoElementPolygon(polData: greenData));
      }
      icon = truth == 1 ? ic.Air.forest : ic.Air.prjForest;
      mProvider.addMarker(geo.UniqueMarker.fromGeoPolygon(
          context, mapPolygon, data2, icon)); // placeholder

      // multi forest data
      break;
  }
  eProvider.resetEditor();
}

void doMapAction(BuildContext context, LatLng p) async {
  // manage actions executed on map tap
  // tap on markers is managed by them
  // tap on geometry editing is managed by the EditorProvider
  final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
  final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
  final eProvider = Provider.of<pr.EditorProvider>(context, listen: false);
  final pProvider = Provider.of<pr.PanelProvider>(context, listen: false);

  // Airtree geometry checks
  if (gProvider.project!.hasData == 0) {
    if (!eProvider.isItaly(p, gProvider.idProject)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Airtree is available only in Italy'),
            duration: Duration(seconds: 3)),
      );
      return;
    } else {
      gProvider.tempPrjLat = p.latitude;
      gProvider.tempPrjLng = p.longitude;
    }
  } else {
    if (!eProvider.isWithinDistance(p)) {
      String testoRange = AppLocalizations.of(context)!.rangeAirTree;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(testoRange), duration: Duration(seconds: 3)),
      );
      return;
    }

    // set temporary project coordinates. These coordinates are unused if the geometry is not saved
  }

  // add point to geometry
  switch (pProvider.panel) {
    case en.Panel.addTree:
      if (eProvider.markerTestLayer.isEmpty) {
        eProvider.pointEditorAdd(p);
      }
      break;
    case en.Panel.addRow:
      eProvider.lineEditorAdd(p);
      break;
    case en.Panel.addForest:
      eProvider.polygonEditorAdd(p);
      break;
    default:
      // deselect marker
      mProvider.resetSelectedMarker2();
      break;
  }
}

Row getPanel(BuildContext context, en.Panel type) {
  switch (type) {
    case en.Panel.addTree:
    case en.Panel.addRow:
    case en.Panel.addForest:
      return getEditPanel(context, type);
    case en.Panel.map:
      return getMapPanel(context);
    default:
      return getInfoPanel(context, type);
  }
}

Row getMapPanel(BuildContext context) {
  final gProvider = Provider.of<pr.GlobalProvider>(context, listen: true);
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Column(
        children: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
                gProvider.setMapType(1);
            },
          ),
          Text("OpenStreetMap"),
        ],
      ),
      Column(
        children: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
                gProvider.setMapType(2);
            },
          ),
          Text("Bing satellite"),
        ],
      ),
      Column(
        children: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
                gProvider.setMapType(3);
            },
          ),
          Text("Bing hybrid"),
        ],
      ),
    ],
  );
}

// -- Info Panel -----------------------------------------------------------------
Row getInfoPanel(BuildContext context, en.Panel type) {
  final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
  final pProvider = Provider.of<pr.PanelProvider>(context, listen: false);
  final parProvider = Provider.of<pr.ParamProvider>(context, listen: false);
  final rProvider = Provider.of<pr.ResultProvider>(context, listen: false);
  final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);

  List<Widget> buttons = [];
  switch (type) {
    case en.Panel.info:
      // TODO: add result buttons only if they are ready for this geometry
      bool checkResultReady = true;
      if (checkResultReady) {
        buttons.addAll([
          IconButton(
            icon: pProvider.switchInfo
                ? Icon(MdiIcons.informationSlabCircle, size: 40.0)
                : const Icon(Icons.inbox, size: 40.0),
            color: Colors.blue,
            onPressed: () {
              pProvider.switchInfo2result();
              // TODO: show results for selected marker
            },
          ),
          const Padding(padding: EdgeInsets.only(bottom: 5))
        ]);
      }
      //buttons.add(InkWell(
      //        radius: 90,
      //        onTap: () {
      //            ScaffoldMessenger.of(context).showSnackBar(
      //                SnackBar(content: Text(AppLocalizations.of(context)!.longPress)),
      //            );
      //        },
      //        onLongPress: () async {
      //            await Navigator.push(
      //                context,
      //                MaterialPageRoute(
      //                    builder: (context) => inp.InfoDati(
      //                        crowndiameter: AppLocalizations.of(context)!.helloWorld,
      //                        diameter: "c",
      //                        treeheight: "c",
      //                        crownheight: "c",
      //                        lai: "c",
      //                    )),
      //            );
      //        },
      //        child: Ink(
      //                   child:
      //                   const Icon(Icons.edit_document, size: 40.0, color: Colors.blue),
      //               ),
      //        ));
      break;
    case en.Panel.resetGeometry:
      buttons.add(InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.longPress)),
          );
        },
        onLongPress: () {
          if (mProvider.selectedMarker2.isEmpty) return;
          mProvider.selectedMarker2[0].editGeometry(context);
        },
        child: Ink(
          child: Icon(MdiIcons.swapHorizontal, size: 40.0, color: Colors.blue),
        ),
      ));

    case en.Panel.delete:
      buttons.add(InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.longPress)),
          );
        },
        onLongPress: () {
          if (mProvider.selectedMarker2.isEmpty) return;
          mProvider.selectedMarker2[0].delete(context);
          if (mProvider.marker2.isEmpty) {
            // there are not geometries in the project
            db.Project.setProjectCoords(gProvider.idProject, 0, 0, 0);
            gProvider.project!.hasData = 0;
            gProvider.project!.lat = 0;
            gProvider.project!.lon = 0;
          }

          // set a project outdated in current session
          if (gProvider.projectStatus == 2) {
            gProvider.projectStatus = 3;
            gProvider.project!.status = 3;
          }
        },
        child: Ink(
          child: Icon(MdiIcons.delete, size: 40.0, color: Colors.blue),
        ),
      ));
    default:
      break;
  }
  final locale = Localizations.localeOf(context).toString();


  String? selectedId;
  if (rProvider.ready && mProvider.selectedMarker2.isNotEmpty) {
    selectedId = mProvider.selectedMarker2[0].getId();
  }
  List<TableRow> rows = [];
  if (pProvider.switchInfo) {
    final result = rProvider.infoResult4id[selectedId];
    if (result != null) {
      rows = result.getTableRows(parProvider.par3,locale);
    }
  } else {
    if (mProvider.selectedMarker2.isNotEmpty) {
      rows = mProvider.selectedMarker2[0].getTableRows(parProvider.par3);
    }
  }

  //String selectedId = mProvider.selectedMarker2[0].getId();
  if (mProvider.selectedMarker2.isNotEmpty &&
      mProvider.selectedMarker2[0].type == en.EditorType.polygon) {
    bool next = false;
    bool prev = false;
    Color nextColor = Colors.grey;
    Color prevColor = Colors.grey;
    int elements =
        mProvider.selectedMarker2[0].infoPolygon!.element2.length - 1;
    int indexElement = mProvider.selectedMarker2[0].infoPolygon!.indexElement;

    if (indexElement < elements) {
      next = true;
      nextColor = Colors.blue;
    }
    if (indexElement > 0) {
      prev = true;
      prevColor = Colors.blue;
    }

    buttons.addAll([
      const Padding(padding: EdgeInsets.only(bottom: 5)),
      IconButton(
        icon: const Icon(Icons.arrow_upward, size: 40.0),
        color: nextColor,
        onPressed: () {
          if (next) {
            mProvider.selectedMarker2[0].infoPolygon!.indexElement++;
            pProvider.notifyListeners();
          }
          //    mProvider.deleteSelectedMarker();
        },
      ),
      const Padding(padding: EdgeInsets.only(bottom: 5)),
      IconButton(
        icon: const Icon(Icons.arrow_downward, size: 40.0),
        color: prevColor,
        onPressed: () {
          if (prev) {
            mProvider.selectedMarker2[0].infoPolygon!.indexElement--;
            pProvider.notifyListeners();
          }
          //    mProvider.deleteSelectedMarker();
        },
      ),
    ]);
  }
  return Row(children: [
    Expanded(
      flex: 85,
      child: mProvider.selectedMarker2.isNotEmpty
          ? Container(
              alignment: Alignment.topCenter,
              child: Table(
                border: const TableBorder(
                    horizontalInside: BorderSide(
                        width: 1,
                        color: Colors.blue,
                        style: BorderStyle.solid)),
                children: rows,
              ))
          : Text(AppLocalizations.of(context)!.markerSelected),
    ),
    Expanded(flex: 15, child: Column(children: buttons))
  ]);
}

//  edit panel
Row getEditPanel(BuildContext context, en.Panel type) {
  final eProvider = Provider.of<pr.EditorProvider>(context, listen: true);
  final pProvider = Provider.of<pr.PanelProvider>(context, listen: false);
  final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);

  // switches for active buttons
  var activeReset = true;
  var activeUndo = true;
  var activeInsertInfo = true;
  var editorType = en.EditorType.point;

  switch (type) {
    case en.Panel.addTree:
      editorType = en.EditorType.point;
      if (eProvider.markerTestLayer.isEmpty) {
        activeReset = false;
        // unused activeUndo = false;
        activeInsertInfo = false;
      }
      break;
    case en.Panel.addRow:
      editorType = en.EditorType.line;
      if (eProvider.lineTest.points.isEmpty) {
        activeReset = false;
        activeUndo = false;
        activeInsertInfo = false;
      } else if (eProvider.lineTest.points.length < 2) {
        activeInsertInfo = false;
      }
    case en.Panel.addForest:
      editorType = en.EditorType.polygon;
      if (eProvider.testPolygon.points.isEmpty) {
        activeReset = false;
        activeUndo = false;
        activeInsertInfo = false;
      } else if (eProvider.testPolygon.points.length < 3) {
        activeInsertInfo = false;
      }
    default:
      break;
  }

  // visibility for middle button
  var visibilityGoBack = true;
  if (pProvider.panel == en.Panel.addTree) {
    visibilityGoBack = false;
  }

  var background = const ShapeDecoration(
    color: Colors.blue,
    shape: CircleBorder(),
  );
  var inactiveBackground = const ShapeDecoration(
    color: Colors.grey,
    shape: CircleBorder(),
  );
  return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
    Ink(
        decoration: activeReset ? background : inactiveBackground,
        child: IconButton(
          icon: const Icon(Icons.replay, size: 40.0),
          padding: EdgeInsets.zero,
          color: Colors.white,
          onPressed: () {
            switch (pProvider.panel) {
              case en.Panel.addTree:
                activeReset ? eProvider.pointEditorReset() : null;
                break;
              case en.Panel.addRow:
                activeReset ? eProvider.lineEditorReset() : null;
                break;
              case en.Panel.addForest:
                activeReset ? eProvider.polygonEditorReset() : null;
                break;
              default:
                break;
            }
          },
        )),
    Visibility(
        visible: visibilityGoBack,
        child: Ink(
            decoration: activeUndo ? background : inactiveBackground,
            child: IconButton(
              icon: const Icon(Icons.arrow_left, size: 40.0),
              padding: EdgeInsets.zero,
              color: Colors.white,
              onPressed: () {
                switch (pProvider.panel) {
                  case en.Panel.addRow:
                    activeUndo ? eProvider.lineEditorPop() : null;
                    break;
                  case en.Panel.addForest:
                    activeUndo ? eProvider.polygonEditorPop() : null;
                    break;
                  default:
                    break;
                }
              },
            ))),
    Ink(
        decoration: activeInsertInfo ? background : inactiveBackground,
        child: IconButton(
          icon: const Icon(Icons.arrow_right, size: 40.0),
          padding: EdgeInsets.zero,
          color: Colors.white,
          onPressed: () {
            if (activeInsertInfo) {
              if (eProvider.showForm) {
                addGreen(context, editorType);
                if (gProvider.project!.hasData == 0) {
                  // set info for geometry editing checks
                  db.Project.setProjectCoords(gProvider.idProject,
                      gProvider.tempPrjLat, gProvider.tempPrjLng, 1);

                  gProvider.project!.hasData = 1;
                  gProvider.project!.lat = gProvider.tempPrjLat;
                  gProvider.project!.lon = gProvider.tempPrjLng;
                  eProvider.setProjectLatLng(
                      gProvider.tempPrjLat, gProvider.tempPrjLng);
                }
                if (gProvider.project!.status == 2) {
                  gProvider.project!.status = 3;
                  db.Project.setStatus(gProvider.project!.idProject, 3);
                }
              } else {
                updateGeometryGreen(context, editorType);
              }
            }
          },
        )),
  ]);
}

void setProjectCoords(BuildContext context) async {
  final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
  final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);

  double lat = 0;
  double lng = 0;
  bool init = true;

  for (var marker in mProvider.marker2) {
    LatLng point = marker.point;
    if (init) {
      init = false;
      lat = point.latitude;
      lng = point.longitude;
    } else {
      lat = (lat + point.latitude) / 2;
      lng = (lng + point.longitude) / 2;
    }
  }
  var coords = <double>[];
  await db.Project.setProjectCoords(gProvider.idProject, lat, lng, 1);
}

// Bing Maps
// All compatible imagery sets
enum BingMapsImagerySet {
  road('RoadOnDemand', zoomBounds: (min: 0, max: 21)),
  aerial('Aerial', zoomBounds: (min: 0, max: 20)),
  aerialLabels('AerialWithLabelsOnDemand', zoomBounds: (min: 0, max: 20)),
  canvasDark('CanvasDark', zoomBounds: (min: 0, max: 21)),
  canvasLight('CanvasLight', zoomBounds: (min: 0, max: 21)),
  canvasGray('CanvasGray', zoomBounds: (min: 0, max: 21)),
  ordnanceSurvey('OrdnanceSurvey', zoomBounds: (min: 12, max: 17));

  final String urlValue;
  final ({int min, int max}) zoomBounds;

  const BingMapsImagerySet(this.urlValue, {required this.zoomBounds});
}

// Custom tile provider that contains the quadkeys logic
// Note that you can also extend from the CancellableNetworkTileProvider
class BingMapsTileProvider extends NetworkTileProvider {
  BingMapsTileProvider({super.headers});

  String _getQuadKey(int x, int y, int z) {
    final quadKey = StringBuffer();
    for (int i = z; i > 0; i--) {
      int digit = 0;
      final int mask = 1 << (i - 1);
      if ((x & mask) != 0) digit++;
      if ((y & mask) != 0) digit += 2;
      quadKey.write(digit);
    }
    return quadKey.toString();
  }

  @override
  Map<String, String> generateReplacementMap(
    String urlTemplate,
    TileCoordinates coordinates,
    TileLayer options,
  ) =>
      super.generateReplacementMap(urlTemplate, coordinates, options)
        ..addAll(
          {
            'culture': 'en-GB', // Or your culture value of choice
            'subdomain': options.subdomains[
                (coordinates.x + coordinates.y) % options.subdomains.length],
            'quadkey': _getQuadKey(coordinates.x, coordinates.y, coordinates.z),
          },
        );
}

// Custom `TileLayer` wrapper that can be inserted into a `FlutterMap`
class BingMapsTileLayer extends StatelessWidget {
  const BingMapsTileLayer({
    super.key,
    required this.apiKey,
    required this.imagerySet,
  });

  final String apiKey;
  final BingMapsImagerySet imagerySet;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: http.get(
        Uri.parse(
          'http://dev.virtualearth.net/REST/V1/Imagery/Metadata/${imagerySet.urlValue}?output=json&include=ImageryProviders&key=$apiKey',
        ),
      ),
      builder: (context, response) {
        if (response.data == null) return const Placeholder();

        return TileLayer(
          urlTemplate: (((((jsonDecode(response.data!.body)
                          as Map<String, dynamic>)['resourceSets']
                      as List<dynamic>)[0] as Map<String, dynamic>)['resources']
                  as List<dynamic>)[0] as Map<String, dynamic>)['imageUrl']
              as String,
          tileProvider: BingMapsTileProvider(),
          subdomains: const ['t0', 't1', 't2', 't3'],
          minNativeZoom: imagerySet.zoomBounds.min,
          maxNativeZoom: imagerySet.zoomBounds.max,
        );
      },
    );
  }
}

List<Widget> getPageList(BuildContext context) {
  // -- Project appBar ----------------------------------------------------------
  final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
  final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
  final eProvider = Provider.of<pr.EditorProvider>(context, listen: false);
  final pProvider = Provider.of<pr.PanelProvider>(context, listen: true);

  var w1 = Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Tooltip(
          message: "Add Project", // Testo del tooltip
          child: GestureDetector(
              onTap: () async {
                  mProvider.reset();
                  var prj = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => inp.MyCustomFormProject(
                              idUser: gProvider.idUser,
                          ),
                      ),
                  );
                  if (prj != null) {
                      gProvider.projectStatus = 0;
                      await db.Project.insertProject(prj);
                      gProvider.getProjects();
                      gProvider.setProject4form(prj);
                      gProvider.currentPageIndex = 1;
                  }
              },
              child: const Icon(
                         Icons.add,
                         size: 26.0,
                     ),
          ),
          ),
          );

  //tasto impostazioni
  var w2 = PopupMenuButton<String>(
      onSelected: (value) {
          if (value == 'name') {
              // ordina progetti per nome
              gProvider.sortProjectByName();
          } else if (value == 'date') {
              gProvider.sortProjectByDate();
          }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
              value: 'name',
              child: ListTile(
                  leading: Icon(Icons.sort_by_alpha),
                  title: Text(AppLocalizations.of(context)!.sortName),
              ),
          ),
          PopupMenuItem<String>(
              value: 'date',
              child: ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text(AppLocalizations.of(context)!.sortDate),
              ),
          ),
      ],
      child: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: const Icon(Icons.filter_list),
      ),
      offset: Offset(0, 30),
      );

      var appBar = AppBar(
          title: Text(AppLocalizations.of(context)!.projectList),
          actions: <Widget>[w1, w2],
      );

  // -- flutter map -------------------------------------------------------------

  var flutterMap =
      Consumer2<pr.EditorProvider, pr.GlobalProvider>(builder: (context, eProvider, gProvider, child) {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(mProvider.startLat, mProvider.startLon),
        maxZoom: 21,
        onTap: (_, p) async {
          doMapAction(context, p);
        },
      ),

      // map background layer
      children: [
          if (gProvider.mapType == 1)  // OpenStreetMap
          TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.fleaflet.flutter_map.example',
              maxNativeZoom: 18,
              maxZoom: 30,
          )
          else if (gProvider.mapType == 2)  // Bing satellite
          BingMapsTileLayer(
              apiKey: Env.bingKey,
              imagerySet: BingMapsImagerySet.aerial,
          )
          else if (gProvider.mapType == 3)  // Bing hybrid
              BingMapsTileLayer(
                  apiKey: Env.bingKey,
                  imagerySet: BingMapsImagerySet.aerialLabels,
              ),

        CurrentLocationLayer(),

        // editor layers
        MarkerLayer(markers: eProvider.markerTestLayer),
        PolylineLayer(polylines: [eProvider.lineTest]),
        PolygonLayer(polygons: [eProvider.testPolygon]),

        // map layers
        PolylineLayer(polylines: mProvider.treeLine2),
        PolygonLayer(polygons: mProvider.forest2),
        MarkerLayer(markers: mProvider.marker2),
        MarkerLayer(markers: mProvider.selectedMarker2),
        DragMarkers(markers: eProvider.lineEditor.edit()),
        DragMarkers(markers: eProvider.polygonEditor.edit()),
      ],
    );
  });

  final loc = AppLocalizations.of(context)!;

  bool showDialLabel = gProvider.userSetting!.idHelpLabel == 1 ? true : false;

  // -- SpeedDial in Map ---------------------------------------------------------------
  var dialButtons = SpeedDial(
    icon: pProvider.lastIcon,
    activeIcon: Icons.close, //icon when menu is expanded on button
    backgroundColor: pProvider.activeColor, //background color of button
    foregroundColor: Colors.white, //font color, icon color in button
    activeBackgroundColor:
        Colors.black, //background color when menu is expanded
    activeForegroundColor: Colors.white,
    buttonSize: const Size(50, 50), //button size
    iconTheme: const IconThemeData(size: 40.0), //icon theme of button
    childrenButtonSize: const Size(70, 70), //size of menu items

    //buttonSize: 56, //button size
    visible: true,
    closeManually: false,
    curve: Curves.bounceIn,
    //overlayColor: Colors.black,
    overlayOpacity: 0,
    //onOpen: () => print('OPENING DIAL'), // action when menu opens
    //onClose: () => print('DIAL CLOSED'), //action when menu closes

    elevation: 8.0, //shadow elevation of button
    shape: const CircleBorder(), //shape of button

    children: [
      SpeedDialChild(
        label: showDialLabel==true? loc.tree: null,
        child: Tooltip(
          triggerMode: TooltipTriggerMode.longPress,
          message: loc.tree,
          child: Icon(MdiIcons.tree, size: 50),

          preferBelow: false, //tooltip non viene mostrato sotto di default
          verticalOffset: -20, //sposta tooltip in alto
          margin:
              EdgeInsets.fromLTRB(80, 0, 80, 0), //posiziona tooltip a sinistra
          textStyle: TextStyle(
            //modifica colore testo
            color: Colors.black,
          ),
          decoration: BoxDecoration(
            //modifica box tooltip
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(), //shape of button
        onTap: () {
          eProvider.resetEditor();
          eProvider.showForm = true;

          // set panel
          pProvider.setShowBottomPanel(true);
          pProvider.setHeightMap(90);
          pProvider.setHeightPanel(10);

          // set editor
          eProvider.editorType = en.EditorType.point;
          pProvider.setPanel(en.Panel.addTree);
          pProvider.setIconAndPanel(
              en.Panel.addTree, MdiIcons.tree, Colors.green);
        },
      ),
      //onLongPress: () => print('FIRST CHILD LONG PRESS'),

      SpeedDialChild(
          label: showDialLabel==true? loc.treeRow: null,

        // add tree row

        child: Tooltip(
          //parte per vedere infomazioni icona
          message: AppLocalizations.of(context)!.treeRow,
          child: Icon(Icons.add_road, size: 40),
          //set posizione del tooltip
          preferBelow: false,
          verticalOffset: -20,
          margin: EdgeInsets.fromLTRB(80, 0, 80, 0),
          textStyle: TextStyle(
            //modifica colore testo
            color: Colors.black,
          ),
          decoration: BoxDecoration(
            //modifica box tooltip
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),

        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        shape: const CircleBorder(), //shape of button
        onTap: () {
          eProvider.resetEditor();
          eProvider.showForm = true;
          // set panel
          pProvider.setShowBottomPanel(true);
          pProvider.setHeightMap(90);
          pProvider.setHeightPanel(10);
          pProvider.setPanel(en.Panel.addRow);

          // set editor
          eProvider.editorType = en.EditorType.line;
          pProvider.setIconAndPanel(
              en.Panel.addRow, Icons.add_road, Colors.green);
        },
        //onLongPress: () => print('THIRD CHILD LONG PRESS'),
      ),

      SpeedDialChild(
          label: showDialLabel==true? loc.urbanForest: null,
        // add forest

        child: Tooltip(
          //parte per vedere infomazioni icona
          message: AppLocalizations.of(context)!.urbanForest,
          child: Icon(MdiIcons.forest, size: 40),
          //set posizione del tooltip
          preferBelow: false,
          verticalOffset: -20,
          margin: EdgeInsets.fromLTRB(80, 0, 80, 0),
          textStyle: TextStyle(
            //modifica colore testo
            color: Colors.black,
          ),
          decoration: BoxDecoration(
            //modifica box tooltip
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),

        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(), //shape of button
        onTap: () {
          eProvider.resetEditor();
          eProvider.showForm = true;
          // set panel
          pProvider.setShowBottomPanel(true);
          pProvider.setHeightMap(90);
          pProvider.setHeightPanel(10);
          pProvider.setIconAndPanel(
              en.Panel.addForest, Icons.forest, Colors.green);
          pProvider.setPanel(en.Panel.addForest);

          // set editor
          eProvider.editorType = en.EditorType.polygon;
        },
        //onLongPress: () => print('SECOND CHILD LONG PRESS'),
      ),

      SpeedDialChild(
        label: showDialLabel==true? loc.information: null,

        // info

        child: Tooltip(
          //parte per vedere infomazioni icona
          message: AppLocalizations.of(context)!.information,
          child: Icon(MdiIcons.informationSlabCircle, size: 55),
          //set posizione del tooltip
          preferBelow: false,
          verticalOffset: -20,
          margin: EdgeInsets.fromLTRB(80, 0, 80, 0),
          textStyle: TextStyle(
            //modifica colore testo
            color: Colors.black,
          ),
          decoration: BoxDecoration(
            //modifica box tooltip
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),

        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const CircleBorder(), //shape of button
        onTap: () {
          eProvider.resetEditor();
          pProvider.setShowBottomPanel(true);
          pProvider.setHeightMap(70);
          pProvider.setHeightPanel(30);
          pProvider.setIconAndPanel(
              en.Panel.info, MdiIcons.informationSlabCircle, Colors.black);
          pProvider.setPanel(en.Panel.info);
        },
        //onLongPress: () => print('SECOND CHILD LONG PRESS'),
      ),
      SpeedDialChild(
        label: showDialLabel==true? loc.changePosition: null,

        // reset geometry

        child: Tooltip(
          //parte per vedere infomazioni icona
          message: AppLocalizations.of(context)!.changePosition,
          child: Icon(MdiIcons.swapHorizontal, size: 40),
          //set posizione del tooltip
          preferBelow: false,
          verticalOffset: -20,
          margin: EdgeInsets.fromLTRB(80, 0, 80, 0),
          textStyle: TextStyle(
            //modifica colore testo
            color: Colors.black,
          ),
          decoration: BoxDecoration(
            //modifica box tooltip
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),

        shape: const CircleBorder(), //shape of button
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        onTap: () {
          eProvider.resetEditor();
          eProvider.showForm = false;
          // set panel
          pProvider.setShowBottomPanel(true);
          pProvider.setHeightMap(70);
          pProvider.setHeightPanel(30);
          pProvider.setIconAndPanel(
              en.Panel.resetGeometry, MdiIcons.swapHorizontal, Colors.orange);
          pProvider.setPanel(en.Panel.resetGeometry);
        },
        //onLongPress: () => print('SECOND CHILD LONG PRESS'),
      ),

      SpeedDialChild(
          label: showDialLabel==true? loc.changeMap: null,

        //cambio tipo di mappa
        child: Tooltip(
          message: AppLocalizations.of(context)!.map,
          child: Icon(Icons.map, size: 40),
          preferBelow: false,
          verticalOffset: -20,
          margin: EdgeInsets.fromLTRB(80, 0, 80, 0),
          textStyle: TextStyle(
            color: Colors.black,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(), //shape of button
        onTap: () {
          // set panel
          eProvider.resetEditor();
          eProvider.showForm = true;
          // set panel
          pProvider.setShowBottomPanel(true);
          pProvider.setHeightMap(90);
          pProvider.setHeightPanel(10);
          pProvider.setPanel(en.Panel.map);
          // set editor
          pProvider.setIconAndPanel(en.Panel.map, Icons.map, Colors.blue);
        },
      ),

      SpeedDialChild(
        label: showDialLabel==true? loc.delete: null,
        // delete
        child: Tooltip(
          //parte per vedere infomazioni icona
          message: AppLocalizations.of(context)!.delete,
          child: Icon(MdiIcons.delete, size: 40),
          //set posizione del tooltip
          preferBelow: false,
          verticalOffset: -20,
          margin: EdgeInsets.fromLTRB(80, 0, 80, 0),
          textStyle: TextStyle(
            //modifica colore testo
            color: Colors.black,
          ),
          decoration: BoxDecoration(
            //modifica box tooltip
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),

        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: const CircleBorder(), //shape of button
        onTap: () {
          eProvider.resetEditor();
          // set panel
          pProvider.setShowBottomPanel(true);
          pProvider.setHeightMap(70);
          pProvider.setHeightPanel(30);
          pProvider.setIconAndPanel(
              en.Panel.delete, MdiIcons.delete, Colors.red);
          pProvider.setPanel(en.Panel.delete);
        },
        //onLongPress: () => print('SECOND CHILD LONG PRESS'),
      ),
    ],
  );
  //print(eProvider.handType);
//  if (eProvider.handType == 1) {
    return <Widget>[
      Scaffold(
        // project list
        appBar: appBar,
        body: ProjectTable(prj2: gProvider.projList),
      ),
      Column(children: <Widget>[
        Expanded(
            flex: pProvider.heightMap,
            child: Container(
                child: Stack(
              children: <Widget>[
                flutterMap,
                // mancino o destro
                Align(
                    // floating bottons over map
                    alignment: gProvider.idHandness == 0
                                ?Alignment.bottomRight
                                :Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
                      child: dialButtons,
                    )),
              ],
            ))),
        Visibility(
            visible: pProvider.showPanel,
            //visible: true,
            child:
                // info bar
                Expanded(
                    flex: pProvider.heightPanel,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(width: 2.0, color: Colors.blue),
                          bottom: BorderSide(width: 2.0, color: Colors.blue),
                        ),
                      ),
                      child: getPanel(context, pProvider.panel),
                    ))),
      ]),
      Container(
        color: Colors.white,
        alignment: Alignment.topLeft,
        child: getResultPage(context),
      ),
      Container(
          // Pagina Other a fine File
          child: const oth.OtherWidget())
    ];
}

List<DropdownMenuItem<int>> getDropdownResult(
    gi.InfoResult resultTotal,
    Map<int, gi.InfoResult> resultSpecies,
    Map<int, String> species3, // intersect ParamSpecies name/id with result id
    String locale,
) {
    List<DropdownMenuItem<int>> menuItems = [];
    Map<int, String> aggResult = {};
    final totString = locale == 'en' ? 'Total' : 'Totale';
    menuItems.add(DropdownMenuItem(
            value: -2,
            child: Text(totString),
    ));
    species3.forEach((key, value) {
        menuItems.add(DropdownMenuItem(
                value: key,
                child: Text(value),
        ));
    });
    return menuItems;
}

Widget getResultPage(BuildContext context) {
    final rProvider = Provider.of<pr.ResultProvider>(context, listen: true);
    final gProvider = Provider.of<pr.GlobalProvider>(context, listen: false);
    final parProvider = Provider.of<pr.ParamProvider>(context, listen: false);

    List<DropdownMenuItem<int>> dropdownResultItems = [];

    Widget graph = const Text('');
    String graphUnit = '';
    String graphName = '';
    Text period = const Text('');
    final locale = Localizations.localeOf(context).toString();


    if (rProvider.infoResultTotal != null) {
        dropdownResultItems = getDropdownResult(
            rProvider.infoResultTotal!,
            rProvider.infoResult4species,
            rProvider.id2species,
            locale,
        );
        period = Text(rProvider.getPeriod(locale));
    }

    var idProject = gProvider.idProject;
    List<TableRow> rows = [];
    gi.InfoResult result;
    if (rProvider.infoResultTotal != null) {
        if (rProvider.dropdownItemId == -2) {
            result = rProvider.infoResultTotal!;
        } else {
            result = rProvider.infoResult4species[rProvider.dropdownItemId]!;
        }
        graph = result.getGraph(rProvider.pollutantId, locale);
        graphUnit = result.unitArray;
        graphName = result.nameArray;
        rows = result.getTableRows(parProvider.par3, locale);
    }

  var visibilityGetResult = false;
  var visibilityInfoResult = false;
  List<int> visibilityStatus2 = [-1, 0, 3];

  var appBarColor = Colors.blue;
  var msg = '';
  var visibleMsg = false;

  if (gProvider.project != null) {
    // a project has been selected
    // msg
    if (gProvider.project!.hasData == 0) {
      msg = AppLocalizations.of(context)!.noData;
      visibleMsg = true;
    }
    visibleMsg = gProvider.project!.hasData == 0;
    switch (gProvider.project!.status) {
      case 0:
        appBarColor = Colors.grey;
        msg = AppLocalizations.of(context)!.greyServer;
        visibleMsg = true;
        break;
      case 1:
        appBarColor = Colors.green;
        msg = AppLocalizations.of(context)!.greenServer;
        visibleMsg = true;
        break;
      case 2:
        appBarColor = Colors.blue;
        break;
      case 3:
        appBarColor = Colors.orange;
        msg = AppLocalizations.of(context)!.orangeServer;
        visibleMsg = true;
        break;
    }
    if (gProvider.project!.hasData == 1) {
        // always show get result button
        visibilityGetResult = true;
        if (visibilityStatus2.contains(gProvider.project!.status)) {
            visibilityGetResult = true;
        } else {
            visibilityInfoResult = true;
        }
    }
  }

  final buttonGetResult = Visibility(
      visible: visibilityGetResult,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.get_app, size: 30),
            label: const Text('get result'),
            style: ButtonStyle(
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: const BorderSide(color: Colors.white))),
            ),
            onPressed: () {
              // gProvider.projectStatus = 1;
              // gProvider.project!.status = 1;
              // // db.Project.setStatus(gProvider.project!.idProject, 1);
              // gProvider.getProjects();
              setProjectCoords(context);
              rProvider.sendProject(idProject).then((response) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response)),
                );
                if (response != 'Server upload issue') {
                  // db.Project.setStatus(gProvider.project!.idProject, 2);
                    gProvider.projectStatus = 1;
                    gProvider.project!.status = 1;
                    // db.Project.setStatus(gProvider.project!.idProject, 1);
                    gProvider.getProjects();
                }

              });
            },
          )));


  final language = Localizations.localeOf(context).toString();
  const infoEn = '''
    Canopy area: Total canopy area covered by trees, tree lines and forests. The pollutant removal is calculated on this area for the selected period
    NPP: Net Primary Production, the amount of carbon removed from the atmosphere by photosynthesis
    O₃: Ozone, a gas that can cause respiratory problems
    PM₁: Particulate Matter with a diameter of 1 micrometers or less
    PM₂₅: Particulate Matter with a diameter of 2.5 micrometers or less
    PM₁₀: Particulate Matter with a diameter of 10 micrometers or less
    NO₂: Nitrogen Dioxide is an gas with a strong odor, irritating for the respiratory system and eyes
    SO₂: Sulfur Dioxide is a gas with a strong odor, irritating for the respiratory system and eyes
    CO: Carbon Monoxide is an odorless gas that can cause respiratory problems
  ''';
  const infoIt = '''
    Canopy area: Superficie totale della chioma coperta da alberi, filari di alberi e foreste. La rimozione degli inquinanti è calcolata su questa superficie per il periodo selezionato
    NPP: Produzione primaria netta, la quantità di carbonio rimossa dall'atmosfera mediante la fotosintesi
    O₃: Ozono, un gas che può causare problemi respiratori
    PM₁: Particolato con un diametro pari o inferiore a 1 micrometro
    PM₂₅: Particolato con un diametro pari o inferiore a 2,5 micrometri
    PM₁₀: Particolato con un diametro pari o inferiore a 10 micrometri
    NO₂: Il biossido di azoto è un gas dal forte odore, irritante per le vie respiratorie e gli occhi
    SO₂: L’anidride solforosa è un gas dal forte odore, irritante per le vie respiratorie e gli occhi
    CO: Il monossido di carbonio è un gas inodore che può causare problemi respiratori
 ''';
  final infoResult = Visibility(
      visible: visibilityInfoResult,
      child:  Padding(
          padding: const EdgeInsets.all(16.0),
          child:
          Tooltip(
              showDuration: Duration(seconds: 20),
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              verticalOffset: -15,
              margin: const EdgeInsets.fromLTRB(30, 0, 30, 0),
              message: language == 'en' ? infoEn : infoIt,
              child: const Icon(Icons.info)
          ),
      ),
      );


  return Scaffold(
      appBar: AppBar(
        title: Text(gProvider.projectName),
        actions: <Widget>[infoResult, buttonGetResult],
        backgroundColor: appBarColor,
      ),
      body: Container(
        color: Colors.white,
        width: double.infinity,
        child: Column(children: [
          Visibility(
            visible: visibleMsg,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8),
                child: Text(msg),
            ),
          ),
          Visibility(
            visible: rProvider.ready,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: period,
                ),
                DropdownButton(
                  value: rProvider.dropdownItemId,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: dropdownResultItems,
                  onChanged: (int? newValue) {
                    rProvider.setDropdownItemId(newValue!);
                  },
                ),
                Container(
                  margin: const EdgeInsets.all(15.0),
                  padding: const EdgeInsets.all(3.0),
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.blue)),
                  child: Table(
                      border: const TableBorder(
                          horizontalInside: BorderSide(
                              width: 1,
                              color: Colors.blue,
                              style: BorderStyle.solid)),
                      children: rows),
                ),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(10),
                    children: getPollutantButtonList(context),
                  ),
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(top: 10, right: 30, bottom: 10),
                    child: Column(
                      children: [
                        Text("$graphName ($graphUnit)"),
                        const Padding(padding: EdgeInsets.all(3)),
                        graph,
                      ],
                    )),
              ],
            ),
          )
        ]),
      ));
}

class ProjectTable extends StatefulWidget {
  List<dat.Project> prj2;
  ProjectTable({super.key, required this.prj2});

  @override
  State<ProjectTable> createState() => _ProjectTableState();
}

class _ProjectTableState extends State<ProjectTable> {
  bool sort = false;
  int numItems = 1;

  @override
  Widget build(BuildContext context) {
    final rProvider = Provider.of<pr.ResultProvider>(context, listen: false);
    final eProvider = Provider.of<pr.EditorProvider>(context, listen: false);
    numItems = widget.prj2.length;
    final double sWidth = MediaQuery.of(context).size.width;

    return Consumer2<pr.GlobalProvider, pr.MapProvider>(
        builder: (context, gProvider, mProvider, child) {
      return Container(
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: 2,
                  sortAscending: sort, // TODO: implement sorting and searching
                  sortColumnIndex: 0, // TODO: as above

                  columns: <DataColumn>[
                    DataColumn(
                        label: SizedBox(
                      width: sWidth * 0.45,
                      child: Text(AppLocalizations.of(context)!.nameProject),
                    )),
                    DataColumn(
                        label: SizedBox(
                      width: sWidth * 0.20,
                      child: Text(AppLocalizations.of(context)!.dateProject),
                    )),
                    DataColumn(
                        label: Container(
                      width: sWidth * 0.15,
                      alignment: Alignment.center,
                      child: const Text(''),
                    )),
                    DataColumn(
                        label: Container(
                      width: sWidth * 0.15,
                      alignment: Alignment.centerLeft,
                      child: const Text(''),
                    )),
                  ],
                  rows: List<DataRow>.generate(
                    numItems,
                    (int index) => DataRow(
                      color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.green.withOpacity(0.3);
                        }
                        if (index.isEven) {
                          return Colors.grey.withOpacity(0.3);
                        }
                        return null;
                      }),
                      cells: <DataCell>[
                        DataCell(Text(widget.prj2[index].name)),
                        DataCell(Text(
                            DateFormat(AppLocalizations.of(context)!.formatDate)
                                .format(DateTime.fromMillisecondsSinceEpoch(
                                    widget.prj2[index].lastUpdate * 1000)))),
                        DataCell(
                          IconButton(
                              icon: const Icon(Icons.info),
                              onPressed: () async {
                                // TODO: display project info
                                var prj = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => inp.MyCustomFormProject(
                                          idUser: gProvider.idUser,
                                          project: widget.prj2[index],
                                      )),
                                );
                              }),
                        ),
                        DataCell(
                          Tooltip(
                            message: getStatusMessage(
                                AppLocalizations.of(context)!.soilLanguage,
                                widget.prj2[index].status),
                            child: IconButton(
                              icon: const Icon(Icons.circle, size: 20.0),
                              color:
                                  getIconStatusColor(widget.prj2[index].status),
                              onPressed: () {
                                // TODO: display message of status when long pressed
                              },
                            ),
                          ),
                        )
                      ],
                      selected: gProvider.indexPrjTable ==
                          index, // change color of selected row
                      onSelectChanged: (bool? value) {
                        setState(() {
                          // store project info
                          gProvider.setProject4table(index);

                          // reset providers
                          eProvider.reset();
                          if (gProvider.project!.hasData == 1) {
                            eProvider.setProjectLatLng(
                                gProvider.project!.lat, gProvider.project!.lon);

                            // on map tab zoom to project geometries
                            mProvider.startLat = gProvider.project!.lat;
                            mProvider.startLon = gProvider.project!.lon;
                          }
                          // set results and map data
                          rProvider.dropdownItemId = -2;
                          rProvider.reset();
                          if ((gProvider.idProject !=
                                  gProvider.previousIdProject) ||
                              gProvider.previousIdProject.isEmpty) {
                            mProvider.initGeometries(
                                context, gProvider.idProject);
                            if (gProvider.projectStatus == 2 ||
                                gProvider.projectStatus == 3) {
                              rProvider
                                  .getResultFromDb(gProvider.idProject)
                                  .then((value) {
                                rProvider.setReady(true);
                              });
                            } else {
                              rProvider.setReady(false);
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              )));
    });
  }
}

Color getIconStatusColor(int status) {
    switch (status) {
        case -1: // project error
            return Colors.red;
        case 0: // project initialized
            return Colors.grey;
        case 1: // results are being calculated from server
            return Colors.green;
        case 2: // results are ready and updated
            return Colors.blue;
        case 3: // results are ready but outdated (project has been modified after results were calculated)
            return Colors.orange;
        default:
            return Colors.black;
    }
}

String getStatusMessage(String lan, int status) {
    if (lan == "en") {
    switch (status) {
      case -1:
        return "Project Error";
      case 0:
        return "Project Initialized";
      case 1:
        return "Elaboration data";
      case 2:
        return "Results are ready";
      case 3:
        return "Data have been changed";
      default:
        return "Unknown Status";
    }
  } else {
    switch (status) {
      case -1:
        return "Errore";
      case 0:
        return "Progetto inizializzato";
      case 1:
        return "Elaborazione dei dati";
      case 2:
        return "Risultati pronti";
      case 3:
        return "Dati modificati";
      default:
        return "Stato sconosciuto";
    }
  }
}


