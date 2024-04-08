/// geographic widgets
library;

import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data.dart' as dat; 
import 'providers.dart' as pr;
import 'enums.dart' as en;
import 'icon.dart' as ic;
import 'geo_info.dart';
import 'database.dart' as db;





// ----------------------------------------------------------------------------
// MARKER
// ----------------------------------------------------------------------------
// implements placeholders to interact with points, lines and polygons
// why? A unique layer is required by flutter_map for tap actions on markers
// https://stackoverflow.com/questions/54617432/looking-up-a-deactivated-widgets-ancestor-is-unsafe
class UniqueMarker extends fm.Marker { //ignore: must_be_immutable
    final en.EditorType type;
    InfoPoint?   infoPoint;
    InfoLine?    infoLine;
    InfoPolygon? infoPolygon;
    String id;

    UniqueMarker({
        super.key,
        required this.type,
        required super.point,
        //required BuildContext context,
        required this.id,
        required super.child,

        this.infoPoint,
        this.infoLine,
        this.infoPolygon,

        super.width = 30.0,
        super.height = 30.0,
        super.rotate,
        Offset? rotateOrigin,
        AlignmentGeometry? rotateAlignment,
        //fm.AnchorPos? anchorPos,
    });

    db.Point getNewPoint(BuildContext context, LatLng pnt) {
        // only points can be converted to data points 
        assert(type == en.EditorType.point);
        assert(infoPoint != null);
        return db.Point(
            idProject      : infoPoint!.pnt.idProject,
            idUser         : infoPoint!.pnt.idUser,
            lastUpdate     : DateTime.now().millisecondsSinceEpoch ~/ 1000,        
            id            : infoPoint!.pnt.id,
            idSpecies     : infoPoint!.pnt.idSpecies,
            diameter      : infoPoint!.pnt.diameter,
            height        : infoPoint!.pnt.height,
            crownHeight   : infoPoint!.pnt.crownHeight,
            crownDiameter : infoPoint!.pnt.crownDiameter,
            lai           : infoPoint!.pnt.lai,
            truth         : infoPoint!.pnt.truth,
            latlng        : pnt,
        );
    }

    db.Point toPoint(BuildContext context) {
        //assert(type == en.EditorType.point);
        assert(infoPoint != null);
        return db.Point(
            idProject      : infoPoint!.pnt.idProject,
            idUser         : infoPoint!.pnt.idUser,
            lastUpdate     : DateTime.now().millisecondsSinceEpoch ~/ 1000,
            id            : infoPoint!.pnt.id,
            idSpecies     : infoPoint!.pnt.idSpecies,
            diameter      : infoPoint!.pnt.diameter,
            height        : infoPoint!.pnt.height,
            crownHeight   : infoPoint!.pnt.crownHeight,
            crownDiameter : infoPoint!.pnt.crownDiameter,
            lai           : infoPoint!.pnt.lai,
            truth         : infoPoint!.pnt.truth,
            latlng        : point,
        );
    }




    static UniqueMarker fromPoint(BuildContext context, db.Point point, Container icon) {
        final keyPt =  GlobalKey();

        return UniqueMarker(
            key           : keyPt,
            type          : en.EditorType.point,
            id            : point.id,
            point         : point.latlng,
            infoPoint     : InfoPoint(
                pnt: point
            ),
            child: //(ctx) //=> const Icon(Icons.circle, size: 15, color: Colors.red),
            GestureDetector(
                onTap: () {

                    final mProvider = Provider.of<pr.MapProvider>(keyPt.currentContext!, listen: false);
                    final pProvider = Provider.of<pr.PanelProvider>(keyPt.currentContext!, listen: false);
                    var action2 = [
                        en.Panel.info,
                        en.Panel.resetGeometry,
                        en.Panel.delete,
                    ];
                    if (action2.contains(pProvider.panel)){
                        mProvider.changeSelectedMarker(
                            fromPoint(context, point, ic.Air.selected));
                        pProvider.showPanel = true;
                    }
                },
                child: icon
            ));
    }

    static UniqueMarker fromGeoLine(BuildContext context, GeoLine line, Container icon) {
        final keyPt =  GlobalKey();

        return UniqueMarker(
            key           : keyPt,
            type          : en.EditorType.line,
            id            : line.line.id,
            point         : line.points[0],
            infoLine      : InfoLine(
                line: line.line
            ),
            child:
            GestureDetector(
                onTap: () {
                    final mProvider = Provider.of<pr.MapProvider>(keyPt.currentContext!, listen: false);
                    final pProvider = Provider.of<pr.PanelProvider>(keyPt.currentContext!, listen: false);
                    var action2 = [
                        en.Panel.info,
                        en.Panel.resetGeometry,
                        en.Panel.delete,
                    ];
                    if (action2.contains(pProvider.panel)){
                        //var icon1 = Icon(Icons.circle, size: 30, color: Colors.yellow.withOpacity(0.5));
                        mProvider.changeSelectedMarker(
                            fromGeoLine(context, line, ic.Air.selected));
                        pProvider.showPanel = true;
                    }
                },
                child: icon,
            ));
    }


    static UniqueMarker fromGeoPolygon(BuildContext context, GeoPolygon pol, List<InfoElementPolygon> data2, Container icon) {

        final keyPt =  GlobalKey();

        return UniqueMarker(
            key           : keyPt,
            type          : en.EditorType.polygon,
            id            : pol.polygonGeometry.id,
            point         : pol.points[0],
            infoPolygon     : InfoPolygon(
                id            : pol.polygonGeometry.id,
                element2      : data2,
            ),
            child: GestureDetector(
                onTap: () {
                    final mProvider = Provider.of<pr.MapProvider>(keyPt.currentContext!, listen: false);
                    final pProvider = Provider.of<pr.PanelProvider>(keyPt.currentContext!, listen: false);
                    var action2 = [
                        en.Panel.info,
                        en.Panel.resetGeometry,
                        en.Panel.delete,
                    ];
                    if (action2.contains(pProvider.panel)){
                        //var icon1 = Icon(Icons.circle, size: 30, color: Colors.yellow.withOpacity(0.5));
                        mProvider.changeSelectedMarker(
                            fromGeoPolygon(context, pol, data2, ic.Air.selected));
                        pProvider.showPanel = true;
                    }
                },
                child: icon
            ));
    }

    String getId() {
        switch (type) {
            case en.EditorType.point:
                return infoPoint!.pnt.id;
            case en.EditorType.line:
                return infoLine!.line.id;
            case en.EditorType.polygon:
                int index = infoPolygon!.indexElement;
                return infoPolygon!.element2[index].polData.id;
            default:
                return '';
        }
    }


    List<TableRow> getTableRows(Map<int, dat.ParamRow>mapInt) {
        switch (type) {
            case en.EditorType.point:
                return infoPoint!.getTableRows(type, mapInt);
            case en.EditorType.line:
                return infoLine!.getTableRows(type, mapInt);
            case en.EditorType.polygon:
                return infoPolygon!.getTableRows(mapInt);
            default:
                return [];
        }
    }

    void delete(BuildContext context) {
        switch (type) {
            case en.EditorType.point:
                infoPoint!.delete(context);
                break;
            case en.EditorType.line:
                infoLine!.delete(context);
                break;
            case en.EditorType.polygon:
                infoPolygon!.delete(context);
                break;
            default:
                break;
        }
    }

    void editGeometry(BuildContext context) {
        final mProvider = Provider.of<pr.MapProvider>(context, listen: false);
        final pProvider = Provider.of<pr.PanelProvider>(context, listen: false);
        final eProvider = Provider.of<pr.EditorProvider>(context, listen: false);

        eProvider.selectedId = id;
        switch(type){
            case en.EditorType.point:
                //var marker = mProvider.marker2.firstWhere((p)=>p.id == id);
                //mProvider.resetSelectedMarker2();
                //eProvider.pointEditorAdd(marker.point);
                pProvider.setPanel(en.Panel.addTree);
                break;
            case en.EditorType.line:
                var line = mProvider.treeLine2.firstWhere((p)=>p.line.id == id);
                mProvider.resetSelectedMarker2();
                eProvider.lineTest.points.addAll(line.points);
                pProvider.setPanel(en.Panel.addRow);
                break;
            case en.EditorType.polygon:
                var pol = mProvider.forest2.firstWhere((p)=>p.polygonGeometry.id == id);
                mProvider.resetSelectedMarker2();
                eProvider.testPolygon.points.addAll(pol.points);
                pProvider.setPanel(en.Panel.addForest);
                break;
            default:
                break;
        }
    }

}

// ----------------------------------------------------------------------------
// LINE
// ----------------------------------------------------------------------------
class GeoLine extends fm.Polyline {
    final db.Line line;

    GeoLine({
        Key? key,
        required this.line,

    }) : super(
    strokeWidth: 2,
    color: line.truth == 1? Colors.green : Colors.blue,
    points: line.coords,
    );

}

// ----------------------------------------------------------------------------
// POLYGON
// ----------------------------------------------------------------------------
// Polygon data is implemented as one to many relationship with data.ForestInfo
// id<GreenPolygon> ==> idGeometry<ForestInfo> 
class GeoPolygon extends fm.Polygon{
    final db.PolygonGeometry polygonGeometry;

    GeoPolygon({
        Key? key,
        required this.polygonGeometry,
    }) : super(
    points: polygonGeometry.coords,
    color: polygonGeometry.truth==1? Colors.green.withOpacity(0.4): Colors.blue.withOpacity(0.4),
    isFilled: true,
    );
}

