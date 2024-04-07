import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:provider/provider.dart';

import 'models/template.dart';

class VarSetter extends StatefulWidget {
  final String name;

  const VarSetter({super.key, required this.name});

  @override
  VarSetterState createState() => VarSetterState();
}

class VarSetterState extends State<VarSetter> {
  final TextEditingController _controller = TextEditingController();
  Object? _value;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_isDate(widget.name)) {
      child = _dateVarSetter();
    } else {
      child = _textVarSetter();
    }
    return child;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      var newValue = _value ?? _controller.text;
      Provider.of<TemplateModel>(context, listen: false)
          .setVariable(widget.name, newValue);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isDate(String value) {
    var lower = value.toLowerCase();
    return lower.endsWith('date') || lower.endsWith('time');
  }

  Widget _dateVarSetter() {
    return Row(
      children: [
        Expanded(
            child: TextField(
          decoration: InputDecoration(labelText: widget.name),
          controller: _controller,
          //onChanged: (value) => _updateValue(value),
        )),
        IconButton(
          onPressed: () {
            DatePicker.showDateTimePicker(context,
                showTitleActions: true,
                onConfirm: (date) => _controller.text = date.toString(),
                currentTime: DateTime.now(),
                locale: LocaleType.zh);
          },
          tooltip: '选择日期',
          icon: const Icon(Icons.date_range_outlined),
        ),
      ],
    );
  }

  Widget _textVarSetter() {
    return Row(
      children: [
        Expanded(
            child: TextField(
          decoration: InputDecoration(labelText: widget.name),
          controller: _controller,
          onChanged: (value) => _value = null,
        )),
        IconButton(
          onPressed: () async {
            var files = await FilePicker.platform.pickFiles();
            if (files == null || files.files.single.path == null) {
              return;
            }
            try {
              var file = File(files.files.single.path!);
              var bytes = await file.readAsBytes();
              _value = bytes;
              _controller.text = utf8.decode(bytes);
            } catch (e) {
              debugPrint('Failed to read file: $e');
            }
          },
          icon: const Icon(Icons.file_open_outlined),
          tooltip: '以文件内容填充',
        ),
      ],
    );
  }
}

class VarSetterWidget extends StatelessWidget {
  const VarSetterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var model = Provider.of<TemplateModel>(context);

    var varNames = model.variableNames;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: varNames.map((name) {
        return VarSetter(name: name);
      }).toList(),
    );
  }
}
