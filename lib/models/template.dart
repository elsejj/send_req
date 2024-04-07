import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:send_req/models/pipes.dart';

// a variable in the template
class Variable {
  String name = '';
  Object? _value;

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

  set value(Object? newValue) {
    _value = buildValue(newValue);
  }

  Object? get value => _value;

  String get valueAsString {
    if (_value == null) {
      return '';
    }
    switch (_value) {
      case String text:
        return text;
      case Uint8List bytes:
        return utf8.decode(bytes);
      default:
        return '';
    }
  }

  bool trySetValue(Object? newValue) {
    newValue = buildValue(newValue);
    if (equals(_value, newValue)) {
      return false;
    }
    _value = newValue;
    return true;
  }

  bool equals(Object? left, Object? right) {
    if (left == null && right == null) {
      return true;
    }
    if (left == null || right == null) {
      return false;
    }
    if (left.runtimeType != right.runtimeType) {
      return false;
    }
    if (left is String && right is String) {
      return left == right;
    }
    if (left is Uint8List && right is Uint8List) {
      return left.length == right.length &&
          left.every((e) => right.contains(e));
    }
    return false;
  }

  Object? buildValue(Object? newValue) {
    if (newValue == null) {
      return null;
    }
    Object? value;
    if (pipes.isEmpty) {
      switch (newValue) {
        case String text:
          value = text;
          break;
        case Uint8List bytes:
          value = utf8.decode(bytes);
          break;
      }
    } else {
      value = newValue;
      for (var pipe in pipes) {
        value = applyPipe(pipe, value!);
      }
    }
    return value;
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

  Object? setVariable(String name, Object? value) {
    for (var v in _variables) {
      if (v.name == name) {
        if (v.trySetValue(value)) {
          notifyListeners();
        }
        return v.value;
      }
    }
    return null;
  }

  String getVariable(String name) {
    for (var v in _variables) {
      if (v.name == name) {
        return v.valueAsString;
      }
    }
    return '';
  }

  bool get hasVariables => _variables.isNotEmpty;

  bool get loaded => _template.isNotEmpty;

  List<String> get variableNames {
    return _variables.map((e) => e.name).toList();
  }

  String get replaced {
    var result = _template;
    List<String> parts = [];
    var start = 0;
    for (var v in _variables) {
      parts.add(result.substring(start, v.startPos));
      var value = v.valueAsString;
      if (value.isNotEmpty) {
        parts.add(v.valueAsString);
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
