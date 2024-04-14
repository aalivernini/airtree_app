import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:latlong2/latlong.dart';
import 'package:objectid/objectid.dart';
import 'package:flutter/services.dart';
import 'data.dart' as dat;
import 'dart:typed_data';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'export_import_database.dart' as ex;
import 'package:geojson_vi/geojson_vi.dart' as geoj;
//import 'package:collection/collection.dart';
import 'package:archive/archive_io.dart';


import 'io.dart' as io;

// interface of data.Point to db
const String databaseName = 'data_41.db';
const String databaseParam = 'param_mobile.sqlite';
const exDbName = 'exported_database.sqlite';
const String projectGeojsonName = 'project.geojson';

class Param {
    static Future<List<dat.ParamRow>> getParamList(int idLanguageSpecies) async {
        var databasesPath = await getDatabasesPath();
        var path = join(databasesPath, databaseParam);

        // Check if the database exists
        var exists = await databaseExists(path);

        if (!exists) {
            // Make sure the parent directory exists
            try {
                await Directory(dirname(path)).create(recursive: true);
            } catch (_) {}

            // Copy from asset
            ByteData data = await rootBundle.load(url.join("assets", databaseParam));
            List<int> bytes =
                    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            // Write and flush the bytes written
            await File(path).writeAsBytes(bytes, flush: true);
        }

        String speciesColumn;
        switch (idLanguageSpecies) {
            case 0:
                speciesColumn = 'species';
                break;
            case 1:
                speciesColumn = 'species_eng';
                break;
            case 2:
                speciesColumn = 'species_ita';
                break;
            default:
                speciesColumn = 'species';
        }
        final db = await openDatabase(path);
        final List<Map<String, dynamic>> maps = await db.query('db');
        return List.generate(maps.length, (i) {
            return dat.ParamRow(
                 airtreeId: maps[i]['id_airtree'],
                 name: maps[i][speciesColumn],
                 diameter: maps[i]['dbh'],
                 height: maps[i]['height'],
                 crownHeight: maps[i]['height'] * 0.7,
                 crownDiameter: maps[i]['crownwidth'],
                 lai: maps[i]['lai']
            );
        });
    }

}


mixin Base {
  static Future<Database> getConnection() async {
    // Open the database and store the reference.
    final database = openDatabase(
      join(await getDatabasesPath(), databaseName),
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE points(
                        id TEXT UNIQUE,
                        id_project TEXT,
                        id_user TEXT,
                        lat REAL,
                        lon REAL,
                        last_update INTEGER,
                        id_species INTEGER,
                        diameter INTEGER,
                        height REAL,
                        crown_height REAL,
                        crown_diameter REAL,
                        lai REAL,
                        truth INTEGER,
                        id_int INTEGER PRIMARY KEY
                    )''');
        await db.execute('''CREATE TABLE line(
                        id TEXT UNIQUE,
                        id_project TEXT,
                        id_user TEXT,
                        json_geometry TEXT,
                        last_update INTEGER,
                        id_species INTEGER,
                        diameter INTEGER,
                        height REAL,
                        crown_height REAL,
                        crown_diameter REAL,
                        lai REAL,
                        truth INTEGER,
                        tree_number INTEGER,
                        length REAL,
                        id_int INTEGER PRIMARY KEY
                    )''');
        await db.execute('''CREATE TABLE polygon_geometry(
                        id TEXT UNIQUE,
                        id_project TEXT,
                        id_user TEXT,
                        json_geometry TEXT,
                        last_update INTEGER,
                        truth INTEGER,
                        id_int INTEGER PRIMARY KEY
                    )''');

        await db.execute('''CREATE TABLE polygon_data(
                        id TEXT UNIQUE,
                        id_project TEXT,
                        id_user TEXT,
                        id_geometry TEXT,
                        last_update INTEGER,
                        id_species INTEGER,
                        diameter INTEGER,
                        height REAL,
                        crown_height REAL,
                        crown_diameter REAL,
                        lai REAL,
                        truth INTEGER,
                        percent_area INTEGER,
                        percent_cover INTEGER,
                        area REAL,
                        id_int INTEGER PRIMARY KEY
                    )''');

        await db.execute('''
                    CREATE TABLE projects(
                        id_project  TEXT UNIQUE,
                        id_user  TEXT ,
                        name TEXT,
                        location TEXT,
                        description TEXT,
                        last_update INTEGER,
                        start_date INTEGER,
                        end_date  INTEGER,
                        private_project INTEGER,
                        irrigation INTEGER,
                        status INTEGER,
                        lat REAL,
                        lon REAL,
                        id_soil_texture INTEGER,
                        has_data INTEGER,
                        id_int INTEGER PRIMARY KEY
                    )''');
        await db.execute('''
                    CREATE TABLE user(
                        id_user TEXT UNIQUE,
                        nome TEXT,
                        cognome TEXT,
                        username TEXT UNIQUE,
                        email TEXT,
                        password TEXT,
                        id_int INTEGER PRIMARY KEY
                    )''');
        await db.execute('''
                    CREATE TABLE settings(
                        atm_time_start INTEGER,
                        atm_time_end INTEGER,
                        version STRING "1",
                        id_int INTEGER PRIMARY KEY
                    )''');
        await db.execute('''
                    CREATE TABLE result(
                         id_user     TEXT,
                         id_project  TEXT,
                         id_species  INTEGER,
                         id          TEXT,
                         last_update INTEGER,
                         start_date  INTEGER,
                         end_date    INTEGER,
                         canopy_area REAL,
                         npp         REAL,
                         o3          REAL,
                         pm1         REAL,
                         pm2_5       REAL,
                         pm10        REAL,
                         no2         REAL,
                         so2         REAL,
                         co          REAL,
                         ts_npp      BLOB,
                         ts_o3       BLOB,
                         ts_pm10     BLOB,
                         ts_pm2_5    BLOB,
                         ts_pm1      BLOB,
                         ts_no2      BLOB,
                         ts_so2      BLOB,
                         ts_co       BLOB,
                         ts_time     BLOB,
                         id_int      INTEGER PRIMARY KEY
                    )''');

        await db.execute('''
                CREATE TABLE user_setting(
                    id_language_interface INTEGER,
                    id_language_species   INTEGER,
                    id_handness           INTEGER,
                    id_privacy_terms      INTEGER,
                    id_help_label         INTEGER,
                    id_vertex_colour      INTEGER,
                    size_panel_edit       INTEGER,
                    size_panel_info       INTEGER,
                    size_character        INTEGER,
                    id_int                INTEGER PRIMARY KEY
                )''');
      },
      onUpgrade: (db, oldVersion, version) async {
        await db.execute('DROP TABLE IF EXISTS user');

        await db.execute('''
                CREATE TABLE user(
                    id_user TEXT UNIQUE,
                    nome TEXT,
                    cognome TEXT,
                    username TEXT UNIQUE,
                    email TEXT,
                    password TEXT,
                    id_int INTEGER PRIMARY KEY
                )''');
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 3,
    );

    return database;
  }

//  geojson
    static Future<String> generateGeoJSONFile() async {
        final db = await getConnection();

        // Esempio: Recupera tutti i punti dal database
        final List<Map<String, dynamic>> points = await db.query('points');

        final featureCollection = {
        'type': 'FeatureCollection',
        'features': [
            for (final point in points)
        {
            'type': 'Feature',
            'geometry': {
            'type': 'Point',
            'coordinates': [point['lon'], point['lat']],
        },
            'properties': {
            'id': point['id'],
            'id_project': point['id_project'],
            'id_user': point['id_user'],
            'diameter': point['diameter'],
            'height': point['height'],
            'crownHeight': point['crown_height'],
            'crownDiameter': point['crown_diameter'],
            'lai': point['lai'],
            // Aggiungi altri campi necessari
        },
        },
            // Puoi aggiungere qui altri tipi di geometrie (LineString, Polygon, etc.)
        ],
    };

        // Converti l'oggetto GeoJSON in una stringa JSON
        final geoJSONString = json.encode(featureCollection);
        final destinationPath = await ex.getTemporaryPath(projectGeojsonName);
        //Salva la stringa GeoJSON su un file
        final File file = File(destinationPath);
        await file.writeAsString(geoJSONString);
        return destinationPath;
    }

    static Future<void> shareFile(String filePath, String name) async {
        List<String> files = [filePath];

        await Share.shareFiles(
            files,
            text: 'GeoJson File',
            subject: name,
        );
    }

    Future<Database> connect() async {
        return getConnection();
    }
}

class DatabaseManager {
    // Mock User Method
    // TODO: implement user registration and login
    static Future<dat.User> getUser() async {
        dat.User user;

        // Get a reference to the database.
        final db = await Base.getConnection();

        // try to get user from db. If not present, create an anonymous user
        final List<Map<String, dynamic>> maps = await db.query('user');
        if (maps.isEmpty) {
            var idUser = ObjectId().hexString;
            user = dat.User(
                idUser: idUser,
                nome: "",
                cognome: "",
                username: "",
                email: "",
                password: "",
            );

            db.insert(
                'user',
                {
                  'id_user': user.idUser,
                  'nome': "",
                  'cognome': "",
                  'username': "",
                  'email': "",
                  'password': "",
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
           );
        } else {
            user = dat.User(
                idUser: maps[0]['id_user'],
                nome: maps[0]['nome'],
                cognome: maps[0]['cognome'],
                username: maps[0]['username'],
                email: maps[0]['email'],
                password: maps[0]['password'],
            );
        }
        return user;
    }

    static createUser(data) async {
        final db = await Base.getConnection();

        db.update('user', {
            'nome': data['nome'],
            'cognome': data['cognome'],
            'username': data['username'],
            'email': data['email'],
            'password': data['password'],
        });
        final List<Map<String, dynamic>> maps = await db.query('user');
    }

    // retrieve all projects from the database
    static Future<List<dat.Project>> getProject2() async {
        // Get a reference to the database.
        final db = await Base.getConnection();

        // Query the table for all The Dogs.
        final List<Map<String, dynamic>> maps = await db.query('projects');
        developer.log("projects length: ${maps.length}");

        // Convert the List<Map<String, dynamic> into a List<Project>.
        return List.generate(maps.length, (i) {
            return dat.Project(
                idProject: maps[i]['id_project'],
                idUser: maps[i]['id_user'],
                name: maps[i]['name'],
                location: maps[i]['location'],
                description: maps[i]['description'],
                lastUpdate: maps[i]['last_update'],
                startDate: maps[i]['start_date'],
                endDate: maps[i]['end_date'],
                privateProject: maps[i]['private_project'],
                irrigation: maps[i]['irrigation'],
                status: maps[i]['status'],
                idSoilTexture: maps[i]['id_soil_texture'],
                lat: maps[i]['lat'],
                lon: maps[i]['lon'],
                hasData: maps[i]['has_data'],
            );
        });
    }

    /// read points table into List<Point>
    static Future<List<Point>> getPoint2(String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM points WHERE id_project=?', [idProject]);
        return List.generate(maps.length, (i) {
            return Point(
                id: maps[i]['id'],
                idProject: maps[i]['id_project'],
                idUser: maps[i]['id_user'],
                lastUpdate: maps[i]['last_update'],
                idSpecies: maps[i]['id_species'],
                diameter: maps[i]['diameter'],
                height: maps[i]['height'],
                crownHeight: maps[i]['crown_height'],
                crownDiameter: maps[i]['crown_diameter'],
                lai: maps[i]['lai'],
                truth: maps[i]['truth'],
                latlng: LatLng(
                    maps[i]['lat'],
                    maps[i]['lon'],
                ),
            );
        });
    }

    /// read line table into List<Line>
    static Future<List<Line>> getLine2(String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps =
        await db.rawQuery('SELECT * FROM line WHERE id_project=?', [idProject]);
        return List.generate(maps.length, (i) {
            return Line(
                id: maps[i]['id'],
                idProject: maps[i]['id_project'],
                idUser: maps[i]['id_user'],
                lastUpdate: maps[i]['last_update'],
                idSpecies: maps[i]['id_species'],
                diameter: maps[i]['diameter'],
                height: maps[i]['height'],
                crownHeight: maps[i]['crown_height'],
                crownDiameter: maps[i]['crown_diameter'],
                lai: maps[i]['lai'],
                truth: maps[i]['truth'],
                treeNumber: maps[i]['tree_number'],
                setLength: maps[i]['length'],
                coords: Line.getCoordsFromJson(maps[i]['json_geometry']),
            );
        });
    }

    static Future<List<PolygonGeometry>> getPolygonGeometry2(
        String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db.rawQuery(
            'SELECT * FROM polygon_geometry WHERE id_project=?', [idProject]);
        return List.generate(maps.length, (i) {
            return PolygonGeometry(
                id: maps[i]['id'],
                idProject: maps[i]['id_project'],
                idUser: maps[i]['id_user'],
                lastUpdate: maps[i]['last_update'],
                setTruth: maps[i]['truth'],
                setArea: maps[i]['area'],
                coords: PolygonGeometry.getCoordsFromJson(maps[i]['json_geometry']),
            );
        });
    }

    static Future<Map<String, List<PolygonData>>> getPolygonData3(
        String idProject) async {
        // Get a reference to the database.
        final db = await Base.getConnection();

        // Query points table for all the points.
        //final maps = await db.query('points');
        final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM polygon_data WHERE id_project=?', [idProject]);

        var data2 = List.generate(maps.length, (i) {
            return PolygonData(
                id: maps[i]['id'],
                idProject: maps[i]['id_project'],
                idUser: maps[i]['id_user'],
                idGeometry: maps[i]['id_geometry'],
                lastUpdate: maps[i]['last_update'],
                idSpecies: maps[i]['id_species'],
                diameter: maps[i]['diameter'],
                height: maps[i]['height'],
                crownHeight: maps[i]['crown_height'],
                crownDiameter: maps[i]['crown_diameter'],
                lai: maps[i]['lai'],
                truth: maps[i]['truth'],
                percentArea: maps[i]['percent_area'],
                percentCover: maps[i]['percent_cover'],
                area: maps[i]['area'],
            );
        });

        Map<String, List<PolygonData>> data3 = {};
        for (var x in data2) {
        if (data3.containsKey(x.idGeometry)) {
        data3[x.idGeometry]?.add(x);
      } else {
        data3[x.idGeometry] = [];
        data3[x.idGeometry]?.add(x);
      }
    }
        return data3;
    }
}

class Project with Base {
    static Future<int> insertProject(dat.Project prj) async {
        // Get a reference to the database.
        final db = await Base.getConnection();
        final insertedId = await db.insert(
            'projects',
        {
            'id_project': prj.idProject,
            'id_user': prj.idUser,
            'name': prj.name,
            'location': prj.location,
            'description': prj.description,
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'start_date': prj.startDate,
            'end_date': prj.endDate,
            'private_project': prj.privateProject,
            'irrigation': prj.irrigation,
            'status': prj.status,
            'lat': prj.lat,
            'lon': prj.lon,
            'id_soil_texture': prj.idSoilTexture,
            'has_data': prj.hasData,
        },
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return insertedId;
    }

    static Future<int> setProjectCoords(
        String idProject, double latitude, double longitude, int hasData) async {
        final db = await Base.getConnection();
        int cnt = await db.update(
            'projects',
        {
            'lat': latitude,
            'lon': longitude,
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'has_data': hasData,
        },
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        return cnt;
    }

    static Future<int> setStatus(String idProject, int status) async {
        final db = await Base.getConnection();
        int cnt = await db.update(
            'projects',
        {
            'status': status,
        },
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        return cnt;
    }

    static Future<int> dbDelete(String idProject) async {
        // NOT IMPLEMENTED
        final db = await Base.getConnection();
        int cnt = await db.delete(
            'projects',
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        int cntResult = await deleteResult(idProject);
        int cntPoint = await db.delete(
            'points',
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        int cntLine = await db.delete(
            'line',
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        int cntPolygonGeometry = await db.delete(
            'polygon_geometry',
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        int cntPolygonData = await db.delete(
            'polygon_data',
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        int cntTotal = cnt + cntResult + cntPoint + cntLine + cntPolygonGeometry + cntPolygonData;
        return cntTotal;
    }

    static Future<int> deleteResult(String idProject) async {
        // NOT IMPLEMENTED
        final db = await Base.getConnection();
        int cnt = await db.delete(
            'result',
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        return cnt;
    }

    static Future<void> shareProject(String idProject, Map<int, dat.ParamRow> mapIntSpecies) async {
        final pathJson2 = <String>[];

        // GET RESULT
        final res3 = await getResult3(idProject);

        // GET TREES
        final pt2 = await DatabaseManager.getPoint2(idProject);
        final jsonPt2 = pt2.map((e) => e.toGeoJson(mapIntSpecies, res3)).toList();
        final ptCollection = geoj.GeoJSONFeatureCollection([]);
        ptCollection.features.addAll(jsonPt2);
        String jsonDump = ptCollection.toJSON();
        String path = await ex.getTemporaryPath("tree.geojson");
        await File(path)
                .writeAsString(jsonDump);
        pathJson2.add(path);

        // GET TREE ROWS
        final ln2 = await DatabaseManager.getLine2(idProject);
        final jsonLn2 = ln2.map((e) => e.toGeoJson(mapIntSpecies, res3)).toList();
        final lnCollection = geoj.GeoJSONFeatureCollection([]);
        lnCollection.features.addAll(jsonLn2);
        jsonDump = lnCollection.toJSON();
        path = await ex.getTemporaryPath("tree_row.geojson");
        await File(path)
                .writeAsString(jsonDump);
        pathJson2.add(path);

        // GET FOREST
        // get polygon data
        final polData3 = await DatabaseManager.getPolygonData3(idProject);
        // get polygon geometry
        final polGeometry3 = await DatabaseManager.getPolygonGeometry2(idProject);
        final jsonPol2 = polGeometry3.map((e) => e.toGeoJson(mapIntSpecies, polData3, res3)).toList();
        final polCollection = geoj.GeoJSONFeatureCollection([]);
        polCollection.features.addAll(jsonPol2);
        jsonDump = polCollection.toJSON();
        path = await ex.getTemporaryPath("forest.geojson");
        await File(path)
                .writeAsString(jsonDump);
        pathJson2.add(path);

        // GET TOTALS CSV [TODO]

        // CREATE ZIP & SHARE
        String pathZip = await ex.getTemporaryPath("airtree.zip");
        var encoder =  ZipFileEncoder();
        encoder.create(pathZip);
        for (var path in pathJson2) {
            await encoder.addFile(File(path));
        }
        encoder.close();
        Base.shareFile(pathZip, 'airtree.zip');
    }

    static Future<List<Map<String, dynamic>>> getResult2(String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM result WHERE id_project=?', [idProject]);
        return maps;
    }

    static Future<Map<String, Map<String, dynamic>>> getResult3(String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM result WHERE id_project=?', [idProject]);
        Map<String, Map<String, dynamic>> dict = {};
        for (var element in maps) {
            dict[element['id']] = element;
        }
        print(dict.keys.toList());
        return dict;
    }

    static Future<int> setUpdate(String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM projects WHERE id_project=?', [idProject]);
        final update3 = {
        'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
        final prj3 = maps[0];
        if (prj3['status'] == 2) {
      update3['status'] = 3;
    }

        int cnt = await db.update(
            'projects',
            update3,
            where: 'id_project = ?',
            whereArgs: [idProject],
        );
        return cnt;
    }

    // update progetti
    static Future<int> updateData(dat.Project prj) async {
        final db = await Base.getConnection();

        int cnt = await db.update(
            'projects',
        {
            'name': prj.name,
            'location': prj.location,
            'description': prj.description,
            'last_update': prj.lastUpdate,
            'start_date': prj.startDate,
            'end_date': prj.endDate,
            'private_project': prj.privateProject,
            'irrigation': prj.irrigation,
            'lat': prj.lat,
            'lon': prj.lon,
            'id_soil_texture': prj.idSoilTexture,
        },
            where: 'id_project = ?',
            whereArgs: [prj.idProject],
        );
        await db.close();
        return cnt;
    }
}

class AirtreeInput with Base {
    static Future<String> getAirtreeData(String idProject) async {
        var project = await _getProject(idProject);
        var points = await _getPoints(idProject);
        var lines = await _getLines(idProject);
        var polGeometries = await _getPolygonGeometries(idProject);
        var polData = await _getPolygonData(idProject);

        Map<String, dynamic> toAirtree = {
        'project': project,
        'point': points,
        'line': lines,
        'polygon_geometry': polGeometries,
        'polygon_data': polData,
    };
        return jsonEncode(toAirtree);
    }

    static Future<Map<String, dynamic>> _getProject(String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM projects WHERE id_project=?', [idProject]);
        return maps[0];
    }

    static Future<List<Map<String, dynamic>>> _getPoints(String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM points WHERE id_project=?', [idProject]);
        return maps;
    }

    static Future<List<Map<String, dynamic>>> _getLines(String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps =
        await db.rawQuery('SELECT * FROM line WHERE id_project=?', [idProject]);
        return maps;
    }

    static Future<List<Map<String, dynamic>>> _getPolygonGeometries(
        String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db.rawQuery(
            'SELECT * FROM polygon_geometry WHERE id_project=?', [idProject]);
        return maps;
    }

    static Future<List<Map<String, dynamic>>> _getPolygonData(
        String idProject) async {
        final db = await Base.getConnection();
        final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT * FROM polygon_data WHERE id_project=?', [idProject]);
        return maps;
    }
}

class Point extends dat.Point with Base {
    Point({
        required super.id,
        required super.idProject,
        required super.idUser,
        required super.lastUpdate,
        required super.idSpecies,
        required super.diameter,
        required super.height,
        required super.crownHeight,
        required super.crownDiameter,
        required super.lai,
        required super.truth,
        required super.latlng,
    });

    /// insert point in db
    /// return id of inserted point
    Future<int> dbInsert() async {
        final db = await connect();
        final insertedId = await db.insert(
            'points',
        {
            'id': id,
            'id_project': idProject,
            'id_user': idUser,
            'lat': latlng.latitude,
            'lon': latlng.longitude,
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
        },
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await Project.setUpdate(idProject);
        return insertedId; // id_int?
    }

    /// delete point from db
    /// return cnt of deleted points
    Future<int> dbDelete() async {
        final db = await connect();
        int cnt = await db.delete(
            'points',
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    /// update point in db
    /// return cnt of updated points
    Future<int> dbUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'points',
        {
            'id_project': idProject,
            'id_user': idUser,
            'lat': latlng.latitude,
            'lon': latlng.longitude,
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
        },
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    Future<int> dbTableUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'points',
        {
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
        },
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    String toJson() {
        return jsonEncode({
            'id': id,
            'id_project': idProject,
            'id_user': idUser,
            'lat': latlng.latitude,
            'lon': latlng.longitude,
            'last_update': lastUpdate,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
        });
    }

    geoj.GeoJSONFeature toGeoJson(Map<int, dat.ParamRow> mapIntSpecies, Map<String, dynamic> result3) {
        // print("id: $id");
        final r1 = result3[id];
        // print("r1: $r1");
        return geoj.GeoJSONFeature(
            geoj.GeoJSONPoint([latlng.longitude, latlng.latitude]),
            properties : {
                'id':             id,
                'id_project':     idProject,
                'id_user':        idUser,
                'last_update':    lastUpdate,
                'id_species':     idSpecies,
                'species_name':   mapIntSpecies[idSpecies]!.name,
                'diameter':       diameter,
                'height':         height,
                'crown_height':   crownHeight,
                'crown_diameter': crownDiameter,
                'lai':            lai,
                'truth':          truth,
                'canopy_area':    r1['canopy_area'],
                'npp':            r1['npp'],
                'o3':             r1['o3'],
                'pm1':            r1['pm1'],
                'pm2_5':          r1['pm2_5'],
                'pm10':           r1['pm10'],
                'no2':            r1['no2'],
                'so2':            r1['so2'],
                'co':             r1['co'],
            });
    }
}

class Line extends dat.Line with Base {
    Line(
    {required super.id,
        required super.idProject,
        required super.idUser,
        required super.lastUpdate,
        required super.idSpecies,
        required super.diameter,
        required super.height,
        required super.crownHeight,
        required super.crownDiameter,
        required super.lai,
        required super.truth,
        required super.treeNumber,
        required super.coords,
        super.setLength}) {
        setLength != null ? length = setLength! : length = computeLength();
    }

    /// insert line in db
    /// return id of inserted line
    Future<int> dbInsert() async {
        final db = await connect();
        final insertedId = await db.insert(
            'line',
        {
            'id': id,
            'id_project': idProject,
            'id_user': idUser,
            'json_geometry': getJsonGeometry(),
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
            'tree_number': treeNumber,
            'length': length,
        },
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await Project.setUpdate(idProject);
        return insertedId; // id_int?
    }

    /// delete line from db
    /// return cnt of deleted lines
    Future<int> dbDelete() async {
        final db = await connect();
        int cnt = await db.delete(
            'line',
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    /// update line in db
    /// return cnt of updated lines
    Future<int> dbUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'line',
        {
            'id_project': idProject,
            'id_user': idUser,
            'json_geometry': getJsonGeometry(),
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
            'tree_number': treeNumber,
            'length': length,
        },
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    Future<int> dbTableUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'line',
        {
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
            'tree_number': treeNumber,
        },
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    static List<LatLng> getCoordsFromJson(String jsonLineString) {
        List<LatLng> coords = [];
        final parse = jsonDecode(jsonLineString);
        final point2 = parse['coordinates'];
        for (var pnt in point2) {
        coords.add(LatLng(pnt[1], pnt[0]));
    }
        return coords;
    }

    String getJsonGeometry() {
        String jsonGeometry = '{"type":"LineString","coordinates":[';
        for (int i = 0; i < coords.length; i++) {
        //jsonGeometry += '[' + coords[i].longitude.toString() + ',' + coords[i].latitude.toString() + ']';
        jsonGeometry +=
        '[${coords[i].longitude.toString()},${coords[i].latitude.toString()}]';
        if (i < coords.length - 1) {
        jsonGeometry += ',';
      }
    }
        jsonGeometry += ']}';
        return jsonGeometry;
    }

    String toJson() {
        return jsonEncode({
            'id': id,
            'id_project': idProject,
            'id_user': idUser,
            'json_geometry': getJsonGeometry(), // avoid? reading and re-encoding
            'last_update': lastUpdate,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
            'tree_number': treeNumber,
            'length': length,
        });
    }

    geoj.GeoJSONFeature toGeoJson(Map<int, dat.ParamRow> mapIntSpecies, Map<String, dynamic> result3) {
        final coords2 = coords.map((e) => [e.longitude, e.latitude]).toList();
        final r1 = result3[id];

        return geoj.GeoJSONFeature(
            geoj.GeoJSONLineString(coords2),
            properties : {
                'id': id,
                'id_project': idProject,
                'id_user': idUser,
                'last_update': lastUpdate,
                'id_species': idSpecies,
                'species_name': mapIntSpecies[idSpecies]!.name,
                'diameter': diameter,
                'height': height,
                'crown_height': crownHeight,
                'crown_diameter': crownDiameter,
                'lai': lai,
                'truth': truth,
                'tree_number': treeNumber,
                'length': length,
                'npp' : r1['npp'],
                'o3': r1['o3'],
                'pm1': r1['pm1'],
                'pm2_5': r1['pm2_5'],
                'pm10': r1['pm10'],
                'no2': r1['no2'],
                'so2': r1['so2'],
                'co': r1['co'],
            });
    }
}

class PolygonGeometry extends dat.PolygonGeometry with Base {
    PolygonGeometry({
        required super.id,
        required super.idProject,
        required super.idUser,
        required super.coords,
        required super.lastUpdate,
        super.setTruth,
        super.setArea,
    }) {
        setTruth != null ? truth = setTruth! : truth = 1;
        setArea != null ? area = setArea! : area = computeArea();
    }

    Future<int> dbInsert() async {
        final db = await connect();
        final insertedId = await db.insert(
            'polygon_geometry',
        {
            'id': id, // idGeometry
            'id_project': idProject,
            'id_user': idUser,
            'json_geometry': getJsonGeometry(),
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'truth': truth,
        },
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await Project.setUpdate(idProject);
        return insertedId; // id_int?
    }

    Future<int> dbDelete() async {
        final db = await connect();
        int cnt = await db.delete(
            'polygon_geometry',
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    Future<int> dbUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'polygon_geometry',
        {
            'id_project': idProject,
            'id_user': idUser,
            'json_geometry': getJsonGeometry(),
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'truth': truth,
        },
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    // return a json string of the geometry
    String getJsonGeometry() {
        String jsonGeometry = '{"type":"Polygon","coordinates":[';
        for (int i = 0; i < coords.length; i++) {
        jsonGeometry +=
        '[${coords[i].longitude.toString()},${coords[i].latitude.toString()}]';
        if (i < coords.length - 1) {
        jsonGeometry += ',';
      }
    }
        jsonGeometry += ']}';
        return jsonGeometry;
    }

    static List<LatLng> getCoordsFromJson(String jsonPolygonString) {
        List<LatLng> coords = [];
        final parse = jsonDecode(jsonPolygonString);
        final point2 = parse['coordinates'];
        for (var pnt in point2) {
        coords.add(LatLng(pnt[1], pnt[0]));
    }
        return coords;
    }

    String toJson() {
        return jsonEncode({
            'id': id,
            'id_project': idProject,
            'id_user': idUser,
            'json_geometry': getJsonGeometry(), // avoid? reading and re-encoding
            'last_update': lastUpdate,
            'truth': truth,
        });
    }

    geoj.GeoJSONFeature toGeoJson(
        Map<int, dat.ParamRow> mapIntSpecies,
        Map<String, List<PolygonData>> data3,
        Map<String, Map<String, dynamic>> result3
    ) {
        final coords2 = coords.map((e) => [e.longitude, e.latitude]).toList();
        coords2.add(coords2[0]);
        final data2 = data3[id] ?? [];

        final Map<String, dynamic>mapOut = {
            'id': id,
            'id_project': idProject,
            'id_user': idUser,
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'truth': truth,
            'area': area,
        };

        int index = 0;
        for (var element in data2) {
            final r1 = result3[element.id];
            if (r1 == null) {
                continue;
            }
            index++;
            final map1 = {
                'z$index.id_species':     element.idSpecies,
                'z$index.species_name':   mapIntSpecies[element.idSpecies]!.name,
                'z$index.diameter':       element.diameter,
                'z$index.height':         element.height,
                'z$index.crown_height':   element.crownHeight,
                'z$index.crown_diameter': element.crownDiameter,
                'z$index.lai':            element.lai,
                'z$index.percent_area':   element.percentArea,
                'z$index.percent_cover':  element.percentCover,
                'z$index.npp':            r1['npp'],
                'z$index.o3':             r1['o3'],
                'z$index.pm1':            r1['pm1'],
                'z$index.pm2_5':          r1['pm2_5'],
                'z$index.pm10':           r1['pm10'],
                'z$index.no2':            r1['no2'],
                'z$index.so2':            r1['so2'],
                'z$index.co':             r1['co'],
            };
            mapOut.addAll(map1);
        }

        return geoj.GeoJSONFeature(
            geoj.GeoJSONPolygon([coords2]),
            properties : mapOut,
        );
    }

}

class PolygonData extends dat.PolygonData with Base {
    PolygonData({
        required super.idGeometry,
        required super.id,
        required super.idProject,
        required super.idUser,
        required super.lastUpdate,
        required super.idSpecies,
        required super.diameter,
        required super.height,
        required super.crownHeight,
        required super.crownDiameter,
        required super.lai,
        required super.truth,
        required super.percentArea,
        required super.percentCover,
        required super.area,
    });

    Future<int> dbInsert() async {
        final db = await connect();
        final insertedId = await db.insert(
            'polygon_data',
        {
            'id': id,
            'id_project': idProject,
            'id_user': idUser,
            'id_geometry': idGeometry,
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
            'percent_area': percentArea,
            'percent_cover': percentCover,
            'area': area,
        },
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await Project.setUpdate(idProject);
        return insertedId; // id_int?
    }

    Future<int> dbDelete() async {
        final db = await connect();
        int cnt = await db.delete(
            'polygon_data',
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    Future<int> dbUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'polygon_data',
        {
            'id_project': idProject,
            'id_user': idUser,
            'id_geometry': idGeometry,
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
            'percent_area': percentArea,
            'percent_cover': percentCover,
            'area': area,
        },
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }

    Future<int> dbTableUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'polygon_data',
        {
            'last_update': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
            'percent_area': percentArea,
            'percent_cover': percentCover,
        },
            where: 'id = ?',
            whereArgs: [id],
        );
        await Project.setUpdate(idProject);
        return cnt;
    }



    String toJson() {
        return jsonEncode({
            'id': id,
            'id_project': idProject,
            'id_user': idUser,
            'id_geometry': idGeometry,
            'last_update': lastUpdate,
            'id_species': idSpecies,
            'diameter': diameter,
            'height': height,
            'crown_height': crownHeight,
            'crown_diameter': crownDiameter,
            'lai': lai,
            'truth': truth,
            'percent_area': percentArea,
            'percent_cover': percentCover,
            'area': area,
        });
    }
}

class Result extends dat.Result with Base {
    Result({
        required super.idUser,
        required super.idProject, // -1: result is not referred to a species; data are totals for the project
        required super.idSpecies, // -1: result is not referred to a geometry; data are totals for the species
        required super.id,
        required super.startDate,
        required super.endDate,
        required super.lastUpdate,
        required super.npp,
        required super.o3,
        required super.pm1,
        required super.pm10,
        required super.pm25,
        required super.no2,
        required super.so2,
        required super.co,
        required super.canopyArea,
        required super.tsxnpp,
        required super.tsxo3,
        required super.tsxpm1,
        required super.tsxpm10,
        required super.tsxpm25,
        required super.tsxno2,
        required super.tsxso2,
        required super.tsxco,
        required super.tsxtime,
    });

    static List<int> blob2listInt(Uint8List uint8list) {
        final l = gzip.decode(uint8list) as Uint8List;
        return l.buffer.asInt64List();
    }

    static List<double> blob2listDouble(Uint8List uint8list) {
        final l = gzip.decode(uint8list) as Uint8List;
        return l.buffer.asFloat64List();
    }

    static List<int> listInt2blob(List<int> ilist) {
        final int64list = Int64List.fromList(ilist);
        final l = int64list.buffer.asUint8List();
        return gzip.encode(l);
    }

    static List<int> listDouble2blob(List<double> dlist) {
        final float64list = Float64List.fromList(dlist);
        final l = float64list.buffer.asUint8List();
        return gzip.encode(l);
    }

    //Uint8List getUint8List(List<double> dlist) {
    //    var float32list = Float32List.fromList(dlist);
    //    return float32list.buffer.asUint8List();
    //}
    //Uint8List getUint8List4int(List<int> dlist) {
    //    var int32list = Int32List.fromList(dlist);
    //    return int32list.buffer.asUint8List();
    //    //return Uint8List.fromList(dlist);
    //}

    //static List<double> getDoubleList(Uint8List uint8list) {
    //    return uint8list.buffer.asFloat32List();
    //}

    //static List<int> getIntList(Uint8List uint8list) {
    //    //return uint8list.buffer.asInt32List();
    //    return uint8list.toList();
    //}

    // TODO
    Future<int> dbInsert() async {
        final db = await connect();
        final insertedId = await db.insert(
            'result',
        {
            'id_user': idUser,
            'id_project': idProject,
            'id_species': idSpecies,
            'id': id,
            'last_update': lastUpdate,
            'start_date': startDate,
            'end_date': endDate,
            'canopy_area': canopyArea,
            'npp': npp,
            'o3': o3,
            'pm1': pm1,
            'pm2_5': pm25,
            'pm10': pm10,
            'no2': no2,
            'so2': so2,
            'co': co,
            'ts_npp': listDouble2blob(tsxnpp),
            'ts_o3': listDouble2blob(tsxo3),
            'ts_pm10': listDouble2blob(tsxpm10),
            'ts_pm2_5': listDouble2blob(tsxpm25),
            'ts_pm1': listDouble2blob(tsxpm1),
            'ts_no2': listDouble2blob(tsxno2),
            'ts_so2': listDouble2blob(tsxso2),
            'ts_co': listDouble2blob(tsxco),
            'ts_time': listInt2blob(tsxtime),
        },
            conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return insertedId; // id_int?
    }

    Future<int> dbDelete() async {
        // NOT IMPLEMENTED
        final db = await connect();
        int cnt = await db.delete(
            'result',
            where: 'id = ?',
            whereArgs: [id],
        );
        return cnt;
    }

    List<double> sum2(List<double> a, List<double> b) {
        List<double> c = [];
        for (int i = 0; i < a.length; i++) {
        c.add(a[i] + b[i]);
    }
        return c;
    }

    Result add(Result result) {
        return Result(
            idUser: idUser,
            idProject: idProject,
            idSpecies: idSpecies,
            id: id,
            startDate: startDate,
            endDate: endDate,
            lastUpdate: lastUpdate,
            tsxtime: tsxtime,
            npp: npp + result.npp,
            o3: o3 + result.o3,
            pm1: pm1 + result.pm1,
            pm10: pm10 + result.pm10,
            pm25: pm25 + result.pm25,
            no2: no2 + result.no2,
            so2: so2 + result.so2,
            co: co + result.co,
            canopyArea: canopyArea + result.canopyArea,
            tsxnpp: sum2(tsxnpp, result.tsxnpp),
            tsxo3: sum2(tsxo3, result.tsxo3),
            tsxpm1: sum2(tsxpm1, result.tsxpm1),
            tsxpm10: sum2(tsxpm10, result.tsxpm10),
            tsxpm25: sum2(tsxpm25, result.tsxpm25),
            tsxno2: sum2(tsxno2, result.tsxno2),
            tsxso2: sum2(tsxso2, result.tsxso2),
            tsxco: sum2(tsxco, result.tsxco),
        );
    }
}

// todo: require new acceptance of privacy terms when renewing
class UserSetting with Base {
    int idLanguageInterface  ;
    int idLanguageSpecies    ;
    int idHandness           ;
    int idPrivacyTerms       ;
    int idHelpLabel          ;
    int idVertexColour       ;
    int sizePanelEdit        ;
    int sizePanelInfo        ;
    int sizeCharacter        ;

    UserSetting({
        required this.idLanguageInterface,
        required this.idLanguageSpecies,
        required this.idHandness,
        required this.idPrivacyTerms,
        required this.idHelpLabel,
        required this.idVertexColour,
        required this.sizePanelEdit,
        required this.sizePanelInfo,
        required this.sizeCharacter,
    });

    static Future<UserSetting> fromDb() async {
        final db = await Base.getConnection();
        UserSetting userSetting;
        final List<Map<String, dynamic>> maps = await db.query('user_setting');
        if (maps.isEmpty) {
            userSetting = UserSetting(
                idLanguageInterface: 0,
                idLanguageSpecies: 0,
                idHandness: 0,
                idPrivacyTerms: 0,
                idHelpLabel : 1,
                idVertexColour : 0,
                sizePanelEdit: 0,
                sizePanelInfo: 0,
                sizeCharacter: 0,

            );
            await db.insert('user_setting', {
                'id_language_interface': userSetting.idLanguageInterface,
                'id_language_species':   userSetting.idLanguageSpecies,
                'id_handness':           userSetting.idHandness,
                'id_privacy_terms':      userSetting.idPrivacyTerms,
                'id_help_label':         userSetting.idHelpLabel,
                'id_vertex_colour':      userSetting.idVertexColour,
                'size_panel_edit':       userSetting.sizePanelEdit,
                'size_panel_info':       userSetting.sizePanelInfo,
                'size_character':        userSetting.sizeCharacter,

            });
        } else {
            userSetting = UserSetting(
                idLanguageInterface: maps[0]['id_language_interface'],
                idLanguageSpecies: maps[0]['id_language_species'],
                idHandness: maps[0]['id_handness'],
                idPrivacyTerms: maps[0]['id_privacy_terms'],
                idHelpLabel: maps[0]['id_help_label'],
                idVertexColour: maps[0]['id_vertex_colour'],
                sizePanelEdit: maps[0]['size_panel_edit'],
                sizePanelInfo: maps[0]['size_panel_info'],
                sizeCharacter: maps[0]['size_character'],
            );
        }
        return userSetting;
    }

    Future<int> dbUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'user_setting',
            {
                'id_language_interface': idLanguageInterface,
                'id_language_species': idLanguageSpecies,
                'id_handness': idHandness,
                'id_privacy_terms': idPrivacyTerms,
                'id_help_label': idHelpLabel,
                'id_vertex_colour': idVertexColour,
                'size_panel_edit': sizePanelEdit,
                'size_panel_info': sizePanelInfo,
                'size_character': sizeCharacter,
            },
            where: 'id_int = 1',
        );
        return cnt;
    }
}


class Settings with Base {
    final String version;
    final int atmTimeStart;
    final int atmTimeEnd;

    Settings({
        required this.version,
        required this.atmTimeStart,
        required this.atmTimeEnd,
    });

    Future<int> dbUpdate() async {
        final db = await connect();
        int cnt = await db.update(
            'settings',
            {
                'version': version,
                'atm_time_start': atmTimeStart,
                'atm_time_end': atmTimeEnd,
            },
            where: 'id_int = 1',
        );
        return cnt;
    }

    Future<Settings> fromDb() async {
        final db = await connect();
        Settings settings;
        final List<Map<String, dynamic>> maps = await db.query('settings');
        if (maps.isEmpty) {
            settings = await io.getSettingsFromMongo();
            await db.insert('settings', {
                'version': settings.version,
                'atm_time_start': settings.atmTimeStart,
                'atm_time_end': settings.atmTimeEnd,
            });
        } else {
            settings = Settings(
                version: maps[0]['version'],
                atmTimeStart: maps[0]['atm_time_start'],
                atmTimeEnd: maps[0]['atm_time_end'],
            );
        }
        return settings;
    }

    static void updateFromWeb() async {
        Settings settings = await io.getSettingsFromMongo();
        try {
            await settings.dbUpdate();
        } on DatabaseException catch (e) {
            // on initial run db is empty.
            print('Settings update error: $e');
            final db = await Base.getConnection();
            await db.insert('settings', {
                'id_int': 1,
                'version': settings.version,
                'atm_time_start': settings.atmTimeStart,
                'atm_time_end': settings.atmTimeEnd,
            });
        }
        await settings.dbUpdate();
    }
}
