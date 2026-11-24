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
  String noChannelsMatch(String query) {
    return '\"$query\" ile eşleşen kanal yok';
  }

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
}
