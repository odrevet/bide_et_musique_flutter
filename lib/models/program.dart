import '../utils.dart';
import 'song.dart';

class ProgramLink {
  int? id;
  String? name;
  String? songCount;

  ProgramLink({this.id, this.name, this.songCount});
}

class Program {
  int? id;
  String? type;
  String? name;
  String? description;
  List<String?>? airedOn;
  List<String>? inMeta;
  List<SongLink>? songs;

  Program({this.id, this.name, this.description, this.airedOn, this.type});

  Program.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      type = json['type'],
      name = decodeHtmlEntities(json['name']),
      description = json['description'] {
    songs = <SongLink>[];
    for (var songEntry in json['songs']) {
      songs!.add(
        SongLink(
          id: songEntry['song_id'],
          name: decodeHtmlEntities(songEntry['name']),
          artist: decodeHtmlEntities(songEntry['alias']),
        ),
      );
    }

    airedOn = <String?>[];
    for (var airedOnEntry in json['aired_on']) {
      airedOn!.add(airedOnEntry);
    }
  }
}
