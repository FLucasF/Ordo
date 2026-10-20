/// A small pull reader for the few SpreadsheetML parts the app reads (workbook, relationships, shared
/// strings, sheets). Not a general XML parser: no DTDs, no validation, namespaces reduced to local
/// names (`x:row` and `row` are the same element), which is all an .xlsx needs.
library;

sealed class XmlEvent {
  const XmlEvent();
}

/// `<name a="1">`, or `<name a="1"/>` when [selfClosing].
final class XmlStart extends XmlEvent {
  const XmlStart(this.name, this.attributes, {required this.selfClosing});

  /// The local name, without the namespace prefix.
  final String name;

  /// By local name too: `r:id` is `id`.
  final Map<String, String> attributes;
  final bool selfClosing;

  String? operator [](String attribute) => attributes[attribute];
}

final class XmlEnd extends XmlEvent {
  const XmlEnd(this.name);
  final String name;
}

/// Character data between tags, entities already decoded (CDATA too).
final class XmlText extends XmlEvent {
  const XmlText(this.text);
  final String text;
}

/// The events of [source], in order. Comments, processing instructions and the doctype are skipped.
/// Throws [FormatException] on a tag that never closes.
Iterable<XmlEvent> xmlEvents(String source) sync* {
  final s = source.startsWith('﻿') ? source.substring(1) : source;
  var i = 0;
  while (i < s.length) {
    final lt = s.indexOf('<', i);
    if (lt < 0) {
      final text = s.substring(i);
      if (text.isNotEmpty) yield XmlText(decodeXmlEntities(text));
      return;
    }
    if (lt > i) yield XmlText(decodeXmlEntities(s.substring(i, lt)));
    if (s.startsWith('<!--', lt)) {
      i = _after(s, '-->', lt);
    } else if (s.startsWith('<![CDATA[', lt)) {
      final end = s.indexOf(']]>', lt);
      if (end < 0) throw const FormatException('unclosed CDATA');
      yield XmlText(s.substring(lt + 9, end));
      i = end + 3;
    } else if (s.startsWith('<?', lt)) {
      i = _after(s, '?>', lt);
    } else if (s.startsWith('<!', lt)) {
      i = _after(s, '>', lt);
    } else if (s.startsWith('</', lt)) {
      final end = s.indexOf('>', lt);
      if (end < 0) throw const FormatException('unclosed end tag');
      yield XmlEnd(_local(s.substring(lt + 2, end).trim()));
      i = end + 1;
    } else {
      final end = _tagEnd(s, lt);
      var body = s.substring(lt + 1, end);
      final selfClosing = body.endsWith('/');
      if (selfClosing) body = body.substring(0, body.length - 1);
      final nameEnd = body.indexOf(RegExp(r'\s'));
      final name = _local(nameEnd < 0 ? body : body.substring(0, nameEnd));
      yield XmlStart(name, nameEnd < 0 ? const {} : _attributes(body.substring(nameEnd)), selfClosing: selfClosing);
      i = end + 1;
    }
  }
}

int _after(String s, String marker, int from) {
  final end = s.indexOf(marker, from);
  if (end < 0) throw FormatException('unclosed $marker');
  return end + marker.length;
}

/// The `>` that ends the tag at [from], skipping the ones inside quoted attribute values.
int _tagEnd(String s, int from) {
  String? quote;
  for (var i = from + 1; i < s.length; i++) {
    final c = s[i];
    if (quote != null) {
      if (c == quote) quote = null;
    } else if (c == '"' || c == "'") {
      quote = c;
    } else if (c == '>') {
      return i;
    }
  }
  throw const FormatException('unclosed tag');
}

String _local(String name) {
  final colon = name.indexOf(':');
  return colon < 0 ? name : name.substring(colon + 1);
}

final _attribute = RegExp(r'''([^\s=]+)\s*=\s*("([^"]*)"|'([^']*)')''');

Map<String, String> _attributes(String text) => {for (final m in _attribute.allMatches(text)) _local(m[1]!): decodeXmlEntities(m[3] ?? m[4]!)};

final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos);');

/// `&amp;`, `&lt;`, `&#233;`, `&#xE9;`… An unknown entity stays as written.
String decodeXmlEntities(String text) => !text.contains('&')
    ? text
    : text.replaceAllMapped(_entity, (m) {
        final e = m[1]!;
        return switch (e) {
          'amp' => '&',
          'lt' => '<',
          'gt' => '>',
          'quot' => '"',
          'apos' => "'",
          _ when e.startsWith('#x') => String.fromCharCode(int.parse(e.substring(2), radix: 16)),
          _ => String.fromCharCode(int.parse(e.substring(1))),
        };
      });

/// Text ready to go between tags or in an attribute: the five special characters escaped and the
/// control characters XML 1.0 forbids dropped (tab, line feed and carriage return stay).
String escapeXml(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    switch (rune) {
      case 0x26:
        out.write('&amp;');
      case 0x3C:
        out.write('&lt;');
      case 0x3E:
        out.write('&gt;');
      case 0x22:
        out.write('&quot;');
      case 0x27:
        out.write('&apos;');
      case 0x09 || 0x0A || 0x0D:
        out.writeCharCode(rune);
      case < 0x20 || (>= 0xD800 && <= 0xDFFF) || 0xFFFE || 0xFFFF:
        break;
      default:
        out.writeCharCode(rune);
    }
  }
  return out.toString();
}
