import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import 'seek_bar.dart';
import '../models/song.dart';
import '../player.dart';
import 'radio_stream_button.dart';

class PlayerWidget extends StatefulWidget {
  final Orientation orientation;
  final Future<SongNowPlaying> _songNowPlaying;

  PlayerWidget(this.orientation, this._songNowPlaying);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  IconButton _button(IconData iconData, VoidCallback onPressed) => IconButton(
        icon: Icon(iconData),
        iconSize: 32.0,
        onPressed: onPressed,
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream:
          audioHandler.playbackState.map((state) => state.playing).distinct(),
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;

        if(!playing){
          return RadioStreamButton(widget._songNowPlaying);
        }

        return FutureBuilder<dynamic>(
          future: audioHandler.customAction('get_radio_mode'),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              bool radioMode = snapshot.data;
              if (radioMode) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    playing
                        ? _button(Icons.stop, audioHandler.stop)
                        : RadioStreamButton(widget._songNowPlaying),
                  ],
                );
              } else {
                return Row(
                  children: [
                    // Play/pause/stop buttons.
                    StreamBuilder<bool>(
                      stream: audioHandler.playbackState
                          .map((state) => state.playing)
                          .distinct(),
                      builder: (context, snapshot) {
                        final playing = snapshot.data ?? false;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (playing)
                              _button(Icons.pause, audioHandler.pause),
                            _button(Icons.stop, audioHandler.stop),
                          ],
                        );
                      },
                    ),
                    // A seek bar.
                    StreamBuilder<MediaState>(
                      stream: _mediaStateStream,
                      builder: (context, snapshot) {
                        final mediaState = snapshot.data;
                        return Expanded(
                          child: SeekBar(
                            duration: mediaState?.mediaItem?.duration ??
                                Duration.zero,
                            position: mediaState?.position ?? Duration.zero,
                            onChangeEnd: (newPosition) {
                              audioHandler.seek(newPosition);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );

              }
            }

            return CircularProgressIndicator();
          },
        );
      },
    );
  }
  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
          audioHandler.mediaItem,
          AudioService.position,
              (mediaItem, position) => MediaState(mediaItem, position));


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
