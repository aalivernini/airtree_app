import 'package:flutter_test/flutter_test.dart';

import 'package:Airtree/map/imagery_provider.dart';
import 'package:Airtree/map/raster_imagery.dart';

void main() {
  test('the default background is Esri World Imagery', () {
    final provider = ImageryProvider();
    expect(provider.background, MapBackground.esri);
    expect(provider.esriFallbackActive, isFalse);
  });

  test('selectBackground changes the background and notifies', () {
    final provider = ImageryProvider();
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider.selectBackground(MapBackground.openStreetMap);

    expect(provider.background, MapBackground.openStreetMap);
    expect(notifications, greaterThan(0));
  });

  test('an unavailable probe result activates the Wayback fallback', () {
    final provider = ImageryProvider(apiKey: 'abc');

    provider.applyProbeResult(
      const ImageryProbeResult(availability: ImageryAvailability.unavailable),
    );

    expect(provider.esriFallbackActive, isTrue);
    expect(provider.availability, ImageryAvailability.unavailable);
    expect(provider.esriTileTemplate, esriWaybackTileTemplate());
  });

  test('an available probe result keeps the primary template', () {
    final provider = ImageryProvider(apiKey: 'abc');

    provider.applyProbeResult(
      const ImageryProbeResult(
        availability: ImageryAvailability.available,
        copyrightText: 'Source: Esri',
      ),
    );

    expect(provider.esriFallbackActive, isFalse);
    expect(provider.esriCopyrightText, 'Source: Esri');
    expect(provider.esriTileTemplate, isNot(esriWaybackTileTemplate()));
    expect(provider.esriTileTemplate, contains('?token=abc'));
  });

  test('a tile error activates the fallback only on the Esri background', () {
    final provider = ImageryProvider(apiKey: 'abc');

    provider.activateEsriFallbackOnTileError(StateError('tile failed'));

    expect(provider.esriFallbackActive, isTrue);
  });

  test('a tile error is ignored on another background', () {
    final provider = ImageryProvider(apiKey: 'abc');
    provider.selectBackground(MapBackground.openStreetMap);

    provider.activateEsriFallbackOnTileError(StateError('tile failed'));

    expect(provider.esriFallbackActive, isFalse);
  });

  test('the fallback is engaged only once', () {
    final provider = ImageryProvider(apiKey: 'abc');
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider.activateEsriFallback();
    provider.activateEsriFallback();

    expect(provider.esriFallbackActive, isTrue);
    expect(notifications, 1);
  });

  test('the template is null without a key and without a fallback', () {
    final provider = ImageryProvider(apiKey: '');

    expect(provider.esriFallbackActive, isFalse);
    expect(provider.esriTileTemplate, isNull);
  });
}
