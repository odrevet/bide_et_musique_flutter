import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:share/share.dart';

import 'account.dart';
import 'artist.dart';
import 'coverViewer.dart';
import 'identification.dart';
import 'search.dart' show fetchSearchSong;
import 'songActions.dart';
import 'utils.dart';

class SongLink {
  String id;
  String title;
  String artist;
  String program;
  bool isNew;

  SongLink(
      {this.id = '',
      this.title = '',
      this.artist = '',
      this.program = '',
      this.isNew = false});
}

class Song {
  String id;
  int year;
  String title;
  String artist;
  String artistId;
  String author;
  String length;
  String label;
  String reference;
  String lyrics;
  List<Comment> comments;
  bool canListen;
  bool canFavourite;
  bool isFavourite;
  bool hasVote;

  Song(
      {this.id,
      this.title,
      this.year,
      this.artist,
      this.artistId,
      this.author,
      this.length,
      this.label,
      this.reference,
      this.lyrics});

  factory Song.fromJson(Map<String, dynamic> json) {
    final String lyrics = json['lyrics'];
    return Song(
        id: json['id'].toString(),
        title: json['name'],
        year: json['year'],
        artist: stripTags(json['artists']['main']['alias']),
        artistId: json['artists']['main']['id'].toString(),
        author: json['author'],
        length: json['length']['pretty'],
        label: stripTags(json['label']),
        reference: stripTags(json['reference']),
        lyrics: lyrics == null
            ? 'Paroles non renseignées pour cette chanson '
            : lyrics);
  }
}

class Comment {
  AccountLink author;
  String body;
  String time;

  Comment();
}

String extractSongId(str) {
  final idRegex = RegExp(r'/song/(\d+).html');
  var match = idRegex.firstMatch(str);
  if (match != null) {
    return match[1];
  } else {
    return null;
  }
}

class SongCardWidget extends StatelessWidget {
  final SongLink songLink;

  SongCardWidget({Key key, this.songLink}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (songLink.id != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SongPageWidget(
                      songLink: songLink, song: fetchSong(songLink.id))));
        }
      },
      onLongPress: () {
        Navigator.of(context).push(MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return CoverViewer(songLink.id);
            },
            fullscreenDialog: true));
      },
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).canvasColor),
        child: Image.network('$baseUri/images/pochettes/${songLink.id}.jpg'),
      ),
    );
  }
}

Future<Song> fetchSong(String songId) async {
  var song;
  final url = '$baseUri/song/$songId';
  final responseJson = await http.get(url);

  if (responseJson.statusCode == 200) {
    try {
      var decodedJson = utf8.decode(responseJson.bodyBytes);
      song = Song.fromJson(json.decode(decodedJson));
    } catch (e) {
      song = Song(
          id: songId,
          title: '?',
          year: 0,
          artist: '?',
          author: '?',
          length: '?',
          label: '?',
          reference: '?',
          lyrics: e.toString());
    }
  } else {
    throw Exception('Failed to load song with id $songId');
  }

  //If connected, fetch comments and favorite status
  var session = Session();
  var response;
  if (session.accountLink.id != null) {
    response = await session.get(url + '.html');
  } else {
    response = await http.get(url + '.html');
  }

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var comments = <Comment>[];
    var divComments = document.getElementById('comments');
    var tdsComments = divComments.getElementsByClassName('normal');

    for (dom.Element tdComment in tdsComments) {
      var comment = Comment();
      try {
        var tdCommentChildren = tdComment.children;
        dom.Element aAccount = tdCommentChildren[1].children[0];
        String accountId = extractAccountId(aAccount.attributes['href']);
        String accountName = aAccount.innerHtml;
        comment.author = AccountLink(id: accountId, name: accountName);
        var commentLines = tdComment.innerHtml.split('<br>');
        commentLines.removeAt(0);
        comment.body = commentLines.join();
        comment.time = tdCommentChildren[2].innerHtml;
        comments.add(comment);
      } catch (e) {
        print(e.toString());
      }
    }
    song.comments = comments;

    //check if the song is available to listen
    //order of title are not consistent : need to check each title content
    song.canListen = false;
    song.isFavourite = false;
    song.canFavourite = false;

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
    if (session.accountLink.id != null) {
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

class SongPageWidget extends StatelessWidget {
  final SongLink songLink;
  final Future<Song> song;

  SongPageWidget({Key key, this.songLink, this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Song>(
        future: song,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: Text('Ouille ouille ouille !')),
              body: Center(child: Center(child: errorDisplay(snapshot.error))),
            );
          }

          var loadingMessage = 'Chargement';
          if (songLink.title.isNotEmpty) {
            loadingMessage += ' de "${songLink.title}"';
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(loadingMessage),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  void _openCoverViewerDialog(Song song, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return CoverViewer(song.id);
        },
        fullscreenDialog: true));
  }

  Widget _buildView(BuildContext context, Song song) {
    var urlCover = '$baseUri/images/pochettes/${song.id}.jpg';
    final _fontLyrics = TextStyle(fontSize: 18.0);

    var nestedScrollView = NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            backgroundColor: Theme.of(context).canvasColor,
            expandedHeight: 200.0,
            automaticallyImplyLeading: false,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
                background: Row(children: [
              Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                          child: InkWell(
                              onTap: () {
                                _openCoverViewerDialog(song, context);
                              },
                              child: Image.network(urlCover))),
                      Expanded(child: SongWidget(song)),
                    ],
                  ))
            ])),
          ),
        ];
      },
      body: Center(
          child: Container(
        child: Stack(children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.7)),
            ),
          ),
          PageView(
            children: <Widget>[
              SingleChildScrollView(
                  child: Padding(
                padding: EdgeInsets.only(left: 8.0, top: 2.0),
                child: Html(
                    data: song.lyrics,
                    defaultTextStyle: _fontLyrics,
                    onLinkTap: (url) {
                      onLinkTap(url, context);
                    }),
              )),
              _buildViewComments(context, song.comments),
            ],
          )
        ]),
        decoration: BoxDecoration(
            image: DecorationImage(
          fit: BoxFit.fill,
          alignment: FractionalOffset.topCenter,
          image: NetworkImage(urlCover),
        )),
      )),
    );

    //list of actions in the title bar
    var actions = <Widget>[];

    //list of actions for sharing
    var actionsShare = <Widget>[];

    //if the song can be listen, add the song player
    if (song.canListen) {
      actions.add(SongPlayerWidget(song));
    }

    var session = Session();
    if (session.accountLink.id != null) {
      if (song.canFavourite) {
        actions.add(SongFavoriteIconWidget(song.id, song.isFavourite));
      }

      actions.add(SongVoteIconWidget(song.id, song.hasVote));
    }

    var listenButton = IconButton(
        icon: Icon(Icons.music_note),
        onPressed: () {
          Share.share('$baseUri/stream_${song.id}.php');
        });

    actionsShare.add(SongShareIconWidget(song));
    actionsShare.add(listenButton);

    //build widget for overflow button
    var popupMenuAction = <PopupMenuEntry<Widget>>[];
    for (Widget actionWidget in actionsShare) {
      popupMenuAction.add(PopupMenuItem<Widget>(child: actionWidget));
    }

    //overflow menu
    actions.add(PopupMenuButton<Widget>(
        icon: Icon(
          Icons.share,
        ),
        itemBuilder: (BuildContext context) => popupMenuAction));

    var actionContainer = Container(
      padding: EdgeInsets.only(left: 54.0),
      alignment: Alignment.topCenter,
      child: Row(children: actions),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(stripTags(song.title)),
        bottom: PreferredSize(
          child: actionContainer,
          preferredSize: Size(0.0, 20.0),
        ),
      ),
      body: nestedScrollView,
    );
  }

  Widget _buildViewComments(BuildContext context, List<Comment> comments) {
    var rows = <ListTile>[];
    String loginName = Session().accountLink.name;
    var selfComment = TextStyle(
      color: Colors.red,
    );

    for (Comment comment in comments) {
      rows.add(ListTile(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AccountPageWidget(
                        account: fetchAccount(comment.author.id))));
          },
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Image(
                image: NetworkImage(
                    '$baseUri/images/avatars/${comment.author.id}.jpg')),
          ),
          title: Html(
              data: comment.body,
              onLinkTap: (url) {
                onLinkTap(url, context);
              }),
          subtitle: Text('Par ' + comment.author.name + ' ' + comment.time,
              style: comment.author.name == loginName ? selfComment : null)));
    }

    return ListView(children: rows);
  }
}

//////////////////
/// Display given songs in a ListView
class SongListingWidget extends StatefulWidget {
  final List<SongLink> _songLinks;

  SongListingWidget(this._songLinks, {Key key}) : super(key: key);

  @override
  SongListingWidgetState createState() =>
      SongListingWidgetState(this._songLinks);
}

class SongListingWidgetState extends State<SongListingWidget> {
  List<SongLink> _songs;

  SongListingWidgetState(this._songs);

  @override
  Widget build(BuildContext context) {
    var rows = <ListTile>[];

    for (SongLink songLink in _songs) {
      rows.add(ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Image(
                image:
                    NetworkImage('$baseUri/images/thumb25/${songLink.id}.jpg')),
          ),
          title: Text(
            songLink.title,
          ),
          trailing: songLink.isNew ? Icon(Icons.fiber_new) : null,
          subtitle: Text(songLink.artist == null ? '' : songLink.artist),
          onTap: () => launchSongPage(songLink, context)));
    }

    return ListView(children: rows);
  }
}

void launchSongPage(SongLink song, BuildContext context) {
  if (song.id != null) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SongPageWidget(songLink: song, song: fetchSong(song.id))));
  }
}

class SongWidget extends StatelessWidget {
  final Song _song;

  SongWidget(this._song);

  @override
  Widget build(BuildContext context) {
    var textSpans = <TextSpan>[];

    if (_song.year != 0) {
      textSpans.add(TextSpan(
          text: _song.year.toString() + '\n',
          recognizer: TapGestureRecognizer()
            ..onTap = () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: Text('Recherche par année'),
                                ),
                                body: Center(
                                  child: SongListingFutureWidget(
                                      fetchSearchSong(
                                          _song.year.toString(), '7')),
                                ),
                              ))),
                }));
    }

    if (_song.artist != null) {
      textSpans.add(TextSpan(
          text: _song.artist + '\n',
          recognizer: TapGestureRecognizer()
            ..onTap = () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ArtistPageWidget(
                              artist: fetchArtist(_song.artistId)))),
                }));
    }

    if (_song.length != null) {
      textSpans.add(TextSpan(text: _song.length + '\n'));
    }

    if (_song.label != null) {
      textSpans.add(TextSpan(
          text: _song.label + '\n',
          recognizer: TapGestureRecognizer()
            ..onTap = () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: Text('Recherche par label'),
                                ),
                                body: Center(
                                  child: SongListingFutureWidget(
                                      fetchSearchSong(_song.label, '5')),
                                ),
                              ))),
                }));
    }

    if (_song.reference != null) {
      textSpans.add(TextSpan(text: _song.reference.toString() + '\n'));
    }

    final textStyle = TextStyle(
      fontSize: 18.0,
      color: Colors.black,
    );

    return Center(
        child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(style: textStyle, children: textSpans)));
  }
}

//////////////////////////
// Display songs from future song list
class SongListingFutureWidget extends StatelessWidget {
  final Future<List<SongLink>> songs;

  SongListingFutureWidget(this.songs, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongLink>>(
        future: songs,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SongListingWidget(snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return CircularProgressIndicator();
        });
  }
}
