import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:Airtree/env.dart';
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
/// The provider owns the Esri availability probe and the one-way switch to the
/// Wayback fallback, so the map background, its availability and the layer
/// that is actually rendered always share one source of truth.
class ImageryProvider extends ChangeNotifier {
  /// Creates a provider in the default state: Esri World Imagery active, no
  /// fallback engaged and no probe result recorded yet.
  ///
  /// [apiKey] overrides the ArcGIS key read from the environment; it exists so
  /// the state machine can be exercised without the real credentials.
  ImageryProvider({String? apiKey}) : _apiKeyOverride = apiKey;

  final String? _apiKeyOverride;

  /// The ArcGIS key the provider uses, defaulting to the configured one.
  String get _apiKey => _apiKeyOverride ?? Env.arcgisLocationKey;

  MapBackground _background = MapBackground.esri;
  bool _esriFallbackActive = false;
  ImageryAvailability _availability = ImageryAvailability.unavailable;
  String _esriCopyrightText = '';

  /// The active background.
  MapBackground get background => _background;

  /// Selects the active background and notifies the listeners.
  void selectBackground(MapBackground background) {
    _background = background;
    notifyListeners();
  }

  /// True once the Wayback fallback is in use.
  bool get esriFallbackActive => _esriFallbackActive;

  /// Availability reported by the last probe.
  ImageryAvailability get availability => _availability;

  /// The `copyrightText` reported by the last successful probe, if any.
  String get esriCopyrightText => _esriCopyrightText;

  /// The tile template to use for the Esri layer, or null when no key is
  /// configured and the fallback is not active.
  String? get esriTileTemplate {
    if (_esriFallbackActive) return esriWaybackTileTemplate();
    return esriWorldImageryTileTemplate(_apiKey);
  }

  /// Applies a probe result and activates the fallback when needed.
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

  /// Activates the Wayback fallback. The switch is one-way: it never flips
  /// back within a session, so a flapping service cannot thrash the map.
  void activateEsriFallback() {
    if (_esriFallbackActive) return;
    _esriFallbackActive = true;
    notifyListeners();
  }

  /// Entry point for a tile load error on the Esri layer.
  ///
  /// The fallback is engaged only while the Esri background is active; errors
  /// raised by another layer are ignored.
  void activateEsriFallbackOnTileError(Object error) {
    if (_background != MapBackground.esri) return;
    activateEsriFallback();
  }

  /// Runs the availability probe and applies its result. Never throws.
  Future<void> refreshAvailability({http.Client? client}) async {
    try {
      final result = await probeEsriImagery(_apiKey, client: client);
      applyProbeResult(result);
    } catch (_) {
      applyProbeResult(
        const ImageryProbeResult(availability: ImageryAvailability.unavailable),
      );
    }
  }
}
