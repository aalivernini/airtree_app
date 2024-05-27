import 'package:flutter/material.dart';
import 'widget/lai_widget.dart' as aw;

enum TypeThreshold {
    minDist,
    hsv,
    lab,
    greeness,
}


class ProviderLai extends ChangeNotifier {
    double laiValue = 0;

    List<String> pathImage2     = []; // list: path of image
    List<String> pathImageTmp2  = []; // list: path of image
    List<aw.Threshold3> threshold2 = []; // list: path of image
    List<double> lai2 = []; // list: lai

    String currentImage     = ''; // path of image
    String currentImageTmp  = ''; // path of image
    aw.Threshold3? currentThreshold; // path of image

    bool boolLai = true; // avoid computing lai twice when switching method

    // threshold
    TypeThreshold typeThreshold = TypeThreshold.greeness;
    //TypeThreshold typeThreshold = TypeThreshold.greeness;

    int ixThreshold = 0;

    // camera
    double laiAngle         = 57.5;
    int ixCameraDirection   = 1; // 57.5°

    // screen
    bool verticalScreen = true;
    double minSize = 0;

    double laiMean () {
        return lai2.reduce((a, b) => a + b) / lai2.length;
    }

    void lai2Reset () {
        pathImage2    = [];
        pathImageTmp2 = [];
        lai2          = [];
    }

    void lai2Add (double lai) {
        lai2.add(lai);
        pathImage2.add(currentImage);
    }

    void setCameraDirection (int ixCameraDirection) {
        this.ixCameraDirection = ixCameraDirection;
        switch (ixCameraDirection) {
            case 0:
                laiAngle = 90;
                break;
            case 1:
                laiAngle = 57.5;
                break;
            case 2:
                laiAngle = -57.5;
                break;
            case 3:
                laiAngle = -90;
                break;
            default:
                laiAngle = 57.5;
        }

    }

    void setThresholdMethod (int ixThreshold) {
        List<TypeThreshold> tThreshold = TypeThreshold.values;
        typeThreshold = tThreshold[ixThreshold];
        this.ixThreshold = ixThreshold;
    }
}


