import 'package:flutter/material.dart';
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
    setState(() => _loading = true);
    try {
      final path = await ExcelService.downloadTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path != null
                  ? 'Template disimpan ke:\n$path'
                  : 'Gagal membuat template',
            ),
            backgroundColor:
                path != null ? AppColors.accent : AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${toImport.length} siswa berhasil diimport!'),
          backgroundColor: AppColors.accent,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final toImportCount = _preview
        .where((r) => !_existingNames.contains(r.nama.toLowerCase().trim()))
        .length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Siswa via Excel',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        Text(
                          widget.kelas.nama,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Panduan format ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.table_view_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Format File Excel (.xlsx)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Kolom A = NIS  •  Kolom B = Nama Siswa\n'
                            'Baris pertama (header) otomatis dilewati.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Mini tabel contoh
                          Table(
                            border: TableBorder.all(
                              color: AppColors.border,
                              width: 0.5,
                              borderRadius: BorderRadius.circular(6),
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
                          const SizedBox(height: 10),
                          // Tombol download template
                          TextButton.icon(
                            onPressed: _loading ? null : _downloadTemplate,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: AppColors.primary,
                            ),
                            icon: const Icon(
                              Icons.download_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Download Template Excel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Tombol pilih file ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _pickFile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file_outlined),
                        label: Text(
                          _fileName != null
                              ? _fileName!
                              : 'Pilih File Excel (.xlsx)',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    // ── Error ──────────────────────────────────────────────
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.costChip,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.danger,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.costChipText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Preview hasil parse ────────────────────────────────
                    if (_preview.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Preview — ${_preview.length} siswa ditemukan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (toImportCount < _preview.length)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.costChip,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_namaDuplikat.length} duplikat',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.costChipText,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _preview.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppColors.border,
                          ),
                          itemBuilder: (ctx, i) {
                            final row = _preview[i];
                            final isDuplikat = _existingNames.contains(
                              row.nama.toLowerCase().trim(),
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isDuplikat
                                        ? Icons.remove_circle_outline
                                        : Icons.person_add_outlined,
                                    size: 16,
                                    color: isDuplikat
                                        ? AppColors.textSecondary
                                        : AppColors.accent,
                                  ),
                                  const SizedBox(width: 10),
                                  // NIS chip (jika ada)
                                  if (row.nis.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        row.nis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      row.nama,
                                      style: TextStyle(
                                        fontSize: 13,
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
                                    const Text(
                                      'sudah ada',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
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

            // ── Bottom import button ───────────────────────────────────────
            if (_preview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_saving || toImportCount == 0) ? null : _import,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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
                        : const Icon(Icons.download_done_outlined),
                    label: Text(
                      toImportCount == 0
                          ? 'Semua sudah ada di kelas'
                          : 'Import $toImportCount Siswa',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  TableRow _tableRow(String col1, String col2, {bool isHeader = false}) {
    final style = TextStyle(
      fontSize: 11,
      fontFamily: 'monospace',
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(col1, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(col2, style: style),
        ),
      ],
    );
  }
}
