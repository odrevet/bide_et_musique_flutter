import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../models/song.dart';
import '../player.dart';
import '../session.dart';
import '../utils.dart';
import 'seek_bar.dart';

class SongPlayerWidget extends StatefulWidget {
  final Song? _song;

  SongPlayerWidget(this._song, {Key? key}) : super(key: key);

  @override
  _SongPlayerWidgetState createState() => _SongPlayerWidgetState();
}

class _SongPlayerWidgetState extends State<SongPlayerWidget> {
  _SongPlayerWidgetState();

  Future<void> playSong() async {
    audioHandler.stop();
    await audioHandler.customAction('set_session_id',
        <String, dynamic>{'session_id': Session.headers['cookie']});
    await audioHandler
        .customAction('set_radio_mode', <String, dynamic>{'radio_mode': false});
    await audioHandler.customAction('set_song', widget._song!.toJson());
    audioHandler.play();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            final mediaItem = snapshot.data;

            // No song is being played. Display play arrow
            if (mediaItem == null) {
              return _button(Icons.play_arrow, this.playSong);
            }

            return FutureBuilder<dynamic>(
                future: audioHandler.customAction('get_radio_mode'),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    bool radioMode = snapshot.data;
                    if (radioMode) {
                      return _button(Icons.play_arrow, this.playSong);
                    }
                    else {
                      // check if the displayed song is the song being played
                      return getIdFromUrl(mediaItem.id) == widget._song!.id
                          ? Column(
                        children: [
                          StreamBuilder<bool>(
                            stream: audioHandler.playbackState
                                .map((state) => state.playing)
                                .distinct(),
                            builder: (context, snapshot) {
                              final playing = snapshot.data ?? false;
                              var controls;
                              if (playing) {
                                controls = [
                                  _button(Icons.fast_rewind, audioHandler.rewind),
                                  _button(Icons.pause, audioHandler.pause),
                                  _button(
                                      Icons.fast_forward, audioHandler.fastForward),
                                ];
                              } else {
                                controls = [
                                  _button(Icons.play_arrow, this.playSong),
                                ];
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: controls,
                              );
                            },
                          ),
                          // A seek bar.
                          StreamBuilder<MediaState>(
                            stream: _mediaStateStream,
                            builder: (context, snapshot) {
                              final mediaState = snapshot.data;
                              return SeekBar(
                                duration: mediaState?.mediaItem?.duration ??
                                    Duration.zero,
                                position: mediaState?.position ?? Duration.zero,
                                onChangeEnd: (newPosition) {
                                  audioHandler.seek(newPosition);
                                },
                              );
                            },
                          ),
                        ],
                      )
                          : _button(Icons.play_arrow, this.playSong);
                    }
                  }

                  return CircularProgressIndicator();
                } );


          },
        ),
      ],
    );
  }

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
          audioHandler.mediaItem,
          AudioService.position,
              (mediaItem, position) => MediaState(mediaItem, position));

  IconButton _button(IconData iconData, VoidCallback onPressed) => IconButton(
    icon: Icon(iconData),
    iconSize: 64.0,
    onPressed: onPressed,
  );
}
