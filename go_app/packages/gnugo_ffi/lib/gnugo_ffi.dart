import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'gnugo_ffi_bindings_generated.dart' as bindings;

final class GnuGoEngine {
  static Future<void> _tail = Future<void>.value();

  Future<void> start(int boardSize, {int seed = 1}) {
    return _enqueue<void>(() async {
      final result = await Isolate.run(
        () => bindings.gnugo_ffi_init(boardSize, seed),
      );
      if (result != 0) {
        throw GnuGoException(
          'GNU Go could not initialize board size $boardSize.',
        );
      }
    });
  }

  Future<String> command(String command) {
    return _enqueue<String>(() => Isolate.run(() => _commandOnWorker(command)));
  }

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await task());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

String _commandOnWorker(String command) {
  final commandPointer = command.toNativeUtf8();
  final responsePointer = calloc<ffi.Char>(4096);
  try {
    final length = bindings.gnugo_ffi_command(
      commandPointer.cast<ffi.Char>(),
      responsePointer,
      4096,
    );
    if (length < 0) {
      throw GnuGoException('GNU Go command failed (native error $length).');
    }

    final response = responsePointer.cast<Utf8>().toDartString(length: length);
    final trimmed = response.trim();
    if (trimmed.startsWith('?')) {
      throw GnuGoException(trimmed.substring(1).trim());
    }
    if (!trimmed.startsWith('=')) {
      throw GnuGoException('Invalid GNU Go response.');
    }
    return trimmed.substring(1).trim();
  } finally {
    calloc.free(commandPointer);
    calloc.free(responsePointer);
  }
}

final class GnuGoException implements Exception {
  const GnuGoException(this.message);

  final String message;

  @override
  String toString() => message;
}
