import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('tr')];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get unknownError;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @liveTv.
  ///
  /// In en, this message translates to:
  /// **'Live TV'**
  String get liveTv;

  /// No description provided for @movies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get movies;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @libraryOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the library: {error}'**
  String libraryOpenFailed(String error);

  /// No description provided for @playlistsAutoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {names}'**
  String playlistsAutoUpdated(String names);

  /// No description provided for @channelCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 channel} other{{count} channels}}'**
  String channelCount(int count);

  /// No description provided for @movieCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 movie} other{{count} movies}}'**
  String movieCount(int count);

  /// No description provided for @seriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} series'**
  String seriesCount(int count);

  /// No description provided for @playlistCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 playlist} other{{count} playlists}}'**
  String playlistCount(int count);

  /// No description provided for @seasonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 season} other{{count} seasons}}'**
  String seasonCount(int count);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(int minutes);

  /// No description provided for @timerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String timerMinutes(int minutes);

  /// No description provided for @timerHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String timerHours(int hours);

  /// No description provided for @timerHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String timerHoursMinutes(int hours, int minutes);

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeLeft(String time);

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @addPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add playlist'**
  String get addPlaylist;

  /// No description provided for @autoRefreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Update playlists automatically'**
  String get autoRefreshTitle;

  /// No description provided for @autoRefreshSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When the app opens, lists older than a day are refreshed.'**
  String get autoRefreshSubtitle;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide, lock or reorder categories'**
  String get categoriesSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @autoNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Play next episode automatically'**
  String get autoNextTitle;

  /// No description provided for @audioLanguage.
  ///
  /// In en, this message translates to:
  /// **'Audio language'**
  String get audioLanguage;

  /// No description provided for @audioLanguageDefault.
  ///
  /// In en, this message translates to:
  /// **'Stream default. Pick a language in the player and it\'s used from then on.'**
  String get audioLanguageDefault;

  /// No description provided for @subtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitles;

  /// No description provided for @subtitlesDefault.
  ///
  /// In en, this message translates to:
  /// **'Stream default. Pick subtitles in the player and they\'re used from then on.'**
  String get subtitlesDefault;

  /// No description provided for @tapForStreamDefault.
  ///
  /// In en, this message translates to:
  /// **'{choice} · tap to go back to the stream default'**
  String tapForStreamDefault(String choice);

  /// No description provided for @parentalControl.
  ///
  /// In en, this message translates to:
  /// **'Parental control'**
  String get parentalControl;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get setPin;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @pinNotSet.
  ///
  /// In en, this message translates to:
  /// **'Lock categories so they need a PIN to open.'**
  String get pinNotSet;

  /// No description provided for @pinUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Locked categories are open until the app restarts.'**
  String get pinUnlocked;

  /// No description provided for @pinLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked categories need the PIN to open.'**
  String get pinLocked;

  /// No description provided for @lockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get lockNow;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get removePin;

  /// No description provided for @removePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Locked categories open without a PIN.'**
  String get removePinSubtitle;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @backupToFile.
  ///
  /// In en, this message translates to:
  /// **'Back up to a file'**
  String get backupToFile;

  /// No description provided for @backupToFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists, logins, favorites, watch history and categories'**
  String get backupToFileSubtitle;

  /// No description provided for @restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from a file'**
  String get restoreFromFile;

  /// No description provided for @restoreFromFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds the playlists from a backup and downloads their channels'**
  String get restoreFromFileSubtitle;

  /// No description provided for @tvGuide.
  ///
  /// In en, this message translates to:
  /// **'TV guide'**
  String get tvGuide;

  /// No description provided for @updateTvGuideNow.
  ///
  /// In en, this message translates to:
  /// **'Update TV guide now'**
  String get updateTvGuideNow;

  /// No description provided for @downloadingGuide.
  ///
  /// In en, this message translates to:
  /// **'Downloading guide…'**
  String get downloadingGuide;

  /// No description provided for @guideUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String guideUpdateFailed(String error);

  /// No description provided for @guideNoLink.
  ///
  /// In en, this message translates to:
  /// **'No guide link for this playlist. Add one from the playlist menu.'**
  String get guideNoLink;

  /// No description provided for @guideUpdatesAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Updates automatically when a playlist is refreshed.'**
  String get guideUpdatesAutomatically;

  /// No description provided for @guideProgramsLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count} programs loaded'**
  String guideProgramsLoaded(int count);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionLine.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · Free and open source under GPL-3.0'**
  String versionLine(String version);

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Tally is a player only. It does not include, sell or promote any channels or content. Use it with playlists you are allowed to watch.'**
  String get disclaimer;

  /// No description provided for @backupWarning.
  ///
  /// In en, this message translates to:
  /// **'The file includes your playlist links, usernames and passwords. Keep it somewhere private.'**
  String get backupWarning;

  /// No description provided for @backUp.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backUp;

  /// No description provided for @saveBackup.
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get saveBackup;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the backup: {error}'**
  String backupFailed(String error);

  /// No description provided for @chooseBackup.
  ///
  /// In en, this message translates to:
  /// **'Choose a backup'**
  String get chooseBackup;

  /// No description provided for @readingBackup.
  ///
  /// In en, this message translates to:
  /// **'Reading backup…'**
  String get readingBackup;

  /// No description provided for @loadingNamed.
  ///
  /// In en, this message translates to:
  /// **'Loading {name}…'**
  String loadingNamed(String name);

  /// No description provided for @restoreAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {playlists}'**
  String restoreAdded(String playlists);

  /// No description provided for @restoreAllPresent.
  ///
  /// In en, this message translates to:
  /// **'{playlists} already in the app, so only favorites, history and categories were merged'**
  String restoreAllPresent(String playlists);

  /// No description provided for @restoreSomePresent.
  ///
  /// In en, this message translates to:
  /// **'{count} already in the app'**
  String restoreSomePresent(int count);

  /// No description provided for @restoreSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped local files: {names}'**
  String restoreSkipped(String names);

  /// No description provided for @restoreEmpty.
  ///
  /// In en, this message translates to:
  /// **'The backup has no playlists.'**
  String get restoreEmpty;

  /// No description provided for @playlistUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} updated'**
  String playlistUpdated(String name);

  /// No description provided for @playlistUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update {name}: {error}'**
  String playlistUpdateFailed(String name, String error);

  /// No description provided for @removePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removePlaylistTitle(String name);

  /// No description provided for @removePlaylistBody.
  ///
  /// In en, this message translates to:
  /// **'Its channels, favorites and watch history are removed from this device.'**
  String get removePlaylistBody;

  /// No description provided for @neverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Never updated'**
  String get neverUpdated;

  /// No description provided for @updatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedOn(String date);

  /// No description provided for @inUse.
  ///
  /// In en, this message translates to:
  /// **'In use · {status}'**
  String inUse(String status);

  /// No description provided for @playlistOptions.
  ///
  /// In en, this message translates to:
  /// **'Playlist options'**
  String get playlistOptions;

  /// No description provided for @updateChannels.
  ///
  /// In en, this message translates to:
  /// **'Update channels'**
  String get updateChannels;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylist;

  /// No description provided for @tvGuideLink.
  ///
  /// In en, this message translates to:
  /// **'TV guide link'**
  String get tvGuideLink;

  /// No description provided for @chooseM3uPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Choose an M3U playlist'**
  String get chooseM3uPlaylist;

  /// No description provided for @chooseFileFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a playlist file first.'**
  String get chooseFileFirst;

  /// No description provided for @defaultPlaylistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get defaultPlaylistName;

  /// No description provided for @enterValidAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid address'**
  String get enterValidAddress;

  /// No description provided for @addYourPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add your playlist'**
  String get addYourPlaylist;

  /// No description provided for @playlistStaysHere.
  ///
  /// In en, this message translates to:
  /// **'Your playlist stays on this device. Tally doesn\'t provide any channels. Use a playlist from your TV provider.'**
  String get playlistStaysHere;

  /// No description provided for @m3uLink.
  ///
  /// In en, this message translates to:
  /// **'M3U link'**
  String get m3uLink;

  /// No description provided for @m3uFile.
  ///
  /// In en, this message translates to:
  /// **'M3U file'**
  String get m3uFile;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @playlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get playlistNameHint;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @guideLinkField.
  ///
  /// In en, this message translates to:
  /// **'TV guide (XMLTV) link'**
  String get guideLinkField;

  /// No description provided for @guideHelpXtream.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the guide from your Xtream server.'**
  String get guideHelpXtream;

  /// No description provided for @guideHelpM3u.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the guide named in the playlist, if any.'**
  String get guideHelpM3u;

  /// No description provided for @loadingChannelsHint.
  ///
  /// In en, this message translates to:
  /// **'Loading channels. Large playlists can take a minute.'**
  String get loadingChannelsHint;

  /// No description provided for @playlistLink.
  ///
  /// In en, this message translates to:
  /// **'Playlist link'**
  String get playlistLink;

  /// No description provided for @playlistFile.
  ///
  /// In en, this message translates to:
  /// **'Playlist file'**
  String get playlistFile;

  /// No description provided for @chooseM3uFile.
  ///
  /// In en, this message translates to:
  /// **'Choose .m3u file'**
  String get chooseM3uFile;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @stageDownloadPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Downloading playlist'**
  String get stageDownloadPlaylist;

  /// No description provided for @stageConnect.
  ///
  /// In en, this message translates to:
  /// **'Connecting to server'**
  String get stageConnect;

  /// No description provided for @stageSave.
  ///
  /// In en, this message translates to:
  /// **'Saving to this device'**
  String get stageSave;

  /// No description provided for @loadingYourPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Loading your playlist'**
  String get loadingYourPlaylist;

  /// No description provided for @loadingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Loading {name}'**
  String loadingPlaylist(String name);

  /// No description provided for @keepAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Large playlists can take a minute. Keep the app open.'**
  String get keepAppOpen;

  /// No description provided for @watchHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get watchHistory;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing watched yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Channels you watch and movies or series you start show up here.'**
  String get historyEmptyMessage;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the star on any channel, movie or series to add it here.'**
  String get favoritesEmptyMessage;

  /// No description provided for @favoriteChannels.
  ///
  /// In en, this message translates to:
  /// **'Favorite channels'**
  String get favoriteChannels;

  /// No description provided for @favoriteMoviesAndSeries.
  ///
  /// In en, this message translates to:
  /// **'Favorite movies and series'**
  String get favoriteMoviesAndSeries;

  /// No description provided for @recentChannels.
  ///
  /// In en, this message translates to:
  /// **'Recently watched channels'**
  String get recentChannels;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear watch history?'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Recently watched channels and continue watching are cleared for this playlist.'**
  String get clearHistoryBody;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get continueWatching;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search channels, movies and series'**
  String get searchHint;

  /// No description provided for @searchEverything.
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get searchEverything;

  /// No description provided for @searchMinLetters.
  ///
  /// In en, this message translates to:
  /// **'Type at least two letters of a channel, movie or series name.'**
  String get searchMinLetters;

  /// No description provided for @nothingMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\"'**
  String nothingMatches(String query);

  /// No description provided for @noFavoriteMovies.
  ///
  /// In en, this message translates to:
  /// **'No favorite movies yet'**
  String get noFavoriteMovies;

  /// No description provided for @noFavoriteSeries.
  ///
  /// In en, this message translates to:
  /// **'No favorite series yet'**
  String get noFavoriteSeries;

  /// No description provided for @noMoviesInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No movies in this playlist'**
  String get noMoviesInPlaylist;

  /// No description provided for @noSeriesInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No series in this playlist'**
  String get noSeriesInPlaylist;

  /// No description provided for @playlistHasNoMovies.
  ///
  /// In en, this message translates to:
  /// **'Your playlist doesn\'t include movies. Xtream Codes accounts usually do.'**
  String get playlistHasNoMovies;

  /// No description provided for @playlistHasNoSeries.
  ///
  /// In en, this message translates to:
  /// **'Your playlist doesn\'t include series. Xtream Codes accounts usually do.'**
  String get playlistHasNoSeries;

  /// No description provided for @noChannelsMatch.
  ///
  /// In en, this message translates to:
  /// **'No channels match \"{query}\"'**
  String noChannelsMatch(String query);

  /// No description provided for @noFavoriteChannels.
  ///
  /// In en, this message translates to:
  /// **'No favorite channels yet'**
  String get noFavoriteChannels;

  /// No description provided for @noChannelsHere.
  ///
  /// In en, this message translates to:
  /// **'No channels here'**
  String get noChannelsHere;

  /// No description provided for @favoriteChannelsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the star next to a channel to keep it here.'**
  String get favoriteChannelsHint;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @inFavorites.
  ///
  /// In en, this message translates to:
  /// **'In favorites'**
  String get inFavorites;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist order'**
  String get sortPlaylist;

  /// No description provided for @sortNumber.
  ///
  /// In en, this message translates to:
  /// **'Channel number'**
  String get sortNumber;

  /// No description provided for @sortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name Z–A'**
  String get sortNameDesc;

  /// No description provided for @sortRating.
  ///
  /// In en, this message translates to:
  /// **'Highest rated'**
  String get sortRating;

  /// No description provided for @sortYear.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortYear;

  /// No description provided for @switchPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Switch playlist'**
  String get switchPlaylist;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @chooseFourDigitPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a 4-digit PIN'**
  String get chooseFourDigitPin;

  /// No description provided for @enterPinAgain.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get enterPinAgain;

  /// No description provided for @pinUseFourDigits.
  ///
  /// In en, this message translates to:
  /// **'Use 4 digits.'**
  String get pinUseFourDigits;

  /// No description provided for @pinsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs don\'t match.'**
  String get pinsDontMatch;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN.'**
  String get wrongPin;

  /// No description provided for @noAdultCategories.
  ///
  /// In en, this message translates to:
  /// **'No adult categories found in this list.'**
  String get noAdultCategories;

  /// No description provided for @lockedCategories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Locked 1 category} other{Locked {count} categories}}'**
  String lockedCategories(int count);

  /// No description provided for @lockAdultCategories.
  ///
  /// In en, this message translates to:
  /// **'Lock adult categories'**
  String get lockAdultCategories;

  /// No description provided for @showAllRestoreOrder.
  ///
  /// In en, this message translates to:
  /// **'Show all and restore order'**
  String get showAllRestoreOrder;

  /// No description provided for @categoriesHelp.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Hidden categories disappear from the lists; locked ones need your PIN.'**
  String get categoriesHelp;

  /// No description provided for @noCategoriesHere.
  ///
  /// In en, this message translates to:
  /// **'No categories here'**
  String get noCategoriesHere;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @lockWithPin.
  ///
  /// In en, this message translates to:
  /// **'Lock with PIN'**
  String get lockWithPin;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get manageCategories;

  /// No description provided for @findCategory.
  ///
  /// In en, this message translates to:
  /// **'Find a category'**
  String get findCategory;

  /// No description provided for @noCategoryMatches.
  ///
  /// In en, this message translates to:
  /// **'No category matches \"{query}\"'**
  String noCategoryMatches(String query);

  /// No description provided for @director.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get director;

  /// No description provided for @cast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get cast;

  /// No description provided for @resumeFrom.
  ///
  /// In en, this message translates to:
  /// **'Resume from {time}'**
  String resumeFrom(String time);

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescription;

  /// No description provided for @episodeCode.
  ///
  /// In en, this message translates to:
  /// **'S{season} · E{episode}'**
  String episodeCode(int season, int episode);

  /// No description provided for @playEpisode.
  ///
  /// In en, this message translates to:
  /// **'Play {episode}'**
  String playEpisode(String episode);

  /// No description provided for @continueEpisode.
  ///
  /// In en, this message translates to:
  /// **'Continue {episode}'**
  String continueEpisode(String episode);

  /// No description provided for @seasonNumber.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String seasonNumber(int number);

  /// No description provided for @noEpisodes.
  ///
  /// In en, this message translates to:
  /// **'No episodes available'**
  String get noEpisodes;

  /// No description provided for @closeChannelList.
  ///
  /// In en, this message translates to:
  /// **'Close channel list'**
  String get closeChannelList;

  /// No description provided for @streamCouldNotPlay.
  ///
  /// In en, this message translates to:
  /// **'This stream could not be played'**
  String get streamCouldNotPlay;

  /// No description provided for @nextProgram.
  ///
  /// In en, this message translates to:
  /// **'Next  {time}  {title}'**
  String nextProgram(String time, String title);

  /// No description provided for @noChannelNumber.
  ///
  /// In en, this message translates to:
  /// **'No channel {number}'**
  String noChannelNumber(String number);

  /// No description provided for @nextEpisodeIn.
  ///
  /// In en, this message translates to:
  /// **'Next episode in {seconds} s'**
  String nextEpisodeIn(int seconds);

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get playNow;

  /// No description provided for @speedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get speedNormal;

  /// No description provided for @pictureSize.
  ///
  /// In en, this message translates to:
  /// **'Picture size'**
  String get pictureSize;

  /// No description provided for @pictureSizeSmallPlayer.
  ///
  /// In en, this message translates to:
  /// **'You see the difference in full screen. The small player keeps the original shape, so most videos look the same here.'**
  String get pictureSizeSmallPlayer;

  /// No description provided for @fitBest.
  ///
  /// In en, this message translates to:
  /// **'Best fit'**
  String get fitBest;

  /// No description provided for @fitFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fitFit;

  /// No description provided for @fitFill.
  ///
  /// In en, this message translates to:
  /// **'Fill screen'**
  String get fitFill;

  /// No description provided for @fitStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get fitStretch;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @stopsIn.
  ///
  /// In en, this message translates to:
  /// **'Stops in {time}'**
  String stopsIn(String time);

  /// No description provided for @pictureInPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture in picture'**
  String get pictureInPicture;

  /// No description provided for @pictureInPictureHint.
  ///
  /// In en, this message translates to:
  /// **'Keep watching in a small window. Pressing Home does this too.'**
  String get pictureInPictureHint;

  /// No description provided for @playerOptions.
  ///
  /// In en, this message translates to:
  /// **'Player options'**
  String get playerOptions;

  /// No description provided for @previousChannel.
  ///
  /// In en, this message translates to:
  /// **'Previous channel'**
  String get previousChannel;

  /// No description provided for @nextChannel.
  ///
  /// In en, this message translates to:
  /// **'Next channel'**
  String get nextChannel;

  /// No description provided for @back10.
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get back10;

  /// No description provided for @forward10.
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get forward10;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// No description provided for @exitFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get exitFullScreen;

  /// No description provided for @trackNumber.
  ///
  /// In en, this message translates to:
  /// **'Track {number}'**
  String trackNumber(int number);

  /// No description provided for @audioMono.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get audioMono;

  /// No description provided for @audioStereo.
  ///
  /// In en, this message translates to:
  /// **'Stereo'**
  String get audioStereo;

  /// No description provided for @audioChannels.
  ///
  /// In en, this message translates to:
  /// **'{count} ch'**
  String audioChannels(int count);

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @moreFrom.
  ///
  /// In en, this message translates to:
  /// **'More from {group}'**
  String moreFrom(String group);

  /// No description provided for @noGuideData.
  ///
  /// In en, this message translates to:
  /// **'No guide data for this channel.'**
  String get noGuideData;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @errNoContent.
  ///
  /// In en, this message translates to:
  /// **'This account has no channels, movies or series.'**
  String get errNoContent;

  /// No description provided for @errNoChannelsInM3u.
  ///
  /// In en, this message translates to:
  /// **'No channels were found in this playlist. Check that the link points to an M3U file.'**
  String get errNoChannelsInM3u;

  /// No description provided for @errProviderNoGuide.
  ///
  /// In en, this message translates to:
  /// **'Your provider doesn\'t offer a TV guide. You can add a guide (XMLTV) link from the playlist menu.'**
  String get errProviderNoGuide;

  /// No description provided for @errGuideLinkNotFound.
  ///
  /// In en, this message translates to:
  /// **'The guide link was not found. Check the link in the playlist menu.'**
  String get errGuideLinkNotFound;

  /// No description provided for @errGuideUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the guide server. Check your connection.'**
  String get errGuideUnreachable;

  /// No description provided for @errGuideDownload.
  ///
  /// In en, this message translates to:
  /// **'Guide download failed ({detail}).'**
  String errGuideDownload(String detail);

  /// No description provided for @errServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check the address and your internet connection.'**
  String get errServerUnreachable;

  /// No description provided for @errSecureConnection.
  ///
  /// In en, this message translates to:
  /// **'Secure connection failed. Try the address with http:// instead of https://.'**
  String get errSecureConnection;

  /// No description provided for @errConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String errConnectionFailed(String error);

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to answer. Try again in a moment.'**
  String get errTimeout;

  /// No description provided for @errFullLink.
  ///
  /// In en, this message translates to:
  /// **'Enter a full playlist link starting with http:// or https://.'**
  String get errFullLink;

  /// No description provided for @errAccessRefused.
  ///
  /// In en, this message translates to:
  /// **'The server refused access ({code}). Check that your subscription is active.'**
  String errAccessRefused(int code);

  /// No description provided for @errHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'The server responded with error {code}.'**
  String errHttpStatus(int code);

  /// No description provided for @errInvalidXtream.
  ///
  /// In en, this message translates to:
  /// **'The server did not return valid Xtream data.'**
  String get errInvalidXtream;

  /// No description provided for @errLoginRejected.
  ///
  /// In en, this message translates to:
  /// **'Username or password was rejected by the server.'**
  String get errLoginRejected;

  /// No description provided for @errAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'This account is {status}.'**
  String errAccountStatus(String status);

  /// No description provided for @errNotBackup.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Tally backup.'**
  String get errNotBackup;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
