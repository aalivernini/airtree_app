# Airtree — Project Agent Documentation

## Project Overview

Airtree is a Flutter smartphone application for airtree/vegetation mapping. It uses
[flutter_map](https://github.com/fleaflet/flutter_map) as the mapping engine and allows
field operators to collect, geotag, and submit vegetation observations linked to GPS
coordinates and projects.

## Tech Stack

| Component        | Technology                                      |
|------------------|-------------------------------------------------|
| Framework        | Flutter 3.47.9                                  |
| Language         | Dart 3.13.7                                     |
| Map engine       | flutter_map ^6.0.1, latlong2 ^0.9.0             |
| State management | provider ^6.0.5                                 |
| Location         | geolocator ^10.1.0, flutter_map_location_marker |
| Camera           | camera ^0.11.3, sensors_plus ^4.0.2             |
| Database         | sqflite ^2.2.8+4, objectid ^3.0.0               |
| Networking       | dio ^5.2.1+1, http ^1.1.0                      |
| UI               | flutter_speed_dial ^7.0.0, fl_chart ^0.64.0    |
| Localization     | flutter_localizations, intl ^0.20.2            |
| Other            | path_provider, permission_handler, file_picker, share_plus, envied |

## Architecture / Key Files

```
lib/
├── main.dart               # App entry point, MultiProvider setup, NavigationPage
├── widget.dart             # Main UI scaffold, page list, bottom navigation
├── widget_other.dart       # Secondary/drawer UI components
├── form.dart               # Data entry forms (GreenForm)
├── form_user.dart          # User-related forms
├── form_parts.dart         # Reusable form components
├── data.dart               # Data models
├── database.dart           # SQLite database helpers
├── providers.dart          # Provider state classes (Global, Map, Editor, Panel, Result, Param, ProviderLai)
├── icon.dart               # Icon definitions / aliases
├── mdi_icons.dart          # Vendored Material Design Icons (tree, forest, informationSlabCircle, swapHorizontal, delete)
├── geo.dart                # Geolocation helpers
├── geo_info.dart           # Geographic info utilities
├── io.dart                 # File I/O utilities
├── http_result.dart        # HTTP result handling
├── export_import_database.dart
├── chart.dart
├── enums.dart
├── l10n/
│   └── l10n.dart           # Localization configuration
├── map/
│   ├── raster_imagery.dart   # Esri tile URL templates, availability probe
│   ├── imagery_provider.dart # Active background + Wayback fallback state
│   └── attribution.dart       # Bottom-left credit label for the imagery in use
├── env.dart                # envied access to the .env variables
├── privacy_terms.dart      # Terms of use and privacy notice texts
├── src/generated/l10n/
│   ├── app_localizations.dart
│   ├── app_localizations_en.dart
│   └── app_localizations_it.dart
├── camera/
│   ├── camera.dart         # Camera capture screen
│   ├── provider_lai.dart   # LAI (Leaf Area Index) provider
│   ├── array_plus.dart
│   ├── colour.dart
│   ├── threshold.dart
│   └── widget/
│       ├── oriented_camera.dart
│       ├── lai_wid_util.dart
│       ├── lai_widget.dart
│       └── shape.dart
└── env.g.dart              # Generated envied configuration (git-ignored)
```

**Note:** `package:` imports use the form `package:Airtree/...` (e.g., `package:Airtree/l10n/l10n.dart`).

## Environment

- **Flutter:** 3.47.9
- **Dart:** 3.13.7
- **Min SDK:** Android (see `android/app/build.gradle`)
- **Assets:** `assets/` (general assets), `lib/l10n/` (localization JSON), `assets/fonts/materialdesignicons-webfont.ttf` (vendored MDI font)
- **Toolchain on PATH:** the Flutter SDK is not on the default PATH; export
  `PATH=/home/alessandro/aa/pack/flutter/bin:$PATH` before any `flutter`/`dart` command.

## Build & Run Commands

```sh
flutter pub get            # Install dependencies
flutter run               # Run on connected device/emulator
flutter build apk         # Build release APK
flutter build apk --debug  # Build debug APK
flutter analyze           # Run static analysis (dart analyze / flutter analyze)
```

### Generated files

`lib/env.g.dart` is **generated** by `envied` and is **git-ignored**: it must never be
staged nor committed. Generate it before any build, analysis or test run:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The same command also regenerates `lib/gen/fonts.gen.dart` (asset manifest), which is
likewise git-ignored. `flutter analyze` rewrites the tracked `analysis_options.yaml` and
`flutter pub get` rewrites the tracked `pubspec.lock`; restore both with
`git checkout -- analysis_options.yaml pubspec.lock` before committing.

### Tests and smoke run

```sh
flutter test               # unit and widget tests
flutter build bundle       # canonical smoke run: whole-program compile
```

`flutter build bundle` is the canonical smoke command, because it compiles every Dart
file (including the generated `lib/env.g.dart`) without needing a platform toolchain.
If it is unavailable, fall back to `flutter build apk --debug` and then to
`flutter build web --release`.

## Configuration (envied)

The ArcGIS Location Platform API key is read from the `.env` file at the package root
through `envied`:

- `lib/env.dart` declares the fields and the `part 'env.g.dart';` directive.
- The key is the `.env` variable `ARCGIS_LOCATION_KEY`, mapped to the field
  `Env.arcgisLocationKey` with `@EnviedField(varName: 'ARCGIS_LOCATION_KEY', obfuscate: true)`.
  The value is an ArcGIS Location Platform API key and is sent to ArcGIS as the `token`
  query parameter; `apiKey=` is rejected with error 499.
- `lib/env.g.dart` is produced by `dart run build_runner build` and is git-ignored.
- The build **fails** when `ARCGIS_LOCATION_KEY` is missing from `.env`
  (`Environment variable not found for field 'arcgisLocationKey'.`): the field is
  deliberately not optional, because a silently empty key would downgrade every user to
  the archived imagery.
- `.env` is a symlink to the shared secret store and is never staged.

## Map imagery and attribution

The map background is provided by the `lib/map/` capability modules:

- `lib/map/raster_imagery.dart` holds the Esri World Imagery and OpenStreetMap tile URL
  templates, the key sanitation, the availability classifier and the startup probe of
  the Esri metadata endpoint.
- `lib/map/imagery_provider.dart` owns the active background (Esri World Imagery or
  OpenStreetMap), the probe result and the **Wayback fallback** state. When the Esri
  service cannot serve the key (missing, invalid, expired, disabled, unreachable or
  quota-exhausted), the map automatically switches to the Esri World Imagery Wayback
  layer; the switch is one-way within a session.
- `lib/map/attribution.dart` renders the attribution label.

The map type picker lets the user choose **Esri World Imagery** or **OpenStreetMap**.

**Attribution obligation:** the map must always show the credit of the imagery in use,
bottom-left and unobstructed (never hidden under the UI or off-screen):

- Esri (current imagery or Wayback fallback): the literal text "Powered by Esri" plus
  the provider list published by the service.
- OpenStreetMap: "© OpenStreetMap contributors".

Both credits are licence text and are never translated; only the Italian connective
wording is localized.

## Conventions

- **Package imports:** Always use `package:Airtree/...` for internal imports.
- **Localization:** ARB files live in `lib/l10n/`; generated files are in `lib/src/generated/l10n/`.
- **Vendored icons:** Custom/vendored icons are in `lib/mdi_icons.dart` backed by the `Material Design Icons` font in `assets/fonts/`.
- **State management:** Provider with `ChangeNotifierProvider` for each domain (Global, Map, Editor, Panel, Result, Param, LAI).
- **Database:** SQLite via `sqflite`; models expose `fromDb()` / `dbUpdate()` static and instance methods.

## Known Decisions

### Vendored MDI Icons (2026-07-01)

The `material_design_icons_flutter` package (7.0.7296) is unmaintained and incompatible
with Flutter 3.44's `final IconData` class. Instead of updating the package, 5 required
icons were vendored directly:

- `tree`
- `forest`
- `informationSlabCircle`
- `swapHorizontal`
- `delete`

These are implemented in `lib/mdi_icons.dart` using a custom `IconData` that references
the vendored `Material Design Icons` font registered in `pubspec.yaml` under
`fonts → family: Material Design Icons`. The font file (`materialdesignicons-webfont.ttf`)
is stored in `assets/fonts/`.
