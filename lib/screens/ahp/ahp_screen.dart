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

        // Tentukan mana yang dominan
        // val > 1.0 -> A lebih penting
        // val < 1.0 -> B lebih penting (skala = 1/val)
        // val == 1.0 -> Sama penting
        final int dominant; // 0: A, 1: Sama, 2: B
        final int scaleValue; // 1..9

        if (val > 1.0) {
          dominant = 0;
          scaleValue = val.round().clamp(1, 9);
        } else if (val < 1.0) {
          dominant = 2;
          scaleValue = (1 / val).round().clamp(1, 9);
        } else {
          dominant = 1;
          scaleValue = 1;
        }

        cardList.add(
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isError ? AppColors.costChip : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isError ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border,
                width: isError ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pasangan $pairIndex dari $totalPairs',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isError)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Perlu Penyesuaian',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Baris Pilihan Utama (Keutamaan)
                Text(
                  'Mana yang lebih diutamakan?',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Tombol Kriteria A
                    Expanded(
                      flex: 4,
                      child: _buildChoiceChip(
                        label: kriteriaA.nama,
                        isSelected: dominant == 0,
                        onTap: () {
                          final newScale = (dominant == 0 && scaleValue > 1) ? scaleValue : 3;
                          _updateNilai(i, j, newScale.toDouble());
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Tombol Sama Penting
                    Expanded(
                      flex: 3,
                      child: _buildChoiceChip(
                        label: 'Sama Penting',
                        isSelected: dominant == 1,
                        onTap: () {
                          _updateNilai(i, j, 1.0);
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Tombol Kriteria B
                    Expanded(
                      flex: 4,
                      child: _buildChoiceChip(
                        label: kriteriaB.nama,
                        isSelected: dominant == 2,
                        onTap: () {
                          final newScale = (dominant == 2 && scaleValue > 1) ? scaleValue : 3;
                          _updateNilai(i, j, 1.0 / newScale);
                        },
                      ),
                    ),
                  ],
                ),

                // Dropdown Tingkat Keutamaan (hanya muncul jika salah satu lebih diutamakan, atau pilih tingkat)
                if (dominant != 1) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Tingkat Keutamaan Verbal:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: scaleValue,
                        isExpanded: true,
                        alignment: Alignment.center,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Center(child: Text('1 - Sama pentingnya'))),
                          DropdownMenuItem(value: 2, child: Center(child: Text('2 - Antara sama & sedikit lebih penting'))),
                          DropdownMenuItem(value: 3, child: Center(child: Text('3 - Sedikit lebih penting'))),
                          DropdownMenuItem(value: 4, child: Center(child: Text('4 - Antara sedikit & cukup lebih penting'))),
                          DropdownMenuItem(value: 5, child: Center(child: Text('5 - Cukup lebih penting'))),
                          DropdownMenuItem(value: 6, child: Center(child: Text('6 - Antara cukup & sangat penting'))),
                          DropdownMenuItem(value: 7, child: Center(child: Text('7 - Sangat lebih penting'))),
                          DropdownMenuItem(value: 8, child: Center(child: Text('8 - Antara sangat & mutlak penting'))),
                          DropdownMenuItem(value: 9, child: Center(child: Text('9 - Mutlak lebih penting'))),
                        ],
                        onChanged: (newScale) {
                          if (newScale == null) return;
                          if (newScale == 1) {
                            _updateNilai(i, j, 1.0);
                          } else if (dominant == 0) {
                            _updateNilai(i, j, newScale.toDouble());
                          } else {
                            _updateNilai(i, j, 1.0 / newScale);
                          }
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Banner Kalimat Verbal Pembacaan
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
                      children: _buildKalimatVerbalSpan(kriteriaA.nama, kriteriaB.nama, val),
                    ),
                  ),
                ),

                // Saran Inkonsistensi (jika ada)
                if (isError) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb, size: 16, color: AppColors.warningDark),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Saran Penyelarasan AHP:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          saran.nilaiSaran == 1
                              ? 'Ubah perbandingan kedua kriteria menjadi "Sama penting" (Skala 1).'
                              : 'Disarankan ubah ${kriteriaA.nama} dibanding ${kriteriaB.nama} ke Skala ${saran.nilaiSaran}.',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => _updateNilai(i, j, saran.nilaiSaran.toDouble()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.warningDark,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Terapkan Skala ${saran.nilaiSaran}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
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

  /// Tombol pilihan chip keutamaan
  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// Formatter kalimat verbal perbandingan
  List<InlineSpan> _buildKalimatVerbalSpan(String namaA, String namaB, double val) {
    if (val == 1.0) {
      return [
        TextSpan(text: namaA, style: const TextStyle(fontWeight: FontWeight.w700)),
        const TextSpan(text: ' sama pentingnya dengan '),
        TextSpan(text: namaB, style: const TextStyle(fontWeight: FontWeight.w700)),
        const TextSpan(text: ' (Skala 1)', style: TextStyle(color: Colors.grey, fontSize: 11)),
      ];
    } else if (val > 1.0) {
      final v = val.round();
      final ket = _getDeskripsiKeutamaan(v);
      return [
        TextSpan(text: namaA, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        TextSpan(text: ' $ket daripada '),
        TextSpan(text: namaB, style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: ' (Skala $v)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ];
    } else {
      final v = (1 / val).round();
      final ket = _getDeskripsiKeutamaan(v);
      return [
        TextSpan(text: namaB, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        TextSpan(text: ' $ket daripada '),
        TextSpan(text: namaA, style: const TextStyle(fontWeight: FontWeight.w700)),
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
