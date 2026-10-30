import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final repositoryRoot = input.packageRoot.resolve('../../../');
    final hostBuildDirectory = input.outputDirectoryShared.resolve(
      'gnugo-host-build/',
    );
    await Directory.fromUri(hostBuildDirectory).create(recursive: true);

    final configureResult = await Process.run('cmake', [
      '-S',
      repositoryRoot.toFilePath(),
      '-B',
      hostBuildDirectory.toFilePath(),
      '-DCMAKE_BUILD_TYPE=Release',
    ]);
    if (configureResult.exitCode != 0) {
      throw StateError(
        'Could not configure GNU Go host pattern tools:\n'
        '${configureResult.stdout}\n${configureResult.stderr}',
      );
    }

    final buildResult = await Process.run('cmake', [
      '--build',
      hostBuildDirectory.toFilePath(),
      '--config',
      'Release',
      '--target',
      'patterns',
    ]);
    if (buildResult.exitCode != 0) {
      throw StateError(
        'Could not generate GNU Go pattern sources:\n'
        '${buildResult.stdout}\n${buildResult.stderr}',
      );
    }

    final generatedPatternDirectory = hostBuildDirectory.resolve('patterns/');
    final generatedPatterns = [
      'apatterns.c',
      'dpatterns.c',
      'handipat.c',
      'influence.c',
      'barriers.c',
      'endgame.c',
      'conn.c',
      'fusekipat.c',
      'aa_attackpat.c',
      'owl_vital_apat.c',
      'owl_attackpat.c',
      'owl_defendpat.c',
      'fuseki9.c',
      'fuseki13.c',
      'fuseki19.c',
      'josekidb.c',
      'patterns.c',
      'eyes.c',
      'mcpat.c',
    ];
    final patternSources = <String>[];
    for (final pattern in generatedPatterns) {
      final sourceUri = generatedPatternDirectory.resolve(pattern);
      if (pattern == 'influence.c' || pattern == 'endgame.c') {
        final wrapperUri = input.outputDirectoryShared.resolve(
          'gnugo_ffi_generated/${pattern.replaceAll('.c', '_patterns.c')}',
        );
        await Directory.fromUri(wrapperUri).parent.create(recursive: true);
        final includePath = sourceUri.toFilePath().replaceAll(r'\', '/');
        final wrapper = File.fromUri(wrapperUri);
        final contents = '#include "$includePath"\n';
        if (!await wrapper.exists() || await wrapper.readAsString() != contents) {
          await wrapper.writeAsString(contents);
        }
        patternSources.add(wrapperUri.toFilePath());
      } else {
        patternSources.add(sourceUri.toFilePath());
      }
    }

    final rootSources = <String>[
      'interface/gtp.c',
      'interface/play_gtp.c',
      'engine/aftermath.c',
      'engine/board.c',
      'engine/boardlib.c',
      'engine/breakin.c',
      'engine/cache.c',
      'engine/clock.c',
      'engine/combination.c',
      'engine/dragon.c',
      'engine/endgame.c',
      'engine/filllib.c',
      'engine/fuseki.c',
      'engine/genmove.c',
      'engine/globals.c',
      'engine/handicap.c',
      'engine/hash.c',
      'engine/influence.c',
      'engine/interface.c',
      'engine/matchpat.c',
      'engine/montecarlo.c',
      'engine/move_reasons.c',
      'engine/movelist.c',
      'engine/optics.c',
      'engine/oracle.c',
      'engine/owl.c',
      'engine/persistent.c',
      'engine/printutils.c',
      'engine/readconnect.c',
      'engine/reading.c',
      'engine/semeai.c',
      'engine/sgfdecide.c',
      'engine/sgffile.c',
      'engine/shapes.c',
      'engine/showbord.c',
      'engine/surround.c',
      'engine/unconditional.c',
      'engine/utils.c',
      'engine/value_moves.c',
      'engine/worm.c',
      'sgf/sgf_utils.c',
      'sgf/sgfnode.c',
      'sgf/sgftree.c',
      'utils/getopt.c',
      'utils/getopt1.c',
      'utils/random.c',
      'utils/gg_utils.c',
      'utils/winsocket.c',
      'patterns/connections.c',
      'patterns/helpers.c',
      'patterns/transform.c',
    ];
    final sources = <String>[
      'src/gnugo_ffi.c',
      ...patternSources,
      ...rootSources.map((source) => '../../../$source'),
    ];
    final libraries = input.config.code.targetOS == OS.windows
        ? <String>['wsock32']
        : <String>['m'];
    final cbuilder = CBuilder.library(
      name: input.packageName,
      assetName: '${input.packageName}_bindings_generated.dart',
      sources: sources,
      includes: [
        'src',
        '${repositoryRoot.toFilePath()}engine',
        '${repositoryRoot.toFilePath()}interface',
        '${repositoryRoot.toFilePath()}patterns',
        '${repositoryRoot.toFilePath()}sgf',
        '${repositoryRoot.toFilePath()}utils',
      ],
      defines: const {'HAVE_CONFIG_H': null},
      libraries: libraries,
      flags: input.config.code.targetOS == OS.android
          ? const ['-Wno-excess-initializers', '-fcommon']
          : const [],
    );
    await cbuilder.run(input: input, output: output);
  });
}
