import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:xml/xml.dart' as xml;
import 'package:flutter_radio/flutter_radio.dart';
import 'main.dart';
import 'utils.dart';
import 'coverViewer.dart';
import 'account.dart';
import 'ident.dart';

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

  SongInformations(
      {this.year,
      this.artists,
      this.author,
      this.length,
      this.label,
      this.reference,
      this.lyrics});

  factory SongInformations.fromJson(Map<String, dynamic> json) {
    return SongInformations(
        year: json['year'],
        artists: stripTags(json['artists']['main']['alias']),
        author: json['author'],
        length: json['length']['pretty'],
        label: stripTags(json['label']),
        reference: stripTags(json['reference']),
        lyrics: stripTags(json['lyrics']));
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
  Song song;

  SongCardWidget({Key key, this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            new MaterialPageRoute(
                builder: (context) => new SongPageWidget(
                    song: song,
                    songInformations: fetchSongInformations(song.id))));
      },
      onLongPress: () {
        Navigator.of(context).push(new MaterialPageRoute<Null>(
            builder: (BuildContext context) {
              return new CoverViewer(song.id);
            },
            fullscreenDialog: true));
      },
      child: Container(
        decoration: new BoxDecoration(
            image: new DecorationImage(
          fit: BoxFit.scaleDown,
          alignment: FractionalOffset.topCenter,
          image: new NetworkImage(
              'http://www.bide-et-musique.com/images/pochettes/' +
                  song.id +
                  '.jpg'),
        )),
      ),
    );
  }
}

Future<SongInformations> fetchSongInformations(String songId) async {
  var songInformations;
  final url = 'http://www.bide-et-musique.com/song/' + songId;

  final responseJson = await http.get(url);

  if (responseJson.statusCode == 200) {
    songInformations = SongInformations.fromJson(
        json.decode(utf8.decode(responseJson.bodyBytes)));
  } else {
    throw Exception('Failed to load song information');
  }

  //Fetch comments and favourited status if connected
  var response;
  if (gSession.id != null) {
    response = await gSession.get(url + '.html');
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
      dom.Element aAccount = tdComment.children[1].children[0];
      String accountId = extractAccountId(aAccount.attributes['href']);
      String accountName = aAccount.innerHtml;
      comment.author = Account(accountId, accountName);
      comment.body = tdComment.innerHtml.split('<br>')[1];
      comment.time = tdComment.children[2].innerHtml;
      comments.add(comment);
    }
    songInformations.comments = comments;

    //check if the song is available to listen
    var divTitre = document.getElementsByClassName('titreorange');
    songInformations.canListen = divTitre[0].innerHtml == 'Écouter le morceau';

    //check if favourited
    if (gSession.id != null) {
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

  return songInformations;
}

class SongPageWidget extends StatelessWidget {
  Song song;
  Future<SongInformations> songInformations;
  final _fontLyrics = TextStyle(fontSize: 20.0);

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
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new CoverViewer(song.id);
        },
        fullscreenDialog: true));
  }

  Widget _buildView(BuildContext context, SongInformations songInformations) {
    var urlCover =
        'http://www.bide-et-musique.com/images/pochettes/' + song.id + '.jpg';

    var year =
        songInformations.year == 0 ? '?' : songInformations.year.toString();

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
                              child: new Image.network(urlCover))),
                      Expanded(
                        child: Center(
                            child: Text(
                                'Année : ' +
                                    year +
                                    '\n' +
                                    'Artists : ' +
                                    songInformations.artists +
                                    '\n'
                                    'Durée : ' +
                                    songInformations.length +
                                    '\n' +
                                    'Label : ' +
                                    songInformations.label +
                                    '\n'
                                    'Reference : ' +
                                    songInformations.reference,
                                style: _fontLyrics)),
                      ),
                    ],
                  ))
            ])),
          ),
        ];
      },
      body: Center(
          child: Container(
        child: Stack(children: [
          new BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: new Container(
              decoration: new BoxDecoration(
                  color: Colors.grey.shade200.withOpacity(0.7)),
            ),
          ),
          PageView(
            children: <Widget>[
              SingleChildScrollView(
                  child: Text(songInformations.lyrics, style: _fontLyrics)),
              _buildViewComments(context, songInformations.comments),
            ],
          )
        ]),
        decoration: new BoxDecoration(
            image: new DecorationImage(
          fit: BoxFit.fill,
          alignment: FractionalOffset.topCenter,
          image: new NetworkImage(urlCover),
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
    //print(">> " + session.id.toString() + " and " + songInformations.canFavourite.toString());
    if (session.id != null && songInformations.canFavourite) {
      actions
          .add(SongFavoriteIconWidget(song.id, songInformations.isFavourite));
    }

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
                new MaterialPageRoute(
                    builder: (context) => new AccountPageWidget(
                        account: comment.author,
                        accountInformations: fetchAccount(comment.author.id))));
          },
          leading: new CircleAvatar(
            backgroundColor: Colors.black12,
            child: new Image(
                image: new NetworkImage(
                    'http://www.bide-et-musique.com/images/avatars/' +
                        comment.author.id +
                        '.jpg')),
          ),
          title: Text(
            stripTags(comment.body),
          ),
          subtitle: Text('Par ' + comment.author.name + ' ' + comment.time)));
    }

    return ListView(children: rows);
  }
}

////////////////////////////////
class SongFavoriteIconWidget extends StatefulWidget {
  final String _songId;
  bool _isFavourite;

  SongFavoriteIconWidget(this._songId, this._isFavourite, {Key key})
      : super(key: key);

  @override
  _SongFavoriteIconWidgetState createState() =>
      _SongFavoriteIconWidgetState(this._songId, this._isFavourite);
}

class _SongFavoriteIconWidgetState extends State<SongFavoriteIconWidget> {
  final String _songId;
  bool _isFavourite;

  _SongFavoriteIconWidgetState(this._songId, this._isFavourite);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var session = Session();
    print("SESSION ID BUILD IS " + session.id.toString());

    if (_isFavourite) {
      return IconButton(
          icon: new Icon(Icons.star),
          onPressed: () async {
            //var url = '$host/song/$_songId.html';

            final response = await session.post(
                '$host/account/${session.id}.html',
                {'K': _songId, 'Step': '', 'DS.x': '1', 'DS.y': '1'});

            if (response.statusCode == 200) {
              setState(() {
                _isFavourite = false;
              });
            }
          });
    } else {
      return IconButton(
        icon: new Icon(Icons.star_border),
        onPressed: () async {
          var url = '$host/song/$_songId.html';

          session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
          session.headers['Host'] = 'www.bide-et-musique.com';
          session.headers['Origin'] = host;
          session.headers['Referer'] = url;

          final response = await session.post(url, {'M': 'AS'});

          session.headers.remove('Referer');
          session.headers.remove('Content-Type');
          if (response.statusCode == 200) {
            setState(() {
              _isFavourite = true;
            });
          } else {
            print("Add song to favorites returned status code " +
                response.statusCode.toString());
          }
        },
      );
    }
  }
}

////////////////////////////////
enum PlayerState { stopped, playing, paused }

class SongPlayerWidget extends StatefulWidget {
  final String _songId;
  SongPlayerWidget(this._songId, {Key key}) : super(key: key);

  @override
  _SongPlayerWidgetState createState() => _SongPlayerWidgetState(this._songId);
}

class _SongPlayerWidgetState extends State<SongPlayerWidget> {
  final String _songId;

  PlayerState playerState = PlayerState.stopped;
  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  _SongPlayerWidgetState(this._songId);

  @override
  Widget build(BuildContext context) {
    var playStopButton;

    if (isPlaying) {
      playStopButton = IconButton(
        icon: new Icon(Icons.stop),
        onPressed: () {
          stop();
        },
      );
    } else {
      playStopButton = IconButton(
        icon: new Icon(Icons.play_arrow),
        onPressed: () {
          playerWidget.stop();
          play();
        },
      );
    }

    return playStopButton;
  }

  @override
  void dispose() {
    //if the radio stream is playing do not stop
    //if the song player is playing stop it
    if (isPlaying) {
      FlutterRadio.stop();
    }

    super.dispose();
  }

  play() {
    FlutterRadio.play(
        url: 'http://www.bide-et-musique.com/stream_' + this._songId + '.php');
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  stop() {
    FlutterRadio.stop();
    setState(() {
      playerState = PlayerState.stopped;
    });
  }
}

//////////////////
Future<List<Song>> fetchNewSongs() async {
  var songs = <Song>[];
  final url = '$host/new_song.rss';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    var document = xml.parse(body);
    for (var item in document.findAllElements('item')) {
      var link = item.children[2].text;
      var song = Song();
      song.id = extractSongId(link);
      song.title = item.firstChild.text;
      song.artist = '';
      songs.add(song);
    }
    return songs;
  } else {
    throw Exception('Failed to load pochette');
  }
}

class NewSongsWidget extends StatelessWidget {
  final Future<List<Song>> songs;

  NewSongsWidget({Key key, this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Les nouvelles entrées'),
      ),
      body: Center(
        child: FutureBuilder<List<Song>>(
          future: songs,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data);
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

  Widget _buildView(BuildContext context, List<Song> songs) {
    var rows = <ListTile>[];
    for (Song song in songs) {
      rows.add(ListTile(
        leading: new CircleAvatar(
          backgroundColor: Colors.black12,
          child: new Image(
              image: new NetworkImage(
                  'http://bide-et-musique.com/images/thumb25/' +
                      song.id +
                      '.jpg')),
        ),
        title: Text(
          song.title,
        ),
        subtitle: Text(song.artist),
        onTap: () {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new SongPageWidget(
                      song: song,
                      songInformations: fetchSongInformations(song.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
}
