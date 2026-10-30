import 'package:flutter/material.dart';
import 'package:gnugo_ffi/gnugo_ffi.dart';

void main() {
  runApp(const EngineExampleApp());
}

class EngineExampleApp extends StatefulWidget {
  const EngineExampleApp({super.key});

  @override
  State<EngineExampleApp> createState() => _EngineExampleAppState();
}

class _EngineExampleAppState extends State<EngineExampleApp> {
  final GnuGoEngine _engine = GnuGoEngine();
  String _response = 'Initializing…';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _engine.start(9);
      await _engine.command('boardsize 9');
      await _engine.command('clear_board');
      final move = await _engine.command('genmove black');
      if (mounted) setState(() => _response = 'GNU Go played $move');
    } on GnuGoException catch (error) {
      if (mounted) setState(() => _response = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('GNU Go FFI example')),
      body: Center(child: Text(_response)),
    ),
  );
}
