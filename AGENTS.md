# Airtree — Project Agent Documentation

## Project Overview

Airtree is a Flutter smartphone application for airtree/vegetation mapping. It uses
[flutter_map](https://github.com/fleaflet/flutter_map) as the mapping engine and allows
field operators to collect, geotag, and submit vegetation observations linked to GPS
coordinates and projects.

## Tech Stack

| Component        | Technology                                      |
|------------------|-------------------------------------------------|
| Framework        | Flutter 3.44.4                                  |
| Language         | Dart 3.12.2                                     |
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
└── env.g.dart              # Generated envied configuration
```

**Note:** `package:` imports use the form `package:Airtree/...` (e.g., `package:Airtree/l10n/l10n.dart`).

## Environment

- **Flutter:** 3.44.4
- **Dart:** 3.12.2
- **Min SDK:** Android (see `android/app/build.gradle`)
- **Assets:** `assets/` (general assets), `lib/l10n/` (localization JSON), `assets/fonts/materialdesignicons-webfont.ttf` (vendored MDI font)

## Build & Run Commands

```sh
flutter pub get            # Install dependencies
flutter run               # Run on connected device/emulator
flutter build apk         # Build release APK
flutter build apk --debug  # Build debug APK
flutter analyze           # Run static analysis (dart analyze / flutter analyze)
```

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
