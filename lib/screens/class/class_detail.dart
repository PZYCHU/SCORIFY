import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../ahp/ahp_screen.dart';
import '../student/add_student.dart';
import '../class/input_nilai_screen.dart';
import '../kalkulasi/calculate_result.dart';

class DetailKelasScreen extends StatelessWidget {
  final String kelasId;

  const DetailKelasScreen({super.key, required this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final kelas = provider.getKelas(kelasId);
        if (kelas == null) {
          return const Scaffold(
            body: Center(child: Text('Kelas tidak ditemukan')),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, kelas, provider),
                Expanded(
                  child: kelas.muridList.isEmpty
                      ? const EmptyState(
                          icon: '👨‍🎓',
                          title: 'Belum ada murid',
                          subtitle:
                              'Tap tombol + untuk menambahkan\nmurid ke kelas ini',
                        )
                      : _buildMuridList(context, kelas),
                ),
                _buildBottomBar(context, kelas, provider),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TambahMuridScreen(kelasId: kelasId, kelas: kelas),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Kelas kelas, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kelas.nama,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (val) async {
                  if (val == 'edit') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur edit kelas sedang dalam pengembangan',
                        ),
                      ),
                    );
                  } else if (val == 'hapus') {
                    final confirm = await showConfirmDialog(
                      context,
                      title: 'Hapus Kelas',
                      content:
                          'Semua data murid di kelas ini akan ikut terhapus. Lanjutkan?',
                    );
                    if (confirm && context.mounted) {
                      await provider.hapusKelas(kelasId);
                      Navigator.of(context).pop();
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Kelas')),
                  const PopupMenuItem(
                    value: 'hapus',
                    child: Text(
                      'Hapus Kelas',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeaderChip(
                icon: Icons.people_outline,
                label: '${kelas.jumlahSiswa} Siswa',
              ),
              const SizedBox(width: 10),
              _HeaderChip(
                icon: Icons.tune,
                label: '${kelas.jumlahKriteria} Kriteria',
              ),
              if (kelas.sudahKalkulasi) ...[
                const SizedBox(width: 10),
                _HeaderChip(
                  icon: Icons.check_circle_outline,
                  label: 'Terhitung',
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuridList(BuildContext context, Kelas kelas) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: kelas.muridList.length,
      itemBuilder: (ctx, i) {
        final murid = kelas.muridList[i];
        return _MuridCard(
          murid: murid,
          kelas: kelas,
          rank: kelas.sudahKalkulasi ? i + 1 : null,
          // ← tap buka sheet penilaian KBM
          onTapNilai: () =>
              showInputNilaiSheet(context, kelas: kelas, murid: murid),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Kelas kelas,
    AppProvider provider,
  ) {
    final bobotBelumDiisi = kelas.kriteria.any((k) => k.bobot == 0.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: kelas.muridList.isEmpty
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AhpScreen(kelasId: kelasId),
                      ),
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.balance, size: 18),
              label: Text(
                bobotBelumDiisi ? 'Isi Bobot AHP' : 'Edit Bobot AHP',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (kelas.muridList.isEmpty || bobotBelumDiisi)
                  ? null
                  : () => _jalankanKalkulasi(context, provider, kelas),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Kalkulasi'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _jalankanKalkulasi(
    BuildContext context,
    AppProvider provider,
    Kelas kelas,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final hasil = await provider.jalankanKalkulasi(kelasId);
    if (context.mounted) Navigator.of(context).pop();

    if (hasil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal: pastikan bobot AHP sudah diisi')),
      );
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HasilKalkulasiScreen(kelasId: kelasId),
        ),
      );
    }
  }
}

// ─── Murid Card ───────────────────────────────────────────────────────────────

class _MuridCard extends StatelessWidget {
  final Murid murid;
  final Kelas kelas;
  final int? rank;
  final VoidCallback onTapNilai;

  const _MuridCard({
    required this.murid,
    required this.kelas,
    required this.onTapNilai,
    this.rank,
  });

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFF9A825);
    if (rank == 2) return const Color(0xFF9E9E9E);
    if (rank == 3) return const Color(0xFF8D6E63);
    return AppColors.primary.withOpacity(0.15);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapNilai,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (rank != null) ...[
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _rankColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: rank! <= 3
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          murid.nama,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: kelas.kriteria
                        .map((k) => _KriteriaTag(nama: k.nama))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (murid.skorFinal != null)
              _SkorBadge(skor: murid.skorFinal!)
            else
              // Ikon pensil sebagai hint bisa di-tap
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TambahMuridScreen(
                            kelasId: kelas.id,
                            kelas: kelas,
                            existingMurid: murid,
                          ),
                        ),
                      );
                    } else if (val == 'hapus') {
                      _hapusMurid(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'hapus',
                      child: Text(
                        'Hapus',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _hapusMurid(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Hapus Murid',
      content: 'Data ${murid.nama} akan dihapus. Lanjutkan?',
    );
    if (confirm && context.mounted) {
      await context.read<AppProvider>().hapusMurid(kelas.id, murid.id);
    }
  }
}

// ─── Widget kecil ─────────────────────────────────────────────────────────────

class _KriteriaTag extends StatelessWidget {
  final String nama;
  const _KriteriaTag({required this.nama});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag, size: 10, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Text(
            nama,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkorBadge extends StatelessWidget {
  final double skor;
  const _SkorBadge({required this.skor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.scoreCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'Skor Final',
            style: TextStyle(fontSize: 9, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            skor.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _HeaderChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
