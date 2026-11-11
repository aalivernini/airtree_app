import 'package:Airtree/map/osm_tiles.dart';
import 'package:flutter_test/flutter_test.dart';

/// The OpenStreetMap User-Agent must identify the application and carry a
/// contact URL, and must not carry any identifier that is on the OpenStreetMap
/// block denylist.
void main() {
  group('osmUserAgent', () {
    test('identifies the application and its contact URL', () {
      expect(osmUserAgent, startsWith('Airtree/'));
      expect(osmUserAgent, contains('it.alivernini.airtree'));
      expect(osmUserAgent, contains('https://github.com/aalivernini/airtree_app'));
    });

    test('carries no blocked identifier', () {
      expect(osmUserAgent, isNot(contains('flutter_map')));
      expect(osmUserAgent, isNot(contains('dev.fleaflet')));
      expect(osmUserAgent, isNot(contains('com.example')));
      expect(osmUserAgent, isNot(contains('Mozilla')));
      expect(osmUserAgent, isNot(contains('Dart/')));
    });
  });

  group('osmTileTemplate', () {
    test('points at the OpenStreetMap standard tiles over https', () {
      expect(osmTileTemplate, startsWith('https://tile.openstreetmap.org/'));
      expect(osmTileTemplate, contains('{z}/{x}/{y}'));
      expect(osmTileTemplate, isNot(startsWith('http://')));
    });
  });

  test('the OpenStreetMap native zoom limit is the last served zoom', () {
    expect(kOsmMaxNativeZoom, 19);
  });
}
