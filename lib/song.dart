import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:flutter/gestures.dart';
import 'package:share/share.dart';
import 'package:flutter_html/flutter_html.dart';
import 'utils.dart';
import 'coverViewer.dart';
import 'account.dart';
import 'identification.dart';
import 'search.dart' show fetchSearchSong;
import 'songActions.dart';
import 'artist.dart';

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

/// information available on the song page
class Song {
  int year;
  String title;
  String artists;
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
      {this.title,
      this.year,
      this.artists,
      this.artistId,
      this.author,
      this.length,
      this.label,
      this.reference,
      this.lyrics});

  factory Song.fromJson(Map<String, dynamic> json) {
    final String lyrics = json['lyrics'];
    return Song(
        title: json['name'],
        year: json['year'],
        artists: stripTags(json['artists']['main']['alias']),
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
  final SongLink song;

  SongCardWidget({Key key, this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (song.id != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SongPageWidget(
                      songLink: song, song: fetchSong(song.id))));
        }
      },
      onLongPress: () {
        Navigator.of(context).push(MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return CoverViewer(song.id);
            },
            fullscreenDialog: true));
      },
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).canvasColor),
        child: Image.network('$baseUri/images/pochettes/${song.id}.jpg'),
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
      song = Song.fromJson(json.decode(utf8.decode(responseJson.bodyBytes)));
    } catch (e) {
      song = Song(
          year: 0,
          artists: '?',
          author: '?',
          length: '?',
          label: '?',
          reference: '?',
          lyrics: e.toString());
    }
  } else {
    throw Exception('Failed to load song information');
  }

  //If connected, fetch comments and favorite status
  var session = Session();
  var response;
  if (session.id != null) {
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
        comment.author = AccountLink(accountId, accountName);
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
    var divTitre = document.getElementsByClassName('titreorange');
    song.canListen = divTitre[0].innerHtml == 'Écouter le morceau';

    //information available only if logged-in
    if (session.id != null) {
      //check if favourited
      if (divTitre.length == 2) {
        song.canFavourite = false;
        song.isFavourite = false;
      } else {
        song.canFavourite = true;
        song.isFavourite = stripTags(divTitre[2].innerHtml).trim() ==
            'Ce morceau est dans vos favoris';
      }

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
            return Text("${snapshot.error}");
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

  void _openCoverViewerDialog(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return CoverViewer(songLink.id);
        },
        fullscreenDialog: true));
  }

  Widget _buildView(BuildContext context, Song songInformations) {
    var urlCover = '$baseUri/images/pochettes/${songLink.id}.jpg';
    final _fontLyrics = TextStyle(fontSize: 20.0);

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
                                _openCoverViewerDialog(context);
                              },
                              child: Image.network(urlCover))),
                      Expanded(child: SongInformationWidget(songInformations)),
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
              padding: EdgeInsets.only(left:8.0, top:2.0),
        child: Html(
            data: songInformations.lyrics,
            defaultTextStyle: _fontLyrics),
      )


                  ),
              _buildViewComments(context, songInformations.comments),
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
    if (songInformations.canListen) {
      actions.add(startButtonSong(songLink));
    }

    var session = Session();
    if (session.id != null) {
      if (songInformations.canFavourite) {
        actions.add(
            SongFavoriteIconWidget(songLink.id, songInformations.isFavourite));
      }

      actions.add(SongVoteIconWidget(songLink.id, songInformations.hasVote));
    }

    var listenButton = IconButton(
        icon: Icon(Icons.music_note),
        onPressed: () {
          Share.share('$baseUri/stream_${songLink.id}.php');
        });

    actionsShare.add(SongShareIconWidget(songLink));
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
      padding: EdgeInsets.only(left:50.0),
      alignment: Alignment.topCenter,
      child: Row(children: actions),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(stripTags(songInformations.title)),
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
          subtitle: Text('Par ' + comment.author.name + ' ' + comment.time)));
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

class SongInformationWidget extends StatelessWidget {
  final Song _songInformations;

  SongInformationWidget(this._songInformations);

  @override
  Widget build(BuildContext context) {
    var textSpans = <TextSpan>[];

    if (_songInformations.year != 0) {
      textSpans.add(TextSpan(
          text: _songInformations.year.toString() + '\n',
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
                                          _songInformations.year.toString(),
                                          '7')),
                                ),
                              ))),
                }));
    }

    if (_songInformations.artists != null) {
      textSpans.add(TextSpan(
          text: _songInformations.artists + '\n',
          recognizer: TapGestureRecognizer()
            ..onTap = () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ArtistPageWidget(
                              artist:
                                  fetchArtist(_songInformations.artistId)))),
                }));
    }

    if (_songInformations.length != null) {
      textSpans.add(TextSpan(text: _songInformations.length + '\n'));
    }

    if (_songInformations.label != null) {
      textSpans.add(TextSpan(
          text: _songInformations.label + '\n',
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
                                      fetchSearchSong(
                                          _songInformations.label, '5')),
                                ),
                              ))),
                }));
    }

    if (_songInformations.reference != null) {
      textSpans
          .add(TextSpan(text: _songInformations.reference.toString() + '\n'));
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
    return Center(
      child: FutureBuilder<List<SongLink>>(
        future: songs,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SongListingWidget(snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
