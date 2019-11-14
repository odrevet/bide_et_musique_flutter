import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

import 'account.dart';
import 'artist.dart';
import 'program.dart';
import 'song.dart';

const site = 'bide-et-musique.com';
const host = 'www.$site';
const baseUri = 'https://$host';

String stripTags(String htmlString) {
  var document = parser.parse(htmlString);
  return parser.parse(document.body.text).documentElement.text;
}

//handle an url (e.g deep link) if the app can understand it returns the
//corresponding Widget or returns false otherwise
Widget handleLink(String url, BuildContext context) {
  RegExp regExp = RegExp(
      r'https?:\/\/www.bide-et-musique.com\/(\w+)\/(\d+).html',
      caseSensitive: false);

  if (regExp.hasMatch(url) == true) {
    var type = regExp.firstMatch(url)[1];
    var id = regExp.firstMatch(url)[2];

    switch (type) {
      case 'song':
        return SongPageWidget(songLink: SongLink(id: id), song: fetchSong(id));
        break;
      case 'account':
        return AccountPageWidget(account: fetchAccount(id));
        break;
      case 'artist':
        return ArtistPageWidget(artist: fetchArtist(id));
        break;
      case 'program':
        return ProgramPageWidget(program: fetchProgram(id));
        break;
      default:
        return null;
    }
  }

  return null;
}

void onLinkTap(String url, BuildContext context) {
  //if (!handleLink(url, context)) launchURL(url);
  Widget widget = handleLink(url, context);
  if (widget == null)
    launchURL(url);
  else
    Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
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
