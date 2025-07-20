import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/song.dart';
import '../../services/song.dart';

class SongAiringNotifier extends ChangeNotifier {
  static final SongAiringNotifier _singleton = SongAiringNotifier._internal();

  factory SongAiringNotifier() {
    return _singleton;
  }

  SongAiringNotifier._internal();

  Future<SongAiring>? songAiring;
  dynamic e;
  Timer? _t;

  void periodicFetchSongAiring() {
    e = null;
    _reset();
    try {
      songAiring = fetchAiring();
      songAiring!.then(
        (s) async {
          notifyListeners();
          int delay =
              (s.duration!.inSeconds -
                      (s.duration!.inSeconds * s.elapsedPcent! / 100))
                  .ceil();
          _t = Timer(Duration(seconds: delay), () {
            periodicFetchSongAiring();
          });
        },
        onError: (e) {
          this.e = e;
          _reset();
          notifyListeners();
        },
      );
    } catch (e) {
      this.e = e;
      _reset();
      notifyListeners();
    }
  }

  void _reset() {
    _t?.cancel();
    songAiring = null;
  }
}
