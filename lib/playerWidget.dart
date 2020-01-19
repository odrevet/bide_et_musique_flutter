import 'dart:math';
import 'package:rxdart/rxdart.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'player.dart';

class PlayerWidget extends StatefulWidget {
  final PlaybackState _state;

  PlayerWidget(this._state);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget._state?.basicState == BasicPlaybackState.playing ||
              widget._state?.basicState == BasicPlaybackState.buffering
          ? [pauseButton(), stopButton(), positionIndicator()]
          : widget._state?.basicState == BasicPlaybackState.paused
              ? [playButton(), stopButton()]
              : [
                  Padding(
                      padding: const EdgeInsets.all(8), child: startButton())
                ],
    );
  }

  Widget positionIndicator() {
    double seekPos;
    return StreamBuilder(
      stream: Rx.combineLatest2<double, double, double>(
          _dragPositionSubject.stream,
          Stream.periodic(Duration(milliseconds: 200)),
          (dragPosition, _) => dragPosition),
      builder: (context, snapshot) {
        double position =
            snapshot.data ?? widget._state.currentPosition.toDouble();
        double duration = AudioService.currentMediaItem?.duration?.toDouble();

        return Container(
          height: 20,
          child: Row(
            children: [
              if (duration != null)
                Slider(
                  inactiveColor: Colors.grey,
                  activeColor: Colors.red,
                  min: 0.0,
                  max: duration,
                  value: seekPos ?? max(0.0, min(position, duration)),
                  onChanged: (value) {
                    _dragPositionSubject.add(value);
                  },
                  onChangeEnd: (value) {
                    AudioService.seekTo(value.toInt());
                    seekPos = value;
                    _dragPositionSubject.add(null);
                  },
                ),
              if (duration != null)
                Text(
                    "${(widget._state.currentPosition / 1000).toStringAsFixed(0)}"),
            ],
          ),
        );
      },
    );
  }

  final double _iconSize = 48.0;

  RaisedButton startButton() => RaisedButton.icon(
        icon: Icon(Icons.radio, size: _iconSize),
        label: Text("Écouter la radio",
            style: TextStyle(
              fontSize: 20.0,
            )),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: _iconSize,
        onPressed: AudioService.play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: _iconSize,
        onPressed: AudioService.pause,
      );

  IconButton stopButton() => IconButton(
        icon: Icon(Icons.stop),
        iconSize: _iconSize,
        onPressed: AudioService.stop,
      );
}
