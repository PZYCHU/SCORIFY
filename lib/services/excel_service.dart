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

        final cellA = row.length > 0 ? (row[0]?.value?.toString().trim() ?? '') : '';
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

  /// Membuat file Excel berisi daftar siswa (NIS + Nama) lalu menyimpannya
  /// ke direktori Downloads / Documents dan mengembalikan path-nya.
  static Future<String?> exportSiswa(Kelas kelas) async {
    try {
      final excel = Excel.createExcel();
      // Hapus sheet default 'Sheet1' (jika ada) dan buat sheet baru
      final sheetName = 'Daftar Siswa';
      excel.rename('Sheet1', sheetName);
      final sheet = excel[sheetName];

      // ─ Header ─
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

      // Lebar kolom
      sheet.setColumnWidth(0, 18);
      sheet.setColumnWidth(1, 30);

      // ─ Data siswa ─
      final sortedMurid = List<Murid>.from(kelas.muridList);
      // Urutkan: jika sudah kalkulasi pakai skorFinal desc, else by nama
      if (kelas.sudahKalkulasi) {
        sortedMurid.sort((a, b) =>
            (b.skorFinal ?? 0).compareTo(a.skorFinal ?? 0));
      } else {
        sortedMurid.sort((a, b) => a.nama.compareTo(b.nama));
      }

      for (int i = 0; i < sortedMurid.length; i++) {
        final m = sortedMurid[i];
        final rowIdx = i + 1; // 0-based, baris data mulai index 1 (setelah header di 0)

        // Alternating row color
        final rowBg = i.isEven
            ? ExcelColor.fromHexString('#F5F7F3')
            : ExcelColor.fromHexString('#FFFFFF');
        final dataStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Left,
        );

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
          ..value = TextCellValue(m.nis ?? '')
          ..cellStyle = dataStyle;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
          ..value = TextCellValue(m.nama)
          ..cellStyle = dataStyle;
      }

      // ─ Simpan file ─
      final bytes = excel.save();
      if (bytes == null) return null;

      final dir = await _getExportDir();
      final safeName = kelas.nama.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final fileName = 'Siswa_${safeName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      debugPrint('ExcelService.exportSiswa error: $e');
      return null;
    }
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
