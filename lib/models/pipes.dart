import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:send_req/mimetypes.dart';

Object applyPipe(String pipe, Object input) {
  var lists = pipe.split(' ');

  var pipeName = lists[0];
  var pipeArgs = lists.skip(1).toList();

  switch (pipeName.toLowerCase()) {
    case "base64":
      return base64Encode(input);
    case "base64_dec":
      return base64Decode(input);
    case 'dataurl':
      return dataUrlEncode(input);
    case 'dataurl_dec':
      return dataUrlDecode(input);
    case 'escape':
      return escapeEncode(input);
    case 'escape_dec':
      return escapeDecode(input);
    case 'md5':
      return md5sum(input);
    case 'sha1':
      return sha1sum(input);
    case 'lower':
      return lowerCase(input);
    case 'upper':
      return upperCase(input);
    case 'date':
      return formatDate(input, pipeArgs);
    default:
      return input;
  }
}

Object base64Encode(Object input) {
  switch (input) {
    case String text:
      return base64.encode(utf8.encode(text));
    case Uint8List bytes:
      return base64.encode(bytes);
    default:
      return input;
  }
}

Object base64Decode(Object input) {
  switch (input) {
    case String text:
      return Uint8List.fromList(base64.decode(text));
    case Uint8List bytes:
      return Uint8List.fromList(base64.decode(String.fromCharCodes(bytes)));
    default:
      return input;
  }
}

Object dataUrlEncode(Object input) {
  switch (input) {
    case String text:
      return 'data:text/plain;base64,${base64.encode(utf8.encode(text))}';
    case Uint8List bytes:
      return 'data:${gussMimetypes(bytes)};base64,${base64.encode(bytes)}';
    default:
      return input;
  }
}

Object dataUrlDecode(Object input) {
  if (input is String) {
    var parts = input.split(',');
    if (parts.length == 2) {
      var data = base64.decode(parts[1]);
      return data;
    }
  }
  return input;
}

Object escapeEncode(Object input) {
  switch (input) {
    case String text:
      text = jsonEncode(text);
      return text.substring(1, text.length - 1);
    case Uint8List bytes:
      var text = jsonEncode(String.fromCharCodes(bytes));
      return text.substring(1, text.length - 1);
    default:
      return input;
  }
}

Object escapeDecode(Object input) {
  switch (input) {
    case String text:
      if (text.startsWith('"') && text.endsWith('"')) {
        return jsonDecode(text);
      } else {
        return jsonDecode('"$text"');
      }
    case Uint8List bytes:
      var text = String.fromCharCodes(bytes);
      if (text.startsWith('"') && text.endsWith('"')) {
        return jsonDecode(text);
      } else {
        return jsonDecode('"$text"');
      }
    default:
      return input;
  }
}

Object md5sum(Object input) {
  switch (input) {
    case String text:
      return md5.convert(utf8.encode(text)).toString();
    case Uint8List bytes:
      return md5.convert(bytes).toString();
    default:
      return input;
  }
}

Object sha1sum(Object input) {
  switch (input) {
    case String text:
      return sha1.convert(utf8.encode(text)).toString();
    case Uint8List bytes:
      return sha1.convert(bytes).toString();
    default:
      return input;
  }
}

Object lowerCase(Object input) {
  switch (input) {
    case String text:
      return text.toLowerCase();
    case Uint8List bytes:
      return String.fromCharCodes(bytes).toLowerCase();
    default:
      return input;
  }
}

Object upperCase(Object input) {
  switch (input) {
    case String text:
      return text.toUpperCase();
    case Uint8List bytes:
      return String.fromCharCodes(bytes).toUpperCase();
    default:
      return input;
  }
}

Object formatDate(Object input, List<String> args) {
  var dateText = '';
  switch (input) {
    case String text:
      dateText = text;
    case Uint8List bytes:
      dateText = utf8.decode(bytes);
    default:
      return input;
  }
  DateTime? date;

  // try to parse the input as a number
  try {
    int dataNumber = int.parse(dateText);
    if (dateText.length <= 11) {
      // 11位以下的数字认为是秒级时间戳
      date = DateTime.fromMicrosecondsSinceEpoch(dataNumber * 1000 * 1000);
    } else if (dateText.length <= 14) {
      // 13位以下的数字认为是毫秒级时间戳
      date = DateTime.fromMicrosecondsSinceEpoch(dataNumber * 1000);
    } else if (dateText.length <= 17) {
      // 17位以下的数字认为是微秒级时间戳
      date = DateTime.fromMicrosecondsSinceEpoch(dataNumber);
    } else {
      // 其他情况认为是纳秒级时间戳
      date = DateTime.fromMicrosecondsSinceEpoch(dataNumber ~/ 1000);
    }
  } catch (e) {
    date = null;
  }

  // try to parse the input as a date
  if (date == null) {
    try {
      date = DateTime.parse(dateText);
    } catch (e) {
      date = null;
    }
  }
  if (date == null) {
    return input;
  }

  var format = args.isEmpty ? 'yyyy-MM-dd HH:mm:ss' : args[0];
  var lowerFormat = format.toLowerCase();
  switch (lowerFormat) {
    case 's':
      return '${date.millisecondsSinceEpoch ~/ 1000}';
    case 'ms':
      return '${date.millisecondsSinceEpoch}';
    case 'us':
      return '${date.microsecondsSinceEpoch}';
    case 'ns':
      return '${date.microsecondsSinceEpoch * 1000}';
    default:
      DateFormat formatter = DateFormat(format);
      return formatter.format(date);
  }
}
