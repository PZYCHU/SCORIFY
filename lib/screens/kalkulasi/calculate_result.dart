import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class HasilKalkulasiScreen extends StatelessWidget {
  final String kelasId;

  const HasilKalkulasiScreen({super.key, required this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final kelas = provider.getKelas(kelasId);
        if (kelas == null) return const Scaffold(body: SizedBox());

        final muridSorted = kelas.muridList;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, kelas),
                Expanded(
                  child: muridSorted.isEmpty
                      ? const EmptyState(
                          icon: '📊',
                          title: 'Belum ada data',
                          subtitle: 'Tambahkan murid terlebih dahulu',
                        )
                      : _buildRanking(context, kelas, muridSorted),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hasil Kalkulasi',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white)),
                    Text(kelas.nama,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bobot summary
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kelas.kriteria.map((k) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${k.nama}: ${(k.bobot * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRanking(BuildContext context, Kelas kelas, List<Murid> muridList) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: muridList.length,
      itemBuilder: (ctx, i) {
        final murid = muridList[i];
        return _RankingCard(murid: murid, kelas: kelas, rank: i + 1);
      },
    );
  }
}

// ─── Ranking Card ─────────────────────────────────────────────────────────────

class _RankingCard extends StatelessWidget {
  final Murid murid;
  final Kelas kelas;
  final int rank;

  const _RankingCard({required this.murid, required this.kelas, required this.rank});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFF9A825);
    if (rank == 2) return const Color(0xFF78909C);
    if (rank == 3) return const Color(0xFF8D6E63);
    return AppColors.primary.withOpacity(0.5);
  }

  /// Ambil nilai ringkasan per kriteria untuk ditampilkan:
  /// - performa & derived: rata-rata semua nilai
  /// - hasil: rata-rata nilai terbaik (attempt tertinggi) per sesi
  double _nilaiRingkasan(Kriteria k) {
    // Derived: hitung frekuensi ngulang, bukan rata-rata nilaiList
    if (k.jenis == JenisKriteria.derived) {
      return murid.getFrekuensiNgulang().toDouble();
    }

    final semuaNilai = murid.getNilaiByKriteria(k.id);
    if (semuaNilai.isEmpty) return 0;

    if (k.jenis == JenisKriteria.hasil && k.perSesi) {
      // Grup per sesi, ambil nilai terbaik per sesi
      final Map<String, double> bestPerSesi = {};
      for (final n in semuaNilai) {
        final sesiKey = n.sesiId ?? 'no_sesi';
        if (!bestPerSesi.containsKey(sesiKey) ||
            n.nilai > bestPerSesi[sesiKey]!) {
          bestPerSesi[sesiKey] = n.nilai;
        }
      }
      if (bestPerSesi.isEmpty) return 0;
      return bestPerSesi.values.reduce((a, b) => a + b) / bestPerSesi.length;
    }

    // Counter: SUM semua pertemuan (konsisten dengan kalkulasi SAW)
    if (k.jenis == JenisKriteria.performa &&
        k.inputType == InputType.counter) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai);
    }

    // Toggle, number: rata-rata semua pertemuan
    return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai) / semuaNilai.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(color: _rankColor.withOpacity(0.4), width: 1.5)
            : Border.all(color: AppColors.border, width: 0.5),
        boxShadow: rank == 1
            ? [
                BoxShadow(
                    color: _rankColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(murid.nama,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      // Nilai per kriteria
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: kelas.kriteria.map((k) {
                          final val = _nilaiRingkasan(k);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.border, width: 0.5),
                            ),
                            child: Text(
                              '${k.nama}: ${val.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Skor final
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.scoreCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text('Skor Final',
                          style: TextStyle(fontSize: 9, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(
                        murid.skorFinal?.toStringAsFixed(2) ?? '-',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress bar skor
          if (murid.skorFinal != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _SkorProgressBar(skor: murid.skorFinal!, color: _rankColor),
            ),
        ],
      ),
    );
  }
}

// ─── Skor Progress Bar ────────────────────────────────────────────────────────

class _SkorProgressBar extends StatelessWidget {
  final double skor;
  final Color color;

  const _SkorProgressBar({required this.skor, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (skor / 100).clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: AppColors.background,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}