import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bide_et_musique/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/song.dart';
import '../../services/player.dart';
import '../../services/song.dart';
import '../song_page/song_page.dart';
import 'radio_stream_button.dart';
import 'seek_bar.dart';

class PlayerWidget extends StatefulWidget {
  final Orientation orientation;
  final Future<SongAiring>? _songAiring;

  const PlayerWidget(this.orientation, this._songAiring, {super.key});

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  IconButton _button(IconData iconData, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(iconData),
      iconSize: 32.0,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: audioHandler.playbackState.map((s) => s.playing).distinct(),
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;

        if (!playing) return RadioStreamButton(widget._songAiring);

        return FutureBuilder<dynamic>(
          future: audioHandler.customAction('get_radio_mode'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final radioMode = snapshot.data as bool;

            if (radioMode) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_button(Icons.stop, audioHandler.stop)],
              );
            }

            return Row(
              children: [
                _buildSongThumbnail(),
                _buildControls(),
                _buildSeekBar(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSongThumbnail() {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox();

        final songLink = SongLink(
          id: getIdFromUrl(mediaItem.id)!,
          name: mediaItem.title,
        );

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SongPageWidget(
                  songLink: songLink,
                  song: fetchSong(songLink.id),
                ),
              ),
            );
          },
          child: CachedNetworkImage(imageUrl: songLink.thumbLink),
        );
      },
    );
  }

  Widget _buildControls() {
    return StreamBuilder<bool>(
      stream: audioHandler.playbackState.map((s) => s.playing).distinct(),
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;

        final buttons = playing
            ? [
                _button(Icons.fast_rewind_rounded, audioHandler.rewind),
                _button(Icons.stop, audioHandler.stop),
                _button(Icons.fast_forward_rounded, audioHandler.fastForward),
              ]
            : [_button(Icons.stop, audioHandler.stop)];

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buttons,
        );
      },
    );
  }

  Widget _buildSeekBar() {
    return StreamBuilder<MediaState>(
      stream: _mediaStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        return Expanded(
          child: SeekBar(
            duration: state?.mediaItem?.duration ?? Duration.zero,
            position: state?.position ?? Duration.zero,
            onChangeEnd: audioHandler.seek,
          ),
        );
      },
    );
  }

  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
        audioHandler.mediaItem,
        AudioService.position,
        (item, pos) => MediaState(item, pos),
      );
}
