import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bide_et_musique/utils.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import 'nowPlaying.dart';
import 'player.dart';
import 'song.dart';
import 'songPositionSlider.dart';

class PlayerWidget extends StatefulWidget {
  final Orientation orientation;
  final Future<SongNowPlaying> _songNowPlaying;

  PlayerWidget(this.orientation, this._songNowPlaying);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Rx.combineLatest2<MediaItem, PlaybackState, PlayerState>(
            AudioService.currentMediaItemStream,
            AudioService.playbackStateStream,
            (mediaItem, playbackState) =>
                PlayerState(mediaItem, playbackState)),
        builder: (context, snapshot) {
          final screenState = snapshot.data;
          final mediaItem = screenState?.mediaItem;
          final state = screenState?.playbackState;
          final basicState = state?.basicState ?? BasicPlaybackState.none;

          List<Widget> controls;

          if (!snapshot.hasData ||
              basicState == null ||
              basicState == BasicPlaybackState.none)
            controls = [RadioStreamButton(widget._songNowPlaying)];
          else if (basicState == BasicPlaybackState.buffering ||
              basicState == BasicPlaybackState.connecting) {
            controls = [
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
              stopButton()
            ];
          } else
            controls = <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    PlayerSongType.playerMode == PlayerMode.song
                        ? InkWell(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              int id = getIdFromUrl(mediaItem.id);
                              return SongPageWidget(
                                  songLink: SongLink(id: id),
                                  song: fetchSong(id));
                            })),
                            child: Icon(
                              Icons.music_note,
                              size: 18.0,
                            ),
                          )
                        : InkWell(
                            onTap: () => _streamInfoDialog(context),
                            child: Icon(
                              Icons.radio,
                              size: 18.0,
                            ),
                          ),
                    basicState == BasicPlaybackState.paused
                        ? playButton()
                        : pauseButton(),
                    stopButton()
                  ]),
              if (PlayerSongType.playerMode == PlayerMode.song)
                Container(
                    height: 20, child: SongPositionSlider(mediaItem, state))
            ];

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.orientation == Orientation.portrait
                  ? Row(
                      children: controls,
                    )
                  : Column(
                      children: controls,
                    )
            ],
          );
        });
  }

  _streamInfoDialog(BuildContext context) {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0)),
              actions: <Widget>[],
              title: Text('Informations du flux musical'),
              content: StreamBuilder<dynamic>(
                  stream: AudioService.customEventStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data is IcyMetadata) {
                      var icyMetadata = snapshot.data;
                      String info =
                          '''${icyMetadata.headers.name} ${icyMetadata.headers.genre}
${icyMetadata.info.title}
bitrate ${icyMetadata.headers.bitrate}
''';
                      return Text(info);
                    } else if (snapshot.hasError) {
                      return Text("${snapshot.error}");
                    }

                    // By default, show a loading spinner
                    return Text('Chargement');
                  }));
        });
  }
}

class RadioStreamButton extends StatefulWidget {
  final Future<SongNowPlaying> _songNowPlaying;

  RadioStreamButton(this._songNowPlaying);

  @override
  _RadioStreamButtonState createState() => _RadioStreamButtonState();
}

class _RadioStreamButtonState extends State<RadioStreamButton> {
  Widget build(BuildContext context) {
    Widget label = Text("Écouter la radio",
        style: TextStyle(
          fontSize: 20.0,
        ));

    return FutureBuilder<SongNowPlaying>(
      future: widget._songNowPlaying,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          label = RichText(
            text: TextSpan(
              text: 'Écouter la radio ',
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                    text: '\n${snapshot.data.nbListeners} auditeurs',
                    style:
                        TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
              ],
            ),
          );
        }
        return RaisedButton.icon(
          icon: Icon(Icons.radio, size: 40),
          label: label,
          onPressed: () async {
            bool success = await AudioService.start(
              backgroundTaskEntrypoint: audioPlayerTaskEntrypoint,
              resumeOnClick: true,
              androidNotificationChannelName: 'Bide&Musique',
              notificationColor: 0xFFFFFFFF,
              androidNotificationIcon: 'mipmap/ic_launcher',
            );
            if (success) {
              SongAiringNotifier().songNowPlaying.then((song) async {
                PlayerSongType.playerMode = PlayerMode.radio;
                await AudioService.customAction('mode', 'radio');
                await AudioService.customAction('song', song.toJson());
                await AudioService.play();
              });
            }
          },
        );
      },
    );
  }
}

IconButton playButton([double iconSize = 40]) => IconButton(
      icon: Icon(Icons.play_arrow),
      iconSize: iconSize,
      onPressed: AudioService.play,
    );

IconButton pauseButton([double iconSize = 40]) => IconButton(
      icon: Icon(Icons.pause),
      iconSize: iconSize,
      onPressed: AudioService.pause,
    );

IconButton stopButton([double iconSize = 40]) => IconButton(
      icon: Icon(Icons.stop),
      iconSize: iconSize,
      onPressed: AudioService.stop,
    );
