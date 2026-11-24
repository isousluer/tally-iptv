import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Languages the app is translated into. The first one is the fallback.
const appLocales = [Locale('en'), Locale('tr')];

/// The language to use when the viewer hasn't picked one: the device's
/// language if Tally speaks it, English otherwise.
Locale systemLocale() {
  for (final device in WidgetsBinding.instance.platformDispatcher.locales) {
    for (final l in appLocales) {
      if (l.languageCode == device.languageCode) return l;
    }
  }
  return appLocales.first;
}

/// Strings for code that has no [BuildContext], such as error messages from
/// the data layer and formatting helpers. [TallyApp] keeps it on the app's
/// current language; widgets use [L10nContext.l10n] instead so they rebuild
/// when the language changes.
AppLocalizations strings = lookupAppLocalizations(appLocales.first);

void useLocale(Locale locale) {
  if (strings.localeName == locale.languageCode) return;
  strings = lookupAppLocalizations(locale);
  intl.Intl.defaultLocale = locale.languageCode;
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
