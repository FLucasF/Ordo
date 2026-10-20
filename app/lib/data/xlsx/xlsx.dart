import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'mini_xml.dart';

// An .xlsx is a zip of SpreadsheetML parts. This writes the few the app needs (inline strings, one
// styles part with bold headers, dates and reais) and reads back the cells of any workbook: shared
// strings, inline strings, numbers and booleans. Formulas are read by their cached value.

/// A day, or a day and time, written as an Excel date (a serial number with a date format).
class XlsxDate {
  const XlsxDate(this.local, {this.withTime = false});

  /// Local wall-clock time; Excel dates have no time zone.
  final DateTime local;
  final bool withTime;
}

/// Reais in cents, written as a number with the "R$ #,##0.00" format.
class XlsxMoney {
  const XlsxMoney(this.cents);
  final int cents;
}

class XlsxColumn {
  const XlsxColumn(this.header, {this.width = 14});
  final String header;

  /// In Excel's units (about one character of the default font).
  final double width;
}

/// A sheet to write: the header row (bold, frozen, with filters) and the rows under it. A cell is a
/// [String], a [num], an [XlsxDate], an [XlsxMoney] or null (empty).
class XlsxSheet {
  const XlsxSheet(this.name, this.columns, this.rows);
  final String name;
  final List<XlsxColumn> columns;
  final List<List<Object?>> rows;
}

/// A row read from a sheet: its number in Excel (1 = the first) and the cells by column, from A.
/// A cell is a [String], a [double], a [bool] or null.
class XlsxRow {
  const XlsxRow(this.number, this.cells);
  final int number;
  final List<Object?> cells;

  Object? operator [](int column) => column < cells.length ? cells[column] : null;
}

class XlsxTable {
  const XlsxTable(this.name, this.rows);
  final String name;

  /// Rows with at least one cell, in order.
  final List<XlsxRow> rows;
}

/// Thrown when the bytes are not an .xlsx workbook.
class InvalidWorkbook implements Exception {
  const InvalidWorkbook(this.reason);
  final String reason;
  @override
  String toString() => 'InvalidWorkbook: $reason';
}

// ------------------------------------------------------------------ dates

final _excelEpoch = DateTime.utc(1899, 12, 30);

/// Excel's serial number of a local date and time: days since 30/12/1899, the time as the fraction.
double excelSerial(DateTime local) {
  final day = DateTime.utc(local.year, local.month, local.day).difference(_excelEpoch).inDays;
  final seconds = local.hour * 3600 + local.minute * 60 + local.second;
  return day + seconds / 86400;
}

/// The local date and time of an Excel serial number, to the second.
DateTime fromExcelSerial(double serial) {
  final seconds = (serial * 86400).round();
  final utc = _excelEpoch.add(Duration(seconds: seconds));
  return DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);
}

// ------------------------------------------------------------------ writing

/// "A", "B"… "Z", "AA" for the column at [index] (0 = A).
String columnLetters(int index) {
  var n = index + 1;
  var letters = '';
  while (n > 0) {
    letters = String.fromCharCode(65 + (n - 1) % 26) + letters;
    n = (n - 1) ~/ 26;
  }
  return letters;
}

/// Excel's limits on sheet names: 31 characters, none of `[]:*?/\`, unique ignoring case.
List<String> _sheetNames(List<XlsxSheet> sheets) {
  final used = <String>{};
  return [
    for (final s in sheets)
      () {
        var base = s.name.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
        if (base.isEmpty) base = 'Sheet';
        if (base.length > 31) base = base.substring(0, 31);
        var name = base;
        for (var n = 2; used.contains(name.toLowerCase()); n++) {
          final suffix = ' ($n)';
          name = '${base.length + suffix.length > 31 ? base.substring(0, 31 - suffix.length) : base}$suffix';
        }
        used.add(name.toLowerCase());
        return name;
      }(),
  ];
}

// Styles (cellXfs indexes).
const _styleHeader = 1, _styleDate = 2, _styleDateTime = 3, _styleMoney = 4;

/// Longest text a cell takes.
const _maxCellText = 32767;

const _mainNs = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _relNs = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _xmlHead = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';

/// The workbook with [sheets], in order.
Uint8List encodeXlsx(List<XlsxSheet> sheets) {
  final names = _sheetNames(sheets);
  final archive = Archive();
  void add(String path, String xml) => archive.addFile(ArchiveFile.bytes(path, utf8.encode(xml)));

  add(
    '[Content_Types].xml',
    '$_xmlHead<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '${[for (var i = 1; i <= sheets.length; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
        '</Types>',
  );
  add(
    '_rels/.rels',
    '$_xmlHead<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="$_relNs/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
  );
  final filters = StringBuffer();
  for (final (i, s) in sheets.indexed) {
    final quoted = "'${names[i].replaceAll("'", "''")}'";
    filters.write(
      '<definedName name="_xlnm._FilterDatabase" localSheetId="$i" hidden="1">'
      '${escapeXml(quoted)}!\$A\$1:\$${columnLetters(s.columns.length - 1)}\$${s.rows.length + 1}</definedName>',
    );
  }
  add(
    'xl/workbook.xml',
    '$_xmlHead<workbook xmlns="$_mainNs" xmlns:r="$_relNs"><bookViews><workbookView/></bookViews><sheets>'
        '${[for (var i = 0; i < sheets.length; i++) '<sheet name="${escapeXml(names[i])}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
        '</sheets>${sheets.isEmpty ? '' : '<definedNames>$filters</definedNames>'}</workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '$_xmlHead<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '${[for (var i = 1; i <= sheets.length; i++) '<Relationship Id="rId$i" Type="$_relNs/worksheet" Target="worksheets/sheet$i.xml"/>'].join()}'
        '<Relationship Id="rId${sheets.length + 1}" Type="$_relNs/styles" Target="styles.xml"/>'
        '</Relationships>',
  );
  add('xl/styles.xml', _styles);
  for (final (i, s) in sheets.indexed) {
    add('xl/worksheets/sheet${i + 1}.xml', _sheetXml(s));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _styles =
    '$_xmlHead<styleSheet xmlns="$_mainNs">'
    '<numFmts count="3">'
    '<numFmt numFmtId="164" formatCode="dd/mm/yyyy"/>'
    '<numFmt numFmtId="165" formatCode="dd/mm/yyyy hh:mm"/>'
    '<numFmt numFmtId="166" formatCode="&quot;R\$&quot;\\ #,##0.00;\\-&quot;R\$&quot;\\ #,##0.00"/>'
    '</numFmts>'
    '<fonts count="2"><font><sz val="11"/><name val="Calibri"/><family val="2"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/><family val="2"/></font></fonts>'
    '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="5">'
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '<xf numFmtId="166" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>'
    '</cellXfs>'
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
    '</styleSheet>';

String _number(num n) {
  if (n is int || n == n.roundToDouble() && n.abs() < 1e15) return n.round().toString();
  return n.toString();
}

String _cell(String ref, Object? value, {int style = 0}) {
  final s = style == 0 ? '' : ' s="$style"';
  return switch (value) {
    null => '',
    final String text when text.isEmpty => '',
    final String text =>
      '<c r="$ref" t="inlineStr"$s><is><t xml:space="preserve">'
          '${escapeXml(text.length > _maxCellText ? text.substring(0, _maxCellText) : text)}</t></is></c>',
    final num n when n.isFinite => '<c r="$ref"$s><v>${_number(n)}</v></c>',
    num() => '',
    final XlsxDate d => '<c r="$ref" s="${d.withTime ? _styleDateTime : _styleDate}"><v>${_number(excelSerial(d.local))}</v></c>',
    final XlsxMoney m => '<c r="$ref" s="$_styleMoney"><v>${_number(m.cents / 100)}</v></c>',
    _ => _cell(ref, '$value', style: style),
  };
}

String _sheetXml(XlsxSheet s) {
  final out = StringBuffer(
    '$_xmlHead<worksheet xmlns="$_mainNs" xmlns:r="$_relNs">'
    '<sheetViews><sheetView workbookViewId="0">'
    '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
    '<selection pane="bottomLeft" activeCell="A2" sqref="A2"/>'
    '</sheetView></sheetViews>'
    '<sheetFormatPr defaultRowHeight="15"/>',
  );
  if (s.columns.isNotEmpty) {
    out.write('<cols>');
    for (final (i, c) in s.columns.indexed) {
      out.write('<col min="${i + 1}" max="${i + 1}" width="${c.width}" customWidth="1"/>');
    }
    out.write('</cols>');
  }
  out.write('<sheetData><row r="1">');
  for (final (i, c) in s.columns.indexed) {
    out.write(_cell('${columnLetters(i)}1', c.header, style: _styleHeader));
  }
  out.write('</row>');
  for (final (r, row) in s.rows.indexed) {
    out.write('<row r="${r + 2}">');
    for (final (i, value) in row.indexed) {
      out.write(_cell('${columnLetters(i)}${r + 2}', value));
    }
    out.write('</row>');
  }
  out.write('</sheetData>');
  if (s.columns.isNotEmpty) out.write('<autoFilter ref="A1:${columnLetters(s.columns.length - 1)}${s.rows.length + 1}"/>');
  out.write('</worksheet>');
  return out.toString();
}

// ------------------------------------------------------------------ reading

/// The sheets of an .xlsx, in the workbook's order. Throws [InvalidWorkbook] when it is not one.
List<XlsxTable> decodeXlsx(List<int> bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw const InvalidWorkbook('not a zip');
  }
  String? part(String path) {
    final file = archive.findFile(path.startsWith('/') ? path.substring(1) : path);
    if (file == null || !file.isFile) return null;
    return utf8.decode(file.content, allowMalformed: true);
  }

  final workbook = part('xl/workbook.xml');
  if (workbook == null) throw const InvalidWorkbook('no xl/workbook.xml');
  try {
    // Relationship id → part path, relative to xl/ unless absolute.
    final targets = <String, String>{};
    String? sharedStringsPath;
    for (final e in xmlEvents(part('xl/_rels/workbook.xml.rels') ?? '').whereType<XmlStart>()) {
      if (e.name != 'Relationship') continue;
      final target = e['Target'];
      if (target == null) continue;
      final path = target.startsWith('/') ? target.substring(1) : 'xl/$target';
      if (e['Id'] case final id?) targets[id] = path;
      if ((e['Type'] ?? '').endsWith('/sharedStrings')) sharedStringsPath = path;
    }
    final shared = _sharedStrings(part(sharedStringsPath ?? 'xl/sharedStrings.xml'));
    final tables = <XlsxTable>[];
    var index = 0;
    for (final e in xmlEvents(workbook).whereType<XmlStart>()) {
      if (e.name != 'sheet') continue;
      index++;
      final path = targets[e['id']] ?? 'xl/worksheets/sheet$index.xml';
      final xml = part(path);
      if (xml == null) continue;
      tables.add(XlsxTable(e['name'] ?? 'Sheet$index', _rows(xml, shared)));
    }
    return tables;
  } on FormatException catch (e) {
    throw InvalidWorkbook(e.message);
  }
}

/// The `<si>` items: the text of their `<t>`s (rich text runs joined), phonetic guides left out.
List<String> _sharedStrings(String? xml) {
  if (xml == null) return const [];
  final out = <String>[];
  StringBuffer? item;
  var inText = false, inPhonetic = false;
  for (final e in xmlEvents(xml)) {
    switch (e) {
      case XmlStart(name: 'si', :final selfClosing):
        if (selfClosing) {
          out.add('');
        } else {
          item = StringBuffer();
        }
      case XmlEnd(name: 'si'):
        out.add(_unescapeOoxml(item.toString()));
        item = null;
      case XmlStart(name: 'rPh', selfClosing: false):
        inPhonetic = true;
      case XmlEnd(name: 'rPh'):
        inPhonetic = false;
      case XmlStart(name: 't', selfClosing: false):
        inText = true;
      case XmlEnd(name: 't'):
        inText = false;
      case XmlText(:final text) when inText && !inPhonetic:
        item?.write(text);
      default:
    }
  }
  return out;
}

/// SpreadsheetML writes characters XML can't hold as `_xHHHH_` (a line break as `_x000D_`).
String _unescapeOoxml(String text) =>
    !text.contains('_x') ? text : text.replaceAllMapped(RegExp('_x([0-9A-Fa-f]{4})_'), (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)));

/// The column index (0 = A) of a reference such as "AB12"; null when it has no letters.
int? columnOf(String ref) {
  var n = 0, letters = 0;
  for (final c in ref.toUpperCase().codeUnits) {
    if (c < 65 || c > 90) break;
    n = n * 26 + (c - 64);
    letters++;
  }
  return letters == 0 ? null : n - 1;
}

String? _at(List<String> shared, int? index) => index != null && index >= 0 && index < shared.length ? shared[index] : null;

List<XlsxRow> _rows(String xml, List<String> shared) {
  final rows = <XlsxRow>[];
  var rowNumber = 0, column = -1;
  List<Object?>? cells;
  // The cell being read: its column, type and the text of its <v> or <is>.
  String? type;
  StringBuffer? value;
  var inValue = false, inPhonetic = false;

  void endRow() {
    if (cells != null && cells!.any((c) => c != null)) rows.add(XlsxRow(rowNumber, List.unmodifiable(cells!)));
    cells = null;
  }

  void endCell() {
    final raw = value?.toString();
    value = null;
    if (raw == null || cells == null || column < 0) return;
    final Object? parsed = switch (type) {
      's' => _at(shared, int.tryParse(raw.trim())),
      'inlineStr' || 'str' => _unescapeOoxml(raw),
      'b' => raw.trim() == '1' || raw.trim().toLowerCase() == 'true',
      'e' => null,
      _ => double.tryParse(raw.trim()) ?? (raw.trim().isEmpty ? null : raw),
    };
    if (parsed == null || parsed == '') return;
    while (cells!.length <= column) {
      cells!.add(null);
    }
    cells![column] = parsed;
  }

  for (final e in xmlEvents(xml)) {
    switch (e) {
      case XmlStart(name: 'row', :final selfClosing):
        endRow();
        rowNumber = int.tryParse(e['r'] ?? '') ?? rowNumber + 1;
        column = -1;
        cells = selfClosing ? null : [];
      case XmlEnd(name: 'row'):
        endRow();
      case XmlStart(name: 'c'):
        column = columnOf(e['r'] ?? '') ?? column + 1;
        type = e['t'];
        value = null;
      case XmlEnd(name: 'c'):
        endCell();
      case XmlStart(name: 'v' || 't', selfClosing: false):
        inValue = true;
        value ??= StringBuffer();
      case XmlStart(name: 'v' || 't', selfClosing: true):
        value ??= StringBuffer();
      case XmlEnd(name: 'v' || 't'):
        inValue = false;
      case XmlStart(name: 'rPh', selfClosing: false):
        inPhonetic = true;
      case XmlEnd(name: 'rPh'):
        inPhonetic = false;
      case XmlText(:final text) when inValue && !inPhonetic:
        value?.write(text);
      default:
    }
  }
  endRow();
  return rows;
}
