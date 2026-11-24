// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get ok => 'OK';

  @override
  String get remove => 'Remove';

  @override
  String get tryAgain => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get off => 'Off';

  @override
  String get play => 'Play';

  @override
  String get required => 'Required';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get more => 'More';

  @override
  String get search => 'Search';

  @override
  String get live => 'Live';

  @override
  String get unknownError => 'unknown error';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get liveTv => 'Live TV';

  @override
  String get movies => 'Movies';

  @override
  String get series => 'Series';

  @override
  String get library => 'Library';

  @override
  String get settings => 'Settings';

  @override
  String get channels => 'Channels';

  @override
  String get categories => 'Categories';

  @override
  String libraryOpenFailed(String error) {
    return 'Could not open the library: $error';
  }

  @override
  String playlistsAutoUpdated(String names) {
    return 'Updated $names';
  }

  @override
  String channelCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString channels', one: '1 channel');
    return '$_temp0';
  }

  @override
  String movieCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString movies', one: '1 movie');
    return '$_temp0';
  }

  @override
  String seriesCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString series';
  }

  @override
  String playlistCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString playlists',
      one: '1 playlist',
    );
    return '$_temp0';
  }

  @override
  String seasonCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString seasons', one: '1 season');
    return '$_temp0';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String timerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String timerHours(int hours) {
    return '$hours h';
  }

  @override
  String timerHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String get playlists => 'Playlists';

  @override
  String get addPlaylist => 'Add playlist';

  @override
  String get autoRefreshTitle => 'Update playlists automatically';

  @override
  String get autoRefreshSubtitle => 'When the app opens, lists older than a day are refreshed.';

  @override
  String get categoriesSubtitle => 'Hide, lock or reorder categories';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get playback => 'Playback';

  @override
  String get autoNextTitle => 'Play next episode automatically';

  @override
  String get audioLanguage => 'Audio language';

  @override
  String get audioLanguageDefault => 'Stream default. Pick a language in the player and it\'s used from then on.';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get subtitlesDefault => 'Stream default. Pick subtitles in the player and they\'re used from then on.';

  @override
  String tapForStreamDefault(String choice) {
    return '$choice · tap to go back to the stream default';
  }

  @override
  String get subtitleStyle => 'Subtitle style';

  @override
  String get subtitleStyleSubtitle => 'Size, background and position';

  @override
  String get subtitleSample => 'This is how subtitles will look.';

  @override
  String get subtitleSize => 'Size';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get sizeHuge => 'Very large';

  @override
  String get subtitleBackground => 'Background';

  @override
  String get backgroundNone => 'Outline only';

  @override
  String get backgroundBox => 'See-through box';

  @override
  String get backgroundSolid => 'Dark box';

  @override
  String get subtitlePosition => 'Position';

  @override
  String get positionLow => 'Bottom';

  @override
  String get positionMiddle => 'A little higher';

  @override
  String get positionHigh => 'Higher';

  @override
  String get account => 'Account';

  @override
  String get accountInfo => 'Account info';

  @override
  String get details => 'Details';

  @override
  String get accountLoadFailed => 'Couldn\'t load the account';

  @override
  String get accountStatus => 'Status';

  @override
  String get accountActive => 'Active';

  @override
  String get accountExpired => 'Expired';

  @override
  String get accountBanned => 'Banned';

  @override
  String get accountDisabled => 'Disabled';

  @override
  String get accountTrial => 'Trial';

  @override
  String get accountExpires => 'Ends';

  @override
  String get accountNoEnd => 'Doesn\'t run out';

  @override
  String get accountToday => 'ends today';

  @override
  String accountDaysLeft(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$daysString days left', one: '1 day left');
    return '$_temp0';
  }

  @override
  String get accountConnections => 'Connections';

  @override
  String accountConnectionsInUse(int active, int max) {
    return '$active of $max in use';
  }

  @override
  String get accountCreated => 'Created';

  @override
  String accountEnded(String name) {
    return 'The subscription for $name has ended.';
  }

  @override
  String accountEndsToday(String name) {
    return 'The subscription for $name ends today.';
  }

  @override
  String accountEndsInDays(String name, int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'The subscription for $name ends in $daysString days.',
      one: 'The subscription for $name ends tomorrow.',
    );
    return '$_temp0';
  }

  @override
  String get sync => 'Sync';

  @override
  String get audioDelay => 'Sound';

  @override
  String get audioDelayHint => 'Sound ahead of the picture? Press +';

  @override
  String get subtitleDelay => 'Subtitles';

  @override
  String get subtitleDelayHint => 'Subtitles too early? Press +';

  @override
  String get delayNone => '0 s';

  @override
  String delaySeconds(String value) {
    return '$value s';
  }

  @override
  String get earlier => 'Earlier';

  @override
  String get later => 'Later';

  @override
  String get channelLists => 'My channel lists';

  @override
  String get channelListsSubtitle => 'Your own groups of channels, in your order';

  @override
  String get manageChannelLists => 'Make and edit channel lists';

  @override
  String get newList => 'New list';

  @override
  String get renameList => 'Rename list';

  @override
  String get listNameHint => 'For example Sports or News';

  @override
  String get addToList => 'Add to a list';

  @override
  String get listOptions => 'List options';

  @override
  String get deleteList => 'Delete list';

  @override
  String deleteListTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteListBody => 'The channels stay in your playlist; only this list goes.';

  @override
  String get removeFromList => 'Take out of this list';

  @override
  String get noListsTitle => 'No channel lists yet';

  @override
  String get noListsMessage => 'Make lists like Sports, News or Kids, then touch and hold a channel to add it.';

  @override
  String get listEmptyTitle => 'This list is empty';

  @override
  String get listEmptyMessage => 'Touch and hold a channel in Live TV to add it here.';

  @override
  String get openInOtherApp => 'Open in another app';

  @override
  String get openInOtherAppHint => 'VLC, MX Player or another video player';

  @override
  String get noAppToOpen => 'No app on this device can play this stream.';

  @override
  String get accountContent => 'Content';

  @override
  String get parentalControl => 'Parental control';

  @override
  String get setPin => 'Set a PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get pinNotSet => 'Lock categories so they need a PIN to open.';

  @override
  String get pinUnlocked => 'Locked categories are open until the app restarts.';

  @override
  String get pinLocked => 'Locked categories need the PIN to open.';

  @override
  String get lockNow => 'Lock now';

  @override
  String get removePin => 'Remove PIN';

  @override
  String get removePinSubtitle => 'Locked categories open without a PIN.';

  @override
  String get backup => 'Backup';

  @override
  String get backupToFile => 'Back up to a file';

  @override
  String get backupToFileSubtitle => 'Playlists, logins, favorites, watch history and categories';

  @override
  String get restoreFromFile => 'Restore from a file';

  @override
  String get restoreFromFileSubtitle => 'Adds the playlists from a backup and downloads their channels';

  @override
  String get tvGuide => 'TV guide';

  @override
  String get updateTvGuideNow => 'Update TV guide now';

  @override
  String get downloadingGuide => 'Downloading guide…';

  @override
  String guideUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get guideNoLink => 'No guide link for this playlist. Add one from the playlist menu.';

  @override
  String get guideUpdatesAutomatically => 'Updates automatically when a playlist is refreshed.';

  @override
  String guideProgramsLoaded(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString programs loaded';
  }

  @override
  String get about => 'About';

  @override
  String versionLine(String version) {
    return 'Version $version · Free and open source under GPL-3.0';
  }

  @override
  String get sourceCode => 'Source code';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get notifyUpdates => 'Tell me about new versions';

  @override
  String get notifyUpdatesSubtitle => 'Looks for a new release on GitHub when the app opens.';

  @override
  String get checkingForUpdates => 'Checking for updates…';

  @override
  String updateAvailable(String version) {
    return 'Tally $version is available';
  }

  @override
  String get download => 'Download';

  @override
  String upToDate(String version) {
    return 'You have the latest version ($version).';
  }

  @override
  String get updateCheckFailed => 'Couldn\'t reach GitHub. Try again later.';

  @override
  String get disclaimer =>
      'Tally is a player only. It does not include, sell or promote any channels or content. Use it with playlists you are allowed to watch.';

  @override
  String get backupWarning =>
      'The file includes your playlist links, usernames and passwords. Keep it somewhere private.';

  @override
  String get backUp => 'Back up';

  @override
  String get saveBackup => 'Save backup';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String backupFailed(String error) {
    return 'Couldn\'t save the backup: $error';
  }

  @override
  String get chooseBackup => 'Choose a backup';

  @override
  String get readingBackup => 'Reading backup…';

  @override
  String loadingNamed(String name) {
    return 'Loading $name…';
  }

  @override
  String restoreAdded(String playlists) {
    return 'Added $playlists';
  }

  @override
  String restoreAllPresent(String playlists) {
    return '$playlists already in the app, so only favorites, history and categories were merged';
  }

  @override
  String restoreSomePresent(int count) {
    return '$count already in the app';
  }

  @override
  String restoreSkipped(String names) {
    return 'Skipped local files: $names';
  }

  @override
  String get restoreEmpty => 'The backup has no playlists.';

  @override
  String playlistUpdated(String name) {
    return '$name updated';
  }

  @override
  String playlistUpdateFailed(String name, String error) {
    return 'Couldn\'t update $name: $error';
  }

  @override
  String removePlaylistTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removePlaylistBody => 'Its channels, favorites and watch history are removed from this device.';

  @override
  String get neverUpdated => 'Never updated';

  @override
  String updatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String inUse(String status) {
    return 'In use · $status';
  }

  @override
  String get playlistOptions => 'Playlist options';

  @override
  String get updateChannels => 'Update channels';

  @override
  String get rename => 'Rename';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get tvGuideLink => 'TV guide link';

  @override
  String get chooseM3uPlaylist => 'Choose an M3U playlist';

  @override
  String get chooseFileFirst => 'Choose a playlist file first.';

  @override
  String get defaultPlaylistName => 'Playlist';

  @override
  String get enterValidAddress => 'Enter a valid address';

  @override
  String get addYourPlaylist => 'Add your playlist';

  @override
  String get playlistStaysHere =>
      'Your playlist stays on this device. Tally doesn\'t provide any channels. Use a playlist from your TV provider.';

  @override
  String get m3uLink => 'M3U link';

  @override
  String get m3uFile => 'M3U file';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get playlistNameHint => 'Home';

  @override
  String get advanced => 'Advanced';

  @override
  String get guideLinkField => 'TV guide (XMLTV) link';

  @override
  String get guideHelpXtream => 'Leave empty to use the guide from your Xtream server.';

  @override
  String get guideHelpM3u => 'Leave empty to use the guide named in the playlist, if any.';

  @override
  String get loadingChannelsHint => 'Loading channels. Large playlists can take a minute.';

  @override
  String get playlistLink => 'Playlist link';

  @override
  String get playlistFile => 'Playlist file';

  @override
  String get chooseM3uFile => 'Choose .m3u file';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get stageDownloadPlaylist => 'Downloading playlist';

  @override
  String get stageConnect => 'Connecting to server';

  @override
  String get stageSave => 'Saving to this device';

  @override
  String get loadingYourPlaylist => 'Loading your playlist';

  @override
  String loadingPlaylist(String name) {
    return 'Loading $name';
  }

  @override
  String get keepAppOpen => 'Large playlists can take a minute. Keep the app open.';

  @override
  String get watchHistory => 'History';

  @override
  String get historyEmptyTitle => 'Nothing watched yet';

  @override
  String get historyEmptyMessage => 'Channels you watch and movies or series you start show up here.';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyMessage => 'Tap the star on any channel, movie or series to add it here.';

  @override
  String get favoriteChannels => 'Favorite channels';

  @override
  String get favoriteMoviesAndSeries => 'Favorite movies and series';

  @override
  String get recentChannels => 'Recently watched channels';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryTitle => 'Clear watch history?';

  @override
  String get clearHistoryBody => 'Recently watched channels and continue watching are cleared for this playlist.';

  @override
  String get clear => 'Clear';

  @override
  String get continueWatching => 'Continue watching';

  @override
  String get searchHint => 'Search channels, movies and series';

  @override
  String get searchEverything => 'Search everything';

  @override
  String get searchMinLetters => 'Type at least two letters of a channel, movie or series name.';

  @override
  String nothingMatches(String query) {
    return 'Nothing matches \"$query\"';
  }

  @override
  String get noFavoriteMovies => 'No favorite movies yet';

  @override
  String get noFavoriteSeries => 'No favorite series yet';

  @override
  String get noMoviesInPlaylist => 'No movies in this playlist';

  @override
  String get noSeriesInPlaylist => 'No series in this playlist';

  @override
  String get playlistHasNoMovies => 'Your playlist doesn\'t include movies. Xtream Codes accounts usually do.';

  @override
  String get playlistHasNoSeries => 'Your playlist doesn\'t include series. Xtream Codes accounts usually do.';

  @override
  String noChannelsMatch(String query) {
    return 'No channels match \"$query\"';
  }

  @override
  String get noFavoriteChannels => 'No favorite channels yet';

  @override
  String get noChannelsHere => 'No channels here';

  @override
  String get favoriteChannelsHint => 'Tap the star next to a channel to keep it here.';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get inFavorites => 'In favorites';

  @override
  String get closeSearch => 'Close search';

  @override
  String get sort => 'Sort';

  @override
  String get sortPlaylist => 'Playlist order';

  @override
  String get sortNumber => 'Channel number';

  @override
  String get sortNameAsc => 'Name A–Z';

  @override
  String get sortNameDesc => 'Name Z–A';

  @override
  String get sortRating => 'Highest rated';

  @override
  String get sortYear => 'Newest first';

  @override
  String get switchPlaylist => 'Switch playlist';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get chooseFourDigitPin => 'Choose a 4-digit PIN';

  @override
  String get enterPinAgain => 'Enter the PIN again';

  @override
  String get pinUseFourDigits => 'Use 4 digits.';

  @override
  String get pinsDontMatch => 'The PINs don\'t match.';

  @override
  String get wrongPin => 'Wrong PIN.';

  @override
  String get noAdultCategories => 'No adult categories found in this list.';

  @override
  String lockedCategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Locked $count categories',
      one: 'Locked 1 category',
    );
    return '$_temp0';
  }

  @override
  String get lockAdultCategories => 'Lock adult categories';

  @override
  String get showAllRestoreOrder => 'Show all and restore order';

  @override
  String get categoriesHelp =>
      'Drag to reorder. Hidden categories disappear from the lists; locked ones need your PIN.';

  @override
  String get noCategoriesHere => 'No categories here';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get unlock => 'Unlock';

  @override
  String get lockWithPin => 'Lock with PIN';

  @override
  String get all => 'All';

  @override
  String get favorites => 'Favorites';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get findCategory => 'Find a category';

  @override
  String noCategoryMatches(String query) {
    return 'No category matches \"$query\"';
  }

  @override
  String get director => 'Director';

  @override
  String get cast => 'Cast';

  @override
  String resumeFrom(String time) {
    return 'Resume from $time';
  }

  @override
  String get startOver => 'Start over';

  @override
  String get noDescription => 'No description available.';

  @override
  String episodeCode(int season, int episode) {
    return 'S$season · E$episode';
  }

  @override
  String playEpisode(String episode) {
    return 'Play $episode';
  }

  @override
  String continueEpisode(String episode) {
    return 'Continue $episode';
  }

  @override
  String seasonNumber(int number) {
    return 'Season $number';
  }

  @override
  String get noEpisodes => 'No episodes available';

  @override
  String get closeChannelList => 'Close channel list';

  @override
  String get streamCouldNotPlay => 'This stream could not be played';

  @override
  String nextProgram(String time, String title) {
    return 'Next  $time  $title';
  }

  @override
  String noChannelNumber(String number) {
    return 'No channel $number';
  }

  @override
  String nextEpisodeIn(int seconds) {
    return 'Next episode in $seconds s';
  }

  @override
  String get playNow => 'Play now';

  @override
  String get speedNormal => 'Normal';

  @override
  String get pictureSize => 'Picture size';

  @override
  String get pictureSizeSmallPlayer =>
      'You see the difference in full screen. The small player keeps the original shape, so most videos look the same here.';

  @override
  String get fitFit => 'Fit';

  @override
  String get fitFill => 'Fill screen';

  @override
  String get fitStretch => 'Stretch';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String stopsIn(String time) {
    return 'Stops in $time';
  }

  @override
  String get pictureInPicture => 'Picture in picture';

  @override
  String get pictureInPictureHint => 'Keep watching in a small window. Pressing Home does this too.';

  @override
  String get playerOptions => 'Player options';

  @override
  String get previousChannel => 'Previous channel';

  @override
  String get nextChannel => 'Next channel';

  @override
  String get streamInfo => 'Stream info';

  @override
  String get streamInfoHint => 'Resolution, codecs and bitrate over the video. I key on a keyboard.';

  @override
  String get infoVideo => 'Video';

  @override
  String get infoBitrate => 'Bitrate';

  @override
  String get infoBuffer => 'Buffer';

  @override
  String get infoDecoder => 'Decoder';

  @override
  String get infoHardware => 'hardware';

  @override
  String get infoSoftware => 'software';

  @override
  String backToChannel(String channel) {
    return 'Back to $channel';
  }

  @override
  String get back10 => 'Back 10 seconds';

  @override
  String get forward10 => 'Forward 10 seconds';

  @override
  String get pause => 'Pause';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String trackNumber(int number) {
    return 'Track $number';
  }

  @override
  String get audioMono => 'Mono';

  @override
  String get audioStereo => 'Stereo';

  @override
  String audioChannels(int count) {
    return '$count ch';
  }

  @override
  String get audio => 'Audio';

  @override
  String get playing => 'Playing';

  @override
  String moreFrom(String group) {
    return 'More from $group';
  }

  @override
  String get noGuideData => 'No guide data for this channel.';

  @override
  String get now => 'Now';

  @override
  String get upNext => 'Up next';

  @override
  String get pastPrograms => 'Past programs';

  @override
  String pastProgramsOf(String channel) {
    return 'Past programs · $channel';
  }

  @override
  String get noPastPrograms => 'No recordings are available for this channel right now.';

  @override
  String get backToLive => 'Back to live';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get hasArchive => 'Past programs available';

  @override
  String get errNoContent => 'This account has no channels, movies or series.';

  @override
  String get errNoChannelsInM3u =>
      'No channels were found in this playlist. Check that the link points to an M3U file.';

  @override
  String get errProviderNoGuide =>
      'Your provider doesn\'t offer a TV guide. You can add a guide (XMLTV) link from the playlist menu.';

  @override
  String get errGuideLinkNotFound => 'The guide link was not found. Check the link in the playlist menu.';

  @override
  String get errGuideUnreachable => 'Could not reach the guide server. Check your connection.';

  @override
  String errGuideDownload(String detail) {
    return 'Guide download failed ($detail).';
  }

  @override
  String get errServerUnreachable => 'Could not reach the server. Check the address and your internet connection.';

  @override
  String get errSecureConnection => 'Secure connection failed. Try the address with http:// instead of https://.';

  @override
  String errConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get errTimeout => 'The server took too long to answer. Try again in a moment.';

  @override
  String get errFullLink => 'Enter a full playlist link starting with http:// or https://.';

  @override
  String errAccessRefused(int code) {
    return 'The server refused access ($code). Check that your subscription is active.';
  }

  @override
  String errHttpStatus(int code) {
    return 'The server responded with error $code.';
  }

  @override
  String get errInvalidXtream => 'The server did not return valid Xtream data.';

  @override
  String get errLoginRejected => 'Username or password was rejected by the server.';

  @override
  String errAccountStatus(String status) {
    return 'This account is $status.';
  }

  @override
  String get errNotBackup => 'This file is not a Tally backup.';
}
