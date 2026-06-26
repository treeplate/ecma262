import 'package:ecma262/lexer.dart';

void main(List<String> arguments) {
  // TODO: this currently does not work
  SourceTextIterator file = SourceTextIterator('test', '0.005');
  List<SyntaxError> errors = [];
  while (!file.isDone) {
    Token token = tokenize(file, InputElementType.div, errors);
    if (token is! NonToken) {
      print(token);
    }
  }
  print(errors);
}
