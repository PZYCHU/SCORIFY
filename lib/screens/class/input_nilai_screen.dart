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

  // Debounce timer per kriteria
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
        // Toggle, stopwatch, number: tampilkan nilai hari ini jika ada,
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
    for (final t in _debounceTimers.values) t.cancel();
    super.dispose();
  }

  // Auto-save dengan debounce 800ms
  void _autoSave(String kriteriaId, double nilai) {
    _debounceTimers[kriteriaId]?.cancel();
    _debounceTimers[kriteriaId] = Timer(
      const Duration(milliseconds: 800),
      () => _simpanNilai(kriteriaId, nilai),
    );
  }

  Future<void> _simpanNilai(String kriteriaId, double nilai) async {
    await _provider.inputNilaiPerforma(
      kelasId: widget.kelas.id,
      muridId: widget.murid.id,
      kriteriaId: kriteriaId,
      nilai: nilai,
      tanggal: DateTime.now(),
    );
  }

  void _updateNilai(String kriteriaId, double nilai) {
    setState(() => _nilaiMap[kriteriaId] = nilai);
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
                  // Indikator auto-save
                  _AutoSaveIndicator(),
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      children: _kriteriaPerforma
                          .map((k) => _buildKriteriaItem(k))
                          .toList(),
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
        return _CounterWidget(
          nilai: nilai.toInt(),
          onChanged: (v) => _updateNilai(k.id, v.toDouble()),
        );

      case InputType.toggle:
        return _ToggleWidget(
          nilai: nilai,
          onChanged: (v) => _updateNilai(k.id, v),
        );

      case InputType.stopwatch:
        return _StopwatchWidget(
          kriteriaId: k.id,
          detikTersimpan: nilai.toInt(),
          onStop: (detik) {
            // Simpan LANGSUNG saat stop — tanpa debounce
            // Tidak pakai setState karena onStop juga dipanggil dari dispose()
            _nilaiMap[k.id] = detik.toDouble();
            _simpanNilai(k.id, detik.toDouble());
          },
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
      InputType.toggle => Icons.toggle_on_outlined,
      InputType.stopwatch => Icons.timer_outlined,
      InputType.number => Icons.edit_outlined,
      null => Icons.auto_awesome_outlined,
    };
    return Icon(icon, size: 16, color: AppColors.textSecondary);
  }
}

// ─── Auto Save Indicator ──────────────────────────────────────────────────────

class _AutoSaveIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cloud_done_outlined, size: 14, color: AppColors.accent),
        const SizedBox(width: 4),
        Text(
          'Auto-save',
          style: TextStyle(fontSize: 11, color: AppColors.accent),
        ),
      ],
    );
  }
}

// ─── Counter Widget ───────────────────────────────────────────────────────────

class _CounterWidget extends StatelessWidget {
  final int nilai;
  final ValueChanged<int> onChanged;

  const _CounterWidget({required this.nilai, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tombol −
        _CircleBtn(
          icon: Icons.remove,
          color: nilai > 0 ? AppColors.danger : AppColors.border,
          onTap: nilai > 0 ? () => onChanged(nilai - 1) : null,
        ),

        // Nilai
        Column(
          children: [
            Text(
              '$nilai',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              'kali',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),

        // Tombol +
        _CircleBtn(
          icon: Icons.add,
          color: AppColors.accent,
          onTap: () => onChanged(nilai + 1),
        ),
      ],
    );
  }
}

// ─── Toggle Widget ────────────────────────────────────────────────────────────

class _ToggleWidget extends StatelessWidget {
  final double nilai;
  final ValueChanged<double> onChanged;

  const _ToggleWidget({required this.nilai, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isOn = nilai >= 1;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(isOn ? 0 : 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isOn
                    ? AppColors.accent.withOpacity(0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOn ? AppColors.accent : AppColors.border,
                  width: isOn ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOn ? Icons.check_circle : Icons.cancel_outlined,
                    color: isOn ? AppColors.accent : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOn ? 'Baik' : 'Kurang',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isOn ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stopwatch Widget ─────────────────────────────────────────────────────────

class _StopwatchWidget extends StatefulWidget {
  final String kriteriaId;
  final int detikTersimpan;
  final ValueChanged<int> onStop;

  const _StopwatchWidget({
    required this.kriteriaId,
    required this.detikTersimpan,
    required this.onStop,
  });

  @override
  State<_StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<_StopwatchWidget> {
  late Stopwatch _sw;
  Timer? _timer;
  bool _running = false;
  late int _totalDetik;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch();
    _totalDetik = widget.detikTersimpan;
  }

  @override
  void dispose() {
    if (_running) {
      // Auto-stop & auto-save jika sheet ditutup saat stopwatch masih jalan
      _sw.stop();
      _timer?.cancel();
      final totalDetik = widget.detikTersimpan + _sw.elapsed.inSeconds;
      widget.onStop(totalDetik); // aman: onStop tidak pakai setState
    } else {
      _timer?.cancel();
    }
    super.dispose();
  }

  void _mulai() {
    _sw.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(
        () => _totalDetik = widget.detikTersimpan + _sw.elapsed.inSeconds,
      );
    });
    setState(() => _running = true);
  }

  void _stop() {
    _sw.stop();
    _timer?.cancel();
    setState(() {
      _running = false;
      _totalDetik = widget.detikTersimpan + _sw.elapsed.inSeconds;
    });
    widget.onStop(_totalDetik);
  }

  void _reset() {
    _sw.reset();
    _timer?.cancel();
    setState(() {
      _running = false;
      _totalDetik = 0;
    });
    widget.onStop(0);
  }

  String _format(int detik) {
    final m = detik ~/ 60;
    final s = detik % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _format(_totalDetik),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: _running ? AppColors.accent : AppColors.primary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_running) ...[
              _CircleBtn(
                icon: Icons.refresh,
                color: AppColors.textSecondary,
                onTap: _totalDetik > 0 ? _reset : null,
              ),
              const SizedBox(width: 20),
              _CircleBtn(
                icon: Icons.play_arrow,
                color: AppColors.accent,
                size: 56,
                onTap: _mulai,
              ),
            ] else ...[
              _CircleBtn(
                icon: Icons.stop,
                color: AppColors.danger,
                size: 56,
                onTap: _stop,
              ),
            ],
          ],
        ),
        if (_totalDetik > 0 && !_running) ...[
          const SizedBox(height: 8),
          Text(
            'Tersimpan: ${_format(_totalDetik)}',
            style: TextStyle(fontSize: 12, color: AppColors.accent),
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

// ─── Circle Button ────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  const _CircleBtn({
    required this.icon,
    required this.color,
    this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onTap != null ? color : color.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
