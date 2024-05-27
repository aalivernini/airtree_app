import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'database.dart' as db;
import 'dart:typed_data';
import 'env.dart' ;



String addressHome = Env.adressHome;
String airtreeApiKey = Env.airtreeKey;


BaseOptions dioOptions = BaseOptions(
  // baseUrl: "http://$addressHome",
  baseUrl: "$addressHome",
  connectTimeout: const Duration(milliseconds: 5000),
  receiveTimeout: const Duration(milliseconds: 5000 * 10),
  receiveDataWhenStatusError: true,
);


final dio = Dio(dioOptions);


class HttpResult {
    final String msg;
    final int statusCode;
    Map<String, dynamic> data;

    HttpResult(this.msg, this.statusCode, {this.data = const {}});
}

// GET atm_time_start and atm_time_end
// TODO: rework to get atm_time_start and atm_time_end
// Future<String> getHttp() async {
//     String output = 'The server is down';
//     try {
//     final response = await dio.get('/ping');
//         Map<String, dynamic> json3 = jsonDecode(
//             jsonEncode(response.data)
//         );
//         output = json3['service'];
//     } catch (e) {
//         print(e);
//     }
//     return output;
// }

// GET settings data
Future<HttpResult> getSettingsFromMongo() async {
    String address = '/get-settings?api_key=$airtreeApiKey';
    final response = await dio.get(address);
    HttpResult out;
    if (response.statusCode == 200) {
        Map<String, dynamic> json3 = jsonDecode(
            response.data
        );
        out = HttpResult(
            'Settings received',
            response.statusCode!,
            data: json3,
        );
    } else {
        out = HttpResult(
            response.data['detail'],
            response.statusCode!,
        );
    }
    // final out = db.Settings(
    //     version      : json3['version'],
    //     atmTimeStart : json3['atm_time_start'],
    //     atmTimeEnd   : json3['atm_time_end'],
    // );
    return out;
}

// TODO: move to database.dart
Future<String> getProjectDataJson(String idProject) async {
    // get and set project lat lon

    // get project data
    var jsonProject = await db.AirtreeInput.getAirtreeData(idProject);
    // print("json: $jsonProject");
    return jsonProject;
}

// POST project data (with gzip)
Future<HttpResult> sendProject(String idProject) async {
    var projectData = await getProjectDataJson(idProject);

    HttpResult httpResult;
    try {
        var dataGzip = gzip.encode(
            utf8.encode(
                projectData
            )
        );
        var options = Options(
            headers: {
                HttpHeaders.contentLengthHeader: dataGzip.length, // set content-length
                HttpHeaders.contentTypeHeader: 'multipart/form-data',
                HttpHeaders.contentEncodingHeader: 'gzip',
            },
        );
        var formData = FormData.fromMap({
            'file': MultipartFile.fromBytes(
                dataGzip,
            ),
        });


        String address = '/post-project';
        address = '$address?api_key=$airtreeApiKey';
        final response = await dio.post(
            address,
            //data: Stream.fromIterable(dataGzip.map((e) => [e])),
            data: formData,
            options: options,
            onSendProgress: (int sent, int total) {
                //print('$sent $total');
            },
        );
        httpResult = HttpResult(
            'upload ok',
            response.statusCode!
        );

        await db.Project.setStatus(idProject, 1);
    }
    on DioException catch (e) {
        print(e);
        httpResult = HttpResult(
            'Server upload issue',
            404,
        );
        await db.Project.setStatus(idProject, 0);
    }
    return httpResult;
}

Future<HttpResult> getResult (String idProject, String idUser) async {
    String address = '/get-result';
    address = '$address?api_key=$airtreeApiKey&id_project=$idProject&id_user=$idUser';
    HttpResult out;
    try {
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
        out = HttpResult(
            'Result received',
            rs.statusCode!,
            data: result,
        );
    } catch (e) {
        out = HttpResult(
            '$e',
            404,
        );
    }
    return out;
}

Future<HttpResult> setDelivered (String idProject, String idUser) async {
    String address = '/set-delivered';
    address = '$address?api_key=$airtreeApiKey&id_project=$idProject&id_user=$idUser';
    final response = await dio.patch(address);
    if (response.statusCode != 200) {
        return HttpResult(
            'Server issue',
            response.statusCode!,
        );
    }
    final out = HttpResult(
        'Status updated',
        response.statusCode!,
    );
    return out;
}


// TODO
// GET project status
Future<HttpResult> getProjectStatus(String idProject, String idUser) async {
    String msg;
    int statusCode;
    try {
        String address = '/get-work-status';
        final response = await dio.get('$address?api_key=$airtreeApiKey&id_project=$idProject&id_user=$idUser');
        msg = response.data.toString();
        statusCode = response.statusCode!;
    } catch (e) {
        msg = 'The server is down';
        statusCode = 404;
    }
    final HttpResult out = HttpResult(
        msg,
        statusCode,
    );
    return out;
}




