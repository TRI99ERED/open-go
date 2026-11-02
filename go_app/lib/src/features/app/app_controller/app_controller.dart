import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:opengo/src/core/controller/base_controller/base_controller.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/features/app/data/models/user_model.dart';

part 'app_state.dart';

final class AppController extends BaseController<AppState> {
  final authNotifier = ValueNotifier<bool>(false);
  bool isInitialized = false;

  AppController()
    : super(
        state: AppState.idle(
          message: 'App initialized',
          user: const UnauthorizedUser(),
          tsumegos: SgfCollection([]),
        ),
        name: 'AppController',
      );

  Future<void> loadTsumegos() async =>
      await serialExecutor.synchronized(() async {
        try {
          setState(
            AppState.processing(
              message: 'Getting tsumegos',
              user: state.user,
              tsumegos: state.tsumegos,
            ),
          );
          final source = await rootBundle.loadString(
            'assets/problems/gogameguru-weekly.sgf',
          );
          final tsumegos = SgfCollection.parse(source);
          setState(
            AppState.idle(
              message: 'Successfully got tsumegos',
              user: state.user,
              tsumegos: tsumegos,
            ),
          );
        } catch (error, stackTrace) {
          setState(
            AppState.failed(
              message: 'Could not load tsumegos',
              user: state.user,
              tsumegos: state.tsumegos,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
      });

  Future<void> importTsumegos({required String dialogTitle}) async =>
      await serialExecutor.synchronized(() async {
        try {
          setState(
            AppState.processing(
              message: 'Importing Tsumegos',
              user: state.user,
              tsumegos: state.tsumegos,
            ),
          );
          final files = await FilePicker.pickFiles(
            dialogTitle: dialogTitle,
            type: FileType.custom,
            allowedExtensions: const ['sgf'],
          );
          if (files.isEmpty) return;
          final games = state.tsumegos.games;
          for (final file in files) {
            final source = utf8.decode(await file.readAsBytes());
            final collection = SgfCollection.parse(source);
            games.addAll(collection.games);
          }
          setState(
            AppState.idle(
              message: 'Successfully imported tsumegos',
              user: state.user,
              tsumegos: SgfCollection(games),
            ),
          );
        } catch (error, stackTrace) {
          setState(
            AppState.failed(
              message: 'Could not import tsumegos',
              user: state.user,
              tsumegos: state.tsumegos,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
      });

  Future<({SgfCollection collection, String fileName})?> importSgf({
    required String dialogTitle,
  }) async => await serialExecutor.synchronized(() async {
    try {
      setState(
        AppState.processing(
          message: 'Importing SGF',
          user: state.user,
          tsumegos: state.tsumegos,
        ),
      );
      final file = await FilePicker.pickFile(
        dialogTitle: dialogTitle,
        type: FileType.custom,
        allowedExtensions: const ['sgf'],
      );
      if (file == null) {
        setState(
          AppState.idle(
            message: 'SGF import cancelled',
            user: state.user,
            tsumegos: state.tsumegos,
          ),
        );
        return null;
      }

      final source = utf8.decode(await file.readAsBytes());
      final collection = SgfCollection.parse(source);
      setState(
        AppState.idle(
          message: 'Successfully imported SGF',
          user: state.user,
          tsumegos: state.tsumegos,
        ),
      );
      return (collection: collection, fileName: file.name);
    } catch (error, stackTrace) {
      setState(
        AppState.failed(
          message: 'Could not import SGF',
          user: state.user,
          tsumegos: state.tsumegos,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  });

  Future<Uri?> exportSgf({
    required SgfNode game,
    required String fileName,
    required String dialogTitle,
  }) async => await serialExecutor.synchronized(() async {
    try {
      setState(
        AppState.processing(
          message: 'Exporting SGF',
          user: state.user,
          tsumegos: state.tsumegos,
        ),
      );
      final data = SgfCollection([game]).write();
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(data)),
        mimeType: 'application/x-go-sgf',
        dialogTitle: dialogTitle,
      );
      setState(
        AppState.idle(
          message: uri == null
              ? 'SGF export cancelled'
              : 'Successfully exported SGF',
          user: state.user,
          tsumegos: state.tsumegos,
        ),
      );
      return uri;
    } catch (error, stackTrace) {
      setState(
        AppState.failed(
          message: 'Could not export SGF',
          user: state.user,
          tsumegos: state.tsumegos,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  });
}
