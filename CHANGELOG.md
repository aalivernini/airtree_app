# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v1.0.7] - 2026-11-11

This release brings the Airtree field app up to a current Android and Flutter toolchain so it can be built and distributed again, and it makes the field survey workflow usable end to end: the app now talks to the Airtree server over the current API, exports the collected observations as GeoJSON archives for downstream analysis, and offers a leaf-area-index camera workflow based on canopy greenness.

### This release (since 0.9.4)

- The Android build moves to a current Gradle, Android Gradle Plugin and Kotlin toolchain with Java 17 and the it.alivernini.airtree application id, so the app compiles and installs on present-day devices.
- The project is migrated towards Flutter 3.58, with the generated localization sources and the generated asset manifest now kept inside the repository.
- The Material Design icon set is vendored into the app, removing the unmaintained icon package dependency.
- The application entry point and the desktop plugin registration are updated for the new Flutter embedding.

### Current minor series (since v0.9.0)

- Server communication is reworked around the current FastAPI protocol: every answer carries a status code and a message, and a failed project upload shows the server error text with a copy-to-clipboard action.
- Project sharing exports the trees, the tree rows and the forest polygons as GeoJSON files bundled into a single zip archive.
- Tabular editing of the survey data is partially implemented for the main observation forms.
- The forest areas on the map are extended: the portions are loaded from the local database, the total area is validated and removing a portion updates the status of the project.
- New localized messages warn the user when the forest portions would exceed the total area and explain how to remove the only remaining portion.
- The leaf-area-index camera workflow gains a canopy greenness threshold, usable as the default analysis method.

### Current major series (since v0.9.0)

- Field surveys are captured per project as points, tree rows and forest polygons, all persisted in the local database and shareable as GeoJSON.
- The exchange with the Airtree server uses one consistent answer contract for the settings retrieval and for the project upload.
- The app is brought onto a modern Android toolchain so it can be compiled, installed and updated on current devices.
