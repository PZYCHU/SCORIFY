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
  // Nilai sementara di memory per kriteria (kriteriaId -> nilai)
  late Map<String, double> _nilaiMap;
  late AppProvider _provider;

  bool _isSaving = false;
  bool _isDirty = false; // ada perubahan yang belum disimpan

  // Debounce timer per kriteria (untuk background auto-save)
  final Map<String, Timer> _debounceTimers = {};

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
        // Counter: tampilkan nilai hari ini saja (bukan akumulasi semua hari)
        // Akumulasi antar hari dilakukan di SAW, bukan di UI
        _nilaiMap[k.id] = nilaiHariIni.isNotEmpty
            ? nilaiHariIni.first.nilai
            : 0;
      } else {
        // Toggle, number: tampilkan nilai hari ini jika ada,
        // kalau tidak tampilkan nilai terakhir yang tersimpan
        if (nilaiHariIni.isNotEmpty) {
          _nilaiMap[k.id] = nilaiHariIni.first.nilai;
        } else {
          existing.sort((a, b) => b.tanggal.compareTo(a.tanggal));
          _nilaiMap[k.id] = existing.first.nilai;
        }
      }
    }
  }

  @override
  void dispose() {
    // Flush semua pending debounce (fire-and-forget sebagai fallback)
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    // Jika masih ada perubahan belum tersimpan, coba simpan sekarang
    if (_isDirty) {
      for (final entry in _nilaiMap.entries) {
        _provider.inputNilaiPerforma(
          kelasId: widget.kelas.id,
          muridId: widget.murid.id,
          kriteriaId: entry.key,
          nilai: entry.value,
          tanggal: DateTime.now(),
        );
      }
    }
    super.dispose();
  }

  // Auto-save background (debounce) — hanya backup, bukan andalan utama
  void _autoSave(String kriteriaId, double nilai) {
    _debounceTimers[kriteriaId]?.cancel();
    _debounceTimers[kriteriaId] = Timer(
      const Duration(milliseconds: 1200),
      () => _simpanSatuKriteria(kriteriaId, nilai),
    );
  }

  Future<void> _simpanSatuKriteria(String kriteriaId, double nilai) async {
    await _provider.inputNilaiPerforma(
      kelasId: widget.kelas.id,
      muridId: widget.murid.id,
      kriteriaId: kriteriaId,
      nilai: nilai,
      tanggal: DateTime.now(),
    );
  }

  /// Simpan SEMUA kriteria sekaligus dan tutup sheet.
  Future<void> _simpanSemua() async {
    // Cancel semua debounce — kita simpan sekarang secara eksplisit
    for (final t in _debounceTimers.values) t.cancel();
    _debounceTimers.clear();

    setState(() => _isSaving = true);
    try {
      for (final entry in _nilaiMap.entries) {
        await _simpanSatuKriteria(entry.key, entry.value);
      }
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _updateNilai(String kriteriaId, double nilai) {
    setState(() {
      _nilaiMap[kriteriaId] = nilai;
      _isDirty = true;
    });
    // Background auto-save sebagai fallback
    _autoSave(kriteriaId, nilai);
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
                          'Penilaian KBM',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indikator
                  _SaveStatusIndicator(isDirty: _isDirty, isSaving: _isSaving),
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

            // ── Tombol Simpan Semua ──────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isSaving || _kriteriaPerforma.isEmpty)
                        ? null
                        : _simpanSemua,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDirty
                          ? AppColors.accent
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: _isDirty ? 4 : 0,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isDirty
                                ? Icons.save_outlined
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                    label: Text(
                      _isSaving
                          ? 'Menyimpan...'
                          : _isDirty
                              ? 'Simpan Semua Nilai'
                              : 'Selesai',
                      style: const TextStyle(
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
              _inputTypeIcon(k.inputType),
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
          onAddPoin: (poinBaru) => _updateNilai(k.id, nilai + poinBaru),
        );

      case InputType.number:
        return _NumberWidget(
          nilai: nilai,
          onChanged: (v) => _updateNilai(k.id, v),
        );

      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _inputTypeIcon(InputType? t) {
    final icon = switch (t) {
      InputType.counter => Icons.add_circle_outline,
      InputType.number => Icons.edit_outlined,
      null => Icons.auto_awesome_outlined,
    };
    return Icon(icon, size: 16, color: AppColors.textSecondary);
  }
}

// ─── Save Status Indicator ────────────────────────────────────────────────────

class _SaveStatusIndicator extends StatelessWidget {
  final bool isDirty;
  final bool isSaving;

  const _SaveStatusIndicator({required this.isDirty, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Menyimpan...',
            style: TextStyle(fontSize: 11, color: AppColors.accent),
          ),
        ],
      );
    }
    if (isDirty) {
      return Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.orange),
          const SizedBox(width: 5),
          Text(
            'Belum disimpan',
            style: TextStyle(fontSize: 11, color: Colors.orange[700]),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.cloud_done_outlined, size: 14, color: AppColors.accent),
        const SizedBox(width: 4),
        Text(
          'Tersimpan',
          style: TextStyle(fontSize: 11, color: AppColors.accent),
        ),
      ],
    );
  }
}

// ─── Accumulator Widget ─────────────────────────────────────────────────────────

class _AccumulatorWidget extends StatefulWidget {
  final ValueChanged<double> onAddPoin;

  const _AccumulatorWidget({required this.onAddPoin});

  @override
  State<_AccumulatorWidget> createState() => _AccumulatorWidgetState();
}

class _AccumulatorWidgetState extends State<_AccumulatorWidget> {
  final _poinCtrl = TextEditingController();
  bool _showSuccess = false;
  Timer? _successTimer;

  @override
  void dispose() {
    _poinCtrl.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  void _kirimPoin() {
    final input = _poinCtrl.text.trim();
    if (input.isEmpty) return;

    final poin = double.tryParse(input);
    if (poin != null) {
      widget.onAddPoin(poin);
      _poinCtrl.clear();

      setState(() => _showSuccess = true);
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSuccess = false);
      });
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
                controller: _poinCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '+ Tambah Poin (mis. 80)',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _kirimPoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Send', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (_showSuccess) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Poin tersimpan ke akumulasi!',
                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ],
    );
  }
}


// ─── Number Widget ────────────────────────────────────────────────────────────

class _NumberWidget extends StatefulWidget {
  final double nilai;
  final ValueChanged<double> onChanged;

  const _NumberWidget({required this.nilai, required this.onChanged});

  @override
  State<_NumberWidget> createState() => _NumberWidgetState();
}

class _NumberWidgetState extends State<_NumberWidget> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.nilai > 0 ? widget.nilai.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: 'Masukkan angka',
        suffixIcon: Icon(
          Icons.edit_outlined,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}


