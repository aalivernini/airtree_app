import 'dart:convert';

import 'package:http/http.dart' as http;

/// Host serving the current Esri World Imagery raster tiles.
const String kEsriImageryHost = 'ibasemaps-api.arcgis.com';

/// Path of the Esri World Imagery raster MapServer.
const String kEsriImageryServicePath =
    '/arcgis/rest/services/World_Imagery/MapServer';

/// Host serving Esri World Imagery Wayback releases.
const String kEsriWaybackHost = 'wayback.maptiles.arcgis.com';

/// Release id of the pinned Esri World Imagery Wayback release.
///
/// `43291` is `World Imagery (Wayback 2026-10-29)` (layer `WB_2026_R10`).
/// The service answers with a 301 redirect to the release that owns the
/// requested tile at the requested zoom; `package:http` follows it.
const String kEsriWaybackReleaseId = '43291';

/// Highest zoom level for which Esri World Imagery serves real imagery.
///
/// Beyond this level the service answers with a uniform blank grey image.
const int kEsriImageryMaxNativeZoom = 19;

/// Availability of an imagery endpoint.
enum ImageryAvailability {
  /// The endpoint answered with usable imagery metadata.
  available,

  /// The key is missing, invalid, expired or not permitted.
  unauthorized,

  /// The service is disabled, rate limited or unreachable.
  unavailable,
}

/// Outcome of the imagery availability probe.
class ImageryProbeResult {
  /// Creates a probe outcome.
  const ImageryProbeResult({
    required this.availability,
    this.copyrightText = '',
    this.statusCode,
  });

  /// Whether the endpoint can serve the configured key.
  final ImageryAvailability availability;

  /// The service `copyrightText`, the authoritative attribution for the layer.
  final String copyrightText;

  /// HTTP status of the probe response, for diagnostics.
  final int? statusCode;
}

/// Strips surrounding whitespace and one layer of double quotes from a key.
///
/// `envied` already unquotes `.env` values, but the secret store may hold the
/// key in quotes and ArcGIS rejects a quoted token with error 498.
String sanitizeApiKey(String raw) {
  var value = raw.trim();
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    value = value.substring(1, value.length - 1).trim();
  }
  return value;
}

/// Tile URL template of the key-bearing Esri World Imagery layer, or null when
/// no usable key is configured.
///
/// The ArcGIS REST path order is `{z}/{row}/{col}`; in flutter_map terms the
/// row is `y` and the column is `x`.
String? esriWorldImageryTileTemplate(String apiKey) {
  final key = sanitizeApiKey(apiKey);
  if (key.isEmpty) return null;
  return 'https://$kEsriImageryHost$kEsriImageryServicePath/tile/{z}/{y}/{x}'
      '?token=${Uri.encodeQueryComponent(key)}';
}

/// Tile URL template of the Esri World Imagery Wayback fallback layer.
String esriWaybackTileTemplate() =>
    'https://$kEsriWaybackHost$kEsriImageryServicePath'
    '/tile/$kEsriWaybackReleaseId/{z}/{y}/{x}';

/// Classifies an Esri metadata response.
///
/// ArcGIS answers token problems with HTTP 200 and a `text/plain` JSON body
/// (`{"error":{"code":499,...}}`), so the body must be inspected. Esri
/// publishes no "quota exceeded" code, so every non-image, non-200 outcome is
/// treated as "primary unavailable".
ImageryAvailability classifyImageryResponse({
  required int statusCode,
  required String contentType,
  required String body,
}) {
  if (statusCode != 200) {
    if (statusCode == 401 || statusCode == 403) {
      return ImageryAvailability.unauthorized;
    }
    return ImageryAvailability.unavailable;
  }

  Map<String, dynamic>? document;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) document = decoded;
  } on FormatException {
    document = null;
  }

  if (document == null) {
    // A body that is not a JSON document cannot describe a usable layer.
    return ImageryAvailability.unavailable;
  }

  final error = document['error'];
  if (error is Map<String, dynamic>) {
    final code = error['code'];
    if (code == 498 || code == 499) {
      return ImageryAvailability.unauthorized;
    }
    return ImageryAvailability.unavailable;
  }

  final copyrightText = document['copyrightText'];
  if (copyrightText is String && copyrightText.isNotEmpty) {
    return ImageryAvailability.available;
  }
  return ImageryAvailability.unavailable;
}

/// Probes the Esri imagery endpoint and reports whether it can be used.
///
/// The probe also returns the service `copyrightText`, which is the
/// authoritative attribution string for the layer in use. It never throws:
/// a timeout or a transport error yields an [ImageryAvailability.unavailable]
/// result.
Future<ImageryProbeResult> probeEsriImagery(
  String apiKey, {
  http.Client? client,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final key = sanitizeApiKey(apiKey);
  if (key.isEmpty) {
    return const ImageryProbeResult(
      availability: ImageryAvailability.unauthorized,
    );
  }

  final uri = Uri.parse(
    'https://$kEsriImageryHost$kEsriImageryServicePath'
    '?f=json&token=${Uri.encodeQueryComponent(key)}',
  );

  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient.get(uri).timeout(timeout);
    final availability = classifyImageryResponse(
      statusCode: response.statusCode,
      contentType: response.headers['content-type'] ?? '',
      body: response.body,
    );
    return ImageryProbeResult(
      availability: availability,
      copyrightText: _extractCopyrightText(response.body),
      statusCode: response.statusCode,
    );
  } catch (_) {
    return const ImageryProbeResult(availability: ImageryAvailability.unavailable);
  }
}

/// Extracts the service `copyrightText` from a metadata document.
///
/// Returns an empty string when the body is not a JSON document or carries no
/// attribution.
String _extractCopyrightText(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final copyrightText = decoded['copyrightText'];
      if (copyrightText is String) return copyrightText;
    }
  } on FormatException {
    return '';
  }
  return '';
}
