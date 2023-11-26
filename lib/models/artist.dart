import '../utils.dart';
import 'song.dart';

class Artist {
  int id;
  String? alias;
  String? firstName;
  String? lastName;
  String? site;
  String? dates;
  List<SongLink>? disco;

  Artist({required this.id, this.alias, this.site, this.dates, this.disco});

  Artist.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        alias = json['alias'],
        site = json['site'],
        dates = json['dates']['pretty'] {
    disco = <SongLink>[];
    for (var discoEntry in json['disco']) {
      disco!.add(SongLink(
          id: discoEntry['id'], name: decodeHtmlEntities(discoEntry['name'])));
    }
  }

  String get urlImage {
    return '$baseUri/images/photos/ART$id.jpg';
  }
}
