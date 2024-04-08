import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class Air {
  static Container selected = Container(
    padding: EdgeInsets.zero,
    child: Icon(Icons.circle, size: 30, color: Colors.yellow.withOpacity(0.5)),
  );

  static Container tree = Container(
    padding: EdgeInsets.zero,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.green, //era green
    ),
    child: Icon(
      MdiIcons.tree,
      color: Colors.white,
    ),
  );

  static Container treeRow = Container(
    padding: EdgeInsets.zero,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.green,
    ),
    child: const Icon(
      Icons.add_road,
      color: Colors.white,
    ),
  );

  static Container forest = Container(
    padding: EdgeInsets.zero,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.green,
    ),
    child: Icon(
      MdiIcons.forest,
      color: Colors.white,
    ),
  );

  static Container prjTree = Container(
    padding: EdgeInsets.zero,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.blue,
    ),
    child: Icon(
      MdiIcons.tree,
      color: Colors.white,
    ),
  );

  static Container prjTreeRow = Container(
    padding: EdgeInsets.zero,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.blue,
    ),
    child: const Icon(
      Icons.add_road,
      color: Colors.white,
    ),
  );

  static Container prjForest = Container(
    padding: EdgeInsets.zero,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.blue,
    ),
    child: Icon(
      MdiIcons.forest,
      color: Colors.white,
    ),
  );
}
