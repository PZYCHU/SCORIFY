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
            // ── Panduan Skala ──
            _buildPanduanSkala(context),

            const SizedBox(height: 20),

            // ── Matriks ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Matriks Perbandingan Berpasangan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasInconsistency) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Saran tersedia',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildMatriks(context),

            const SizedBox(height: 20),

            // ── Makna Perbandingan Verbal ──
            _buildPenjelasanVerbal(context),

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
    final Map<String, SaranInkonsistensi> saranMap = {};
    if (_hasilPreview != null && !_hasilPreview!.konsisten) {
      for (final s in _hasilPreview!.saranList) {
        saranMap['${s.i}-${s.j}'] = s;
      }
    }

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
                    isHeader: true, width: 90, height: 60,
                    child: const SizedBox()),
                ...List.generate(
                  n,
                  (j) => _MatriksCell(
                    isHeader: true,
                    height: 60,
                    width: 74,
                    child: Text(
                      _kriteria[j].nama,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                        isHeader: true,
                        width: 90,
                        height: 60,
                        child: Text(
                          _kriteria[i].nama,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Nilai
                      ...List.generate(n, (j) {
                        if (i == j) {
                          // Diagonal = 1
                          return _MatriksCell(
                            isDiagonal: true,
                            height: 60,
                            width: 74,
                            child: const Text('1',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary),
                                textAlign: TextAlign.center),
                          );
                        }
                        if (i > j) {
                          // Bawah diagonal = resiprokal (tampilkan saja)
                          final val = _matriks[i][j];
                          return _MatriksCell(
                            isReciprocal: true,
                            height: 60,
                            width: 74,
                            child: Text(
                              val < 1
                                  ? '1/${(1 / val).round()}'
                                  : val.round().toString(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        // Atas diagonal = input
                        final saran = saranMap['$i-$j'];
                        return _MatriksInputCell(
                          key: ValueKey('cell_${i}_${j}_${_matriks[i][j]}'),
                          value: _matriks[i][j],
                          saran: saran,
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

  Widget _buildPenjelasanVerbal(BuildContext context) {
    final n = _kriteria.length;
    final Map<String, SaranInkonsistensi> saranMap = {};
    if (_hasilPreview != null && !_hasilPreview!.konsisten) {
      for (final s in _hasilPreview!.saranList) {
        saranMap['${s.i}-${s.j}'] = s;
      }
    }

    final List<Widget> items = [];
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final val = _matriks[i][j];
        final saran = saranMap['$i-$j'];
        final isError = saran != null;

        items.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade50 : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isError ? Colors.red.shade300 : AppColors.border,
                width: isError ? 1.2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    isError ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: isError ? Colors.red.shade700 : Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                          children: _buildDeskripsiSpan(_kriteria[i].nama, _kriteria[j].nama, val),
                        ),
                      ),
                      if (isError) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '⚠️ Tidak selaras. Disarankan: ${saran.nilaiSaran}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _updateNilai(i, j, saran.nilaiSaran.toDouble()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Terapkan: ${saran.nilaiSaran}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Penjelasan Perbandingan Kriteria',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Rincian arti nilai perbandingan yang sedang Anda tentukan:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  List<InlineSpan> _buildDeskripsiSpan(String namaA, String namaB, double val) {
    final v = val.round();
    final String hubungan;
    if (v == 1) {
      hubungan = ' sama penting dengan ';
    } else if (v == 2) {
      hubungan = ' antara sama penting & sedikit lebih penting dibanding ';
    } else if (v == 3) {
      hubungan = ' sedikit lebih penting dibanding ';
    } else if (v == 4) {
      hubungan = ' antara sedikit lebih penting & cukup penting dibanding ';
    } else if (v == 5) {
      hubungan = ' cukup lebih penting dibanding ';
    } else if (v == 6) {
      hubungan = ' antara cukup penting & sangat penting dibanding ';
    } else if (v == 7) {
      hubungan = ' sangat lebih penting dibanding ';
    } else if (v == 8) {
      hubungan = ' antara sangat penting & mutlak penting dibanding ';
    } else {
      hubungan = ' mutlak lebih penting dibanding ';
    }

    return [
      TextSpan(text: namaA, style: const TextStyle(fontWeight: FontWeight.w700)),
      TextSpan(text: hubungan),
      TextSpan(text: namaB, style: const TextStyle(fontWeight: FontWeight.w700)),
      TextSpan(text: ' (Skala $v)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ];
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
              ? AppColors.benefitChipText.withValues(alpha: 0.3)
              : AppColors.costChipText.withValues(alpha: 0.3),
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
  final double height;

  const _MatriksCell({
    required this.child,
    this.isHeader = false,
    this.isDiagonal = false,
    this.isReciprocal = false,
    this.width = 74,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDiagonal
            ? AppColors.background
            : isHeader
                ? AppColors.primary.withValues(alpha: 0.05)
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
  final SaranInkonsistensi? saran;
  final ValueChanged<double> onChanged;

  const _MatriksInputCell({
    super.key,
    required this.value,
    this.saran,
    required this.onChanged,
  });

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
  void didUpdateWidget(covariant _MatriksInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.text = widget.value == 1.0 ? '1' : widget.value.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSaran = widget.saran != null;

    return Container(
      width: 74,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: hasSaran ? Colors.red.shade50 : AppColors.surfaceWhite,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 32,
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: hasSaran ? Colors.red.shade900 : AppColors.primary,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: hasSaran ? Colors.red.shade400 : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: hasSaran ? Colors.red.shade400 : AppColors.border,
                    width: hasSaran ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: hasSaran ? Colors.red.shade700 : AppColors.primary,
                    width: 2.0,
                  ),
                ),
                fillColor: hasSaran ? Colors.red.shade50 : AppColors.surfaceWhite,
                filled: true,
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed >= 1 && parsed <= 9) {
                  widget.onChanged(parsed.toDouble());
                }
              },
            ),
          ),
          if (hasSaran)
            GestureDetector(
              onTap: () {
                final s = widget.saran!.nilaiSaran;
                _ctrl.text = '$s';
                widget.onChanged(s.toDouble());
              },
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '💡 Coba:${widget.saran!.nilaiSaran}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
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
