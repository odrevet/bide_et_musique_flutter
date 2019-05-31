import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

import 'account.dart';
import 'artist.dart';
import 'program.dart';
import 'song.dart';

const host = 'www.bide-et-musique.com';
const baseUri = 'http://$host';

const stream_hq = 'http://relay2.bide-et-musique.com:9100';
const stream_lq = 'http://relay2.bide-et-musique.com:9200';

String stripTags(String htmlString) {
  var document = parser.parse(htmlString);
  return parser.parse(document.body.text).documentElement.text;
}

void onLinkTap(String url, BuildContext context) {
  //check if the url point to a page that the app can handle
  //check if point to a page
  RegExp regExp = new RegExp(r"http://www.bide-et-musique.com/(\w+)/(\d+).html",
      caseSensitive: false);

  var hasMatch = regExp.hasMatch(url);

  if (hasMatch == true) {
    var type = regExp.firstMatch(url)[1];
    var id = regExp.firstMatch(url)[2];

    switch (type) {
      case 'song':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SongPageWidget(
                    songLink: SongLink(id: id), song: fetchSong(id))));
        break;
      case 'account':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AccountPageWidget(account: fetchAccount(id))));
        break;
      case 'artist':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ArtistPageWidget(artist: fetchArtist(id))));
        break;
      case 'program':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ProgramPageWidget(program: fetchProgram(id))));
        break;
      default:
        launchURL(url);
    }
  } else {
    // otherwise launch in a browser
    launchURL(url);
  }
}

launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

Widget errorDisplay(final Object error) {
  var title = TextStyle(fontWeight: FontWeight.bold, color: Colors.red);
  var defaultStyle = TextStyle(color: Colors.black);
  var reportedError = TextStyle(fontStyle: FontStyle.italic);

  return RichText(
    text: TextSpan(
      style: defaultStyle,
      children: <TextSpan>[
        TextSpan(text: 'Ouille ouille ouille !', style: title),
        TextSpan(text: ' \n Une erreur est survenue !'),
        TextSpan(text: ' \n Le message reporté est : \n'),
        TextSpan(text: ' \n ${error.toString()}\n', style: reportedError),
        TextSpan(
            text:
                ' \n • Verifiez que votre appareil est connecté à Internet\n'),
        TextSpan(
            text:
                ' \n • Bide et Musique est peut-être temporairement indisponible, ré-éssayez ulterieurement\n')
      ],
    ),
  );
}
