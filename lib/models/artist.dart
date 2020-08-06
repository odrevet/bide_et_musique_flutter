import '../utils.dart';
import 'song.dart';

class Artist {
  int id;
  String alias;
  String firstName;
  String lastName;
  String site;
  String dates;
  List<SongLink> disco;

  Artist({this.id, this.alias, this.site, this.dates, this.disco});

  Artist.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        alias = json['alias'],
        site = json['site'],
        dates = json['dates']['pretty'] {
    this.disco = <SongLink>[];
    for (var discoEntry in json['disco']) {
      this.disco.add(
          SongLink(id: discoEntry['id'], name: stripTags(discoEntry['name'])));
    }
  }

  String get urlImage {
    return '$baseUri/images/photos/ART${this.id}.jpg';
  }
}
