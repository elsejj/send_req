import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:send_req/models/pipes.dart';

// a variable in the template
class Variable {
  String name = '';
  Object? value;

  List<String> pipes = [];
  final int startPos;
  final int endPos;

  Variable(this.startPos, this.endPos, String text) {
    parseDefinition(text);
  }

  // parse the definition of the variable
  // e.g. "name|pipe1|pipe2"
  void parseDefinition(String definition) {
    var parts = definition.split('|');
    name = parts.first.trim();
    pipes = parts.skip(1).map((e) => e.trim()).toList();
  }

  String get builded {
    if (value == null) {
      return '';
    }
    if (pipes.isEmpty) {
      switch (value) {
        case String text:
          return text;
        case Uint8List bytes:
          return value = bytes.toString();
        default:
          return value.toString();
      }
    } else {
      var newValue = value!;
      for (var pipe in pipes) {
        newValue = applyPipe(pipe, newValue);
      }
      return newValue.toString();
    }
  }
}

class TemplateModel extends ChangeNotifier {
  String _filePath = '';
  String _template = '';
  String get template => _template;

  final List<Variable> _variables = [];

  TemplateModel(String path) {
    filePath = path;
  }

  static final variablePattern = RegExp(r'{{\s*(.+?)\s*}}');

  set filePath(String path) {
    try {
      // read the file and set the template
      final file = File(path);
      final content = file.readAsStringSync();
      _template = content;
      _filePath = path;

      _parseVariables();

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to read file: $e');
    }
  }

  reload() {
    filePath = _filePath;
  }

  String get filePath => _filePath;

  void setVariable(String name, Object? value) {
    bool changed = false;
    for (var v in _variables) {
      if (v.name == name) {
        changed = v.value != value;
        v.value = value;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  bool get hasVariables => _variables.isNotEmpty;

  bool get loaded => _template.isNotEmpty;

  List<String> get variableNames {
    var names = <String>[];
    for (var v in _variables) {
      if (!names.contains(v.name)) {
        names.add(v.name);
      }
    }
    return names;
  }

  String get replaced {
    var result = _template;
    List<String> parts = [];
    var start = 0;
    for (var v in _variables) {
      parts.add(result.substring(start, v.startPos));
      var value = v.builded;
      if (value.isNotEmpty) {
        parts.add(v.builded);
      } else {
        parts.add(result.substring(v.startPos, v.endPos));
      }
      start = v.endPos;
    }
    parts.add(result.substring(start));
    result = parts.join('');
    return parts.join('');
  }

  void _parseVariables() {
    _variables.clear();
    var match = variablePattern.allMatches(_template);
    for (var m in match) {
      _variables.add(Variable(m.start, m.end, m.group(1)!));
    }
  }
}
