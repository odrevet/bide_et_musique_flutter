import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class SongPositionSlider extends StatefulWidget {
  final MediaItem mediaItem;
  final PlaybackState state;

  SongPositionSlider(this.mediaItem, this.state);

  @override
  _SongPositionSliderState createState() => _SongPositionSliderState();
}

class _SongPositionSliderState extends State<SongPositionSlider> {
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);

  String _formatSongDuration(Duration duration) {
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
          double position = snapshot.data ??
              widget.state.currentPosition.inMilliseconds.toDouble();
          double duration =
              widget.mediaItem?.duration?.inMilliseconds?.toDouble();

          Widget text = Text(_formatSongDuration(widget.state.currentPosition));

          Widget slider = Slider(
              inactiveColor: Colors.grey,
              activeColor: Colors.red,
              min: 0.0,
              max: duration,
              value: seekPos ?? max(0.0, min(position, duration)),
              onChanged: (value) {
                _dragPositionSubject.add(value);
              },
              onChangeEnd: (value) {
                AudioService.seekTo(Duration(milliseconds: value.toInt()));
                seekPos = value;
                _dragPositionSubject.add(null);
              });
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[text, slider],
          );
        });
  }
}
