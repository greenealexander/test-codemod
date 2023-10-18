import 'dart:convert';
import 'dart:io';

import 'package:codemod/codemod.dart';
import 'package:glob/glob.dart';
import 'package:http/http.dart';
import 'package:test_codemod/test_codemod.dart';

void main(List<String> args) async {
  final resp = await get(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/1/comments'));

  List<Thing> strings =
      List.from(jsonDecode(resp.body)).map((e) => Thing.from(e)).toList();
  strings.sort((lhs, rhs) => lhs.identifier.compareTo(rhs.identifier));

  final filePaths =
      filePathsFromGlob(Glob('lib/generated/**.dart', recursive: true));

  final tester = IdentifyMethodDeclarations();
  final tester2 =
      InsertMethodDeclarations(identified: tester, strings: strings);

  exitCode = await runInteractiveCodemodSequence(filePaths, [tester, tester2],
      args: args, defaultYes: true);
}
