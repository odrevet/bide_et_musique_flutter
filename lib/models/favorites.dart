import 'package:html/dom.dart' as dom;

import 'song.dart';

import '../utils.dart';

class FavoritesResults {
  List<SongLink> songLinks;
  int pageCount;
  int page;

  FavoritesResults({this.songLinks, this.pageCount, this.page});
}

List<SongLink> parseFavoriteTable(dom.Element table) {
  List<SongLink> favorites = [];
  int pageCount;
  List<dom.Element> navbars = table.getElementsByClassName('navbar');

  if (navbars.isEmpty)
    pageCount = 0;
  else {
    pageCount = navbars[0].getElementsByTagName('td').length - 1;
  }

  List<dom.Element> trs = table.children[0].children;
  print(trs.length);
  if (pageCount > 0) {
    trs.removeAt(0);
    trs.removeLast();
  }

  for (dom.Element tr in trs) {
    SongLink songLink = SongLink();
    dom.Element aTitle = tr.children[4].children[0];

    if (aTitle.toString() == '<html div>') aTitle = tr.children[4].children[1];

    songLink.id = getIdFromUrl(aTitle.attributes['href']);
    songLink.name = stripTags(aTitle.innerHtml);
    songLink.artist = stripTags(tr.children[3].innerHtml);
    favorites.add(songLink);
  }

  return favorites;
}
