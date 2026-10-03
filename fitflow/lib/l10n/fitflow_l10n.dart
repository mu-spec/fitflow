import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// English is the only complete FitFlow V1 locale.
///
/// There is no language setting. The app follows the system locale and
/// falls back to English when that locale has no reviewed translation.
extension FitFlowLocalizationsX on BuildContext {
  AppLocalizations get l10n {
    return Localizations.of<AppLocalizations>(this, AppLocalizations) ??
        lookupAppLocalizations(const Locale('en'));
  }
}

/// App copy for code that has no widget context, such as a notification.
///
/// Always English until a complete additional locale is shipped.
AppLocalizations englishAppLocalizations() =>
    lookupAppLocalizations(const Locale('en'));
