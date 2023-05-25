import 'package:flutter/material.dart';

import '../models/account.dart';
import '../services/account.dart';
import '../services/trombidoscope.dart';
import '../utils.dart';
import 'account.dart';

class TrombidoscopeWidget extends StatefulWidget {
  const TrombidoscopeWidget({Key? key}) : super(key: key);

  @override
  State<TrombidoscopeWidget> createState() => _TrombidoscopeWidgetState();
}

class _TrombidoscopeWidgetState extends State<TrombidoscopeWidget> {
  var _accountLinks = <AccountLink>[];
  final ScrollController _controller = ScrollController();
  bool? _isLoading;

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
          title: const Text('Le trombidoscope'),
        ),
        body: GridView.builder(
            itemCount: _accountLinks.length,
            controller: _controller,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: orientation == Orientation.portrait ? 1 : 3),
            itemBuilder: (BuildContext context, int index) {
              var account = _accountLinks[index];
              final url = baseUri + account.image!;
              return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AccountPage(account: fetchAccount(account.id))));
                  },
                  onLongPress: () {
                    openAccountImageViewerDialog(context, NetworkImage(url), account.name);
                  },
                  child: Column(
                    children: [
                      Text(account.name!, style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 16.0,)),
                      Expanded(
                          child: Container(
                        decoration: BoxDecoration(
                            image: DecorationImage(
                          fit: BoxFit.contain,
                          image: NetworkImage(url),
                        )),
                      )),
                    ],
                  ));
            }));
  }
}
