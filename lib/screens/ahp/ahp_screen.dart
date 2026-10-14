import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculate_service.dart';
import '../../widgets/app_widgets.dart';
import '../tutorial_screen.dart';

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
                              'Konfigurasi Parameter Penilaian',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              kelas?.nama ?? 'Penetapan Bobot & Parameter Kriteria',
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
                                'Panduan Pengisian AHP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Geser slider ke arah kriteria yang lebih Anda prioritaskan, atau ketuk langsung angka skala Saaty (1–9). Titik tengah (1) berarti kedua kriteria seimbang. Pastikan perbandingan konsisten (CR ≤ 0.10).',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  height: 1.45,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TutorialScreen(initialCategoryIndex: 3),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Pelajari Skenario & Kiat Pembobotan di Panduan Lengkap',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
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

                  const SizedBox(height: 20),

                  // ── Header Perbandingan Berpasangan ──
                  Row(
                    children: [
                      Text(
                        'Perbandingan Berpasangan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
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
                                size: 14,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Saran Perbaikan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
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

                  // ── Referensi Skala Saaty ──
                  _buildSaatyLegend(),

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

  /// Widget legenda visual skala fundamental Saaty (1, 3, 5, 7, 9)
  Widget _buildSaatyLegend() {
    const scales = [
      (val: '1', label: 'Seimbang'),
      (val: '3', label: 'Agak Lebih'),
      (val: '5', label: 'Jelas Lebih'),
      (val: '7', label: 'Jauh Lebih'),
      (val: '9', label: 'Mutlak'),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
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
              const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Referensi Skala Saaty AHP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: scales.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.val,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Konversi nilai matriks AHP (0.111 s.d. 9.0) ke posisi slider (-8.0 s.d. 8.0)
  /// Negatif = condong ke Kriteria A, Positif = condong ke Kriteria B, 0 = seimbang (1)
  double _matriksToSliderValue(double val) {
    if (val >= 0.95 && val <= 1.05) {
      return 0.0;
    } else if (val > 1.05) {
      final int scale = val.round().clamp(1, 9);
      return -(scale - 1).toDouble();
    } else {
      final int scale = (1.0 / val).round().clamp(1, 9);
      return (scale - 1).toDouble();
    }
  }

  /// Konversi posisi slider (-8.0 s.d. 8.0) ke nilai perbandingan matriks AHP
  double _sliderValueToMatriks(double sliderVal) {
    final int rounded = sliderVal.round().clamp(-8, 8);
    if (rounded == 0) {
      return 1.0;
    } else if (rounded < 0) {
      // Ke kiri = Kriteria A lebih dominan (skala 2 s.d. 9)
      final int scale = 1 + (-rounded);
      return scale.toDouble();
    } else {
      // Ke kanan = Kriteria B lebih dominan (skala 1/2 s.d. 1/9)
      final int scale = 1 + rounded;
      return 1.0 / scale;
    }
  }

  /// Membangun daftar kartu perbandingan berpasangan menggunakan Slider Bidirectional Saaty
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

    const tickMarks = [
      (val: -8.0, label: '9'),
      (val: -6.0, label: '7'),
      (val: -4.0, label: '5'),
      (val: -2.0, label: '3'),
      (val: 0.0, label: '1'),
      (val: 2.0, label: '3'),
      (val: 4.0, label: '5'),
      (val: 6.0, label: '7'),
      (val: 8.0, label: '9'),
    ];

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final val = _matriks[i][j];
        final saran = saranMap['$i-$j'];
        final isError = saran != null;

        final kriteriaA = _kriteria[i];
        final kriteriaB = _kriteria[j];

        final double currentSliderVal = _matriksToSliderValue(val);
        final bool isADominant = currentSliderVal < -0.5;
        final bool isBDominant = currentSliderVal > 0.5;

        cardList.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Pasangan X dari Y & Badge Inkonsistensi
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Pasangan $pairIndex dari $totalPairs',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isError)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                            const SizedBox(width: 4),
                            Text(
                              'Perlu Penyesuaian',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
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

                // Nama Kriteria Kiri (A) dan Kanan (B)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kriteria A
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (currentSliderVal >= 0) {
                            _updateNilai(i, j, _sliderValueToMatriks(-2.0));
                          }
                        },
                        child: Row(
                          children: [
                            if (isADominant) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                kriteriaA.nama,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: isADominant ? FontWeight.w800 : FontWeight.w600,
                                  color: isADominant ? AppColors.primary : AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Kriteria B
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (currentSliderVal <= 0) {
                            _updateNilai(i, j, _sliderValueToMatriks(2.0));
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                kriteriaB.nama,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: isBDominant ? FontWeight.w800 : FontWeight.w600,
                                  color: isBDominant ? AppColors.primary : AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isBDominant) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bidirectional Slider dengan Tombol Panah Presisi
                Row(
                  children: [
                    // Tombol Panah Kiri (Geser ke Kriteria A)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: currentSliderVal > -8.0
                            ? () {
                                final nextVal = (currentSliderVal - 1.0).clamp(-8.0, 8.0);
                                _updateNilai(i, j, _sliderValueToMatriks(nextVal));
                              }
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: currentSliderVal > -8.0
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: currentSliderVal > -8.0
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 22,
                            color: currentSliderVal > -8.0
                                ? AppColors.primary
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Slider Track
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackShape: const BiDirectionalSliderTrackShape(),
                          trackHeight: 6.0,
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: const Color(0xFFE2E8F0),
                          thumbColor: AppColors.primary,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 9.0,
                            elevation: 2.0,
                          ),
                          overlayColor: AppColors.primary.withValues(alpha: 0.12),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
                        ),
                        child: Slider(
                          value: currentSliderVal.clamp(-8.0, 8.0),
                          min: -8.0,
                          max: 8.0,
                          divisions: 16,
                          onChanged: (newSliderVal) {
                            _updateNilai(i, j, _sliderValueToMatriks(newSliderVal));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Tombol Panah Kanan (Geser ke Kriteria B)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: currentSliderVal < 8.0
                            ? () {
                                final nextVal = (currentSliderVal + 1.0).clamp(-8.0, 8.0);
                                _updateNilai(i, j, _sliderValueToMatriks(nextVal));
                              }
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: currentSliderVal < 8.0
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: currentSliderVal < 8.0
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: currentSliderVal < 8.0
                                ? AppColors.primary
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Baris Angka Skala Saaty (9 7 5 3 1 3 5 7 9)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 46),
                  child: Row(
                    children: tickMarks.map((t) {
                      final bool isThisTickActive = (currentSliderVal - t.val).abs() < 0.6;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _updateNilai(i, j, _sliderValueToMatriks(t.val));
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.label,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isThisTickActive ? 14 : 12,
                                  fontWeight: isThisTickActive ? FontWeight.w800 : FontWeight.w600,
                                  color: isThisTickActive
                                      ? (t.val == 0.0 ? AppColors.textPrimary : AppColors.primary)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: isThisTickActive ? 5 : 3,
                                height: isThisTickActive ? 5 : 3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isThisTickActive
                                      ? (t.val == 0.0 ? AppColors.textPrimary : AppColors.primary)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Kalimat verbal pembacaan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                          height: 1.45,
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

                // Alert Saran Penyelarasan Otomatis
                if (isError) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
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
                                'Saran Penyelarasan Bobot',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                saran.nilaiSaran == 1
                                    ? 'Agar penilaian selaras, sistem menyarankan: Keduanya sama pentingnya'
                                    : 'Agar penilaian selaras, sistem menyarankan: ${(saran.lebihPentingA ? kriteriaA.nama : kriteriaB.nama)} ${_getDeskripsiKeutamaan(saran.nilaiSaran)} daripada ${(saran.lebihPentingA ? kriteriaB.nama : kriteriaA.nama)} (${saran.nilaiSaran})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF7F1D1D),
                                  height: 1.38,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            final targetVal = saran.lebihPentingA
                                ? saran.nilaiSaran.toDouble()
                                : (1.0 / saran.nilaiSaran);
                            _updateNilai(i, j, targetVal);
                            final kDominan = saran.lebihPentingA ? kriteriaA.nama : kriteriaB.nama;
                            final kLawan = saran.lebihPentingA ? kriteriaB.nama : kriteriaA.nama;
                            AppFeedback.showSuccess(
                              context,
                              saran.nilaiSaran == 1
                                  ? 'Saran diterapkan: Keduanya sama pentingnya'
                                  : 'Saran diterapkan: $kDominan ${_getDeskripsiKeutamaan(saran.nilaiSaran)} daripada $kLawan (${saran.nilaiSaran})',
                            );
                          },
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
                              'Terapkan Saran',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
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

  /// Formatter kalimat verbal perbandingan dengan indikator angka intensitas Saaty
  List<InlineSpan> _buildKalimatVerbalSpan(String namaA, String namaB, double val) {
    if (val >= 0.95 && val <= 1.05) {
      return [
        TextSpan(
          text: namaA,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const TextSpan(text: ' sama pentingnya dengan '),
        TextSpan(
          text: namaB,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const TextSpan(
          text: ' (1)',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary),
        ),
      ];
    } else if (val > 1.05) {
      final v = val.round().clamp(1, 9);
      final ket = _getDeskripsiKeutamaan(v);
      return [
        TextSpan(
          text: namaA,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        TextSpan(text: ' $ket daripada '),
        TextSpan(
          text: namaB,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        TextSpan(
          text: ' ($v)',
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
      ];
    } else {
      final v = (1.0 / val).round().clamp(1, 9);
      final ket = _getDeskripsiKeutamaan(v);
      return [
        TextSpan(
          text: namaB,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        TextSpan(text: ' $ket daripada '),
        TextSpan(
          text: namaA,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        TextSpan(
          text: ' ($v)',
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
      ];
    }
  }

  String _getDeskripsiKeutamaan(int v) {
    switch (v) {
      case 1:
        return 'sama pentingnya dengan';
      case 2:
        return 'sedikit lebih penting';
      case 3:
        return 'cukup lebih penting';
      case 4:
        return 'lebih penting';
      case 5:
        return 'jauh lebih penting';
      case 6:
        return 'sangat lebih penting';
      case 7:
        return 'sangat jauh lebih penting';
      case 8:
        return 'hampir mutlak lebih penting';
      case 9:
        return 'mutlak paling penting';
      default:
        return 'lebih penting';
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
                        fontSize: 16,
                        color: konsisten ? const Color(0xFF059669) : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      konsisten
                          ? 'Rasio konsistensi memenuhi syarat (CR ≤ 0.10)'
                          : 'CR > 0.10, gunakan saran penyesuaian di atas',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
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
              fontSize: 15,
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
                            fontSize: 14.5,
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
                            fontSize: 13.5,
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
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
            fontSize: 13.5,
            color: isHighlight && highlightColor != null
                ? highlightColor
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Track slider bidirectional kustom yang menggambar highlight dari posisi tengah (0) ke jempol
class BiDirectionalSliderTrackShape extends RoundedRectSliderTrackShape {
  const BiDirectionalSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? const Color(0xFFE2E8F0);
    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? AppColors.primary;
    final Paint centerMarkPaint = Paint()
      ..color = const Color(0xFF64748B);

    final double trackRadius = trackRect.height / 2;

    // 1. Gambar latar track netral
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(trackRadius)),
      inactivePaint,
    );

    // 2. Gambar track aktif yang melebar dari pusat (0) ke arah posisi jempol
    final double centerX = trackRect.center.dx;
    final double thumbX = thumbCenter.dx;

    if ((thumbX - centerX).abs() > 1.0) {
      final double left = thumbX < centerX ? thumbX : centerX;
      final double right = thumbX > centerX ? thumbX : centerX;
      final Rect activeRect = Rect.fromLTRB(left, trackRect.top, right, trackRect.bottom);
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, Radius.circular(trackRadius)),
        activePaint,
      );
    }

    // 3. Gambar penanda garis tengah (Skala 1 = Seimbang)
    final Rect centerMarkRect = Rect.fromCenter(
      center: Offset(centerX, trackRect.center.dy),
      width: 3.5,
      height: trackRect.height + 6,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(centerMarkRect, const Radius.circular(2)),
      centerMarkPaint,
    );
  }
}

