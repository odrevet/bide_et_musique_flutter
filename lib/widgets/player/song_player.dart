import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/session.dart';
import '../../models/song.dart';
import '../../services/player.dart';
import '../../utils.dart';
import 'seek_bar.dart';

class SongPlayerWidget extends StatefulWidget {
  final Song? _song;

  const SongPlayerWidget(this._song, {super.key});

  @override
  State<SongPlayerWidget> createState() => _SongPlayerWidgetState();
}

class _SongPlayerWidgetState extends State<SongPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _playButtonController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> playSong() async {
    _playButtonController.forward().then((_) {
      _playButtonController.reverse();
    });

    audioHandler.stop();
    await audioHandler.customAction('set_session_id', <String, dynamic>{
      'session_id': Session.headers['cookie'],
    });
    await audioHandler.customAction('set_radio_mode', <String, dynamic>{
      'radio_mode': false,
    });
    await audioHandler.customAction('set_song', widget._song!.toJson());
    audioHandler.play();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player controls
            StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;

                // No song is being played
                if (mediaItem == null) {
                  return _buildSimplePlayButton();
                }

                return FutureBuilder<dynamic>(
                  future: audioHandler.customAction('get_radio_mode'),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      bool radioMode = snapshot.data;
                      if (radioMode) {
                        return _buildSimplePlayButton();
                      } else {
                        // Check if the displayed song is the song being played
                        return getIdFromUrl(mediaItem.id) == widget._song!.id
                            ? _buildFullPlayerControls(mediaItem)
                            : _buildSimplePlayButton();
                      }
                    }

                    return _buildLoadingState();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePlayButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _playButtonController, curve: Curves.easeInOut),
        ),
        child: IconButton(
          icon: const Icon(Icons.play_arrow_rounded),
          iconSize: 48,
          color: Theme.of(context).colorScheme.onPrimary,
          onPressed: playSong,
          padding: const EdgeInsets.all(24),
        ),
      ),
    );
  }

  Widget _buildFullPlayerControls(MediaItem mediaItem) {
    return Column(
      children: [
        // Playback controls
        StreamBuilder<bool>(
          stream: audioHandler.playbackState
              .map((state) => state.playing)
              .distinct(),
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Rewind button
                  _buildControlButton(
                    Icons.fast_rewind_rounded,
                    audioHandler.rewind,
                    enabled: playing,
                  ),

                  // Main play/pause button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey(playing),
                        ),
                      ),
                      iconSize: 40,
                      color: Theme.of(context).colorScheme.onPrimary,
                      onPressed: playing ? audioHandler.pause : playSong,
                      padding: const EdgeInsets.all(20),
                    ),
                  ),

                  // Fast forward button
                  _buildControlButton(
                    Icons.fast_forward_rounded,
                    audioHandler.fastForward,
                    enabled: playing,
                  ),
                ],
              ),
            );
          },
        ),

        // Seek bar with time indicators
        StreamBuilder<MediaState>(
          stream: _mediaStateStream,
          builder: (context, snapshot) {
            final mediaState = snapshot.data;
            final duration = mediaState?.mediaItem?.duration ?? Duration.zero;
            final position = mediaState?.position ?? Duration.zero;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  SeekBar(
                    duration: duration,
                    position: position,
                    onChangeEnd: (newPosition) {
                      audioHandler.seek(newPosition);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Time indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(enabled ? 1.0 : 0.5),
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: 32,
        color: enabled
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
        onPressed: enabled ? onPressed : null,
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSecondaryButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 24,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      onPressed: onPressed,
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem?, Duration, MediaState>(
        audioHandler.mediaItem,
        AudioService.position,
            (mediaItem, position) => MediaState(mediaItem, position),
      );

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// MediaState class for combining media item and position
class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}