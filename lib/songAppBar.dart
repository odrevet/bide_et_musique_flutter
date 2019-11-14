import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:clipboard_manager/clipboard_manager.dart';

import 'player.dart';
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
          var songActionButton = SongActionButton(song);

          return AppBar(
            title: Text(snapshot.data.title),
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

class SongActionButton extends StatelessWidget {
  final Song _song;
  final _actions = <Widget>[];

  SongActionButton(this._song);

  @override
  Widget build(BuildContext context) {
    //add buttons to the actions menu
    //some action buttons are added when user is logged in
    //some action buttons are not available on some songs

    //if the song can be listen, add the song player
    if (_song.canListen) {
      _actions.add(SongPlayerWidget(_song));
    }

    //if the user if logged in
    if (Session.accountLink.id != null) {
      if (_song.canFavourite) {
        _actions.add(PopupMenuItem(child: SongFavoriteIconWidget(_song)));
      }

      _actions.add(SongVoteIconWidget(_song));
    }

    // Share buttons (message and song id)

    //list of actions for sharing
    var actionsShare = <Widget>[];

    var shareSongStream = IconButton(
        icon: Icon(Icons.music_note),
        onPressed: () {
          Share.share('$baseUri/stream_${_song.id}.php');
        });

    actionsShare.add(SongShareIconWidget(_song));
    actionsShare.add(shareSongStream);

    //build widget for overflow button
    var popupMenuShare = <PopupMenuEntry<Widget>>[];
    for (Widget actionWidget in actionsShare) {
      popupMenuShare.add(PopupMenuItem<Widget>(child: actionWidget));
    }

    _actions.add(PopupMenuButton<Widget>(
        icon: Icon(
          Icons.share,
        ),
        itemBuilder: (BuildContext context) => popupMenuShare));

    ///////////////////////////////////
    //// Copy
    var popupMenuCopy = <PopupMenuEntry<Widget>>[];
    popupMenuCopy
        .add(PopupMenuItem<Widget>(child: SongCopyLinkIconWidget(_song)));
    popupMenuCopy
        .add(PopupMenuItem<Widget>(child: SongCopyLinkHtmlIconWidget(_song)));

    _actions.add(PopupMenuButton<Widget>(
        icon: Icon(
          Icons.content_copy,
        ),
        itemBuilder: (BuildContext context) => popupMenuCopy));

    _actions.add(SongOpenInBrowserIconWidget(_song));

    ///////////////////////////////////
    //wrap all actions in a PopupMenuItem to be added in the action menu
    var popupMenuEntries = <PopupMenuEntry<Widget>>[];
    for (Widget actionWidget in _actions) {
      popupMenuEntries.add(PopupMenuItem<Widget>(child: actionWidget));
    }

    return PopupMenuButton(
      icon: Icon(Icons.more_vert),
      itemBuilder: (context) => popupMenuEntries,
    );
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
          String url = widget._song.getLink();

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
      String url = widget._song.getLink();

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

    return IconButton(
        icon: Icon(Icons.exposure_plus_1),
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
    return IconButton(
        icon: Icon(Icons.message),
        onPressed: () {
          Share.share(
              '''En ce moment j'écoute '${_song.title}' sur bide et musique !
          
Tu peux consulter la fiche de cette chanson à l'adresse : 
${_song.getLink()}
          
--------
Message envoyé avec l'application 'bide et musique flutter pour android'
https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique
''');
        });
  }
}

////////////////////////////////
//// Copy

class SongCopyLinkIconWidget extends StatelessWidget {
  final Song _song;

  SongCopyLinkIconWidget(this._song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return IconButton(
        icon: Icon(Icons.link),
        onPressed: () {
          ClipboardManager.copyToClipBoard(_song.getLink());
        });
  }
}

class SongCopyLinkHtmlIconWidget extends StatelessWidget {
  final Song _song;

  SongCopyLinkHtmlIconWidget(this._song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return IconButton(
        icon: Icon(Icons.code),
        onPressed: () {
          ClipboardManager.copyToClipBoard(
              '<a href="${_song.getLink()}">${_song.title}</a>');
        });
  }
}

////////////////////////////////
//// Open in browser

class SongOpenInBrowserIconWidget extends StatelessWidget {
  final Song _song;

  SongOpenInBrowserIconWidget(this._song, {Key key}) : super(key: key);

  Widget build(BuildContext context) {
    //share song button
    return IconButton(
        icon: Icon(Icons.open_in_browser),
        onPressed: () {
          launchURL(_song.getLink());
        });
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
  bool _isPlaying;

  _SongPlayerWidgetState();

  @override
  void initState() {
    super.initState();

    bool isPlaying;
    if (AudioService.playbackState == null ||
        AudioService.playbackState.basicState == BasicPlaybackState.stopped ||
        AudioService.playbackState.basicState == BasicPlaybackState.none) {
      isPlaying = false;
    } else
      isPlaying = widget._song.id == AudioService.currentMediaItem.id;

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
      'id': widget._song.id,
      'title': widget._song.title,
      'artist': widget._song.artist,
      'duration': widget._song.duration.inSeconds
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
