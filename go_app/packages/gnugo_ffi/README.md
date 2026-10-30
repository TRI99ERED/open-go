# gnugo_ffi

This local Dart FFI package exposes a small API over GNU Go's existing GTP
command handlers:

- `start(boardSize, seed)` initializes or resets the process-wide engine.
- `command(text)` executes one GTP command and returns its successful response
  payload. GTP failures become `GnuGoException`.

The engine contains process-global state, so the Dart wrapper serializes native
calls. GNU Go generation may take noticeable time; calls run on helper isolates
to avoid blocking Flutter's UI isolate.

The native build hook first uses host CMake to build GNU Go's pattern generators
and generate their C tables, then compiles the GNU Go engine sources for the
requested Flutter target. This lets cross builds use host-built pattern tools
instead of trying to execute target binaries.

This package is intentionally local to the GNU Go source tree. Its relative
source references expect the app at `go_app/packages/gnugo_ffi`. GNU Go is
licensed under GPL version 3 or later; see the repository's `COPYING` file.
