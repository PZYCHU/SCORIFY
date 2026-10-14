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
          final valStr = _formatNilaiSheet1(m, k);

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
          if (k.jenis != JenisKriteria.byProduct) continue;
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
      // SHEET 3: Log Proses KBM (Audit Log Dinamis untuk Kriteria By Process)
      // Menampung histori akumulasi semua kriteria proses: keaktifan, sikap, partisipasi kelompok, dll.
      // ────────────────────────────────────────────────────────────────────────
      final sheet3Name = 'Log Proses KBM';
      final sheet3 = excel[sheet3Name];

      final header3Style = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E6B52'), // Emerald Green
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers3 = [
        'No',
        'NIS',
        'Nama Siswa',
        'Kriteria',
        'Catatan / Aksi Ke-',
        'Nilai / Poin',
        'Total Akumulasi',
        'Tanggal & Waktu',
        'Keterangan',
      ];

      for (int c = 0; c < headers3.length; c++) {
        sheet3.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          ..value = TextCellValue(headers3[c])
          ..cellStyle = header3Style;
      }

      sheet3.setColumnWidth(0, 8);   // No
      sheet3.setColumnWidth(1, 16);  // NIS
      sheet3.setColumnWidth(2, 28);  // Nama Siswa
      sheet3.setColumnWidth(3, 24);  // Kriteria
      sheet3.setColumnWidth(4, 20);  // Catatan / Aksi Ke-
      sheet3.setColumnWidth(5, 14);  // Nilai / Poin
      sheet3.setColumnWidth(6, 16);  // Total Akumulasi
      sheet3.setColumnWidth(7, 20);  // Tanggal & Waktu
      sheet3.setColumnWidth(8, 30);  // Keterangan

      int pRow = 1;
      for (final m in sortedMurid) {
        for (final k in kelas.kriteria) {
          if (k.jenis != JenisKriteria.byProcess) continue;
          final entries = m.nilaiList.where((n) => n.kriteriaId == k.id).toList();
          if (entries.isEmpty) continue;

          // Urutkan berdasarkan kronologi waktu
          entries.sort((a, b) => a.tanggal.compareTo(b.tanggal));

          double runningTotal = 0.0;
          for (int idx = 0; idx < entries.length; idx++) {
            final n = entries[idx];
            runningTotal += n.nilai;
            final aksiKe = idx + 1;
            final isLast = aksiKe == entries.length;

            final pBg = pRow.isEven
                ? ExcelColor.fromHexString('#F2FBF6')
                : ExcelColor.fromHexString('#FFFFFF');
            final pStyle = CellStyle(
              backgroundColorHex: pBg,
              horizontalAlign: HorizontalAlign.Left,
            );
            final pCenter = CellStyle(
              backgroundColorHex: pBg,
              horizontalAlign: HorizontalAlign.Center,
            );

            final tglStr =
                '${n.tanggal.day.toString().padLeft(2, '0')}/${n.tanggal.month.toString().padLeft(2, '0')}/${n.tanggal.year} '
                '${n.tanggal.hour.toString().padLeft(2, '0')}:${n.tanggal.minute.toString().padLeft(2, '0')}';
            final poinStr = n.nilai % 1 == 0
                ? n.nilai.toInt().toString()
                : n.nilai.toStringAsFixed(1);
            final poinDisplay = n.nilai > 0 ? '+$poinStr' : poinStr;
            final totalStr = runningTotal % 1 == 0
                ? runningTotal.toInt().toString()
                : runningTotal.toStringAsFixed(1);

            final ketStr = entries.length == 1
                ? 'Input tunggal'
                : (isLast
                    ? 'Total akhir: $totalStr ($aksiKe kali catatan)'
                    : 'Catatan ke-$aksiKe dari ${entries.length}');

            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: pRow))
              ..value = IntCellValue(pRow)
              ..cellStyle = pCenter;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: pRow))
              ..value = TextCellValue(m.nis ?? '-')
              ..cellStyle = pCenter;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: pRow))
              ..value = TextCellValue(m.nama)
              ..cellStyle = pStyle;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: pRow))
              ..value = TextCellValue(k.nama)
              ..cellStyle = pStyle;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: pRow))
              ..value = TextCellValue('Catatan #$aksiKe')
              ..cellStyle = pCenter;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: pRow))
              ..value = TextCellValue(poinDisplay)
              ..cellStyle = pCenter;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: pRow))
              ..value = TextCellValue(totalStr)
              ..cellStyle = pCenter;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: pRow))
              ..value = TextCellValue(tglStr)
              ..cellStyle = pCenter;
            sheet3.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: pRow))
              ..value = TextCellValue(ketStr)
              ..cellStyle = pStyle;

            pRow++;
          }
        }
      }

      if (pRow == 1) {
        final infoStyle = CellStyle(
          italic: true,
          fontColorHex: ExcelColor.fromHexString('#718096'),
        );
        sheet3.cell(CellIndex.indexByString('A2'))
          ..value = TextCellValue('Belum ada log catatan proses KBM pada kelas ini.')
          ..cellStyle = infoStyle;
      }

      // ────────────────────────────────────────────────────────────────────────
      // SHEET 4: Riwayat Kriteria yang Sudah Dihapus
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
        final sheet4Name = 'Kriteria Dihapus';
        final sheet4 = excel[sheet4Name];

        final header4Style = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#4A1942'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          horizontalAlign: HorizontalAlign.Center,
        );

        final headers4 = [
          'No',
          'NIS',
          'Nama Siswa',
          'ID Kriteria (Sudah Dihapus)',
          'Nilai',
          'Tanggal Input',
          'Keterangan',
        ];

        for (int c = 0; c < headers4.length; c++) {
          sheet4.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            ..value = TextCellValue(headers4[c])
            ..cellStyle = header4Style;
        }

        sheet4.setColumnWidth(0, 8);
        sheet4.setColumnWidth(1, 16);
        sheet4.setColumnWidth(2, 28);
        sheet4.setColumnWidth(3, 32);
        sheet4.setColumnWidth(4, 12);
        sheet4.setColumnWidth(5, 18);
        sheet4.setColumnWidth(6, 30);

        int s4Row = 1;
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

            final rowBg = s4Row.isEven
                ? ExcelColor.fromHexString('#FAF0FF')
                : ExcelColor.fromHexString('#FFFFFF');
            final s4Style = CellStyle(backgroundColorHex: rowBg, horizontalAlign: HorizontalAlign.Left);
            final s4Center = CellStyle(backgroundColorHex: rowBg, horizontalAlign: HorizontalAlign.Center);

            final tglStr = '${n.tanggal.day.toString().padLeft(2, '0')}/'
                '${n.tanggal.month.toString().padLeft(2, '0')}/'
                '${n.tanggal.year}';
            final nilaiStr = n.nilai % 1 == 0
                ? n.nilai.toInt().toString()
                : n.nilai.toStringAsFixed(2);

            sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: s4Row))
              ..value = IntCellValue(s4Row)
              ..cellStyle = s4Center;
            sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: s4Row))
              ..value = TextCellValue(murid.nis ?? '-')
              ..cellStyle = s4Center;
            sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: s4Row))
              ..value = TextCellValue(murid.nama)
              ..cellStyle = s4Style;
            sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: s4Row))
              ..value = TextCellValue(kriteriaIdLabel)
              ..cellStyle = s4Style;
            sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: s4Row))
              ..value = TextCellValue(nilaiStr)
              ..cellStyle = s4Center;
            sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: s4Row))
              ..value = TextCellValue(tglStr)
              ..cellStyle = s4Center;
            sheet4.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: s4Row))
              ..value = TextCellValue('Kriteria ini sudah dihapus dari kelas — data nilai tetap tercatat')
              ..cellStyle = s4Style;

            s4Row++;
          }
        }
      }

      // ─ Simpan file ─
      final bytes = excel.save();
      if (bytes == null) return null;

      final safeName = kelas.nama.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final fileName = 'Laporan_Nilai_${safeName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      return await _saveFile(bytes, fileName);
    } catch (e) {
      debugPrint('ExcelService.exportSiswa error: $e');
      return null;
    }
  }

  /// Format nilai ringkasan untuk tampilan Sheet 1 (Rekap & Ranking)
  /// Menampilkan total poin dan frekuensi (X kali) jika kriteria By Process diinput berulang
  static String _formatNilaiSheet1(Murid murid, Kriteria k) {
    final semuaNilai = murid.getNilaiByKriteria(k.id);
    if (semuaNilai.isEmpty) return '0';

    if (k.jenis == JenisKriteria.byProcess) {
      final activeEntries = semuaNilai.where((n) => n.nilai > 0).toList();
      final count = activeEntries.length;

      double poinAgregasi = 0.0;
      if (k.aggregationRule == AggregationRule.average) {
        poinAgregasi = activeEntries.isEmpty
            ? 0.0
            : activeEntries.fold(0.0, (sum, n) => sum + n.nilai) / activeEntries.length;
      } else if (k.aggregationRule == AggregationRule.min) {
        poinAgregasi = activeEntries.isEmpty
            ? 0.0
            : activeEntries.map((n) => n.nilai).reduce((a, b) => a < b ? a : b);
      } else {
        // Default Max / Counter Sum
        if (k.inputType == InputType.counter) {
          poinAgregasi = semuaNilai.fold(0.0, (sum, n) => sum + n.nilai);
        } else {
          poinAgregasi = semuaNilai.map((n) => n.nilai).reduce((a, b) => a > b ? a : b);
        }
      }

      final poinStr = poinAgregasi % 1 == 0
          ? poinAgregasi.toInt().toString()
          : poinAgregasi.toStringAsFixed(1);

      // Jika ada lebih dari 1 aksi/catatan, atau bertipe counter/keaktifan, sertakan info frekuensi
      final isMultiProcess = k.inputType == InputType.counter ||
          k.nama.toLowerCase().contains('aktif') ||
          semuaNilai.length > 1;

      if (isMultiProcess && count > 0) {
        return '$poinStr (${count}x)';
      }
      return poinStr;
    }

    // Untuk byProduct (tugas, kuis, ujian)
    final val = _hitungNilaiRingkasan(murid, k);
    return val == val.roundToDouble()
        ? val.toInt().toString()
        : val.toStringAsFixed(1);
  }

  /// Helper kalkulasi nilai ringkasan per kriteria untuk diekspor
  static double _hitungNilaiRingkasan(Murid murid, Kriteria k) {
    final semuaNilai = murid.getNilaiByKriteria(k.id);
    if (semuaNilai.isEmpty) return 0;

    final isKeaktifan = k.jenis == JenisKriteria.byProcess &&
        (k.inputType == InputType.counter ||
            k.nama.toLowerCase().contains('aktif'));

    if (isKeaktifan) {
      if (k.aggregationRule == AggregationRule.average) {
        final active = semuaNilai.where((n) => n.nilai > 0).toList();
        return active.isEmpty
            ? 0.0
            : active.fold(0.0, (sum, n) => sum + n.nilai) / active.length;
      } else if (k.aggregationRule == AggregationRule.min) {
        final active = semuaNilai.where((n) => n.nilai > 0).toList();
        return active.isEmpty
            ? 0.0
            : active.map((n) => n.nilai).reduce((a, b) => a < b ? a : b);
      } else {
        return semuaNilai.map((n) => n.nilai).reduce((a, b) => a > b ? a : b);
      }
    }

    if (k.jenis == JenisKriteria.byProduct) {
      final Map<String, List<Nilai>> perSesi = {};
      for (final n in semuaNilai) {
        final key = n.sesiId ?? 'no_sesi';
        perSesi.putIfAbsent(key, () => []).add(n);
      }
      if (perSesi.isEmpty) return 0;

      double totalSesi = 0.0;
      for (final list in perSesi.values) {
        if (k.aggregationRule == AggregationRule.average) {
          totalSesi += list.fold(0.0, (s, n) => s + n.nilai) / list.length;
        } else if (k.aggregationRule == AggregationRule.min) {
          totalSesi += list
              .map((e) => e.nilai)
              .reduce((a, b) => a < b ? a : b);
        } else {
          totalSesi += list
              .map((e) => e.nilai)
              .reduce((a, b) => a > b ? a : b);
        }
      }
      return totalSesi / perSesi.length;
    }

    if (k.jenis == JenisKriteria.byProcess &&
        k.inputType == InputType.attendance) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai);
    }

    if (k.aggregationRule == AggregationRule.average) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai) / semuaNilai.length;
    } else if (k.aggregationRule == AggregationRule.min) {
      return semuaNilai.map((n) => n.nilai).reduce((a, b) => a < b ? a : b);
    }
    return semuaNilai.map((n) => n.nilai).reduce((a, b) => a > b ? a : b);
  }

  /// Menyimpan bytes file dengan fallback kandidat direktori berurutan:
  /// 1. Public Download Android (jika OS mengizinkan)
  /// 2. External Storage App Downloads (bebas permission di Android)
  /// 3. External Storage App Files
  /// 4. getDownloadsDirectory() (Desktop / OS umum)
  /// 5. getApplicationDocumentsDirectory() (Internal app)
  static Future<String?> _saveFile(List<int> bytes, String fileName) async {
    final List<Directory> candidates = [];

    if (Platform.isAndroid) {
      // 1. Coba public Download jika didukung OS (Android <= 9 atau izin khusus)
      candidates.add(Directory('/storage/emulated/0/Download'));

      // 2. Coba Android App External Downloads (tidak butuh permission khusus di Android 10+)
      try {
        final extDownloads = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDownloads != null && extDownloads.isNotEmpty) {
          candidates.addAll(extDownloads);
        }
      } catch (_) {}

      // 3. Coba Android App External Storage
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          candidates.add(extDir);
        }
      } catch (_) {}
    }

    // 4. Desktop / generic Downloads directory
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        candidates.add(downloads);
      }
    } catch (_) {}

    // 5. Fallback ke App Documents (selalu bisa diakses di semua platform)
    try {
      final docs = await getApplicationDocumentsDirectory();
      candidates.add(docs);
    } catch (_) {}

    // Coba simpan berurutan ke kandidat direktori yang bisa ditulis
    for (final dir in candidates) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);

        // Pastikan file berhasil tertulis
        if (await file.exists() && await file.length() > 0) {
          return filePath;
        }
      } catch (e) {
        debugPrint('ExcelService._saveFile: gagal menulis di ${dir.path} ($e), mencoba opsi berikutnya...');
      }
    }

    return null;
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

      const fileName = 'Template_Import_Siswa.xlsx';
      return await _saveFile(bytes, fileName);
    } catch (e) {
      debugPrint('ExcelService.downloadTemplate error: $e');
      return null;
    }
  }
}
