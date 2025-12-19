import 'dart:io';

import 'src/unicode.dart';

sealed class Token {
  final int line;
  final int column;
  final String file;

  Token(this.line, this.column, this.file);
}

class NonToken extends Token {
  NonToken(super.line, super.column, super.file);

  @override
  String toString() => '<not a token>';
}

class LineTerminator extends Token {
  LineTerminator(super.line, super.column, super.file);

  @override
  String toString() => '<line terminator>';
}

class Identifier extends Token {
  Identifier(super.line, super.column, super.file, this.name);

  final String name;

  @override
  String toString() => 'identifier $name';
}

enum InputElementType {
  hashbangOrRegExp, // start of Script or Module
  regExpOrTemplateTail, // a RegularExpressionLiteral, a TemplateMiddle, or a TemplateTail is permitted
  regExp, // a RegularExpressionLiteral is permitted but neither a TemplateMiddle, nor a TemplateTail is permitted
  templateTail, // a TemplateMiddle or a TemplateTail is permitted but a RegularExpressionLiteral is not permitted
  div, // all other contexts
}

typedef Location = ({int index, int line, int column});

class SourceTextIterator {
  final String filename;
  final List<int> _string;
  final List<Location> _stack = [(index: 0, line: 1, column: 1)];
  int _stackIndex = 0;
  int? getRune() {
    return _stack[_stackIndex].index >= _string.length
        ? null
        : _string[_stack[_stackIndex].index];
  }

  void consume() {
    Location location = _stack[_stackIndex];
    bool newLine = _string[_stack[_stackIndex].index] == 0xa;
    _stack[_stackIndex] = (
      index: location.index + 1,
      line: location.line,
      column: newLine ? 1 : location.column + 1,
    );
  }

  void save() {
    _stackIndex++;
    if (_stackIndex == _stack.length) {
      _stack.add(_stack.last);
    } else {
      _stack[_stackIndex] = _stack[_stackIndex - 1];
    }
  }

  void restore() {
    assert(_stackIndex > 0);
    _stackIndex--;
  }

  void stackDown() {
    assert(_stackIndex > 0);
    _stack[_stackIndex - 1] = _stack[_stackIndex];
    _stackIndex--;
  }

  int get line => _stack[_stackIndex].line;
  int get column => _stack[_stackIndex].column;

  bool get isDone => _stack[_stackIndex].index == _string.length;

  SourceTextIterator(this.filename, String string)
    : _string = string.runes.toList();
}

List<int> spaces = const [
  0x9,
  0xb,
  0xc,
  0x20,
  0xa0,
  0x1680,
  0x2000,
  0x2001,
  0x2002,
  0x2003,
  0x2004,
  0x2005,
  0x2006,
  0x2007,
  0x2008,
  0x2009,
  0x200a,
  0x202f,
  0x205f,
  0x3000,
  0xfeff,
];

List<int> lineTerminators = [0xa, 0xd, 0x2028, 0x2029];

bool isIdentifierStart(int rune) {
  return isIDContinue(rune) || rune == 0x24;
}

bool isIdentifierPart(int rune) {
  return isIDStart(rune) || rune == 0x24 || rune == 0x5f;
}

Token tokenize(
  SourceTextIterator sourceText,
  InputElementType inputElementType,
  List<SyntaxError> errors,
) {
  int? rune = sourceText.getRune();
  assert(rune != null, 'don\'t call tokenize with no text left to tokenise!');
  if (rune == null) {
    throw StateError(
      'internal error: called tokenize with no text left to tokenise',
    );
  }
  int line = sourceText.line;
  int column = sourceText.column;
  String filename = sourceText.filename;
  if (spaces.contains(rune)) {
    sourceText.consume();
    return NonToken(line, column, filename);
  }
  if (lineTerminators.contains(rune)) {
    sourceText.consume();
    return LineTerminator(line, column, filename);
  }
  if (rune == 0x2f) {
    sourceText.save();
    sourceText.consume();
    int? rune2 = sourceText.getRune();
    if (rune2 == 0x2f) {
      sourceText.stackDown();
      while (true) {
        int? rune3 = sourceText.getRune();
        if (rune3 == null || lineTerminators.contains(rune3)) {
          break;
        }
        sourceText.consume();
      }
      return NonToken(line, column, filename);
    }
    if (rune2 == 0x2a) {
      bool lineTerminator = false;
      bool asterisk = false;
      bool eof = false;
      while (true) {
        int? rune3 = sourceText.getRune();
        if (rune3 == null) {
          eof = true;
          break;
        }
        if (!lineTerminator && lineTerminators.contains(rune3)) {
          lineTerminator = true;
        }
        if (asterisk && rune3 == 0x2f) {
          sourceText.consume();
          break;
        }
        asterisk = false;
        if (rune3 == 0x2a) {
          asterisk = true;
        }
        sourceText.consume();
      }
      if (!eof) {
        sourceText.stackDown();
        if (lineTerminator) {
          return LineTerminator(line, column, filename);
        } else {
          return NonToken(line, column, filename);
        }
      }
    }
    sourceText.restore();
  }
  identifier:
  if (isIdentifierStart(rune) || rune == 0x5c) {
    StringBuffer buffer = StringBuffer();
    if (rune == 0x5c) {
      int? unicodeEscape = getUnicodeEscape(sourceText);
      if (unicodeEscape == null) break identifier;
      if (!isIdentifierStart(unicodeEscape)) {
        errors.add(
          SyntaxError(
            'Invalid unicode escape to start identifier',
            sourceText.line,
            sourceText.column,
            sourceText.filename,
          ),
        );
      }
      buffer.writeCharCode(unicodeEscape);
    } else {
      buffer.writeCharCode(rune);
    }
    sourceText.consume();
    while (true) {
      int? rune = sourceText.getRune();
      if (rune == null) break;
      if (isIdentifierPart(rune) || rune == 0x5c) {
        if (rune == 0x5c) {
          int? unicodeEscape = getUnicodeEscape(sourceText);
          if (unicodeEscape == null) break;
          if (!isIdentifierPart(unicodeEscape)) {
            errors.add(
              SyntaxError(
                'Invalid unicode escape in identifier',
                sourceText.line,
                sourceText.column,
                sourceText.filename,
              ),
            );
          }
          buffer.writeCharCode(unicodeEscape);
        } else {
          buffer.writeCharCode(rune);
          sourceText.consume();
        }
      } else {
        break;
      }
    }
    return Identifier(line, column, sourceText.filename, buffer.toString());
  }
  throw UnimplementedError(
    'no rules matched token U+${rune.toRadixString(16).padLeft(4, '0')}',
  );
}

class SyntaxError {
  // TODO: i think this should be a js-style object
  final String error;
  final int line;
  final int column;
  final String file;

  @override
  String toString() => '$error $file:$line:$column';
  SyntaxError(this.error, this.line, this.column, this.file);
}

int? getUnicodeEscape(SourceTextIterator sourceText) {
  sourceText.save();
  sourceText.consume();
  if (sourceText.getRune() != 0x75) {
    sourceText.restore();
    return null;
  }
  sourceText.consume();
  int? hex1 = getHexDigit(sourceText);
  if (hex1 == null) {
    int? rune = sourceText.getRune();
    if (rune != 0x7b) {
      sourceText.restore();
      return null;
    }
    sourceText.consume();
    int? hexDigits = getHexDigits(sourceText, false);
    if (hexDigits == null ||
        hexDigits > 0x10fff ||
        sourceText.getRune() != 0x7d) {
      sourceText.restore();
      return null;
    }
    sourceText.consume();
    return hexDigits;
  }
  int? hex2 = getHexDigit(sourceText);
  int? hex3 = getHexDigit(sourceText);
  int? hex4 = getHexDigit(sourceText);
  if (hex2 == null || hex3 == null || hex4 == null) {
    sourceText.restore();
    return null;
  }
  return hex1 * 0x1000 + hex2 * 0x100 + hex3 * 0x10 + hex4;
}

int? getHexDigit(SourceTextIterator sourceText) {
  int? rune = sourceText.getRune();
  if (rune == null) return null;
  if (rune >= 0x30 && rune <= 0x39) {
    sourceText.consume();
    return rune - 0x30;
  }
  if (rune >= 0x41 && rune <= 0x46) {
    sourceText.consume();
    return rune - 0x41 + 0xa;
  }
  if (rune >= 0x61 && rune <= 0x66) {
    sourceText.consume();
    return rune - 0x61 + 0xa;
  }
  return null;
}

int? getHexDigits(SourceTextIterator sourceText, bool separator) {
  int? digit1 = getHexDigit(sourceText);
  if (digit1 == null) return null;
  int buffer = digit1;
  while (true) {
    int? digit = getHexDigit(sourceText);
    if (digit == null) {
      if (!separator || sourceText.getRune() != 0x5f) {
        break;
      }
      sourceText.consume();
    } else {
      buffer *= 0x10;
      buffer += digit;
    }
  }
  return buffer;
}
