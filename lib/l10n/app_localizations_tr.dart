// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get ok => 'Tamam';

  @override
  String get remove => 'Kaldır';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get close => 'Kapat';

  @override
  String get back => 'Geri';

  @override
  String get off => 'Kapalı';

  @override
  String get play => 'Oynat';

  @override
  String get required => 'Zorunlu';

  @override
  String get show => 'Göster';

  @override
  String get hide => 'Gizle';

  @override
  String get more => 'Daha fazla';

  @override
  String get search => 'Ara';

  @override
  String get live => 'Canlı';

  @override
  String get unknownError => 'bilinmeyen hata';

  @override
  String get somethingWentWrong => 'Bir şeyler ters gitti';

  @override
  String get liveTv => 'Canlı TV';

  @override
  String get movies => 'Filmler';

  @override
  String get series => 'Diziler';

  @override
  String get library => 'Kitaplık';

  @override
  String get settings => 'Ayarlar';

  @override
  String get channels => 'Kanallar';

  @override
  String get categories => 'Kategoriler';

  @override
  String libraryOpenFailed(String error) {
    return 'Kitaplık açılamadı: $error';
  }

  @override
  String playlistsAutoUpdated(String names) {
    return '$names güncellendi';
  }

  @override
  String channelCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString kanal';
  }

  @override
  String movieCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString film';
  }

  @override
  String seriesCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString dizi';
  }

  @override
  String playlistCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString liste';
  }

  @override
  String seasonCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString sezon';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String timerMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String timerHours(int hours) {
    return '$hours sa';
  }

  @override
  String timerHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String timeLeft(String time) {
    return '$time kaldı';
  }

  @override
  String get playlists => 'Listeler';

  @override
  String get addPlaylist => 'Liste ekle';

  @override
  String get autoRefreshTitle => 'Listeleri otomatik güncelle';

  @override
  String get autoRefreshSubtitle => 'Uygulama açılınca bir günden eski listeler yenilenir.';

  @override
  String get categoriesSubtitle => 'Kategorileri gizle, kilitle veya sırala';

  @override
  String get language => 'Dil';

  @override
  String get systemLanguage => 'Sistem dili';

  @override
  String get playback => 'Oynatma';

  @override
  String get autoNextTitle => 'Sonraki bölümü otomatik oynat';

  @override
  String get audioLanguage => 'Ses dili';

  @override
  String get audioLanguageDefault => 'Yayının varsayılanı. Oynatıcıda bir dil seçersen bundan sonra o kullanılır.';

  @override
  String get subtitles => 'Altyazı';

  @override
  String get subtitlesDefault => 'Yayının varsayılanı. Oynatıcıda altyazı seçersen bundan sonra o kullanılır.';

  @override
  String tapForStreamDefault(String choice) {
    return '$choice · yayının varsayılanına dönmek için dokun';
  }

  @override
  String get subtitleStyle => 'Altyazı görünümü';

  @override
  String get subtitleStyleSubtitle => 'Boyut, arka plan ve konum';

  @override
  String get subtitleSample => 'Altyazılar böyle görünecek.';

  @override
  String get subtitleSize => 'Boyut';

  @override
  String get sizeSmall => 'Küçük';

  @override
  String get sizeMedium => 'Orta';

  @override
  String get sizeLarge => 'Büyük';

  @override
  String get sizeHuge => 'Çok büyük';

  @override
  String get subtitleBackground => 'Arka plan';

  @override
  String get backgroundNone => 'Sadece kenarlık';

  @override
  String get backgroundBox => 'Yarı saydam kutu';

  @override
  String get backgroundSolid => 'Koyu kutu';

  @override
  String get subtitlePosition => 'Konum';

  @override
  String get positionLow => 'En altta';

  @override
  String get positionMiddle => 'Biraz yukarıda';

  @override
  String get positionHigh => 'Daha yukarıda';

  @override
  String get account => 'Hesap';

  @override
  String get accountInfo => 'Hesap bilgisi';

  @override
  String get details => 'Ayrıntılar';

  @override
  String get accountLoadFailed => 'Hesap bilgisi alınamadı';

  @override
  String get accountStatus => 'Durum';

  @override
  String get accountActive => 'Aktif';

  @override
  String get accountExpired => 'Süresi dolmuş';

  @override
  String get accountBanned => 'Engellenmiş';

  @override
  String get accountDisabled => 'Devre dışı';

  @override
  String get accountTrial => 'Deneme';

  @override
  String get accountExpires => 'Bitiş';

  @override
  String get accountNoEnd => 'Süresiz';

  @override
  String get accountToday => 'bugün bitiyor';

  @override
  String accountDaysLeft(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return '$daysString gün kaldı';
  }

  @override
  String get accountConnections => 'Aynı anda izleme';

  @override
  String accountConnectionsInUse(int active, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Aynı anda en fazla $max cihazda izlenebilir',
      one: 'Aynı anda tek cihazda izlenebilir',
    );
    String _temp1 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: 'Şu an bu hesapta $active yayın açık.',
      zero: 'Şu an bu hesapta açık yayın yok.',
    );
    return '$_temp0. $_temp1';
  }

  @override
  String get accountConnectionsFull => 'Hepsi kullanımda; yeni bir yayın açılmayabilir ya da açık olanı kapatabilir.';

  @override
  String get accountCreated => 'Oluşturulma';

  @override
  String accountEnded(String name) {
    return '$name aboneliğinin süresi doldu.';
  }

  @override
  String accountEndsToday(String name) {
    return '$name aboneliği bugün bitiyor.';
  }

  @override
  String accountEndsInDays(String name, int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$name aboneliği $daysString gün sonra bitiyor.',
      one: '$name aboneliği yarın bitiyor.',
    );
    return '$_temp0';
  }

  @override
  String get sync => 'Senkronizasyon';

  @override
  String get audioDelay => 'Ses';

  @override
  String get audioDelayHint => 'Ses görüntüden önce mi geliyor? + bas';

  @override
  String get subtitleDelay => 'Altyazı';

  @override
  String get subtitleDelayHint => 'Altyazı erken mi çıkıyor? + bas';

  @override
  String get delayNone => '0 sn';

  @override
  String delaySeconds(String value) {
    return '$value sn';
  }

  @override
  String get earlier => 'Daha erken';

  @override
  String get later => 'Daha geç';

  @override
  String get channelLists => 'Kanal listelerim';

  @override
  String get channelListsSubtitle => 'Kendi kanal grupların, istediğin sırayla';

  @override
  String get manageChannelLists => 'Kanal listesi oluştur ve düzenle';

  @override
  String get newList => 'Yeni liste';

  @override
  String get renameList => 'Listeyi yeniden adlandır';

  @override
  String get listNameHint => 'Örneğin Spor veya Haber';

  @override
  String get addToList => 'Listeye ekle';

  @override
  String get listOptions => 'Liste seçenekleri';

  @override
  String get deleteList => 'Listeyi sil';

  @override
  String deleteListTitle(String name) {
    return '$name silinsin mi?';
  }

  @override
  String get deleteListBody => 'Kanallar listende kalır; yalnızca bu liste silinir.';

  @override
  String get removeFromList => 'Listeden çıkar';

  @override
  String get noListsTitle => 'Henüz kanal listen yok';

  @override
  String get noListsMessage => 'Spor, Haber, Çocuk gibi listeler oluştur, sonra bir kanala basılı tutarak ekle.';

  @override
  String get listEmptyTitle => 'Bu liste boş';

  @override
  String get listEmptyMessage => 'Canlı TV\'de bir kanala basılı tutarak buraya ekleyebilirsin.';

  @override
  String get openInOtherApp => 'Başka uygulamada aç';

  @override
  String get openInOtherAppHint => 'VLC, MX Player veya başka bir video oynatıcı';

  @override
  String get noAppToOpen => 'Bu cihazda bu yayını açabilecek bir uygulama yok.';

  @override
  String get accountContent => 'İçerik';

  @override
  String get parentalControl => 'Ebeveyn denetimi';

  @override
  String get setPin => 'PIN belirle';

  @override
  String get changePin => 'PIN\'i değiştir';

  @override
  String get pinNotSet => 'Kategorileri kilitle, açmak için PIN gereksin.';

  @override
  String get pinUnlocked => 'Kilitli kategoriler uygulama yeniden açılana kadar açık.';

  @override
  String get pinLocked => 'Kilitli kategoriler PIN ile açılır.';

  @override
  String get lockNow => 'Şimdi kilitle';

  @override
  String get removePin => 'PIN\'i kaldır';

  @override
  String get removePinSubtitle => 'Kilitli kategoriler PIN sormadan açılır.';

  @override
  String get backup => 'Yedekleme';

  @override
  String get backupToFile => 'Dosyaya yedekle';

  @override
  String get backupToFileSubtitle => 'Listeler, giriş bilgileri, favoriler, izleme geçmişi ve kategoriler';

  @override
  String get restoreFromFile => 'Dosyadan geri yükle';

  @override
  String get restoreFromFileSubtitle => 'Yedekteki listeleri ekler ve kanallarını indirir';

  @override
  String get tvGuide => 'Yayın akışı';

  @override
  String get updateTvGuideNow => 'Yayın akışını şimdi güncelle';

  @override
  String get downloadingGuide => 'Yayın akışı indiriliyor…';

  @override
  String guideUpdateFailed(String error) {
    return 'Güncellenemedi: $error';
  }

  @override
  String get guideNoLink => 'Bu listenin yayın akışı linki yok. Liste menüsünden ekleyebilirsin.';

  @override
  String get guideUpdatesAutomatically => 'Liste yenilenince kendiliğinden güncellenir.';

  @override
  String guideProgramsLoaded(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString program yüklendi';
  }

  @override
  String get about => 'Hakkında';

  @override
  String versionLine(String version) {
    return 'Sürüm $version · GPL-3.0 lisanslı, özgür ve açık kaynak';
  }

  @override
  String get sourceCode => 'Kaynak kodu';

  @override
  String get checkForUpdates => 'Güncellemeleri denetle';

  @override
  String get notifyUpdates => 'Yeni sürümleri haber ver';

  @override
  String get notifyUpdatesSubtitle => 'Uygulama açılınca GitHub\'da yeni sürüm var mı diye bakar.';

  @override
  String get checkingForUpdates => 'Güncellemeler denetleniyor…';

  @override
  String updateAvailable(String version) {
    return 'Tally $version çıktı';
  }

  @override
  String get download => 'İndir';

  @override
  String upToDate(String version) {
    return 'En son sürümü kullanıyorsun ($version).';
  }

  @override
  String get updateCheckFailed => 'GitHub\'a ulaşılamadı. Biraz sonra tekrar dene.';

  @override
  String get disclaimer =>
      'Tally yalnızca bir oynatıcıdır. Hiçbir kanal ya da içerik içermez, satmaz veya tanıtmaz. İzleme hakkın olan listelerle kullan.';

  @override
  String get backupWarning =>
      'Dosyada liste linklerin, kullanıcı adların ve şifrelerin bulunur. Onu güvenli bir yerde sakla.';

  @override
  String get backUp => 'Yedekle';

  @override
  String get saveBackup => 'Yedeği kaydet';

  @override
  String get backupSaved => 'Yedek kaydedildi';

  @override
  String backupFailed(String error) {
    return 'Yedek kaydedilemedi: $error';
  }

  @override
  String get chooseBackup => 'Bir yedek seç';

  @override
  String get readingBackup => 'Yedek okunuyor…';

  @override
  String loadingNamed(String name) {
    return '$name yükleniyor…';
  }

  @override
  String restoreAdded(String playlists) {
    return '$playlists eklendi';
  }

  @override
  String restoreAllPresent(String playlists) {
    return '$playlists zaten uygulamada, bu yüzden yalnızca favoriler, geçmiş ve kategoriler birleştirildi';
  }

  @override
  String restoreSomePresent(int count) {
    return '$count tanesi zaten uygulamada';
  }

  @override
  String restoreSkipped(String names) {
    return 'Atlanan yerel dosyalar: $names';
  }

  @override
  String get restoreEmpty => 'Yedekte hiç liste yok.';

  @override
  String playlistUpdated(String name) {
    return '$name güncellendi';
  }

  @override
  String playlistUpdateFailed(String name, String error) {
    return '$name güncellenemedi: $error';
  }

  @override
  String removePlaylistTitle(String name) {
    return '$name kaldırılsın mı?';
  }

  @override
  String get removePlaylistBody => 'Kanalları, favorileri ve izleme geçmişi bu cihazdan silinir.';

  @override
  String get neverUpdated => 'Hiç güncellenmedi';

  @override
  String updatedOn(String date) {
    return 'Güncellendi: $date';
  }

  @override
  String inUse(String status) {
    return 'Kullanımda · $status';
  }

  @override
  String get playlistOptions => 'Liste seçenekleri';

  @override
  String get updateChannels => 'Kanalları güncelle';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get renamePlaylist => 'Listeyi yeniden adlandır';

  @override
  String get tvGuideLink => 'Yayın akışı linki';

  @override
  String get chooseM3uPlaylist => 'Bir M3U listesi seç';

  @override
  String get chooseFileFirst => 'Önce bir liste dosyası seç.';

  @override
  String get defaultPlaylistName => 'Liste';

  @override
  String get enterValidAddress => 'Geçerli bir adres gir';

  @override
  String get addYourPlaylist => 'Listeni ekle';

  @override
  String get playlistStaysHere =>
      'Listen bu cihazda kalır. Tally kanal sağlamaz. TV sağlayıcından aldığın listeyi kullan.';

  @override
  String get m3uLink => 'M3U linki';

  @override
  String get m3uFile => 'M3U dosyası';

  @override
  String get playlistName => 'Liste adı';

  @override
  String get playlistNameHint => 'Ev';

  @override
  String get advanced => 'Gelişmiş';

  @override
  String get guideLinkField => 'Yayın akışı (XMLTV) linki';

  @override
  String get guideHelpXtream => 'Boş bırakırsan Xtream sunucunun yayın akışı kullanılır.';

  @override
  String get guideHelpM3u => 'Boş bırakırsan listede belirtilen yayın akışı (varsa) kullanılır.';

  @override
  String get loadingChannelsHint => 'Kanallar yükleniyor. Büyük listeler bir dakika sürebilir.';

  @override
  String get playlistLink => 'Liste linki';

  @override
  String get playlistFile => 'Liste dosyası';

  @override
  String get chooseM3uFile => '.m3u dosyası seç';

  @override
  String get serverUrl => 'Sunucu adresi';

  @override
  String get username => 'Kullanıcı adı';

  @override
  String get password => 'Şifre';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get stageDownloadPlaylist => 'Liste indiriliyor';

  @override
  String get stageConnect => 'Sunucuya bağlanılıyor';

  @override
  String get stageSave => 'Bu cihaza kaydediliyor';

  @override
  String get loadingYourPlaylist => 'Listen yükleniyor';

  @override
  String loadingPlaylist(String name) {
    return '$name yükleniyor';
  }

  @override
  String get keepAppOpen => 'Büyük listeler bir dakika sürebilir. Uygulamayı açık tut.';

  @override
  String get watchHistory => 'İzleme geçmişi';

  @override
  String get historyEmptyTitle => 'Henüz bir şey izlemedin';

  @override
  String get historyEmptyMessage => 'İzlediğin kanallar ve başladığın filmler ile diziler burada görünür.';

  @override
  String get favoritesEmptyTitle => 'Henüz favori yok';

  @override
  String get favoritesEmptyMessage => 'Bir kanalı, filmi ya da diziyi buraya eklemek için yıldızına dokun.';

  @override
  String get favoriteChannels => 'Favori kanallar';

  @override
  String get favoriteMoviesAndSeries => 'Favori filmler ve diziler';

  @override
  String get recentChannels => 'Son izlenen kanallar';

  @override
  String get clearHistory => 'Geçmişi temizle';

  @override
  String get clearHistoryTitle => 'İzleme geçmişi temizlensin mi?';

  @override
  String get clearHistoryBody => 'Bu listedeki son izlenen kanallar ve yarım kalan filmler ile diziler silinir.';

  @override
  String get clear => 'Temizle';

  @override
  String get continueWatching => 'İzlemeye devam et';

  @override
  String get searchHint => 'Kanal, film ve dizi ara';

  @override
  String get searchEverything => 'Her yerde ara';

  @override
  String get searchMinLetters => 'Kanal, film ya da dizi adından en az iki harf yaz.';

  @override
  String nothingMatches(String query) {
    return '\"$query\" ile eşleşen bir şey yok';
  }

  @override
  String get noFavoriteMovies => 'Henüz favori film yok';

  @override
  String get noFavoriteSeries => 'Henüz favori dizi yok';

  @override
  String get noMoviesInPlaylist => 'Bu listede film yok';

  @override
  String get noSeriesInPlaylist => 'Bu listede dizi yok';

  @override
  String get playlistHasNoMovies => 'Listende film yok. Xtream Codes hesaplarında genelde bulunur.';

  @override
  String get playlistHasNoSeries => 'Listende dizi yok. Xtream Codes hesaplarında genelde bulunur.';

  @override
  String get noFavoriteChannels => 'Henüz favori kanal yok';

  @override
  String get noChannelsHere => 'Burada kanal yok';

  @override
  String get favoriteChannelsHint => 'Burada tutmak için kanalın yanındaki yıldıza dokun.';

  @override
  String get addToFavorites => 'Favorilere ekle';

  @override
  String get removeFromFavorites => 'Favorilerden çıkar';

  @override
  String get inFavorites => 'Favorilerde';

  @override
  String get closeSearch => 'Aramayı kapat';

  @override
  String get sort => 'Sırala';

  @override
  String get sortPlaylist => 'Liste sırası';

  @override
  String get sortNumber => 'Kanal numarası';

  @override
  String get sortNameAsc => 'Ad A–Z';

  @override
  String get sortNameDesc => 'Ad Z–A';

  @override
  String get sortRating => 'En yüksek puan';

  @override
  String get sortYear => 'Önce en yeni';

  @override
  String get switchPlaylist => 'Liste değiştir';

  @override
  String get enterPin => 'PIN\'i gir';

  @override
  String get chooseFourDigitPin => '4 haneli bir PIN seç';

  @override
  String get enterPinAgain => 'PIN\'i tekrar gir';

  @override
  String get pinUseFourDigits => '4 hane gir.';

  @override
  String get pinsDontMatch => 'PIN\'ler eşleşmiyor.';

  @override
  String get wrongPin => 'Yanlış PIN.';

  @override
  String get noAdultCategories => 'Bu listede yetişkin kategorisi bulunamadı.';

  @override
  String lockedCategories(int count) {
    return '$count kategori kilitlendi';
  }

  @override
  String get lockAdultCategories => 'Yetişkin kategorilerini kilitle';

  @override
  String get showAllRestoreOrder => 'Hepsini göster ve sırayı sıfırla';

  @override
  String get categoriesHelp => 'Sıralamak için sürükle. Gizlenen kategoriler listelerden kalkar, kilitliler PIN ister.';

  @override
  String get noCategoriesHere => 'Burada kategori yok';

  @override
  String get uncategorized => 'Kategorisiz';

  @override
  String get unlock => 'Kilidi aç';

  @override
  String get lockWithPin => 'PIN ile kilitle';

  @override
  String get all => 'Tümü';

  @override
  String get favorites => 'Favoriler';

  @override
  String get manageCategories => 'Kategorileri yönet';

  @override
  String get findCategory => 'Kategori bul';

  @override
  String noCategoryMatches(String query) {
    return '\"$query\" ile eşleşen kategori yok';
  }

  @override
  String get director => 'Yönetmen';

  @override
  String get cast => 'Oyuncular';

  @override
  String resumeFrom(String time) {
    return '$time noktasından devam et';
  }

  @override
  String get startOver => 'Baştan başlat';

  @override
  String get noDescription => 'Açıklama yok.';

  @override
  String episodeCode(int season, int episode) {
    return 'S$season · B$episode';
  }

  @override
  String playEpisode(String episode) {
    return '$episode oynat';
  }

  @override
  String continueEpisode(String episode) {
    return '$episode devam et';
  }

  @override
  String seasonNumber(int number) {
    return '$number. Sezon';
  }

  @override
  String get noEpisodes => 'Bölüm yok';

  @override
  String get closeChannelList => 'Kanal listesini kapat';

  @override
  String get streamCouldNotPlay => 'Bu yayın oynatılamadı';

  @override
  String nextProgram(String time, String title) {
    return 'Sonra  $time  $title';
  }

  @override
  String noChannelNumber(String number) {
    return '$number numaralı kanal yok';
  }

  @override
  String nextEpisodeIn(int seconds) {
    return 'Sonraki bölüm $seconds sn sonra';
  }

  @override
  String get playNow => 'Şimdi oynat';

  @override
  String get speedNormal => 'Normal';

  @override
  String get pictureSize => 'Görüntü boyutu';

  @override
  String get pictureSizeSmallPlayer =>
      'Farkı tam ekranda görürsün. Küçük oynatıcı orijinal oranı korur, bu yüzden çoğu video burada aynı görünür.';

  @override
  String get fitFit => 'Sığdır';

  @override
  String get fitFill => 'Ekranı doldur';

  @override
  String get fitStretch => 'Uzat';

  @override
  String get aspectRatio => 'Görüntü oranı';

  @override
  String get aspectOriginal => 'Orijinal';

  @override
  String get aspectRatioHintChannel => 'Basık ya da uzamış görünen kanallar için. Bu kanal için hatırlanır.';

  @override
  String get aspectRatioHintVideo => 'Basık ya da uzamış görünen videolar için. Bu yapım için hatırlanır.';

  @override
  String get playbackSpeed => 'Oynatma hızı';

  @override
  String get sleepTimer => 'Uyku zamanlayıcısı';

  @override
  String stopsIn(String time) {
    return '$time sonra durur';
  }

  @override
  String get pictureInPicture => 'Resim içinde resim';

  @override
  String get pictureInPictureHint => 'Küçük bir pencerede izlemeye devam et. Ana ekran tuşu da bunu yapar.';

  @override
  String get playerOptions => 'Oynatıcı seçenekleri';

  @override
  String get previousChannel => 'Önceki kanal';

  @override
  String get nextChannel => 'Sonraki kanal';

  @override
  String get streamInfo => 'Yayın bilgisi';

  @override
  String get streamInfoHint => 'Çözünürlük, codec ve bit hızı görüntünün üstünde. Klavyede I tuşu.';

  @override
  String get infoVideo => 'Görüntü';

  @override
  String get infoBitrate => 'Bit hızı';

  @override
  String get infoBuffer => 'Tampon';

  @override
  String get infoDecoder => 'Kod çözücü';

  @override
  String get infoHardware => 'donanım';

  @override
  String get infoSoftware => 'yazılım';

  @override
  String backToChannel(String channel) {
    return '$channel kanalına dön';
  }

  @override
  String get back10 => '10 saniye geri';

  @override
  String get forward10 => '10 saniye ileri';

  @override
  String get pause => 'Duraklat';

  @override
  String get fullScreen => 'Tam ekran';

  @override
  String get exitFullScreen => 'Tam ekrandan çık';

  @override
  String trackNumber(int number) {
    return 'Parça $number';
  }

  @override
  String get audioMono => 'Mono';

  @override
  String get audioStereo => 'Stereo';

  @override
  String audioChannels(int count) {
    return '$count kanal';
  }

  @override
  String get audio => 'Ses';

  @override
  String get playing => 'Oynatılıyor';

  @override
  String moreFrom(String group) {
    return '$group kategorisinden';
  }

  @override
  String get noGuideData => 'Bu kanal için yayın akışı yok.';

  @override
  String get now => 'Şimdi';

  @override
  String get upNext => 'Sıradaki';

  @override
  String get pastPrograms => 'Geçmiş yayınlar';

  @override
  String pastProgramsOf(String channel) {
    return 'Geçmiş yayınlar · $channel';
  }

  @override
  String get noPastPrograms => 'Bu kanalın şu an izlenebilecek kaydı yok.';

  @override
  String get backToLive => 'Canlıya dön';

  @override
  String get doubleTapFullScreenTip =>
      'İpucu: Tam ekran için videoya iki kez dokun, bu panele dönmek için yine iki kez dokun.';

  @override
  String get today => 'Bugün';

  @override
  String get yesterday => 'Dün';

  @override
  String get hasArchive => 'Geçmiş yayınlar izlenebilir';

  @override
  String get errNoContent => 'Bu hesapta kanal, film veya dizi yok.';

  @override
  String get errNoChannelsInM3u => 'Bu listede kanal bulunamadı. Linkin bir M3U dosyasını gösterdiğinden emin ol.';

  @override
  String get errProviderNoGuide =>
      'Sağlayıcın yayın akışı sunmuyor. Liste menüsünden bir yayın akışı (XMLTV) linki ekleyebilirsin.';

  @override
  String get errGuideLinkNotFound => 'Yayın akışı linki bulunamadı. Liste menüsündeki linki kontrol et.';

  @override
  String get errGuideUnreachable => 'Yayın akışı sunucusuna ulaşılamadı. Bağlantını kontrol et.';

  @override
  String errGuideDownload(String detail) {
    return 'Yayın akışı indirilemedi ($detail).';
  }

  @override
  String get errServerUnreachable => 'Sunucuya ulaşılamadı. Adresi ve internet bağlantını kontrol et.';

  @override
  String get errSecureConnection => 'Güvenli bağlantı kurulamadı. Adresi https:// yerine http:// ile dene.';

  @override
  String errConnectionFailed(String error) {
    return 'Bağlantı kurulamadı: $error';
  }

  @override
  String get errTimeout => 'Sunucu çok geç yanıt verdi. Biraz sonra tekrar dene.';

  @override
  String get errFullLink => 'http:// veya https:// ile başlayan tam bir liste linki gir.';

  @override
  String errAccessRefused(int code) {
    return 'Sunucu erişimi reddetti ($code). Aboneliğinin aktif olduğundan emin ol.';
  }

  @override
  String errHttpStatus(int code) {
    return 'Sunucu $code hatası döndürdü.';
  }

  @override
  String get errInvalidXtream => 'Sunucu geçerli Xtream verisi döndürmedi.';

  @override
  String get errLoginRejected => 'Sunucu kullanıcı adını veya şifreyi kabul etmedi.';

  @override
  String errAccountStatus(String status) {
    return 'Bu hesabın durumu: $status.';
  }

  @override
  String get errNotBackup => 'Bu dosya bir Tally yedeği değil.';

  @override
  String get cleanupTitle => 'Listeni düzenle';

  @override
  String get cleanupMenu => 'Listeyi düzenle';

  @override
  String cleanupIntro(int count) {
    return 'Bu listede $count ülkeden kanal var. Görmek istediklerini seç. Hiçbirini seçmezsen hepsi kalır.';
  }

  @override
  String get cleanupIntroNoCountries => 'Bu listenin neleri göstereceğini seç.';

  @override
  String get cleanupCountries => 'Ülkeler';

  @override
  String cleanupCountryCount(String name, String count) {
    return '$name · $count';
  }

  @override
  String get cleanupNoCountryNote =>
      'Ülke belirtmeyen kategoriler, örneğin çoğu film ve dizi kategorisi, her zaman kalır.';

  @override
  String get cleanupHideAdult => 'Yetişkin kategorileri gizle';

  @override
  String cleanupAdultFound(String names) {
    return 'Kategori adından bulunanlar: $names';
  }

  @override
  String get cleanupLater => 'Bunu istediğin zaman Ayarlar › Kategoriler\'den değiştirebilirsin.';

  @override
  String get cleanupSave => 'Kaydet';

  @override
  String get cleanupSkip => 'Hepsini göster';

  @override
  String cleanupDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kategori gizlendi',
      zero: 'Hiçbir şey gizlenmedi',
    );
    return '$_temp0';
  }

  @override
  String get streamCopies => 'Kalite';

  @override
  String copyFallback(String from, String to) {
    return '$from açılmadı, $to deneniyor';
  }

  @override
  String get streamTimedOut => 'Yayın başlamadı. Sağlayıcı görüntü göndermiyor.';

  @override
  String copiesCount(int count) {
    return '$count kalite';
  }

  @override
  String get streamFailing => 'Son denemelerde açılmadı';

  @override
  String get mergeCopiesTitle => 'Kanal kopyalarını birleştir';

  @override
  String get mergeCopiesSubtitle =>
      'HD, SD ve Full HD kopyalar tek kanal olarak görünür. En iyisi açılır, açılmazsa sıradaki denenir.';

  @override
  String get audioOnly => 'Sadece ses';

  @override
  String get audioOnlyHint =>
      'Görüntüyü kapatır, ekran kapalıyken de çalmaya devam eder. Pil tasarrufu sağlar; sağlayıcı yine de tüm yayını gönderir.';

  @override
  String get audioOnlyOn => 'Sadece ses';

  @override
  String get stop => 'Durdur';

  @override
  String get mobileDataNotice => 'Mobil verideysin. Canlı yayın saatte yaklaşık 1–3 GB harcar.';

  @override
  String get warnMobileDataTitle => 'Mobil veride uyar';

  @override
  String get warnMobileDataSubtitle => 'Wi-Fi olmadan bir yayın başlayınca kısa bir uyarı gösterir.';
}
