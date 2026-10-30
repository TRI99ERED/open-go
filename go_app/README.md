# OpenGo

OpenGo is an offline Flutter app prototype for playing Go against GNU Go
or another person sharing the device. Initial targets are Windows, Android, and
iOS. Web and online multiplayer are not included.

## Run on Windows

From this directory:

```powershell
flutter pub get
flutter run -d windows
```

The `gnugo_ffi` package builds GNU Go's C engine as a native asset. Its build
hook uses the repository's CMake project and host C compiler to generate GNU
Go's pattern tables, then builds the C engine for the selected Flutter target.
Keep `go_app` inside the GNU Go source tree so the local package's source paths
resolve.

Android builds require the Android SDK, NDK, CMake, and accepted Android SDK
licenses. iOS builds require macOS and Xcode. Both use the same C ABI and Dart
game interface as Windows.

## Current game features

- GNU Go AI and local pass-and-play
- 9×9, 13×13, and 19×19 boards
- Human color selection, pass, and undo
- Move validation and AI move generation through GNU Go's GTP command handlers
- Tsumego practice with bundled Go Game Guru weekly problems and SGF import
- SGF game review with move navigation, comments, variations, and playback
- Touchscreen game recording with pass, undo, player metadata, and SGF export

The engine is a single process-wide session and native commands are serialized.
Scoring/results UI, online play, and Web support are not included.

The bundled 33 `gogameguru-weekly.sgf` problems are selected from
[Go Game Guru's go-problems collection](https://github.com/gogameguru/go-problems).
They are licensed CC BY-NC-SA 4.0, with attribution and distribution details in
[`licenses/THIRD_PARTY_NOTICES.md`](licenses/THIRD_PARTY_NOTICES.md). This
license permits non-commercial use; commercial distribution requires separate
permission from the rights holders.

## Licensing

OpenGo and GNU Go are distributed under GNU GPL version 3 or later; the
full license text is in [`../COPYING`](../COPYING). Preserve the GNU Go notices
and provide the corresponding source when distributing a build. Confirm that
release materials satisfy all GPLv3 obligations before publishing.
