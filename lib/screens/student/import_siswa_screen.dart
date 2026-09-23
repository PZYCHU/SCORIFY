import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/excel_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Layar import siswa dari file Excel (.xlsx / .xls).
/// Format: Kolom A = NIS, Kolom B = Nama Siswa.
/// Baris pertama (header) otomatis dilewati.
class ImportSiswaScreen extends StatefulWidget {
  final String kelasId;
  final Kelas kelas;

  const ImportSiswaScreen({
    super.key,
    required this.kelasId,
    required this.kelas,
  });

  @override
  State<ImportSiswaScreen> createState() => _ImportSiswaScreenState();
}

class _ImportSiswaScreenState extends State<ImportSiswaScreen> {
  List<({String nis, String nama})> _preview = [];
  List<String> _namaDuplikat = [];
  bool _loading = false;
  bool _saving = false;
  String? _fileName;
  String? _errorMsg;

  // Nama siswa yang sudah ada di kelas (lowercase untuk cek duplikat)
  Set<String> get _existingNames =>
      widget.kelas.muridList.map((m) => m.nama.toLowerCase().trim()).toSet();

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
      _preview = [];
      _namaDuplikat = [];
    });

    try {
      final (:result, :fileName) = await ExcelService.pickAndParse();

      if (fileName == null) {
        // User batal
        setState(() => _loading = false);
        return;
      }

      _fileName = fileName;

      if (result.hasError) {
        setState(() => _errorMsg = result.error);
        return;
      }

      // Filter baris yang namanya tidak kosong
      final rows = result.rows.where((r) => r.nama.isNotEmpty).toList();

      // Cek duplikat
      final duplikat = rows
          .where((r) => _existingNames.contains(r.nama.toLowerCase().trim()))
          .map((r) => r.nama)
          .toList();

      setState(() {
        _preview = rows;
        _namaDuplikat = duplikat;
      });
    } catch (e) {
      setState(() => _errorMsg = 'Gagal membaca file: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadTemplate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Mengunduh Template Excel...',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final path = await ExcelService.downloadTemplate();
      if (mounted) Navigator.of(context).pop(); // Tutup dialog progress

      if (path != null && mounted) {
        AppFeedback.showDownloadSuccessSheet(
          context,
          filePath: path,
          title: 'Template Excel Berhasil Diunduh',
        );
      } else if (mounted) {
        AppFeedback.showError(context, 'Gagal mengunduh template Excel');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        AppFeedback.showError(context, 'Terjadi kesalahan: $e');
      }
    }
  }

  Future<void> _import() async {
    if (_preview.isEmpty) return;
    setState(() => _saving = true);

    final provider = context.read<AppProvider>();

    // Hanya import nama yang belum ada
    final toImport = _preview
        .where((r) => !_existingNames.contains(r.nama.toLowerCase().trim()))
        .toList();

    final newMuridList = toImport.asMap().entries.map((e) {
      final r = e.value;
      return Murid(
        id: '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
        nama: r.nama,
        nis: r.nis.isEmpty ? null : r.nis,
        nilaiList: [],
      );
    }).toList();

    await provider.importMuridBatch(widget.kelasId, newMuridList);

    setState(() => _saving = false);
    if (mounted) {
      AppFeedback.showSuccess(context, '${toImport.length} siswa berhasil diimport!');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final toImportCount = _preview
        .where((r) => !_existingNames.contains(r.nama.toLowerCase().trim()))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Column(
        children: [
          // ── Hero Header Scorify ──────────────────────────────────────────
          _buildHeroHeader(context),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Panduan Format Excel ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.table_view_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Format File Excel (.xlsx / .xls)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Kolom A = NIS  •  Kolom B = Nama Siswa\nBaris pertama (header) akan otomatis dilewati oleh sistem.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mini tabel contoh
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Table(
                            border: TableBorder.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                            },
                            children: [
                              _tableRow('NIS', 'Nama Siswa', isHeader: true),
                              _tableRow('12345', 'Andi Pratama'),
                              _tableRow('12346', 'Budi Santoso'),
                              _tableRow('12347', 'Citra Dewi'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Tombol Download Template Excel ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: const Icon(
                            Icons.file_download_rounded,
                            color: Color(0xFF059669),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Belum Punya Template?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Unduh format template Excel resmi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _downloadTemplate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            'Unduh',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Upload Box / Tombol Pilih File ───────────────────────
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _loading ? null : _pickFile,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _fileName != null
                              ? const Color(0xFFECFDF5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _fileName != null
                                ? const Color(0xFF10B981)
                                : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _fileName != null
                                    ? const Color(0xFFD1FAE5)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: _loading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _fileName != null
                                          ? Icons.task_alt_rounded
                                          : Icons.upload_file_rounded,
                                      color: _fileName != null
                                          ? const Color(0xFF059669)
                                          : AppColors.primary,
                                      size: 26,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _fileName != null
                                  ? _fileName!
                                  : 'Pilih File Excel (.xlsx / .xls)',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: _fileName != null
                                    ? const Color(0xFF047857)
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fileName != null
                                  ? 'Ketuk untuk mengganti file'
                                  : 'Maksimal 1 file per import',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Error Box ─────────────────────────────────────────────
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Preview Hasil Parse ──────────────────────────────────
                  if (_preview.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          'Preview Siswa',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_preview.length} ditemukan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (toImportCount < _preview.length)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              '${_namaDuplikat.length} sudah ada',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _preview.length,
                        separatorBuilder: (_, index) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (ctx, i) {
                          final row = _preview[i];
                          final isDuplikat = _existingNames.contains(
                            row.nama.toLowerCase().trim(),
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isDuplikat
                                        ? const Color(0xFFF1F5F9)
                                        : const Color(0xFFECFDF5),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    isDuplikat
                                        ? Icons.remove_circle_outline_rounded
                                        : Icons.person_add_rounded,
                                    size: 16,
                                    color: isDuplikat
                                        ? AppColors.textSecondary
                                        : const Color(0xFF059669),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // NIS Chip
                                if (row.nis.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      row.nis,
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    row.nama,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDuplikat
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                      decoration: isDuplikat
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (isDuplikat)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Sudah Ada',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom Action Import ─────────────────────────────────────────
          if (_preview.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (_saving || toImportCount == 0) ? null : _import,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_done_rounded, size: 20),
                    label: Text(
                      toImportCount == 0
                          ? 'Semua Siswa Sudah Ada di Kelas'
                          : 'Import $toImportCount Siswa ke Kelas',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Hero Header Widget ────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D252B),
            Color(0xFF163842),
            Color(0xFF1B4B5A),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 20),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Siswa via Excel',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kelas ${widget.kelas.nama}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(String col1, String col2, {bool isHeader = false}) {
    final style = GoogleFonts.robotoMono(
      fontSize: 11,
      fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal,
      color: isHeader ? AppColors.primary : AppColors.textPrimary,
    );
    return TableRow(
      decoration: isHeader
          ? BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
            )
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(col1, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(col2, style: style),
        ),
      ],
    );
  }
}
