//import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'database.dart' as db;
import 'dart:typed_data';
import 'env.dart' ;



String addressHome = Env.adressHome;
String airtreeApiKey = Env.airtreeKey;


BaseOptions dioOptions = BaseOptions(
  baseUrl: "http://$addressHome",
  connectTimeout: const Duration(milliseconds: 5000),
  receiveTimeout: const Duration(milliseconds: 5000 * 10),
  receiveDataWhenStatusError: true,
);


final dio = Dio(dioOptions);

// GET atm_time_start and atm_time_end
// TODO: rework to get atm_time_start and atm_time_end
Future<String> getHttp() async {
    String output = 'The server is down';
    try {
    final response = await dio.get('/ping');
        Map<String, dynamic> json3 = jsonDecode(
            jsonEncode(response.data)
        );
        output = json3['service'];
    } catch (e) {
        print(e);
    }
    return output;
}

// GET settings data
Future<db.Settings> getSettingsFromMongo() async {
    String address = '/get_settings?api_key=$airtreeApiKey';
    final response = await dio.get(address);
    //final in1 = jsonEncode(response.data);
    Map<String, dynamic> json3 = jsonDecode(
        response.data
    );
    final out = db.Settings(
        version      : json3['version'],
        atmTimeStart : json3['atm_time_start'],
        atmTimeEnd   : json3['atm_time_end'],
    );
    return out;
}

Future<String> getProjectDataJson(String idProject) async {
    // get and set project lat lon

    // get project data
    var jsonProject = await db.AirtreeInput.getAirtreeData(idProject);
    // print("json: $jsonProject");
    return jsonProject;
}

// POST project data (with gzip)
Future<String> sendProject(String idProject) async {
    var projectData = await getProjectDataJson(idProject);

    String output = 'Server upload issue';
    try {
        var dataGzip = gzip.encode(
            utf8.encode(
                projectData
            )
        );
        var options = Options(
            headers: {
                HttpHeaders.contentLengthHeader: dataGzip.length, // set content-length
            },
        );

        String address = '/post_project';
        address = '$address?api_key=$airtreeApiKey';
        final response = await dio.post(
            address,
            data: Stream.fromIterable(dataGzip.map((e) => [e])),
            options: options,
            onSendProgress: (int sent, int total) {
                //print('$sent $total');
            },
        );
        output = response.data.toString();
        await db.Project.setStatus(idProject, 1);
    }
    on DioException catch (e) {
        await db.Project.setStatus(idProject, 0);
        output = e.response?.data.toString() ?? 'Server upload issue';
    }
    return output;
}

Future<Map<String, dynamic>> getResult (String idProject, String idUser) async {
    String address = '/get_result';
    address = '$address?api_key=$airtreeApiKey&id_project=$idProject&id_user=$idUser';
    final rs = await dio.get(
        address,
        options: Options(responseType: ResponseType.stream), // Set the response type to `stream`.
    );

    List<int> byteList2 = [];

    final stream = rs.data.stream; // Response stream.
    await for (var data in stream) {
        for (var b in data) {
            byteList2.add(b);
        }
    }
    var bytes = Uint8List.fromList(byteList2);
    final jsonString = utf8.decode(gzip.decode(bytes));
    Map<String, dynamic> result = jsonDecode(jsonString);
    return result;
}

Future<Map<String, dynamic>> setDelivered (String idProject, String idUser) async {
    String address = '/set_delivered';
    address = '$address?api_key=$airtreeApiKey&id_project=$idProject&id_user=$idUser';
    final response = await dio.patch(address);
    // Map<String, dynamic> json3 = jsonDecode(
    //     response.data
    // );
    const json3 = {'status': 'delivered'};
    return json3;
}


// TODO
// GET project status
Future<String> getProjectStatus(String idProject, String idUser) async {
    String output = 'The server is down';
    try {
        String address = '/get_work_status';
    final response = await dio.get('$address?api_key=$airtreeApiKey&id_project=$idProject&id_user=$idUser');
        //Map<String, dynamic> json3 = jsonDecode(
        //    jsonEncode(response.data)
        //);
        output = response.data.toString();
    } catch (e) {
        print(e);
    }
    return output;
}



