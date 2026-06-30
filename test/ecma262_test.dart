import 'package:ecma262/lexer.dart';
import 'package:ecma262/parser.dart';
import 'package:test/test.dart';

void main() {
  group('tokenisation', () {
    test('identifiers, whitespace, comments', () {
      SourceTextIterator file = SourceTextIterator(
        'test',
        'me\\u006fw meow\n i/*meow*/am a c\\u{6f}w',
      );
      List<SyntaxError> errors = [];
      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        false,
        'meow',
      );
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        false,
        'meow',
      );
      expect(
        tokenize(file, InputElementType.div, errors),
        isA<LineTerminatorToken>(),
      );
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        false,
        'i',
      );
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        false,
        'am',
      );
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        false,
        'a',
      );
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        false,
        'cow',
      );
      expect(errors, isEmpty);
    });
    test('/*/', () {
      SourceTextIterator file = SourceTextIterator('test', '/*/*/');
      List<SyntaxError> errors = [];
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expect(file.isDone, isTrue);
      expect(errors, isEmpty);
    });
    test('private identifiers', () {
      SourceTextIterator file = SourceTextIterator(
        'test',
        '#meow#meow says#cow',
      );
      List<SyntaxError> errors = [];

      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        true,
        'meow',
      );
      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        true,
        'meow',
      );
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());

      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        false,
        'says',
      );
      expectIdentifier(
        tokenize(file, InputElementType.div, errors),
        true,
        'cow',
      );
      expect(errors, isEmpty);
    });
    test('punctuators', () {
      SourceTextIterator file = SourceTextIterator(
        'test',
        '{()[]:;,. ...<><=>=<<>> >>><<=>>=>>>== == ====>~!!=!==&|&&||&=|=&&=||=^^=%%=* ***=**=+-++--+=-=? ????=?.',
      );
      List<SyntaxError> errors = [];
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .leftBrace,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .leftParen,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .rightParen,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .leftSquare,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .rightSquare,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .colon);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .semicolon,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .comma);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .period);
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectPunctuator(tokenize(file, InputElementType.div, errors), .ellipsis);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .less);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .greater);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .lessEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .greaterEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .leftShift,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .rightShift,
      );
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .rightShiftUnsigned,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .leftShiftEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .rightShiftEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .rightShiftUnsignedEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .equals);
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .equalsEquals,
      );
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .equalsEqualsEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .arrow);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .bitwiseNot,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .not);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .notEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .notEqualsEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .and);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .or);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .logicalAnd,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .logicalOr,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .andEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .orEquals);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .logicalAndEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .logicalOrEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .xor);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .xorEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .mod);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .modEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .times);
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectPunctuator(tokenize(file, InputElementType.div, errors), .pow);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .timesEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .powEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .add);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .subtract);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .addOne);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .subtractOne,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .addEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .subtractEquals,
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .question);
      expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .questionQuestion,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .questionQuestionEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .optionalChaining,
      );

      expect(errors, isEmpty);
    });
    test('numbers', () {
      SourceTextIterator file = SourceTextIterator(
        'test',
        '1,1.5,1e5,1.5e2,1n,0xa,0b11,0o3_0n',
      );
      List<SyntaxError> errors = [];
      expectNumber(tokenize(file, InputElementType.div, errors), 1);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .comma);
      expectNumber(tokenize(file, InputElementType.div, errors), 1.5);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .comma);
      expectNumber(tokenize(file, InputElementType.div, errors), 1e5);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .comma);
      expectNumber(tokenize(file, InputElementType.div, errors), 1.5e2);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .comma);
      expectBigInt(
        tokenize(file, InputElementType.div, errors),
        BigInt.from(1),
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .comma);
      expectNumber(tokenize(file, InputElementType.div, errors), 0xa);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .comma);
      expectNumber(tokenize(file, InputElementType.div, errors), 3);
      expectPunctuator(tokenize(file, InputElementType.div, errors), .comma);
      expectBigInt(
        tokenize(file, InputElementType.div, errors),
        BigInt.from(24),
      );

      expect(errors, isEmpty);
    });
    test('0.5', () {
      SourceTextIterator file = SourceTextIterator('test', '0.5');
      List<SyntaxError> errors = [];
      expectNumber(tokenize(file, InputElementType.div, errors), 0.5);
      expect(errors, isEmpty);
    });
    test('strings', () {
      SourceTextIterator file = SourceTextIterator(
        'test',
        '"cat\'s"\'"dog"\\u000a\\x0a\\u{2028}\\a\\t\\\u{2028}\\\n\\\r\n\\\r\\\u{2029}l2\'',
      );
      List<SyntaxError> errors = [];
      expectString(tokenize(file, InputElementType.div, errors), 'cat\'s');
      // ignore: unnecessary_string_escapes
      expectString(
        tokenize(file, InputElementType.div, errors),
        '"dog"\u000a\x0a\u{2028}\a\tl2',
      );

      expect(errors, isEmpty);
    });
    test('div, right brace, hashbang', () {
      SourceTextIterator file = SourceTextIterator(
        'test',
        '#! hashbang comment!\n/}}/=/',
      );
      List<SyntaxError> errors = [];
      expect(
        tokenize(file, InputElementType.hashbangOrRegExp, errors),
        isA<NonToken>(),
      );
      expect(
        tokenize(file, InputElementType.div, errors),
        isA<LineTerminatorToken>(),
      );
      expectPunctuator(tokenize(file, InputElementType.div, errors), .div);
      expectPunctuator(
        tokenize(file, InputElementType.div, errors),
        .rightBrace,
      );
      expectPunctuator(
        tokenize(file, InputElementType.regExp, errors),
        .rightBrace,
      );
      expectPunctuator(
        tokenize(file, InputElementType.templateTail, errors),
        .divEquals,
      );
      expectPunctuator(
        tokenize(file, InputElementType.templateTail, errors),
        .div,
      );

      expect(errors, isEmpty);
    });
  });
  group('parsing', () {
    test('empty modules, empty scripts', () {
      SourceTextIterator file = SourceTextIterator(
        'test',
        '#! hashbang comment\n // regular comment\n/*multi\nline\ncomment*/  /*another one*/',
      );
      List<SyntaxError> errors = [];
      expect(parseScript(file, errors), isEmpty);
      expect(errors, isEmpty);
      expect(parseModule(file, errors), isEmpty);
      expect(errors, isEmpty);
    });
  });
}

void expectIdentifier(Token token, bool shouldBePrivate, String expectedName) {
  expect(token, isA<IdentifierToken>());
  expect((token as IdentifierToken).private, shouldBePrivate);
  expect(token.name, expectedName);
}

void expectPunctuator(Token token, Punctuator expectedPunctuator) {
  expect(token, isA<PunctuatorToken>());
  expect((token as PunctuatorToken).punctuator, expectedPunctuator);
}

void expectNumber(Token token, double expectedNumber) {
  expect(token, isA<NumberToken>());
  expect((token as NumberToken).number, expectedNumber);
}

void expectString(Token token, String expectedString) {
  expect(token, isA<StringToken>());
  expect((token as StringToken).string, expectedString);
}

void expectBigInt(Token token, BigInt expectedBigInt) {
  expect(token, isA<BigIntToken>());
  expect((token as BigIntToken).bigInt, expectedBigInt);
}
