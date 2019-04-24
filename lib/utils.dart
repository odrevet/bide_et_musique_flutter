import 'package:html/parser.dart' as parser;

final host = 'www.bide-et-musique.com';
final baseUri = 'http://$host';

String stripTags(String htmlString) {
  var document = parser.parse(htmlString);
  return parser.parse(document.body.text).documentElement.text;
}
