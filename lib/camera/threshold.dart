import 'package:flutter/material.dart';
import 'package:image/image.dart' as im;
import 'package:collection/collection.dart';
import 'dart:math';
import 'array_plus.dart' as ap;
import 'colour.dart';
import 'dart:isolate';
import 'package:provider/provider.dart';
import 'provider_lai.dart' as pr;


// define type for image array
typedef ImageArray3 = List<List<List<int>>>;
typedef ImageArray2 = List<List<int>>;

abstract class Threshold {
    final au = ap.ArrayPlus();


    // apply threshold (0: background, 1: vegetation)
    List<int> applyThreshold(ImageArray3 imgArr);

    static Threshold getThreshold(BuildContext context) {
        final lSetting = Provider.of<pr.ProviderLai>(context, listen: false);
        switch (lSetting.typeThreshold) {
           case pr.TypeThreshold.minDist:
               return ThresholdMinimum();
           case pr.TypeThreshold.hsv:
               return ThresholdHsv();
           case pr.TypeThreshold.lab:
               return ThresholdLab();
              case pr.TypeThreshold.greeness:
               return ThresholdGreeness();
           default:
               return ThresholdMinimum();
        }
    }

    // load image
    Future<ImageArray3> loadImg(String path) async { // return RGB image array
        final cmd = im.Command()
                ..decodeImageFile(path);
        await cmd.executeThread();
        final img = cmd.outputImage;
        if (img == null) {
            throw Exception("img is null");
        }

        final width  = img.width;
        final height = img.height;

        final imgArr = List.generate(width, (_) =>
            List.generate(height, (_) =>
                List.filled(3, 0),
                growable: false),
            growable: false);
        num rMax = 0;
        num gMax = 0;
        num bMax = 0;
        num rMin = 255;
        num gMin = 255;
        num bMin = 255;

        for (var i = 0; i < width; i++) {       // col
            for (var j = 0; j < height; j++) {  // row
                final pixel = img.getPixel(i, j);
                imgArr[i][j] = [
                    pixel.r ~/ 1,
                    pixel.g ~/ 1,
                    pixel.b ~/ 1,
                ];
                if (pixel.r > rMax) { rMax = pixel.r; }
                if (pixel.g > gMax) { gMax = pixel.g; }
                if (pixel.b > bMax) { bMax = pixel.b; }
                if (pixel.r < rMin) { rMin = pixel.r; }
                if (pixel.g < gMin) { gMin = pixel.g; }
                if (pixel.b < bMin) { bMin = pixel.b; }
            }
        }
        return imgArr;
    }
}



class ThresholdHsv extends Threshold {

    ImageArray3 convertToHSV(ImageArray3 imgArr) {
        final width = imgArr.length;
        final height = imgArr[0].length;
        var hMax = 0;
        var sMax = 0;
        var vMax = 0;
        var hMin = 255;
        var sMin = 255;
        var vMin = 255;
        final colour = Colour();
        for (var i = 0; i < width; i++) {      // column
            for (var j = 0; j < height; j++) { // row
                final pixel = imgArr[i][j];
                final hsv = colour.rgb2hsv(pixel[0], pixel[1], pixel[2]);
                int h = (hsv[0] * 255.0) ~/1 ;   // rescale to 0-255
                int s = (hsv[1] * 255.0) ~/1 ;   // rescale to 0-255
                int v = (hsv[2] * 255.0) ~/1 ;   // rescale to 0-255
                if (h > hMax) { hMax = h; }
                if (s > sMax) { sMax = s; }
                if (v > vMax) { vMax = v; }
                if (h < hMin) { hMin = h; }
                if (s < sMin) { sMin = s; }
                if (v < vMin) { vMin = v; }
                imgArr[i][j] = [h, s, v];
            }
        }
        return imgArr;
    }

    // apply threshold
    // http://dx.doi.org/10.1016/j.inpa.2015.07.003
    @override
    List<int> applyThreshold(ImageArray3 imgArr) {  // return binary image array (0: background, 1: vegetation)
        final imgArrHsv = convertToHSV(imgArr);

        final width = imgArrHsv.length;
        final height = imgArrHsv[0].length;
        //var imgArr2 = List.generate(width, (_) =>
        //    List.filled(height, 0),
        //    growable: false);

        final arr = List<int>.filled(width * height, 0);

        var hMax = 0;
        var sMax = 0;
        var vMax = 0;
        var hMin = 255;
        var sMin = 255;
        var vMin = 255;

        var ii = 0;
        for (var i = 0; i < imgArrHsv.length; i++) {
            for (var j = 0; j < imgArrHsv[0].length; j++) {
                final pix = imgArrHsv[i][j];
                final h = pix[0];
                final s = pix[1];
                final v = pix[2];
                if (h > hMax) { hMax = h; }
                if (s > sMax) { sMax = s; }
                if (v > vMax) { vMax = v; }
                if (h < hMin) { hMin = h; }
                if (s < sMin) { sMin = s; }
                if (v < vMin) { vMin = v; }
                int ix = 1;
                if (h < 50 || h > 150) {
                    ix = 0;
                }
                if (h > 50-1 && s > 5 && s < 50 && v > 150) {
                    //print("c2");
                    ix = 0;
                }
                //imgArr2[i][j] = ix;
                arr[ii] = ix;
                ii++;

                if (ix ==1) {
                    //print("ix = 1");
                }
            }
        }
        return arr;
    }
}

class ThresholdMinimum extends Threshold {
    // from Cover package
    final size = List<int>.filled(3,0);
    final au = ap.ArrayPlus();

    bool bimodtest(List<double> y) {
        // Test if a histogram is bimodal.
        // from HistThresh toolbox
        final len = y.length;
        bool b = false;
        int modes = 0;
        for (var k = 1; k < len-1; k++) {
            if (y[k] == 0) {  // TESTING
                continue;
            }
            if (y[k-1] < y[k] && y[k+1] < y[k]) {
                modes += 1;
                if (modes > 2) {
                    return false;
                }
            }
        }
        if (modes == 2) {
            b = true;
        }
        return b;
    }


    int findMinimum(      // return threshold value
        List<int> hist,   // flatted histogram array
    ) {
        // convert to double
        var flat = hist.map((x) => x.toDouble()).toList();
        int iter = 0;
        final len = flat.length;
        while (!bimodtest(flat)) {
            flat = au.conv1d(flat, len);
            iter += 1;
            // If the histogram turns out not to be bimodal, set T to zero.
            if (iter > 10000) {
                return 0;
            }
        }
        // The threshold is the minimum between the two peaks.
        var threshold = 0;
        bool peakfound = false;
        for (var k = 1; k < len; k++) {
            if (flat[k-1] < flat[k]
                && flat[k+1] < flat[k]) {
                peakfound = true;
            }
            if (peakfound
                && flat[k-1] >= flat[k]
                && flat[k+1] >= flat[k]) {
                threshold = hist[k-1];
                return k-1;
            }
        }
        return threshold;
}


    @override
    List<int> applyThreshold(ImageArray3 imgArr) {
        size[0] = imgArr.length;          // width
        size[1] = imgArr[0].length;       // height
        size[2] = imgArr[0][0].length;    // depth  (ie. 3 for RGB)

        // get blue band (flat) (coveR) https://link.springer.com/epdf/10.1007/s00468-022-02338-5?sharing_token=Bqh24tLEoHoTD61xilF9Sve4RwlQNchNByi7wbcMAY6erI7p25b_bCe_SlX9nbHtstgks-TW5CVw-SteavcAqFtGrC_3neKDD2Ghog46MYf7--0DRHhCpFg78RWfXrUixczcCpXHPq9ucgJpvDRw_P6jjdveScsjhTZUkfXAQyM=
        final arrBlue = au.flattenInner(imgArr, 2);

        // get histogram
        final hist = au.histogram(arrBlue, 256);

        // find minimum
        final thr = findMinimum(hist);  // find threshold value

        // apply threshold
        final out1d = arrBlue.map((val) => val > thr ? 0 : 1).toList();

        // reshape to 2d
        return out1d;
    }
}

// https://plantmethods.biomedcentral.com/articles/10.1186/s13007-019-0402-3/tables/6
class ThresholdGreeness extends Threshold {
    // from Cover package
    final size = List<int>.filled(3,0);
    final au = ap.ArrayPlus();

    bool bimodtest(List<double> y) {
        // Test if a histogram is bimodal.
        // from HistThresh toolbox
        final len = y.length;
        bool b = false;
        int modes = 0;
        for (var k = 1; k < len-1; k++) {
            if (y[k] == 0) {  // TESTING
                continue;
            }
            if (y[k-1] < y[k] && y[k+1] < y[k]) {
                modes += 1;
                if (modes > 2) {
                    return false;
                }
            }
        }
        if (modes == 2) {
            b = true;
        }
        return b;
    }


    int findMinimum(      // return threshold value
        List<int> hist,   // flatted histogram array
    ) {
        // convert to double
        var flat = hist.map((x) => x.toDouble()).toList();
        int iter = 0;
        final len = flat.length;
        while (!bimodtest(flat)) {
            flat = au.conv1d(flat, len);
            iter += 1;
            // If the histogram turns out not to be bimodal, set T to zero.
            if (iter > 10000) {
                return 0;
            }
        }
        // The threshold is the minimum between the two peaks.
        var threshold = 0;
        bool peakfound = false;
        for (var k = 1; k < len; k++) {
            if (flat[k-1] < flat[k]
                && flat[k+1] < flat[k]) {
                peakfound = true;
            }
            if (peakfound
                && flat[k-1] >= flat[k]
                && flat[k+1] >= flat[k]) {
                threshold = hist[k-1];
                return k-1;
            }
        }
        return threshold;
}


    @override
    List<int> applyThreshold(ImageArray3 imgArr) {
        size[0] = imgArr.length;          // width
        size[1] = imgArr[0].length;       // height
        size[2] = imgArr[0][0].length;    // depth  (ie. 3 for RGB)

        // get blue band (flat) (coveR) https://link.springer.com/epdf/10.1007/s00468-022-02338-5?sharing_token=Bqh24tLEoHoTD61xilF9Sve4RwlQNchNByi7wbcMAY6erI7p25b_bCe_SlX9nbHtstgks-TW5CVw-SteavcAqFtGrC_3neKDD2Ghog46MYf7--0DRHhCpFg78RWfXrUixczcCpXHPq9ucgJpvDRw_P6jjdveScsjhTZUkfXAQyM=
        final arrBlue = au.flattenInner(imgArr, 2);
        final arrGreen = au.flattenInner(imgArr, 1);
        final arrRed = au.flattenInner(imgArr, 0);

        // GET GREENESS INDEX
        // Greeness index = 2*G - 2*R + B
        // https://iforest.sisef.org/pdf/?id=ifor0939-007
        final arrGreeness = List<int>.filled(arrGreen.length, 0);
        final arrLen = arrGreen.length;
        var maxValue = 0;
        var minValue = 1000000;
        int currentValue = 0;
        int green = 0;
        int red = 0;
        int blue = 0;

        for (var k = 1; k < arrLen; k++) {
            red = arrRed[k];
            green = arrGreen[k];
            blue = arrBlue[k];

            //currentValue = (2 * green - red - blue);
            //currentValue = (2 * blue - green);
            currentValue = (30 * red + 59 * green + 11 * blue) ~/ 100;  // LUMA index https://www.biorxiv.org/content/10.1101/2022.04.01.486683v1.full
            //print("currentValue: $currentValue");
            //currentValue = (green - red) ~/ sub;
            //currentValue = max(0, currentValue);

            //currentValue = (
            //    2 * arrGreen[k]
            //    - 2 * arrRed[k]
            //    + arrBlue[k]
            //);
            arrGreeness[k] = currentValue;
            //maxValue = max(maxValue, currentValue);
            //minValue = min(minValue, currentValue);
        }

        // rescale to 0-255
        // print("maxValue: $maxValue");
        // print("minValue: $minValue");
        // var to_add = 0;
        // if (minValue < 0) {
        //     to_add = -minValue;
        //     minValue = 0;
        //     maxValue += to_add;
        // }
        // // gap filling
        // for (var k = 1; k < arrLen; k++) {
        //     currentValue = arrGreeness[k] + to_add;
        //     currentValue = (
        //         ((currentValue - minValue) * 255)
        //             / (maxValue - minValue)
        //     ) ~/ 1;
        //     arrGreeness[k] = currentValue;
        // }

        // get histogram
        final hist = au.histogram(arrGreeness, 256);

        // find minimum
        final thr = findMinimum(hist);  // find threshold value

        // apply threshold
        final out1d = arrGreeness.map((val) => val > thr ? 0 : 1).toList();

        // reshape to 2d
        return out1d;
    }
}


class ThresholdLab extends Threshold {

    @override
    List<int> applyThreshold(ImageArray3 imgArr) {  // return binary image array (0: background, 1: vegetation)

        // IDENTIFY FOREGROUND AND BACKGROUND PIXELS
        final red   = au.flattenInner(imgArr, 0);
        final green = au.flattenInner(imgArr, 1);
        final blue  = au.flattenInner(imgArr, 2);
        final len = red.length;
        // final height = imgArr[0].length;

        final bg =  // background
                List<bool>.generate(len, (i) => (red[i]+blue[i]-2*green[i]) > -1);
        final fg =  //foreground
                List<bool>.generate(len, (i) =>
                    (green[i]>red[i])
                    &(green[i]>blue[i])
                    &(green[i]>25));
        final darkPixels = List<bool>.generate(len, (i) => green[i] <= 25);

        // GLA algorithm
        final gla1 = List<double>.generate(
            len,
            (i) => (2*green[i]-red[i]-blue[i] + 1)
            /(2*(2*green[i]+red[i]+blue[i]))
        );

        // CONVERT TO LAB COLOR SPACE AND GET A* AND B* VALUES
        final lenFlat = red.length;
        final labArrA = List<double>.filled(lenFlat, 0, growable: false);
        final labArrB = List<double>.filled(lenFlat, 0, growable: false);

        final colour = Colour();

        for (var ix=0; ix<lenFlat; ix++){
            final labPix = colour.rgb2lab(red[0], blue[1], green[2]);
            labArrA[ix] = labPix[1];
            labArrB[ix] = labPix[2];

        }

        // CALCULATE THE MEAN A*, B*, GLA AND GLA OF FOREGROUND
        double fgA    = 0;         // foreground mean a*
        double fgB    = 0;         // foreground mean b*
        double fgGla1 = 0;      // foreground mean GLA
        int cntFgA    = 0;         // foreground pixels a*
        int cntFgB    = 0;         // foreground pixels b*
        int cntFgGla1 = 0;      // foreground pixels GLA
        for (var ix=0; ix<len; ix++){
            if (fg[ix]){
                fgA += labArrA[ix];
                fgB += labArrB[ix];
                fgGla1 += gla1[ix];
                cntFgA += 1;
                cntFgB += 1;
                cntFgGla1 += 1;
            }
        }
        fgA    = fgA / cntFgA.toDouble();
        fgB    = fgB / cntFgB.toDouble();
        fgGla1 = fgGla1 / cntFgGla1.toDouble();

        // CALCULATE THE MEAN A*, B*, gla AND GLA OF BACKGROUND
        double bgA       = 0;      // background mean a*
        double bgB       = 0;      // background mean b*
        double bgGla1    = 0;      // background mean GLA
        int cntBgA    = 0;      // background pixels a*
        int cntBgB    = 0;      // background pixels b*
        int cntBgGla1 = 0;      // background pixels GLA
        for (var ix=0; ix<len; ix++){
            if (bg[ix]){
                bgA += labArrA[ix];
                bgB += labArrB[ix];
                bgGla1 += gla1[ix];
                cntBgA += 1;
                cntBgB += 1;
                cntBgGla1 += 1;
            }
        }
        bgA    = fgA / cntBgA.toDouble();
        bgB    = fgB / cntBgB.toDouble();
        bgGla1 = fgGla1 / cntBgGla1.toDouble();


        // LAB2 - L*A*B AND GLA NEAREST NEIGHBOUR CLASSIFICATION
        final lab2 = List<int>.filled(lenFlat, 0, growable: false);
        for (var ix=0; ix<len; ix++){
            final distanceFg = // modified: ^0.5 omitted (not needed)
                    (
                        pow(labArrA[ix] - fgA, 2)
                        + pow(labArrB[ix] - fgB, 2)
                        + pow(gla1[ix] - fgGla1, 2)
                        )
                    ;

            final distanceBg = // modified: ^0.5 omitted (not needed)
                    (
                        pow(labArrA[ix] - bgA, 2)
                        + pow(labArrB[ix] - bgB, 2)
                        + pow(gla1[ix] - bgGla1, 2)
                        )
                    ;
            if (distanceFg < distanceBg
                && !bg[ix]
                && !darkPixels[ix]) {
                lab2[ix] = 1;
            }
            // TODO: remove noise ?
        }
        // reshape to 2d
        return lab2;
    }
}



class Image1d {
    final List<int> arr;
    final int width;
    final int height;
    Image1d(this.arr, this.width, this.height);
}





class Lai {
    late pr.ProviderLai lSetting;
    late Threshold thr;
    //final thr = ThresholdMinimum();
    //final thr = ThresholdHsv();
    //final thr = ThresholdLab();
    final au = ap.ArrayPlus();

    Lai(BuildContext context) {
        thr = Threshold.getThreshold(context);
    }

    Future<Map<String, double>> getLaiIsolate(Image1d img1d) async {
        return await Isolate.run(() => getLai(img1d));
    }

    Future<Image1d> thresholdImageIsolate(
        String path,
        {bool filterVeg = false}
    ) async {
        return await Isolate.run(() => thresholdImage(path, filterVeg: filterVeg));
    }

    Future<Image1d> thresholdImage(String path, {bool filterVeg = false}) async {
        final imgArr3    = await thr.loadImg(path);
        // return binary flat array (0: background, 1: vegetation)
        final imgArr   = thr.applyThreshold(imgArr3);

        final width = imgArr3.length;
        final height = imgArr3[0].length;
        final arrLength = imgArr.length;

        if (filterVeg) {
            // from  https://doi.org/10.1111/j.2041-210X.2011.00151.x
            // foreground objects smaller than 0.05% of the image size were reclassified as background
            int filterSize   = arrLength * 0.0005 ~/ 1;
            if (filterSize < 1) {
                filterSize = 1;
            }
            final vegConnected = au.findConnectedComponents1d(imgArr, width, height, 1);
            final vegMap       = au.getComponentListSize(vegConnected);
            final vegMapLength = vegMap.length;
            final toExclude2 =  <int>[];
            for (var ix = 1; ix < vegMapLength; ix++) {
                if (vegMap[ix] < filterSize) {
                    toExclude2.add(ix);
                }
            }
            for (var i = 0; i < arrLength; i++) {
                if (toExclude2.contains(vegConnected[i])) {
                    imgArr[i] = 0;
                }
            }
        }
        return Image1d(imgArr, width, height);
    }


    Future<Map<String, double>> getLai(Image1d img1d) async {
        final imgArr = img1d.arr;
        final arrLength = imgArr.length;


        // label pixel regions with same value (only background)
        final connected = au.findConnectedComponents1d(imgArr, img1d.width, img1d.height, 0);
        // get size of pixels for each connected component (only background)
        final map       = au.getComponentSize(connected);

        int pxTotal = arrLength;
        int pxVegTot = 0;
        for (var i = 0; i < arrLength; i++) {
            final pix = imgArr[i];
            if (pix == 1){
                pxVegTot += 1;
            }
        }
        // final pxGapTot = pxTotal - pxVegTot;

        List<double> gap2 = [];
        for (var entry in map.entries) {
            gap2.add(entry.value.toDouble());
        }
        // get gap mean
        double mean = gap2.average;
        // get std
        // Calculate the variance
        double variance = gap2.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
                (gap2.length - 1);
        // Calculate the standard deviation
        double standardDeviation = sqrt(variance);
        // Calculate the standard error
        double standardError = standardDeviation / sqrt(gap2.length);

        double bigGapSize     = mean + standardError;
        // 1.3 % of total pixels (ratio empirical)

        int gapSizeNormal = 0;
        int gapSizeBig = 0;
        for (var entry in map.entries) {
            final val = entry.value;
            if (val < bigGapSize) {
                gapSizeNormal += val;
            }
            else {
                gapSizeBig += val;
            }

        }

        double gapSize      = gapSizeNormal.toDouble();
        double bboxSize     = (pxTotal.toDouble() - gapSizeBig.toDouble());
        final gapFraction   = gapSize / bboxSize;

        final totalGapFraction = (gapSizeNormal + gapSizeBig) / pxTotal.toDouble();
        final largeGap = gapSizeBig.toDouble() / pxTotal.toDouble();

        // const angle = 57.5 * pi / 180;
        // final lai = -(cos(angle)/0.5) * log(gapFraction);

        // clumping index computation ? TODO

        // species specific
        //const extinctionCoeff = 0.85; // Chianucci F (2020) An overview of insitu digital canopy photography in forestry. Can J for Res 50:227–242. https:// doi. org/ 10. 1139/ cjfr- 2019- 005

        final foliageCover  = 1 - totalGapFraction;
        final crownCover    = 1 - largeGap;
        final crownPorosity = 1 - (foliageCover /crownCover);
        var actualLai     = -crownCover*log(crownPorosity)/ 0.92;
        actualLai = actualLai - 0.2 * actualLai; // correction factor to exclude Wood Area Index. From: https://agupubs.onlinelibrary.wiley.com/doi/pdf/10.1029/2018RG000608

        // final effectiveLai  = -log(1 - foliageCover) / 0.92;  // 0.92 is the extinction coefficient for 57.5 deg
        // final clumpingIndex = effectiveLai/actualLai;

        Map<String, double> stats = {
          'lai': actualLai,
        };

        return stats;

    }





}
