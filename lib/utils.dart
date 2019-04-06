import 'package:html/parser.dart' as parser;

String stripTags(String htmlString) {
  var document = parser.parse(htmlString);
  String parsedString = parser.parse(document.body.text).documentElement.text;
  return parsedString;
}
