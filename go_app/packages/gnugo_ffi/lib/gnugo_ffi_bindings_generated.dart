// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

@ffi.Native<ffi.Int32 Function(ffi.Int32, ffi.Uint32)>()
external int gnugo_ffi_init(int boardSize, int seed);

@ffi.Native<
  ffi.Int32 Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, ffi.Int32)
>()
external int gnugo_ffi_command(
  ffi.Pointer<ffi.Char> command,
  ffi.Pointer<ffi.Char> response,
  int capacity,
);
