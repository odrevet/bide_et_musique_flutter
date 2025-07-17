import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final defaultStyle = const TextStyle(color: Colors.black);
  final reportedError = const TextStyle(fontStyle: FontStyle.italic);
  final dynamic exception;

  const ErrorDisplay(this.exception, {super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: <TextSpan>[
          const TextSpan(
            text: 'Ouille ouille ouille !',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const TextSpan(text: ' \n Une erreur est survenue !'),
          const TextSpan(text: ' \n Le message reporté est : \n'),
          TextSpan(text: ' \n ${exception.toString()}\n', style: reportedError),
          const TextSpan(
            text: ' \n • Verifiez que votre appareil est connecté à Internet\n',
          ),
          const TextSpan(
            text:
                ' \n • Bide et Musique est peut-être temporairement indisponible, ré-éssayez ulterieurement\n',
          ),
        ],
      ),
    );
  }
}
