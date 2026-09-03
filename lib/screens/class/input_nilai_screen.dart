import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

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
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.murid.nama,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Penilaian KBM (Tersimpan otomatis per kriteria)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // List kriteria
            Expanded(
              child: _kriteriaPerforma.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada kriteria performa\ndi kelas ini',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Selesai Menilai',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  k.nama,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _inputTypeChip(k.inputType),
            ],
          ),
          const SizedBox(height: 14),
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
      InputType.number => 'Nilai Angka',
      null => 'Penilaian',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
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

  Future<void> _kirimPoin() async {
    final input = _poinCtrl.text.trim();
    if (input.isEmpty) return;

    final poin = double.tryParse(input);
    if (poin != null && poin > 0) {
      setState(() => _isSaving = true);
      try {
        await widget.onSavePoin(poin);
        _poinCtrl.clear();
        FocusScope.of(context).unfocus();
        if (mounted) {
          setState(() {
            _showSuccess = true;
            _isSaving = false;
          });
          _successTimer?.cancel();
          _successTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showSuccess = false);
          });
        }
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
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.functions, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Total nilai hari ini: ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
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
                decoration: InputDecoration(
                  hintText: 'Tambah poin (mis. 10 atau 80)',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _kirimPoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, size: 18),
              label: Text(
                _isSaving ? '...' : 'Tambah',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (_showSuccess) ...[
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 14),
              SizedBox(width: 4),
              Text(
                'Poin berhasil ditambahkan & tersimpan!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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

  Future<void> _simpan() async {
    final val = double.tryParse(_ctrl.text.trim());
    if (val == null) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSaveNilai(val);
      FocusScope.of(context).unfocus();
      if (mounted) {
        setState(() {
          _showSuccess = true;
          _isSaving = false;
        });
        _successTimer?.cancel();
        _successTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSuccess = false);
        });
      }
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
                decoration: InputDecoration(
                  hintText: 'Masukkan nilai (0–100)',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(
                _isSaving ? '...' : 'Simpan',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (_showSuccess) ...[
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 14),
              SizedBox(width: 4),
              Text(
                'Nilai berhasil disimpan!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
