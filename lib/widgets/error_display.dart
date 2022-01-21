import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final title = TextStyle(fontWeight: FontWeight.bold, color: Colors.red);
  final defaultStyle = TextStyle(color: Colors.black);
  final reportedError = TextStyle(fontStyle: FontStyle.italic);
  final dynamic exception;

  ErrorDisplay(this.exception);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: <TextSpan>[
          TextSpan(text: 'Ouille ouille ouille !', style: title),
          TextSpan(text: ' \n Une erreur est survenue !'),
          TextSpan(text: ' \n Le message reporté est : \n'),
          TextSpan(text: ' \n ${exception.toString()}\n', style: reportedError),
          TextSpan(
              text:
                  ' \n • Verifiez que votre appareil est connecté à Internet\n'),
          TextSpan(
              text:
                  ' \n • Bide et Musique est peut-être temporairement indisponible, ré-éssayez ulterieurement\n')
        ],
      ),
    );
  }
}
