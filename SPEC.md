# SPEC: Esri World Imagery background, OSM 403 fix, and map attribution label

## Context

### Problem statement

Three defects in the Airtree Flutter app (`/home/alessandro/aa/git/ring/modeling/airtree/app`, package `Airtree`, Flutter 3.47.9 / Dart 3.13.7, `flutter_map` 6.2.1):

1. **OSM 403.** The OpenStreetMap background (`lib/widget.dart:1136-1142`) sends `userAgentPackageName: 'dev.fleaflet.flutter_map.example'`. flutter_map 6.2.1 turns that into the wire header `User-Agent: flutter_map (dev.fleaflet.flutter_map.example)` (`tile_layer.dart:333-337`), and that exact string is on OSM's block denylist. OSM answers **HTTP 200** with `content-type: image/png`, header `x-blocked: Access denied. See https://operations.osmfoundation.org/policies/tiles/`, and a rendered "403 Access blocked" PNG — so the failure is completely silent in the app and invisible to any status-code check.
2. **Bing/Azure imagery.** The only satellite background is `https://atlas.microsoft.com/map/tile?...&subscription-key=${Env.azureKey}` (`lib/widget.dart:1143-1150`). It must become Esri World Imagery, authenticated with the ArcGIS location API key that already exists in `.env` as `ARCGIS_LOCATION_KEY`, with a graceful fallback to Esri World Imagery Wayback when the free quota is not available.
3. **No attribution at all.** `grep -rn "attribution" lib/` → zero hits. OSM and Esri both require a visible, unobstructed credit. A very small label must sit at the bottom-right of the map, showing the credit of the imagery actually in use.

### Decisions taken during clarification

| Question | Decision |
|---|---|
| OSM layer | Keep it, fix the User-Agent, add OSM credit |
| Esri service | ArcGIS Online current World Imagery (key-bearing) + Esri World Imagery Wayback fallback |
| Quota handling | Automatic runtime detection, with graceful switch to Wayback |
| Attribution | Dynamic per active layer, localized through ARB (en + it), verified against the live Esri/OSM licence clauses |
| Key wiring | `envied`, variable name `ARCGIS_LOCATION_KEY`, value read from the existing `.env` |

### Key constraints and verified facts (from investigation — all re-verified live)

**A. `ARCGIS_LOCATION_KEY` is real, valid, and quoted.**
- `.env` is a symlink to `/home/alessandro/aa/git/ring/modeling/airtree/secret/app/.env`; it defines `ADRESS_HOME`, `AIRTREE_KEY`, `ARCGIS_LOCATION_KEY`, `BING_KEY`. **`AZURE_KEY` and `AZURE_ID` are absent.**
- `ARCGIS_LOCATION_KEY` is present, non-empty, **293 characters inside surrounding double quotes**, 5 dot-separated segments (`27..250..12`), alnum/`_`/`-`/`.` — the ArcGIS Location Platform API-key layout. `envied`'s dotenv-derived parser strips the quotes; a defensive strip is still specified.
- Verified against live endpoints (key never printed): `www.arcgis.com/sharing/rest/portals/self?f=json&token=KEY` → **200, `error: null`, portal user `alivernini`**; with the quotes retained → **498 "Invalid token."**. `basemapstyles-api.arcgis.com/.../styles/v2/styles/arcgis/imagery?f=json&token=KEY` → **200**; `geocode.arcgis.com/.../findAddressCandidates` → **200**. The key is live and valid.
- **It must be an ArcGIS Location API key.** `ibasemaps-api.arcgis.com` accepts `?token=`; `?apiKey=` returns `{"error":{"code":499,"message":"Token Required."}}`.

**B. Esri endpoints (verified, HTTP status + content-type + bytes):**
- Primary (key-bearing): `https://ibasemaps-api.arcgis.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}?token={KEY}` → 200 `image/jpeg`. Tile order is **`{z}/{row}/{col}`**, i.e. `{z}/{y}/{x}` in flutter_map terms (Esri `row` = north→south = flutter_map `y`; Esri `col` = west→east = flutter_map `x`). Verified by edge correlation against the OSM tile `5/10/16` and by z=1 quadrant inspection.
- Primary metadata (also used by the probe): `https://ibasemaps-api.arcgis.com/arcgis/rest/services/World_Imagery/MapServer?f=json&token={KEY}` → 200 JSON, `copyrightText` = `"Source: Esri, Vantor, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community"`. `tileInfo.lods` = 24 levels (0→23), but **tiles at z ≥ 20 are a uniform 2521-byte grey image** → `maxNativeZoom: 19`.
- Wayback fallback (tokenless): `https://wayback.maptiles.arcgis.com/arcgis/rest/services/World_Imagery/MapServer/tile/43291/{z}/{y}/{x}` → 200 `image/jpeg` after the server's 301 (192 of 198 release ids redirect to the release that actually owns the tile at that zoom). The pinned id `43291` = `World Imagery (Wayback 2026-10-29)` / layer `WB_2026_R10`; the directly-servable id `7110` = `World Imagery (Wayback 2022-11-02)`. `package:http` follows redirects by default (`followRedirects` default true, max 5), so the 301 is transparent.
- **Wayback needs no token**; `?token=` is accepted and ignored.
- **"Latest World Imagery" is not an ArcGIS product name.** `services.arcgisonline.com/.../Latest_World_Imagery/MapServer?f=json` → `{"error":{"code":404,"message":"Service not found"}}`; `ibasemaps-api.../Latest_World_Imagery/MapServer` → 404 `"The requested URL was not found."`; ArcGIS Online search `title:"Latest World Imagery"` → `total: 0`; `tags:"Latest World Imagery"` → `total: 0`. The current-imagery item is `10df2279f9684e4a9f6a7f08febac2a9`, title `World Imagery`, owner `esri`, `accessInformation` = `"Esri, Vantor, Earthstar Geographics, and the GIS User Community"`. **The live `World_Imagery` service *is* the continuously-updated "latest" World Imagery** (its z16 Rome tile is byte-identical, md5 `6addd51824388f0e595972c849e98032`, to the newest Wayback release). The app therefore ships "Esri World Imagery" as the layer name; "Latest World Imagery" is recorded here as the requirement's wording, not as a service name.

**C. Quota / availability detection — what is actually observable.**
- `ibasemaps-api` **does not validate the token value**: a garbage token returns byte-identical tiles; only a *missing* token returns 499. Quota exhaustion therefore **cannot** be inferred from the raster tile response. Esri publishes **no** "quota exceeded" error code or message string for Location Platform; the documented behaviour is "service access disabled" until the free tier resets.
- Observable failure signals, all verified: `499 "Token Required."` (missing/empty key, `text/plain` JSON body, HTTP 200), `498` / HTTP 401 (invalid or expired key), HTTP 403 (disabled service / no privilege), HTTP 429 / 5xx (service-side trouble), network error or timeout, and a tile body that is **not** a decodable image (ArcGIS answers `text/plain` JSON, which fails image decoding → the tile load throws).
- Consequence: detection must combine (i) a **one-shot startup probe** of the key-bearing metadata endpoint and (ii) **runtime tile-load errors** on the Esri layer. The classifier must treat *any* non-image / non-200 outcome as "primary unavailable" — that is the only safe rule given no published quota code.

**D. Attribution wording (verbatim, fetched live on 2026-11-11):**
- Esri current World Imagery — service `copyrightText`: `"Source: Esri, Vantor, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community"`. Esri additionally mandates the literal text **"Powered by Esri"**, with the word *Esri* linked to `https://www.esri.com`, displayed bottom-right, unobstructed, ≥12 px recommended, colour `#323232` on `#ffffff` at 65 % opacity. Source: <https://developers.arcgis.com/documentation/esri-and-data-attribution/interactive-maps/>.
- Esri World Imagery Wayback — item `accessInformation` for every recent release (e.g. `5b7cef1b0dcc42698c1f52fb415f202c`, `089e60f6167847f8a14726009c16db66`): `"Esri, Vantor, Earthstar Geographics, and the GIS User Community"`.
- OSM — `"© OpenStreetMap contributors"`, with *OpenStreetMap* linking to `https://www.openstreetmap.org/copyright`; OSMF accepts the historical forms `© OpenStreetMap contributors` / `© OpenStreetMap` and requires the credit to be **clearly visible, in the vicinity of the map, never hidden beneath UI or off-screen**. Source: <https://operations.osmfoundation.org/policies/tiles/> and <https://wiki.osmfoundation.org/wiki/Licence/Attribution_Guidelines>.
- The OSM credit is **not** a required part of the Esri World Imagery credit (that service's provider list contains no OSM entry). Credits are therefore **per active layer**, exactly as the user asked.
- Legal, not stylistic, note recorded in the code: the Esri provider list and "Powered by Esri" are the licence text and are **not** translated; only the Italian connective wording is localized.

**E. Repository blockers that must be cleared before any green gate (all verified):**
- `lib/env.dart` declares non-optional `AZURE_KEY` and `AZURE_ID`, which are **absent from `.env`** → `dart run build_runner build` fails with `Environment variable not found for field 'azureKey'.` → `lib/env.g.dart` is never produced → `flutter analyze` reports **6 errors** in `lib/env.dart`. Removing the Azure/Bing fields (which this change does anyway) fixes the build.
- `test/widget_test.dart` imports `package:airtree_app/main.dart` and calls `MyApp`; the package is `Airtree` and the root widget is `NavigationBarApp` → **2 errors**, `flutter test` fails to compile. No test currently protects anything.
- `flutter analyze` reports **160 issues** (8 errors, the rest warnings/infos in `lib/widget.dart`, `lib/widget_other.dart`, `pubspec.yaml`).
- `flutter analyze` **rewrites the tracked** `analysis_options.yaml` (injects `analyzer.exclude`), and `flutter pub get` **rewrites the tracked** `pubspec.lock` (intl 0.20.2→0.20.3, matcher, meta 1.18.0→1.19.0, test_api, vector_math 2.2.0→2.4.4, sdk `>=3.10.0-0`→`>=3.11.0-0`). Both must be restored (`git checkout --`) before committing, or the slice diff is polluted.
- `lib/env.g.dart` is gitignored (`.gitignore:49`) and `lib/gen/fonts.gen.dart` is regenerated untracked → **never stage them**; `dart run build_runner build` must precede `flutter analyze` / `flutter test`.
- The toolchain is **not on PATH**: `export PATH=/home/alessandro/aa/pack/flutter/bin:$PATH` (Flutter 3.47.9, Dart 3.13.7) is required for every gate.
- `lat.md` is **not initialized** in this repo → no lat.md obligation.
- Stray untracked files `bt.bin`, `bt2.bin`, `cs.json`, `i1.bin`, `i2.bin`, `ti.json` exist in the repo root (another agent's probe output) → **must not be staged**.

**F. `envied` 1.3.1 API (read from the pinned package source in `~/.pub-cache/hosted/pub.dev/envied-1.3.1/`):**
- The package exports exactly **three** public symbols: `envied`, `Envied`, `EnviedField`. **There is no `@EnviedKey`, no `@EnviedSecret`, no `@EnviedKeyValue`** (`grep -rn "EnviedKey" ~/.pub-cache/hosted/pub.dev/envied-1.3.1/` → 0 hits). The user's request for `@EnviedKey('ARCGIS_LOCATION_KEY')` is therefore implemented with the only API the pinned version offers — `@EnviedField(varName: 'ARCGIS_LOCATION_KEY', obfuscate: true)` — matching the repo's existing style (`lib/env.dart:7-14`).
- `EnviedField({String? varName, bool? obfuscate, Object? defaultValue, bool? environment, bool? optional, bool? useConstantCase, bool? interpolate, bool? rawString, int? randomSeed})`.
- `obfuscate: true` ⇒ the generated field is `static final` (runtime XOR decode), **not** a compile-time constant ⇒ the Esri tile template must be built at runtime. `varName` pins the `.env` key. The `.env` path defaults to `.env` relative to the package root; `@Envied(path: '.env')` is already in place.
- Generation command: **`dart run build_runner build`** (there is no `dart run envied`; envied 1.3.1 ships no `bin/`). `flutter_gen_runner` is a separate builder in the same `dev_dependencies` and runs in the same command.

**G. flutter_map 6.2.1 API facts (quoted from the pinned package source):**
- `TileLayer.userAgentPackageName` default `'unknown'`; `tile_layer.dart:333-337` does `tileProvider.headers.putIfAbsent('User-Agent', () => 'flutter_map ($userAgentPackageName)')` — **guarded by `if (!kIsWeb)`**, and it can only ever produce `flutter_map (<pkg>)`.
- `TileProvider({Map<String, String>? headers})` and `NetworkTileProvider({super.headers, BaseClient? httpClient})`; a pre-set `User-Agent` inside the provider's `headers` **wins** over `userAgentPackageName` (that is what `putIfAbsent` means).
- `generateReplacementMap` (`base_tile_provider.dart:180-204`) provides `x`, `y`, `z`, `s`, `r`, `d`; `{row}`/`{col}` are **not** available (`additionalOptions` is static). Esri's row/col order is therefore expressed as `{z}/{y}/{x}` — no custom provider needed.
- `errorTileCallback` **exists** in 6.2.1: `typedef ErrorTileCallBack = void Function(TileImage tile, Object error, StackTrace? stackTrace);`, invoked from `_onTileLoadError` (`tile_layer.dart:702-704`) — i.e. it fires when the fetch throws or the body fails to decode. **An ArcGIS `text/plain` JSON error body fails image decoding → the callback fires.** This is the runtime hook for the quota fallback.
- `fallbackUrl` fires only on thrown/decoding failures, never on a successful-but-blocked response — irrelevant here, not used.
- `SimpleAttributionWidget` hardcodes the prefix `const Text('flutter_map | © ')` (`simple.dart:50`) → **not used**; the app renders its own label.
- `url_launcher` 6.3.2 is already a **direct** dependency (`pubspec.yaml:37`, `pubspec.lock:1221-1228`) and is currently unused → no dependency change is needed for the credit links.

### Out of scope (explicitly)

- Splitting the pre-existing over-limit files `lib/widget.dart` (1800 effective lines) and `lib/providers.dart` (746). See "Code Structure" for the named seams and the explicit deviation record; this change must **shrink** both, never grow them.
- Migrating off `tile.openstreetmap.org` to a commercial OSM tile provider, or to vector tiles / MapLibre.
- Upgrading `flutter_map` (6.2.1 → 8.x) for persistent tile caching (the OSM ≥ 7-day caching rule) — recorded as residual risk.
- Persisting `mapType` in the `UserSetting` table (it is in-memory only today, both before and after this change).

---

## Architecture

### Capability map

| Capability | Files | Responsibility |
|---|---|---|
| **map background imagery** (new) | `lib/map/raster_imagery.dart` (new), `lib/map/imagery_provider.dart` (new) | Which raster source the map draws, its tile URL template, the availability probe, and the runtime fallback state |
| **map attribution** (new) | `lib/map/attribution.dart` (new) | The tiny bottom-right credit label, dynamic per active layer, linked to the licence pages |
| **app state** | `lib/providers.dart` | Existing providers; the map-type field moves out to the imagery capability |
| **map UI** | `lib/widget.dart`, `lib/main.dart` | Hosts the `FlutterMap`, the layer switch, the map-type picker, the overlay stack |
| **configuration** | `lib/env.dart` (generated part `lib/env.g.dart`, gitignored) | envied access to `.env` |
| **localization** | `lib/l10n/app_en.arb`, `lib/l10n/app_it.arb`, `lib/src/generated/l10n/*` (generated, tracked) | ARB sources and generated localizations |
| **legal text** | `lib/privacy_terms.dart` | Terms of use; the Bing-imagery exception is replaced by the Esri one |

### Data flow

```
.env (symlink, gitignored)
  └─> dart run build_runner build
        └─> lib/env.g.dart  ──> Env.arcgisLocationKey  (static final, runtime-decoded)
              │
              ├─> ImageryProvider (ChangeNotifier, registered in lib/main.dart)
              │      ├─ probe: GET ibasemaps-api .../World_Imagery/MapServer?f=json&token=KEY
              │      │     ├─ 200 JSON  -> availability = available, copyrightText cached
              │      │     └─ anything else -> availability = unavailable -> Wayback
              │      ├─ errorTileCallback on the Esri TileLayer -> activateEsriFallback()
              │      └─ state: background (esri | openStreetMap), esriFallbackActive
              │
              └─> tile URL template (runtime string, key URL-encoded)
                     Esri primary : ibasemaps-api .../tile/{z}/{y}/{x}?token=KEY
                     Esri Wayback : wayback.maptiles.arcgis.com .../tile/43291/{z}/{y}/{x}
                     OSM          : tile.openstreetmap.org/{z}/{x}/{y}.png
                           via NetworkTileProvider(headers: {'User-Agent': 'Airtree/<ver> (...)'})

lib/widget.dart  ──> FlutterMap(children: [ EsriTileLayer | OsmTileLayer, ...overlays ])
                 └─> Stack(children: [ FlutterMap, Align(SpeedDial) ])
                       └─> Positioned(right:2, bottom:1) -> MapAttributionLabel
                             reads ImageryProvider state + AppLocalizations
                             -> RichText(credit) + tap -> url_launcher(licence URL)
```

### Dependencies and coupling

- `lib/map/*` depends on `package:flutter_map`, `package:http`, `package:url_launcher`, `package:Airtree/env.dart` and `package:Airtree/l10n/l10n.dart` — **no dependency on `lib/widget.dart`**, so the new modules are unit-testable in isolation.
- `lib/widget.dart` depends on `lib/map/*` (one-way).
- `lib/main.dart` registers the new `ChangeNotifierProvider` alongside the existing ones (`lib/main.dart:49-57`).
- `lib/providers.dart` **loses** the map-type field (net shrink); nothing else changes there.

---

## Code Structure

| Path | Responsibility | Expected effective lines |
|---|---|---|
| `lib/map/raster_imagery.dart` (new) | Esri/OSM tile URL templates, key sanitation, availability classification, the startup probe | ≈ 150 (limit 500, split threshold 550) |
| `lib/map/imagery_provider.dart` (new) | `ImageryProvider` (ChangeNotifier): active background, fallback state, probe application, attribution inputs | ≈ 130 (limit 500, split threshold 550) |
| `lib/map/attribution.dart` (new) | `MapAttributionLabel` widget: tiny bottom-right credit, per layer, tappable | ≈ 110 (limit 500, split threshold 550) |
| `lib/env.dart` (modified) | envied fields: drop `BING_KEY`/`AZURE_KEY`/`AZURE_ID`, add `ARCGIS_LOCATION_KEY` | 15 → 12 (limit 500) |
| `lib/widget.dart` (modified) | New layer construction, map-type picker, attribution overlay; delete the dead Bing classes | 1800 → ≈ 1680 (**must shrink**) |
| `lib/providers.dart` (modified) | Remove the map-type field and setter | 746 → ≈ 715 (**must shrink**) |
| `lib/main.dart` (modified) | Register `ImageryProvider` | 216 → 218 |
| `lib/l10n/app_en.arb`, `lib/l10n/app_it.arb` (modified) | Credit strings | 508 → ≈ 516; 146 → ≈ 150 (ARB is a flat resource file; under the 550 threshold) |
| `lib/src/generated/l10n/app_localizations{,_en,_it}.dart` (regenerated) | Generated getters | 198 / 322 / 325 → +≈ 15 each |
| `lib/privacy_terms.dart` (modified) | Bing-imagery exception → Esri-imagery terms | 108 → 108 |
| `test/map/raster_imagery_test.dart` (new) | URL templates, key sanitation, probe classification | ≈ 120 |
| `test/map/imagery_provider_test.dart` (new) | Provider state transitions and fallback activation | ≈ 110 |
| `test/map/attribution_test.dart` (new) | Widget test of the label per active layer | ≈ 90 |
| `test/widget_test.dart` (rewritten) | Environment contract test (replaces the broken counter test) | 14 → ≈ 25 |
| `README.md`, `AGENTS.md`, `CHANGELOG.md`, `.gitignore`, `l10n.yaml` (modified) | Setup/run/test documentation, architecture map, release notes, hygiene | exempt (docs/config) |

### Named seams and the §11 deviation record

- **Seam used in this change:** `lib/widget.dart` lines 956-1043 (`BingMapsImagerySet`, `BingMapsTileProvider`, `BingMapsTileLayer` — dead code, referenced only from the commented-out block at 1151-1158) and the background-layer block at 1134-1159 are **deleted**, and their replacement lives in the new `lib/map/` capability modules. `lib/widget.dart` therefore **shrinks**; it is not grown.
- **Pre-existing over-limit files:** `lib/widget.dart` (1800) and `lib/providers.dart` (746) are already above the 550 split threshold before this change. A full decomposition of `lib/widget.dart` is a multi-PR refactor of a 2000-line UI file, disproportionate to and risky for this defect fix; it is therefore **not** performed here. The named seams for that follow-up, recorded so it is not forgotten:
  - `lib/widget.dart` → `lib/map/map_page.dart` (`getPageList` map page, 1045-1546), `lib/panels/panels.dart` (`getPanel`/`getMapPanel`/`getInfoPanel`/`getEditPanel`, 410-932), `lib/result/result_page.dart` (`getResultPage` + dropdowns, 1569-1864), `lib/project/project_table.dart` (`ProjectTable` + status helpers, 1865-2067), `lib/geometry/geometry.dart` (`addGreen`/`updateGeometryGreen`/`doMapAction`, 146-409).
  - `lib/providers.dart` → `lib/providers/{result,global,panel,editor,map,param}_provider.dart` (each provider class is a self-contained seam).
- **Every file this change creates stays under 500 effective lines**, and no touched file grows.

---

## Implementation Tasks

Ordered by dependency. T0 is always present and always first. All build tasks are executed by the **build agent** (switch with Tab); the planner never edits source.

### Common pre-flight for every build task (T1-T4)

```sh
cd /home/alessandro/aa/git/ring/modeling/airtree/app
export PATH=/home/alessandro/aa/pack/flutter/bin:$PATH
git status --porcelain          # must be empty apart from the known stray files
dart run build_runner build --delete-conflicting-outputs   # regenerates lib/env.g.dart (gitignored)
```
- `lib/env.g.dart` and `lib/gen/fonts.gen.dart` are **never staged**. Stage files by explicit path only — never `git add -A`.
- After every `flutter analyze` / `flutter pub get`, restore the tracked files those tools mutate:
  `git checkout -- analysis_options.yaml pubspec.lock`
- Do **not** commit `.env`, `lib/env.g.dart`, or any `*.bin` / `*.json` probe file left in the repo root.

---

### T0: Write SPEC.md to disk (MANDATORY first task)

- **Files**: `<project_root>/SPEC.md`
- **Classification**: INDEPENDENT (doc-only)
- **Parallel-OK**: T1, T2, T3, T4 (no file overlap)
- **Slice count**: 5 total slices (T0 + T1-T4) — the fewest that keeps each micro-increment whole. See the rationale under T1.
- **Business logic**: Capture this executive execution spec as a tracked, versioned artifact.
- **Code**: the full content of this SPEC.md (the planner pastes the spec body into the T0 brief).
- **Test**: none (doc slice — exempt from the code+test+integration rule).
- **Integration**: none.
- **README**: none (SPEC.md is not a README section).
- **.gitignore**: none (SPEC.md is tracked, not ignored).
- **Decisions**: The spec is structured as Context → Architecture → Code Structure → Implementation Tasks → Graph Context → Edge Cases → References so a build agent can execute any task without re-reading the repository.
- **Acceptance**: SPEC.md exists at `<project_root>/SPEC.md` and is committed; markdown is well-formed.
- **Commit**: `docs: add SPEC.md execution spec for Esri imagery background and map attribution` + Summary + Decisions + per-file Files entry.

---

### T1: Esri World Imagery background with Wayback fallback

- **Files**: `lib/map/raster_imagery.dart` (new), `lib/map/imagery_provider.dart` (new), `lib/env.dart` (modified), `lib/main.dart` (modified), `lib/widget.dart` (modified), `lib/providers.dart` (modified), `test/map/raster_imagery_test.dart` (new), `test/map/imagery_provider_test.dart` (new), `test/widget_test.dart` (rewritten), `README.md` (modified)
- **Classification**: CONTENDED — shares `lib/widget.dart` with T2 and T3, and `README.md` with T4
- **Parallel-OK**: none (T2, T3, T4 all touch `lib/widget.dart`)
- **Slice count**: 5 total planned slices — the fewest that keeps each micro-increment whole. Each slice costs a worktree, a merge and a worker round trip, so the three defects (OSM 403, Esri imagery, attribution) are split by defect, but the ESRI imagery slice and the attribution slice both touch the map background block of `lib/widget.dart` and cannot be committed independently without a conflict-prone partial-file state, so they stay sequential. T4 (hygiene/docs) touches disjoint files and is the only candidate for parallelism, but it is a single trivial slice whose round trip is not worth a worktree.
- **Business logic**: The map's raster background is Esri World Imagery, requested with the `ARCGIS_LOCATION_KEY` from `.env`; when the Esri service cannot serve that key (missing, invalid, disabled, quota-exhausted, unreachable), the map falls back to Esri World Imagery Wayback instead of showing a blank or broken background.
- **Code**:

  **`lib/env.dart`** — rewrite the field block. `@EnviedKey` does not exist in envied 1.3.1 (the package exports only `envied`, `Envied`, `EnviedField`), so the request is implemented with the repo's existing idiom. `BING_KEY`, `AZURE_KEY`, `AZURE_ID` are removed: `azureKey` is the reason `dart run build_runner build` currently fails (`Environment variable not found for field 'azureKey'.` — `AZURE_KEY`/`AZURE_ID` are absent from `.env`), and `bingKey`/`azureID` have no remaining consumer once the Bing classes are deleted.

  ```dart
  import 'package:envied/envied.dart';

  part 'env.g.dart';

  /// Environment-backed configuration for the application.
  ///
  /// Values are read from the `.env` file at the package root by `envied`
  /// (see `dart run build_runner build`). The generated part file
  /// `lib/env.g.dart` is git-ignored and must never be committed.
  @Envied(path: '.env')
  abstract class Env {
    /// Base URL of the Airtree backend API.
    @EnviedField(varName: 'ADRESS_HOME', obfuscate: true)
    static final String adressHome = _Env.adressHome;

    /// API key for the Airtree backend API.
    @EnviedField(varName: 'AIRTREE_KEY', obfuscate: true)
    static final String airtreeKey = _Env.airtreeKey;

    /// ArcGIS Location Platform API key used for Esri basemap access.
    ///
    /// The value is an ArcGIS Location Platform API key (not a JWT and not a
    /// portal token). It is sent to ArcGIS as the `token` query parameter of
    /// the basemap tile endpoints; `apiKey=` is rejected with error 499.
    @EnviedField(varName: 'ARCGIS_LOCATION_KEY', obfuscate: true)
    static final String arcgisLocationKey = _Env.arcgisLocationKey;
  }
  ```

  **`lib/map/raster_imagery.dart`** (new) — the imagery capability. Public surface:

  ```dart
  import 'dart:convert';
  import 'package:http/http.dart' as http;

  /// Host serving the current Esri World Imagery raster tiles.
  const String kEsriImageryHost = 'ibasemaps-api.arcgis.com';

  /// Path of the Esri World Imagery raster MapServer.
  const String kEsriImageryServicePath =
      '/arcgis/rest/services/World_Imagery/MapServer';

  /// Path segment of the pinned Esri World Imagery Wayback release.
  ///
  /// `43291` is `World Imagery (Wayback 2026-10-29)` (layer `WB_2026_R10`).
  /// The Wayback service answers with a 301 redirect to the release that owns
  /// the requested tile at the requested zoom; `package:http` follows it.
  const String kEsriWaybackReleaseId = '43291';

  /// Host serving Esri World Imagery Wayback releases.
  const String kEsriWaybackHost = 'wayback.maptiles.arcgis.com';

  /// Esri World Imagery is served up to zoom 19; beyond that the service
  /// returns a blank grey image.
  const int kEsriImageryMaxNativeZoom = 19;

  /// Native zoom limit of the OpenStreetMap standard raster tiles.
  const int kOsmMaxNativeZoom = 19;

  /// Removes surrounding whitespace and one layer of double quotes from a key.
  ///
  /// `envied` already unquotes `.env` values, but the secret store may hold the
  /// key in quotes; ArcGIS rejects a quoted token with error 498.
  String sanitizeApiKey(String raw) {
    var value = raw.trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1).trim();
    }
    return value;
  }

  /// Tile URL template of the key-bearing Esri World Imagery layer.
  ///
  /// The ArcGIS REST path order is `{z}/{row}/{col}`; in flutter_map terms the
  /// row is `y` and the column is `x`, so the template is `{z}/{y}/{x}`.
  /// Returns `null` when no usable key is configured.
  String? esriWorldImageryTileTemplate(String apiKey) {
    final key = sanitizeApiKey(apiKey);
    if (key.isEmpty) return null;
    return 'https://$kEsriImageryHost$kEsriImageryServicePath/tile/{z}/{y}/{x}'
        '?token=${Uri.encodeQueryComponent(key)}';
  }

  /// Tile URL template of the Esri World Imagery Wayback fallback layer.
  String esriWaybackTileTemplate() =>
      'https://$kEsriWaybackHost/arcgis/rest/services/World_Imagery/MapServer'
      '/tile/$kEsriWaybackReleaseId/{z}/{y}/{x}';

  /// OpenStreetMap standard raster tile URL template.
  const String osmTileTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// User-Agent sent with every raster tile request.
  ///
  /// OpenStreetMap blocks the flutter_map default UA and the example package
  /// identifier; the policy requires a distinct, stable UA naming the app and
  /// optionally a contact URL.
  const String osmUserAgent =
      'Airtree/1.0.7 (it.alivernini.airtree; '
      'https://github.com/aalivernini/airtree_app)';

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
    const ImageryProbeResult({
      required this.availability,
      this.copyrightText = '',
      this.statusCode,
    });
    final ImageryAvailability availability;
    final String copyrightText;
    final int? statusCode;
  }

  /// Classifies an Esri metadata response.
  ///
  /// ArcGIS answers token problems with HTTP 200 and a `text/plain` JSON body
  /// (`{"error":{"code":499,...}}`), so the body has to be inspected; Esri
  /// publishes no "quota exceeded" code, so every non-image, non-200 outcome
  /// is treated as "primary unavailable".
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
    if (contentType.contains('json') || body.trimLeft().startsWith('{')) {
      // ArcGIS error envelope: 498 invalid token, 499 token required.
      if (body.contains('"code":498') || body.contains('"code":499')) {
        return ImageryAvailability.unauthorized;
      }
      return ImageryAvailability.unavailable;
    }
    return ImageryAvailability.available;
  }

  /// Probes the Esri imagery endpoint and reports whether it can be used.
  ///
  /// The probe also returns the service `copyrightText`, which is the
  /// authoritative attribution string for the layer in use.
  Future<ImageryProbeResult> probeEsriImagery(
    String apiKey, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) async { /* GET metadata URL, classify, extract copyrightText */ }
  ```

  **`lib/map/imagery_provider.dart`** (new) — `class ImageryProvider extends ChangeNotifier` owning:
  - `enum MapBackground { esri, openStreetMap }` (the map-type model moves out of `GlobalProvider`).
  - `MapBackground get background` / `void selectBackground(MapBackground)`.
  - `bool get esriFallbackActive` — true once the Wayback layer is in use.
  - `ImageryAvailability get availability` and `String get esriCopyrightText`.
  - `void applyProbeResult(ImageryProbeResult)` — sets availability; when the result is not `available`, calls `activateEsriFallback()`.
  - `void activateEsriFallback()` — flips `esriFallbackActive` to true exactly once (idempotent, never flips back) and calls `notifyListeners()`.
  - `void activateEsriFallbackOnTileError(Object error)` — the `errorTileCallback` entry point; ignores errors raised while the OSM layer is active or while the fallback is already active.
  - `String get esriTileTemplate` — the primary template when healthy, the Wayback template when the fallback is active, `null` when no key is configured and the fallback is inactive.
  - `Future<void> refreshAvailability({http.Client? client})` — runs `probeEsriImagery` and applies the result; never throws.
  Every public member carries a doc comment stating the contract.

  **`lib/widget.dart`** — changes:
  1. Delete `BingMapsImagerySet` (956-972), `BingMapsTileProvider` (975-1005), `BingMapsTileLayer` (1008-1048) and the commented-out usage block (1151-1158). Remove the imports that become unused (`dart:convert` / `package:http` if they are only used by the deleted code — verify with `flutter analyze`; `flutter_lints` flags unused imports as errors).
  2. Replace the background-layer block (1134-1159) with a single call that selects the layer from `ImageryProvider`:
     - ESRI primary → `TileLayer(urlTemplate: provider.esriTileTemplate, maxNativeZoom: kEsriImageryMaxNativeZoom, maxZoom: 21, errorTileCallback: (tile, error, stackTrace) => provider.activateEsriFallbackOnTileError(error))`
     - ESRI fallback (Wayback) → `TileLayer(urlTemplate: esriWaybackTileTemplate(), maxNativeZoom: kEsriImageryMaxNativeZoom, maxZoom: 21)`
     - OSM → `TileLayer(urlTemplate: osmTileTemplate, tileProvider: NetworkTileProvider(headers: {'User-Agent': osmUserAgent}), maxNativeZoom: kOsmMaxNativeZoom, maxZoom: 30)`
     The layer must be rebuilt when `ImageryProvider` notifies; wrap the existing `Consumer2<pr.EditorProvider, pr.GlobalProvider>` in an outer `Consumer<ImageryProvider>` (or add it to the existing consumer) so a fallback switch repaints the map.
  3. `getMapPanel` (423-463): replace the three hardcoded "OpenStreetMap" / "Bing satellite" / "Bing hybrid" buttons with two buttons — "Esri World Imagery" → `provider.selectBackground(MapBackground.esri)`, "OpenStreetMap" → `provider.selectBackground(MapBackground.openStreetMap)`. Keep the existing `IconButton` + `Text` visual style.
  4. The `MapOptions.center` deprecation warning at 1127 (`'center' is deprecated ... Prefer initialCenter'`) is pre-existing; leave it alone (do not mix an unrelated migration into this slice).
  5. The map page must trigger `refreshAvailability()` once when it is first built (the probe is asynchronous; the primary layer is used until the probe reports otherwise).

  **`lib/providers.dart`** — remove `_mapType`, `mapType`, `setMapType` (365-366, 380-395) and the now-unused `mapType` references; `GlobalProvider` loses ~31 effective lines. `lib/providers.dart` must **shrink** (746 → ≈ 715).

  **`lib/main.dart`** — register the new provider in the `providers:` list of the outer `MultiProvider` (after line 56): `ChangeNotifierProvider(create: (context) => pr_ImageryProvider())` — imported as `import 'package:Airtree/map/imagery_provider.dart';` (use the repo's `package:Airtree/...` import form).

  **`test/map/raster_imagery_test.dart`** — unit tests for `sanitizeApiKey` (quoted, unquoted, whitespace-only, empty), `esriWorldImageryTileTemplate` (null for empty key; contains `?token=`, contains `{z}/{y}/{x}` in that order; key is URL-encoded), `esriWaybackTileTemplate` (contains `43291` and `{z}/{y}/{x}`), `classifyImageryResponse` (200 + JSON 499 → unauthorized; 200 + JSON 498 → unauthorized; 200 + JSON without code → unavailable; 401 → unauthorized; 403 → unauthorized; 500 → unavailable; 200 + JSON service document with `copyrightText` → available; 200 + `text/plain` non-JSON → unavailable), and `probeEsriImagery` against an injected `http.Client` returning a canned response (use `package:http`'s `MockClient` from `package:http/testing.dart`).

  **`test/map/imagery_provider_test.dart`** — provider state tests: default background is Esri; `selectBackground` notifies; `applyProbeResult(unavailable)` activates the fallback and switches `esriTileTemplate` to the Wayback template; `activateEsriFallbackOnTileError` activates the fallback only when the Esri layer is active and only once; `esriTileTemplate` is `null` with no key and no fallback.

  **`test/widget_test.dart`** — replace the broken counter test with the environment contract test:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:Airtree/env.dart';

  void main() {
    test('ArcGIS location key is configured and unquoted', () {
      // Never print the value itself: assert on booleans only.
      expect(Env.arcgisLocationKey.isNotEmpty, isTrue);
      expect(Env.arcgisLocationKey.trim().startsWith('"'), isFalse);
      expect(Env.arcgisLocationKey.trim().endsWith('"'), isFalse);
    });
  }
  ```

  **`README.md`** — in the setup section: replace the `BING_KEY` template block with `ARCGIS_LOCATION_KEY` (ArcGIS Location Platform API key, sent as the `token` parameter; the value must be stored **without** surrounding quotes — a quoted value is rejected with error 498), keep `ADRESS_HOME` and `AIRTREE_KEY`; add a "Run tests" section (currently missing — the file has Description, Platforms, Install-from-source-code, Run, but **no test section**) documenting `dart run build_runner build --delete-conflicting-outputs` (mandatory first, `lib/env.g.dart` is generated and git-ignored) then `flutter test`; add a "Smoke run" section describing the canonical smoke command.

- **Test**: the three test files listed above. `flutter test` must pass with **zero** failures and zero compile errors.
- **Integration**: `lib/main.dart` registers `ImageryProvider`; `lib/widget.dart` selects the tile layer from the provider and starts the probe; `lib/providers.dart` no longer owns the map type.
- **README**: update the setup section (`.env` template) and **create** the missing "Run tests" and "Smoke run" sections.
- **.gitignore**: none needed in this slice (no new binary/secret/artifact pattern is introduced; `lib/env.g.dart` is already ignored at `.gitignore:49` and `*.env` at `:47`).
- **Decisions**:
  - *General*: the map type becomes an enum owned by the imagery capability instead of an `int` on `GlobalProvider`, so the map background, its availability and its fallback live in one place and the type cannot drift from the state that renders it.
  - *General*: Esri tile URLs use `{z}/{y}/{x}` because the ArcGIS REST path is `{z}/{row}/{col}` and flutter_map's `generateReplacementMap` provides no `{row}`/`{col}`.
  - *General*: the Wayback release id is pinned to `43291` (`World Imagery (Wayback 2026-10-29)`); the service's 301 to the owning release is followed by `package:http` automatically, so a pinned id stays valid as the archive grows.
  - *General*: the availability probe is a metadata request, not a tile request, because it returns the authoritative `copyrightText` in the same round trip.
  - *General*: the fallback is one-way (never flips back within a session) so a flapping service cannot thrash the map.
  - *lib/env.dart*: `@EnviedField(varName: 'ARCGIS_LOCATION_KEY', obfuscate: true)` — envied 1.3.1 has no `@EnviedKey`; `obfuscate` keeps the value out of the binary in clear text but the field stays `static final`, so every use site builds the URL at runtime.
  - *lib/env.dart*: the Azure/Bing fields are deleted rather than made optional — they are the reason code generation fails today, and nothing consumes them after this change.
  - *lib/map/raster_imagery.dart*: a sanitiser strips quotes defensively even though `envied` already unquotes, because the ArcGIS rejection (498) is silent at the tile endpoint.
  - *lib/widget.dart*: the OSM layer gets an explicit `NetworkTileProvider` with a compliant `User-Agent`; `userAgentPackageName` alone can only produce `flutter_map (<pkg>)` and is never used for the OSM layer.
  - *lib/providers.dart*: the map-type field is removed rather than duplicated, so there is exactly one source of truth for the active background.
- **Acceptance**:
  - `dart run build_runner build --delete-conflicting-outputs` exits 0 (the pre-existing `Environment variable not found for field 'azureKey'.` error is gone) and `lib/env.g.dart` contains `arcgisLocationKey`.
  - `flutter analyze` reports **no error-level issues** (the 6 `lib/env.dart` errors and the 2 `test/widget_test.dart` errors are resolved) and **no new warning-level issue** relative to the 160-issue baseline minus the resolved errors.
  - `flutter test` exits 0 with all tests passing.
  - Smoke run (§7) green: the canonical smoke command is
    `export PATH=/home/alessandro/aa/pack/flutter/bin:$PATH && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test && flutter build bundle`
    `flutter build bundle` is the whole-program compile gate (it compiles every Dart file, including the generated `lib/env.g.dart`, without needing a platform toolchain). If `flutter build bundle` is unavailable in the environment, fall back in this order: `flutter build apk --debug`, then `flutter build web --release`; if all three are unavailable, report `TOOLCHAIN ABSENT: <cmd> not available; fallback: flutter analyze + flutter test exit 0` — never claim a runtime success that did not happen.
  - The §7 report is pasted verbatim with all six sections (`=== TYPECHECK ===`, `=== LINT ===`, `=== TESTS ===`, `=== SMOKE ===`, `=== GIT STATUS ===`, `=== DIFF STAT ===`) plus the `=== EFFECTIVE LINES ===` block, one `EFFECTIVE-LINES: <path> = <n> (limit 500, split threshold 550)` line per touched source file.
  - The `=== EFFECTIVE LINES ===` block shows `lib/widget.dart` and `lib/providers.dart` **smaller** than their pre-change values (1800 and 746) and every new file below 500.
  - No file in the slice exceeds the 550 split threshold.
  - `codebase-memory-mcp_query_graph` with `MATCH (f:Function) WHERE f.is_test = true AND f.name =~ '.*esri.*' RETURN f.file_path AS file, f.name AS name` returns at least one test — the graph has no `TESTS` edge, so test identity is the `is_test` property.
  - Every added or changed function, method, class and module carries a docstring/doc comment, public and private alike, and **no SPEC slice reference appears inside any docstring**.
  - `git status` shows no staged `.env`, `lib/env.g.dart`, `*.bin`, or other artifact; `git checkout -- analysis_options.yaml pubspec.lock` has been applied if those tools mutated them.
- **Commit**:
  ```
  feat: use Esri World Imagery as map background with Wayback fallback

  Summary: The satellite background used the Azure/Bing tile endpoint with a
  key that is no longer provisioned, and the build could not even generate the
  envied part file because the Azure variables are missing from .env. The map
  background is now Esri World Imagery requested with the ARCGIS_LOCATION_KEY
  already present in .env, and it degrades to Esri World Imagery Wayback when
  the service cannot serve that key.

  Decisions:
  - The map type becomes an enum owned by the new map imagery capability
    instead of an int on GlobalProvider, so the background, its availability
    and its fallback state share one source of truth.
  - Esri tile templates use {z}/{y}/{x} because the ArcGIS REST path order is
    {z}/{row}/{col} and flutter_map provides no {row}/{col} placeholders.
  - The Wayback fallback pins release 43291 (Wayback 2026-10-29); the service
    answers with a 301 to the release owning the tile and package:http follows
    it automatically.
  - Availability is probed on the Esri metadata endpoint, which returns the
    authoritative copyrightText in the same round trip; the fallback is
    one-way so a flapping service cannot thrash the map.
  - The Azure and Bing envied fields are deleted rather than made optional:
    they are the reason code generation fails today and nothing consumes them.

  Files:
  - lib/env.dart: expose ARCGIS_LOCATION_KEY through envied and drop the
    unused BING_KEY/AZURE_KEY/AZURE_ID fields that break code generation.
  - lib/map/raster_imagery.dart: Esri/OSM tile URL templates, key sanitation,
    availability classification and the startup probe for the imagery service.
  - lib/map/imagery_provider.dart: ImageryProvider change notifier holding the
    active background, the probe result and the Wayback fallback state.
  - lib/main.dart: register ImageryProvider in the provider list.
  - lib/widget.dart: build the tile layer from ImageryProvider, delete the
    dead Bing tile classes and their commented-out usage, and reduce the
    map-type picker to Esri World Imagery and OpenStreetMap.
  - lib/providers.dart: remove the map-type field and setter now owned by the
    imagery capability.
  - test/map/raster_imagery_test.dart: unit tests for the URL templates, key
    sanitation and the response classifier.
  - test/map/imagery_provider_test.dart: tests for the provider state machine
    and the fallback activation.
  - test/widget_test.dart: replace the broken counter test with the
    environment contract test.
  - README.md: document ARCGIS_LOCATION_KEY, the missing test section and the
    canonical smoke command.
  ```

---

### T2: Compliant OpenStreetMap User-Agent

- **Files**: `lib/map/raster_imagery.dart` (modified — the UA constant is defined in T1 and applied here), `lib/widget.dart` (modified), `test/map/raster_imagery_test.dart` (modified)
- **Classification**: CONTENDED — shares `lib/widget.dart` with T1 and T3
- **Parallel-OK**: none
- **Slice count**: 5 total (see T1).
- **Business logic**: The OpenStreetMap background stops receiving the blocked "403 Access blocked" tile by sending a policy-compliant User-Agent that identifies the app and its contact URL.
- **Code**:
  - The OSM `TileLayer` is constructed with `tileProvider: NetworkTileProvider(headers: {'User-Agent': osmUserAgent})` and **no** `userAgentPackageName` for that layer. flutter_map's `tile_layer.dart:333-337` uses `putIfAbsent`, so a pre-set `User-Agent` in the provider headers wins over the library default `flutter_map (<pkg>)`.
  - The URL stays `https://tile.openstreetmap.org/{z}/{x}/{y}.png` over **https** — never `http://`, because `dart:io` replaces the User-Agent with `Dart/x.y (dart:io)` on a redirect and that exact string is on OSM's denylist.
  - `maxNativeZoom` for the OSM layer is `kOsmMaxNativeZoom` (19): OSM serves z0-19 and answers z=20 with HTTP 400 `You requested an invalid tile.`, which would otherwise raise a tile error.
  - `osmUserAgent` value: `Airtree/1.0.7 (it.alivernini.airtree; https://github.com/aalivernini/airtree_app)` — app name + version + bundle id + contact URL, as required by the OSMF tile usage policy §3.1. It is a `const` in `lib/map/raster_imagery.dart`; when the app version in `pubspec.yaml` is bumped, this constant must be bumped in the same commit.
- **Test**: in `test/map/raster_imagery_test.dart` — assert the UA constant starts with `Airtree/`, contains the bundle id `it.alivernini.airtree`, contains the contact URL `https://github.com/aalivernini/airtree_app`, does **not** contain `flutter_map`, does not contain `dev.fleaflet`, and does not contain `com.example`. The policy check is a pure string assertion, so it needs no network.
- **Integration**: the OSM branch of the layer selection in `lib/widget.dart` passes the compliant provider.
- **README**: none (the setup/run/test execution does not change).
- **.gitignore**: none.
- **Decisions**:
  - *General*: the UA is overridden at the `NetworkTileProvider` level rather than through `userAgentPackageName`, because the latter can only produce `flutter_map (<pkg>)` and both `flutter_map (unknown)` and `flutter_map (dev.fleaflet.flutter_map.example)` are on the OSM denylist.
  - *General*: OSM's block is delivered as HTTP 200 with an `x-blocked` header and a valid PNG, so no status-code check would ever detect it — the only reliable fix is the UA itself.
  - *lib/widget.dart*: the OSM layer keeps `maxNativeZoom: 19` so that z=20 400 responses cannot raise tile errors.
- **Acceptance**: same §7 report and §10 checklist as T1, with the smoke run green; `flutter analyze` free of new warnings; the `=== EFFECTIVE LINES ===` block present and every touched file below 550; the UA assertion tests pass; no SPEC reference in any docstring.
- **Commit**:
  ```
  fix: send a policy compliant User-Agent to OpenStreetMap

  Summary: The OpenStreetMap background was requested with the flutter_map
  example package identifier, which OpenStreetMap blocks, so every tile
  rendered the "403 Access blocked" image while still answering HTTP 200. The
  layer now identifies the application and its contact URL, as the tile usage
  policy requires.

  Decisions:
  - The User-Agent is set on the NetworkTileProvider because
    userAgentPackageName can only ever produce "flutter_map (<pkg>)" and
    both the library default and the example identifier are blocked.
  - The tile URL stays on https: a redirect makes dart:io replace the
    User-Agent with its own default, which is blocked as well.
  - The OSM native zoom limit is 19 because zoom 20 answers HTTP 400.

  Files:
  - lib/map/raster_imagery.dart: define the compliant User-Agent constant
    and the OpenStreetMap native zoom limit.
  - lib/widget.dart: give the OpenStreetMap layer a provider carrying the
    compliant User-Agent.
  - test/map/raster_imagery_test.dart: assert the User-Agent identifies the
    app and no longer carries a blocked flutter_map or example identifier.
  ```

---

### T3: Attribution label (dynamic per layer, localized)

- **Files**: `lib/map/attribution.dart` (new), `lib/l10n/app_en.arb` (modified), `lib/l10n/app_it.arb` (modified), `lib/src/generated/l10n/app_localizations.dart` (regenerated), `lib/src/generated/l10n/app_localizations_en.dart` (regenerated), `lib/src/generated/l10n/app_localizations_it.dart` (regenerated), `lib/widget.dart` (modified), `test/map/attribution_test.dart` (new)
- **Classification**: CONTENDED — shares `lib/widget.dart` with T1 and T2, and the ARB files with T4 (no overlap in practice)
- **Parallel-OK**: none
- **Slice count**: 5 total (see T1).
- **Business logic**: The map always shows, at its bottom-right corner, a small credit for the imagery actually in use — the Esri credit while Esri World Imagery (or its Wayback fallback) is active, and the OpenStreetMap credit while the OSM background is active — with the provider names and licence links required by both licences.
- **Code**:

  **ARB keys** (en file gets a `@key` description block, it file does not — the it file carries no `@` metadata today):

  | key | en | it |
  |---|---|---|
  | `attributionEsriPowered` | `Powered by Esri` | `Powered by Esri` |
  | `attributionEsriSources` | `Source: Esri, Vantor, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community` | `Fonte: Esri, Vantor, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN e la comunita utenti GIS` |
  | `attributionEsriWaybackSources` | `Source: Esri, Vantor, Earthstar Geographics, and the GIS User Community` | `Fonte: Esri, Vantor, Earthstar Geographics e la comunita utenti GIS` |
  | `attributionOsm` | `© OpenStreetMap contributors` | `© OpenStreetMap contributors` |

  Legal notes to record in the code comments and in this table:
  - `Powered by Esri` is **mandated verbatim by Esri** and is therefore identical in both locales.
  - `© OpenStreetMap contributors` is one of the two forms accepted by the OSMF attribution guidelines; it is **not** translated, because a translated form is not an accepted form.
  - The Esri provider list is Esri's `copyrightText` fetched live from the service on 2026-11-11; Esri states attribution can change and must be reviewed periodically — record the source URL in the doc comment.
  - The Wayback provider list is the `accessInformation` of the Wayback release items.

  **Generated localizations**: regenerate with `flutter gen-l10n` (verified to work on this repo: exit 0, and it rewrites the three tracked files under `lib/src/generated/l10n/`). The four new getters must appear in `app_localizations.dart` (abstract), `app_localizations_en.dart` and `app_localizations_it.dart`. If `flutter gen-l10n` cannot run, hand-edit the three files following the existing generated pattern exactly (`String get attributionEsriPowered;` in the abstract class; `String get attributionEsriPowered => '...';` in the `_en` / `_it` implementations) — and say so in the report.

  **`lib/map/attribution.dart`** (new) — `class MapAttributionLabel extends StatelessWidget`:
  - Reads `ImageryProvider` (via `context.watch`) to know the active background and whether the Wayback fallback is active, and `AppLocalizations.of(context)` for the strings.
  - Renders a `Text.rich` with: the Esri variant = `attributionEsriPowered` + `" | "` + (the provider's runtime `esriCopyrightText` when available, else `attributionEsriSources`; when the Wayback fallback is active, `attributionEsriWaybackSources`); the OSM variant = `attributionOsm`.
  - Style: `fontSize: 8.0`, `color: Color(0xFF323232)`, background `Color(0xFFFFFF).withOpacity(0.65)` (Esri's recommended colours), `padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1)`, `textAlign: TextAlign.right`, `maxLines: 2`.
  - The whole label is tappable: `GestureDetector` → `launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)` with `url_launcher` — `https://www.esri.com` for the Esri variant, `https://www.openstreetmap.org/copyright` for the OSM variant. `url_launcher` is already a direct dependency (`pubspec.yaml:37`).
  - The label must be **unobstructed**: it is placed at the very bottom edge of the map so it never collides with the speed dial, whose `Align` has a 20 px bottom margin (`lib/widget.dart:1506-1515`).

  **`lib/widget.dart`** — inside the map `Stack` (`lib/widget.dart:1503-1516`), add a third child:
  ```dart
  Positioned(
    right: 2,
    bottom: 1,
    child: const MapAttributionLabel(),
  ),
  ```
  placed **after** the speed-dial `Align` so the credit is drawn on top and stays legible. Do not change the speed dial's geometry.

  **`test/map/attribution_test.dart`** — widget tests: with the ESRI background active the rendered text contains `Powered by Esri` and `Esri`; with the OSM background active it contains `OpenStreetMap contributors` and does **not** contain `Powered by Esri`; with the Wayback fallback active it contains `Esri, Vantor, Earthstar Geographics`; the label is positioned at the bottom-right of its parent.
- **Test**: `test/map/attribution_test.dart` as described; the existing suite stays green.
- **Integration**: the `Positioned` child in the map `Stack` in `lib/widget.dart`.
- **README**: none (no setup/run/test change).
- **.gitignore**: none.
- **Decisions**:
  - *General*: the credit is rendered by the app rather than by flutter_map's `SimpleAttributionWidget`, because that widget hardcodes the prefix `flutter_map | © ` and cannot carry a per-layer, localized, tappable string.
  - *General*: the label is 8 px — the user asked for a very small label; Esri's own guidance recommends 12 px, so the size is a single named constant (`kAttributionFontSize`) and is the one-line change if the stricter recommendation must be met. This deviation is deliberate and recorded here and in the code comment.
  - *General*: the label sits at the bottom edge of the map stack rather than in a corner reserved for it, because the speed dial already occupies the bottom-right corner with a 20 px inset; the credit stays below it and is never covered, as both licences require.
  - *ARB*: the provider names and `Powered by Esri` are never translated — they are the licence text, not UI copy; only the Italian connective wording is localized.
  - *ARB*: the Esri provider list is a static fallback; when the imagery provider holds a live `copyrightText` from the service, that value wins, so a credit change upstream is picked up without a release.
- **Acceptance**: same §7 report and §10 checklist as T1, with the smoke run green; `flutter gen-l10n` output committed and consistent with the ARB files; the attribution widget tests pass; the `=== EFFECTIVE LINES ===` block shows `lib/map/attribution.dart` below 500 and `lib/widget.dart` smaller than 1800; no SPEC reference in any docstring.
- **Commit**:
  ```
  feat: show the imagery attribution at the bottom right of the map

  Summary: The app displayed OpenStreetMap and Esri imagery without any
  visible credit, which both the OpenStreetMap tile usage policy and the
  Esri attribution requirements forbid. The map now always shows a small
  bottom-right label with the credit of the imagery in use, localized through
  the ARB files.

  Decisions:
  - The label is rendered by the app instead of flutter_map's
    SimpleAttributionWidget, which hardcodes a "flutter_map |" prefix and
    cannot carry a per-layer localized string.
  - The credit lists the providers Esri publishes for the service in use and
    links to esri.com; the OpenStreetMap credit links to the copyright page.
  - Licence text is not translated: "Powered by Esri" and the OpenStreetMap
    contributor form are kept verbatim in both locales.
  - The label is anchored to the bottom edge of the map so the speed dial,
    which already occupies the bottom-right corner, can never cover it.

  Files:
  - lib/map/attribution.dart: the bottom-right credit label, per active layer,
    with the licence links.
  - lib/l10n/app_en.arb: English credit strings.
  - lib/l10n/app_it.arb: Italian credit strings.
  - lib/src/generated/l10n/app_localizations.dart: regenerated getters.
  - lib/src/generated/l10n/app_localizations_en.dart: regenerated English values.
  - lib/src/generated/l10n/app_localizations_it.dart: regenerated Italian values.
  - lib/widget.dart: anchor the attribution label to the map stack.
  - test/map/attribution_test.dart: tests for the per-layer credit text.
  ```

---

### T4: Repository hygiene and documentation

- **Files**: `.gitignore` (modified), `README.md` (modified if not already complete in T1), `AGENTS.md` (modified), `CHANGELOG.md` (modified), `l10n.yaml` (modified), `lib/privacy_terms.dart` (modified), `pubspec.yaml.bak` (deleted from the index), `lib/build/.last_build_id` (deleted from the index)
- **Classification**: INDEPENDENT of the map code — disjoint file set
- **Parallel-OK**: T1, T2, T3 (disjoint files; this slice may run in parallel with the code slices, but it is a single trivial slice and is sequenced last so the docs describe the final state)
- **Slice count**: 5 total (see T1).
- **Business logic**: The repository stops tracking build artifacts, the licence text stops referring to retired Bing imagery, and the documentation describes the new imagery setup, the generated-file workflow and the test/smoke commands.
- **Code**:
  - `.gitignore`: add `*.bak` and `lib/build/` (the tracked artifacts `pubspec.yaml.bak` and `lib/build/.last_build_id` are removed from the index with `git rm --cached`). Existing coverage is otherwise complete: binaries (`*.class`, `*.log`, `*.pyc`, `/build/`, `/android/app/debug|profile|release`), secrets (`*.env`, `.env.`), artifacts (`.dart_tool/`, `.packages`, `.flutter-plugins*`).
  - `l10n.yaml`: change `arb-dir: lib\l10n` to `arb-dir: lib/l10n` (Windows separators in a Linux CI path).
  - `lib/privacy_terms.dart` (lines 30 and 93): replace the "immagini di Microsoft Bing" exception with the Esri World Imagery exception, citing the Esri terms (<https://www.esri.com/en-us/legal/terms>) and the Esri World Imagery item.
  - `README.md`: ensure the five required sections exist — Description, Purpose/use, Setup, Run, **Run tests** — plus the Smoke-run section created in T1; document that `dart run build_runner build --delete-conflicting-outputs` must run before any build because `lib/env.g.dart` is generated and git-ignored.
  - `AGENTS.md`: add `lib/map/` to the architecture map, replace the stale toolchain line (`Flutter 3.44.4 / Dart 3.12.2`) with the installed `Flutter 3.47.9 / Dart 3.13.7`, and document the `ARCGIS_LOCATION_KEY` requirement and the attribution obligation.
  - `CHANGELOG.md`: add an entry for the imagery switch, the OSM User-Agent fix and the attribution label.
- **Test**: none beyond the existing suite (must stay green).
- **Integration**: none.
- **README**: create/refresh the missing sections (see above).
- **.gitignore**: add `*.bak` and `lib/build/`.
- **Decisions**:
  - *General*: the tracked backup and build-id files are untracked rather than deleted from disk, so a developer's local build cache survives.
  - *General*: the Bing imagery exception in the terms of use must change in the same change that stops serving Bing imagery — the terms would otherwise reference imagery the app no longer uses.
  - *l10n.yaml*: forward slashes keep `flutter gen-l10n` reproducible on Linux CI.
- **Acceptance**: `flutter analyze` and `flutter test` stay green; `git ls-files` no longer lists `pubspec.yaml.bak` or `lib/build/.last_build_id`; the §7 report is pasted with all six sections and the `=== EFFECTIVE LINES ===` block (docs/config files are exempt: `EFFECTIVE-LINES: n/a (exempt: <path>)`); `git status` shows no secret and no artifact staged.
- **Commit**:
  ```
  chore: update repository hygiene and documentation for the imagery switch

  Summary: The repository tracked a pubspec backup and a build id, the terms
  of use still excused Bing imagery that the app no longer serves, and the
  documentation did not mention the generated env file, the ArcGIS key or the
  test and smoke commands.

  Decisions:
  - The backup and build id are untracked rather than deleted so local build
    caches survive.
  - The Bing imagery exception in the terms of use is replaced in the same
    change that stops serving Bing imagery.
  - l10n.yaml uses forward slashes so localization generation is reproducible
    on Linux CI.

  Files:
  - .gitignore: ignore backup files and the lib build directory.
  - l10n.yaml: use forward slashes for the ARB directory.
  - lib/privacy_terms.dart: replace the Bing imagery exception with the Esri
    World Imagery terms.
  - README.md: document the ArcGIS key, the generated env file, the test and
    smoke commands.
  - AGENTS.md: document the new map imagery modules, the toolchain versions and
    the attribution obligation.
  - CHANGELOG.md: record the imagery switch, the User-Agent fix and the
    attribution label.
  - pubspec.yaml.bak: untrack the stale pubspec backup.
  - lib/build/.last_build_id: untrack the build artifact.
  ```

---

## Graph Context

- **Architecture overview** (`codebase-memory-mcp_get_architecture`): 974 nodes / 2683 edges; 35 Dart files; entry points `lib/main.dart:main` and `linux/main.cc:main`. Packages: `widget` (25), `widget_other` (36), `providers` (60), `database` (74), `camera` (94), `data` (20), `form` (14), `geo`/`geo_info` (13/26), `src` (19). Boundaries: `widget → src` (5), `widget → mdi_icons` (2), `form → form_parts` (4), `io → http_result` (5), `geo → geo_info` (3). `lib/env.dart` is not yet a node in the graph (it holds only the `Env` class).
- **Risk map — highest-degree functions** (`MATCH (f:Function)-[r]-(o) ... ORDER BY degree DESC LIMIT 10`): `lib/widget.dart:getPageList` 43, `getInfoPanel` 37, `addGreen` 30, `getResultPage` 25, `getEditPanel` 24, `updateGeometryGreen` 22, `doMapAction` 18, `downloadResults` 12, `setProjectCoords` 12, `getPanel` 10. **The map page lives inside `getPageList`** — the highest-degree function in the app. Any edit inside it must be re-verified by an actual map render, which is why the smoke run is mandatory and why the attribution widget gets its own widget test.
- **Affected paths**: `lib/widget.dart` (background layers 1134-1159, map panel 423-463, map stack 1503-1516, dead Bing classes 956-1048), `lib/providers.dart` (365-366, 380-395), `lib/main.dart` (49-57), `lib/env.dart` (all), `lib/l10n/app_{en,it}.arb`, `lib/src/generated/l10n/*`, `lib/privacy_terms.dart` (30, 93), `README.md` (33-45), `test/widget_test.dart`.
- **Cross-directory coupling to watch** (`MATCH (a:File)-[r]->(b:File)`): the graph shows `AGENTS.md → pubspec.yaml`, `AGENTS.md → android/app/build.gradle`, `AGENTS.md → lib/mdi_icons.dart`, plus the platform runners. The `lib/` internal couplings (`widget → src`, `widget → mdi_icons`, `form → form_parts`, `io → http_result`, `geo → geo_info`) mean the new `lib/map/` modules must **not** import `lib/widget.dart` — the dependency is one-way (`widget.dart → map/`), so the new modules stay unit-testable.
- **Known coverage gaps (untested hotspots)**: `MATCH (f:Function) WHERE f.is_test = false` returns `downloadResults`, `getPollutantButtonList`, `updateGeometryGreen`, `addGreen`, `doMapAction`, `getPanel`, `getMapPanel`, `getInfoPanel`, `getEditPanel`, `setProjectCoords` — all in `lib/widget.dart`, **none covered by any test**. `getMapPanel` is touched by this change, so T1 adds the provider tests that cover the map-type selection logic it delegates to.
- **High-degree hubs (out-degree)**: `getPageList` 7, `getResultPage` 5, `getPanel` 3, `getInfoPanel` 3, `getEditPanel` 2.

---

## Edge Cases & Error Handling

| Case | Handling |
|---|---|
| `ARCGIS_LOCATION_KEY` missing from `.env` | `envied` fails generation with `Environment variable not found for field 'arcgisLocationKey'.` — the same explicit failure as today. The field is **not** made optional, because a silent empty key would silently downgrade every user to the 2022 archive. The README documents the requirement. |
| Key present but empty after sanitation | `esriWorldImageryTileTemplate` returns `null`; the provider marks the primary unavailable and uses the Wayback layer; the attribution shows the Wayback credit. |
| Key present but rejected by ArcGIS (498) | Detected by the startup probe → Wayback fallback; the fallback is one-way, so the key is re-probed on the next app start only. |
| Key present but the free quota is exhausted | Esri publishes no quota error code. The startup probe classifies **any** non-image / non-200 answer as unavailable → Wayback. If exhaustion happens mid-session, the Esri tile request returns a non-image body that fails to decode → `errorTileCallback` → `activateEsriFallbackOnTileError` → Wayback. |
| Wayback release 43291 does not own the requested tile at that zoom | The service answers 301 to the owning release; `package:http` follows up to 5 redirects automatically. |
| Wayback unreachable | The map shows the OSM background as the last resort and the attribution follows the layer actually in use. |
| OSM returns the block tile anyway (policy change) | The failure is silent by nature (HTTP 200 + `x-blocked` + a valid PNG). The compliant UA is the mitigation; the residual risk is recorded below. |
| Esri tile at zoom ≥ 20 | `maxNativeZoom: 19` clamps the request; without it the service returns a blank grey image. |
| OSM tile at zoom 20 | `maxNativeZoom: 19` avoids the HTTP 400 `You requested an invalid tile.` |
| Web build | `userAgentPackageName` and the `User-Agent` override are ignored on web (`tile_layer.dart:334` guards on `!kIsWeb`) and browsers forbid setting the header. The app targets Android/iOS/Linux desktop; a web build would need a different tile source. Recorded as a residual risk. |
| OSM cache policy | flutter_map 6.2.1 caches tiles in memory for the session only, which does not satisfy the OSMF ≥ 7-day caching rule; fixing it needs flutter_map ≥ 8.2 (persistent caching) — out of scope, recorded as residual risk. |
| Stray untracked probe files in the repo root (`bt.bin`, `bt2.bin`, `cs.json`, `i1.bin`, `i2.bin`, `ti.json`) | Never staged; T4 leaves them alone (they belong to another process) but ensures they cannot enter a commit. |

### Residual risks (accepted, documented in code where relevant)

1. **OSM in a distributed mobile app.** The OSMF tile usage policy does not forbid mobile apps outright, but it forbids bulk download, offline caching of the standard tiles and heavy use, offers no SLA, and states access may be withdrawn at any time. A compliant UA plus visible attribution satisfies §2 and §3.1 but does not turn the free tiles into a licensed service. Migrating to a commercial provider (CARTO, Stadia) or self-hosting is the durable path.
2. **Esri attribution drift.** The provider list is Esri's `copyrightText`; Esri states attribution can change frequently. The app prefers the runtime value fetched from the service and falls back to the ARB copy, which must be reviewed periodically.
3. **Quota semantics unverified.** No published Esri error code identifies "free quota exhausted"; the implementation therefore treats every unexpected answer as unavailable, which is safe but may switch to the archive on a transient 5xx. A retry on the next app start restores the primary.
4. **`flutter analyze` baseline.** 160 issues exist before this change (8 errors). The gate is "no new issues, and the 8 errors resolved", not "zero issues" — a clean-baseline rewrite of `lib/widget.dart` is a separate refactor.
5. **The key is not a secret.** An API key embedded in a mobile binary is extractable; `obfuscate: true` only raises the effort. The ArcGIS key should be restricted (referrer / usage limits) and rotated if the app is distributed publicly.

---

## References

- Esri attribution requirements: <https://developers.arcgis.com/documentation/esri-and-data-attribution/interactive-maps/> — "Powered by Esri", bottom-right, ≥ 12 px, `#323232` on `#ffffff` at 65 %.
- Esri data attributions: <https://www.esri.com/en-us/legal/terms/data-attributions> · terms: <https://www.esri.com/en-us/legal/terms>
- Esri Location Platform key authentication: <https://developers.arcgis.com/documentation/security-and-authentication/api-key-authentication/>
- Esri World Imagery service: <https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer?f=json> — item `10df2279f9684e4a9f6a7f08febac2a9`, owner `esri`, `accessInformation` "Esri, Vantor, Earthstar Geographics, and the GIS User Community"
- Esri World Imagery Wayback: <https://wayback.maptiles.arcgis.com/arcgis/rest/services/World_Imagery/MapServer?f=json> (198 releases, `Selection[]` with `Name`/`M`/`ID`) · catalogue <https://s3-us-west-2.amazonaws.com/config.maptiles.arcgis.com/waybackconfig.json>
- OSMF tile usage policy: <https://operations.osmfoundation.org/policies/tiles/> — §2 attribution, §3.1 User-Agent, §3.2 caching, §4 no bulk download
- OSMF attribution guidelines: <https://wiki.osmfoundation.org/wiki/Licence/Attribution_Guidelines> · <https://wiki.openstreetmap.org/wiki/Attribution> · <https://wiki.openstreetmap.org/wiki/Blocked_tiles>
- flutter_map 6.2.1 sources (local, `~/.pub-cache/hosted/pub.dev/flutter_map-6.2.1/`): `lib/src/layer/tile_layer/tile_layer.dart:239-337` (constructor, `errorTileCallback`, User-Agent setup), `lib/src/layer/tile_layer/tile_provider/base_tile_provider.dart:20-28,142-204` (`headers`, placeholder substitution), `lib/src/layer/tile_layer/tile_provider/network_tile_provider.dart:34-40` (`RetryClient(Client())`), `lib/src/layer/attribution_layer/simple.dart:30-50`, `lib/src/layer/attribution_layer/rich/widget.dart:13-28,118-130`
- envied 1.3.1: <https://pub.dev/packages/envied/versions/1.3.1> · local sources `~/.pub-cache/hosted/pub.dev/envied-1.3.1/lib/src/envied_base.dart` (only `envied`, `Envied`, `EnviedField`) and `envied_generator-1.3.1/lib/src/generator.dart` (missing-variable error), `generate_field_encrypted.dart` (obfuscated fields are `static final`)
- Package documentation: <https://docs.fleaflet.dev/v6/layers/tile-layer> · <https://docs.fleaflet.dev/tile-servers/using-openstreetmap-direct> (flutter_map's own note that OSM blocks the example identifier)
- Repository facts: `pubspec.yaml` (name `Airtree`, version `1.0.7+13`, `flutter_map: ^6.0.1` → 6.2.1, `envied: ^1.3.1`, `url_launcher: ^6.1.11` → 6.3.2), `android/app/build.gradle` (`applicationId "it.alivernini.airtree"`), `l10n.yaml`, `.gitignore`, `README.md`, `AGENTS.md`, `CHANGELOG.md`
