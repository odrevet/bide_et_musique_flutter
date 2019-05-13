import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';
import 'song.dart';

const host = 'www.bide-et-musique.com';
const baseUri = 'http://$host';

String stripTags(String htmlString) {
  var document = parser.parse(htmlString);
  return parser.parse(document.body.text).documentElement.text;
}

void onLinkTap(String url, BuildContext context) {
  //check if the url point to a page that the app can handle
  //check if point to a page
  RegExp regExp = new RegExp(r"http://www.bide-et-musique.com/song/(\d+).html",
      caseSensitive: false);

  var hasMatch = regExp.hasMatch(url);

  if (hasMatch == true) {
    var songId = regExp.firstMatch(url)[1];
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SongPageWidget(
                song: Song(id: songId),
                songInformations: fetchSongInformations(songId))));
  } else {
    // otherwise launch in a browser
    _launchURL(url);
  }
}

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
