import 'package:flutter_test/flutter_test.dart';

import 'package:Airtree/env.dart';

void main() {
  test('the ArcGIS location key is configured and unquoted', () {
    // Assert on booleans only: a failing expectation must never print the key.
    expect(Env.arcgisLocationKey.isNotEmpty, isTrue);
    expect(Env.arcgisLocationKey.trim().startsWith('"'), isFalse);
    expect(Env.arcgisLocationKey.trim().endsWith('"'), isFalse);
  });
}
