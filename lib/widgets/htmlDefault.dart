import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';

import '../utils.dart';

class HtmlDefault extends StatelessWidget {
  final String data;

  HtmlDefault({this.data});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
        child: Html(
            data: data,
            style: {
              'html': Style(fontSize: FontSize(16.0)),
              'a': Style(color: Colors.red)
            },
            onLinkTap: (url) {
              onLinkTap(url, context);
            }));
  }
}
