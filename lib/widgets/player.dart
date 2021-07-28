import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bide_et_musique/utils.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../player.dart';
import 'song.dart';
import '../services/song.dart';
import 'radio_stream_button.dart';
import 'seek_bar.dart';

class PlayerWidget extends StatefulWidget {
  final Orientation orientation;
  final Future<SongNowAiring>? _songNowAiring;

  PlayerWidget(this.orientation, this._songNowAiring);

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

        if (!playing) {
          return RadioStreamButton(widget._songNowAiring);
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
                        : RadioStreamButton(widget._songNowAiring),
                  ],
                );
              } else {
                return Row(
                  children: [
                    StreamBuilder<MediaItem?>(
                      stream: audioHandler.mediaItem,
                      builder: (context, snapshot) {
                        final mediaItem = snapshot.data;
                        final songLink = SongLink(id: getIdFromUrl(mediaItem!.id)!, name: mediaItem.title);
                        return InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SongPageWidget(
                                          songLink: songLink,
                                          song: fetchSong(songLink.id))));
                            },
                          child: CachedNetworkImage(
                              imageUrl: songLink.thumbLink),
                        );
                      },
                    ),
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
}
