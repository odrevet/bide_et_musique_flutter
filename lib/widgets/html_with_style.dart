import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../utils.dart';

class HtmlWithStyle extends StatelessWidget {
  final String? data;

  const HtmlWithStyle({this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Html(
        data: data,
        style: {
          'html': Style(fontSize: FontSize(18.0)),
          'a': Style(color: Colors.red),
        },
        onLinkTap: (url, _, __) {
          onLinkTap(url!, context);
        });
  }
}
