import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

import 'player.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

class SongAppBar extends StatefulWidget implements PreferredSizeWidget {
  Future<Song> _song;
  var _actions = <Widget>[];

  SongAppBar(this._song, {Key key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize;

  @override
  _SongAppBarState createState() => _SongAppBarState();
}

class _SongAppBarState extends State<SongAppBar> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Song>(
      future: widget._song,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Song song = snapshot.data;

          //add buttons to the actions menu
          //some action buttons are added when user is logged in
          //some action buttons are not available on some songs

          //if the user if logged in
          if (Session.accountLink.id != null) {
            if (song.canFavourite) {
              widget._actions.add(PopupMenuItem(child: SongFavoriteIconWidget(song)));
            }

            widget._actions.add(SongVoteIconWidget(song));
          }

          //if the song can be listen, add the song player
          if (song.canListen) {
            widget._actions.add(SongPlayerWidget(song));
          }

          //wrap all actions in a PopupMenuItem to be added in the action menu
          var popupMenuAction = <PopupMenuEntry<Widget>>[];
          for (Widget actionWidget in widget._actions) {
            popupMenuAction.add(PopupMenuItem<Widget>(child: actionWidget));
          }

          /*
          //list of actions for sharing
          var actionsShare = <Widget>[];



          var listenButton = IconButton(
              icon: Icon(Icons.music_note),
              onPressed: () {
                Share.share('$baseUri/stream_${song.id}.php');
              });

          //actionsShare.add(SongShareIconWidget(songLink));
          actionsShare.add(listenButton);

          //build widget for overflow button
          var popupMenuAction = <PopupMenuEntry<Widget>>[];
          for (Widget actionWidget in actionsShare) {
            popupMenuAction.add(PopupMenuItem<Widget>(child: actionWidget));
          }

          //overflow menu
          widget._actions.add(PopupMenuButton<Widget>(
              icon: Icon(
                Icons.share,
              ),
              itemBuilder: (BuildContext context) => popupMenuAction));

          var actionContainer = Container(
            padding: EdgeInsets.only(left: 54.0),
            alignment: Alignment.topCenter,
            child: Row(children: widget._actions),
          );
*/
          var buttonActions = PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => popupMenuAction,
          );

          return AppBar(
            title: Text(snapshot.data.title),
            actions: <Widget>[buttonActions],
          );
        } else if (snapshot.hasError) {
          return AppBar(title: Text("Chargement"));
        }

        // By default, show a loading spinner
        return AppBar(title: CircularProgressIndicator());
      },
    );
  }
}

/////////////////////////////////////////////////////////////////////////////
// Actions Buttons

////////////////////////////////
//// Add to favorite
class SongFavoriteIconWidget extends StatefulWidget {
  Song _song;

  SongFavoriteIconWidget(this._song, {Key key}) : super(key: key);

  @override
  _SongFavoriteIconWidgetState createState() => _SongFavoriteIconWidgetState();
}

class _SongFavoriteIconWidgetState extends State<SongFavoriteIconWidget> {
  _SongFavoriteIconWidgetState();

  @override
  Widget build(BuildContext context) {
    if (widget._song.isFavourite) {
      return IconButton(
          icon: Icon(Icons.star),
          onPressed: () async {
            final response = await Session.post(
                '$baseUri/account/${Session.accountLink.id}.html',
                body: {
                  'K': widget._song.id,
                  'Step': '',
                  'DS.x': '1',
                  'DS.y': '1'
                });

            if (response.statusCode == 200) {
              setState(() {
                widget._song.isFavourite = false;
              });
            }
          });
    } else {
      return IconButton(
        icon: Icon(Icons.star_border),
        onPressed: () async {
          var url = '$baseUri/song/${widget._song.id}.html';

          Session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
          Session.headers['Host'] = host;
          Session.headers['Origin'] = baseUri;
          Session.headers['Referer'] = url;

          final response = await Session.post(url, body: {'M': 'AS'});

          Session.headers.remove('Referer');
          Session.headers.remove('Content-Type');
          if (response.statusCode == 200) {
            setState(() {
              widget._song.isFavourite = true;
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
  final Song _song;

  SongVoteIconWidget(this._song, {Key key}) : super(key: key);

  @override
  _SongVoteIconWidgetState createState() =>
      _SongVoteIconWidgetState();
}

class _SongVoteIconWidgetState extends State<SongVoteIconWidget> {

  _SongVoteIconWidgetState();

  @override
  Widget build(BuildContext context) {
    if (widget._song.hasVote) {
      return IconButton(icon: Icon(Icons.exposure_plus_1), onPressed: null);
    } else {
      return IconButton(
        icon: Icon(Icons.exposure_plus_1),
        onPressed: () async {
          var url = '$baseUri/song/${widget._song.id}.html';

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
              widget._song.hasVote = true;
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
//// Share

class SongShareIconWidget extends StatelessWidget {
  final SongLink _songLink;

  SongShareIconWidget(this._songLink, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return IconButton(
        icon: Icon(Icons.message),
        onPressed: () {
          Share.share(
              '''En ce moment j'écoute '${_songLink.title}' sur bide et musique !
          
Tu peux consulter la fiche de cette chanson à l'adresse : 
$baseUri/song/${_songLink.id}.html
          
--------
Message envoyé avec l'application 'bide et musique flutter pour android'
https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique
''');
        });
  }
}

////////////////////////////////
//// Player

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
