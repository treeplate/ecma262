import 'package:ecma262/ecma262.dart';

void main(List<String> arguments) {
  SourceTextIterator file = SourceTextIterator('test', 'me\\u006fw meow\n i am a c\\u{6f}w');
  List<SyntaxError> errors = [];
  while (!file.isDone) {
    Token token = tokenize(file, InputElementType.div, errors);
    if (token is! NonToken) {
      print(token);
    }
  }
  print(errors);
}
