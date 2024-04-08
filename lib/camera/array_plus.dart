import 'package:image/image.dart' as im;
import 'dart:math';
import 'dart:typed_data';
import 'package:collection/collection.dart';


typedef ImageArray3 = List<List<List<int>>>;
typedef ImageArray2 = List<List<int>>;


class ArrayPlus {
    List<T> flattenInner<T>(List<List<List<T>>> in1, indexInner){
        return in1.expand((i) =>
            i.expand((j) =>
                [j[indexInner]]
            )).toList();
    }

    ImageArray3 mat3dInt(int width, int height, int depth) {
        final imgArr = List.generate(width, (_) =>
            List.generate(height, (_) =>
                List.filled(depth, 0),
                growable: false),
            growable: false);
        return imgArr;
    }

    ImageArray2 mat2dInt(int width, int height) {
        final imgArr2 = List.generate(width, (_) =>
            List.filled(height, 0),
            growable: false);
        return imgArr2;
    }

    List<List<T>>addDim<T>(
        List<T> in1, // input flat array
        int dim      // size of new dimension
    ) {
        final len = in1.length;
        List<List<T>> out = [];
        List<T> out1 = [];
        var cnt = 1;
        for (var ix=0; ix<len; ix++){
            out1.add(in1[ix]);
            cnt++;
            if (cnt > dim){
                cnt = 1;
                out.add(out1);
                out1 = [];
            }
        }
        return out;
    }

    List<T> flatten<T>(   // not recursive
        List<List<T>> in1 // input array
    ) {
        return in1.expand((x) => x).toList();
    }

    List<T> extract<T>(List<T> in1, List<bool> mask){
        final len = in1.length;
        List<T> out = [];
        for (var ix=0; ix<len; ix++){
            if (mask[ix]){
                out.add(in1[ix]);
            }
        }
        return out;
    }

    List<int> histogram(
        List<int> flat, // flat image array
        int histSize    // digital number range (eg. 256)
    ){
        // get max value of flat
        final maxVal = flat.reduce(max);
        if (maxVal > histSize) {
            throw Exception("maxVal > histSize");
        }
        final len = flat.length;
        final out = List<int>.filled(histSize, 0);
        for (var ix=0; ix<len; ix++){
            final val = flat[ix];
            out[val] = out[val] + 1;
        }
        return out;
    }


    List<double>conv1d(List<double> arr, int len) {
        // Convolution of a vector with a vector.
        //final kernel = [1/3, 1/3, 1/3];

        final out = List<double>.filled(len, 0);

        for (var k = 0; k < len; k++) {
            if (k == 0){
                out[k] += (arr[0] + arr[1])/ 2;
            } else if (k == len-1) {
                out[k] += (arr[len-1] + arr[len-2])/ 2;
            } else {
                out[k] += (arr[k-1] + arr[k] + arr[k+1])/ 3;
            }
        }
        return out;
    }

    List<int> findConnectedComponents1d(List<int> imgArr, int width, int height, int selectedValue) {
        final connected = List<int>.filled(imgArr.length, 0);
        int ix = 1;

        for (var i = 0; i < width; i++) {
            for (var j = 0; j < height; j++) {
                final index = i * height + j;
                if (imgArr[index] != selectedValue){
                    continue;
                }
                if (i == 0 && j == 0) {
                    connected[index] = ix;
                    ix += 1;
                } else if (i == 0) {
                    if (connected[index - 1] != 0) {
                        connected[index] = connected[index - 1];
                    } else {
                        connected[index] = ix;
                        ix += 1;
                    }
                } else if (j == 0) {
                    if (connected[index - height] != 0) {
                        connected[index] = connected[index - height];
                    } else {
                        connected[index] = ix;
                        ix += 1;
                    }
                } else {
                    if (connected[index - height] != 0 && connected[index - 1] != 0) {
                        connected[index] = connected[index - height];
                        if (connected[index - height] != connected[index - 1]) {
                            connected[index - 1] = connected[index - height];
                        }
                    } else if (connected[index - height] != 0) {
                        connected[index] = connected[index - height];
                    } else if (connected[index - 1] != 0) {
                        connected[index] = connected[index - 1];
                    } else {
                        connected[index] = ix;
                        ix += 1;
                    }
                }

            }
        }
        return connected;
    }




    // find connected components
    // https://en.wikipedia.org/wiki/Connected-component_labeling
    ImageArray2 findConnectedComponents2d(ImageArray2 imgArr, int selectedValue) {
        final width = imgArr.length;
        final height = imgArr[0].length;
        final connected = List.generate(width, (_) =>
            List.filled(height, 0),
            growable: false);
        int ix = 1;

        for (var i = 0; i < imgArr.length; i++) {
            for (var j = 0; j < imgArr[0].length; j++) {

                if (imgArr[i][j] != selectedValue){
                    continue;
                }
                    if (i == 0 && j == 0) {
                        connected[i][j] = ix;
                        ix += 1;
                    } else if (i == 0) {
                        if (connected[i][j-1] != 0) {
                            connected[i][j] = connected[i][j-1];
                        } else {
                            connected[i][j] = ix;
                            ix += 1;
                        }
                    } else if (j == 0) {
                        if (connected[i-1][j] != 0) {
                            connected[i][j] = connected[i-1][j];
                        } else {
                            connected[i][j] = ix;
                            ix += 1;
                        }
                    } else {
                        if (connected[i-1][j] != 0 && connected[i][j-1] != 0) {
                            connected[i][j] = connected[i-1][j];
                            if (connected[i-1][j] != connected[i][j-1]) {
                                connected[i][j-1] = connected[i-1][j];
                            }
                        } else if (connected[i-1][j] != 0) {
                            connected[i][j] = connected[i-1][j];
                        } else if (connected[i][j-1] != 0) {
                            connected[i][j] = connected[i][j-1];
                        } else {
                            connected[i][j] = ix;
                            ix += 1;
                        }
                    }
            }
        }
        return connected;
    }

    // get size of pixels for each connected component
    Map<int, int> getComponentSize(List<int> imgArr) {
        Map<int, int> map = {};
        // flatten array
        for (var element in imgArr) {
            if (element == 0) { continue; } // only for background, no vegetation !
            if(!map.containsKey(element)) {
                map[element] = 1;
            } else {
                map[element] = map[element]! + 1;
            }
        }
        return map;
    }

    List<int> getComponentListSize(List<int> imgArr) {
        final max = imgArr.max;
        final out = List<int>.filled(max+1, 0);
        final len = imgArr.length;
        for (var ix=1; ix<len; ix++) {  // background (0) is not counted
            final val = imgArr[ix];
            out[val]++;
        }
        return out;
    }

    Uint8List arr2ToImg(List<List<int>> arr2) {
        final width = arr2.length;
        final height = arr2[0].length;
        final img = im.Image(width: width, height: height);

        // Iterate over its pixels
        for (var i = 0; i < img.width; i++) {
            for (var j = 0; j < img.height; j++) {
                final pix = arr2[i][j];
                img.setPixelRgb(i, j, 0, pix * 255, 0);
            }
        }
        final jpg = im.encodeJpg(img);
        return jpg;
    }



    List<int> stretch8bit(List<double> in1){
        final len = in1.length;
        final min1 = in1.min;
        final max1 = in1.max;
        final out = List<int>.generate(len, (i) => (in1[i]-min1)*255/(max1-min1) ~/ 1);
        return out;
    }


}

