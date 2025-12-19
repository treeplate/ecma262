import 'package:unicode/unicode.dart';
import 'dart:io';

List<int>? patternSyntax;
const List<int> patternWhitespace = [
  0x9,
  0xa,
  0xb,
  0xc,
  0xd,
  0x20,
  0x85,
  0x200e,
  0x200f,
  0x2028,
  0x2029,
];

bool isPatternSyntaxOrWhitespace(int rune) {
  if (patternSyntax == null) {
    patternSyntax = [];
    List<String> lines = File('PropList.txt').readAsLinesSync();
    for (String line in lines) {
      if (line.contains('Pattern_Syntax')) {
        String range = line.substring(0, line.indexOf(';')).trimRight();
        if (range.contains('..')) {
          int left = int.parse(range.substring(0, range.indexOf('..')), radix: 16);
          int right = int.parse(range.substring(range.indexOf('..') + 2), radix: 16);
          while (left <= right) {
            patternSyntax!.add(left);
            left++;
          }
        } else {
          patternSyntax!.add(int.parse(range, radix: 16));
        }
      }
    }
  }
  return patternSyntax!.contains(rune);
}

bool isIDStart(int rune) {
  if (isPatternSyntaxOrWhitespace(rune)) {
    return false;
  }
  return isUpperCaseLetter(rune) ||
      isLowerCaseLetter(rune) ||
      isTitleCaseLetter(rune) ||
      isModifierLetter(rune) ||
      isOtherLetter(rune) ||
      isLetterNumber(rune) ||
      rune == 0x1885 ||
      rune == 0x1886 ||
      rune == 0x2118 ||
      rune == 0x212e ||
      rune == 0x309b ||
      rune == 0x309c;
}

bool isIDContinue(int rune) {
  if (isPatternSyntaxOrWhitespace(rune)) {
    return false;
  }
  return isIDStart(rune) ||
      isNonspacingMark(rune) ||
      isSpacingMark(rune) ||
      isDecimalNumber(rune) ||
      isConnectorPunctuation(rune) ||
      rune == 0xb7 ||
      rune == 0x387 ||
      rune >= 0x1369 && rune <= 0x1371 ||
      rune == 0x19da ||
      rune == 0x200c ||
      rune == 0x200d ||
      rune == 0x30fb ||
      rune == 0xff65;
}
