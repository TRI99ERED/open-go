class SgfNode {
  final Map<String, List<String>> properties;
  final List<SgfNode> children;

  SgfNode({Map<String, List<String>>? properties, List<SgfNode>? children})
    : properties = properties ?? {},
      children = children ?? [];

  String? firstValue(String property) => properties[property]?.firstOrNull;
  List<String> values(String property) => properties[property] ?? const [];

  void setValue(String property, String value) {
    properties[property] = [value];
  }
}

class SgfCollection {
  const SgfCollection(this.games);

  final List<SgfNode> games;

  factory SgfCollection.parse(String source) => _SgfParser(source).parse();

  String write() => games.map(_writeGame).join('\n');

  static String _writeGame(SgfNode root) {
    final output = StringBuffer('(');
    _writeLine(output, root);
    output.write(')');
    return output.toString();
  }

  static void _writeLine(StringBuffer output, SgfNode node) {
    output.write(';');
    for (final entry in node.properties.entries) {
      if (!RegExp(r'^[A-Z]+$').hasMatch(entry.key)) {
        throw FormatException('Invalid SGF property identifier: ${entry.key}');
      }
      if (entry.value.isEmpty) {
        throw FormatException('SGF property ${entry.key} has no values.');
      }
      output.write(entry.key);
      for (final value in entry.value) {
        output
          ..write('[')
          ..write(value.replaceAll(r'\', r'\\').replaceAll(']', r'\]'))
          ..write(']');
      }
    }

    if (node.children.length == 1) {
      _writeLine(output, node.children.single);
    } else {
      for (final child in node.children) {
        output.write('(');
        _writeLine(output, child);
        output.write(')');
      }
    }
  }
}

class _SgfParser {
  _SgfParser(this.source);

  final String source;
  int _offset = 0;

  SgfCollection parse() {
    final games = <SgfNode>[];
    _skipWhitespace();
    while (!_atEnd) {
      games.add(_parseTree());
      _skipWhitespace();
    }
    if (games.isEmpty) throw const FormatException('No SGF game trees found.');
    return SgfCollection(games);
  }

  SgfNode _parseTree() {
    _expect('(');
    _skipWhitespace();
    if (_peek != ';') throw _error('A game tree must start with a node.');

    SgfNode? root;
    SgfNode? tail;
    while (true) {
      _skipWhitespace();
      if (_peek == ';') {
        _offset++;
        final node = _parseNode();
        if (tail == null) {
          root = node;
        } else {
          tail.children.add(node);
        }
        tail = node;
      } else if (_peek == '(') {
        if (tail == null) throw _error('A variation has no parent node.');
        tail.children.add(_parseTree());
      } else if (_peek == ')') {
        _offset++;
        if (root == null) throw _error('The game tree is empty.');
        return root;
      } else {
        throw _error('Expected a node, variation, or end of game tree.');
      }
    }
  }

  SgfNode _parseNode() {
    final properties = <String, List<String>>{};
    while (true) {
      _skipWhitespace();
      final start = _offset;
      while (_isUppercase(_peek)) {
        _offset++;
      }
      if (start == _offset) break;
      final identifier = source.substring(start, _offset);
      final values = properties.putIfAbsent(identifier, () => []);
      _skipWhitespace();
      if (_peek != '[') throw _error('Property $identifier has no value.');
      while (_peek == '[') {
        values.add(_parseValue());
        _skipWhitespace();
      }
    }
    return SgfNode(properties: properties);
  }

  String _parseValue() {
    _expect('[');
    final value = StringBuffer();
    while (!_atEnd) {
      final character = source[_offset++];
      if (character == ']') return value.toString();
      if (character != r'\') {
        value.write(character);
        continue;
      }
      if (_atEnd) throw _error('Unterminated escape sequence.');
      final escaped = source[_offset++];
      if (escaped == '\r') {
        if (_peek == '\n') _offset++;
      } else if (escaped != '\n') {
        value.write(escaped);
      }
    }
    throw _error('Unterminated property value.');
  }

  bool get _atEnd => _offset >= source.length;
  String? get _peek => _atEnd ? null : source[_offset];

  bool _isUppercase(String? character) =>
      character != null &&
      character.codeUnitAt(0) >= 65 &&
      character.codeUnitAt(0) <= 90;

  void _skipWhitespace() {
    while (!_atEnd && source[_offset].trim().isEmpty) {
      _offset++;
    }
  }

  void _expect(String character) {
    if (_peek != character) throw _error('Expected "$character".');
    _offset++;
  }

  FormatException _error(String message) =>
      FormatException('$message (offset $_offset)', source);
}
