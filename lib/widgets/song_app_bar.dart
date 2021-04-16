// @dart=2.9

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share/share.dart';

import '../models/song.dart';
import '../player.dart';
import '../services/favorite.dart';
import '../services/song.dart';
import '../session.dart';
import '../utils.dart';
import 'song_position_slider.dart';

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
          Widget songActionButton = IconButton(
              icon: Icon(Icons.menu),
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

    //if the user is logged in
    if (Session.accountLink.id != null) {
      if (_song.canFavourite) {
        _actions.add(SongFavoriteIconWidget(_song));
      }

      _actions.add(SongVoteIconWidget(_song));
    }

    _actions.add(SongOpenInBrowserIconWidget(_song));

    // Share buttons (message and song id)
    var actionsShare = <Widget>[];

    var shareSongStream = ElevatedButton.icon(
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
      return ElevatedButton.icon(
          icon: Icon(Icons.star),
          label: Text('Retirer des favoris'),
          onPressed: () async {
            int statusCode = await removeSongFromFavorites(widget._song.id);
            if (statusCode == 200) {
              setState(() {
                widget._song.isFavourite = false;
              });
            }
          });
    } else {
      return ElevatedButton.icon(
        icon: Icon(Icons.star_border),
        label: Text('Ajouter aux favoris'),
        onPressed: () async {
          int statusCode = await addSongToFavorites(widget._song.link);
          if (statusCode == 200) {
            setState(() => widget._song.isFavourite = true);
          } else {
            print('Add song to favorites returned status code $statusCode');
          }
        },
      );
    }
  }
}

// Vote
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
      int statusCode = await voteForSong(widget._song.link);

      if (statusCode == 200) {
        setState(() {
          widget._song.hasVote = true;
        });
      } else {
        print('Vote for song returned status code $statusCode');
      }
    };

    return ElevatedButton.icon(
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
    return ElevatedButton.icon(
        icon: Icon(Icons.message),
        label: Text('Message'),
        onPressed: () => Share.share(
            '''En ce moment j'écoute '${_song.name}' sur Bide et Musique !

Tu peux consulter la fiche de cette chanson à l'adresse :
${_song.link}

--------
Message envoyé avec l'application 'Bide et Musique'. Disponible pour  
* Android https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique 
* IOS https://apps.apple.com/fr/app/bide-et-musique/id1524513644''',
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
    return ElevatedButton.icon(
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
    return ElevatedButton.icon(
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
    return ElevatedButton.icon(
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
    return StreamBuilder(
        stream: Rx.combineLatest2<MediaItem, PlaybackState, ScreenState>(
            AudioService.currentMediaItemStream,
            AudioService.playbackStateStream,
            (mediaItem, playbackState) =>
                ScreenState(mediaItem, playbackState)),
        builder: (context, snapshot) {
          final screenState = snapshot.data;
          final mediaItem = screenState?.mediaItem;
          final state = screenState?.playbackState;
          final processingState =
              state?.processingState ?? AudioProcessingState.none;
          final playing = state?.playing ?? false;
          final radioMode = mediaItem?.album == radioIcon;

          // Display the play song button when no song is being played or player is in player mode
          if (processingState == AudioProcessingState.none ||
              radioMode == true ||
              mediaItem == null ||
              widget._song?.streamLink != mediaItem.id) {
            return ElevatedButton.icon(
                icon: Icon(Icons.play_arrow),
                label: Text('Écouter'),
                onPressed: () => play());
          } else {
            Widget playPauseControl;
            if (playing == null ||
                processingState == AudioProcessingState.buffering ||
                processingState == AudioProcessingState.connecting) {
              playPauseControl = Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      height: 25.0,
                      width: 25.0,
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black))));
            } else if (playing == true) {
              playPauseControl = pauseSongButton;
            } else {
              playPauseControl = resumeSongButton;
            }

            return Column(children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[playPauseControl, stopSongButton],
              ),
              SongPositionSlider(mediaItem, state),
              Divider()
            ]);
          }
        });
  }

  Widget stopSongButton = ElevatedButton.icon(
      icon: Icon(Icons.stop),
      label: Text('Stop'),
      onPressed: () => AudioService.stop());

  Widget pauseSongButton = ElevatedButton.icon(
      icon: Icon(Icons.pause),
      label: Text('Pause'),
      onPressed: () => AudioService.pause());

  Widget resumeSongButton = ElevatedButton.icon(
      icon: Icon(Icons.play_arrow),
      label: Text('Reprendre'),
      onPressed: () => AudioService.play());

  play() async {
    if (AudioService.running) await AudioService.stop();

    await AudioService.start(
      backgroundTaskEntrypoint: audioPlayerTaskEntrypoint,
      androidNotificationChannelName: 'Bide&Musique',
      androidNotificationIcon: 'mipmap/ic_launcher',
    );

    await AudioService.customAction('set_radio_mode', false);
    await AudioService.customAction(
        'set_session_id', Session.headers['cookie']);
    await AudioService.customAction('set_song', widget._song.toJson());
    await AudioService.play();
  }
}
