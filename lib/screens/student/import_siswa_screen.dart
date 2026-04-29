import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Layar import siswa dari file CSV/Excel.
/// Format CSV yang diterima: satu kolom nama per baris.
/// Baris pertama boleh header (otomatis diabaikan jika bukan nama valid).
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
  List<String> _namaPreview = [];
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
      _namaPreview = [];
      _namaDuplikat = [];
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final file = File(result.files.single.path!);
      _fileName = result.files.single.name;
      final content = await file.readAsString();

      // Parse CSV
      final rows = const CsvToListConverter(eol: '\n').convert(content);

      final names = <String>[];
      for (final row in rows) {
        if (row.isEmpty) continue;
        final nama = row.first.toString().trim();
        if (nama.isEmpty) continue;

        // Skip baris header jika mengandung kata 'nama', 'no', 'siswa'
        final lower = nama.toLowerCase();
        if (lower == 'nama' ||
            lower == 'nama siswa' ||
            lower == 'no' ||
            lower == 'nama murid')
          continue;

        names.add(nama);
      }

      // Cek duplikat dengan existing
      final duplikat = names
          .where((n) => _existingNames.contains(n.toLowerCase().trim()))
          .toList();

      setState(() {
        _namaPreview = names;
        _namaDuplikat = duplikat;
      });
    } catch (e) {
      setState(() => _errorMsg = 'Gagal membaca file: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _import() async {
    if (_namaPreview.isEmpty) return;
    setState(() => _saving = true);

    final provider = context.read<AppProvider>();
    // Hanya import nama yang belum ada
    final toImport = _namaPreview
        .where((n) => !_existingNames.contains(n.toLowerCase().trim()))
        .toList();

    for (final nama in toImport) {
      await provider.tambahMurid(widget.kelasId, nama: nama, nilaiList: []);
    }

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
    final toImportCount = _namaPreview
        .where((n) => !_existingNames.contains(n.toLowerCase().trim()))
        .length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                          'Import Siswa via CSV',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
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
                    // Panduan format
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
                                Icons.description_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Format File CSV',
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
                            'Satu nama siswa per baris. Baris header '
                            '(Nama, No, dll) otomatis dilewati.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Nama Siswa\nAndi Pratama\nBudi Santoso\nCitra Dewi',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol pilih file
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
                          _fileName != null ? _fileName! : 'Pilih File CSV',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    // Error
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

                    // Preview hasil parse
                    if (_namaPreview.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Preview — ${_namaPreview.length} nama ditemukan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (toImportCount < _namaPreview.length)
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
                          itemCount: _namaPreview.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (ctx, i) {
                            final nama = _namaPreview[i];
                            final isDuplikat = _existingNames.contains(
                              nama.toLowerCase().trim(),
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
                                  Expanded(
                                    child: Text(
                                      nama,
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

            // Bottom import button
            if (_namaPreview.isNotEmpty)
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
}
