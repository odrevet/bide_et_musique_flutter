import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:flutter/gestures.dart';
import 'package:share/share.dart';
import 'utils.dart';
import 'coverViewer.dart';
import 'account.dart';
import 'ident.dart';
import 'searchWidget.dart' show fetchSearchSong;
import 'package:flutter_html/flutter_html.dart';
import 'songActions.dart';

class Song {
  String id;
  String title;
  String artist;

  Song();
}

/// information available on the song page
class SongInformations {
  int year;
  String artists;
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

  SongInformations(
      {this.year,
      this.artists,
      this.author,
      this.length,
      this.label,
      this.reference,
      this.lyrics});

  factory SongInformations.fromJson(Map<String, dynamic> json) {
    final String lyrics = json['lyrics'];
    return SongInformations(
        year: json['year'],
        artists: stripTags(json['artists']['main']['alias']),
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
  Account author;
  String body;
  String time;

  Comment();
}

String extractSongId(str) {
  final idRegex = RegExp(r'/song/(\d+).html');
  var match = idRegex.firstMatch(str);
  return match[1];
}

class SongCardWidget extends StatelessWidget {
  final Song song;

  SongCardWidget({Key key, this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SongPageWidget(
                    song: song,
                    songInformations: fetchSongInformations(song.id))));
      },
      onLongPress: () {
        Navigator.of(context).push(MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return CoverViewer(song.id);
            },
            fullscreenDialog: true));
      },
      child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
          fit: BoxFit.scaleDown,
          alignment: FractionalOffset.topCenter,
          image: NetworkImage('$baseUri/images/pochettes/${song.id}.jpg'),
        )),
      ),
    );
  }
}

Future<SongInformations> fetchSongInformations(String songId) async {
  var songInformations;
  final url = '$baseUri/song/$songId';

  final responseJson = await http.get(url);

  if (responseJson.statusCode == 200) {
    try {
      songInformations = SongInformations.fromJson(
          json.decode(utf8.decode(responseJson.bodyBytes)));
    } catch (e) {
      songInformations = SongInformations(
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

  //Fetch comments and favourited status if connected
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
        comment.author = Account(accountId, accountName);
        var commentLines = tdComment.innerHtml.split('<br>');
        commentLines.removeAt(0);
        comment.body = commentLines.join();
        comment.time = tdCommentChildren[2].innerHtml;
        comments.add(comment);
      } catch (e) {
        print(e.toString());
      }
    }
    songInformations.comments = comments;

    //check if the song is available to listen
    var divTitre = document.getElementsByClassName('titreorange');
    songInformations.canListen = divTitre[0].innerHtml == 'Écouter le morceau';

    //check if favourited
    if (session.id != null) {
      if (divTitre.length == 2) {
        songInformations.canFavourite = false;
        songInformations.isFavourite = false;
      } else {
        songInformations.canFavourite = true;
        songInformations.isFavourite =
            stripTags(divTitre[2].innerHtml).trim() ==
                'Ce morceau est dans vos favoris';
      }
    } else {
      songInformations.isFavourite = false;
      songInformations.canFavourite = false;
    }
  } else {
    throw Exception('Failed to load song page');
  }

  songInformations.hasVote = false; //TODO
  return songInformations;
}

class SongPageWidget extends StatelessWidget {
  final Song song;
  final Future<SongInformations> songInformations;

  SongPageWidget({Key key, this.song, this.songInformations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<SongInformations>(
        future: songInformations,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Chargement de "' + song.title + '"'),
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
          return CoverViewer(song.id);
        },
        fullscreenDialog: true));
  }

  Widget _buildView(BuildContext context, SongInformations songInformations) {
    var urlCover = '$baseUri/images/pochettes/${song.id}.jpg';
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
                  child: Html(
                      data: songInformations.lyrics,
                      defaultTextStyle: _fontLyrics)),
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

    //if the song can be listen, add the song player
    if (songInformations.canListen) {
      actions.add(SongPlayerWidget(song.id));
    }

    var session = Session();
    if (session.id != null) {
      if(songInformations.canFavourite){
        actions
            .add(SongFavoriteIconWidget(song.id, songInformations.isFavourite));
      }

      actions
          .add(SongVoteIconWidget(song.id, songInformations.hasVote));
    }

    //share song button
    actions.add(IconButton(
        icon: Icon(Icons.share),
        onPressed: () {
          Share.share(
              '''En ce moment j'écoute '${song.title}' sur bide et musique !
          
Tu peut consulter la fiche de cette chanson à l'adresse : 
http://bide-et-musique.com/song/${song.id}.html
          
--------
Message envoyé avec l'application 'bide et musique flutter pour android'
https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique
''');
        }));

    return Scaffold(
      appBar: AppBar(title: Text(song.title), actions: actions),
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
                        account: comment.author,
                        accountInformations:
                            fetchAccountInformations(comment.author.id))));
          },
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Image(
                image: NetworkImage(
                    '$baseUri/images/avatars/${comment.author.id}.jpg')),
          ),
          title: Html(data: comment.body),
          subtitle: Text('Par ' + comment.author.name + ' ' + comment.time)));
    }

    return ListView(children: rows);
  }
}

//////////////////
/// Display given songs in a ListView
class SongListingWidget extends StatefulWidget {
  final List<Song> _songs;

  SongListingWidget(this._songs, {Key key}) : super(key: key);

  @override
  SongListingWidgetState createState() => SongListingWidgetState(this._songs);
}

class SongListingWidgetState extends State<SongListingWidget> {
  List<Song> _songs;
  SongListingWidgetState(this._songs);

  @override
  Widget build(BuildContext context) {
    var rows = <ListTile>[];
    for (Song song in _songs) {
      rows.add(ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.black12,
          child: Image(
              image: NetworkImage('$baseUri/images/thumb25/${song.id}.jpg')),
        ),
        title: Text(
          song.title,
        ),
        subtitle: Text(song.artist == null ? '' : song.artist),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SongPageWidget(
                      song: song,
                      songInformations: fetchSongInformations(song.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
}

class SongInformationWidget extends StatelessWidget {
  final SongInformations _songInformations;

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
                          builder: (context) => SongListingFutureWidget(
                              fetchSearchSong(
                                  _songInformations.year.toString(), '7')))),
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
                          builder: (context) => SongListingFutureWidget(
                              fetchSearchSong(
                                  _songInformations.artists, '4')))),
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
                          builder: (context) => SongListingFutureWidget(
                              fetchSearchSong(_songInformations.label, '5')))),
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
  final Future<List<Song>> songs;

  SongListingFutureWidget(this.songs, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recherche de chansons'),
      ),
      body: Center(
        child: FutureBuilder<List<Song>>(
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
      ),
    );
  }
}
