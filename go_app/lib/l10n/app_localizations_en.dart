// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Open Go';

  @override
  String get home => 'Home';

  @override
  String get openGo => 'OpenGo';

  @override
  String get settings => 'Settings';

  @override
  String get playGoYourWay => 'Play Go your way';

  @override
  String get homeDescription =>
      'Play, study problems, review or keep game records.';

  @override
  String get play => 'Play';

  @override
  String get solve => 'Solve';

  @override
  String get review => 'Review';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String unableToChangeFullscreen(Object error) {
    return 'Unable to change fullscreen mode: $error';
  }

  @override
  String get game => 'Game';

  @override
  String get black => 'Black';

  @override
  String get white => 'White';

  @override
  String get blackToPlay => 'Black to play';

  @override
  String get whiteToPlay => 'White to play';

  @override
  String get startingGnuGo => 'Starting GNU Go…';

  @override
  String playerResignsWinner(Object player, Object winner) {
    return '$player resigns — $winner wins';
  }

  @override
  String get bothPlayersPassedScoring => 'Both players passed — scoring game…';

  @override
  String get draw => 'Draw';

  @override
  String playerWinsByPoints(Object player, Object points) {
    return '$player wins by $points points';
  }

  @override
  String get scoringFailed => 'Scoring failed';

  @override
  String get engineError => 'Engine error';

  @override
  String couldNotStartGame(Object error) {
    return 'Could not start the game: $error';
  }

  @override
  String moveFailed(Object error) {
    return 'Move failed: $error';
  }

  @override
  String passFailed(Object error) {
    return 'Pass failed: $error';
  }

  @override
  String couldNotScoreGame(Object error) {
    return 'Could not score game: $error';
  }

  @override
  String undoFailed(Object error) {
    return 'Undo failed: $error';
  }

  @override
  String get board => 'Board';

  @override
  String get gameMode => 'Game';

  @override
  String get vsGnuGo => 'Vs GNU Go';

  @override
  String get passAndPlay => 'Pass-and-play';

  @override
  String get youPlay => 'You play';

  @override
  String get pass => 'Pass';

  @override
  String get undo => 'Undo';

  @override
  String get newGame => 'New game';

  @override
  String get gameRecord => 'Game record';

  @override
  String get blackPlayer => 'Black player';

  @override
  String get whitePlayer => 'White player';

  @override
  String get gameNameOptional => 'Game name (optional)';

  @override
  String get exporting => 'Exporting…';

  @override
  String get exportSgf => 'Export SGF';

  @override
  String get exportSgfGame => 'Export SGF game';

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String savedSgfTo(Object path) {
    return 'Saved SGF to $path';
  }

  @override
  String couldNotExportSgf(Object error) {
    return 'Could not export SGF: $error';
  }

  @override
  String get tsumegos => 'Tsumegos';

  @override
  String get tsumego => 'Tsumego';

  @override
  String get loadingProblems => 'Loading problems…';

  @override
  String problemNumber(int number) {
    return 'Problem $number';
  }

  @override
  String problemUnavailable(int number) {
    return 'Problem $number is unavailable.';
  }

  @override
  String couldNotLoadProblems(Object error) {
    return 'Could not load problems: $error';
  }

  @override
  String get failedToLoadProblems => 'Could not load problems.';

  @override
  String get couldNotImportProblems => 'Could not import problems.';

  @override
  String get importTsumegoSgf => 'Import tsumego SGF';

  @override
  String get findSolution => 'Find the solution.';

  @override
  String invalidProblemSgf(Object error) {
    return 'Invalid problem SGF: $error';
  }

  @override
  String get incorrectMove =>
      'That move is not in the solution. Try another move.';

  @override
  String get solvedProblem => 'Solved! You found the solution.';

  @override
  String get correctContinue => 'Correct. Continue the sequence.';

  @override
  String incorrectAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incorrect attempts',
      one: '$count incorrect attempt',
      zero: 'No incorrect attempts',
    );
    return '$_temp0';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get next => 'Next';

  @override
  String get reviewSgf => 'Review SGF';

  @override
  String get openSgfGameRecord => 'Open SGF game record';

  @override
  String couldNotOpenSgf(Object error) {
    return 'Could not open SGF: $error';
  }

  @override
  String variation(int number) {
    return 'Variation $number';
  }

  @override
  String get setup => 'Setup';

  @override
  String playerPasses(Object player) {
    return '$player passes';
  }

  @override
  String get openSgfReviewDescription =>
      'Open an SGF file to review its game, comments, and variations.';

  @override
  String gameNumber(int number) {
    return 'Game $number';
  }

  @override
  String moveProgress(int current, int total, Object player) {
    return 'Move $current / $total · $player to play';
  }

  @override
  String get previousMove => 'Previous move';

  @override
  String get pause => 'Pause';

  @override
  String get nextMoveChooseVariation => 'Next move / choose variation';

  @override
  String get date => 'Date';

  @override
  String get result => 'Result';

  @override
  String get komi => 'Komi';

  @override
  String get rules => 'Rules';

  @override
  String get event => 'Event';

  @override
  String boardSize(int size) {
    return 'Board: $size×$size';
  }

  @override
  String get none => 'none';

  @override
  String goBoardSemantics(Object black, Object white) {
    return 'Go board. Black stones: $black. White stones: $white.';
  }

  @override
  String get filter => 'Filter';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearAll => 'Clear All';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get sort => 'Sort';

  @override
  String get defaultAction => 'Default';

  @override
  String get sortOrder => 'Sort Order';

  @override
  String get descending => 'DESCENDING';

  @override
  String get ascending => 'ASCENDING';

  @override
  String get sortBy => 'Sort By';

  @override
  String get applySort => 'Apply sort';

  @override
  String get typeMessage => 'Type a message...';
}
