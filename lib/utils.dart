import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:url_launcher/url_launcher.dart';

import 'models/song.dart';
import 'services/account.dart';
import 'services/artist.dart';
import 'services/program.dart';
import 'services/song.dart';
import 'widgets/account.dart';
import 'widgets/artist.dart';
import 'widgets/program.dart';
import 'widgets/song_page.dart';

const site = 'bide-et-musique.com';
const host = 'www.$site';
const baseUri = 'https://$host';

const radioIcon = '\u{1F4FB}';
const songIcon = '♪';

var linkStyle = const TextStyle(
  color: Colors.red,
);

var defaultStyle = const TextStyle(
  color: Colors.black,
);

int? getIdFromUrl(String url) {
  final idRegex = RegExp(r'(\d+).(?:html|php)$');
  if (idRegex.hasMatch(url)) return int.parse(idRegex.firstMatch(url)![1]!);
  return null;
}

String stripTags(String? htmlString) {
  var document = parser.parse(htmlString);
  return parser.parse(document.body!.text).documentElement!.text;
}

//handle an url (e.g deep link) if the app can understand it returns the
//corresponding Widget or returns false otherwise
Widget? handleLink(String url, BuildContext context) {
  RegExp regExp = RegExp(
      r'https?:\/\/www.bide-et-musique.com\/(\w+)\/(\d+).html',
      caseSensitive: false);

  if (regExp.hasMatch(url) == true) {
    var type = regExp.firstMatch(url)![1];
    int id = int.parse(regExp.firstMatch(url)![2]!);

    switch (type) {
      case 'song':
        return SongPageWidget(
            songLink: SongLink(id: id, name: ''), song: fetchSong(id));
      case 'account':
        return AccountPage(account: fetchAccount(id));
      case 'artist':
        return ArtistPageWidget(artist: fetchArtist(id));
      case 'program':
        return ProgramPage(program: fetchProgram(id));
      default:
        return null;
    }
  }

  return null;
}

void onLinkTap(String url, BuildContext context) {
  if (url.startsWith('/')) url = baseUri + url;
  Widget? widget = handleLink(url, context);
  if (widget == null) {
    launchURL(url);
  } else {
    Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
  }
}

launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

String createTag(SongLink songLink) {
  return songLink.index == null
      ? 'cover_${songLink.id}'
      : 'cover_${songLink.id}_${songLink.index}';
}
