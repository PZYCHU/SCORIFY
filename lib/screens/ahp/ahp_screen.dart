import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('CR > 0.10 — perbandingan tidak konsisten. Silakan perbaiki.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final hasil = await context
        .read<AppProvider>()
        .simpanMatriksAHP(widget.kelasId, _matriks);
    setState(() => _saving = false);

    if (mounted && hasil != null && hasil.konsisten) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Bobot tersimpan! CR = ${hasil.cr.toStringAsFixed(4)} ✓'),
          backgroundColor: AppColors.accent,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInconsistency = _hasilPreview != null &&
        !_hasilPreview!.konsisten &&
        _hasilPreview!.saranList.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
            padding: const EdgeInsets.all(10), child: const AppBackButton()),
        title: const Text('Pembobotan AHP'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Penjelasan ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bandingkan kriteria secara berpasangan. Pilih kriteria yang lebih diutamakan, lalu tentukan tingkat keutamaannya.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // ── Header Perbandingan Berpasangan ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Perbandingan Berpasangan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                ),
                if (hasInconsistency) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.costChip,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.costChipText),
                        const SizedBox(width: 4),
                        Text(
                          'Saran perbaikan tersedia',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.costChipText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── Daftar Kartu Perbandingan ──
            _buildPairwiseCards(context),

            const SizedBox(height: 20),

            // ── Hasil Preview ──
            if (_hasilPreview != null) _buildHasilPreview(context),

            const SizedBox(height: 16),

            BottomSaveButton(
              label: 'Simpan Bobot',
              onPressed:
                  (_hasilPreview?.konsisten ?? false) ? _simpan : null,
              isLoading: _saving,
            ),
          ],
        ),
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
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                    Text(
                      'Pasangan $pairIndex dari $totalPairs',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                      ),
                    ),
                    const Spacer(),
                    if (isError)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Perlu Penyesuaian',
                          style: TextStyle(
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
                    // Kiri: Floating pill Kriteria A (Non-clickable, warna sama)
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

                    // Kanan: Floating pill Kriteria B (Non-clickable, warna sama)
                    Expanded(
                      flex: 3,
                      child: _buildFloatingPill(label: kriteriaB.nama),
                    ),
                  ],
                ),

                // Kalimat verbal pembacaan bersih tanpa kotak outline
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
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

                // Floating semi-transparent alert card in soft red (if inconsistency)
                if (isError) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                            Icons.lightbulb_outline_rounded,
                            size: 16,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saran Penyelarasan AHP',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                saran.nilaiSaran == 1
                                    ? 'Ubah perbandingan menjadi Sama Penting (1)'
                                    : 'Disarankan ubah ke Skala ${saran.nilaiSaran}',
                                style: const TextStyle(
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
                              style: const TextStyle(
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

  /// Floating pill untuk kriteria A / B (Anti-gravity aesthetic - badge visual seragam)
  Widget _buildFloatingPill({
    required String label,
  }) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Pale gray soft surface seragam untuk semua pill
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
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
        TextSpan(text: namaA, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        const TextSpan(text: ' sama pentingnya dengan '),
        TextSpan(text: namaB, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        const TextSpan(text: ' (Skala 1)', style: TextStyle(color: Colors.grey, fontSize: 11)),
      ];
    } else {
      final ket = _getDeskripsiKeutamaan(v);
      return [
        TextSpan(text: namaA, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: konsisten ? AppColors.benefitChip : AppColors.costChip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: konsisten
              ? AppColors.benefitChipText.withValues(alpha: 0.35)
              : AppColors.costChipText.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                konsisten ? Icons.check_circle : Icons.warning_amber_rounded,
                color: konsisten
                    ? AppColors.benefitChipText
                    : AppColors.costChipText,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  konsisten
                      ? 'Perbandingan Konsisten ✓'
                      : 'Perbandingan Tidak Konsisten ✗',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: konsisten
                        ? AppColors.benefitChipText
                        : AppColors.costChipText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ResultRow('λ maks', h.lambdaMax.toStringAsFixed(4)),
          _ResultRow('CI (Consistency Index)', h.ci.toStringAsFixed(4)),
          _ResultRow(
            'CR (Consistency Ratio)',
            '${h.cr.toStringAsFixed(4)} ${h.cr <= 0.10 ? "(≤ 0.10 ✓ Konsisten)" : "(> 0.10 ✗ Tidak Konsisten)"}',
          ),
          const Divider(height: 20),
          const Text(
            'Hasil Bobot Prioritas Kriteria:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_kriteria.length, (i) {
            final bobotPercent = (h.bobot[i] * 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _kriteria[i].nama,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${bobotPercent.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: h.bobot[i].clamp(0.0, 1.0),
                      backgroundColor: AppColors.border.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        konsisten ? AppColors.primary : AppColors.warningDark,
                      ),
                      minHeight: 6,
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

  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
