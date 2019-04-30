import 'package:html/parser.dart' as parser;

const host = 'www.bide-et-musique.com';
const baseUri = 'http://$host';

String stripTags(String htmlString) {
  var document = parser.parse(htmlString);
  return parser.parse(document.body.text).documentElement.text;
}
