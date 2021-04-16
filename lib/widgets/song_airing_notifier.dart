

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../services/song.dart';

class SongAiringNotifier extends ChangeNotifier {
  static final SongAiringNotifier _singleton = SongAiringNotifier._internal();

  factory SongAiringNotifier() {
    return _singleton;
  }

  SongAiringNotifier._internal();

  Future<SongNowPlaying>? songNowPlaying;
  dynamic? e;
  Timer? _t;

  void periodicFetchSongNowPlaying() {
    e = null;
    _reset();
    try {
      songNowPlaying = fetchNowPlaying();
      songNowPlaying!.then((s) async {
        notifyListeners();
        int delay = (s.duration!.inSeconds -
                (s.duration!.inSeconds * s.elapsedPcent! / 100))
            .ceil();
        _t = Timer(Duration(seconds: delay), () {
          periodicFetchSongNowPlaying();
        });
      }, onError: (e) {
        this.e = e;
        _reset();
        notifyListeners();
      });
    } catch (e) {
      this.e = e;
      _reset();
      notifyListeners();
    }
  }

  _reset() {
    _t?.cancel();
    songNowPlaying = null;
  }
}
