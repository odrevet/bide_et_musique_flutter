import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

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
      String alt = tr.children[4].children[0].attributes['alt'];
      bool isAvailable = alt != 'Pas disponible pour le moment';
      var request = Request(songLink: songLink, isAvailable: isAvailable);
      requests.add(request);
    }
  } else {
    throw Exception('Failed to load requests');
  }

  return requests;
}

class RequestsPageWidget extends StatefulWidget {
  RequestsPageWidget({Key key}) : super(key: key);

  @override
  _RequestsPageWidgetState createState() => _RequestsPageWidgetState();
}

class _RequestsPageWidgetState extends State<RequestsPageWidget> {
  String _selectedRequestId;
  final _dedicateController = TextEditingController();
  Future<List<Request>> _requests;

  @override
  void initState() {
    _updateRequests();
    super.initState();
  }

  void _updateRequests() async {
    setState(() {
      _selectedRequestId = null;
      _requests = fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Request>>(
        future: this._requests,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          return CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, List<Request> requests) {
    Widget listview = ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        var songLink = requests[index].songLink;
        bool isAvailable = requests[index].isAvailable;

        Widget listTile = ListTile(
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongPageWidget(
                            songLink: songLink, song: fetchSong(songLink.id))));
              },
              child: CircleAvatar(
                backgroundColor: Colors.black12,
                child: heroThumbCover(songLink),
              ),
            ),
            title: Text(songLink.title),
            subtitle: Text(songLink.artist),
            trailing: songLink.isNew ? Icon(Icons.fiber_new) : null,
            onTap: () => setState(() {
                  if (isAvailable) _selectedRequestId = songLink.id;
                }));

        if (songLink.id == _selectedRequestId)
          return Material(color: Colors.orange[400], child: listTile);
        else if (isAvailable != true)
          return Material(color: Colors.red[300], child: listTile);
        else
          return listTile;
      },
    );

    Function onPressed = _selectedRequestId == null ? null : _sendRequest;
    return Column(
      children: <Widget>[
        Expanded(child: listview),
        Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                maxLength: 40,
                enabled: _selectedRequestId != null,
                controller: _dedicateController,
                decoration: InputDecoration(
                    hintText: 'Dédicace (facultative, 40 caractères maximum)'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: onPressed,
            )
          ],
        )
      ],
    );
  }

  void _sendRequest() async {
    final url = '$baseUri/requetes.html';
    String dedicate = _dedicateController.text;
    await Session.post(url, body: {
      'Nb': _selectedRequestId.toString(),
      'Dedicate': dedicate,
      'Dedicate2': ''
    });

    _updateRequests();
  }
}
