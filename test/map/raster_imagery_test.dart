import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:Airtree/map/raster_imagery.dart';

void main() {
  group('sanitizeApiKey', () {
    test('removes surrounding double quotes', () {
      expect(sanitizeApiKey('"abc"'), 'abc');
    });

    test('keeps an unquoted key unchanged', () {
      expect(sanitizeApiKey('abc'), 'abc');
    });

    test('returns an empty string for whitespace only input', () {
      expect(sanitizeApiKey('   '), '');
    });

    test('returns an empty string for empty input', () {
      expect(sanitizeApiKey(''), '');
    });

    test('trims whitespace around a quoted key', () {
      expect(sanitizeApiKey('  "abc"  '), 'abc');
    });
  });

  group('esriWorldImageryTileTemplate', () {
    test('is null for an empty key', () {
      expect(esriWorldImageryTileTemplate(''), isNull);
      expect(esriWorldImageryTileTemplate('   '), isNull);
    });

    test('uses the token query parameter', () {
      final template = esriWorldImageryTileTemplate('abc');
      expect(template, isNotNull);
      expect(template, contains('?token='));
    });

    test('uses the ArcGIS row/column path order', () {
      final template = esriWorldImageryTileTemplate('abc')!;
      expect(template, contains('/tile/{z}/{y}/{x}'));
      expect(template.indexOf('{z}/{y}/{x}'),
          greaterThan(template.indexOf('{z}/{x}/{y}')));
    });

    test('URL encodes the key', () {
      final template = esriWorldImageryTileTemplate('a b&c=d')!;
      expect(template, contains('token=a+b%26c%3Dd'));
      expect(template, isNot(contains('token=a b&c=d')));
    });

    test('sanitizes a quoted key', () {
      final template = esriWorldImageryTileTemplate('"abc"')!;
      expect(template, endsWith('token=abc'));
    });
  });

  group('esriWaybackTileTemplate', () {
    test('pins the release id', () {
      expect(esriWaybackTileTemplate(), contains('43291'));
    });

    test('uses the row/column path order', () {
      expect(esriWaybackTileTemplate(), contains('{z}/{y}/{x}'));
    });

    test('targets the Wayback host', () {
      expect(esriWaybackTileTemplate(), startsWith('https://wayback.maptiles.arcgis.com'));
    });
  });

  group('classifyImageryResponse', () {
    test('a token-required envelope is unauthorized', () {
      final availability = classifyImageryResponse(
        statusCode: 200,
        contentType: 'text/plain',
        body: '{"error":{"code":499,"message":"Token Required."}}',
      );
      expect(availability, ImageryAvailability.unauthorized);
    });

    test('an invalid-token envelope is unauthorized', () {
      final availability = classifyImageryResponse(
        statusCode: 200,
        contentType: 'text/plain',
        body: '{"error":{"code":498,"message":"Invalid token."}}',
      );
      expect(availability, ImageryAvailability.unauthorized);
    });

    test('a JSON document without a known error code is unavailable', () {
      final availability = classifyImageryResponse(
        statusCode: 200,
        contentType: 'application/json',
        body: '{"somethingElse":true}',
      );
      expect(availability, ImageryAvailability.unavailable);
    });

    test('HTTP 401 is unauthorized', () {
      final availability = classifyImageryResponse(
        statusCode: 401,
        contentType: 'application/json',
        body: '{}',
      );
      expect(availability, ImageryAvailability.unauthorized);
    });

    test('HTTP 403 is unauthorized', () {
      final availability = classifyImageryResponse(
        statusCode: 403,
        contentType: 'application/json',
        body: '{}',
      );
      expect(availability, ImageryAvailability.unauthorized);
    });

    test('HTTP 500 is unavailable', () {
      final availability = classifyImageryResponse(
        statusCode: 500,
        contentType: 'text/html',
        body: 'boom',
      );
      expect(availability, ImageryAvailability.unavailable);
    });

    test('a service document is available', () {
      final availability = classifyImageryResponse(
        statusCode: 200,
        contentType: 'application/json',
        body: '{"copyrightText":"Source: Esri","tileInfo":{}}',
      );
      expect(availability, ImageryAvailability.available);
    });

    test('a non JSON text body is unavailable', () {
      final availability = classifyImageryResponse(
        statusCode: 200,
        contentType: 'text/plain',
        body: 'not a document',
      );
      expect(availability, ImageryAvailability.unavailable);
    });
  });

  group('probeEsriImagery', () {
    test('reports availability and the copyright text', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['token'], 'abc');
        expect(request.url.queryParameters['f'], 'json');
        return http.Response(
          '{"copyrightText":"Source: Esri","tileInfo":{}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await probeEsriImagery('abc', client: client);

      expect(result.availability, ImageryAvailability.available);
      expect(result.copyrightText, 'Source: Esri');
      expect(result.statusCode, 200);
    });

    test('reports unauthorized for a token error envelope', () async {
      final client = MockClient((request) async => http.Response(
            '{"error":{"code":499,"message":"Token Required."}}',
            200,
            headers: {'content-type': 'text/plain'},
          ));

      final result = await probeEsriImagery('abc', client: client);

      expect(result.availability, ImageryAvailability.unauthorized);
    });

    test('reports unavailable instead of throwing when the client fails',
        () async {
      final client = MockClient((request) async =>
          throw http.ClientException('network down'));

      final result = await probeEsriImagery('abc', client: client);

      expect(result.availability, ImageryAvailability.unavailable);
    });
  });
}
