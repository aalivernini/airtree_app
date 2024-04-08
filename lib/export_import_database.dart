import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:restart_app/restart_app.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'database.dart' as db;

Future<String> getTemporaryPath(String fileName) async {
  final directory = await getTemporaryDirectory();
  return join(directory.path, fileName);
}

Future<void> exportDatabase() async {
      String path = await getDatabasesPath();
      String sourceDatabasePath = join(path, db.databaseName);
      String destinationPath = await getTemporaryPath(db.exDbName);
      await io.File(destinationPath)
          .writeAsBytes(await io.File(sourceDatabasePath).readAsBytes());
      await db.Base.shareFile(
          destinationPath,
          'airtree_app.sqlite',
      );
}

Future<void> importDatabase() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String filePath = result.files.single.path!;
      String path = await getDatabasesPath();
      String sourceDatabasePath = join(path, db.databaseName);


      // sovrasscrivi db presente
      await io.File(sourceDatabasePath)
          .writeAsBytes(await io.File(filePath).readAsBytes());
      Restart.restartApp();
    } else {
      //operazione annullata
    }
  } catch (e) {
    print('errore durante il implementazione: $e');
  }
}
