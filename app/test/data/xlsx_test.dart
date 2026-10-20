import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/data/xlsx/mini_xml.dart';
import 'package:task_manager/data/xlsx/xlsx.dart';

/// A zip of [parts] (path → text), as another program would write it.
List<int> zipOf(Map<String, String> parts) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in parts.entries) {
    archive.addFile(ArchiveFile.bytes(key, utf8.encode(value)));
  }
  return ZipEncoder().encode(archive);
}

String partOf(List<int> xlsx, String path) => utf8.decode(ZipDecoder().decodeBytes(xlsx).findFile(path)!.content);

void main() {
  group('mini XML reader', () {
    test('tags, attributes, entities, CDATA; comments and declarations skipped; prefixes dropped', () {
      final events = xmlEvents(
        '﻿<?xml version="1.0"?><!DOCTYPE x><!-- a > comment -->'
        '<x:root a="1 &amp; 2" r:id=\'rId7\' title="a>b"><x:t xml:space="preserve"> caf&#233; &#xE9; &lt;&gt;&quot;&apos;</x:t>'
        '<empty/><![CDATA[<raw> & ]]></x:root>',
      ).toList();
      final root = events.first as XmlStart;
      expect(root.name, 'root');
      expect(root.attributes, {'a': '1 & 2', 'id': 'rId7', 'title': 'a>b'});
      expect(events.whereType<XmlStart>().map((e) => (e.name, e.selfClosing)), [('root', false), ('t', false), ('empty', true)]);
      expect(events.whereType<XmlText>().map((e) => e.text), [' café é <>"\'', '<raw> & ']);
      expect(events.whereType<XmlEnd>().map((e) => e.name), ['t', 'root']);
    });

    test('an unclosed tag is a FormatException', () {
      expect(() => xmlEvents('<a b="1"').toList(), throwsFormatException);
      expect(() => xmlEvents('<a><!-- x').toList(), throwsFormatException);
    });

    test('escapeXml escapes the specials and drops the control characters XML forbids', () {
      expect(escapeXml('a<b>&"\'\tc\nd\u0001\u0008e'), 'a&lt;b&gt;&amp;&quot;&apos;\tc\nde');
      expect(escapeXml('😀 ç'), '😀 ç');
      expect(decodeXmlEntities(escapeXml('<&>"\'')), '<&>"\'');
    });
  });

  group('dates', () {
    test('Excel serial numbers of known days, and the time as the fraction', () {
      expect(excelSerial(DateTime(1900, 3, 1)), 61);
      expect(excelSerial(DateTime(2000, 1, 1)), 36526);
      expect(excelSerial(DateTime(2024, 1, 1)), 45292);
      expect(excelSerial(DateTime(2024, 1, 1, 12)), 45292.5);
      expect(fromExcelSerial(45292), DateTime(2024, 1, 1));
      expect(fromExcelSerial(45292.5), DateTime(2024, 1, 1, 12));
      // A time typed in Excel is never exact in binary: 14:30 rounds to the second.
      expect(fromExcelSerial(46290 + 14.5 / 24 + 1e-9), DateTime(2026, 9, 25, 14, 30));
      final now = DateTime(2026, 10, 20, 23, 59, 59);
      expect(fromExcelSerial(excelSerial(now)), now);
    });

    test('column letters and back', () {
      expect([0, 1, 25, 26, 27, 51, 52, 701, 702].map(columnLetters), ['A', 'B', 'Z', 'AA', 'AB', 'AZ', 'BA', 'ZZ', 'AAA']);
      for (final i in [0, 25, 26, 701, 702, 16383]) {
        expect(columnOf('${columnLetters(i)}12'), i);
      }
      expect(columnOf('12'), isNull);
    });
  });

  group('writing', () {
    final sheets = [
      XlsxSheet(
        'Tarefas',
        const [XlsxColumn('Título', width: 40), XlsxColumn('Prazo'), XlsxColumn('Valor'), XlsxColumn('Qtd')],
        [
          ['Comprar <pão> & "leite"', XlsxDate(DateTime(2026, 9, 25)), const XlsxMoney(123456), 2],
          ['Linha 1\nLinha 2 😀', XlsxDate(DateTime(2026, 9, 25, 14, 30), withTime: true), const XlsxMoney(-50), 2.5],
          [null, null, null, ''],
        ],
      ),
      const XlsxSheet('Lan[ç]a:mentos/*?', [XlsxColumn('A')], []),
      const XlsxSheet('TAREFAS', [XlsxColumn('B')], []),
      const XlsxSheet(
        'Um nome de aba que passa de trinta e um',
        [XlsxColumn('C')],
        [
          ['x'],
        ],
      ),
    ];

    test('round trip: text, numbers, dates and money come back; sheet names follow Excel rules', () {
      final bytes = encodeXlsx(sheets);
      final tables = decodeXlsx(bytes);
      expect(tables.map((t) => t.name), ['Tarefas', 'Lan ç a mentos', 'TAREFAS (2)', 'Um nome de aba que passa de tri']);
      final rows = tables.first.rows;
      expect(rows.map((r) => r.number), [1, 2, 3], reason: 'the empty row is left out');
      expect(rows[0].cells, ['Título', 'Prazo', 'Valor', 'Qtd']);
      expect(rows[1].cells, ['Comprar <pão> & "leite"', 46290.0, 1234.56, 2.0]);
      expect(rows[2].cells, ['Linha 1\nLinha 2 😀', 46290 + 14.5 / 24, -0.5, 2.5]);
      expect(fromExcelSerial(rows[2][1]! as double), DateTime(2026, 9, 25, 14, 30));
      expect(tables[1].rows.single.cells, ['A'], reason: 'an empty sheet still has its header');
    });

    test('the header is bold and frozen, with filters, column widths and the date and money formats', () {
      final bytes = encodeXlsx(sheets);
      final sheet = partOf(bytes, 'xl/worksheets/sheet1.xml');
      expect(sheet, contains('<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'));
      expect(sheet, contains('<autoFilter ref="A1:D4"/>'));
      expect(sheet, contains('<col min="1" max="1" width="40.0" customWidth="1"/>'));
      expect(sheet, contains('<c r="A1" t="inlineStr" s="1">'));
      expect(sheet, contains('<c r="B2" s="2"><v>46290</v></c>'));
      expect(sheet, contains('<c r="B3" s="3">'));
      expect(sheet, contains('<c r="C2" s="4"><v>1234.56</v></c>'));
      final styles = partOf(bytes, 'xl/styles.xml');
      expect(styles, contains('formatCode="dd/mm/yyyy"'));
      expect(styles, contains('<b/>'));
      expect(styles, contains('R\$'));
      final workbook = partOf(bytes, 'xl/workbook.xml');
      expect(
        workbook,
        contains('<definedName name="_xlnm._FilterDatabase" localSheetId="0" hidden="1">&apos;Tarefas&apos;!\$A\$1:\$D\$4</definedName>'),
      );
      expect(partOf(bytes, '[Content_Types].xml'), contains('/xl/worksheets/sheet4.xml'));
    });
  });

  group('reading other programs\' files', () {
    test('a hand-made workbook: shared strings with rich text and phonetics, prefixes, absolute targets, cells without references', () {
      final bytes = zipOf({
        '[Content_Types].xml': '<Types/>',
        'xl/workbook.xml':
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<x:workbook xmlns:x="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            '<x:sheets><x:sheet name="Dados &amp; mais" sheetId="3" r:id="rIdA"/><x:sheet name="Sem parte" sheetId="4" r:id="rIdZ"/></x:sheets></x:workbook>',
        'xl/_rels/workbook.xml.rels':
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rIdA" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="/xl/worksheets/data.xml"/>'
            '<Relationship Id="rIdS" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="strings.xml"/>'
            '</Relationships>',
        'xl/strings.xml':
            '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="3">'
            '<si><t>Título</t></si>'
            '<si><r><rPr><b/></rPr><t>Rich </t></r><r><t xml:space="preserve">text</t></r><rPh sb="0" eb="1"><t>ふりがな</t></rPh></si>'
            '<si><t>quebra_x000D__x000A_aqui</t></si>'
            '<si/>'
            '</sst>',
        'xl/worksheets/data.xml':
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
            '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="C1" t="s"><v>1</v></c></row>'
            '<row r="4"><c t="s"><v>2</v></c><c t="inlineStr"><is><t>inline</t></is></c><c t="str"><f>A4&amp;"!"</f><v>fórmula</v></c>'
            '<c t="b"><v>1</v></c><c t="e"><v>#DIV/0!</v></c><c s="5"><v>45292.75</v></c><c t="s"><v>3</v></c><c t="s"><v>99</v></c></row>'
            '<row r="5"/>'
            '<row r="6"><c r="B6"><v></v></c></row>'
            '</sheetData></worksheet>',
      });
      final tables = decodeXlsx(bytes);
      expect(tables.map((t) => t.name), ['Dados & mais'], reason: 'a sheet whose part is missing is left out');
      final rows = tables.single.rows;
      expect(rows.map((r) => r.number), [1, 4]);
      expect(rows[0].cells, ['Título', null, 'Rich text']);
      expect(rows[1].cells, ['quebra\r\naqui', 'inline', 'fórmula', true, null, 45292.75]);
      expect(rows[1][20], isNull);
    });

    test('without shared strings nor relationships, sheets are found by their usual path', () {
      final bytes = zipOf({
        'xl/workbook.xml': '<workbook><sheets><sheet name="Plan1" sheetId="1"/></sheets></workbook>',
        'xl/worksheets/sheet1.xml':
            '<worksheet><sheetData><row><c><v>1</v></c><c><v>2</v></c></row><row><c><v>3</v></c></row></sheetData></worksheet>',
      });
      final rows = decodeXlsx(bytes).single.rows;
      expect(rows.map((r) => r.number), [1, 2], reason: 'rows without "r" count from 1');
      expect(rows.map((r) => r.cells), [
        [1.0, 2.0],
        [3.0],
      ]);
    });

    test('not a workbook', () {
      expect(() => decodeXlsx(utf8.encode('Título;Prazo\n')), throwsA(isA<InvalidWorkbook>()));
      expect(() => decodeXlsx(zipOf({'tasks.sqlite': 'x'})), throwsA(isA<InvalidWorkbook>()));
      expect(() => decodeXlsx(zipOf({'xl/workbook.xml': '<workbook><sheets><sheet name="a'})), throwsA(isA<InvalidWorkbook>()));
    });
  });
}
