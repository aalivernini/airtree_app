import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:Airtree/map/imagery_provider.dart';
import 'package:Airtree/src/generated/l10n/app_localizations.dart';

/// Font size of the attribution label.
///
/// The requirement asks for a very small credit, so 8 px is used. Esri's own
/// guidance recommends 12 px or larger; the size is kept in this single
/// constant so it can be raised in one place if the stricter recommendation
/// has to be met.
const double kAttributionFontSize = 8.0;

/// Licence page of the Esri attribution.
const String kEsriLicenceUrl = 'https://www.esri.com';

/// Licence page of the OpenStreetMap attribution.
const String kOsmLicenceUrl = 'https://www.openstreetmap.org/copyright';

/// Text colour of the attribution, as recommended by Esri.
const Color kAttributionTextColor = Color(0xFF323232);

/// Background colour of the attribution, as recommended by Esri.
const Color kAttributionBackgroundColor = Color(0xFFFFFFFF);

/// Opacity of the attribution background, as recommended by Esri.
const double kAttributionBackgroundOpacity = 0.65;

/// Largest fraction of the screen width the attribution label may occupy.
const double kAttributionMaxWidthFactor = 0.7;

/// The very small credit label shown at the bottom-right of the map.
///
/// OpenStreetMap and Esri both require the credit of the imagery in use to be
/// visible on the map and not hidden beneath other user interface, so the
/// label is always rendered and follows the active background.
class MapAttributionLabel extends StatelessWidget {
  /// Creates the attribution label.
  const MapAttributionLabel({super.key});

  /// Opens the licence page of the credit in use.
  ///
  /// The page is opened in the external browser application so the user
  /// leaves the map and reads the full licence text.
  void _openLicence(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Builds the text span of the Esri credit.
  ///
  /// The provider list is the live copyright text of the service when it is
  /// known, otherwise the localized fallback for the layer in use.
  TextSpan _esriSpan(AppLocalizations l10n, ImageryProvider imagery) {
    final sources = imagery.esriFallbackActive
        ? l10n.attributionEsriWaybackSources
        : (imagery.esriCopyrightText.isNotEmpty
            ? imagery.esriCopyrightText
            : l10n.attributionEsriSources);
    return TextSpan(
      children: <InlineSpan>[
        TextSpan(text: l10n.attributionEsriPowered),
        const TextSpan(text: ' | '),
        TextSpan(text: sources),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagery = context.watch<ImageryProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isEsri = imagery.background == MapBackground.esri;
    final span = isEsri
        ? _esriSpan(l10n, imagery)
        : TextSpan(text: l10n.attributionOsm);
    final licenceUrl = isEsri ? kEsriLicenceUrl : kOsmLicenceUrl;
    return GestureDetector(
      onTap: () => _openLicence(licenceUrl),
      child: Container(
        color: kAttributionBackgroundColor
            .withValues(alpha: kAttributionBackgroundOpacity),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        // The provider list is long; the label may use at most this fraction
        // of the screen width so it never spills over the map.
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * kAttributionMaxWidthFactor,
        ),
        child: Text.rich(
          span,
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: kAttributionFontSize,
            color: kAttributionTextColor,
          ),
        ),
      ),
    );
  }
}
