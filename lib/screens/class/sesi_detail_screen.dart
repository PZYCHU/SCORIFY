import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class SesiDetailScreen extends StatefulWidget {
  final String kelasId;
  final String kriteriaId;
  final String sesiId;

  const SesiDetailScreen({
    super.key,
    required this.kelasId,
    required this.kriteriaId,
    required this.sesiId,
  });

  @override
  State<SesiDetailScreen> createState() => _SesiDetailScreenState();
}

class _SesiDetailScreenState extends State<SesiDetailScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final kelas = provider.getKelas(widget.kelasId);
        if (kelas == null) return const Scaffold(body: SizedBox());

        final kriteria = kelas.kriteria.firstWhere(
          (k) => k.id == widget.kriteriaId,
          orElse: () => Kriteria(
            id: '',
            nama: 'Kriteria',
            jenis: JenisKriteria.hasil,
            bobot: 0,
          ),
        );

        final sesiList = kelas.getSesiByKriteria(widget.kriteriaId);
        final sesi = sesiList.firstWhere(
          (s) => s.id == widget.sesiId,
          orElse: () => Sesi(
            id: '',
            kriteriaId: '',
            nama: 'Sesi',
            urutan: 1,
            tanggal: DateTime.now(),
          ),
        );

        if (sesi.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sesi Tidak Ditemukan')),
            body: const Center(child: Text('Sesi telah dihapus atau tidak ditemukan.')),
          );
        }

        // Filter murid berdasarkan pencarian
        final filteredMuridList = kelas.muridList.where((m) {
          final query = _searchQuery.toLowerCase();
          final namaMatch = m.nama.toLowerCase().contains(query);
          final nisMatch = (m.nis ?? '').toLowerCase().contains(query);
          return namaMatch || nisMatch;
        }).toList();

        // Hitung statistik sesi
        int muridTerisi = 0;
        double totalNilai = 0;

        for (final m in kelas.muridList) {
          final existing = m.nilaiList.where(
            (n) => n.kriteriaId == kriteria.id && n.sesiId == sesi.id,
          ).toList();

          if (existing.isNotEmpty) {
            existing.sort((a, b) => b.attempt.compareTo(a.attempt));
            muridTerisi++;
            totalNilai += existing.first.nilai;
          }
        }

        final double avgNilai = muridTerisi > 0 ? totalNilai / muridTerisi : 0.0;
        final bool semuaSelesai = muridTerisi == kelas.muridList.length && kelas.muridList.isNotEmpty;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, kelas, kriteria, sesi),
                Expanded(
                  child: Column(
                    children: [
                      // Summary Card Sesi
                      _buildSummaryCard(
                        context,
                        kelas,
                        kriteria,
                        sesi,
                        muridTerisi,
                        kelas.muridList.length,
                        avgNilai,
                        semuaSelesai,
                        provider,
                      ),

                      // Search Bar Siswa dalam Sesi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau NIS siswa...',
                            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _searchCtrl.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            fillColor: AppColors.surfaceWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),

                      // List Murid & Nilai
                      Expanded(
                        child: filteredMuridList.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Tidak ada siswa yang cocok dengan "$_searchQuery"'
                                      : 'Belum ada data siswa di kelas ini.',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: filteredMuridList.length,
                                itemBuilder: (ctx, index) {
                                  final murid = filteredMuridList[index];
                                  final existing = murid.nilaiList.where(
                                    (n) => n.kriteriaId == kriteria.id && n.sesiId == sesi.id,
                                  ).toList();

                                  Nilai? bestNilai;
                                  if (existing.isNotEmpty) {
                                    existing.sort((a, b) => b.attempt.compareTo(a.attempt));
                                    bestNilai = existing.first;
                                  }

                                  return _MuridNilaiCard(
                                    index: index + 1,
                                    murid: murid,
                                    nilaiHasil: bestNilai,
                                    onTapEdit: () => _showSingleNilaiDialog(
                                      context,
                                      kelas,
                                      kriteria,
                                      sesi,
                                      murid,
                                      bestNilai,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showInputAllSheet(context, kelas, kriteria, sesi),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit_note, size: 20),
            label: Text(
              semuaSelesai ? 'Edit Nilai Sekaligus' : 'Input Nilai Sekaligus',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Kelas kelas, Kriteria kriteria, Sesi sesi) {
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
                  sesi.nama,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                Text(
                  'Kriteria: ${kriteria.nama} • ${kelas.nama}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Kelas kelas,
    Kriteria kriteria,
    Sesi sesi,
    int muridTerisi,
    int totalMurid,
    double avgNilai,
    bool semuaSelesai,
    AppProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_turned_in, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sesi.nama,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: semuaSelesai ? AppColors.benefitChip : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            semuaSelesai ? 'Selesai' : 'Belum Lengkap',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: semuaSelesai ? AppColors.benefitChipText : AppColors.warningDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kategori Kriteria: ${kriteria.nama}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                tooltip: 'Hapus Sesi',
                onPressed: () async {
                  final confirm = await showConfirmDialog(
                    context,
                    title: 'Hapus Sesi Penilaian',
                    content: 'Apakah Anda yakin ingin menghapus sesi "${sesi.nama}" beserta seluruh nilainya?',
                  );
                  if (confirm && context.mounted) {
                    await provider.hapusSesi(widget.kelasId, sesi.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Progres Nilai', '$muridTerisi / $totalMurid Murid'),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildStatItem('Rata-Rata Nilai', muridTerisi > 0 ? avgNilai.toStringAsFixed(1) : '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showSingleNilaiDialog(
    BuildContext context,
    Kelas kelas,
    Kriteria kriteria,
    Sesi sesi,
    Murid murid,
    Nilai? existing,
  ) {
    final ctrl = TextEditingController(
      text: existing != null ? existing.nilai.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Nilai — ${murid.nama}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesi: ${sesi.nama} (${kriteria.nama})',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nilai (0 - 100)',
                hintText: 'Masukkan nilai murid',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                final nilai = double.tryParse(text);
                if (nilai != null) {
                  await context.read<AppProvider>().inputNilaiHasil(
                        kelasId: widget.kelasId,
                        muridId: murid.id,
                        kriteriaId: kriteria.id,
                        sesiId: sesi.id,
                        nilai: nilai,
                      );
                }
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showInputAllSheet(
    BuildContext context,
    Kelas kelas,
    Kriteria kriteria,
    Sesi sesi,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InputNilaiPerSesiSheet(
        kelas: kelas,
        kriteria: kriteria,
        sesi: sesi,
        kelasId: widget.kelasId,
      ),
    );
  }
}

// ─── Murid Nilai Card Item ───────────────────────────────────────────────────

class _MuridNilaiCard extends StatelessWidget {
  final int index;
  final Murid murid;
  final Nilai? nilaiHasil;
  final VoidCallback onTapEdit;

  const _MuridNilaiCard({
    required this.index,
    required this.murid,
    required this.nilaiHasil,
    required this.onTapEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasNilai = nilaiHasil != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.surfaceWhite,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          murid.nama,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'NIS: ${murid.nis ?? '-'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasNilai
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasNilai ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                ),
              ),
              child: Text(
                hasNilai ? nilaiHasil!.nilai.toStringAsFixed(0) : 'Belum diisi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: hasNilai ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
              onPressed: onTapEdit,
            ),
          ],
        ),
        onTap: onTapEdit,
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
  State<_InputNilaiPerSesiSheet> createState() => _InputNilaiPerSesiSheetState();
}

class _InputNilaiPerSesiSheetState extends State<_InputNilaiPerSesiSheet> {
  late Map<String, TextEditingController> _ctrls;
  late Map<String, double?> _originalNilai;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrls = {};
    _originalNilai = {};

    for (final murid in widget.kelas.muridList) {
      final existing = murid.nilaiList
          .where((n) =>
              n.kriteriaId == widget.kriteria.id && n.sesiId == widget.sesi.id)
          .toList();

      if (existing.isNotEmpty) {
        existing.sort((a, b) => b.attempt.compareTo(a.attempt));
        final best = existing.first;
        _ctrls[murid.id] = TextEditingController(text: best.nilai.toStringAsFixed(0));
        _originalNilai[murid.id] = best.nilai;
      } else {
        _ctrls[murid.id] = TextEditingController();
        _originalNilai[murid.id] = null;
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

      final original = _originalNilai[murid.id];
      if (original != null && original == nilai) {
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
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Input Nilai Sekaligus',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${widget.sesi.nama} — Kriteria: ${widget.kriteria.nama}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saving ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Simpan All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: widget.kelas.muridList.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final murid = widget.kelas.muridList[i];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              murid.nama,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              'NIS: ${murid.nis ?? '-'}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _ctrls[murid.id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '0-100',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
