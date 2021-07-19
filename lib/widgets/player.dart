import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

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
    return Text('WIP PLAYER WIDGET UPGRADE'); /*StreamBuilder(
        stream: Rx.combineLatest2<MediaItem?, PlaybackState, ScreenState>(
            AudioService.currentMediaItemStream,
            AudioService.playbackStateStream,
            (mediaItem, playbackState) =>
                ScreenState(mediaItem, playbackState)),
        builder: (context, snapshot) {
          final dynamic screenState = snapshot.data;
          final mediaItem = screenState?.mediaItem;
          final state = screenState?.playbackState;
          final processingState =
              state?.processingState ?? AudioProcessingState.none;
          final bool playing = state?.playing ?? false;
          final bool? radioMode =
              mediaItem != null ? mediaItem.album == radioIcon : null;

          List<Widget> controls;

          if (processingState == AudioProcessingState.none) {
            controls = [RadioStreamButton(widget._songNowPlaying)];
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
              playPauseControl = pauseButton();
            } else {
              playPauseControl = playButton();
            }

            controls = <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    radioMode == false
                        ? InkWell(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              int id = getIdFromUrl(mediaItem.id)!;
                              return SongPageWidget(
                                  songLink: SongLink(id: id, name: ''),
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
                    playPauseControl,
                    stopButton()
                  ]),
              /*if (radioMode != null && radioMode != true)
                Container(
                    height: 20, child: SongPositionSlider(mediaItem, state))*/
            ];
          }

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
        });*/
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

                    return Text('Veuillez attendre');
                  }));
        });
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
