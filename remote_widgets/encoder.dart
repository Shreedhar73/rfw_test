import 'dart:io';

import 'package:rfw/formats.dart';

void main() {
  final String counterApp1 = File('a.rfwtxt').readAsStringSync();
  File('text_data.rfw')
      .writeAsBytesSync(encodeLibraryBlob(parseLibraryFile(counterApp1)));
}
