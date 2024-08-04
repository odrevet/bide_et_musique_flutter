import 'dart:async';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/requests.dart';
import '../models/session.dart';
import '../utils.dart';
import 'song.dart';

Future<List<Request>> fetchRequests() async {
  var requests = <Request>[];
  const url = '$baseUri/requetes.html';

  final response = await Session.get(url);

  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    var table = document.getElementsByClassName('bmtable')[0];
    var trs = table.getElementsByTagName('tr');

    trs.removeRange(0, 3);
    trs.removeLast();
    trs.removeLast();

    for (dom.Element tr in trs) {
      var tds = tr.getElementsByTagName('td');
      tds.removeLast();
      var songLink = songLinkFromTr(tr);
      String? alt = tr.children[4].children[0].attributes['alt'];
      bool isAvailable = alt != 'Pas disponible pour le moment';
      var request = Request(songLink: songLink, isAvailable: isAvailable);
      requests.add(request);
    }
  } else {
    throw Exception('Failed to load requests');
  }

  return requests;
}

Future<int> sendRequest(int? requestId, String dedicate) async {
  const url = '$baseUri/requetes.html';

  var resp = await Session.post(url, body: {
    'Nb': requestId.toString(),
    'Dedicate': dedicate,
    'Dedicate2': ''
  });

  return resp.statusCode;
}
