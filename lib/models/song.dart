import '../utils.dart';
import 'comment.dart';
import 'program.dart';

class SongLink {
  int id;
  String name;
  String? artist;
  String? info;
  bool isNew;
  String? cover;
  int? index;

  SongLink(
      {required this.id,
      required this.name,
      this.artist,
      this.cover,
      this.info,
      this.index,
      this.isNew = false});

  String get streamLink {
    return '$baseUri/stream_$id.php';
  }

  String get link {
    return '$baseUri/song/$id.html';
  }

  String get coverLink {
    String url = '$baseUri/images/pochettes/';
    if (cover == null || cover == '') {
      url += '$id.jpg';
    } else {
      url += cover!;
    }
    return url;
  }

  String get thumbLink {
    return '$baseUri/images/thumb100/$id.jpg';
  }
}

class Song extends SongLink {
  int? year;
  int? artistId;
  String? author;
  Duration? duration;
  String? durationPretty;
  String? label;
  String? reference;
  String? lyrics;
  List<Comment> comments = [];
  bool canListen = false;
  bool canFavourite = false;
  bool isFavourite = false;
  bool hasVote = false;

  Song({
    required super.id,
    required super.name,
    super.artist,
    super.cover,
    super.info,
    this.year,
    this.artistId,
    this.author,
    this.duration,
    this.durationPretty,
    this.label,
    this.reference,
    this.lyrics,
  });

  Song.fromJson(Map<String, dynamic> json)
      : year = json['year'],
        artistId = json['artists']['main']['id'],
        author = json['authors'],
        duration = Duration(seconds: json['length']['raw']),
        durationPretty = json['length']['pretty'],
        label = decodeHtmlEntities(json['label']),
        reference = decodeHtmlEntities(json['reference']),
        lyrics = json['lyrics'],
        super(
            id: json['id'],
            name: decodeHtmlEntities(json['name']),
            artist: decodeHtmlEntities(json['artists']['main']['alias']),
            cover: json['covers']['main']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'artist': artist,
        'duration': duration!.inSeconds
      };
}


class SongAiring extends Song {
  final int? elapsedPcent;
  final int? nbListeners;
  final Program program;

  SongAiring.fromJson(super.json)
      : elapsedPcent = json['now']['elapsed_pcent'],
        nbListeners = json['now']['nb_listeners'],
        program = Program(
            id: json['now']['program']['id'],
            name: decodeHtmlEntities(json['now']['program']['name'])),
        super.fromJson();
}
