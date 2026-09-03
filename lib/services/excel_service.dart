import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

/// Hasil parsing file Excel untuk import siswa.
class ExcelImportResult {
  final List<({String nis, String nama})> rows;
  final String? error;

  const ExcelImportResult({required this.rows, this.error});
  bool get hasError => error != null;
}

class ExcelService {
  // ─── Import ────────────────────────────────────────────────────────────────

  /// Membuka file picker dan mem-parse file Excel (.xlsx).
  /// Kolom yang dikenali: A = NIS, B = Nama Siswa.
  /// Baris pertama otomatis dianggap header dan dilewati
  /// jika isinya mengandung kata 'nis', 'nama', 'no', dll.
  static Future<({ExcelImportResult result, String? fileName})> pickAndParse() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true, // butuh bytes untuk web/mobile
      );

      if (picked == null || picked.files.isEmpty) {
        return (result: ExcelImportResult(rows: []), fileName: null);
      }

      final pf = picked.files.single;
      final fileName = pf.name;

      // Baca bytes — gunakan .bytes jika tersedia (web/mobile),
      // fallback ke .path untuk desktop.
      Uint8List bytes;
      if (pf.bytes != null) {
        bytes = pf.bytes!;
      } else if (pf.path != null) {
        bytes = await File(pf.path!).readAsBytes();
      } else {
        return (
          result: ExcelImportResult(rows: [], error: 'File tidak dapat dibaca'),
          fileName: fileName,
        );
      }

      // Decode Excel
      final excel = Excel.decodeBytes(bytes);

      // Ambil sheet pertama
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      final rows = <({String nis, String nama})>[];
      bool firstRow = true;

      for (final row in sheet.rows) {
        if (row.isEmpty) continue;

        final cellA = row.isNotEmpty ? (row[0]?.value?.toString().trim() ?? '') : '';
        final cellB = row.length > 1 ? (row[1]?.value?.toString().trim() ?? '') : '';

        // Skip baris header
        if (firstRow) {
          firstRow = false;
          final lower = cellA.toLowerCase();
          if (lower == 'nis' ||
              lower == 'no' ||
              lower == 'nomor' ||
              lower == 'nomer' ||
              cellB.toLowerCase() == 'nama' ||
              cellB.toLowerCase() == 'nama siswa' ||
              cellB.toLowerCase() == 'nama murid') {
            continue;
          }
        }

        // Jika kolom A kosong & kolom B kosong, skip
        if (cellA.isEmpty && cellB.isEmpty) continue;

        // Jika hanya 1 kolom terisi: anggap itu nama (tanpa NIS)
        if (cellB.isEmpty) {
          rows.add((nis: '', nama: cellA));
        } else {
          rows.add((nis: cellA, nama: cellB));
        }
      }

      return (result: ExcelImportResult(rows: rows), fileName: fileName);
    } catch (e) {
      return (
        result: ExcelImportResult(rows: [], error: 'Gagal membaca file: $e'),
        fileName: null,
      );
    }
  }

  // ─── Export ────────────────────────────────────────────────────────────────

  /// Membuat file Excel multi-sheet:
  /// 1. 'Rekap & Ranking' -> Daftar siswa, nilai per kriteria, skor SAW, & ranking.
  /// 2. 'Riwayat Remedial' -> Detail histori attempt remedial per sesi ujian.
  static Future<String?> exportSiswa(Kelas kelas) async {
    try {
      final excel = Excel.createExcel();

      // ────────────────────────────────────────────────────────────────────────
      // SHEET 1: Rekap & Ranking Nilai
      // ────────────────────────────────────────────────────────────────────────
      final sheet1Name = 'Rekap & Ranking';
      excel.rename('Sheet1', sheet1Name);
      final sheet1 = excel[sheet1Name];

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1B4B5A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      // Header kolom Sheet 1
      final headers = [
        'No',
        'NIS',
        'Nama Siswa',
        ...kelas.kriteria.map((k) => k.nama),
        'Skor Akhir (SAW)',
        'Ranking',
      ];

      for (int c = 0; c < headers.length; c++) {
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          ..value = TextCellValue(headers[c])
          ..cellStyle = headerStyle;
      }

      // Lebar kolom Sheet 1
      sheet1.setColumnWidth(0, 8);   // No
      sheet1.setColumnWidth(1, 16);  // NIS
      sheet1.setColumnWidth(2, 28);  // Nama Siswa
      for (int c = 0; c < kelas.kriteria.length; c++) {
        sheet1.setColumnWidth(3 + c, 20); // Kolom kriteria
      }
      sheet1.setColumnWidth(3 + kelas.kriteria.length, 18);     // Skor SAW
      sheet1.setColumnWidth(3 + kelas.kriteria.length + 1, 12); // Ranking

      // Urutkan siswa: jika sudah kalkulasi urut skorFinal desc, jika belum by nama
      final sortedMurid = List<Murid>.from(kelas.muridList);
      if (kelas.sudahKalkulasi) {
        sortedMurid.sort((a, b) =>
            (b.skorFinal ?? 0).compareTo(a.skorFinal ?? 0));
      } else {
        sortedMurid.sort((a, b) => a.nama.compareTo(b.nama));
      }

      // Data Baris Sheet 1
      for (int i = 0; i < sortedMurid.length; i++) {
        final m = sortedMurid[i];
        final rowIdx = i + 1;

        final rowBg = i.isEven
            ? ExcelColor.fromHexString('#F5F7F3')
            : ExcelColor.fromHexString('#FFFFFF');
        final dataStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Left,
        );
        final centerStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // No
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
          ..value = IntCellValue(i + 1)
          ..cellStyle = centerStyle;

        // NIS
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
          ..value = TextCellValue(m.nis ?? '-')
          ..cellStyle = centerStyle;

        // Nama
        sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx))
          ..value = TextCellValue(m.nama)
          ..cellStyle = dataStyle;

        // Nilai per kriteria
        for (int kIdx = 0; kIdx < kelas.kriteria.length; kIdx++) {
          final k = kelas.kriteria[kIdx];
          final val = _hitungNilaiRingkasan(m, k);
          final valStr = k.jenis == JenisKriteria.derived
              ? '${val.toInt()}x'
              : (val == val.roundToDouble()
                  ? val.toInt().toString()
                  : val.toStringAsFixed(1));

          sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 3 + kIdx, rowIndex: rowIdx))
            ..value = TextCellValue(valStr)
            ..cellStyle = centerStyle;
        }

        // Skor Akhir SAW
        final skorStr = m.skorFinal != null ? m.skorFinal!.toStringAsFixed(4) : '-';
        sheet1.cell(CellIndex.indexByColumnRow(
          columnIndex: 3 + kelas.kriteria.length,
          rowIndex: rowIdx,
        ))
          ..value = TextCellValue(skorStr)
          ..cellStyle = centerStyle;

        // Ranking
        final rankStr = kelas.sudahKalkulasi ? '#${i + 1}' : '-';
        sheet1.cell(CellIndex.indexByColumnRow(
          columnIndex: 3 + kelas.kriteria.length + 1,
          rowIndex: rowIdx,
        ))
          ..value = TextCellValue(rankStr)
          ..cellStyle = centerStyle;
      }

      // ────────────────────────────────────────────────────────────────────────
      // SHEET 2: Riwayat Remedial (Audit Log)
      // ────────────────────────────────────────────────────────────────────────
      final sheet2Name = 'Riwayat Remedial';
      final sheet2 = excel[sheet2Name];

      final header2Style = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#8C4A27'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers2 = [
        'No',
        'NIS',
        'Nama Siswa',
        'Kriteria Penilaian',
        'Sesi / Ujian',
        'Attempt',
        'Nilai',
        'Tanggal Input',
        'Keterangan',
      ];

      for (int c = 0; c < headers2.length; c++) {
        sheet2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          ..value = TextCellValue(headers2[c])
          ..cellStyle = header2Style;
      }

      sheet2.setColumnWidth(0, 8);   // No
      sheet2.setColumnWidth(1, 16);  // NIS
      sheet2.setColumnWidth(2, 28);  // Nama Siswa
      sheet2.setColumnWidth(3, 22);  // Kriteria
      sheet2.setColumnWidth(4, 22);  // Sesi
      sheet2.setColumnWidth(5, 14);  // Attempt
      sheet2.setColumnWidth(6, 12);  // Nilai
      sheet2.setColumnWidth(7, 18);  // Tanggal
      sheet2.setColumnWidth(8, 20);  // Keterangan

      // Kumpulkan data attempt remedial siswa
      int rRow = 1;
      for (final m in sortedMurid) {
        // Cari sesi yang memiliki attempt > 1
        for (final k in kelas.kriteria) {
          if (k.jenis != JenisKriteria.hasil) continue;
          final sesiList = kelas.getSesiByKriteria(k.id);

          for (final s in sesiList) {
            final nilaiSesiList = m.nilaiList
                .where((n) => n.kriteriaId == k.id && n.sesiId == s.id)
                .toList();

            // Jika ada nilai di sesi ini dan pernah attempt > 1 (ada perbaikan)
            if (nilaiSesiList.length > 1) {
              nilaiSesiList.sort((a, b) => a.attempt.compareTo(b.attempt));
              final maxAttempt = nilaiSesiList.last.attempt;

              for (final n in nilaiSesiList) {
                final isLast = n.attempt == maxAttempt;
                final rBg = rRow.isEven
                    ? ExcelColor.fromHexString('#FFF8F5')
                    : ExcelColor.fromHexString('#FFFFFF');
                final rStyle = CellStyle(
                  backgroundColorHex: rBg,
                  horizontalAlign: HorizontalAlign.Left,
                );
                final rCenter = CellStyle(
                  backgroundColorHex: rBg,
                  horizontalAlign: HorizontalAlign.Center,
                );

                final tglStr =
                    '${n.tanggal.day.toString().padLeft(2, '0')}/${n.tanggal.month.toString().padLeft(2, '0')}/${n.tanggal.year}';
                final ketStr = isLast
                    ? 'Nilai Akhir (Tuntas)'
                    : 'Attempt ${n.attempt} (Remedial)';

                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rRow))
                  ..value = IntCellValue(rRow)
                  ..cellStyle = rCenter;
                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rRow))
                  ..value = TextCellValue(m.nis ?? '-')
                  ..cellStyle = rCenter;
                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rRow))
                  ..value = TextCellValue(m.nama)
                  ..cellStyle = rStyle;
                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rRow))
                  ..value = TextCellValue(k.nama)
                  ..cellStyle = rStyle;
                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rRow))
                  ..value = TextCellValue(s.nama)
                  ..cellStyle = rStyle;
                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rRow))
                  ..value = TextCellValue('Attempt ${n.attempt}')
                  ..cellStyle = rCenter;
                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rRow))
                  ..value = DoubleCellValue(n.nilai)
                  ..cellStyle = rCenter;
                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rRow))
                  ..value = TextCellValue(tglStr)
                  ..cellStyle = rCenter;
                sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rRow))
                  ..value = TextCellValue(ketStr)
                  ..cellStyle = rStyle;

                rRow++;
              }
            }
          }
        }
      }

      // Jika belum ada remedial sama sekali
      if (rRow == 1) {
        final infoStyle = CellStyle(
          italic: true,
          fontColorHex: ExcelColor.fromHexString('#718096'),
        );
        sheet2.cell(CellIndex.indexByString('A2'))
          ..value = TextCellValue('Belum ada siswa yang melakukan remedial pada kelas ini.')
          ..cellStyle = infoStyle;
      }

      // ────────────────────────────────────────────────────────────────────────
      // SHEET 3: Riwayat Kriteria yang Sudah Dihapus
      // Scan semua nilaiList murid → cari kriteriaId yang tidak ada di kelas.kriteria aktif
      // ────────────────────────────────────────────────────────────────────────
      final activeKriteriaIds = kelas.kriteria.map((k) => k.id).toSet();

      // Kumpulkan semua nilai "yatim piatu" per kriteriaId (yang sudah dihapus)
      // Map<kriteriaId, {nama: String, entri: List<{murid, nilai}>}>
      final Map<String, Map<String, dynamic>> orphanedData = {};

      for (final m in sortedMurid) {
        for (final n in m.nilaiList) {
          if (!activeKriteriaIds.contains(n.kriteriaId)) {
            orphanedData.putIfAbsent(n.kriteriaId, () => {
              'nama': n.kriteriaId, // fallback: pakai ID jika nama tidak diketahui
              'entries': <Map<String, dynamic>>[],
            });
            (orphanedData[n.kriteriaId]!['entries'] as List<Map<String, dynamic>>).add({
              'murid': m,
              'nilai': n,
            });
          }
        }
      }

      if (orphanedData.isNotEmpty) {
        final sheet3Name = 'Kriteria Dihapus';
        final sheet3 = excel[sheet3Name];

        final header3Style = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#4A1942'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          horizontalAlign: HorizontalAlign.Center,
        );

        final headers3 = [
          'No',
          'NIS',
          'Nama Siswa',
          'ID Kriteria (Sudah Dihapus)',
          'Nilai',
          'Tanggal Input',
          'Keterangan',
        ];

        for (int c = 0; c < headers3.length; c++) {
          sheet3.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            ..value = TextCellValue(headers3[c])
            ..cellStyle = header3Style;
        }

        sheet3.setColumnWidth(0, 8);
        sheet3.setColumnWidth(1, 16);
        sheet3.setColumnWidth(2, 28);
        sheet3.setColumnWidth(3, 32);
        sheet3.setColumnWidth(4, 12);
        sheet3.setColumnWidth(5, 18);
        sheet3.setColumnWidth(6, 30);

        int s3Row = 1;
        for (final entry in orphanedData.entries) {
          final kriteriaIdLabel = entry.key;
          final entries = entry.value['entries'] as List<Map<String, dynamic>>;
          entries.sort((a, b) {
            final dateA = (a['nilai'] as Nilai).tanggal;
            final dateB = (b['nilai'] as Nilai).tanggal;
            final muridA = (a['murid'] as Murid).nama;
            final muridB = (b['murid'] as Murid).nama;
            final dateCmp = dateA.compareTo(dateB);
            return dateCmp != 0 ? dateCmp : muridA.compareTo(muridB);
          });

          for (final e in entries) {
            final murid = e['murid'] as Murid;
            final n = e['nilai'] as Nilai;

            final rowBg = s3Row.isEven
                ? ExcelColor.fromHexString('#FAF0FF')
                : ExcelColor.fromHexString('#FFFFFF');
            final s3Style = CellStyle(backgroundColorHex: rowBg, horizontalAlign: HorizontalAlign.Left);
            final s3Center = CellStyle(backgroundColorHex: rowBg, horizontalAlign: HorizontalAlign.Center);

            final tglStr = '${n.tanggal.day.toString().padLeft(2, '0')}/'
                '${n.tanggal.month.toString().padLeft(2, '0')}/'
                '${n.tanggal.year}';
            final nilaiStr = n.nilai % 1 == 0
                ? n.nilai.toInt().toString()
                : n.nilai.toStringAsFixed(2);

            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: s3Row))
              ..value = IntCellValue(s3Row)
              ..cellStyle = s3Center;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: s3Row))
              ..value = TextCellValue(murid.nis ?? '-')
              ..cellStyle = s3Center;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: s3Row))
              ..value = TextCellValue(murid.nama)
              ..cellStyle = s3Style;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: s3Row))
              ..value = TextCellValue(kriteriaIdLabel)
              ..cellStyle = s3Style;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: s3Row))
              ..value = TextCellValue(nilaiStr)
              ..cellStyle = s3Center;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: s3Row))
              ..value = TextCellValue(tglStr)
              ..cellStyle = s3Center;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: s3Row))
              ..value = TextCellValue('Kriteria ini sudah dihapus dari kelas — data nilai tetap tercatat')
              ..cellStyle = s3Style;

            s3Row++;
          }
        }
      }

      // ─ Simpan file ─
      final bytes = excel.save();
      if (bytes == null) return null;

      final dir = await _getExportDir();
      final safeName = kelas.nama.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final fileName = 'Laporan_Nilai_${safeName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      debugPrint('ExcelService.exportSiswa error: $e');
      return null;
    }
  }

  /// Helper kalkulasi nilai ringkasan per kriteria untuk diekspor
  static double _hitungNilaiRingkasan(Murid murid, Kriteria k) {
    if (k.jenis == JenisKriteria.derived) {
      return murid.getFrekuensiNgulang(k.targetKriteriaIds).toDouble();
    }

    final semuaNilai = murid.getNilaiByKriteria(k.id);
    if (semuaNilai.isEmpty) return 0;

    if (k.jenis == JenisKriteria.hasil && k.perSesi) {
      // Ambil nilai terbaik (attempt tertinggi) per sesi, lalu rata-rata antar sesi
      final Map<String, double> bestPerSesi = {};
      for (final n in semuaNilai) {
        final key = n.sesiId ?? 'no_sesi';
        if (!bestPerSesi.containsKey(key) || n.nilai > bestPerSesi[key]!) {
          bestPerSesi[key] = n.nilai;
        }
      }
      if (bestPerSesi.isEmpty) return 0;
      final total = bestPerSesi.values.fold(0.0, (sum, val) => sum + val);
      return total / bestPerSesi.length;
    }

    if (k.jenis == JenisKriteria.performa && k.inputType == InputType.counter) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai);
    }

    final total = semuaNilai.fold(0.0, (sum, n) => sum + n.nilai);
    return total / semuaNilai.length;
  }

  /// Mendapatkan direktori tujuan export yang paling tepat per platform.
  static Future<Directory> _getExportDir() async {
    if (Platform.isAndroid) {
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (await publicDownload.exists()) {
        return publicDownload;
      }
    }
    try {
      // Android / iOS → Downloads
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {}

    // Fallback → Application Documents
    return await getApplicationDocumentsDirectory();
  }

  // ─── Template ──────────────────────────────────────────────────────────────

  /// Membuat file template Excel kosong (header NIS + Nama) untuk diisi user.
  static Future<String?> downloadTemplate() async {
    try {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Daftar Siswa');
      final sheet = excel['Daftar Siswa'];

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1B4B5A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A1'))
        ..value = TextCellValue('NIS')
        ..cellStyle = headerStyle;
      sheet.cell(CellIndex.indexByString('B1'))
        ..value = TextCellValue('Nama Siswa')
        ..cellStyle = headerStyle;

      // Contoh baris
      final exampleStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('#5A7A82'),
        italic: true,
      );
      sheet.cell(CellIndex.indexByString('A2'))
        ..value = TextCellValue('12345')
        ..cellStyle = exampleStyle;
      sheet.cell(CellIndex.indexByString('B2'))
        ..value = TextCellValue('Contoh: Andi Pratama')
        ..cellStyle = exampleStyle;

      sheet.setColumnWidth(0, 18);
      sheet.setColumnWidth(1, 30);

      final bytes = excel.save();
      if (bytes == null) return null;

      final dir = await _getExportDir();
      const fileName = 'Template_Import_Siswa.xlsx';
      final filePath = '${dir.path}/$fileName';

      await File(filePath).writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('ExcelService.downloadTemplate error: $e');
      return null;
    }
  }
}
