import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

import '../models/account.dart';
import '../services/account.dart';
import '../session.dart';
import '../utils.dart';
import 'account.dart';

class TrombidoscopeWidget extends StatefulWidget {
  TrombidoscopeWidget({Key key}) : super(key: key);

  @override
  _TrombidoscopeWidgetState createState() => _TrombidoscopeWidgetState();
}

class _TrombidoscopeWidgetState extends State<TrombidoscopeWidget> {
  var _accountLinks = <AccountLink>[];
  ScrollController _controller = ScrollController();
  bool _isLoading;

  final _font = TextStyle(
      fontSize: 18.0,
      background: Paint()..color = Color.fromARGB(180, 150, 150, 100));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    _isLoading = true;
    fetchTrombidoscope().then((_) => setState(() {
          _isLoading = false;
        }));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_scrollListener);
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange &&
        _isLoading == false) {
      setState(() {
        _isLoading = true;
      });
      fetchTrombidoscope().then((_) => setState(() {
            _isLoading = false;
          }));
    }
  }

  Future<void> fetchTrombidoscope() async {
    final url = '$baseUri/trombidoscope.html';
    final response = await Session.get(url);
    if (response.statusCode == 200) {
      var body = response.body;
      dom.Document document = parser.parse(body);

      var table = document.getElementsByClassName('bmtable')[0];
      for (dom.Element td in table.getElementsByTagName('td')) {
        var a = td.children[0];
        var href = a.attributes['href'];
        var id = getIdFromUrl(href);
        var account = AccountLink();
        account.id = id;
        account.name = stripTags(a.innerHtml);
        account.image = a.children[0].attributes['src'];
        setState(() {
          _accountLinks.add(account);
        });
      }
    } else {
      throw Exception('Failed to load trombines');
    }
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return Scaffold(
        appBar: AppBar(
          title: Text('Le trombidoscope'),
        ),
        body: GridView.builder(
            itemCount: _accountLinks.length,
            controller: _controller,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: orientation == Orientation.portrait ? 2 : 3),
            itemBuilder: (BuildContext context, int index) {
              var account = _accountLinks[index];
              final url = baseUri + account.image;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AccountPageWidget(
                              account: fetchAccount(account.id))));
                },
                onLongPress: () {
                  openAccountImageViewerDialog(context, NetworkImage(url));
                },
                child: Container(
                  child: Text(account.name, style: _font),
                  decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      image: DecorationImage(
                        fit: BoxFit.contain,
                        alignment: FractionalOffset.topCenter,
                        image: NetworkImage(url),
                      )),
                ),
              );
            }));
  }
}
