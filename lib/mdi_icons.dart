/// Vendored Material Design Icons.
///
/// This file defines the subset of Material Design Icons used by this app.
/// The icons are defined as plain [IconData] constants (not subclasses),
/// which is compatible with Flutter 3.44+ where [IconData] is a final class.
///
/// The font 'Material Design Icons' is registered in pubspec.yaml under the
/// `fonts:` section, bundling the TTF from assets/fonts/.
import 'package:flutter/widgets.dart';

/// A minimal subset of Material Design Icons used throughout the app.
///
/// Constants use the same names as the original
/// `material_design_icons_flutter` package so that existing call sites
/// (e.g. `MdiIcons.tree`) work unchanged after updating the import.
class MdiIcons {
  const MdiIcons._();

  /// Tree icon (Material Design Icons codepoint 0xf0531).
  static const tree = IconData(
    0xf0531,
    fontFamily: 'Material Design Icons',
  );

  /// Forest icon (Material Design Icons codepoint 0xf1897).
  static const forest = IconData(
    0xf1897,
    fontFamily: 'Material Design Icons',
  );

  /// Information slab circle icon (Material Design Icons codepoint 0xf1c69).
  static const informationSlabCircle = IconData(
    0xf1c69,
    fontFamily: 'Material Design Icons',
  );

  /// Swap horizontal icon (Material Design Icons codepoint 0xf04e1).
  static const swapHorizontal = IconData(
    0xf04e1,
    fontFamily: 'Material Design Icons',
  );

  /// Delete icon (Material Design Icons codepoint 0xf01b4).
  static const delete = IconData(
    0xf01b4,
    fontFamily: 'Material Design Icons',
  );
}
