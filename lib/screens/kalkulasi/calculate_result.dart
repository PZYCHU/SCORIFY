import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

        final muridSorted = List<Murid>.from(kelas.muridList)
          ..sort((a, b) => (b.skorFinal ?? 0).compareTo(a.skorFinal ?? 0));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(context, kelas, muridSorted),
              Expanded(
                child: muridSorted.isEmpty
                    ? const Center(
                        child: EmptyState(
                          icon: '📊',
                          title: 'Belum Ada Hasil',
                          subtitle: 'Tambahkan data siswa dan nilai, lalu jalankan kalkulasi',
                        ),
                      )
                    : _buildBody(context, kelas, muridSorted),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Kelas kelas, List<Murid> muridSorted) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D252B), Color(0xFF163842), Color(0xFF1B4B5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Ambient glowing orbs
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Frosted glass back button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasil Perankingan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              kelas.nama,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Pill badge status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF6EE7B7),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Metode SAW',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6EE7B7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bobot horizontal list
                  Row(
                    children: [
                      const Icon(
                        Icons.pie_chart_outline_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bobot Kriteria (AHP):',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: kelas.kriteria.map((k) {
                        final isBenefit = k.arah == ArahKriteria.benefit;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isBenefit ? '↑' : '↓',
                                style: TextStyle(
                                  color: isBenefit ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${k.nama}: ${(k.bobot * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, Kelas kelas, List<Murid> muridList) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Podium card if 3 or more students, or top cards
        if (muridList.length >= 3)
          _buildPodiumSection(context, muridList)
        else if (muridList.isNotEmpty)
          _buildTopSummary(context, muridList),

        const SizedBox(height: 18),

        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Peringkat Lengkap',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${muridList.length} Siswa',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cards list
        ...List.generate(
          muridList.length,
          (i) => _RankingCard(
            murid: muridList[i],
            kelas: kelas,
            rank: i + 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSummary(BuildContext context, List<Murid> muridList) {
    final highest = muridList.first.skorFinal ?? 0;
    final lowest = muridList.last.skorFinal ?? 0;
    final total = muridList.fold<double>(0, (sum, m) => sum + (m.skorFinal ?? 0));
    final avg = muridList.isNotEmpty ? total / muridList.length : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatMiniCard(
            title: 'Tertinggi',
            value: highest.toStringAsFixed(2),
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatMiniCard(
            title: 'Rata-rata',
            value: avg.toStringAsFixed(2),
            icon: Icons.analytics_outlined,
            color: AppColors.primary,
            bg: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatMiniCard(
            title: 'Terendah',
            value: lowest.toStringAsFixed(2),
            icon: Icons.trending_down_rounded,
            color: const Color(0xFF64748B),
            bg: const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSection(BuildContext context, List<Murid> muridList) {
    final first = muridList[0];
    final second = muridList[1];
    final third = muridList[2];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Top 3 Terbaik',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Skor SAW Teratas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 3 podium columns: 2nd, 1st, 3rd
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Silver)
              Expanded(
                child: _buildPodiumColumn(
                  rank: 2,
                  murid: second,
                  color: const Color(0xFF64748B),
                  bg: const Color(0xFFF1F5F9),
                  height: 90,
                  icon: '🥈',
                ),
              ),
              const SizedBox(width: 10),
              // 1st Place (Gold)
              Expanded(
                child: _buildPodiumColumn(
                  rank: 1,
                  murid: first,
                  color: const Color(0xFFF59E0B),
                  bg: const Color(0xFFFEF3C7),
                  height: 115,
                  icon: '🥇',
                  isFirst: true,
                ),
              ),
              const SizedBox(width: 10),
              // 3rd Place (Bronze)
              Expanded(
                child: _buildPodiumColumn(
                  rank: 3,
                  murid: third,
                  color: const Color(0xFFB45309),
                  bg: const Color(0xFFFDF4E6),
                  height: 75,
                  icon: '🥉',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required int rank,
    required Murid murid,
    required Color color,
    required Color bg,
    required double height,
    required String icon,
    bool isFirst = false,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: isFirst ? 26 : 22),
        ),
        const SizedBox(height: 4),
        Text(
          murid.nama,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isFirst ? 13 : 12,
            fontWeight: isFirst ? FontWeight.w800 : FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isFirst ? const Color(0xFF0D252B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            murid.skorFinal?.toStringAsFixed(2) ?? '-',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isFirst ? const Color(0xFF10B981) : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(
              color: color.withValues(alpha: isFirst ? 0.4 : 0.25),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isFirst ? 20 : 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Ranking Card ─────────────────────────────────────────────────────────────

class _RankingCard extends StatelessWidget {
  final Murid murid;
  final Kelas kelas;
  final int rank;

  const _RankingCard({
    required this.murid,
    required this.kelas,
    required this.rank,
  });

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFF59E0B);
    if (rank == 2) return const Color(0xFF64748B);
    if (rank == 3) return const Color(0xFFB45309);
    return const Color(0xFF1B4B5A);
  }

  Color get _rankBg {
    if (rank == 1) return const Color(0xFFFEF3C7);
    if (rank == 2) return const Color(0xFFF1F5F9);
    if (rank == 3) return const Color(0xFFFDF4E6);
    return const Color(0xFFF1F5F9);
  }

  /// Ambil nilai ringkasan per kriteria untuk ditampilkan:
  /// - performa & derived: rata-rata semua nilai
  /// - hasil: rata-rata nilai terbaik (attempt tertinggi) per sesi
  double _nilaiRingkasan(Kriteria k) {
    if (k.jenis == JenisKriteria.derived) {
      return murid.getFrekuensiNgulang(k.targetKriteriaIds).toDouble();
    }

    final semuaNilai = murid.getNilaiByKriteria(k.id);
    if (semuaNilai.isEmpty) return 0;

    if (k.jenis == JenisKriteria.hasil && k.perSesi) {
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

    if (k.jenis == JenisKriteria.performa &&
        (k.inputType == InputType.counter || k.inputType == InputType.attendance)) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai);
    }

    return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai) / semuaNilai.length;
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final skorFinal = murid.skorFinal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop3
              ? _rankColor.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.8),
          width: isTop3 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTop3
                ? _rankColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _rankBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _rankColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      rank == 1
                          ? '🥇'
                          : (rank == 2 ? '🥈' : (rank == 3 ? '🥉' : '#$rank')),
                      style: GoogleFonts.plusJakartaSans(
                        color: _rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: isTop3 ? 18 : 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Nama murid & kriteria breakdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        murid.nama,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: kelas.kriteria.map((k) {
                          final val = _nilaiRingkasan(k);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.7),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${k.nama}: ${val.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Skor final badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D252B),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D252B).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SKOR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        skorFinal?.toStringAsFixed(2) ?? '-',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: rank == 1
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress bar skor
          if (skorFinal != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _SkorProgressBar(skor: skorFinal, color: _rankColor),
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
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: (skor / 100).clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: const Color(0xFFF1F5F9),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}