import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bide_et_musique/utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
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
  late final AudioPlayerHandler _handler;
  bool _radioMode = false;
  StreamSubscription? _playbackSub;

  @override
  void initState() {
    super.initState();
    _handler = audioHandler as AudioPlayerHandler;
    _radioMode = _handler.radioMode;
    _playbackSub = audioHandler.playbackState.listen((_) {
      if (mounted) {
        setState(() => _radioMode = _handler.radioMode);
      }
    });
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    super.dispose();
  }

  IconButton _button(IconData iconData, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(iconData),
      iconSize: 32.0,
      onPressed: onPressed,
    );
  }

  Widget _buildRadioStopButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade300.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: audioHandler.stop,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stop,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 10),
                Text(
                  "Éteindre la radio",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: audioHandler.playbackState.map((s) => s.playing).distinct(),
      builder: (context, snapshot) {
        final playing = snapshot.data ?? false;

        if (!playing) return RadioStreamButton(widget._songAiring);

        if (_radioMode) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_buildRadioStopButton()],
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
