
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'shape.dart';
// import 'package:exif/exif.dart' as ex;
import 'package:sensors_plus/sensors_plus.dart' as se;
import 'dart:collection';
import 'dart:math';
import 'package:camera/camera.dart' as cam; // in alternative: https://github.com/Apparence-io/CamerAwesome
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../provider_lai.dart' as pr_lai;
import 'package:flutter/services.dart';


class Orientation extends ChangeNotifier {
    String? picturePath;

    double acX = 0;  // acceleremeter values
    double acY = 0;  // acceleremeter values
    double acZ = 0;  // acceleremeter values

    double tilt  = 0; // elevation
    double tiltOrto = 0; // rotation
    bool showHorizontalIndicator = false;

    int tiltSign = 1; // [1, -1] sign for titl angle above 90° or below -90°
    StreamSubscription<dynamic>? _streamSubscription;

    static double pi        = 3.1415926535897932;
    static double rad2deg   = 180.0 / pi;
    double laiAngle         = 57.5;
    static double tolerance = 1;
    double iconSize         = 30;

    int pictureStatus   = 0;
    int indicatorOffset = 0;
    int hIndicatorOffset = 0;
    final queue           = ListQueue();     // tilt queue
    final queueComplement = ListQueue(); // tilt complement queue -> tiltDirection
    final queueOrto = ListQueue(); // tilt complement queue -> tiltDirection
    late pr_lai.ProviderLai pLai;

    Camera camera;


    Orientation (BuildContext context, Camera cam1)
            : camera = cam1
    {
        pLai = Provider.of<pr_lai.ProviderLai>(context, listen: false);
        laiAngle = pLai.laiAngle;

        int ixCameraDirection = pLai.ixCameraDirection;
        if (ixCameraDirection == 0 || ixCameraDirection == 2) {  // -90° or 90°
            showHorizontalIndicator = true;
        }

        _streamSubscription = se.accelerometerEvents.listen(
            (se.AccelerometerEvent event) {
                final vScreen  = pLai.verticalScreen;
                acX = event.x;
                acY = event.y;
                acZ = event.z;
                final tilt1 =  acos(acZ / sqrt(acX * acX + acY * acY + acZ * acZ)) * rad2deg - 90; // check angle for lai measurement


                double tiltOrto1 = 0;
                double tiltComplement1 = 0;
                if (vScreen){
                    tiltComplement1 = -(acos(acY / sqrt(acX * acX + acY * acY + acZ * acZ)) * rad2deg - 90); // vertical pointing bottom or top: positive before -90 or + 90 degrees
                    tiltOrto1 =  (acos(acX / sqrt(acX * acX + acY * acY + acZ * acZ)) * rad2deg - 90); // negative when pointing left
                }
                else {
                    tiltComplement1 = -(acos(acX / sqrt(acX * acX + acY * acY + acZ * acZ)) * rad2deg - 90); // horizontal (smartphone buttons up) pointing bottom or top: positive before -90 or + 90 degrees
                    tiltOrto1 =  -(acos(acY / sqrt(acX * acX + acY * acY + acZ * acZ)) * rad2deg - 90); // negative when pointing left
                }

                //final tilt2 =  acos(acY / sqrt(acX * acX + acY * acY + acZ * acZ)) * rad2deg - 90; // vertical pointing bottom or top: negative before -90 or + 90 degrees
                //final tilt3 =  acos(acX / sqrt(acX * acX + acY * acY + acZ * acZ)) * rad2deg - 90; // horizontal (smartphone buttons up) pointing bottom or top: negative before -90 or + 90 degrees


                queue.add(tilt1);
                queueComplement.add(tiltComplement1);
                queueOrto.add(tiltOrto1);
                if (queue.length > 5) {
                    queue.removeFirst();
                    queueComplement.removeFirst();
                    queueOrto.removeFirst();
                }
                tilt = queue.reduce((a, b) => a + b) / queue.length; // average of the queue
                tiltOrto = queueOrto.reduce((a, b) => a + b) / queueOrto.length; // average of the queue
                final tiltComplement = queueComplement.reduce((a, b) => a + b) / queueComplement.length; // average of the queue
                tiltSign = tiltComplement > 0 ? 1 : -1;

                if (pictureStatus == 0) {
                    if (tilt > (laiAngle - tolerance) && tilt < (laiAngle + tolerance)) {
                        HapticFeedback.lightImpact();
                        // get the standard deviation of the queue
                        final std = sqrt(queue.map((e) => (e - tilt) * (e - tilt)).reduce((a, b) => a + b) / queue.length);
                        if (std < 1) {
                            // play cheer sound
                            pictureStatus = 1;
                            takePicture();
                        }
                    }
                }
                notifyListeners();
            }
            );
    }

    Future<void> takePicture() async {
        final imagePath = await camera.takePicture();
        if (imagePath != null) {
            picturePath = imagePath.path;
            pictureStatus = 2;
            //notifyListeners();
        }
    }

    CustomPaint getTriangle(Direction direction) {
        return CustomPaint(
            painter: TrianglePainter(
                strokeColor: Colors.white,
                strokeWidth: 2,
                paintingStyle: PaintingStyle.stroke,
                direction: direction,
            ),
            child: Container(
                height: iconSize,
                width: iconSize,
            ),
        );
    }


    Widget getTiltIndicator( {bool showPrecisionRange = false}) {

        final iconUp = getTriangle(Direction.up);
        final iconDown = getTriangle(Direction.down);

        // --------------------------------------
        // Vertical indicator
        // --------------------------------------
        Widget? icon;
        List<Widget> tiltIndicator = [];
        final diff = (tilt - laiAngle) * tiltSign;


        if (showPrecisionRange) {
            if (diff.abs() <= tolerance * 10){
                final indicator = SizedBox(
                    child: CustomPaint(
                        painter: AccuracyIndicator(diffVertical: diff, diffHorizontal: tiltOrto),
                    )
                );
                return Center(
                    child: indicator,
                );
            }
        }

        final iconOk = SizedBox(
            child: CustomPaint(
                painter: MakeCircle(strokeWidth: 2, strokeCap: StrokeCap.round, radius:30),
            )
        );


        int multiplier = 1;
        if (diff > tolerance) {
            icon = iconDown;
        }
        else if (diff < -tolerance) {
            icon = iconUp;
            multiplier = -1;
        }
        else {
            icon = iconOk;
            multiplier = 0;
        }
        int iconNumber = 1;
        if  (diff.abs() > tolerance * 5 && diff.abs() <= tolerance * 15) {
            iconNumber = 2;
        } else if (diff.abs() > tolerance * 15) {
            iconNumber = 3;
        }
        for (int i = 0; i < iconNumber; i++) {
            tiltIndicator.add(icon);
        }

        if (tiltIndicator.isEmpty) {
            tiltIndicator.add(icon);
        }
        indicatorOffset = iconNumber * multiplier * iconSize ~/ 1;
        double padding = 0;
        if (indicatorOffset > tolerance) {
            padding = indicatorOffset.toDouble() + iconSize * 2;
        } else if (indicatorOffset < -tolerance) {
            padding = indicatorOffset.toDouble() - iconSize * 2;
        }
        else {
            padding = 0;
        }

        return Positioned.fill(
            top: padding,
                child: Align(
                    alignment: Alignment.center,
                    child:
                Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: tiltIndicator,
                )
        ));
    }


    @override
    void dispose() {
        _streamSubscription?.cancel();
        super.dispose();
    }
}

class Camera {
    cam.CameraDescription? camera;
    cam.CameraController? controller;
    double maxZoom = 0.0;
    double minZoom = 0.0;
    double zoom = 0.0;
    double photoAngle = 0.0;

    late String cacheDir;
    //late String docDir;


    Camera ([cam.CameraDescription? cam1]) {
        cam.availableCameras().then((cameras) {
            camera = cameras.first;
        });
    }


    void initDir() async {
        cacheDir = (await getTemporaryDirectory()).path;
        //docDir = (await getApplicationDocumentsDirectory()).path;
    }

    //Future<String> copyToFolder(String cacheFile) async {
    //    final fileName = cacheFile.split('/').last;
    //    final newFile = '$docDir/$fileName';
    //    await File(cacheFile).rename(newFile);
    //    return newFile;
    //}

    void dispose() {
        // Dispose of the controller when the widget is disposed.
        if (controller != null){
            controller!.dispose();
        }
        // controller!.pausePreview();
        //controller!.dispose();
        //WidgetsBinding.instance!.removeObserver(this);
    }




    void setCamera(cam.CameraDescription? cam1){
        camera = cam1!;
    }

    Future<int>? init() async {
        camera = (await cam.availableCameras()).first;
        controller = cam.CameraController(
            // Get a specific camera from the list of available cameras.
            camera!,
            // Define the resolution to use.
            //cam.ResolutionPreset.max,
            // https://medium.com/brickit-engineering/how-we-doubled-the-photo-resolution-from-flutter-camera-on-ios-e17004cd0b74
            cam.ResolutionPreset.ultraHigh,
            // imageFormatGroup: cam.ImageFormatGroup.yuv420,
            imageFormatGroup: cam.ImageFormatGroup.bgra8888,
            enableAudio: false,
        );
        while (controller == null) {
            await Future.delayed(const Duration(milliseconds: 100));
        }
        while (!controller!.value.isInitialized) {
            await controller!.initialize();
            await Future.delayed(const Duration(milliseconds: 100));
        }
        //await controller!.initialize();
        //print('controller!.value.isInitialized: ${controller!.value.isInitialized}');

        // turn off flash
        controller!.setFlashMode(cam.FlashMode.off);
        controller!.setZoomLevel(2.0);
        return 0;
    }

    Future<cam.XFile>? takePicture () async {
        while (controller == null) {
            await Future.delayed(const Duration(milliseconds: 100));
        }
        await Future.delayed(const Duration(milliseconds: 100));
        //await controller!.initialize();
        //controller!.setFlashMode(cam.FlashMode.off);

        await controller!.setFocusMode(cam.FocusMode.locked);
        await controller!.setExposureMode(cam.ExposureMode.locked);

        final imagePath = await controller!.takePicture();
        await controller!.setFocusMode(cam.FocusMode.auto);
        await controller!.setExposureMode(cam.ExposureMode.auto);
        print("TAKE PICTURE");
        return imagePath;
    }
}
