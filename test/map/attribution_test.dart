import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:Airtree/l10n/l10n.dart';
import 'package:Airtree/map/attribution.dart';
import 'package:Airtree/map/imagery_provider.dart';
import 'package:Airtree/src/generated/l10n/app_localizations.dart';

/// Builds the label inside a localized application with the given provider.
Widget _app(ImageryProvider imagery, {Widget? child}) {
  return ChangeNotifierProvider<ImageryProvider>.value(
    value: imagery,
    child: MaterialApp(
      supportedLocales: L10n.all,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: child ?? const Scaffold(body: MapAttributionLabel()),
    ),
  );
}

/// Returns the plain text of the rendered credit.
String _creditText(WidgetTester tester) {
  final richText = tester.widget<RichText>(find.byType(RichText).first);
  return richText.text.toPlainText();
}

void main() {
  testWidgets('the Esri credit names Esri and the powered by notice',
      (WidgetTester tester) async {
    final imagery = ImageryProvider();
    imagery.selectBackground(MapBackground.esri);

    await tester.pumpWidget(_app(imagery));

    final text = _creditText(tester);
    expect(text, contains('Powered by Esri'));
    expect(text, contains('Esri'));
  });

  testWidgets('the OpenStreetMap credit replaces the Esri one',
      (WidgetTester tester) async {
    final imagery = ImageryProvider();
    imagery.selectBackground(MapBackground.openStreetMap);

    await tester.pumpWidget(_app(imagery));

    final text = _creditText(tester);
    expect(text, contains('OpenStreetMap contributors'));
    expect(text, isNot(contains('Powered by Esri')));
  });

  testWidgets('the Wayback fallback shows the archived provider list',
      (WidgetTester tester) async {
    final imagery = ImageryProvider();
    imagery.selectBackground(MapBackground.esri);
    imagery.activateEsriFallback();

    await tester.pumpWidget(_app(imagery));

    final text = _creditText(tester);
    expect(text, contains('Esri, Vantor, Earthstar Geographics'));
  });

  testWidgets('the label sits in the lower right corner of the map',
      (WidgetTester tester) async {
    final imagery = ImageryProvider();
    imagery.selectBackground(MapBackground.esri);

    await tester.pumpWidget(_app(
      imagery,
      child: const Scaffold(
        body: SizedBox(
          width: 400,
          height: 300,
          child: Stack(
            children: <Widget>[
              Positioned(
                right: 2,
                bottom: 1,
                width: 150,
                child: MapAttributionLabel(),
              ),
            ],
          ),
        ),
      ),
    ));

    final rect = tester.getRect(find.byType(MapAttributionLabel));
    expect(rect.right, closeTo(398, 1.0));
    expect(rect.bottom, closeTo(299, 1.0));
    expect(rect.left, greaterThan(200));
    expect(rect.top, greaterThan(150));
  });
}
