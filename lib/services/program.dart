import 'dart:async';
import 'dart:convert';

import '../models/program.dart';
import '../session.dart';
import '../utils.dart';

Future<Program> fetchProgram(int? programId) async {
  var program;
  final url = '$baseUri/program/$programId';

  final responseJson = await Session.get(url);

  if (responseJson.statusCode == 200) {
    try {
      program =
          Program.fromJson(json.decode(utf8.decode(responseJson.bodyBytes)));
    } catch (e) {
      program = Program();
      program.id = '?';
      program.type = '?';
      program.name = '?';
      program.description = e.toString();
    }
  } else {
    throw Exception('Failed to load Program with id $programId');
  }

  return program;
}
