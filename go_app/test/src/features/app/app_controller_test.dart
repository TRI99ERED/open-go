import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengo/src/core/game/sgf.dart';
import 'package:opengo/src/features/app/app_controller/app_controller.dart';

void main() {
  late FilePickerPlatform originalFilePicker;
  late _TestFilePicker filePicker;
  late AppController controller;

  setUp(() {
    originalFilePicker = FilePickerPlatform.instance;
    filePicker = _TestFilePicker();
    FilePickerPlatform.instance = filePicker;
    controller = AppController();
  });

  tearDown(() {
    FilePickerPlatform.instance = originalFilePicker;
    controller.dispose();
  });

  test('exports SGF while reporting processing and success states', () async {
    final game = SgfNode(
      properties: {
        'GM': ['1'],
      },
    );
    final export = controller.exportSgf(
      game: game,
      fileName: 'game.sgf',
      dialogTitle: 'Export SGF',
    );

    await filePicker.started.future;
    expect(controller.state, isA<AppStateProcessing>());
    expect(utf8.decode(filePicker.savedBytes!), '(;GM[1])');
    expect(filePicker.savedFileName, 'game.sgf');
    expect(filePicker.savedDialogTitle, 'Export SGF');

    final uri = Uri.parse('file:///game.sgf');
    filePicker.result.complete(uri);
    expect(await export, uri);
    expect(controller.state, isA<AppStateIdle>());
    expect(controller.state.message, 'Successfully exported SGF');
  });

  test('records export failures and rethrows them', () async {
    final error = StateError('Picker failed');
    filePicker.saveError = error;

    await expectLater(
      controller.exportSgf(
        game: SgfNode(),
        fileName: 'game.sgf',
        dialogTitle: 'Export SGF',
      ),
      throwsA(same(error)),
    );

    expect(controller.state, isA<AppStateFailed>());
    expect(controller.state.message, 'Could not export SGF');
    expect(controller.state.error, same(error));
  });

  test('records cancellation as an idle state', () async {
    final export = controller.exportSgf(
      game: SgfNode(),
      fileName: 'game.sgf',
      dialogTitle: 'Export SGF',
    );

    await filePicker.started.future;
    filePicker.result.complete(null);

    expect(await export, isNull);
    expect(controller.state, isA<AppStateIdle>());
    expect(controller.state.message, 'SGF export cancelled');
  });

  test(
    'imports an SGF file while reporting processing and success states',
    () async {
      filePicker.pickedFile.complete(
        _TestPlatformFile(
          name: 'game.sgf',
          bytes: Uint8List.fromList(utf8.encode('(;SZ[9];B[aa])')),
        ),
      );
      final import = controller.importSgf(dialogTitle: 'Open SGF');

      await filePicker.pickStarted.future;
      expect(controller.state, isA<AppStateProcessing>());
      expect(filePicker.pickDialogTitle, 'Open SGF');

      final imported = await import;
      expect(imported?.fileName, 'game.sgf');
      expect(imported?.collection.games.single.firstValue('SZ'), '9');
      expect(controller.state, isA<AppStateIdle>());
      expect(controller.state.message, 'Successfully imported SGF');
    },
  );

  test('records SGF import cancellation as an idle state', () async {
    final import = controller.importSgf(dialogTitle: 'Open SGF');
    await filePicker.pickStarted.future;
    filePicker.pickedFile.complete(null);

    expect(await import, isNull);
    expect(controller.state, isA<AppStateIdle>());
    expect(controller.state.message, 'SGF import cancelled');
  });

  test('records SGF import failures and rethrows them', () async {
    final error = StateError('Picker failed');
    filePicker.pickError = error;

    await expectLater(
      controller.importSgf(dialogTitle: 'Open SGF'),
      throwsA(same(error)),
    );

    expect(controller.state, isA<AppStateFailed>());
    expect(controller.state.message, 'Could not import SGF');
    expect(controller.state.error, same(error));
  });
}

class _TestFilePicker extends FilePickerPlatform {
  final started = Completer<void>();
  final result = Completer<Uri?>();
  final pickStarted = Completer<void>();
  final pickedFile = Completer<PlatformFile?>();
  Uint8List? savedBytes;
  String? savedFileName;
  String? savedDialogTitle;
  String? pickDialogTitle;
  Object? saveError;
  Object? pickError;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    pickDialogTitle = dialogTitle;
    pickStarted.complete();
    if (pickError case final error?) throw error;
    return pickedFile.future;
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    savedBytes = bytes;
    savedFileName = fileName;
    savedDialogTitle = dialogTitle;
    started.complete();
    if (saveError case final error?) throw error;
    return result.future;
  }
}

final class _TestPlatformFile extends PlatformFile {
  _TestPlatformFile({required this.name, required this.bytes});

  @override
  final String name;
  final Uint8List bytes;

  @override
  Uri get uri => Uri.dataFromBytes(bytes);

  @override
  XFile get xFile => XFile.fromData(bytes, name: name);

  @override
  int? lengthSync() => bytes.length;

  @override
  Future<int?> length() async => bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}
