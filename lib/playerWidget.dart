import 'dart:math';
import 'package:rxdart/rxdart.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'player.dart';

class SongPositionSlider extends StatefulWidget {
  SongPositionSlider();

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
            snapshot.data ?? AudioService.playbackState.currentPosition.toDouble();
        double duration = AudioService.currentMediaItem?.duration.toDouble();

        Widget text =  Text(_formatSongDuration(AudioService.playbackState.currentPosition));

        Widget slider =  Slider(
            inactiveColor: Colors.grey,
            activeColor: Colors.red,
            min: 0.0,
            max: duration,
            value: seekPos ?? max(0.0, min(position,duration)),
            onChanged: (value) {
              _dragPositionSubject.add(value);
            },
            onChangeEnd: (value) {
              AudioService.seekTo(value.toInt());
              seekPos = value;
              _dragPositionSubject.add(null);
            });
        return Row(children: <Widget>[text, slider],);
      }
    );
  }
}

class PlayerWidget extends StatefulWidget {
  PlayerWidget();

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    double duration = AudioService.currentMediaItem?.duration?.toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: AudioService.playbackState?.basicState ==
                  BasicPlaybackState.playing ||
          AudioService.playbackState?.basicState == BasicPlaybackState.buffering
          ? [
              pauseButton(40),
              stopButton(40),
              if (duration != null)
                Container(
                  height: 20,
                  child: SongPositionSlider(),
                )
            ]
          : AudioService.playbackState?.basicState == BasicPlaybackState.paused
              ? [playButton(40), stopButton(40)]
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
