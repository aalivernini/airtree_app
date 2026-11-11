/// Tile URL template of the OpenStreetMap standard raster tiles.
///
/// The standard service serves zoom levels 0 to 19; beyond that it answers
/// HTTP 400. The URL must stay on https: on a redirect dart:io replaces the
/// User-Agent with its own default, which OpenStreetMap blocks as well.
const String osmTileTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Highest zoom level for which the OpenStreetMap standard tiles exist.
const int kOsmMaxNativeZoom = 19;

/// User-Agent sent with every OpenStreetMap tile request.
///
/// OpenStreetMap blocks the flutter_map default User-Agent and the example
/// package identifier shipped with the flutter_map documentation, and it
/// answers with a rendered "403 Access blocked" image and HTTP status 200, so
/// the failure is invisible to the application. The tile usage policy requires
/// a distinct, stable User-Agent that names the application and optionally a
/// contact URL or email.
const String osmUserAgent =
    'Airtree/1.0.7 (it.alivernini.airtree; '
    'https://github.com/aalivernini/airtree_app)';
