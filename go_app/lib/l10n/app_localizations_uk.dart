// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'ВідкритийҐо';

  @override
  String get home => 'Домівка';

  @override
  String get openGo => 'ВідкритийҐо';

  @override
  String get settings => 'Налаштування';

  @override
  String get playGoYourWay => 'Грайте Ґо по-своєму';

  @override
  String get homeDescription =>
      'Грайте, вивчайте проблеми, оглядайте і ведіть записи ігор.';

  @override
  String get play => 'Грати';

  @override
  String get solve => 'Розгадувати';

  @override
  String get review => 'Оглядати';

  @override
  String get appearance => 'Вигляд';

  @override
  String get language => 'Мова';

  @override
  String get languageSystem => 'Системна';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get theme => 'Тема';

  @override
  String get system => 'Системна';

  @override
  String get light => 'Світла';

  @override
  String get dark => 'Темна';

  @override
  String get fullscreen => 'Повноекранний режим';

  @override
  String errorWithMessage(Object message) {
    return 'Помилка: $message';
  }

  @override
  String unableToChangeFullscreen(Object error) {
    return 'Не виходить перейти до повноекранного режиму: $error';
  }

  @override
  String get game => 'Гра';

  @override
  String get black => 'Чорні';

  @override
  String get white => 'Білі';

  @override
  String get blackToPlay => 'Хід Чорних';

  @override
  String get whiteToPlay => 'Хід Білих';

  @override
  String get startingGnuGo => 'Запускаємо GNU Go…';

  @override
  String playerResignsWinner(Object player, Object winner) {
    return '$player здалися — $winner перемагають';
  }

  @override
  String get bothPlayersPassedScoring =>
      'Обидва гравця пропустили хід — оцінюємо гру…';

  @override
  String get draw => 'Нічия';

  @override
  String playerWinsByPoints(Object player, Object points) {
    return '$player перемагає на $points очків';
  }

  @override
  String get scoringFailed => 'Не вдалося оцінити';

  @override
  String get engineError => 'Помилка рушія';

  @override
  String get engineIllegalMove =>
      'Цей хід неможливий. Можливо, це самогубний хід або порушення правила ко.';

  @override
  String get engineOccupiedPoint => 'На цьому перетині вже є камінь.';

  @override
  String get engineInvalidMove =>
      'Хід має неправильний колір або координату на дошці.';

  @override
  String engineStartFailed(Object boardSize) {
    return 'Рушій Ґо не зміг почати гру на дошці $boardSize×$boardSize.';
  }

  @override
  String get engineInvalidBoardState =>
      'Рушій Ґо повернув неправильний стан дошки.';

  @override
  String engineInvalidMoveResponse(Object move) {
    return 'Рушій Ґо повернув неправильний хід: $move.';
  }

  @override
  String engineInvalidScoreResponse(Object score) {
    return 'Рушій Ґо повернув неправильну оцінку рахунку: $score.';
  }

  @override
  String engineUnexpectedError(Object details) {
    return 'Рушій Ґо не зміг виконати запит: $details';
  }

  @override
  String couldNotStartGame(Object error) {
    return 'Не вдалося розпочати гру: $error';
  }

  @override
  String moveFailed(Object error) {
    return 'Не вдалося зробити хід: $error';
  }

  @override
  String passFailed(Object error) {
    return 'Не вдалося пропустити хід: $error';
  }

  @override
  String couldNotScoreGame(Object error) {
    return 'Не вдалося оцінити гру: $error';
  }

  @override
  String undoFailed(Object error) {
    return 'Не вдалося повернути хід: $error';
  }

  @override
  String get board => 'Дошка';

  @override
  String get gameMode => 'Гра';

  @override
  String get vsGnuGo => 'Проти GNU Go';

  @override
  String get passAndPlay => 'Передавай-і-грай';

  @override
  String get youPlay => 'Ваш хід';

  @override
  String get pass => 'Пропустити хід';

  @override
  String get undo => 'Повернути хід';

  @override
  String get newGame => 'Нова гра';

  @override
  String get gameAnnotations => 'Анотації гри';

  @override
  String get gameComment => 'Коментар';

  @override
  String get markerLabel => 'Позначка на дошці';

  @override
  String get invalidMarkerLabel => 'Введіть одну велику літеру або ціле число.';

  @override
  String get enableMarkers => 'Застосувати позначку';

  @override
  String get disableMarkers => 'Вимкнути позначки';

  @override
  String get markerInstructions =>
      'Введіть позначку й натисніть «Застосувати позначку», а потім торкніться точки на дошці. Торкніться ще раз, щоб прибрати цю позначку, або введіть іншу, щоб замінити її.';

  @override
  String get gameRecord => 'Запис гри';

  @override
  String get blackPlayer => 'Гравець Чорних';

  @override
  String get whitePlayer => 'Гравець Білих';

  @override
  String get gameNameOptional => 'Назва гри (необов\'язково)';

  @override
  String get exporting => 'Експортуємо…';

  @override
  String get exportSgf => 'Експорт SGF';

  @override
  String get exportSgfGame => 'Експортувати SGF гру';

  @override
  String get exportCancelled => 'Експорт скасовано';

  @override
  String savedSgfTo(Object path) {
    return 'Збережено SGF до $path';
  }

  @override
  String couldNotExportSgf(Object error) {
    return 'Не вдалося експортувати SGF: $error';
  }

  @override
  String get tsumegos => 'Цумеґо';

  @override
  String get tsumego => 'Цумеґо';

  @override
  String get loadingProblems => 'Завантажуємо проблеми…';

  @override
  String problemNumber(int number) {
    return 'Проблема $number';
  }

  @override
  String problemUnavailable(int number) {
    return 'Проблема $number недоступна.';
  }

  @override
  String couldNotLoadProblems(Object error) {
    return 'Не вдалося завантажити проблеми: $error';
  }

  @override
  String get failedToLoadProblems => 'Не вдалося завантажити проблеми.';

  @override
  String get couldNotImportProblems => 'Не вдалося імпортувати проблеми.';

  @override
  String get importTsumegoSgf => 'Імпортувати цумеґо SGF';

  @override
  String get findSolution => 'Знайдіть рішення.';

  @override
  String invalidProblemSgf(Object error) {
    return 'Недійсний SGF проблеми: $error';
  }

  @override
  String get incorrectMove => 'Цього ходу нема в рішенні. Спробуйте інший хід.';

  @override
  String get solvedProblem => 'Розгадано! Ви знайшли рішення.';

  @override
  String get correctContinue => 'Правильно. Продовжуйте послідовність.';

  @override
  String incorrectAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count некоректних спроб',
      one: '$count ненкоректна спроба',
      zero: 'Немає некоректних спроб',
    );
    return '$_temp0';
  }

  @override
  String get tryAgain => 'Спробуйте знову';

  @override
  String get next => 'Наступна';

  @override
  String get reviewSgf => 'Огляд SGF';

  @override
  String get openSgfGameRecord => 'Відкрити SGF запис гри';

  @override
  String couldNotOpenSgf(Object error) {
    return 'Не вдалося відкрити SGF: $error';
  }

  @override
  String variation(int number) {
    return 'Варіація $number';
  }

  @override
  String get setup => 'Розклад';

  @override
  String playerPasses(Object player) {
    return '$player пропускає хід';
  }

  @override
  String get openSgfReviewDescription =>
      'Відкрийте SGF файл щоб оглянути його гру, коментарі і варіації.';

  @override
  String gameNumber(int number) {
    return 'Гра $number';
  }

  @override
  String moveProgress(int current, int total, Object player) {
    return 'Хід $current / $total · $player ходить';
  }

  @override
  String get previousMove => 'Попередній хід';

  @override
  String get pause => 'Пауза';

  @override
  String get nextMoveChooseVariation => 'Наступний хід / обрати варіацію';

  @override
  String get date => 'Дата';

  @override
  String get result => 'Результат';

  @override
  String get komi => 'Комі';

  @override
  String get rules => 'Правила';

  @override
  String get event => 'Подія';

  @override
  String boardSize(int size) {
    return 'Дошка: $size×$size';
  }

  @override
  String get none => 'нема';

  @override
  String goBoardSemantics(Object black, Object white) {
    return 'Дошка ґо. Чорні камені: $black. Білі камені: $white.';
  }

  @override
  String get filter => 'Фільтр';

  @override
  String get cancel => 'Скасувати';

  @override
  String get clearAll => 'Очистити все';

  @override
  String get applyFilters => 'Застосувати фільтри';

  @override
  String get sort => 'Сортування';

  @override
  String get defaultAction => 'Стандартне';

  @override
  String get sortOrder => 'Порядок сортування';

  @override
  String get descending => 'СПАДАЮЧИЙ';

  @override
  String get ascending => 'ЗРОСТАЮЧИЙ';

  @override
  String get sortBy => 'Сортувати за';

  @override
  String get applySort => 'Застосувати сортування';

  @override
  String get typeMessage => 'Введіть повідомлення...';
}
