import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class InputNilaiHasilScreen extends StatelessWidget {
  final String kelasId;
  const InputNilaiHasilScreen({super.key, required this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final kelas = provider.getKelas(kelasId);
        if (kelas == null) return const Scaffold(body: SizedBox());

        final kriteriaHasil = kelas.kriteria
            .where((k) => k.jenis == JenisKriteria.hasil)
            .toList();

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, kelas),
                Expanded(
                  child: kriteriaHasil.isEmpty
                      ? const EmptyState(
                          icon: '📝',
                          title: 'Tidak ada kriteria nilai',
                          subtitle:
                              'Belum ada kriteria jenis "hasil"\ndi kelas ini',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: kriteriaHasil.length,
                          itemBuilder: (ctx, i) => _KriteriaHasilCard(
                            kelas: kelas,
                            kriteria: kriteriaHasil[i],
                            kelasId: kelasId,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Kelas kelas) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nilai Tugas & Tes',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                Text(
                  kelas.nama,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kriteria Hasil Card ──────────────────────────────────────────────────────

class _KriteriaHasilCard extends StatelessWidget {
  final Kelas kelas;
  final Kriteria kriteria;
  final String kelasId;

  const _KriteriaHasilCard({
    required this.kelas,
    required this.kriteria,
    required this.kelasId,
  });

  @override
  Widget build(BuildContext context) {
    final sesiList = kelas.getSesiByKriteria(kriteria.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kriteria
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kriteria.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sesiList.length} sesi',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showTambahSesiDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Sesi',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),

          if (sesiList.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Belum ada sesi. Tap "+ Sesi" untuk mulai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Column(
              children: [
                ...sesiList.map((sesi) => _SesiTile(
                      kelas: kelas,
                      kriteria: kriteria,
                      sesi: sesi,
                      kelasId: kelasId,
                    )),
                const SizedBox(height: 6),
              ],
            ),
        ],
      ),
    );
  }

  void _showTambahSesiDialog(BuildContext context) {
    final namaCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tambah Sesi — ${kriteria.nama}',
          style: const TextStyle(fontSize: 16),
        ),
        content: TextField(
          controller: namaCtrl,
          decoration: const InputDecoration(
            hintText: 'Contoh: Tugas Bab 1, UTS, Quiz 2',
            labelText: 'Nama Sesi',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) async {
            final nama = namaCtrl.text.trim();
            if (nama.isEmpty) return;
            await context
                .read<AppProvider>()
                .tambahSesi(kelasId, kriteria.id, nama);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nama = namaCtrl.text.trim();
              if (nama.isEmpty) return;
              await context
                  .read<AppProvider>()
                  .tambahSesi(kelasId, kriteria.id, nama);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }
}

// ─── Sesi Tile ────────────────────────────────────────────────────────────────

class _SesiTile extends StatefulWidget {
  final Kelas kelas;
  final Kriteria kriteria;
  final Sesi sesi;
  final String kelasId;

  const _SesiTile({
    required this.kelas,
    required this.kriteria,
    required this.sesi,
    required this.kelasId,
  });

  @override
  State<_SesiTile> createState() => _SesiTileState();
}

class _SesiTileState extends State<_SesiTile> {
  late bool _expanded;

  int get _jumlahTerisi => widget.kelas.muridList
      .where((m) => m.nilaiList
          .any((n) => n.kriteriaId == widget.kriteria.id && n.sesiId == widget.sesi.id))
      .length;

  @override
  void initState() {
    super.initState();
    final total = widget.kelas.muridList.length;
    final terisi = _jumlahTerisi;
    // Sesi yang sudah selesai → collapsed by default
    _expanded = !(terisi == total && total > 0);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.kelas.muridList.length;
    final terisi = _jumlahTerisi;
    final selesai = terisi == total && total > 0;

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (selesai) {
              // Toggle collapse/expand untuk sesi selesai
              setState(() => _expanded = !_expanded);
            } else {
              // Sesi belum selesai → langsung buka input
              _showInputSheet(context);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selesai ? AppColors.benefitChip : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selesai
                    ? AppColors.benefitChipText.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selesai ? Icons.check_circle : Icons.edit_note,
                  color: selesai
                      ? AppColors.benefitChipText
                      : AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sesi.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        selesai
                            ? 'Selesai — $terisi/$total murid'
                            : '$terisi / $total murid sudah diisi',
                        style: TextStyle(
                          fontSize: 11,
                          color: selesai
                              ? AppColors.benefitChipText
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selesai)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.benefitChipText,
                  )
                else
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        // Tombol edit — hanya muncul saat expanded (selesai tapi mau edit)
        if (selesai && _expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showInputSheet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit / Tambah Nilai',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
      ],
    );
  }

  void _showInputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InputNilaiPerSesiSheet(
        kelas: widget.kelas,
        kriteria: widget.kriteria,
        sesi: widget.sesi,
        kelasId: widget.kelasId,
      ),
    );
  }
}

// ─── Input Nilai Per Sesi Sheet ───────────────────────────────────────────────

class _InputNilaiPerSesiSheet extends StatefulWidget {
  final Kelas kelas;
  final Kriteria kriteria;
  final Sesi sesi;
  final String kelasId;

  const _InputNilaiPerSesiSheet({
    required this.kelas,
    required this.kriteria,
    required this.sesi,
    required this.kelasId,
  });

  @override
  State<_InputNilaiPerSesiSheet> createState() =>
      _InputNilaiPerSesiSheetState();
}

class _InputNilaiPerSesiSheetState
    extends State<_InputNilaiPerSesiSheet> {
  late Map<String, TextEditingController> _ctrls;
  // Simpan attempt terakhir untuk tiap murid (0 = belum ada nilai)
  late Map<String, int> _lastAttempt;
  // Simpan nilai awal (null = belum ada nilai sebelumnya)
  late Map<String, double?> _originalNilai;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrls = {};
    _lastAttempt = {};
    _originalNilai = {};

    for (final murid in widget.kelas.muridList) {
      final existing = murid.nilaiList
          .where((n) =>
              n.kriteriaId == widget.kriteria.id &&
              n.sesiId == widget.sesi.id)
          .toList();

      if (existing.isNotEmpty) {
        existing.sort((a, b) => b.attempt.compareTo(a.attempt));
        final best = existing.first;
        _ctrls[murid.id] =
            TextEditingController(text: best.nilai.toStringAsFixed(0));
        _lastAttempt[murid.id] = best.attempt;
        _originalNilai[murid.id] = best.nilai; // simpan nilai awal
      } else {
        _ctrls[murid.id] = TextEditingController();
        _lastAttempt[murid.id] = 0;
        _originalNilai[murid.id] = null; // belum ada nilai
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();

    for (final murid in widget.kelas.muridList) {
      final text = _ctrls[murid.id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final nilai = double.tryParse(text);
      if (nilai == null) continue;

      // Cek apakah nilai berubah dari yang sebelumnya
      final original = _originalNilai[murid.id];
      if (original != null && original == nilai) {
        // Nilai tidak berubah — jangan tambah attempt baru
        continue;
      }

      await provider.inputNilaiHasil(
        kelasId: widget.kelasId,
        muridId: murid.id,
        kriteriaId: widget.kriteria.id,
        sesiId: widget.sesi.id,
        nilai: nilai,
      );
    }

    setState(() => _saving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sesi.nama,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                        Text(
                          widget.kriteria.nama,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.kelas.muridList.length} murid',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // Hint retake
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jika murid sudah punya nilai, input baru = dianggap ngulang (attempt naik).',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List murid
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: widget.kelas.muridList.map((murid) {
                  final attempt = _lastAttempt[murid.id] ?? 0;
                  final sudahAda = attempt > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    murid.nama,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  if (sudahAda) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.costChip,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Attempt $attempt',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color:
                                                AppColors.costChipText),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (sudahAda)
                                const Text(
                                  'Ada nilai — input baru = ngulang',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 88,
                          child: TextField(
                            controller: _ctrls[murid.id],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.primary),
                            decoration: InputDecoration(
                              hintText: '0–100',
                              hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Simpan Nilai',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
