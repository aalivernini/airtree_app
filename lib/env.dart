import 'package:envied/envied.dart';

part 'env.g.dart';

/// Environment-backed configuration for the application.
///
/// Values are read from the `.env` file at the package root by `envied`
/// (run `dart run build_runner build` to generate `lib/env.g.dart`, which is
/// git-ignored and must never be committed).
@Envied(path: '.env')
abstract class Env {
  /// Base URL of the Airtree backend API.
  @EnviedField(varName: 'ADRESS_HOME', obfuscate: true)
  static final String adressHome = _Env.adressHome;

  /// API key for the Airtree backend API.
  @EnviedField(varName: 'AIRTREE_KEY', obfuscate: true)
  static final String airtreeKey = _Env.airtreeKey;

  /// ArcGIS Location Platform API key used to access the Esri basemap services.
  ///
  /// The value is an ArcGIS Location Platform API key (not a JWT and not a
  /// portal token). It is sent to ArcGIS as the `token` query parameter of the
  /// basemap endpoints; `apiKey=` is rejected with error 499. The key is
  /// embedded in the application binary, so it is an identifier rather than a
  /// secret and should be restricted and rotated accordingly.
  @EnviedField(varName: 'ARCGIS_LOCATION_KEY', obfuscate: true)
  static final String arcgisLocationKey = _Env.arcgisLocationKey;
}
