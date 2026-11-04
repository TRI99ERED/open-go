# OpenGo

OpenGo is an offline Flutter app for playing and studying Go. It uses GNU Go as
its local game engine and runs on Windows, Android, and iOS. An internet
connection is not needed for play. Web and online multiplayer are not
supported.

## Features

- Play against GNU Go or play pass-and-play with another person on the same
  device.
- Choose a 9x9, 13x13, or 19x19 board, choose your color, pass, and undo moves.
- Get move validation and AI responses from GNU Go. The game ends after both
  players pass, and GNU Go calculates the result.
- Solve bundled tsumego problems or import problems in SGF format.
- Review SGF games by navigating moves and variations, reading comments, and
  playing through the record.
- Record a game with player names and an optional title, then export it as an
  SGF file.

The engine is a single process-wide session, and native commands are
serialized. Game recording and SGF export are supported; online play and a
separate scoring editor are not.

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`.
- A native toolchain for the platform you want to run:
  - **Windows:** Flutter's Windows desktop development requirements.
  - **Android:** Android SDK, NDK, CMake, and accepted Android SDK licenses.
  - **iOS:** macOS and Xcode.

The `gnugo_ffi` package builds GNU Go's C engine as a native asset. Its build
hook uses the repository's CMake project and host C compiler to generate GNU
Go's pattern tables, then builds the engine for the selected Flutter target.
Keep `go_app` inside the GNU Go source tree so the local package's source paths
resolve.

## Run the app

Run these commands from the `go_app` directory. Fetch dependencies first:

```powershell
flutter pub get
```

Run on Windows:

```powershell
flutter run -d windows
```

For Android, start an emulator or connect a device, then run:

```powershell
flutter run
```

For iOS, use macOS with an iOS simulator or connected device:

```shell
flutter run
```

If Flutter does not select the intended device, list available targets with
`flutter devices` and specify one with `flutter run -d <device-id>`.

## Build a release

Run the relevant command from `go_app`:

```shell
flutter build windows
flutter build apk
flutter build ios
```

The iOS build command must be run on macOS with Xcode.

The bundled 33 `gogameguru-weekly.sgf` problems are selected from
[Go Game Guru's go-problems collection](https://github.com/gogameguru/go-problems).
They are licensed CC BY-NC-SA 4.0, with attribution and distribution details in
[`licenses/THIRD_PARTY_NOTICES.md`](licenses/THIRD_PARTY_NOTICES.md). This
license permits non-commercial use; commercial distribution requires separate
permission from the rights holders.

## F-Droid

The F-Droid source-build recipe and `NonFreeAssets` disclosure are in
[`../metadata/com.tri99er.opengo.yml`](../metadata/com.tri99er.opengo.yml).
The localized listing text, release notes, app icon, and phone screenshots are in
[`../fastlane/metadata/android`](../fastlane/metadata/android). Keep the attribution
and license information in `licenses/THIRD_PARTY_NOTICES.md` with distributed
builds.

To propose inclusion in the official F-Droid repository, first commit the
listing files to this repository and tag the corresponding app release (for
example, `v0.2.0`). Push both the commit and tag. Update the `commit` in the
build recipe to that release commit, then submit the recipe as
`metadata/com.tri99er.opengo.yml` in a [merge request to
fdroiddata](https://gitlab.com/fdroid/fdroiddata/-/merge_requests). The recipe
targets release tag `v0.2.0` at commit
`e3434f105e9b33481a645ef4e10af4bcfd09b636`. Run `fdroid lint` and
`fdroid build` on the recipe, or use the F-Droid CI pipeline, before proposing
it.

F-Droid normally signs its builds with its own key. Installing an F-Droid build
alongside an APK signed with a different key may require uninstalling the
existing app first. Reproducible-build verification is needed to distribute an
APK signed with the developer's key through the official repository.

## Licensing

OpenGo and GNU Go are distributed under GNU GPL version 3 or later; the
full license text is in [`../COPYING`](../COPYING). Preserve the GNU Go notices
and provide the corresponding source when distributing a build. Confirm that
release materials satisfy all GPLv3 obligations before publishing.
