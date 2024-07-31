import 'dart:async';
import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/cupertino.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:xml/xml.dart';

import '../models/account.dart';
import '../models/now_song.dart';
import '../models/song.dart';
import '../session.dart';
import '../utils.dart';

Future<List<SongLink>> fetchNewSongs() async {
  var songs = <SongLink>[];
  const url = '$baseUri/new_song.rss';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    var document = XmlDocument.parse(body);
    for (var item in document.findAllElements('item')) {
      var link = item.findAllElements('comments').first.innerText;
      var song = SongLink(
          id: getIdFromUrl(link)!,
          name: item.findAllElements('title').first.innerText);
      songs.add(song);
    }

    return songs;
  } else {
    throw Exception('Failed to load new songs');
  }
}

Future<List<NowSong>> fetchNowSongs() async {
  var nowSongs = <NowSong>[];
  const url = '$baseUri/morceaux-du-moment.html';
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
      var songLink = SongLink(
          id: getIdFromUrl(tds[3].children[0].attributes['href']!)!,
          name: tds[3].children[0].innerHtml,
          index: index);
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

Future<SongAiring> fetchAiring() async {
  const url = '$baseUri/wapi/song/now';
  try {
    final responseJson = await Session.get(url);
    if (responseJson.statusCode == 200) {
      String decodedString = utf8.decode(responseJson.bodyBytes);
      Map<String, dynamic> decodedJson = json.decode(decodedString);
      return SongAiring.fromJson(decodedJson);
    } else {
      throw ('Response was ${responseJson.statusCode}');
    }
  } catch (e) {
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
          int.parse(tdCommentChildren[0].attributes['id']!.substring(8));
      dom.Element aAccount = tdCommentChildren[1].children[0];
      int? accountId = getIdFromUrl(aAccount.attributes['href']!);
      String accountName = aAccount.innerHtml;
      comment.author = AccountLink(id: accountId, name: accountName);
      var commentLines = divNormal.innerHtml.split('<br>');
      commentLines.removeAt(0);
      comment.body = commentLines.join().trim();
      comment.time = tdCommentChildren[2].innerHtml;
      comments.add(comment);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  return comments;
}

Future<Song> fetchSong(int? songId) async {
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
      var title = divTitre.text.trim();
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

Future<void> sendEditComment(Song song, Comment comment, String text) async {
  if (text.isNotEmpty) {
    await Session.post('$baseUri/edit_comment.html?Comment__=${comment.id}',
        body: {
          'mode': 'Edit',
          'REF': song.link,
          'Comment__': comment.id.toString(),
          'Text': removeDiacritics(text),
        });
  }
}

Future<void> sendAddComment(Song song, String text) async {
  final url = song.link;
  if (text.isNotEmpty) {
    await Session.post(url, body: {
      'T': 'Song',
      'N': song.id.toString(),
      'Mode': 'AddComment',
      'Thread_': '',
      'Text': removeDiacritics(text),
      'x': '42',
      'y': '42'
    });
  }
}

SongLink songLinkFromTr(dom.Element tr) {
  var tdInfo = tr.children[0]; //program for next, HH:MM for past
  var tdArtist = tr.children[2];
  var tdSong = tr.children[3];
  String title = tdSong.text.replaceAll('\n', '');
  const String newFlag = '[nouveauté]';
  dom.Element? a;
  bool isNew = false;
  if (title.contains(newFlag)) {
    isNew = true;
    title = title.replaceFirst(newFlag, '');
    a = tdSong.children[1];
  } else {
    //sometimes the td song element is somehow empty (e.g. Seamus)
    if (tdSong.children.isNotEmpty) a = tdSong.children[0];
  }

  return SongLink(
      id: a != null ? getIdFromUrl(a.attributes['href']!)! : 0,
      artist: tdArtist.text.trim(),
      name: title.trim(),
      info: tdInfo.text.trim(),
      isNew: isNew);
}

Future<Map<String, List<SongLink>>> fetchTitles() async {
  const url = '$baseUri/programmes.php';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var songLinksNext = <SongLink>[];
    var tableNext = document.getElementById('BM_next_songs')!.children[1];
    var trsNext = tableNext.getElementsByTagName('tr');
    int indexNext = 0;
    for (dom.Element tr in trsNext) {
      SongLink songLink = songLinkFromTr(tr);
      songLink.index = indexNext;
      indexNext++;
      songLinksNext.add(songLink);
    }

    var songLinksPast = <SongLink>[];
    var tablePast = document.getElementById('BM_past_songs')!.children[1];
    var trsPast = tablePast.getElementsByTagName('tr');
    trsPast.removeLast(); //remove the 'show more' button
    int indexPast = 0;
    for (dom.Element tr in trsPast) {
      SongLink songLink = songLinkFromTr(tr);
      songLink.index = indexPast;
      indexPast++;
      songLinksPast.add(songLink);
    }

    return {'next': songLinksNext, 'past': songLinksPast};
  } else {
    throw Exception('Failed to load program');
  }
}

Future<int> voteForSong(String songLink) async {
  Session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
  Session.headers['Host'] = host;
  Session.headers['Origin'] = baseUri;
  Session.headers['Referer'] = songLink;

  final response = await Session.post(songLink, body: {'Note': '1', 'M': 'CN'});

  Session.headers.remove('Referer');
  Session.headers.remove('Content-Type');
  return response.statusCode;
}
