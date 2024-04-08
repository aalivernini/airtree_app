import 'package:flutter/services.dart'; // managing the diplay of android top bar
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:latlong2/latlong.dart';
import 'database.dart' as db;

abstract class BaseResult {
    final String idUser;
    final String idProject;
    final int idSpecies;
    final String id;
    final int startDate;
    final int endDate;
    final int lastUpdate;
    final double npp;
    final double o3;
    final double pm1;
    final double pm10;
    final double pm25;
    final double no2;
    final double so2;
    final double co;
    final double canopyArea;

    BaseResult({
        required this.idUser,
        required this.idProject,
        required this.idSpecies,
        required this.id,
        required this.startDate,
        required this.endDate,
        required this.lastUpdate,
        required this.npp,
        required this.o3,
        required this.pm1,
        required this.pm10,
        required this.pm25,
        required this.no2,
        required this.so2,
        required this.co,
        required this.canopyArea,
    });
}

class Result extends BaseResult {
    List<double> tsxnpp;
    List<double> tsxo3;
    List<double> tsxpm1;
    List<double> tsxpm10;
    List<double> tsxpm25;
    List<double> tsxno2;
    List<double> tsxso2;
    List<double> tsxco;
    List<int> tsxtime;

    Result({
        required super.idUser,
        required super.idProject,
        required super.idSpecies,
        required super.id,
        required super.startDate,
        required super.endDate,
        required super.lastUpdate,
        required super.npp,
        required super.o3,
        required super.pm1,
        required super.pm25,
        required super.pm10,
        required super.no2,
        required super.so2,
        required super.co,
        required super.canopyArea,
        required this.tsxnpp,
        required this.tsxo3,
        required this.tsxpm1,
        required this.tsxpm10,
        required this.tsxpm25,
        required this.tsxno2,
        required this.tsxso2,
        required this.tsxco,
        required this.tsxtime,
    });
}

abstract class Green {
    final String id;
    final String idProject;
    final String idUser;
    int lastUpdate;
    int idSpecies;
    int diameter;
    double height;
    double crownHeight;
    double crownDiameter;
    double lai;
    int truth; // bool (int for compatibility with sqflite) 0: false, 1: true

    Green({
        required this.id,
        required this.idProject,
        required this.idUser,
        required this.lastUpdate,
        required this.idSpecies,
        required this.diameter,
        required this.height,
        required this.crownHeight,
        required this.crownDiameter,
        required this.lai,
        required this.truth,
    });
}

class Point extends Green {
    String type = "Tree";
    LatLng latlng;

    Point({
        required this.latlng,
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
    });
}

class Line extends Green {
    String type = "Tree row";
    List<LatLng> coords;
    double length = 0;
    double? setLength;
    int treeNumber;

    Line(
        {required this.coords,
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
            required this.treeNumber,
            this.setLength}) {
        setLength != null ? length = setLength! : length = computeLength();
    }

    double computeLength() {
        List<mt.LatLng> mtCoords = [];
        for (int i = 0; i < coords.length; i++) {
            mtCoords.add(mt.LatLng(coords[i].latitude, coords[i].longitude));
        }
        length = mt.SphericalUtil.computeLength(mtCoords) as double;
        return length;
    }
}


class PolygonGeometry {
    final String id;
    final String idProject;
    final String idUser;
    final int lastUpdate;
    String type = "polygon";
    double area = 0;
    int truth = 0;
    int? setTruth;
    double? setArea;
    List<LatLng> coords;
    PolygonGeometry({
        required this.id,
        required this.idProject,
        required this.idUser,
        required this.coords,
        required this.lastUpdate,
        this.setTruth,
        this.setArea,
    }) {
        setTruth != null ? truth = setTruth! : truth = 1;
        setArea != null ? area = setArea! : area = computeArea();
    }
    double computeArea() {
        List<mt.LatLng> mtCoords = [];
        for (int i = 0; i < coords.length; i++) {
            mtCoords.add(mt.LatLng(coords[i].latitude, coords[i].longitude));
        }
        area = mt.SphericalUtil.computeArea(mtCoords) as double;
        return area;
    }
}

//class ForestData extends Green{
class PolygonData extends Green {
    String type = "Forest";
    final String idGeometry;
    int percentArea; // max 100 in all ForestData with the same idGeometry
    int percentCover; // 1 - 100
    double area; // in m2

    PolygonData({
        required this.idGeometry,
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
        required this.percentArea,
        required this.percentCover,
        required this.area,
    });
}

class Project {
    final String idProject;
    final String idUser;
    String name;
    String location;
    String description;
    int lastUpdate; // [millis since epoch] last update
    int startDate; // [millis since epoch] date of start for airtree
    int endDate; // [millis since epoch] date of end for airtree
    int privateProject; // bool: (int for sqflite) public or privateProject project
    int irrigation; // bool (int for sqflite)
    int status; // -1:   error (red), 0: data entry (blu), 1: data sent (yellow), 2: result ready green
    double lat;
    double lon;
    int idSoilTexture;
    int hasData; // true if there is at least one data in the project

    Project(
        {
            required this.idProject,
            required this.idUser,
            required this.name,
            required this.location,
            required this.description,
            required this.lastUpdate,
            required this.startDate,
            required this.endDate,
            required this.privateProject,
            required this.irrigation,
            required this.status,
            required this.lat,
            required this.lon,
            required this.idSoilTexture,
            required this.hasData
        }
    );
}

class User {
    String idUser;
    String nome;
    String cognome;
    String username;
    String email;
    String password;

    User({
        required this.idUser,
        required this.nome,
        required this.cognome,
        required this.username,
        required this.email,
        required this.password,
    });
}

// ----------------------------------------------------------------------------
// classes managing param.csv
// ----------------------------------------------------------------------------
class ParamRow {
    int airtreeId;
    String name;
    int diameter;
    double height;
    double crownHeight;
    double crownDiameter;
    double lai;

    ParamRow({
        required this.airtreeId,
        required this.name,
        required this.diameter,
        required this.height,
        required this.crownHeight,
        required this.crownDiameter,
        required this.lai,
    });
}

class Soil {
    static Map<int, String> getEnglish() {
        return {
            1: "mean",
            2: "sandy",
            3: "silty",
            4: "clay",
        };
    }

    static Map<int, String> getItalian() {
        return {
            1: "media",
            2: "sabbiosa",
            3: "limosa",
            4: "argillosa",
        };
    }
}

class Param {
    static Future<List<ParamRow>> getList(int idLanguageSpecies) async {
        final speciesList = await db.Param.getParamList(idLanguageSpecies);
        return speciesList;
    }

    static Future<Map<String, ParamRow>> getMapName() async {
        Map<String, ParamRow> species3 = {};

        final userSetting = await db.UserSetting.fromDb();
        int langType = userSetting.idLanguageSpecies;

        var speciesList = await getList(langType);
        for (int i = 0; i < speciesList.length; i++) {
            var paramRow = speciesList[i];
            var name = paramRow.name;
            species3[name] = paramRow;
        }
        return species3;
    }

    static Future<Map<int, ParamRow>> getMapId() async {
        Map<int, ParamRow> species3 = {};

        final userSetting = await db.UserSetting.fromDb();
        int langType = userSetting.idLanguageSpecies;

        var speciesList = await getList(langType);
        for (int i = 0; i < speciesList.length; i++) {
            var paramRow = speciesList[i];
            var id = paramRow.airtreeId;
            species3[id] = paramRow;
        }
        return species3;
    }
}

List<mt.LatLng> getItalyCoordinates() {
    final italyBoundingBoxCoords = [
        [15.081249008128784, 36.549327808985218],
        [15.075973595497796, 36.549480210830019],
        [11.978974744714373, 36.644961790190379],
        [11.973803208281126, 36.645241894219417],
        [11.968653109766963, 36.645789372659067],
        [11.963538263408514, 36.646602756994376],
        [11.95847238888468, 36.647679865464418],
        [11.953469074515997, 36.6490178089145],
        [11.948541740816356, 36.650612998545817],
        [11.943703604494814, 36.652461155541758],
        [11.938967643004098, 36.654557322545102],
        [11.934346559730855, 36.656895876955254],
        [11.92985274992105, 36.659470546009864],
        [8.348557895680322, 38.878722451454998],
        [8.344235125272339, 38.88171729237515],
        [8.340075771754634, 38.884935241170879],
        [8.33609133799245, 38.888367398470869],
        [8.33229284310316, 38.892004272501296],
        [8.148115205786343, 39.077432835069601],
        [8.144553298268823, 39.081252099432987],
        [8.141195639210199, 39.085252110818821],
        [8.138051386278182, 39.089421959609886],
        [8.135129115097355, 39.093750272974987],
        [8.132436795860036, 39.098225245887207],
        [8.12998177158841, 39.102834673320906],
        [8.127770738107188, 39.107565983539622],
        [8.125809725781448, 39.112406272384213],
        [8.12410408306943, 39.117342338467616],
        [8.12265846193517, 39.122360719180257],
        [6.532876946799824, 45.086251344108653],
        [6.531778277956254, 45.091350498213622],
        [6.530946993915955, 45.096500004273267],
        [6.530385356473605, 45.101685851281943],
        [6.530094893757395, 45.106893929355905],
        [6.530076396071234, 45.112110068124153],
        [6.53032991374445, 45.117320075283786],
        [6.530854756994856, 45.122509775215043],
        [6.531649497805538, 45.127665047550998],
        [6.532711973810267, 45.132771865596844],
        [6.705949512683095, 45.805083291159818],
        [6.721735512683088, 45.862473790159768],
        [6.723263117885986, 45.867506034467397],
        [6.725053164757803, 45.872451010971304],
        [6.727100702555087, 45.87729504332011],
        [6.729400068390181, 45.882024734344263],
        [6.731944902893099, 45.886627003108721],
        [6.734728167799679, 45.89108912109095],
        [6.737742165417351, 45.895398747384284],
        [6.740978559914689, 45.899543962829249],
        [6.744428400375877, 45.903513302978425],
        [6.748082145556304, 45.90729578980379],
        [6.751929690270845, 45.91088096205867],
        [6.755960393341836, 45.914258904210492],
        [6.760163107029434, 45.917420273864238],
        [6.764526207862999, 45.92035632760075],
        [6.769037628788189, 45.923058945158473],
        [6.773684892540892, 45.925520651891688],
        [6.778455146155663, 45.927734639443216],
        [6.783335196513254, 45.929694784574302],
        [8.270361086452972, 46.518702129655928],
        [8.275245383417733, 46.520509268738316],
        [8.352470884417775, 46.546816768738346],
        [8.357847830946691, 46.548481122273998],
        [8.363309903373883, 46.549840310070643],
        [10.449073344709166, 46.952768795242122],
        [10.454164858639004, 46.953702541992179],
        [11.146730763687433, 47.064170311833941],
        [11.151815720470697, 47.064942479544101],
        [11.463319480196052, 47.109776788688968],
        [11.468531193807015, 47.110452525469235],
        [12.123896538286571, 47.179930620652257],
        [12.129151606484552, 47.180431759909247],
        [12.134425798033787, 47.180654887277171],
        [12.225366298033775, 47.182099388277152],
        [12.230496096667737, 47.182049266787288],
        [12.235616574759144, 47.181736136935342],
        [12.240714256568536, 47.181160822795974],
        [12.245775726350219, 47.180324838443333],
        [12.250787663658945, 47.179230383966363],
        [12.255736878405795, 47.177880339678822],
        [12.26061034557098, 47.176278258538986],
        [13.749400305167933, 46.616297742405678],
        [13.75418980897352, 46.614352914504281],
        [13.75887241311696, 46.612163183766114],
        [13.763435604882876, 46.609734401524484],
        [13.767867190646092, 46.607073057898965],
        [13.772155328455071, 46.604186264452771],
        [13.776288559675631, 46.601081735189389],
        [13.780255839610366, 46.597767765939494],
        [13.784046567011949, 46.594253212193038],
        [13.787650612411481, 46.590547465435918],
        [13.791058345186148, 46.58666042805428],
        [13.794260659293888, 46.582602486873682],
        [18.504020713115683, 40.352623526438741],
        [18.506918351206405, 40.348425348618534],
        [18.509598136638676, 40.344084870125101],
        [18.602534685006415, 40.187045921979454],
        [18.60522289855642, 40.182334840374992],
        [18.60765171819645, 40.177484931393316],
        [18.609813998149193, 40.172510463845896],
        [18.611703376817946, 40.167426073005252],
        [18.613314295502914, 40.162246717546822],
        [18.614642014755365, 40.156987635539373],
        [18.615682628321427, 40.151664299613429],
        [18.616433074634617, 40.146292371439543],
        [18.61961707463459, 40.117899870439501],
        [18.620056897461602, 40.112804215313552],
        [18.620235607816387, 40.107692737260109],
        [18.620152738207931, 40.102578807468866],
        [18.619808505416049, 40.09747580354307],
        [18.619203809924301, 40.092397074504809],
        [18.618340233564403, 40.087355905875178],
        [18.617220035378313, 40.08236548492043],
        [18.61584614570873, 40.077438866155234],
        [18.614222158533604, 40.072588937193196],
        [18.612352322064584, 40.067828385033955],
        [18.482007207069433, 39.776445256666427],
        [18.479705524591708, 39.771679379177385],
        [18.477154916555758, 39.76704195218435],
        [18.474362527554035, 39.762545965737324],
        [18.471336179439657, 39.75820401369252],
        [18.468084349416337, 39.754028258435298],
        [18.464616146292613, 39.750030396811702],
        [18.442844646292613, 39.726236397811675],
        [18.439175797793155, 39.722433539450201],
        [15.187584739725136, 36.604538593825417],
        [15.183763545493635, 36.600884142366844],
        [15.179754534900251, 36.597436770196609],
        [15.175568915751818, 36.594206114974796],
        [15.14048495044821, 36.568577640320093],
        [15.136142620208473, 36.565578078212297],
        [15.131648087189225, 36.562811785080982],
        [15.127013870105307, 36.560286465939051],
        [15.12225287673645, 36.558009154609614],
        [15.117378367974965, 36.555986194134547],
        [15.112403920889911, 36.55422321910708],
        [15.107343390910605, 36.552725139977653],
        [15.102210873234814, 36.551496129376737],
        [15.097020663569106, 36.550539610492734],
        [15.091787218310733, 36.549858247537259],
        [15.086525114281928, 36.549453938324511],
        [15.081249008128784, 36.549327808985218]
                ];
        List<mt.LatLng> coords = [];
        for (var tuple in italyBoundingBoxCoords) {
            coords.add(mt.LatLng(tuple[1], tuple[0]));
        }
        return coords;
}
