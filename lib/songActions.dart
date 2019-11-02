import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

import 'player.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

class SongAppBar extends StatefulWidget implements PreferredSizeWidget {
  Future<SongLink> _songLink;

  SongAppBar(this._songLink, {Key key}) : preferredSize = Size.fromHeight(kToolbarHeight), super(key: key);

  @override
  final Size preferredSize;

  @override
  _SongAppBarState createState() => _SongAppBarState();
}

class _SongAppBarState extends State<SongAppBar>{

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SongLink>(
      future: widget._songLink,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AppBar( title: Text(snapshot.data.title) );
        } else if (snapshot.hasError) {
          return AppBar( title: Text("Chargement") );
        }

        // By default, show a loading spinner
        return CircularProgressIndicator();
      },
    );
  }
}

/////////////////////////////////////////////////////////////////////////////
// Actions for the song page title bar

////////////////////////////////
//// Add to favorite
class SongFavoriteIconWidget extends StatefulWidget {
  final String _songId;
  final bool _isFavourite;

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
  Widget build(BuildContext context) {
    if (_isFavourite) {
      return IconButton(
          icon: Icon(Icons.star),
          onPressed: () async {
            final response = await Session.post(
                '$baseUri/account/${Session.accountLink.id}.html',
                body: {'K': _songId, 'Step': '', 'DS.x': '1', 'DS.y': '1'});

            if (response.statusCode == 200) {
              setState(() {
                _isFavourite = false;
              });
            }
          });
    } else {
      return IconButton(
        icon: Icon(Icons.star_border),
        onPressed: () async {
          var url = '$baseUri/song/$_songId.html';

          Session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
          Session.headers['Host'] = host;
          Session.headers['Origin'] = baseUri;
          Session.headers['Referer'] = url;

          final response = await Session.post(url, body: {'M': 'AS'});

          Session.headers.remove('Referer');
          Session.headers.remove('Content-Type');
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
//// Vote
class SongVoteIconWidget extends StatefulWidget {
  final String _songId;
  final bool _hasVote;

  SongVoteIconWidget(this._songId, this._hasVote, {Key key}) : super(key: key);

  @override
  _SongVoteIconWidgetState createState() =>
      _SongVoteIconWidgetState(this._songId, this._hasVote);
}

class _SongVoteIconWidgetState extends State<SongVoteIconWidget> {
  final String _songId;
  bool _hasVote;

  _SongVoteIconWidgetState(this._songId, this._hasVote);

  @override
  Widget build(BuildContext context) {
    if (_hasVote) {
      return IconButton(icon: Icon(Icons.exposure_plus_1), onPressed: null);
    } else {
      return IconButton(
        icon: Icon(Icons.exposure_plus_1),
        onPressed: () async {
          var url = '$baseUri/song/$_songId.html';

          Session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
          Session.headers['Host'] = host;
          Session.headers['Origin'] = baseUri;
          Session.headers['Referer'] = url;

          final response =
              await Session.post(url, body: {'Note': '1', 'M': 'CN'});

          Session.headers.remove('Referer');
          Session.headers.remove('Content-Type');
          if (response.statusCode == 200) {
            setState(() {
              _hasVote = true;
            });
          } else {
            print("Vote for song returned status code " +
                response.statusCode.toString());
          }
        },
      );
    }
  }
}

////////////////////////////////
// Share

class SongShareIconWidget extends StatelessWidget {
  final Song _song;

  SongShareIconWidget(this._song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return IconButton(
        icon: Icon(Icons.message),
        onPressed: () {
          Share.share(
              '''En ce moment j'écoute '${_song.title}' sur bide et musique !
          
Tu peux consulter la fiche de cette chanson à l'adresse : 
$baseUri/song/${_song.id}.html
          
--------
Message envoyé avec l'application 'bide et musique flutter pour android'
https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique
''');
        });
  }
}

////////////////////////////////
// Player

class SongPlayerWidget extends StatefulWidget {
  final Song _song;

  SongPlayerWidget(this._song, {Key key}) : super(key: key);

  @override
  _SongPlayerWidgetState createState() => _SongPlayerWidgetState(this._song);
}

class _SongPlayerWidgetState extends State<SongPlayerWidget> {
  final Song _song;

  bool _isPlaying;

  _SongPlayerWidgetState(this._song);

  @override
  void initState() {
    super.initState();

    bool isPlaying;
    if (AudioService.playbackState == null ||
        AudioService.playbackState.basicState == BasicPlaybackState.stopped ||
        AudioService.playbackState.basicState == BasicPlaybackState.none) {
      isPlaying = false;
    } else
      isPlaying = _song.id == AudioService.currentMediaItem.id;

    this.setState(() {
      this._isPlaying = isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    var playStopButton;

    if (_isPlaying) {
      playStopButton = IconButton(
        icon: Icon(Icons.stop),
        onPressed: () {
          stop();
        },
      );
    } else {
      playStopButton = IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () {
          play();
        },
      );
    }

    return playStopButton;
  }

  play() async {
    if (AudioService.playbackState == null ||
        AudioService.playbackState.basicState == BasicPlaybackState.stopped ||
        AudioService.playbackState.basicState == BasicPlaybackState.none) {
      await AudioService.start(
        backgroundTaskEntrypoint: audioPlayerTaskEntrypoint,
        resumeOnClick: true,
        androidNotificationChannelName: 'Bide&Musique',
        notificationColor: 0xFFFFFFFF,
        androidNotificationIcon: 'mipmap/ic_launcher',
      );
    }

    await AudioService.customAction('song', {
      'id': _song.id,
      'title': _song.title,
      'artist': _song.artist,
      'duration': _song.duration.inSeconds
    });

    await AudioService.customAction('setNotification');
    await AudioService.play();

    setState(() {
      _isPlaying = true;
    });
  }

  stop() {
    AudioService.stop();
    setState(() {
      _isPlaying = false;
    });
  }
}
