import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

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

  // Kriteria performa saja (bukan hasil & bukan derived)
  List<Kriteria> get _kriteriaPerforma => widget.kelas.kriteria
      .where((k) => k.jenis == JenisKriteria.performa)
      .toList();

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

      if (k.inputType == InputType.counter) {
        _nilaiMap[k.id] =
            nilaiHariIni.isNotEmpty ? nilaiHariIni.first.nilai : 0;
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

            // List kriteria
            Expanded(
              child: _kriteriaPerforma.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rule_folder_outlined,
                              size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'Tidak ada kriteria performa\ndi kelas ini',
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
                      children: _kriteriaPerforma
                          .map((k) => _buildKriteriaItem(k))
                          .toList(),
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

    switch (k.inputType) {
      case InputType.counter:
        return _AccumulatorWidget(
          currentTotal: nilai,
          onSavePoin: (poinBaru) async {
            final newTotal = nilai + poinBaru;
            await _simpanKriteria(k.id, newTotal);
          },
        );

      case InputType.attendance:
        return _AttendanceWidget(
          currentNilai: nilai,
          onSaveNilai: (nilaiBaru) async {
            await _simpanKriteria(k.id, nilaiBaru);
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
      InputType.counter => 'Poin Tambahan (+)',
      InputType.attendance => 'Presensi / Kehadiran',
      InputType.number => 'Nilai Angka',
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
                  hintText: 'Nilai kehadiran (misal 0–100 atau poin)',
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
        // Preset Poin Cepat
        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: [1, 2, 5, 10].map((val) {
            return InkWell(
              onTap: () => _kirimPoin(val.toDouble()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '+$val Poin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

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
                  'Total poin hari ini: ${total.toStringAsFixed(0)}',
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
                  hintText: 'Tambah poin custom (cth: 5)',
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
                'Poin berhasil ditambahkan!',
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
        // Quick presets
        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: [100, 90, 85, 80, 75].map((val) {
            final isSel = _ctrl.text == val.toString();
            return InkWell(
              onTap: () => _simpan(val.toDouble()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '$val',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSel ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
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
                  hintText: 'Ketik nilai (0–100)',
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
