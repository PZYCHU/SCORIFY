import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../tutorial_screen.dart';

/// Buka bottom sheet penilaian KBM untuk satu murid
void showInputNilaiSheet(
  BuildContext context, {
  required Kelas kelas,
  required Murid murid,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => InputNilaiSheet(kelas: kelas, murid: murid),
  );
}

class InputNilaiSheet extends StatefulWidget {
  final Kelas kelas;
  final Murid murid;

  const InputNilaiSheet({super.key, required this.kelas, required this.murid});

  @override
  State<InputNilaiSheet> createState() => _InputNilaiSheetState();
}

class _InputNilaiSheetState extends State<InputNilaiSheet> {
  // Nilai tersimpan saat ini di memory per kriteria (kriteriaId -> nilai)
  late Map<String, double> _nilaiMap;
  late AppProvider _provider;

  // Kriteria By Process (Presensi, Keaktifan)
  List<Kriteria> get _kriteriaPerforma => widget.kelas.kriteria
      .where((k) => k.jenis == JenisKriteria.byProcess)
      .toList();

  // Kriteria By Product (Tugas, Ujian)
  List<Kriteria> get _kriteriaHasil => widget.kelas.kriteria
      .where((k) => k.jenis == JenisKriteria.byProduct)
      .toList();

  void _showDialogInputNilaiHasil(
    Kriteria k,
    Sesi sesi,
    List<Nilai> existing,
  ) {
    final hasHistory = existing.isNotEmpty;
    final lastAttempt = hasHistory ? existing.first.attempt : 0;
    final lastScore = hasHistory ? existing.first.nilai : null;
    final nextAttempt = lastAttempt + 1;
    bool isKoreksi = false;

    final ctrl = TextEditingController(
      text: hasHistory
          ? (lastScore! % 1 == 0 ? '${lastScore.toInt()}' : '$lastScore')
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF2563EB), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${k.nama} - ${sesi.nama}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siswa: ${widget.murid.nama}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hasHistory) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text('Koreksi #$lastAttempt'),
                            selected: isKoreksi,
                            selectedColor: const Color(0xFFEFF6FF),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isKoreksi ? const Color(0xFF2563EB) : AppColors.textSecondary,
                            ),
                            onSelected: (val) {
                              setDialogState(() {
                                isKoreksi = true;
                                ctrl.text = lastScore! % 1 == 0 ? '${lastScore.toInt()}' : '$lastScore';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Text('Remedi #$nextAttempt'),
                            selected: !isKoreksi,
                            selectedColor: const Color(0xFFFEF3C7),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: !isKoreksi ? const Color(0xFFB45309) : AppColors.textSecondary,
                            ),
                            onSelected: (val) {
                              setDialogState(() {
                                isKoreksi = false;
                                ctrl.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: isKoreksi
                          ? 'Koreksi Nilai (0–100)'
                          : (hasHistory
                              ? 'Nilai Remedial Attempt #$nextAttempt (0–100)'
                              : 'Nilai Tugas (0–100)'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  final text = ctrl.text.trim().replaceAll(',', '.');
                  final val = double.tryParse(text);
                  if (val == null || val < 0 || val > 100) {
                    AppFeedback.showError(context, 'Masukkan nilai antara 0 - 100');
                    return;
                  }
                  Navigator.pop(ctx);
                  await _provider.inputNilaiHasil(
                    kelasId: widget.kelas.id,
                    muridId: widget.murid.id,
                    kriteriaId: k.id,
                    sesiId: sesi.id,
                    nilai: val,
                    isKoreksi: isKoreksi,
                  );
                  if (!mounted) return;
                  setState(() {});
                    AppFeedback.showSuccess(
                      context,
                      'Nilai ${sesi.nama} untuk ${widget.murid.nama} tersimpan: ${val % 1 == 0 ? val.toInt() : val}',
                    );
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductKriteriaItem(Kriteria k) {
    final sesiList = widget.kelas.getSesiByKriteria(k.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  k.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tugas / Ujian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sesiList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Belum ada sesi tugas dibuat untuk kriteria ini.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...sesiList.map((sesi) {
              final existing = widget.murid.nilaiList
                  .where((n) => n.kriteriaId == k.id && n.sesiId == sesi.id)
                  .toList()
                ..sort((a, b) => b.attempt.compareTo(a.attempt));

              final hasScore = existing.isNotEmpty;
              final lastScore = hasScore ? existing.first.nilai : null;
              final attempt = hasScore ? existing.first.attempt : 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasScore ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sesi.nama,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasScore
                                ? 'Nilai: ${lastScore! % 1 == 0 ? lastScore.toInt() : lastScore} (Attempt #$attempt)'
                                : 'Belum ada nilai',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: hasScore ? FontWeight.w700 : FontWeight.w500,
                              color: hasScore ? const Color(0xFF16A34A) : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasScore ? const Color(0xFFF1F5F9) : AppColors.primary,
                        foregroundColor: hasScore ? AppColors.textPrimary : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showDialogInputNilaiHasil(k, sesi, existing),
                      child: Text(
                        hasScore ? 'Ubah / Remedi' : 'Input Nilai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nilaiMap = {};
    _provider = context.read<AppProvider>();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    for (final k in _kriteriaPerforma) {
      final existing = widget.murid.getNilaiByKriteria(k.id);
      if (existing.isEmpty) {
        _nilaiMap[k.id] = 0;
        continue;
      }

      // Cari nilai hari ini
      final nilaiHariIni = existing.where((n) {
        final nStr = '${n.tanggal.year}-${n.tanggal.month}-${n.tanggal.day}';
        return nStr == todayStr;
      }).toList();

      final isCounter = k.inputType == InputType.counter ||
          k.nama.toLowerCase().contains('aktif');
      if (isCounter) {
        _nilaiMap[k.id] = existing.fold(0.0, (s, n) => s + n.nilai);
      } else {
        if (nilaiHariIni.isNotEmpty) {
          _nilaiMap[k.id] = nilaiHariIni.first.nilai;
        } else {
          existing.sort((a, b) => b.tanggal.compareTo(a.tanggal));
          _nilaiMap[k.id] = existing.first.nilai;
        }
      }
    }
  }

  Future<void> _simpanKriteria(String kriteriaId, double nilai) async {
    final kriteria = widget.kelas.kriteria.firstWhere((k) => k.id == kriteriaId);
    final isAttendance = kriteria.inputType == InputType.attendance ||
        kriteria.nama.toLowerCase().contains('hadir') ||
        kriteria.nama.toLowerCase().contains('presensi') ||
        kriteria.nama.toLowerCase().contains('absen');

    if (isAttendance) {
      final existing = widget.murid.getNilaiByKriteria(kriteriaId);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      final nilaiHariIni = existing.where((n) {
        final nStr = '${n.tanggal.year}-${n.tanggal.month}-${n.tanggal.day}';
        return nStr == todayStr;
      }).toList();

      if (nilaiHariIni.isNotEmpty) {
        final prevDate = nilaiHariIni.first.tanggal;
        final jam = prevDate.hour.toString().padLeft(2, '0');
        final mnt = prevDate.minute.toString().padLeft(2, '0');
        final prevVal = nilaiHariIni.first.nilai % 1 == 0
            ? nilaiHariIni.first.nilai.toInt()
            : nilaiHariIni.first.nilai;

        final confirm = await AppFeedback.showConfirmDialog(
          context,
          title: 'Konfirmasi Presensi',
          message:
              'Presensi ${widget.murid.nama} untuk hari ini sudah pernah dicatat pada pukul $jam:$mnt WIB (Nilai: $prevVal).\n\nApakah Anda yakin ingin memperbarui nilai presensi ini?',
          confirmText: 'Ya, Perbarui',
          cancelText: 'Batal',
        );
        if (!confirm) return;
      }
    }

    if (!mounted) return;
    setState(() {
      _nilaiMap[kriteriaId] = nilai;
    });
    await _provider.inputNilaiPerforma(
      kelasId: widget.kelas.id,
      muridId: widget.murid.id,
      kriteriaId: kriteriaId,
      nilai: nilai,
      tanggal: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle Bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header Info Siswa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.murid.nama.isNotEmpty
                          ? widget.murid.nama[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.murid.nama,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Penilaian KBM • Tersimpan otomatis per kriteria',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),

            // Panduan Pengisian Nilai
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gunakan Nilai Puluhan (0-100)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Input nilai berdasarkan skala 0-100. Contoh:\n100 = Sempurna/Sangat Bagus\n80 = Bagus\n75 = Cukup\nHindari menginput angka satuan (seperti 1, 5, 10).',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF14532D), height: 1.3),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TutorialScreen(initialCategoryIndex: 2),
                                ),
                              );
                            },
                            child: Text(
                              'Pelajari Kriteria Penilaian Lebih Lanjut',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF16A34A),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),            // List kriteria
            Expanded(
              child: (_kriteriaPerforma.isEmpty && _kriteriaHasil.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rule_folder_outlined,
                              size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'Tidak ada kriteria penilaian\ndi kelas ini',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        if (_kriteriaPerforma.isNotEmpty) ...[
                          if (_kriteriaHasil.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10, top: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Text(
                                      'NILAI PROSES (KBM HARIAN)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1D4ED8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ..._kriteriaPerforma
                              .map((k) => _buildKriteriaItem(k)),
                        ],
                        if (_kriteriaHasil.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: 10,
                              top: _kriteriaPerforma.isNotEmpty ? 12 : 4,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Text(
                                    'NILAI PRODUK (TUGAS / UJIAN)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF15803D),
                                      letterSpacing: 0.5,
                                ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ..._kriteriaHasil
                              .map((k) => _buildProductKriteriaItem(k)),
                        ],
                      ],
                    ),
            ),

            // ── Tombol Selesai / Tutup ──────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Selesai Menilai',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
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

  Widget _buildKriteriaItem(Kriteria k) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  k.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _inputTypeChip(k.inputType),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputWidget(k),
        ],
      ),
    );
  }

  Widget _buildInputWidget(Kriteria k) {
    final nilai = _nilaiMap[k.id] ?? 0;

    if (k.hasSubKriteria) {
      return _SubKriteriaSelectorWidget(
        kriteria: k,
        currentNilai: nilai,
        onSaveNilai: (nilaiBaru) async {
          await _simpanKriteria(k.id, nilaiBaru);
        },
      );
    }

    switch (k.inputType) {
      case InputType.counter:
        return _AccumulatorWidget(
          currentTotal: nilai,
          onSavePoin: (poinBaru) async {
            await _provider.tambahNilaiKeaktifan(
              kelasId: widget.kelas.id,
              muridId: widget.murid.id,
              kriteriaId: k.id,
              poin: poinBaru,
            );
            if (mounted) {
              setState(() {
                _nilaiMap[k.id] = (_nilaiMap[k.id] ?? 0) + poinBaru;
              });
            }
          },
        );

      case InputType.attendance:
        return _AttendanceWidget(
          currentNilai: nilai,
          onSaveNilai: (nilaiBaru) async {
            // Batasi nilai maksimum 100 untuk presensi
            final finalNilai = nilaiBaru > 100 ? 100.0 : nilaiBaru;
            await _simpanKriteria(k.id, finalNilai);
          },
        );

      case InputType.number:
        return _NumberWidget(
          initialValue: nilai,
          onSaveNilai: (nilaiBaru) async {
            await _simpanKriteria(k.id, nilaiBaru);
          },
        );

      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _inputTypeChip(InputType? t) {
    final label = switch (t) {
      InputType.counter => 'Nilai Kumulatif (+)',
      InputType.attendance => 'Presensi Harian',
      InputType.number => 'Nilai Sekali Catat',
      null => 'Penilaian',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Sub-Kriteria Selector Widget ─────────────────────────────────────────────

class _SubKriteriaSelectorWidget extends StatefulWidget {
  final Kriteria kriteria;
  final double currentNilai;
  final Future<void> Function(double nilai) onSaveNilai;

  const _SubKriteriaSelectorWidget({
    required this.kriteria,
    required this.currentNilai,
    required this.onSaveNilai,
  });

  @override
  State<_SubKriteriaSelectorWidget> createState() =>
      _SubKriteriaSelectorWidgetState();
}

class _SubKriteriaSelectorWidgetState extends State<_SubKriteriaSelectorWidget> {
  double? _selectedNilai;
  bool _isSaving = false;
  bool _showSuccess = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    if (widget.currentNilai > 0) {
      _selectedNilai = widget.currentNilai;
    }
  }

  @override
  void didUpdateWidget(covariant _SubKriteriaSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentNilai != widget.currentNilai) {
      _selectedNilai = widget.currentNilai > 0 ? widget.currentNilai : null;
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _pilihOpsi(double nilai) async {
    setState(() {
      _selectedNilai = nilai;
      _isSaving = true;
    });
    try {
      await widget.onSaveNilai(nilai);
      if (!mounted) return;
      setState(() {
        _showSuccess = true;
        _isSaving = false;
      });
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subList = widget.kriteria.subKriteria ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subList.map((sub) {
            final isSelected = _selectedNilai == sub.nilai;
            final valStr = sub.nilai % 1 == 0
                ? sub.nilai.toInt().toString()
                : sub.nilai.toString();
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving ? null : () => _pilihOpsi(sub.nilai),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sub.nama,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($valStr)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_isSaving) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Menyimpan...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ] else if (_showSuccess) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Nilai berhasil disimpan!',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Attendance Widget (Presensi dengan Preset) ───────────────────────────────

class _AttendanceWidget extends StatefulWidget {
  final double currentNilai;
  final Future<void> Function(double nilai) onSaveNilai;

  const _AttendanceWidget({
    required this.currentNilai,
    required this.onSaveNilai,
  });

  @override
  State<_AttendanceWidget> createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<_AttendanceWidget> {
  late TextEditingController _ctrl;
  bool _isSaving = false;
  bool _showSuccess = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.currentNilai > 0
          ? widget.currentNilai.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _simpan([double? overrideVal]) async {
    final val = overrideVal ?? double.tryParse(_ctrl.text.trim());
    if (val == null) return;

    if (overrideVal != null) {
      _ctrl.text = overrideVal.toStringAsFixed(0);
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSaveNilai(val);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _showSuccess = true;
        _isSaving = false;
      });
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _simpan(),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Ketik nilai kehadiran (cth: 100)',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _simpan(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
        if (_showSuccess) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF059669), size: 14),
              const SizedBox(width: 4),
              Text(
                'Presensi berhasil disimpan!',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Accumulator Widget (Poin Tambahan) ─────────────────────────────────────────

class _AccumulatorWidget extends StatefulWidget {
  final double currentTotal;
  final Future<void> Function(double poin) onSavePoin;

  const _AccumulatorWidget({
    required this.currentTotal,
    required this.onSavePoin,
  });

  @override
  State<_AccumulatorWidget> createState() => _AccumulatorWidgetState();
}

class _AccumulatorWidgetState extends State<_AccumulatorWidget> {
  final _poinCtrl = TextEditingController();
  bool _isSaving = false;
  bool _showSuccess = false;
  Timer? _successTimer;

  @override
  void dispose() {
    _poinCtrl.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _kirimPoin([double? presetPoin]) async {
    final poin = presetPoin ?? double.tryParse(_poinCtrl.text.trim());
    if (poin != null && poin > 0) {
      setState(() => _isSaving = true);
      try {
        await widget.onSavePoin(poin);
        if (!mounted) return;
        _poinCtrl.clear();
        FocusScope.of(context).unfocus();
        setState(() {
          _showSuccess = true;
          _isSaving = false;
        });
        _successTimer?.cancel();
        _successTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSuccess = false);
        });
      } catch (_) {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.currentTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tampilkan total poin terakumulasi
        if (total > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  'Total nilai terakumulasi: ${total.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _poinCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _kirimPoin(),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Tambah nilai (cth: 80)',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFD97706), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _kirimPoin(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      '+ Tambah',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
        if (_showSuccess) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF059669), size: 14),
              const SizedBox(width: 4),
              Text(
                'Nilai berhasil ditambahkan!',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Number Widget (Nilai Angka Langsung) ──────────────────────────────────────

class _NumberWidget extends StatefulWidget {
  final double initialValue;
  final Future<void> Function(double nilai) onSaveNilai;

  const _NumberWidget({
    required this.initialValue,
    required this.onSaveNilai,
  });

  @override
  State<_NumberWidget> createState() => _NumberWidgetState();
}

class _NumberWidgetState extends State<_NumberWidget> {
  late TextEditingController _ctrl;
  bool _isSaving = false;
  bool _showSuccess = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialValue > 0
          ? widget.initialValue.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _simpan([double? presetVal]) async {
    final val = presetVal ?? double.tryParse(_ctrl.text.trim());
    if (val == null) return;

    if (presetVal != null) {
      _ctrl.text = presetVal.toStringAsFixed(0);
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSaveNilai(val);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _showSuccess = true;
        _isSaving = false;
      });
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _simpan(),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Ketik nilai puluhan (cth: 75, 80)',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _simpan(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
        if (_showSuccess) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF059669), size: 14),
              const SizedBox(width: 4),
              Text(
                'Nilai berhasil disimpan!',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
