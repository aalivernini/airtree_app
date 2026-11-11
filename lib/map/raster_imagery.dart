/// Availability of an imagery endpoint.
///
/// Mirrors the interface of the map-imagery capability; the raster
/// implementation that owns the tile templates and the startup probe lives
/// with the imagery capability itself.
enum ImageryAvailability {
  /// The endpoint answered with usable imagery metadata.
  available,

  /// The key is missing, invalid, expired or not permitted.
  unauthorized,

  /// The service is disabled, rate limited or unreachable.
  unavailable,
}

/// Outcome of the imagery availability probe.
///
/// Mirrors the interface of the map-imagery capability; the probe itself and
/// the extraction of the service copyright text belong to that capability.
class ImageryProbeResult {
  /// Creates a probe outcome.
  const ImageryProbeResult({
    required this.availability,
    this.copyrightText = '',
    this.statusCode,
  });

  /// Whether the probed endpoint can serve imagery.
  final ImageryAvailability availability;

  /// The copyright text published by the probed service, when it provided one.
  final String copyrightText;

  /// The HTTP status code of the probe response, when there was one.
  final int? statusCode;
}
