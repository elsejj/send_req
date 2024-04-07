import 'dart:typed_data';
import 'package:mime/mime.dart';

String gussMimetypes(Uint8List body) {
  var type = lookupMimeType('', headerBytes: body);
  if (type == null) {
    return 'application/octet-stream';
  } else {
    return type;
  }
}
