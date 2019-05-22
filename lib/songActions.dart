import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:share/share.dart';
import 'utils.dart';
import 'identification.dart';
import 'song.dart';
import 'player.dart';

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
    var session = Session();
    if (_isFavourite) {
      return IconButton(
          icon: Icon(Icons.star),
          onPressed: () async {
            final response = await session.post(
                '$baseUri/account/${session.id}.html',
                {'K': _songId, 'Step': '', 'DS.x': '1', 'DS.y': '1'});

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

          session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
          session.headers['Host'] = host;
          session.headers['Origin'] = baseUri;
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
    var session = Session();
    if (_hasVote) {
      return IconButton(icon: Icon(Icons.exposure_plus_1), onPressed: null);
    } else {
      return IconButton(
        icon: Icon(Icons.exposure_plus_1),
        onPressed: () async {
          var url = '$baseUri/song/$_songId.html';

          session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
          session.headers['Host'] = host;
          session.headers['Origin'] = baseUri;
          session.headers['Referer'] = url;

          final response = await session.post(url, {'Note': '1', 'M': 'CN'});

          session.headers.remove('Referer');
          session.headers.remove('Content-Type');
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
  final SongLink song;

  SongShareIconWidget(this.song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return IconButton(
        icon: Icon(Icons.message),
        onPressed: () {
          Share.share(
              '''En ce moment j'écoute '${song.title}' sur bide et musique !
          
Tu peux consulter la fiche de cette chanson à l'adresse : 
http://bide-et-musique.com/song/${song.id}.html
          
--------
Message envoyé avec l'application 'bide et musique flutter pour android'
https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique
''');
        });
  }
}

////////////////////////////////
// Player

RaisedButton startButtonSong(SongLink song) => RaisedButton(
      child: Text("PLAY SONG"),
      onPressed: () async {
        if (AudioService.playbackState == null ||
            AudioService.playbackState.basicState ==
                BasicPlaybackState.stopped ||
            AudioService.playbackState.basicState == BasicPlaybackState.none) {
          bool success = await AudioService.start(
            backgroundTask: backgroundAudioPlayerTask,
            resumeOnClick: true,
            androidNotificationChannelName: 'Bide&Musique',
            notificationColor: 0xFFFED152,
            androidNotificationIcon: 'mipmap/ic_launcher',
          );
          if (success) {
            AudioService.customAction('song',
                {'id': song.id, 'title': song.title, 'artist': song.artist});
            await AudioService.customAction('setNotification', '');
            await AudioService.play();
          }
        } else {
          await AudioService.customAction('song',
              {'id': song.id, 'title': song.title, 'artist': song.artist});
          await AudioService.customAction('setNotification', '');
          await AudioService.play();
        }
      },
    );
