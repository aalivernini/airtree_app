import 'package:flutter/material.dart';//import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider_lai.dart' as pr;
//import 'package:toggle_switch/toggle_switch.dart' as ts;




// ts.ToggleSwitch getCameraDirection(BuildContext context){
//     final pLai = Provider.of<pr.ProviderLai>(context, listen: false);
//
//     final ix = pLai.ixCameraDirection;
//     final icon2 = [Icons.north, Icons.north_east, Icons.south_east, Icons.south];
//
//     final mQuery  = MediaQuery.of(context);
//     final height  = mQuery.size.height;
//     final width   = mQuery.size.width;
//
//     final vertical = height < width ? false : true;
//
//     return ts.ToggleSwitch(
//         fontSize: 16.0,
//         initialLabelIndex: ix,
//         activeBgColor: const [Colors.blue],
//         activeFgColor: Colors.white,
//         inactiveBgColor: Colors.grey,
//         inactiveFgColor: Colors.grey[900],
//         totalSwitches: icon2.length,
//         icons: icon2,
//         isVertical: !vertical,
//         onToggle: (index) {
//             pLai.setCameraDirection(index!);
//             Navigator.pushReplacementNamed(context, '/camera');
//         });
// }



String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
        return 'Please enter a number';
    }
    try {
        double.parse(value);
    } on FormatException {
        return 'Please enter a number';
    }
    return null;
}


