import 'dart:math';

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

class LineTerminatorToken extends Token {
  LineTerminatorToken(super.line, super.column, super.file);

  @override
  String toString() => '<line terminator>';
}

class IdentifierToken extends Token {
  IdentifierToken(
    super.line,
    super.column,
    super.file,
    this.name,
    this.private,
  );

  final String name;
  final bool private;

  IdentifierToken asPrivate() =>
      IdentifierToken(line, column, file, name, true);

  @override
  String toString() => '${private ? 'private ' : ''}identifier $name';
}

enum Punctuator {
  leftBrace,
  rightBrace,
  leftParen,
  rightParen,
  leftSquare,
  rightSquare,
  colon,
  semicolon,
  comma,

  period,
  ellipsis,

  less,
  greater,
  lessEquals,
  greaterEquals,
  leftShift,
  rightShift,
  rightShiftUnsigned,
  leftShiftEquals,
  rightShiftEquals,
  rightShiftUnsignedEquals,

  equals,
  equalsEquals,
  equalsEqualsEquals,
  arrow,

  bitwiseNot,
  not,
  notEquals,
  notEqualsEquals,

  and,
  or,
  logicalAnd,
  logicalOr,
  andEquals,
  orEquals,
  logicalAndEquals,
  logicalOrEquals,

  xor,
  xorEquals,
  div,
  divEquals,
  mod,
  modEquals,

  times,
  pow,
  timesEquals,
  powEquals,
  add,
  subtract,
  addOne,
  subtractOne,
  addEquals,
  subtractEquals,

  question,
  questionQuestion,
  questionQuestionEquals,
  optionalChaining,
}

class PunctuatorToken extends Token {
  PunctuatorToken(super.line, super.column, super.file, this.punctuator);

  final Punctuator punctuator;

  @override
  String toString() => '$punctuator';
}

class NumberToken extends Token {
  NumberToken(super.line, super.column, super.file, this.number);

  final double number;

  @override
  String toString() => 'Number:$number';
}

class BigIntToken extends Token {
  BigIntToken(super.line, super.column, super.file, this.bigInt);

  final BigInt bigInt;

  @override
  String toString() => 'BigInt:$bigInt';
}

class StringToken extends Token {
  StringToken(super.line, super.column, super.file, this.string);

  final String string;

  @override
  String toString() => '"$string"';
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
Map<int, Punctuator> punctuators = {
  0x21: .not,
  0x25: .mod,
  0x26: .and,
  0x28: .leftParen,
  0x29: .rightParen,
  0x2a: .times,
  0x2b: .add,
  0x2c: .comma,
  0x2d: .subtract,
  0x2e: .period,
  0x2f: .div,
  0x3a: .colon,
  0x3b: .semicolon,
  0x3c: .less,
  0x3d: .equals,
  0x3e: .greater,
  0x3f: .question,
  0x5b: .leftSquare,
  0x5d: .rightSquare,
  0x5e: .xor,
  0x7b: .leftBrace,
  0x7c: .or,
  0x7d: .rightBrace,
  0x7e: .bitwiseNot,
};
Set<int> singlePunctuators = {
  0x7b,
  0x28,
  0x29,
  0x5b,
  0x5d,
  0x3a,
  0x3b,
  0x2c,
  0x7e,
};

Map<int, int> escapeCharacters = {
  0x62: 0x08,
  0x66: 0x0c,
  0x6e: 0x0a,
  0x72: 0x0d,
  0x74: 0x09,
  0x76: 0x0b,
};

bool isIdentifierStart(int rune) {
  return isIDStart(rune) || rune == 0x24;
}

bool isIdentifierPart(int rune) {
  return isIDContinue(rune) || rune == 0x24 || rune == 0x5f;
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
  // WhiteSpace
  if (spaces.contains(rune)) {
    sourceText.consume();
    return NonToken(line, column, filename);
  }
  // LineTerminator
  if (lineTerminators.contains(rune)) {
    sourceText.consume();
    return LineTerminatorToken(line, column, filename);
  }
  // Comment
  if (rune == 0x2f) {
    sourceText.save();
    sourceText.consume();
    // SingleLineComment
    int? rune2 = sourceText.getRune();
    if (rune2 == 0x2f) {
      sourceText.stackDown();
      sourceText.consume();
      while (true) {
        int? rune3 = sourceText.getRune();
        if (rune3 == null || lineTerminators.contains(rune3)) {
          break;
        }
        sourceText.consume();
      }
      return NonToken(line, column, filename);
    }
    // MultiLineComment
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
          return LineTerminatorToken(line, column, filename);
        } else {
          return NonToken(line, column, filename);
        }
      }
    }
    sourceText.restore();
  }
  // CommonToken
  // IdentifierName
  IdentifierToken? identifier = parseIdentifier(
    sourceText,
    errors,
    line,
    column,
  );
  if (identifier != null) {
    return identifier;
  }
  // PrivateIdentifier
  if (rune == 0x23) {
    sourceText.save();
    sourceText.consume();
    IdentifierToken? identifier = parseIdentifier(
      sourceText,
      errors,
      line,
      column,
    );
    if (identifier == null) {
      sourceText.restore();
    } else {
      sourceText.stackDown();
      return identifier.asPrivate();
    }
  }
  // NumericLiteral (before Punctuator because of periods)
  // DecimalBigIntegerLiteral
  BigInt? bigIntegerLiteral = getDecimalBigIntegerLiteral(sourceText);
  if (bigIntegerLiteral != null) {
    return BigIntToken(line, column, filename, bigIntegerLiteral);
  }
  // DecimalLiteral
  int? integerLiteral = getDecimalIntegerLiteral(sourceText, errors);
  if (integerLiteral != null) {
    if (sourceText.getRune() == 0x2e) {
      sourceText.consume();
      ({int value, int length})? decimalDigits = getDigitsWithLength(
        sourceText,
        true,
        10,
      );
      int? exponentPart = getExponentPart(sourceText, true);
      return NumberToken(
        line,
        column,
        filename,
        (integerLiteral.toDouble() +
                ((decimalDigits?.value ?? 0) *
                    pow(10, -(decimalDigits?.length ?? 0)))) *
            pow(10, exponentPart ?? 0),
      );
    }
    int? exponentPart = getExponentPart(sourceText, true);
    return NumberToken(
      line,
      column,
      filename,
      integerLiteral.toDouble() * pow(10, exponentPart ?? 0),
    );
  }
  if (sourceText.getRune() == 0x2e) {
    sourceText.save();
    sourceText.consume();
    ({int value, int length})? decimalDigits = getDigitsWithLength(
      sourceText,
      true,
      10,
    );
    if (decimalDigits == null) {
      sourceText.restore();
    } else {
      sourceText.stackDown();

      int? exponentPart = getExponentPart(sourceText, true);
      return NumberToken(
        line,
        column,
        filename,
        decimalDigits.value.toDouble() *
            pow(10, -decimalDigits.value) *
            pow(10, exponentPart ?? 0),
      );
    }
  }
  // NonDecimalIntegerLiteral
  BigInt? nonDecimalIntegerLiteral = getNonDecimalIntegerLiteral(
    sourceText,
    errors,
    true,
  );
  if (nonDecimalIntegerLiteral != null) {
    if (sourceText.getRune() == 0x6e) {
      sourceText.consume();
      return BigIntToken(line, column, filename, nonDecimalIntegerLiteral);
    } else {
      return NumberToken(
        line,
        column,
        filename,
        nonDecimalIntegerLiteral.toDouble(),
      );
    }
  }
  if (rune == 0x30) {
    sourceText.consume();
    if (getDigit(sourceText, 10) != null) {
      // in non-strict mode this is supposed to work fine, but it's legacy syntax so nobody should be relying on this
      errors.add(
        SyntaxError(
          'You cannot have a zero before another number.',
          sourceText.line,
          sourceText.column,
          sourceText.filename,
        ),
      );
    }
    return NumberToken(line, column, filename, 0);
  }
  // Punctuator
  if (singlePunctuators.contains(rune)) {
    sourceText.consume();
    return PunctuatorToken(line, column, filename, punctuators[rune]!);
  }
  if (rune == 0x2e) {
    sourceText.consume();
    if (sourceText.getRune() == 0x2e) {
      sourceText.save();
      sourceText.consume();
      if (sourceText.getRune() == 0x2e) {
        sourceText.consume();
        sourceText.stackDown();
        return PunctuatorToken(line, column, filename, .ellipsis);
      }
      sourceText.restore();
    }
    return PunctuatorToken(line, column, filename, .period);
  }
  if (rune == 0x25) {
    sourceText.consume();
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .modEquals);
    }
    return PunctuatorToken(line, column, filename, .mod);
  }
  if (rune == 0x3c) {
    sourceText.consume();
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .lessEquals);
    }
    if (sourceText.getRune() == 0x3c) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .leftShiftEquals);
      }
      return PunctuatorToken(line, column, filename, .leftShift);
    }
    return PunctuatorToken(line, column, filename, .less);
  }
  if (rune == 0x3e) {
    sourceText.consume();
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .greaterEquals);
    }
    if (sourceText.getRune() == 0x3e) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .rightShiftEquals);
      }
      if (sourceText.getRune() == 0x3e) {
        sourceText.consume();
        if (sourceText.getRune() == 0x3d) {
          sourceText.consume();
          return PunctuatorToken(
            line,
            column,
            filename,
            .rightShiftUnsignedEquals,
          );
        }
        return PunctuatorToken(line, column, filename, .rightShiftUnsigned);
      }
      return PunctuatorToken(line, column, filename, .rightShift);
    }
    return PunctuatorToken(line, column, filename, .greater);
  }
  if (rune == 0x3d) {
    sourceText.consume();
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .equalsEqualsEquals);
      }
      return PunctuatorToken(line, column, filename, .equalsEquals);
    }
    if (sourceText.getRune() == 0x3e) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .arrow);
    }
    return PunctuatorToken(line, column, filename, .equals);
  }
  if (rune == 0x21) {
    sourceText.consume();
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .notEqualsEquals);
      }
      return PunctuatorToken(line, column, filename, .notEquals);
    }
    return PunctuatorToken(line, column, filename, .not);
  }
  if (rune == 0x2b) {
    sourceText.consume();
    if (sourceText.getRune() == 0x2b) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .addOne);
    }
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .addEquals);
    }
    return PunctuatorToken(line, column, filename, .add);
  }
  if (rune == 0x2d) {
    sourceText.consume();
    if (sourceText.getRune() == 0x2d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .subtractOne);
    }
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .subtractEquals);
    }
    return PunctuatorToken(line, column, filename, .subtract);
  }
  if (rune == 0x2a) {
    sourceText.consume();
    if (sourceText.getRune() == 0x2a) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .powEquals);
      }
      return PunctuatorToken(line, column, filename, .pow);
    }
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .timesEquals);
    }
    return PunctuatorToken(line, column, filename, .times);
  }
  if (rune == 0x26) {
    sourceText.consume();
    if (sourceText.getRune() == 0x26) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .logicalAndEquals);
      }
      return PunctuatorToken(line, column, filename, .logicalAnd);
    }
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .andEquals);
    }
    return PunctuatorToken(line, column, filename, .and);
  }
  if (rune == 0x7c) {
    sourceText.consume();
    if (sourceText.getRune() == 0x7c) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .logicalOrEquals);
      }
      return PunctuatorToken(line, column, filename, .logicalOr);
    }
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .orEquals);
    }
    return PunctuatorToken(line, column, filename, .or);
  }
  if (rune == 0x5e) {
    sourceText.consume();
    if (sourceText.getRune() == 0x3d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .xorEquals);
    }
    return PunctuatorToken(line, column, filename, .xor);
  }
  if (rune == 0x3f) {
    sourceText.consume();
    if (sourceText.getRune() == 0x2e) {
      sourceText.save();
      sourceText.consume();
      int? digit = getDigit(sourceText, 10);
      if (digit == null) {
        sourceText.stackDown();
        return PunctuatorToken(line, column, filename, .optionalChaining);
      }
      sourceText.restore();
    }
    if (sourceText.getRune() == 0x3f) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .questionQuestionEquals);
      }
      return PunctuatorToken(line, column, filename, .questionQuestion);
    }
    return PunctuatorToken(line, column, filename, .question);
  }
  // StringLiteral
  if (rune == 0x22 || rune == 0x27) {
    sourceText.consume();
    StringBuffer buffer = StringBuffer();
    while (true) {
      int? newRune = sourceText.getRune();
      if (newRune == null) {
        errors.add(
          SyntaxError(
            'EOF inside string',
            sourceText.line,
            sourceText.column,
            sourceText.filename,
          ),
        );
        return StringToken(line, column, filename, buffer.toString());
      }
      if (newRune == 0xa || newRune == 0xd) {
        errors.add(
          SyntaxError(
            'line termintator inside string',
            sourceText.line,
            sourceText.column,
            sourceText.filename,
          ),
        );
        return StringToken(line, column, filename, buffer.toString());
      }
      if (newRune == 0x5c) {
        sourceText.consume();
        newRune = sourceText.getRune();
        if (newRune == null) {
          errors.add(
            SyntaxError(
              'EOF inside string (during escape sequence)',
              sourceText.line,
              sourceText.column,
              sourceText.filename,
            ),
          );
          return StringToken(line, column, filename, buffer.toString());
        }
        if (newRune == 0xa || newRune == 0x2028 || newRune == 0x2029) {
          sourceText.consume();
          continue;
        }
        if (newRune == 0xd) {
          sourceText.consume();
          if (sourceText.getRune() == 0xa) {
            sourceText.consume();
          }
          continue;
        }
        sourceText.save();
        if (getDigit(sourceText, 10) != null) {
          // in non-strict mode this is supposed to work fine, but it's legacy syntax so nobody should be relying on this
          errors.add(
            SyntaxError(
              'You cannot have a number at the start of an escape sequence.',
              sourceText.line,
              sourceText.column,
              sourceText.filename,
            ),
          );
        }
        sourceText.restore();
        if (escapeCharacters.containsKey(newRune)) {
          sourceText.consume();
          buffer.writeCharCode(escapeCharacters[newRune]!);
          continue;
        }
        if (newRune == 0x78) {
          sourceText.save();
          sourceText.consume();
          int? digit1 = getHexDigit(sourceText);
          int? digit2 = getHexDigit(sourceText);
          if (digit2 != null) {
            sourceText.stackDown();
            buffer.writeCharCode(digit1! * 16 + digit2);
            continue;
          } else {
            sourceText.restore();
          }
        }
        int? unicodeEscape = getUnicodeEscape(sourceText);
        if (unicodeEscape != null) {
          buffer.writeCharCode(unicodeEscape);
          continue;
        }
        sourceText.consume();
        buffer.writeCharCode(newRune);
        continue;
      }
      if (newRune == rune) {
        sourceText.consume();
        return StringToken(line, column, filename, buffer.toString());
      }
      sourceText.consume();
      buffer.writeCharCode(newRune);
    }
  }
  // TODO: template
  if (inputElementType == .div || inputElementType == .templateTail) {
    // DivPunctuator
    if (rune == 0x2f) {
      sourceText.consume();
      if (sourceText.getRune() == 0x3d) {
        sourceText.consume();
        return PunctuatorToken(line, column, filename, .divEquals);
      }
      return PunctuatorToken(line, column, filename, .div);
    }
  }
  if (inputElementType == .div || inputElementType == .regExp) {
    // RightBracePunctuator
    if (rune == 0x7d) {
      sourceText.consume();
      return PunctuatorToken(line, column, filename, .rightBrace);
    }
  }
  if (inputElementType == .regExp ||
      inputElementType == .regExpOrTemplateTail ||
      inputElementType == .hashbangOrRegExp) {
    // TODO: reg exp
  }
  if (inputElementType == .regExpOrTemplateTail ||
      inputElementType == .templateTail) {
    // TODO: template substitution tail
  }
  if (inputElementType == .hashbangOrRegExp) {
    // HashbangComment
    if (rune == 0x23) {
      sourceText.save();
      sourceText.consume();
      if (sourceText.getRune() == 0x21) {
        sourceText.stackDown();
        sourceText.consume();
        while (true) {
          int? rune3 = sourceText.getRune();
          if (rune3 == null || lineTerminators.contains(rune3)) {
            break;
          }
          sourceText.consume();
        }
        return NonToken(line, column, filename);
      }
      sourceText.restore();
    }
  }
  throw UnimplementedError(
    'no implemented rules matched token U+${rune.toRadixString(16).padLeft(4, '0')}',
  );
}

IdentifierToken? parseIdentifier(
  SourceTextIterator sourceText,
  List<SyntaxError> errors,
  int line,
  int column,
) {
  StringBuffer buffer = StringBuffer();
  int? rune = sourceText.getRune();
  if (rune == null) return null;
  if (rune == 0x5c) {
    sourceText.save();
    sourceText.consume();
    int? unicodeEscape = getUnicodeEscape(sourceText);
    if (unicodeEscape == null) {
      sourceText.restore();
      return null;
    }
    sourceText.stackDown();
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
  } else if (isIdentifierStart(rune)) {
    buffer.writeCharCode(rune);
  } else {
    return null;
  }
  sourceText.consume();
  while (true) {
    int? rune = sourceText.getRune();
    if (rune == null) break;
    if (isIdentifierPart(rune) || rune == 0x5c) {
      if (rune == 0x5c) {
        sourceText.save();
        sourceText.consume();
        int? unicodeEscape = getUnicodeEscape(sourceText);
        if (unicodeEscape == null) {
          sourceText.restore();
          break;
        }
        sourceText.stackDown();
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
  return IdentifierToken(
    line,
    column,
    sourceText.filename,
    buffer.toString(),
    false,
  );
}

class SyntaxError {
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
    int? hexDigits = getDigitsWithLength(sourceText, false, 16)?.value;
    if (hexDigits == null ||
        hexDigits > 0x10fff ||
        sourceText.getRune() != 0x7d) {
      sourceText.restore();
      return null;
    }
    sourceText.consume();
    sourceText.stackDown();
    return hexDigits;
  }
  int? hex2 = getHexDigit(sourceText);
  int? hex3 = getHexDigit(sourceText);
  int? hex4 = getHexDigit(sourceText);
  if (hex2 == null || hex3 == null || hex4 == null) {
    sourceText.restore();
    return null;
  }
  sourceText.stackDown();
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

/// radix <= 10
int? getNonHexDigit(SourceTextIterator sourceText, int radix) {
  int? rune = sourceText.getRune();
  if (rune == null) return null;
  if (rune >= 0x30 && rune < 0x30 + radix) {
    sourceText.consume();
    return rune - 0x30;
  }
  return null;
}

int? getDigit(SourceTextIterator sourceText, int radix) {
  if (radix <= 10) {
    return getNonHexDigit(sourceText, radix);
  } else {
    assert(radix == 16);
    return getHexDigit(sourceText);
  }
}

({int value, int length})? getDigitsWithLength(
  SourceTextIterator sourceText,
  bool separator,
  int radix,
) {
  int? digit1 = getDigit(sourceText, radix);
  if (digit1 == null) return null;
  int buffer = digit1;
  int length = 1;
  while (true) {
    int? digit = getDigit(sourceText, radix);
    if (digit == null) {
      if (!separator || sourceText.getRune() != 0x5f) {
        break;
      }
      sourceText.consume();
    } else {
      buffer *= radix;
      buffer += digit;
      length += 1;
    }
  }
  return (value: buffer, length: length);
}

({BigInt value, int length})? getBigIntDigitsWithLength(
  SourceTextIterator sourceText,
  bool separator,
  int radix,
) {
  int? digit1 = getDigit(sourceText, radix);
  if (digit1 == null) return null;
  BigInt buffer = BigInt.from(digit1);
  int length = 1;
  while (true) {
    int? digit = getDigit(sourceText, radix);
    if (digit == null) {
      if (!separator || sourceText.getRune() != 0x5f) {
        break;
      }
      sourceText.consume();
    } else {
      buffer *= BigInt.from(radix);
      buffer += BigInt.from(digit);
      length++;
    }
  }
  return (value: buffer, length: length);
}

int? getSignedInteger(SourceTextIterator sourceText, bool separator) {
  int? rune = sourceText.getRune();
  bool negated = false;
  sourceText.save();
  if (rune == 0x2b) {
    sourceText.consume();
  } else if (rune == 0x2d) {
    negated = true;
    sourceText.consume();
  }
  int? signedInteger = getDigitsWithLength(sourceText, separator, 10)?.value;
  if (signedInteger == null) {
    sourceText.restore();
    return null;
  }
  sourceText.stackDown();
  return signedInteger * (negated ? -1 : 1);
}

int? getExponentPart(SourceTextIterator sourceText, bool separator) {
  int? rune = sourceText.getRune();
  if (rune != 0x45 && rune != 0x65) {
    return null;
  }
  sourceText.save();
  sourceText.consume();
  int? signedInteger = getSignedInteger(sourceText, separator);
  if (signedInteger == null) {
    sourceText.restore();
  } else {
    sourceText.stackDown();
  }
  return signedInteger;
}

BigInt? getDecimalBigIntegerLiteral(SourceTextIterator sourceText) {
  int? rune = sourceText.getRune();
  if (rune == null) {
    return null;
  }
  sourceText.save();
  if (rune == 0x30) {
    sourceText.consume();
    int? rune2 = sourceText.getRune();
    if (rune2 != 0x6e) {
      sourceText.restore();
      return null;
    }
    sourceText.stackDown();
    sourceText.consume();
    return BigInt.from(0);
  } else if (rune >= 0x30 && rune <= 0x39) {
    int digit1 = rune - 0x30;
    sourceText.consume();
    int? rune2 = sourceText.getRune();
    if (rune2 == 0x5f) {
      sourceText.consume();
    }
    ({BigInt value, int length})? otherDigits = getBigIntDigitsWithLength(
      sourceText,
      true,
      10,
    );
    if (otherDigits == null) {
      if (rune2 == 0x5f) {
        sourceText.restore();
        return null;
      }
      int? rune3 = sourceText.getRune();
      if (rune3 != 0x6e) {
        sourceText.restore();
        return null;
      }
      sourceText.stackDown();
      sourceText.consume();
      return BigInt.from(digit1);
    }
    int? rune3 = sourceText.getRune();
    if (rune3 != 0x6e) {
      sourceText.restore();
      return null;
    }
    sourceText.stackDown();
    sourceText.consume();
    return BigInt.from(digit1) * BigInt.from(10).pow(otherDigits.length) +
        otherDigits.value;
  } else {
    sourceText.restore();
    return null;
  }
}

int? getDecimalIntegerLiteral(
  SourceTextIterator sourceText,
  List<SyntaxError> errors,
) {
  int? rune = sourceText.getRune();
  if (rune == null) {
    return null;
  }
  if (rune > 0x30 && rune <= 0x39) {
    int digit1 = rune - 0x30;
    sourceText.consume();
    int? rune2 = sourceText.getRune();
    if (rune2 == 0x5f) {
      sourceText.consume();
    }
    ({BigInt value, int length})? otherDigits = getBigIntDigitsWithLength(
      sourceText,
      true,
      10,
    );
    if (otherDigits == null) {
      return digit1;
    }
    return digit1 * pow(10, otherDigits.length).toInt() +
        otherDigits.value.toInt();
  } else {
    return null;
  }
}

/// not necessarily a bigint, if there's no n at the end convert it to a regular int
BigInt? getNonDecimalIntegerLiteral(
  SourceTextIterator sourceText,
  List<SyntaxError> errors,
  bool separator,
) {
  if (sourceText.getRune() != 0x30) return null;
  sourceText.save();
  sourceText.consume();
  int radix;
  switch (sourceText.getRune()) {
    case 0x42:
    case 0x62:
      radix = 2;
    case 0x4f:
    case 0x6f:
      radix = 8;
    case 0x58:
    case 0x78:
      radix = 16;
    default:
      sourceText.restore();
      return null;
  }
  sourceText.consume();
  BigInt? digits = getBigIntDigitsWithLength(
    sourceText,
    separator,
    radix,
  )?.value;
  if (digits == null) {
    sourceText.restore();
    return null;
  } else {
    sourceText.stackDown();
    return digits;
  }
}
