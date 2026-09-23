import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculate_service.dart';
import '../../widgets/app_widgets.dart';

class AhpScreen extends StatefulWidget {
  final String kelasId;

  const AhpScreen({super.key, required this.kelasId});

  @override
  State<AhpScreen> createState() => _AhpScreenState();
}

class _AhpScreenState extends State<AhpScreen> {
  late List<List<double>> _matriks;
  late List<Kriteria> _kriteria;
  HasilAHP? _hasilPreview;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final kelas = context.read<AppProvider>().getKelas(widget.kelasId)!;
    _kriteria = kelas.kriteria;
    // Pakai matriks yang sudah tersimpan atau buat baru
    _matriks = kelas.matriksAHP.isNotEmpty
        ? kelas.matriksAHP
            .map((row) => List<double>.from(row))
            .toList()
        : KalkulasiService.matriksAwal(_kriteria.length);
    _hitungPreview();
  }

  void _hitungPreview() {
    setState(() {
      _hasilPreview = KalkulasiService.hitungAHP(_matriks);
    });
  }

  void _updateNilai(int i, int j, double val) {
    KalkulasiService.setNilaiMatriks(_matriks, i, j, val);
    _hitungPreview();
  }

  Future<void> _simpan() async {
    if (_hasilPreview == null) return;
    if (!_hasilPreview!.konsisten) {
      AppFeedback.showError(
        context,
        'CR > 0.10 — perbandingan belum konsisten. Silakan ikuti saran perbaikan.',
      );
      return;
    }
    setState(() => _saving = true);
    final hasil = await context
        .read<AppProvider>()
        .simpanMatriksAHP(widget.kelasId, _matriks);
    setState(() => _saving = false);

    if (mounted && hasil != null && hasil.konsisten) {
      AppFeedback.showSuccess(
        context,
        'Bobot AHP tersimpan! CR = ${hasil.cr.toStringAsFixed(4)} (Konsisten)',
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildHeader(BuildContext context, Kelas? kelas) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D252B), Color(0xFF163842), Color(0xFF1B4B5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Ambient glowing orbs
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Frosted back button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
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
                              'Pembobotan AHP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              kelas?.nama ?? 'Penetapan Bobot Kriteria',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kelas = context.watch<AppProvider>().getKelas(widget.kelasId);
    final hasInconsistency = _hasilPreview != null &&
        !_hasilPreview!.konsisten &&
        _hasilPreview!.saranList.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, kelas),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Guidance Box ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panduan Matriks Perbandingan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Bandingkan kriteria secara berpasangan dengan Skala Saaty (1–9). Matriks harus konsisten (CR ≤ 0.10) agar bobot valid untuk perankingan SAW.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Header Perbandingan Berpasangan ──
                  Row(
                    children: [
                      Text(
                        'Perbandingan Berpasangan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      if (hasInconsistency)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_fix_high_rounded,
                                size: 13,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Saran Perbaikan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Daftar Kartu Perbandingan ──
                  _buildPairwiseCards(context),

                  const SizedBox(height: 20),

                  // ── Hasil Preview ──
                  if (_hasilPreview != null) _buildHasilPreview(context),

                  const SizedBox(height: 16),

                  BottomSaveButton(
                    label: 'Simpan Bobot AHP',
                    onPressed: (_hasilPreview?.konsisten ?? false) ? _simpan : null,
                    isLoading: _saving,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun daftar kartu perbandingan berpasangan berbentuk kalimat verbal & dropdown
  Widget _buildPairwiseCards(BuildContext context) {
    final n = _kriteria.length;
    final Map<String, SaranInkonsistensi> saranMap = {};
    if (_hasilPreview != null && !_hasilPreview!.konsisten) {
      for (final s in _hasilPreview!.saranList) {
        saranMap['${s.i}-${s.j}'] = s;
      }
    }

    final List<Widget> cardList = [];
    int pairIndex = 1;
    final totalPairs = (n * (n - 1)) ~/ 2;

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final val = _matriks[i][j];
        final saran = saranMap['$i-$j'];
        final isError = saran != null;

        final kriteriaA = _kriteria[i];
        final kriteriaB = _kriteria[j];

        final int scaleValue = val.round().clamp(1, 9);

        cardList.add(
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isError
                    ? AppColors.danger.withValues(alpha: 0.35)
                    : AppColors.border.withValues(alpha: 0.7),
                width: isError ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isError
                      ? AppColors.danger.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header kartu: Pasangan X dari Y & Indikator Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Pasangan $pairIndex dari $totalPairs',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isError)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Perlu Penyesuaian',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Baris horizontal 3 elemen: 2 floating pill seragam & 1 center dropdown (1-9)
                Row(
                  children: [
                    // Kiri: Floating pill Kriteria A
                    Expanded(
                      flex: 3,
                      child: _buildFloatingPill(label: kriteriaA.nama),
                    ),
                    const SizedBox(width: 8),

                    // Tengah: Minimalist borderless dropdown perbandingan 1-9
                    Expanded(
                      flex: 4,
                      child: _buildCenterDropdown(
                        scaleValue: scaleValue,
                        onChanged: (newScale) {
                          if (newScale == null) return;
                          _updateNilai(i, j, newScale.toDouble());
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Kanan: Floating pill Kriteria B
                    Expanded(
                      flex: 3,
                      child: _buildFloatingPill(label: kriteriaB.nama),
                    ),
                  ],
                ),

                // Kalimat verbal pembacaan
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        children: _buildKalimatVerbalSpan(
                          kriteriaA.nama,
                          kriteriaB.nama,
                          val,
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating alert card in soft red (if inconsistency)
                if (isError) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_fix_high_rounded,
                            size: 15,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saran Penyelarasan AHP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                saran.nilaiSaran == 1
                                    ? 'Ubah ke Sama Penting (1)'
                                    : 'Disarankan ubah ke Skala ${saran.nilaiSaran}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              _updateNilai(i, j, saran.nilaiSaran.toDouble()),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.danger.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Terapkan (${saran.nilaiSaran})',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        pairIndex++;
      }
    }

    return Column(children: cardList);
  }

  /// Floating pill untuk kriteria A / B
  Widget _buildFloatingPill({
    required String label,
  }) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Minimalist borderless dropdown resting on an elevated white surface (Skala 1-9)
  Widget _buildCenterDropdown({
    required int scaleValue,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: scaleValue,
          isExpanded: true,
          dropdownColor: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          items: const [
            DropdownMenuItem(
              value: 1,
              child: Text('Sama Penting (1)', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('Mendekati Sedikit (2)', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('Sedikit Lebih Penting (3)', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 4,
              child: Text('Mendekati Cukup (4)', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 5,
              child: Text('Cukup Lebih Penting (5)', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 6,
              child: Text('Mendekati Sangat (6)', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 7,
              child: Text('Sangat Lebih Penting (7)', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 8,
              child: Text('Mendekati Mutlak (8)', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 9,
              child: Text('Mutlak Lebih Penting (9)', overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Formatter kalimat verbal perbandingan (Kriteria A terhadap Kriteria B)
  List<InlineSpan> _buildKalimatVerbalSpan(String namaA, String namaB, double val) {
    final v = val.round().clamp(1, 9);
    if (v == 1) {
      return [
        TextSpan(
          text: namaA,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        const TextSpan(text: ' sama pentingnya dengan '),
        TextSpan(
          text: namaB,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        const TextSpan(text: ' (Skala 1)', style: TextStyle(color: Colors.grey, fontSize: 11)),
      ];
    } else {
      final ket = _getDeskripsiKeutamaan(v);
      return [
        TextSpan(
          text: namaA,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        TextSpan(text: ' $ket daripada '),
        TextSpan(text: namaB, style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: ' (Skala $v)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ];
    }
  }

  String _getDeskripsiKeutamaan(int v) {
    switch (v) {
      case 2:
        return 'antara sama & sedikit lebih penting';
      case 3:
        return 'sedikit lebih penting';
      case 4:
        return 'antara sedikit & cukup lebih penting';
      case 5:
        return 'cukup lebih penting';
      case 6:
        return 'antara cukup & sangat penting';
      case 7:
        return 'sangat lebih penting';
      case 8:
        return 'antara sangat & mutlak penting';
      case 9:
        return 'mutlak lebih penting';
      default:
        return 'sama penting';
    }
  }

  Widget _buildHasilPreview(BuildContext context) {
    final h = _hasilPreview!;
    final konsisten = h.konsisten;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: konsisten
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : AppColors.danger.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (konsisten ? const Color(0xFF10B981) : AppColors.danger).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                  color: (konsisten ? const Color(0xFF10B981) : AppColors.danger).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  konsisten ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: konsisten ? const Color(0xFF059669) : AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      konsisten ? 'Perbandingan Konsisten ✓' : 'Perbandingan Tidak Konsisten ✗',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: konsisten ? const Color(0xFF059669) : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      konsisten
                          ? 'Rasio konsistensi memenuhi syarat (CR ≤ 0.10)'
                          : 'CR > 0.10, gunakan saran penyesuaian di atas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Metric cards row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                _ResultRow('λ maks (Eigen Maksimum)', h.lambdaMax.toStringAsFixed(4)),
                const SizedBox(height: 8),
                _ResultRow('CI (Consistency Index)', h.ci.toStringAsFixed(4)),
                const SizedBox(height: 8),
                _ResultRow(
                  'CR (Consistency Ratio)',
                  '${h.cr.toStringAsFixed(4)} ${h.cr <= 0.10 ? "(≤ 0.10 ✓)" : "(> 0.10 ✗)"}',
                  isHighlight: true,
                  highlightColor: konsisten ? const Color(0xFF059669) : AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Hasil Bobot Prioritas Kriteria:',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_kriteria.length, (i) {
            final bobotPercent = (h.bobot[i] * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _kriteria[i].nama,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${bobotPercent.toStringAsFixed(2)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: h.bobot[i].clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        konsisten ? AppColors.primary : AppColors.warningDark,
                      ),
                      minHeight: 7,
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
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? highlightColor;

  const _ResultRow(
    this.label,
    this.value, {
    this.isHighlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
            fontSize: 12.5,
            color: isHighlight && highlightColor != null
                ? highlightColor
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
