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
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _t?.cancel();
    super.dispose();
  }

  void periodicFetchSongAiring() {
    e = null;
    _reset();
    try {
      songAiring = fetchAiring();
      songAiring!.then(
        (s) {
          if (_disposed) return;
          notifyListeners();
          int delay =
              (s.duration!.inSeconds -
                      (s.duration!.inSeconds * s.elapsedPcent! / 100))
                  .ceil();
          _t = Timer(Duration(seconds: delay), () {
            if (!_disposed) periodicFetchSongAiring();
          });
        },
        onError: (e) {
          if (_disposed) return;
          this.e = e;
          _reset();
          notifyListeners();
        },
      );
    } catch (e) {
      if (_disposed) return;
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
