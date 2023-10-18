import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';
import 'package:recase/recase.dart';

class IdentifyMethodDeclarations extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  var count = 0;
  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);

    count++;
  }
}

class InsertMethodDeclarations extends GeneralizingAstVisitor<void>
    with AstVisitingSuggestor {
  InsertMethodDeclarations({required this.identified, required this.strings})
      : exists = Set.from(strings.map((e) => e.identifier));

  final IdentifyMethodDeclarations identified;
  final List<Thing> strings;
  final Set<String> exists;
  var idx = 0;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);

    if (exists.contains(node.name.toString())) {
      // matching name so do update
      strings.removeAt(0);
      idx++;
      return;
    }

    final changes = strings
        .where((s) => s.identifier.compareTo(node.name.toString()) < 0)
        .map(constructGetter);

    if (changes.isNotEmpty) {
      yieldPatch([...changes, node.toString()].join(('\n\t')), node.offset,
          node.offset + node.length);
      strings.removeRange(0, changes.length);
    }

    if (idx == identified.count - 1 && strings.isNotEmpty) {
      yieldPatch(
        '\n${[
          ...strings.map((s) => '\t${constructGetter(s)}'),
          '}'
        ].join('\n')}',
        node.offset + node.length,
      );
    }

    idx++;
  }

  String constructGetter(Thing t) {
    if (t.value.contains('\n')) {
      return "String get ${t.identifier} => '''${t.value}''';";
    }
    return "String get ${t.identifier} => '${t.value}';";
  }
}

class Thing {
  Thing.from(dynamic t)
      : identifier = ReCase(t['name']).camelCase,
        value = t['body'];

  final String identifier;
  final String value;
}
