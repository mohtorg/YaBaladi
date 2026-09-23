import 'dart:convert';
import 'dart:html' as html;

String _escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('\"', '&quot;')
    .replaceAll("'", '&#39;');

Future<void> printReport({required String title, required String content}) async {
  final t = _escapeHtml(title);
  final c = _escapeHtml(content);
  final url = 'data:text/html;charset=utf-8,' + Uri.encodeComponent(
    '<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">'
    '<title>$t</title><style>body{font-family:Arial,sans-serif;padding:32px;line-height:1.8;color:#111}.report{white-space:pre-wrap}</style>'
    '</head><body><h1>$t</h1><div class="report">$c</div>'
    '<script>window.onload=function(){window.print();}</script></body></html>',
  );
  html.window.open(url, '_blank');
}

Future<void> downloadReport({required String filename, required String content}) async {
  final blob = html.Blob([utf8.encode(content)], 'text/plain;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)..download = filename;
  a.click();
  html.Url.revokeObjectUrl(url);
}
