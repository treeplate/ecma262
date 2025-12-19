import 'package:ecma262/ecma262.dart';
import 'package:test/test.dart';

void main() {
  test('identifiers, whitespace, comments', () {
    SourceTextIterator file = SourceTextIterator(
      'test',
      'me\\u006fw meow\n i/*meow*/am a c\\u{6f}w',
    );
    List<SyntaxError> errors = [];
    expect(
      (tokenize(file, InputElementType.div, errors) as Identifier).name,
      'meow',
    );
    expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
    expect(
      (tokenize(file, InputElementType.div, errors) as Identifier).name,
      'meow',
    );
    expect(tokenize(file, InputElementType.div, errors), isA<LineTerminator>());
    expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
    expect(
      (tokenize(file, InputElementType.div, errors) as Identifier).name,
      'i',
    );
    expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
    expect(
      (tokenize(file, InputElementType.div, errors) as Identifier).name,
      'am',
    );
    expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
    expect(
      (tokenize(file, InputElementType.div, errors) as Identifier).name,
      'a',
    );
    expect(tokenize(file, InputElementType.div, errors), isA<NonToken>());
    expect(
      (tokenize(file, InputElementType.div, errors) as Identifier).name,
      'cow',
    );
  });
}
