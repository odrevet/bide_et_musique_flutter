import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

const host = 'www.bide-et-musique.com';
const baseUri = 'http://$host';

String stripTags(String htmlString) {
  var document = parser.parse(htmlString);
  return parser.parse(document.body.text).documentElement.text;
}

void onLinkTap(String url){
  _launchURL(url);
}

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}