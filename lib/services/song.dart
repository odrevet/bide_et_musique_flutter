import 'dart:async';
import 'dart:convert';

import 'package:xml/xml.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../session.dart';
import '../models/song.dart';
import '../models/nowSong.dart';
import '../models/account.dart';
import '../utils.dart';

Future<List<SongLink>> fetchNewSongs() async {
  var songs = <SongLink>[];
  final url = '$baseUri/new_song.rss';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    var document = XmlDocument.parse(body);
    for (var item in document.findAllElements('item')) {
      var link = item.children[2].text;
      var song = SongLink();
      song.id = getIdFromUrl(link);
      var artistTitle = stripTags(item.firstChild.text).split(' - ');
      song.name = artistTitle[1];
      song.artist = artistTitle[0];
      songs.add(song);
    }
    return songs;
  } else {
    throw Exception('Failed to load new songs');
  }
}

Future<List<NowSong>> fetchNowSongs() async {
  var nowSongs = <NowSong>[];
  final url = '$baseUri/morceaux-du-moment.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    dom.Element table = document.getElementsByClassName('bmtable')[0];
    var trs = table.getElementsByTagName('tr');
    trs.removeAt(0); //remove heading pagination
    trs.removeLast(); //remove leading pagination
    int index = 0;
    for (dom.Element tr in trs) {
      var tds = tr.getElementsByTagName('td');
      var songLink = SongLink();
      songLink.name = tds[3].children[0].innerHtml;
      songLink.id = getIdFromUrl(tds[3].children[0].attributes['href']);
      songLink.index = index;
      var nowSong = NowSong();
      nowSong.date = tds[0].innerHtml.trim();
      nowSong.desc = tds[4].innerHtml;
      nowSong.songLink = songLink;
      index++;
      nowSongs.add(nowSong);
    }
    return nowSongs;
  } else {
    throw Exception('Failed to load now songs');
  }
}

Future<SongNowPlaying> fetchNowPlaying() async {
  final url = '$baseUri/wapi/song/now';
  try {
    final responseJson = await Session.get(url);
    if (responseJson.statusCode == 200) {
      String decodedString = utf8.decode(responseJson.bodyBytes);
      Map<String, dynamic> decodedJson = json.decode(decodedString);
      return SongNowPlaying.fromJson(decodedJson);
    } else {
      throw ('Response was ${responseJson.statusCode}');
    }
  } catch (e) {
    print('ERROR $e');
    rethrow;
  }
}

List<Comment> parseComments(document) {
  var comments = <Comment>[];
  var divComments = document.getElementById('comments');
  var divsNormal = divComments.getElementsByClassName('normal');

  for (dom.Element divNormal in divsNormal) {
    var comment = Comment();
    try {
      var tdCommentChildren = divNormal.children;
      //get comment id (remove 'comment' string)
      comment.id =
          int.parse(tdCommentChildren[0].attributes['id'].substring(8));
      dom.Element aAccount = tdCommentChildren[1].children[0];
      int accountId = getIdFromUrl(aAccount.attributes['href']);
      String accountName = aAccount.innerHtml;
      comment.author = AccountLink(id: accountId, name: accountName);
      var commentLines = divNormal.innerHtml.split('<br>');
      commentLines.removeAt(0);
      comment.body = stripTags(commentLines.join().trim());
      comment.time = tdCommentChildren[2].innerHtml;
      comments.add(comment);
    } catch (e) {
      print(e.toString());
    }
  }
  return comments;
}

Future<Song> fetchSong(int songId) async {
  Song song;
  final responseJson = await Session.get('$baseUri/wapi/song/$songId');

  if (responseJson.statusCode == 200) {
    try {
      var decodedJson = utf8.decode(responseJson.bodyBytes);
      song = Song.fromJson(json.decode(decodedJson));
    } catch (e) {
      song = Song(
          id: songId,
          name: '?',
          year: 0,
          artist: '?',
          author: '?',
          duration: null,
          label: '?',
          reference: '?',
          lyrics: e.toString());
    }
  } else {
    throw Exception('Failed to load song with id $songId');
  }

  //fetch comments and, if connected, the favorite status
  var response = await Session.get('$baseUri/song/$songId.html');

  if (response.statusCode == 200) {
    song.canListen = false;
    song.isFavourite = false;
    song.canFavourite = false;

    var body = response.body;
    dom.Document document = parser.parse(body);

    song.comments = parseComments(document);

    var divTitres = document.getElementsByClassName('titreorange');
    for (var divTitre in divTitres) {
      var title = stripTags(divTitre.innerHtml).trim();
      switch (title) {
        case 'Écouter le morceau':
          song.canListen = true;
          break;
        case 'Ce morceau est dans vos favoris':
          song.isFavourite = true;
          song.canFavourite = true;
          break;
        case 'Ajouter à mes favoris':
          song.isFavourite = false;
          song.canFavourite = true;
          break;
      }
    }

    //available only if logged-in
    if (Session.accountLink.id != null) {
      //check vote
      var vote = document.getElementById('vote');
      if (vote == null) {
        song.hasVote = true;
      } else {
        song.hasVote = false;
      }
    } else {
      song.isFavourite = false;
      song.canFavourite = false;
    }
  } else {
    throw Exception('Failed to load song page');
  }
  return song;
}
