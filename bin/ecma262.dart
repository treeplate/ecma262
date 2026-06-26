import 'package:ecma262/lexer.dart';

void main(List<String> arguments) {
  SourceTextIterator file = SourceTextIterator('test', '/*/ */1');
  List<SyntaxError> errors = [];
  while (!file.isDone) {
    Token token = tokenize(file, InputElementType.div, errors);
    if (token is! NonToken) {
      print(token);
    }
  }
  print(errors);
}
