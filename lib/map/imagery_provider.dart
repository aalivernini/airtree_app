import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:Airtree/map/raster_imagery.dart';

/// The raster background the map displays.
enum MapBackground {
  /// Esri World Imagery, with the Wayback fallback when needed.
  esri,

  /// OpenStreetMap standard raster tiles.
  openStreetMap,
}

/// Holds the active map background and the state of the Esri imagery service.
///
/// Mirrors the interface of the map-imagery capability: the tile templates and
/// the network probe belong to that capability, this holder only keeps the
/// state the map and the attribution label read.
class ImageryProvider extends ChangeNotifier {
  /// Creates a provider with the Esri background active and no fallback.
  ImageryProvider();

  MapBackground _background = MapBackground.esri;
  bool _esriFallbackActive = false;
  ImageryAvailability _availability = ImageryAvailability.unavailable;
  String _esriCopyrightText = '';

  /// The raster background currently displayed by the map.
  MapBackground get background => _background;

  /// Selects the background to display and notifies the listeners.
  void selectBackground(MapBackground background) {
    if (_background == background) return;
    _background = background;
    notifyListeners();
  }

  /// Whether the Esri World Imagery Wayback layer is in use.
  bool get esriFallbackActive => _esriFallbackActive;

  /// The availability of the key-bearing Esri imagery service.
  ImageryAvailability get availability => _availability;

  /// The copyright text published by the Esri imagery service, when known.
  String get esriCopyrightText => _esriCopyrightText;

  /// The tile URL template of the active Esri layer.
  ///
  /// Empty while no imagery service is configured; the imagery capability
  /// owns the actual templates.
  String get esriTileTemplate => '';

  /// Applies the outcome of an availability probe.
  ///
  /// A result other than [ImageryAvailability.available] activates the
  /// Wayback fallback.
  void applyProbeResult(ImageryProbeResult result) {
    _availability = result.availability;
    if (result.copyrightText.isNotEmpty) {
      _esriCopyrightText = result.copyrightText;
    }
    if (result.availability != ImageryAvailability.available) {
      activateEsriFallback();
    } else {
      notifyListeners();
    }
  }

  /// Switches to the Esri World Imagery Wayback layer.
  ///
  /// The switch is one-way and idempotent so a flapping service cannot
  /// thrash the map.
  void activateEsriFallback() {
    if (_esriFallbackActive) return;
    _esriFallbackActive = true;
    notifyListeners();
  }

  /// Handles a tile load failure of the Esri layer.
  ///
  /// The fallback is not activated while another background is displayed.
  void activateEsriFallbackOnTileError(Object error) {
    if (_background != MapBackground.esri) return;
    activateEsriFallback();
  }

  /// Refreshes the availability of the Esri imagery service.
  ///
  /// Never throws: an unavailable service is a state, not an error.
  Future<void> refreshAvailability({http.Client? client}) async {
    notifyListeners();
  }
}
