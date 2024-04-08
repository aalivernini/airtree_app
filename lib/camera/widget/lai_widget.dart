import 'package:flutter/material.dart';
import 'oriented_camera.dart' as orc;
import 'package:camera/camera.dart' as cam; // in alternative: https://github.com/Apparence-io/CamerAwesome
import '../provider_lai.dart' as pr_lai;

import 'package:provider/provider.dart';

import '../threshold.dart' as th;
import '../array_plus.dart' as ap;
import 'package:flutter/services.dart';


class Threshold3 {
    Image img;
    th.Image1d img1d;
    Threshold3(this.img, this.img1d);
}

Future<Threshold3> getThreshold (
    BuildContext context,
    String imagePath,
) async {
    final laiF = th.Lai(context);
    final pl = ap.ArrayPlus();
    final img1d = await laiF.thresholdImageIsolate(
        imagePath,
        filterVeg: false
    );
    final arr2 = pl.addDim(img1d.arr, img1d.height);
    final jpg = pl.arr2ToImg(arr2);

    final img = Image.memory(jpg);
    return Threshold3(img, img1d);
}


class Lai3 {
    Widget laiWid;
    double lai;
    double gapFraction;

    Lai3(this.laiWid, this.lai, this.gapFraction);
}

Widget getIcon(
    BuildContext context,
    double size,
    Icon icon,
    String str,
    void Function() onPressed
) {
    return SizedBox.fromSize(
        size: Size(size, size),
        child: ClipOval(
            child: Material(
                color: Colors.blue,
                child: InkWell(
                    splashColor: Colors.green,
                    onTap: onPressed,
                    child:  Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            icon,
                            Text(str), // <-- Text
                        ],
                    ),
                ),
            ),
        ),
    );
}


// https://fonts.google.com/icons
List<Widget> getLaiButtons (
    BuildContext context,
    double size,
    ) {

    final pLai = Provider.of<pr_lai.ProviderLai>(context, listen: false);
    return [
        // -UNDO-
        getIcon(context, size, const Icon(Icons.undo), "undo", () {
            // remove last measure
            if (pLai.lai2.isNotEmpty)  pLai.lai2.removeLast();
            Navigator.pushNamedAndRemoveUntil(context, '/camera', ModalRoute.withName('/greenForm'));


        }) ,

        // EXIT
        getIcon(context, size, const Icon(Icons.exit_to_app) , "exit" , () {

            // delete current lai data
            pLai.lai2.clear();
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp],
            );
            Navigator.popUntil(context, ModalRoute.withName('/greenForm'));
        }) ,

        // -REDO-
        getIcon(context, size, const Icon(Icons.redo)     , "redo"  , () {
            Navigator.pushNamedAndRemoveUntil(context, '/camera', ModalRoute.withName('/greenForm'));
           // Navigator.pushNamedAndRemoveUntil(context, '/camera', (Route<dynamic> route) => true);
        }) ,

        // OK
        getIcon(context, size, const Icon(Icons.done)     , "ok"    , () {
            pLai.laiValue = pLai.laiMean();
            pLai.lai2Reset();

            // exit to tree screen
            //Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
            // Navigator.popUntil(context, ModalRoute.withName('/'));
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp],
            );
            Navigator.popUntil(context, ModalRoute.withName('/greenForm'));

        }) ,
    ];
}







Widget getCameraScreen(BuildContext context, orc.Orientation oriCam) {
//    final mQuery = MediaQuery.of(context);

    final pLai = Provider.of<pr_lai.ProviderLai>(context, listen: false);
    bool showHorizonalIndicator = false;
    if (pLai.ixCameraDirection == 0 || pLai.ixCameraDirection == 3) {
     showHorizonalIndicator = true;
    }
    final wid1 = oriCam.getTiltIndicator(showPrecisionRange: showHorizonalIndicator);

    // final height  = mQuery.size.height;
    // final width   = mQuery.size.width;

    // final vertical = height < width ? false : true;

    // final wCam = Padding(
    //     padding: const EdgeInsets.all(8.0),
    //     child: wut.getCameraDirection(context));

    // final widCameraDirection = vertical ?
    //         Align(
    //             alignment: Alignment.topCenter,
    //             child: wCam,
    //         ) :
    //         Align(
    //             alignment: Alignment.centerLeft,
    //             child: wCam,
    //         );

    final widList = <Widget>[
                // widCameraDirection,  // switch for camera direction
                Align(  // camera preview
                    alignment: Alignment.center,
                    child:
                    cam.CameraPreview(oriCam.camera.controller!),
                ),

                wid1,  // tilt indicator
                // Align(  // settings ?
                //     alignment: Alignment.bottomRight,
                //     child: IconButton(
                //         icon: const Icon(Icons.more_vert),
                //         onPressed: () {
                //         },
                //     ),
                // ),
    ];


    return Scaffold(
        body: Stack(children: widList),
            );
}







