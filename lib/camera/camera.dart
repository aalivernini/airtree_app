import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widget/oriented_camera.dart' as orc;
import 'widget/lai_widget.dart';

import 'array_plus.dart' as ap;
import 'provider_lai.dart' as pr_lai;
import 'threshold.dart' as th;

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
    TakePictureScreen({
        super.key,
    });

    final camera = orc.Camera();

    @override
    TakePictureScreenState createState() => TakePictureScreenState();
}



class TakePictureScreenState extends State<TakePictureScreen> {
    late Future<int>? _initializeControllerFuture;
    late orc.Orientation oriCam;
    final au = ap.ArrayPlus();
    bool lock = false;


    void preview(BuildContext context) {
        //oriCam.pictureStatus = 0;
        Navigator.pushNamed(context, '/camera/preview', arguments: oriCam.picturePath!);
    }

    @override
    void initState() {
        super.initState();
        oriCam = orc.Orientation(context, widget.camera);
        _initializeControllerFuture = oriCam.camera.init();

        oriCam.pictureStatus = 0;
    }

    @override
    void dispose() {
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final lSetting = Provider.of<pr_lai.ProviderLai>(context, listen: false);

        final mQuery  = MediaQuery.of(context);
        final height  = mQuery.size.height;
        final width   = mQuery.size.width;

        final vertical = height < width ? false : true;
        lSetting.verticalScreen = vertical;

        final st = ValueNotifier<int>(oriCam.pictureStatus);


        return Scaffold(
            body: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                        // If the Future is complete, display the preview.

                        return ValueListenableBuilder(
                            valueListenable: st,
                            builder: (context, value, child) {
                                if (st.value == 2) {
                                    if (!lock) {
                                        lock = true;
                                        Timer(const Duration(milliseconds: 20), () {
                                            preview(context);
                                        });
                                    }
                                } else {
                                    return ListenableBuilder(
                                        listenable: oriCam,
                                        builder: (BuildContext context, Widget? child){
                                            Timer(const Duration(milliseconds: 10), () {
                                                st.value = oriCam.pictureStatus;
                                            });

                                            return LayoutBuilder( builder: (context, constraints){  // required to update precision of the camera
                                                return getCameraScreen(context, oriCam);
                                            }
                                    );
                            });

                            }

                                return const Center(child: CircularProgressIndicator());

                            });}
                    else {
                        // Otherwise, display a loading indicator.
                        return const Center(child: CircularProgressIndicator());
                    }
                },
            ),
            );
    }
}


// A widget that displays the picture taken by the user.
class DisplayPicture extends StatefulWidget {
    const DisplayPicture({Key? key}) : super(key: key);

    @override
    DisplayPictureState createState() => DisplayPictureState();
}

class DisplayPictureState extends State<DisplayPicture> {
    late String imagePath;
    bool lock = false;

    void buildThreshold(BuildContext context, String imagePath) async {
        final pLai = Provider.of<pr_lai.ProviderLai>(context, listen: false);

        pLai.currentImageTmp  = imagePath;

        final mQuery        = MediaQuery.of(context);
        final height        = mQuery.size.height;
        final width         = mQuery.size.width;
        final vertical      = height < width ? false : true;
        final minSize       = height < width ? height : width;
        pLai.verticalScreen = vertical;
        pLai.minSize        = minSize;


        final file = File(imagePath);
        if (file.existsSync()) {
            getThreshold(context, imagePath).then((thr) {
                pLai.boolLai = true;
                try {
                    Navigator.pushNamed(context, '/camera/lai', arguments: thr);
                } catch (e) {
                    //print('todo: resolve');
                }
            });
        } else {
            //print('image not found');
        }
    }


    @override
    Widget build(BuildContext context) {
        //print('------display picture--------');
        RouteSettings rs = ModalRoute.of(context)!.settings;
            imagePath = rs.arguments as String;
            final file = File(imagePath);
            if (file.existsSync()) {
                if (!lock) {
                    lock = true;
                    buildThreshold(context, imagePath);
                }
                return Image.file(file);
            } else {
                return const Text('image not found');
            }
    }
}

class DisplayThreshold extends StatelessWidget {
    const DisplayThreshold({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        RouteSettings rs = ModalRoute.of(context)!.settings;
        final thrImage = rs.arguments as Threshold3;

        final pLai = Provider.of<pr_lai.ProviderLai>(context, listen: true);

        final thLai = th.Lai(context);
        final data = thrImage.img1d;
        final img = thrImage.img;

        final button2 = getLaiButtons(context, 60);

        final widList =  <Widget>[
            Align(
                alignment: Alignment.center,
                child: img, // threshold
            ),
            // navigation buttons
            pLai.verticalScreen? Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //crossAxisAlignment: CrossAxisAlignment.end,
                        children: button2,
                    ),
                ),
            ): Align(
            alignment: Alignment.bottomRight,
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //crossAxisAlignment: CrossAxisAlignment.end,
                    children: button2,
                ),
            ),),];

        return FutureBuilder<Map<String, double>>(
            future: thLai.getLai(data),
            builder: (BuildContext context, AsyncSnapshot<Map<String, double>> snapshot) {
                if (snapshot.hasData) {
                    final stats = snapshot.data!;

                    if (pLai.boolLai) {
                        pLai.boolLai = false;
                        pLai.lai2.add(stats["lai"]!);

                    }
                    if (pLai.lai2.isNotEmpty) {
                        final laiMean = pLai.laiMean();
                        stats["measures"] = pLai.lai2.length.toDouble();
                        stats["lai mean"] = laiMean;

                        List<Widget> childs = [];
                        for (var entry in stats.keys) {
                            String val = "";
                            if (entry == "measures")  {
                                val = "${stats[entry]?.toInt()}";
                            } else {
                                val = "${stats[entry]?.toStringAsFixed(2)}";
                            }
                            childs.add(
                                Text("$entry: $val",
                                    style: TextStyle(
                                        fontSize: pLai.minSize / 30,
                                        color: Colors.black,
                                        decoration: TextDecoration.none,
                                    ),
                                )
                            );
                        }

                        final text = Container(
                            height: pLai.minSize/3.5,
                            color: Colors.transparent,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: const BorderRadius.all(Radius.circular(10.0))),
                                child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child:
                                    Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: childs,
                                    )
                                )
                            ));

                        widList.add(
                            Align(
                                alignment: Alignment.center,
                                child: text,       // lai info
                            ),
                        );
                    }

                    return Material(
                        child: Stack(
                            children: widList,
                        )
                    );
                }
                else {
                    return Material(
                        child: Stack(
                            children: widList,
                        )
                    );
                }
            },
            );
    }
}

