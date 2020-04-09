import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';

import 'player.dart';
import 'playerWidget.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

class SongAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Future<Song> _song;

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
          var songActionButton = FlatButton.icon(
              icon: Icon(Icons.menu),
              label: Text(''),
              onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        contentPadding: EdgeInsets.all(20.0),
                        children: [SongActionMenu(song)],
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0))),
                      );
                    },
                  ));

          return AppBar(
            title: Text(snapshot.data.name),
            actions: <Widget>[songActionButton],
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

class SongActionMenu extends StatelessWidget {
  final Song _song;

  SongActionMenu(this._song);

  @override
  Widget build(BuildContext context) {
    //add buttons to the actions menu
    //some action buttons are added when user is logged in
    //some action buttons are not available on some songs
    final _actions = <Widget>[];
    //if the song can be listen, add the song player
    if (_song.canListen) {
      _actions.add(SongPlayerWidget(_song));
    }

    //if the user if logged in
    if (Session.accountLink.id != null) {
      if (_song.canFavourite) {
        _actions.add(SongFavoriteIconWidget(_song));
      }

      _actions.add(SongVoteIconWidget(_song));
    }

    _actions.add(SongOpenInBrowserIconWidget(_song));

    // Share buttons (message and song id)
    var actionsShare = <Widget>[];

    var shareSongStream = RaisedButton.icon(
        icon: Icon(Icons.music_note),
        label: Text('Flux musical'),
        onPressed: () => Share.share(_song.streamLink));

    actionsShare.add(SongShareIconWidget(_song));
    actionsShare.add(shareSongStream);

    //build widget for overflow button
    var popupMenuShare = <PopupMenuEntry<Widget>>[];
    for (Widget actionWidget in actionsShare) {
      popupMenuShare.add(PopupMenuItem<Widget>(child: actionWidget));
    }

    Widget popupMenuButtonShare = PopupMenuButton<Widget>(
        icon: Icon(
          Icons.share,
        ),
        itemBuilder: (BuildContext context) => popupMenuShare);

    ///////////////////////////////////
    //// Copy
    var popupMenuCopy = <PopupMenuEntry<Widget>>[];
    popupMenuCopy
        .add(PopupMenuItem<Widget>(child: SongCopyLinkIconWidget(_song)));
    popupMenuCopy
        .add(PopupMenuItem<Widget>(child: SongCopyLinkHtmlIconWidget(_song)));

    Widget popupMenuButtonCopy = PopupMenuButton<Widget>(
        icon: Icon(
          Icons.content_copy,
        ),
        itemBuilder: (BuildContext context) => popupMenuCopy);

    _actions.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[popupMenuButtonCopy, popupMenuButtonShare],
    ));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _actions);
  }
}

////////////////////////////////
//// Add to favorite
class SongFavoriteIconWidget extends StatefulWidget {
  final Song _song;

  SongFavoriteIconWidget(this._song, {Key key}) : super(key: key);

  @override
  _SongFavoriteIconWidgetState createState() => _SongFavoriteIconWidgetState();
}

class _SongFavoriteIconWidgetState extends State<SongFavoriteIconWidget> {
  _SongFavoriteIconWidgetState();

  @override
  Widget build(BuildContext context) {
    if (widget._song.isFavourite) {
      return RaisedButton.icon(
          icon: Icon(Icons.star),
          label: Text('Retirer des favoris'),
          onPressed: () async {
            final response = await Session.post(
                '$baseUri/account/${Session.accountLink.id}.html',
                body: {
                  'K': widget._song.id.toString(),
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
      return RaisedButton.icon(
        icon: Icon(Icons.star_border),
        label: Text('Ajouter aux favoris'),
        onPressed: () async {
          String url = widget._song.link;

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
  _SongVoteIconWidgetState createState() => _SongVoteIconWidgetState();
}

class _SongVoteIconWidgetState extends State<SongVoteIconWidget> {
  _SongVoteIconWidgetState();

  @override
  Widget build(BuildContext context) {
    var callbackVote = () async {
      String url = widget._song.link;

      Session.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      Session.headers['Host'] = host;
      Session.headers['Origin'] = baseUri;
      Session.headers['Referer'] = url;

      final response = await Session.post(url, body: {'Note': '1', 'M': 'CN'});

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
    };

    return RaisedButton.icon(
        icon: Icon(Icons.exposure_plus_1),
        label: Text('Voter'),
        onPressed: (widget._song.hasVote ? null : callbackVote));
  }
}

////////////////////////////////
//// Share

class SongShareIconWidget extends StatelessWidget {
  final Song _song;

  SongShareIconWidget(this._song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return RaisedButton.icon(
        icon: Icon(Icons.message),
        label: Text('Message'),
        onPressed: () => Share.share(
            '''En ce moment j'écoute '${_song.name}' sur Bide et Musique !
          
Tu peux consulter la fiche de cette chanson à l'adresse : 
${_song.link}
          
--------
Message envoyé avec l'application 'Bide et Musique flutter pour Android'
https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique
''',
            subject: "'${_song.name}' sur Bide et Musique"));
  }
}

////////////////////////////////
//// Copy

class SongCopyLinkIconWidget extends StatelessWidget {
  final Song _song;

  SongCopyLinkIconWidget(this._song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return RaisedButton.icon(
        icon: Icon(Icons.link),
        label: Text('Copier l\'url'),
        onPressed: () {
          Clipboard.setData(new ClipboardData(text: _song.link));
        });
  }
}

class SongCopyLinkHtmlIconWidget extends StatelessWidget {
  final Song _song;

  SongCopyLinkHtmlIconWidget(this._song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return RaisedButton.icon(
        icon: Icon(Icons.code),
        label: Text('Copier le code HTML du lien'),
        onPressed: () => Clipboard.setData(
            ClipboardData(text: '<a href="${_song.link}">${_song.name}</a>')));
  }
}

////////////////////////////////
//// Open in browser

class SongOpenInBrowserIconWidget extends StatelessWidget {
  final Song _song;

  SongOpenInBrowserIconWidget(this._song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return RaisedButton.icon(
        icon: Icon(Icons.open_in_browser),
        label: Text('Ouvrir l\'url'),
        onPressed: () => launchURL(_song.link));
  }
}

////////////////////////////////
//// Player

class SongPlayerWidget extends StatefulWidget {
  final Song _song;

  SongPlayerWidget(this._song, {Key key}) : super(key: key);

  @override
  _SongPlayerWidgetState createState() => _SongPlayerWidgetState();
}

class _SongPlayerWidgetState extends State<SongPlayerWidget> {
  _SongPlayerWidgetState();

  @override
  Widget build(BuildContext context) {
    final playbackState = InheritedPlaybackState.of(context);
    double duration = AudioService.currentMediaItem?.duration?.toDouble();

    Widget songPlaybackControls;
    bool isPlaying = (PlayerState.playerMode == PlayerMode.song &&
        (AudioService.playbackState != null &&
            AudioService.playbackState.basicState !=
                BasicPlaybackState.stopped &&
            AudioService.playbackState.basicState != BasicPlaybackState.none) &&
        widget._song.streamLink == AudioService.currentMediaItem?.id);

    if (isPlaying == true) {
      Widget stopSongButton = RaisedButton.icon(
          icon: Icon(Icons.stop),
          label: Text('Stop'),
          onPressed: () => AudioService.stop());

      Widget pauseSongButton = RaisedButton.icon(
          icon: Icon(Icons.pause),
          label: Text('Pause'),
          onPressed: () => AudioService.pause());

      Widget resumeSongButton = RaisedButton.icon(
          icon: Icon(Icons.play_arrow),
          label: Text('Reprendre'),
          onPressed: () => AudioService.play());

      songPlaybackControls = Column(children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            if (AudioService.playbackState.basicState ==
                BasicPlaybackState.paused)
              resumeSongButton
            else
              pauseSongButton
            , stopSongButton
          ],
        ),
        if (playbackState != null && duration != null)
          SongPositionSlider(playbackState, duration),
        Divider()
      ]);
    } else {
      songPlaybackControls = RaisedButton.icon(
          icon: Icon(Icons.play_arrow),
          label: Text('Écouter'),
          onPressed: () => play());
    }

    return songPlaybackControls;
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

    PlayerState.playerMode = PlayerMode.song;
    await AudioService.customAction('mode', 'song');
    await AudioService.customAction('song', {
      'id': widget._song.id,
      'name': widget._song.name,
      'artist': widget._song.artist,
      'duration': widget._song.duration.inSeconds
    });
    await AudioService.play();
  }
}
