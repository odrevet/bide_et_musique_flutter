import 'package:flutter/material.dart';

import '../models/account.dart';
import '../services/account.dart';
import '../services/trombidoscope.dart';
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
    fetchTrombidoscope().then((accounts) => setState(() {
          _isLoading = false;
          _accountLinks = [..._accountLinks, ...accounts];
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
      fetchTrombidoscope().then((accounts) => setState(() {
            _isLoading = false;
            _accountLinks = [..._accountLinks, ...accounts];
          }));
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
                          builder: (context) =>
                              AccountPage(account: fetchAccount(account.id))));
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
