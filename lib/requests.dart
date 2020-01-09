import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:diacritic/diacritic.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'song.dart';
import 'session.dart';
import 'utils.dart';
import 'titles.dart';

class Request {
  SongLink songLink;
  bool isAvailable;

  Request({this.songLink, this.isAvailable});
}

Future<List<Request>> fetchRequests() async {
  var requests = <Request>[];
  final url = '$baseUri/requetes.html';

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
      bool isAvailable = true;
      var request = Request(songLink: songLink, isAvailable: isAvailable);
      requests.add(request);
    }
  } else {
    throw Exception('Failed to load requests');
  }

  return requests;
}

class RequestsPageWidget extends StatelessWidget {
  final Future<List<Request>> requests;

  RequestsPageWidget({Key key, this.requests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Request>>(
        future: requests,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          var loadingMessage = 'Chargement';

          return Scaffold(
            appBar: AppBar(
              title: Text(loadingMessage),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Request> requests) {
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        var songLink = requests[index].songLink;
        return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.black12,
              child: heroThumbCover(songLink),
            ),
            title: Text(songLink.title),
            subtitle: Text(songLink.artist),
            trailing:
                songLink.isNew ? Icon(Icons.fiber_new) : null,
            onTap: () => print('tap!'));
      },
    );
  }
}
