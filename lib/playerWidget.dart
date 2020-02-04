import 'dart:math';
import 'package:rxdart/rxdart.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'player.dart';

class InheritedPlayer extends InheritedWidget {
  const InheritedPlayer(
      {Key key, @required this.playbackState, @required Widget child})
      : super(key: key, child: child);

  final PlaybackState playbackState;

  static PlaybackState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedPlayer>()
        .playbackState;
  }

  @override
  bool updateShouldNotify(InheritedPlayer old) =>
      playbackState != old.playbackState;
}

class SongPositionSlider extends StatefulWidget {
  final PlaybackState _playerState;
  final double _duration;
  SongPositionSlider(this._playerState, this._duration);

  @override
  _SongPositionSliderState createState() => _SongPositionSliderState();
}

class _SongPositionSliderState extends State<SongPositionSlider> {
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);

  String _formatSongDuration(int ms) {
    Duration duration = Duration(milliseconds: ms);
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    double seekPos;
    return StreamBuilder(
        stream: Rx.combineLatest2<double, double, double>(
            _dragPositionSubject.stream,
            Stream.periodic(Duration(milliseconds: 200)),
            (dragPosition, _) => dragPosition),
        builder: (context, snapshot) {
          double position =
              snapshot.data ?? widget._playerState.currentPosition.toDouble();

          Widget text =
              Text(_formatSongDuration(widget._playerState.currentPosition));

          Widget slider = Slider(
              inactiveColor: Colors.grey,
              activeColor: Colors.red,
              min: 0.0,
              max: widget._duration,
              value: seekPos ?? max(0.0, min(position, widget._duration)),
              onChanged: (value) {
                _dragPositionSubject.add(value);
              },
              onChangeEnd: (value) {
                AudioService.seekTo(value.toInt());
                seekPos = value;
                _dragPositionSubject.add(null);
              });
          return Row(
            children: <Widget>[text, slider],
          );
        });
  }
}

class PlayerWidget extends StatefulWidget {
  final PlaybackState _playbackState;

  PlayerWidget(this._playbackState);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    double duration = AudioService.currentMediaItem?.duration?.toDouble();

    if (widget._playbackState?.basicState == BasicPlaybackState.buffering ||
        widget._playbackState?.basicState == BasicPlaybackState.connecting) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
          stopButton(48),
        ],
      );
    } else
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget._playbackState?.basicState ==
                    BasicPlaybackState.playing ||
                widget._playbackState?.basicState ==
                    BasicPlaybackState.buffering
            ? [
                pauseButton(48),
                stopButton(48),
                if (duration != null)
                  Container(
                    height: 20,
                    child: SongPositionSlider(widget._playbackState, duration),
                  )
              ]
            : widget._playbackState?.basicState == BasicPlaybackState.paused
                ? [
                    playButton(48),
                    stopButton(48),
                  ]
                : [
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: playRadioStreamButton())
                  ],
      );
  }
}

RaisedButton playRadioStreamButton() => RaisedButton.icon(
      icon: Icon(Icons.radio, size: 40),
      label: Text("Écouter la radio",
          style: TextStyle(
            fontSize: 20.0,
          )),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      onPressed: () async {
        bool success = await AudioService.start(
          backgroundTaskEntrypoint: audioPlayerTaskEntrypoint,
          resumeOnClick: true,
          androidNotificationChannelName: 'Bide&Musique',
          notificationColor: 0xFFFFFFFF,
          androidNotificationIcon: 'mipmap/ic_launcher',
        );
        if (success) {
          await AudioService.customAction('resetSong');
          await AudioService.play();
          await AudioService.customAction('setNotification');
        }
      },
    );

IconButton playButton(double iconSize) => IconButton(
      icon: Icon(Icons.play_arrow),
      iconSize: iconSize,
      onPressed: AudioService.play,
    );

IconButton pauseButton(double iconSize) => IconButton(
      icon: Icon(Icons.pause),
      iconSize: iconSize,
      onPressed: AudioService.pause,
    );

IconButton stopButton(double iconSize) => IconButton(
      icon: Icon(Icons.stop),
      iconSize: iconSize,
      onPressed: AudioService.stop,
    );
