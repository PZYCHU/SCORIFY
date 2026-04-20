import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Isi seberapa penting kriteria di baris dibanding kriteria di kolom. Gunakan skala 1–9.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Matriks ──
            Text('Matriks Perbandingan Berpasangan',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildMatriks(context),

            const SizedBox(height: 20),

            // ── Panduan Skala ──
            _buildPanduanSkala(context),

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

  Widget _buildMatriks(BuildContext context) {
    final n = _kriteria.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Header baris
            Row(
              children: [
                _MatriksCell(
                    child: const SizedBox(), isHeader: true, width: 90),
                ...List.generate(
                  n,
                  (j) => _MatriksCell(
                    child: Text(
                      _kriteria[j].nama,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isHeader: true,
                  ),
                ),
              ],
            ),
            const Divider(height: 1, color: AppColors.border),

            // Data rows
            ...List.generate(n, (i) {
              return Column(
                children: [
                  Row(
                    children: [
                      // Nama kriteria (kolom pertama)
                      _MatriksCell(
                        child: Text(
                          _kriteria[i].nama,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        isHeader: true,
                        width: 90,
                      ),
                      // Nilai
                      ...List.generate(n, (j) {
                        if (i == j) {
                          // Diagonal = 1
                          return _MatriksCell(
                            child: const Text('1',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary),
                                textAlign: TextAlign.center),
                            isDiagonal: true,
                          );
                        }
                        if (i > j) {
                          // Bawah diagonal = resiprokal (tampilkan saja)
                          final val = _matriks[i][j];
                          return _MatriksCell(
                            child: Text(
                              val < 1
                                  ? '1/${(1 / val).round()}'
                                  : val.round().toString(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            isReciprocal: true,
                          );
                        }
                        // Atas diagonal = input
                        return _MatriksInputCell(
                          value: _matriks[i][j],
                          onChanged: (val) => _updateNilai(i, j, val),
                        );
                      }),
                    ],
                  ),
                  if (i < n - 1) const Divider(height: 1, color: AppColors.border),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPanduanSkala(BuildContext context) {
    final skala = [1, 3, 5, 7, 9];
    final label = [
      'Sama penting',
      'Sedikit lebih penting',
      'Cukup lebih penting',
      'Sangat lebih penting',
      'Mutlak lebih penting',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Panduan Skala Saaty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          ...List.generate(
            skala.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${skala[i]}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(label[i],
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHasilPreview(BuildContext context) {
    final h = _hasilPreview!;
    final konsisten = h.konsisten;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: konsisten
            ? AppColors.benefitChip
            : AppColors.costChip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: konsisten
              ? AppColors.benefitChipText.withOpacity(0.3)
              : AppColors.costChipText.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                konsisten ? Icons.check_circle : Icons.warning_amber,
                color: konsisten
                    ? AppColors.benefitChipText
                    : AppColors.costChipText,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                konsisten ? 'Konsisten ✓' : 'Tidak Konsisten ✗',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: konsisten
                      ? AppColors.benefitChipText
                      : AppColors.costChipText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ResultRow('λ max', h.lambdaMax.toStringAsFixed(4)),
          _ResultRow('CI', h.ci.toStringAsFixed(4)),
          _ResultRow('CR', '${h.cr.toStringAsFixed(4)} ${h.cr <= 0.10 ? "≤ 0.10 ✓" : "> 0.10 ✗"}'),
          const Divider(height: 16),
          Text('Bobot Kriteria:',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          ...List.generate(_kriteria.length, (i) {
            return _ResultRow(
              _kriteria[i].nama,
              '${(h.bobot[i] * 100).toStringAsFixed(2)}%',
            );
          }),
        ],
      ),
    );
  }
}

// ─── Sel header / diagonal / resiprokal ──────────────────────────────────────

class _MatriksCell extends StatelessWidget {
  final Widget child;
  final bool isHeader;
  final bool isDiagonal;
  final bool isReciprocal;
  final double width;

  const _MatriksCell({
    required this.child,
    this.isHeader = false,
    this.isDiagonal = false,
    this.isReciprocal = false,
    this.width = 68,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDiagonal
            ? AppColors.background
            : isHeader
                ? AppColors.primary.withOpacity(0.05)
                : isReciprocal
                    ? AppColors.background
                    : AppColors.surfaceWhite,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

// ─── Sel input (atas diagonal) ────────────────────────────────────────────────

class _MatriksInputCell extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _MatriksInputCell({required this.value, required this.onChanged});

  @override
  State<_MatriksInputCell> createState() => _MatriksInputCellState();
}

class _MatriksInputCellState extends State<_MatriksInputCell> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value == 1.0 ? '1' : widget.value.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: TextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          fillColor: AppColors.surfaceWhite,
          filled: true,
        ),
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null && parsed >= 1 && parsed <= 9) {
            widget.onChanged(parsed.toDouble());
          }
        },
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
