import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
  ];

  /// Application name shown in the operating system and app chrome.
  ///
  /// In en, this message translates to:
  /// **'Open Go'**
  String get appTitle;

  /// Title of the application's home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Product name shown in the navigation drawer.
  ///
  /// In en, this message translates to:
  /// **'OpenGo'**
  String get openGo;

  /// Title of the settings screen and its navigation item.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Main heading on the home screen inviting the user to play Go.
  ///
  /// In en, this message translates to:
  /// **'Play Go your way'**
  String get playGoYourWay;

  /// Supporting description of the activities available in the app.
  ///
  /// In en, this message translates to:
  /// **'Play, study problems, review or keep game records.'**
  String get homeDescription;

  /// Home-screen action to start a Go game; also the SGF playback tooltip.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Home-screen action to open Go life-and-death problems.
  ///
  /// In en, this message translates to:
  /// **'Solve'**
  String get solve;

  /// Home-screen action to review a game record.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// Settings section containing theme and fullscreen options.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Settings section for choosing the app's display language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language option that follows the device's preferred language.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// English language option, named in its native language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Ukrainian language option, named in its native language.
  ///
  /// In en, this message translates to:
  /// **'Українська'**
  String get languageUkrainian;

  /// Label for the app theme selection setting.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Theme option that follows the operating system's light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Light appearance theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark appearance theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Setting that toggles fullscreen display mode.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// Prefix shown before an error message in a notification.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(Object message);

  /// Notification shown when the fullscreen setting cannot be changed.
  ///
  /// In en, this message translates to:
  /// **'Unable to change fullscreen mode: {error}'**
  String unableToChangeFullscreen(Object error);

  /// Game screen title and SGF metadata label.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// Black player or stone color in a Go game.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get black;

  /// White player or stone color in a Go game.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get white;

  /// Game status indicating that Black is next to move.
  ///
  /// In en, this message translates to:
  /// **'Black to play'**
  String get blackToPlay;

  /// Game status indicating that White is next to move.
  ///
  /// In en, this message translates to:
  /// **'White to play'**
  String get whiteToPlay;

  /// Game status shown while the GNU Go engine is starting.
  ///
  /// In en, this message translates to:
  /// **'Starting GNU Go…'**
  String get startingGnuGo;

  /// Game status shown when a player resigns and the opponent wins.
  ///
  /// In en, this message translates to:
  /// **'{player} resigns — {winner} wins'**
  String playerResignsWinner(Object player, Object winner);

  /// Game status shown while the final score is calculated after both players pass.
  ///
  /// In en, this message translates to:
  /// **'Both players passed — scoring game…'**
  String get bothPlayersPassedScoring;

  /// Game result when neither player wins.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// Game result stating the winner and the score margin.
  ///
  /// In en, this message translates to:
  /// **'{player} wins by {points} points'**
  String playerWinsByPoints(Object player, Object points);

  /// Game status shown when the final score could not be calculated.
  ///
  /// In en, this message translates to:
  /// **'Scoring failed'**
  String get scoringFailed;

  /// Game status heading shown when the Go engine reports an error.
  ///
  /// In en, this message translates to:
  /// **'Engine error'**
  String get engineError;

  /// Reason shown when GNU Go rejects a move as illegal.
  ///
  /// In en, this message translates to:
  /// **'That move is not legal. It may be suicide or violate the ko rule.'**
  String get engineIllegalMove;

  /// Reason shown when GNU Go rejects a move on an occupied intersection.
  ///
  /// In en, this message translates to:
  /// **'That intersection is already occupied.'**
  String get engineOccupiedPoint;

  /// Reason shown when GNU Go rejects a move with an invalid color or coordinate.
  ///
  /// In en, this message translates to:
  /// **'The move has an invalid color or board coordinate.'**
  String get engineInvalidMove;

  /// Error shown when GNU Go cannot initialize the selected board size.
  ///
  /// In en, this message translates to:
  /// **'The Go engine could not start a game on a {boardSize}×{boardSize} board.'**
  String engineStartFailed(Object boardSize);

  /// Error shown when GNU Go returns an invalid list of stones.
  ///
  /// In en, this message translates to:
  /// **'The Go engine returned an invalid board state.'**
  String get engineInvalidBoardState;

  /// Error shown when GNU Go returns an invalid move.
  ///
  /// In en, this message translates to:
  /// **'The Go engine returned an invalid move: {move}.'**
  String engineInvalidMoveResponse(Object move);

  /// Error shown when GNU Go returns an invalid score estimate.
  ///
  /// In en, this message translates to:
  /// **'The Go engine returned an invalid score estimate: {score}.'**
  String engineInvalidScoreResponse(Object score);

  /// Fallback message shown for an unrecognized Go engine error.
  ///
  /// In en, this message translates to:
  /// **'The Go engine could not complete the request: {details}'**
  String engineUnexpectedError(Object details);

  /// Error shown when a new game cannot be started.
  ///
  /// In en, this message translates to:
  /// **'Could not start the game: {error}'**
  String couldNotStartGame(Object error);

  /// Error shown when a player's move could not be made.
  ///
  /// In en, this message translates to:
  /// **'Move failed: {error}'**
  String moveFailed(Object error);

  /// Error shown when a player could not pass.
  ///
  /// In en, this message translates to:
  /// **'Pass failed: {error}'**
  String passFailed(Object error);

  /// Error shown when calculating the final game score fails.
  ///
  /// In en, this message translates to:
  /// **'Could not score game: {error}'**
  String couldNotScoreGame(Object error);

  /// Error shown when the previous move cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Undo failed: {error}'**
  String undoFailed(Object error);

  /// Label for the Go board size selection.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get board;

  /// Label for the game mode selection.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameMode;

  /// Game mode where the user plays against the GNU Go engine.
  ///
  /// In en, this message translates to:
  /// **'Vs GNU Go'**
  String get vsGnuGo;

  /// Local two-player mode where players take turns on the same device.
  ///
  /// In en, this message translates to:
  /// **'Pass-and-play'**
  String get passAndPlay;

  /// Label for selecting which color the user plays against GNU Go.
  ///
  /// In en, this message translates to:
  /// **'You play'**
  String get youPlay;

  /// Game action that passes the current player's turn.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// Game action that takes back the previous move.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Game action that starts a new game.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// Expandable section for comments and board labels.
  ///
  /// In en, this message translates to:
  /// **'Game annotations'**
  String get gameAnnotations;

  /// Text input for a comment saved in the SGF game record.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get gameComment;

  /// Text input for the label applied to board intersections.
  ///
  /// In en, this message translates to:
  /// **'Board label'**
  String get markerLabel;

  /// Validation error for an invalid board label.
  ///
  /// In en, this message translates to:
  /// **'Enter one uppercase letter or an integer.'**
  String get invalidMarkerLabel;

  /// Enable applying the entered label to board points.
  ///
  /// In en, this message translates to:
  /// **'Apply label'**
  String get enableMarkers;

  /// Stop adding or removing board labels.
  ///
  /// In en, this message translates to:
  /// **'Stop marking'**
  String get disableMarkers;

  /// Instructions for adding and removing SGF labels on the board.
  ///
  /// In en, this message translates to:
  /// **'Enter a label and choose Apply label, then tap a board point. Tap again to remove the same label, or enter a different label to replace it.'**
  String get markerInstructions;

  /// Expandable section containing player names and SGF export controls.
  ///
  /// In en, this message translates to:
  /// **'Game record'**
  String get gameRecord;

  /// Input label for the name of the player assigned Black in the game record.
  ///
  /// In en, this message translates to:
  /// **'Black player'**
  String get blackPlayer;

  /// Input label for the name of the player assigned White in the game record.
  ///
  /// In en, this message translates to:
  /// **'White player'**
  String get whitePlayer;

  /// Optional input label for the game name saved in the SGF record.
  ///
  /// In en, this message translates to:
  /// **'Game name (optional)'**
  String get gameNameOptional;

  /// Button label while the game record is being exported.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// Action to save the current game record in Smart Game Format.
  ///
  /// In en, this message translates to:
  /// **'Export SGF'**
  String get exportSgf;

  /// Title of the file-save dialog for exporting a Go game record.
  ///
  /// In en, this message translates to:
  /// **'Export SGF game'**
  String get exportSgfGame;

  /// Status shown when the user cancels the SGF export dialog.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get exportCancelled;

  /// Status confirming the destination of the exported game record.
  ///
  /// In en, this message translates to:
  /// **'Saved SGF to {path}'**
  String savedSgfTo(Object path);

  /// Error shown when the game record could not be exported.
  ///
  /// In en, this message translates to:
  /// **'Could not export SGF: {error}'**
  String couldNotExportSgf(Object error);

  /// Title of the Go life-and-death problems screen (plural).
  ///
  /// In en, this message translates to:
  /// **'Tsumegos'**
  String get tsumegos;

  /// Title of the Go life-and-death problem screen.
  ///
  /// In en, this message translates to:
  /// **'Tsumego'**
  String get tsumego;

  /// Status shown while Go problems are being loaded.
  ///
  /// In en, this message translates to:
  /// **'Loading problems…'**
  String get loadingProblems;

  /// Fallback label identifying a Go problem by its sequence number.
  ///
  /// In en, this message translates to:
  /// **'Problem {number}'**
  String problemNumber(int number);

  /// Status shown when the requested Go problem cannot be found.
  ///
  /// In en, this message translates to:
  /// **'Problem {number} is unavailable.'**
  String problemUnavailable(int number);

  /// Error shown when the Go problem collection fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load problems: {error}'**
  String couldNotLoadProblems(Object error);

  /// Short status shown when loading the problem collection fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load problems.'**
  String get failedToLoadProblems;

  /// Notification shown when importing Go problems from an SGF file fails.
  ///
  /// In en, this message translates to:
  /// **'Could not import problems.'**
  String get couldNotImportProblems;

  /// Title of the file-picker dialog for importing Go life-and-death problems.
  ///
  /// In en, this message translates to:
  /// **'Import tsumego SGF'**
  String get importTsumegoSgf;

  /// Initial instruction shown when a Go problem is ready to solve.
  ///
  /// In en, this message translates to:
  /// **'Find the solution.'**
  String get findSolution;

  /// Error shown when a Go problem's SGF data cannot be interpreted.
  ///
  /// In en, this message translates to:
  /// **'Invalid problem SGF: {error}'**
  String invalidProblemSgf(Object error);

  /// Feedback shown when a move does not match an accepted problem solution.
  ///
  /// In en, this message translates to:
  /// **'That move is not in the solution. Try another move.'**
  String get incorrectMove;

  /// Success feedback shown after the user solves a Go problem.
  ///
  /// In en, this message translates to:
  /// **'Solved! You found the solution.'**
  String get solvedProblem;

  /// Feedback shown when a correct move continues but does not finish a problem.
  ///
  /// In en, this message translates to:
  /// **'Correct. Continue the sequence.'**
  String get correctContinue;

  /// Count of incorrect moves made while solving the current Go problem.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No incorrect attempts} one{{count} incorrect attempt} other{{count} incorrect attempts}}'**
  String incorrectAttempts(int count);

  /// Action to restart the current Go problem.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Action to advance to the next Go problem.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Title of the screen for reviewing a Smart Game Format record.
  ///
  /// In en, this message translates to:
  /// **'Review SGF'**
  String get reviewSgf;

  /// Title of the file-picker dialog for opening an SGF game record.
  ///
  /// In en, this message translates to:
  /// **'Open SGF game record'**
  String get openSgfGameRecord;

  /// Error shown when an SGF game record cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open SGF: {error}'**
  String couldNotOpenSgf(Object error);

  /// Subtitle identifying a branch in the game's move variations.
  ///
  /// In en, this message translates to:
  /// **'Variation {number}'**
  String variation(int number);

  /// Label for a game-tree node that sets up the board rather than making a move.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setup;

  /// Move description for a player passing instead of placing a stone.
  ///
  /// In en, this message translates to:
  /// **'{player} passes'**
  String playerPasses(Object player);

  /// Empty-state instructions shown before a game record is opened.
  ///
  /// In en, this message translates to:
  /// **'Open an SGF file to review its game, comments, and variations.'**
  String get openSgfReviewDescription;

  /// Label identifying a game in a multi-game SGF file.
  ///
  /// In en, this message translates to:
  /// **'Game {number}'**
  String gameNumber(int number);

  /// Review status showing the current move, main-line length, and next player.
  ///
  /// In en, this message translates to:
  /// **'Move {current} / {total} · {player} to play'**
  String moveProgress(int current, int total, Object player);

  /// Accessibility tooltip for the control that steps to the previous move.
  ///
  /// In en, this message translates to:
  /// **'Previous move'**
  String get previousMove;

  /// Accessibility tooltip shown when SGF move playback is running.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Accessibility tooltip for advancing to the next move or selecting a branch.
  ///
  /// In en, this message translates to:
  /// **'Next move / choose variation'**
  String get nextMoveChooseVariation;

  /// SGF metadata label for the date the game was played.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// SGF metadata label for the game's result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// SGF metadata label for komi, the compensation points given to White.
  ///
  /// In en, this message translates to:
  /// **'Komi'**
  String get komi;

  /// SGF metadata label for the ruleset used in the game.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// SGF metadata label for the event in which the game was played.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// SGF metadata showing the Go board dimensions; the same size is used for width and height.
  ///
  /// In en, this message translates to:
  /// **'Board: {size}×{size}'**
  String boardSize(int size);

  /// Accessibility text indicating that there are no stones of a color on the board.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get none;

  /// Accessibility label describing the Go board and the locations of each color's stones.
  ///
  /// In en, this message translates to:
  /// **'Go board. Black stones: {black}. White stones: {white}.'**
  String goBoardSemantics(Object black, Object white);

  /// Title of the filter options screen.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Action that closes a screen without applying its changes.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Filter-screen action that clears every selected filter.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Action that applies the selected filters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Title of the sorting options screen.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Sorting-screen action that restores the default sort settings.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultAction;

  /// Heading for choosing ascending or descending sort order.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// Sort-order option that places later or larger values first.
  ///
  /// In en, this message translates to:
  /// **'DESCENDING'**
  String get descending;

  /// Sort-order option that places earlier or smaller values first.
  ///
  /// In en, this message translates to:
  /// **'ASCENDING'**
  String get ascending;

  /// Heading for choosing the field used to sort items.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Action that applies the selected sort field and order.
  ///
  /// In en, this message translates to:
  /// **'Apply sort'**
  String get applySort;

  /// Placeholder text in a message input field.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
