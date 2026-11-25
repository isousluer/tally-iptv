/// Works out which country a category belongs to and whether it holds adult
/// content, from the category name alone. Providers name categories in many
/// ways ("NO-NORWAY", "DE | Sports", "TR: ULUSAL", "TURK FILMLERI"), so this
/// looks for a two-letter code at the start first and then for a country name
/// anywhere in it.
library;

/// A country (or region) the cleanup wizard can offer.
class Country {
  const Country(this.code, this.en, this.tr, [this.aliases = const []]);
  final String code;
  final String en;
  final String tr;

  /// Extra spellings found in category names, upper case without accents.
  final List<String> aliases;

  String name(String languageCode) => languageCode == 'tr' ? tr : en;
}

const countries = <Country>[
  Country('TR', 'Turkey', 'Türkiye', ['TURKEY', 'TURKIYE', 'TURK', 'TURKISH', 'TURKCE']),
  Country('DE', 'Germany', 'Almanya', ['GERMANY', 'DEUTSCHLAND', 'DEUTSCH', 'DEUTSCHEN', 'GERMAN', 'ALMANYA']),
  Country('AT', 'Austria', 'Avusturya', ['AUSTRIA', 'OSTERREICH', 'AVUSTURYA']),
  Country('CH', 'Switzerland', 'İsviçre', ['SWITZERLAND', 'SCHWEIZ', 'SUISSE', 'ISVICRE']),
  Country('NL', 'Netherlands', 'Hollanda', ['NETHERLANDS', 'NEDERLAND', 'HOLLAND', 'DUTCH', 'HOLLANDA']),
  Country('BE', 'Belgium', 'Belçika', ['BELGIUM', 'BELGIE', 'BELGIQUE', 'BELCIKA']),
  Country('FR', 'France', 'Fransa', ['FRANCE', 'FRENCH', 'FRANSA']),
  Country('GB', 'United Kingdom', 'Birleşik Krallık', ['ENGLAND', 'BRITAIN', 'BRITISH', 'INGILTERE']),
  Country('IE', 'Ireland', 'İrlanda', ['IRELAND', 'IRISH', 'IRLANDA']),
  Country('US', 'United States', 'ABD', ['USA', 'AMERICA', 'AMERIKA']),
  Country('CA', 'Canada', 'Kanada', ['CANADA', 'KANADA']),
  Country('IT', 'Italy', 'İtalya', ['ITALY', 'ITALIA', 'ITALIAN', 'ITALYA']),
  Country('ES', 'Spain', 'İspanya', ['SPAIN', 'ESPANA', 'SPANISH', 'ISPANYA']),
  Country('PT', 'Portugal', 'Portekiz', ['PORTUGAL', 'PORTEKIZ']),
  Country('GR', 'Greece', 'Yunanistan', ['GREECE', 'GREEK', 'HELLAS', 'YUNANISTAN']),
  Country('CY', 'Cyprus', 'Kıbrıs', ['CYPRUS', 'KIBRIS', 'KKTC']),
  Country('NO', 'Norway', 'Norveç', ['NORWAY', 'NORGE', 'NORSK', 'NORVEC']),
  Country('SE', 'Sweden', 'İsveç', ['SWEDEN', 'SVERIGE', 'SWEDISH', 'ISVEC']),
  Country('DK', 'Denmark', 'Danimarka', ['DENMARK', 'DANMARK', 'DANISH', 'DANIMARKA']),
  Country('FI', 'Finland', 'Finlandiya', ['FINLAND', 'SUOMI', 'FINLANDIYA']),
  Country('IS', 'Iceland', 'İzlanda', ['ICELAND', 'IZLANDA']),
  Country('PL', 'Poland', 'Polonya', ['POLAND', 'POLSKA', 'POLISH', 'POLONYA']),
  Country('CZ', 'Czechia', 'Çekya', ['CZECH', 'CZECHIA', 'CESKO', 'CEKYA']),
  Country('SK', 'Slovakia', 'Slovakya', ['SLOVAKIA', 'SLOVENSKO', 'SLOVAKYA']),
  Country('HU', 'Hungary', 'Macaristan', ['HUNGARY', 'MAGYAR', 'MACARISTAN']),
  Country('RO', 'Romania', 'Romanya', ['ROMANIA', 'ROMANYA']),
  Country('BG', 'Bulgaria', 'Bulgaristan', ['BULGARIA', 'BULGARISTAN']),
  Country('AL', 'Albania', 'Arnavutluk', ['ALBANIA', 'SHQIP', 'ARNAVUTLUK']),
  Country('EXYU', 'Former Yugoslavia', 'Eski Yugoslavya', ['EX-YU', 'EXYU', 'EX YU', 'YUGO', 'BALKAN']),
  Country('RU', 'Russia', 'Rusya', ['RUSSIA', 'RUSSIAN', 'ROSSIYA', 'RUSYA']),
  Country('UA', 'Ukraine', 'Ukrayna', ['UKRAINE', 'UKRAYNA']),
  Country('AZ', 'Azerbaijan', 'Azerbaycan', ['AZERBAIJAN', 'AZERBAYCAN']),
  Country('GE', 'Georgia', 'Gürcistan', ['GEORGIA', 'GURCISTAN']),
  Country('AM', 'Armenia', 'Ermenistan', ['ARMENIA', 'ERMENISTAN']),
  Country('KZ', 'Kazakhstan', 'Kazakistan', ['KAZAKHSTAN', 'KAZAKISTAN']),
  Country('IR', 'Iran', 'İran', ['IRAN', 'PERSIAN', 'FARSI']),
  Country('ARAB', 'Arab countries', 'Arap ülkeleri', ['ARAB', 'ARABIC', 'ARABIAN', 'ARABIA', 'ARAP']),
  Country('IL', 'Israel', 'İsrail', ['ISRAEL', 'ISRAIL']),
  Country('KU', 'Kurdish', 'Kürtçe', ['KURD', 'KURDISH', 'KURDISTAN', 'KURTCE']),
  Country('IN', 'India', 'Hindistan', ['INDIA', 'HINDI', 'HINDISTAN']),
  Country('PK', 'Pakistan', 'Pakistan', ['PAKISTAN']),
  Country('AF', 'Afghanistan', 'Afganistan', ['AFGHANISTAN', 'AFGHAN', 'AFGANISTAN']),
  Country('CN', 'China', 'Çin', ['CHINA', 'CHINESE']),
  Country('JP', 'Japan', 'Japonya', ['JAPAN', 'JAPANESE', 'JAPONYA']),
  Country('KR', 'South Korea', 'Güney Kore', ['KOREA', 'KOREAN', 'KORE']),
  Country('PH', 'Philippines', 'Filipinler', ['PHILIPPINES', 'FILIPINO', 'PINOY', 'FILIPINLER']),
  Country('TH', 'Thailand', 'Tayland', ['THAILAND', 'TAYLAND']),
  Country('VN', 'Vietnam', 'Vietnam', ['VIETNAM']),
  Country('ID', 'Indonesia', 'Endonezya', ['INDONESIA', 'ENDONEZYA']),
  Country('MY', 'Malaysia', 'Malezya', ['MALAYSIA', 'MALEZYA']),
  Country('AU', 'Australia', 'Avustralya', ['AUSTRALIA', 'AVUSTRALYA']),
  Country('NZ', 'New Zealand', 'Yeni Zelanda', ['ZEALAND']),
  Country('MX', 'Mexico', 'Meksika', ['MEXICO', 'MEKSIKA']),
  Country('BR', 'Brazil', 'Brezilya', ['BRAZIL', 'BRASIL', 'BREZILYA']),
  Country('LATAM', 'Latin America', 'Latin Amerika', ['LATINO', 'LATAM', 'LATIN']),
  Country('AFR', 'Africa', 'Afrika', ['AFRICA', 'AFRIKA']),
  Country('CARIB', 'Caribbean', 'Karayipler', ['CARIBBEAN', 'KARAYIP']),
];

final _byCode = {for (final c in countries) c.code: c};

Country? countryByCode(String code) => _byCode[code];

/// Two-letter prefixes providers use that aren't the ISO code.
const _codeAliases = {'UK': 'GB', 'EN': 'GB', 'KU': 'KU', 'KRD': 'KU', 'LAT': 'LATAM', 'YU': 'EXYU'};

/// Codes that also mean something else, so they only count when nothing in
/// the rest of the name points elsewhere ("AR-ARABIAN" is Arabic, not
/// Argentina).
const _ambiguousPrefixes = {'AR', 'IN', 'IS', 'IT', 'NO', 'TV', 'HD', 'SD', 'VIP', 'PPV', 'UHD', 'FHD'};

String _fold(String s) {
  const map = {
    'İ': 'I', 'I': 'I', 'ı': 'I', 'Ş': 'S', 'ş': 'S', 'Ğ': 'G', 'ğ': 'G', 'Ü': 'U', 'ü': 'U', //
    'Ö': 'O', 'ö': 'O', 'Ç': 'C', 'ç': 'C', 'Ä': 'A', 'ä': 'A', 'Å': 'A', 'å': 'A', 'Ø': 'O', 'ø': 'O',
    'É': 'E', 'é': 'E', 'È': 'E', 'è': 'E', 'Ñ': 'N', 'ñ': 'N', 'Æ': 'AE', 'æ': 'AE',
  };
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    b.write(map[ch] ?? ch);
  }
  return b.toString().toUpperCase();
}

final _prefix = RegExp(r'^[\s|\[\(#★]*([A-Z]{2,5})\s*(?:[-|:\]\)/•]|\s)');
final _words = RegExp(r'[A-Z]+');

/// The code of the country [group] belongs to, or null when the name doesn't
/// say.
String? countryOfGroup(String group) {
  final up = _fold(group);
  if (up.contains('EX-YU') || up.contains('EX YU')) return 'EXYU';
  final words = _words.allMatches(up).map((m) => m.group(0)!).toList();
  String? byName;
  for (final c in countries) {
    if (c.aliases.any((a) => a.contains(' ') || a.contains('-') ? up.contains(a) : words.contains(a))) {
      byName = c.code;
      break;
    }
  }
  final m = _prefix.firstMatch(up);
  if (m != null) {
    final raw = m.group(1)!;
    final code = _codeAliases[raw] ?? raw;
    if (_byCode.containsKey(code)) {
      // A name later in the category wins over a code that can mean
      // something else, and over a prefix that disagrees with it.
      if (byName != null && (byName != code) && _ambiguousPrefixes.contains(raw)) return byName;
      return code;
    }
  }
  return byName;
}

/// Category names that usually hold adult content. Only the category name is
/// checked, never the titles inside it, so a normal film with "adult" in its
/// name stays visible.
final adultGroupPattern = RegExp(
  r'(?<![a-z])(adults?|xxx|porn\w*|erotic\w*|erotik\w*|for adults|yeti[sş]kin\w*)(?![a-z])|\+18|18\+',
  caseSensitive: false,
);

/// Matches "Adult Swim" and other names that are not adult content.
final _notAdult = RegExp(r'adult\s*swim|young\s*adult', caseSensitive: false);

bool isAdultGroup(String group) {
  final folded = _fold(group);
  return adultGroupPattern.hasMatch(folded) && !_notAdult.hasMatch(folded);
}

/// What the viewer chose in the cleanup wizard for one playlist.
class CategoryFilter {
  const CategoryFilter({this.countries = const {}, this.hideAdult = false});

  /// Country codes to keep. Empty keeps every country.
  final Set<String> countries;
  final bool hideAdult;

  /// Whether [group] should be hidden under this choice. Categories without
  /// a country are never hidden for their country.
  bool hides(String group) {
    if (hideAdult && isAdultGroup(group)) return true;
    if (countries.isEmpty) return false;
    final c = countryOfGroup(group);
    return c != null && !countries.contains(c);
  }

  /// Whether this choice has anything to say about [group].
  bool concerns(String group) => isAdultGroup(group) || countryOfGroup(group) != null;
}
