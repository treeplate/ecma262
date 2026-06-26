import 'package:ecma262/lexer.dart';

sealed class ParseNode {}

sealed class ModuleItem extends ParseNode {}

class ImportDeclaration extends ModuleItem {}

class ExportDeclaration extends ModuleItem {}

sealed class StatementListItem extends ModuleItem {}

class TokenIterator {
  final SourceTextIterator sourceText;
  final List<SyntaxError> errors;
  final bool isModule;

  InputElementType getInputElementType(bool regexp, bool templateTail) {
    if (sourceText.atStart) return .hashbangOrRegExp;
    if (regexp && templateTail) return .regExpOrTemplateTail;
    if (regexp) return .regExp;
    if (templateTail) return .templateTail;
    return .div;
  }

  Token? _getToken(bool regexp, bool templateTail) {
    if (sourceText.isDone) return null;
    return tokenize(
      sourceText,
      getInputElementType(regexp, templateTail),
      errors,
    );
  }

  // TODO: ASI
  Token? getToken(bool regexp, bool templateTail, bool acceptNewlines) {
    while (!sourceText.isDone) {
      sourceText.save();
      Token? token = _getToken(regexp, templateTail);
      if (token is NonToken) {
        sourceText.stackDown();
        continue;
      }
      if (token is LineTerminatorToken) {
        if (acceptNewlines) {
          sourceText.stackDown();
          continue;
        }
        sourceText.restore();
        return null;
      }
      sourceText.stackDown();
      return token;
    }
    return null;
  }

  String? getIdentifier(
    bool regexp,
    bool templateTail, [
    bool acceptNewlines = true,
  ]) {
    sourceText.save();
    Token? token = getToken(regexp, templateTail, acceptNewlines);
    if (token is IdentifierToken) {
      sourceText.stackDown();
      return token.name;
    }
    sourceText.restore();
    return null;
  }

  bool getKeyword(
    bool regexp,
    bool templateTail,
    String keyword, [
    bool acceptNewlines = true,
  ]) {
    sourceText.save();
    String? token = getIdentifier(regexp, templateTail, acceptNewlines);
    if (token == keyword) {
      sourceText.stackDown();
      return true;
    }
    sourceText.restore();
    return false;
  }

  bool get isDone {
    if (sourceText.isDone) return true;
    sourceText.save();
    Token? token = getToken(true, false, true);
    if (token == null) {
      sourceText.stackDown();
      return true;
    }
    sourceText.restore();
    return false;
  }

  TokenIterator(this.sourceText, this.errors, this.isModule);
}

List<StatementListItem> parseScript(
  SourceTextIterator sourceText,
  List<SyntaxError> errors,
) {
  TokenIterator tokens = TokenIterator(sourceText, errors, false);
  List<StatementListItem> list = parseStatementList(
    tokens,
    yieldParam: false,
    awaitParam: false,
    returnParam: false,
  );
  // TODO: early errors (16.1.1)
  return list;
}

List<ModuleItem> parseModule(
  SourceTextIterator sourceText,
  List<SyntaxError> errors,
) {
  TokenIterator tokens = TokenIterator(sourceText, errors, true);
  List<ModuleItem> list = [];
  while (!tokens.isDone) {
    if (tokens.getKeyword(true, false, 'import')) {
      list.add(parseImportDeclaration(tokens));
    } else if (tokens.getKeyword(true, false, 'export')) {
      list.add(parseExportDeclaration(tokens));
    } else {
      list.add(
        parseStatementListItem(
          tokens,
          yieldParam: false,
          awaitParam: true,
          returnParam: false,
        ),
      );
    }
  }
  // TODO: early errors (16.2.1.1)
  return list;
}

List<StatementListItem> parseStatementList(
  TokenIterator tokens, {
  required bool yieldParam,
  required bool awaitParam,
  required bool returnParam,
}) {
  // technically, StatementList is required to have at least one item
  // but everywhere that uses it has it as optional, so it's as if it could be empty

  List<StatementListItem> list = [];
  // TODO: what if this isn't the outer statementlist but one inside a block
  while (!tokens.isDone) {
    list.add(
      parseStatementListItem(
        tokens,
        yieldParam: yieldParam,
        awaitParam: awaitParam,
        returnParam: returnParam,
      ),
    );
  }

  return list;
}

StatementListItem parseStatementListItem(
  TokenIterator tokens, {
  required bool yieldParam,
  required bool awaitParam,
  required bool returnParam,
}) {
  // TODO: implement this
  throw UnimplementedError('statement list items');
}

StatementListItem parseImportDeclaration(TokenIterator tokens) {
  // TODO: implement this
  throw UnimplementedError('imports');
}

StatementListItem parseExportDeclaration(TokenIterator tokens) {
  // TODO: implement this
  throw UnimplementedError('exports');
}
