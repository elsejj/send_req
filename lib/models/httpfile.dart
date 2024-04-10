import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HttpFile extends ChangeNotifier {
  String method = '';
  String url = '';
  Map<String, String> headers = {};
  String body = '';

  String result = '';

  static final httpFisrtLinePattern = RegExp(r'(\w+) (\S+)');
  static final headerPattern = RegExp(r'(\S+): (.+)');

  void executeSync() {
    result = '等待请求返回，请稍后...';
    notifyListeners();
    execute().then((value) {
      result = value;
      notifyListeners();
    }).onError((error, stackTrace) {
      result = '$error';
      notifyListeners();
    });
  }

  set content(String value) {
    _parseHttpFile(value);
  }

  Future<String> execute() async {
    var request = http.Request(method, Uri.parse(url));

    request.headers.addAll(headers);

    if (body.isNotEmpty) {
      request.body = body;
      //request.headers['Content-Length'] = (body.length + 2).toString();
    }
    var t1 = DateTime.now();
    var resp = await request.send();
    var t2 = DateTime.now();

    List<String> result = [];

    var duration = (t2.difference(t1).inMilliseconds.toDouble()) / 1000.0;
    if (duration > 1) {
      result.add('(请求耗时: ${duration.toStringAsFixed(1)}s)');
    } else {
      result.add('(请求耗时: ${duration.toStringAsFixed(3)}s)');
    }

    result.add('HTTP/${resp.statusCode} ${resp.reasonPhrase}');
    resp.headers.forEach((key, value) {
      result.add('$key: $value');
    });
    result.add('');
    result.add(await resp.stream.bytesToString());
    return result.join('\n');
  }

  void _parseHttpFile(String httpBody) {
    headers.clear();
    body = '';
    method = '';
    url = '';

    var lines = httpBody.split('\n');
    var step = 0;

    var bodyStart = 0;

    for (var (i, line) in lines.indexed) {
      line = line.trim();
      switch (step) {
        case 0:
          step = _parseFirstLine(line);
          break;
        case 1:
          _parseHeaders(line);
          if (line.isEmpty) {
            step = 2;
            bodyStart = i + 1;
          }
          break;
      }
      if (step == 2) {
        break;
      }
    }
    body = lines.sublist(bodyStart).join('\n').trim();
  }

  int _parseFirstLine(String line) {
    var match = httpFisrtLinePattern.firstMatch(line);
    if (match == null) {
      return 0;
    }

    method = match.group(1)!;
    url = match.group(2)!;

    return 1;
  }

  void _parseHeaders(String line) {
    var match = headerPattern.firstMatch(line);
    if (match == null) {
      return;
    }

    headers[match.group(1)!] = match.group(2)!;
  }
}
