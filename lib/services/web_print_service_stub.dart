import 'package:flutter/services.dart';

Future<void> printReport({required String title, required String content}) async {}

Future<void> downloadReport({required String filename, required String content}) async {
  await Clipboard.setData(ClipboardData(text: content));
}
