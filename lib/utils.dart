import 'package:html/parser.dart' as parser;

final host = 'http://www.bide-et-musique.com';

String stripTags(String htmlString) {
  var document = parser.parse(htmlString);
  String parsedString = parser.parse(document.body.text).documentElement.text;
  return parsedString;
}
