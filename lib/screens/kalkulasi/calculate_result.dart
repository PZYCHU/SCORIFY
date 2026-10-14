import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../utils/calculate_service.dart';

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
          _buildPodiumSection(context, kelas, muridList)
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

  Widget _buildPodiumSection(BuildContext context, Kelas kelas, List<Murid> muridList) {
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
                  context: context,
                  kelas: kelas,
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
                  context: context,
                  kelas: kelas,
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
                  context: context,
                  kelas: kelas,
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
    required BuildContext context,
    required Kelas kelas,
    required int rank,
    required Murid murid,
    required Color color,
    required Color bg,
    required double height,
    required String icon,
    bool isFirst = false,
  }) {
    return GestureDetector(
      onTap: () => _showDetailMurid(context, murid, kelas, rank),
      child: Column(
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
      ),
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
  /// - byProduct: nilai per sesi sesuai aggregationRule (max/average), dirata-ratakan
  /// - byProcess (counter / attendance): SUM akumulasi nilai
  /// - byProcess (number / default): rata-rata
  double _nilaiRingkasan(Kriteria k) {
    final semuaNilai = murid.getNilaiByKriteria(k.id);
    if (semuaNilai.isEmpty) return 0;

    final isKeaktifan = k.jenis == JenisKriteria.byProcess &&
        (k.inputType == InputType.counter ||
            k.nama.toLowerCase().contains('aktif'));

    if (isKeaktifan) {
      if (k.aggregationRule == AggregationRule.average) {
        final active = semuaNilai.where((n) => n.nilai > 0).toList();
        return active.isEmpty
            ? 0.0
            : active.fold(0.0, (sum, n) => sum + n.nilai) / active.length;
      } else if (k.aggregationRule == AggregationRule.min) {
        final active = semuaNilai.where((n) => n.nilai > 0).toList();
        return active.isEmpty
            ? 0.0
            : active.map((n) => n.nilai).reduce(min);
      } else {
        return semuaNilai.map((n) => n.nilai).reduce(max);
      }
    }

    if (k.jenis == JenisKriteria.byProduct) {
      final Map<String, List<Nilai>> perSesi = {};
      for (final n in semuaNilai) {
        final sesiKey = n.sesiId ?? 'no_sesi';
        perSesi.putIfAbsent(sesiKey, () => []).add(n);
      }
      if (perSesi.isEmpty) return 0;

      double totalSesi = 0.0;
      for (final list in perSesi.values) {
        if (k.aggregationRule == AggregationRule.average) {
          totalSesi += list.fold(0.0, (s, n) => s + n.nilai) / list.length;
        } else if (k.aggregationRule == AggregationRule.min) {
          totalSesi += list.map((e) => e.nilai).reduce(min);
        } else {
          totalSesi += list.map((e) => e.nilai).reduce(max);
        }
      }
      return totalSesi / perSesi.length;
    }

    if (k.jenis == JenisKriteria.byProcess &&
        k.inputType == InputType.attendance) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai);
    }

    if (k.aggregationRule == AggregationRule.average) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai) / semuaNilai.length;
    } else if (k.aggregationRule == AggregationRule.min) {
      return semuaNilai.map((n) => n.nilai).reduce(min);
    }
    return semuaNilai.map((n) => n.nilai).reduce(max);
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetailMurid(context, murid, kelas, rank),
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
                              final isCost = k.arah == ArahKriteria.cost ||
                                  k.nama.toLowerCase().contains('langgar') ||
                                  k.nama.toLowerCase().contains('disiplin');

                              final Color chipBg;
                              final Color chipBorder;
                              final Color chipText;

                              if (isCost) {
                                if (val > 0) {
                                  chipBg = const Color(0xFFFEF2F2);
                                  chipBorder = const Color(0xFFFECACA);
                                  chipText = const Color(0xFFDC2626);
                                } else {
                                  chipBg = const Color(0xFFECFDF5);
                                  chipBorder = const Color(0xFFA7F3D0);
                                  chipText = const Color(0xFF059669);
                                }
                              } else {
                                chipBg = const Color(0xFFF8FAFC);
                                chipBorder = AppColors.border.withValues(alpha: 0.7);
                                chipText = AppColors.textSecondary;
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: chipBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: chipBorder,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${k.nama}: ${val.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: chipText,
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _SkorProgressBar(skor: skorFinal, color: _rankColor),
                ),
              // Hint interaktif tap rincian
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ketuk untuk rincian sesi & remedial',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

// ─── Modal Detail Sesi & Riwayat Attempt Murid ────────────────────────────────

void _showDetailMurid(
  BuildContext context,
  Murid murid,
  Kelas kelas,
  int rank,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DetailMuridBottomSheet(
      murid: murid,
      kelas: kelas,
      rank: rank,
    ),
  );
}

class _DetailMuridBottomSheet extends StatelessWidget {
  final Murid murid;
  final Kelas kelas;
  final int rank;

  const _DetailMuridBottomSheet({
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

  String get _rankIcon {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final hasilSAW = KalkulasiService.hitungSAW(kelas.muridList, kelas.kriteria);
        final rMap = hasilSAW.rMatrix?[murid.id] ?? {};
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Siswa & Skor Akhir
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _rankBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _rankColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _rankIcon,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: rank <= 3 ? 22 : 16,
                            fontWeight: FontWeight.w800,
                            color: _rankColor,
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
                            murid.nama,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            murid.nis != null && murid.nis!.isNotEmpty
                                ? 'NIS: ${murid.nis} • Peringkat #$rank'
                                : 'Peringkat #$rank di ${kelas.nama}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D252B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SKOR FINAL',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            murid.skorFinal?.toStringAsFixed(2) ?? '-',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Scrollable breakdown content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.analytics_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rincian Evaluasi & Riwayat Sesi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Menampilkan seluruh sesi tugas, jejak remedial attempt, serta akumulasi proses.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Iterate kriteria
                    ...kelas.kriteria.map((k) => _buildKriteriaBreakdown(context, k, rMap[k.id] ?? 0.0)),

                    _buildPanduanPerhitunganCard(),
                    _buildSintesisPerhitunganCard(context, rMap),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanduanPerhitunganCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Panduan Memahami Perhitungan Skor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Skor akhir siswa dihitung dari penggabungan seluruh kriteria penilaian (skala 100):',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF15803D),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          _panduanPoin(
            label: 'Bobot = Batas Poin Maksimal',
            desc: 'Bobot menentukan poin tertinggi yang bisa disumbangkan ke skor akhir (cth: Bobot 40% = maksimal menyumbang +40.00 poin jika capaian sempurna).',
          ),
          const SizedBox(height: 6),
          _panduanPoin(
            label: 'Nilai Normalisasi (0.00 – 1.00)',
            desc: 'Mengukur capaian siswa dibanding standar kelas. Angka 1.000 berarti siswa memperoleh poin maksimal penuh dari kriteria tersebut.',
          ),
          const SizedBox(height: 6),
          _panduanPoin(
            label: 'Poin Akhir = Bobot × Normalisasi',
            desc: 'Poin yang diperoleh dari setiap kriteria dihitung dan dijumlahkan menjadi Total Skor Final siswa.',
          ),
        ],
      ),
    );
  }

  Widget _panduanPoin({required String label, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4, right: 7),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: const Color(0xFF166534),
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSintesisPerhitunganCard(BuildContext context, Map<String, double> rMap) {

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D252B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D252B).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF163842),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calculate_rounded,
                    size: 20,
                    color: Color(0xFF34D399),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sintesis Perhitungan Skor Akhir',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Total Skor = Penjumlahan (Bobot × Nilai Normalisasi)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFF234E59)),
            const SizedBox(height: 14),

            // Daftar Kriteria & Kontribusinya
            ...kelas.kriteria.map((k) {
              final rij = rMap[k.id] ?? 0.0;
              final bobotPct = k.bobot * 100;
              final kontribusi = k.bobot * rij * 100;
              final isCost = k.arah == ArahKriteria.cost ||
                  k.nama.toLowerCase().contains('langgar') ||
                  k.nama.toLowerCase().contains('disiplin');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF163842).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF234E59),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  k.nama,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isCost ? const Color(0xFF7F1D1D) : const Color(0xFF064E3B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCost ? 'Cost' : 'Benefit',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCost ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bobot: ${bobotPct.toInt()} • ${rij.toStringAsFixed(3)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${kontribusi.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF34D399),
                          ),
                        ),
                        Text(
                          '${bobotPct.toInt()} × ${rij.toStringAsFixed(3)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 1, color: Color(0xFF234E59)),
            const SizedBox(height: 12),

            // Total Final Score Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF163842),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF34D399), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL SKOR FINAL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        'Peringkat #$rank dari ${kelas.muridList.length} siswa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFF6EE7B7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    murid.skorFinal?.toStringAsFixed(2) ?? '-',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF34D399),
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

  Widget _buildKriteriaBreakdown(BuildContext context, Kriteria k, double rij) {
    if (k.jenis == JenisKriteria.byProduct) {
      return _buildByProductBreakdown(context, k, rij);
    } else {
      return _buildByProcessBreakdown(context, k, rij);
    }
  }

  Widget _buildByProductBreakdown(BuildContext context, Kriteria k, double rij) {
    final sesiList = kelas.getSesiByKriteria(k.id);
    final semuaNilai = murid.getNilaiByKriteria(k.id);

    // Hitung per sesi HANYA untuk sesi yang valid di kriteria ini
    final Map<String, List<Nilai>> perSesi = {};
    for (final s in sesiList) {
      final list = semuaNilai.where((n) => n.sesiId == s.id).toList();
      perSesi[s.id] = list;
    }

    double sumSesiScore = 0.0;
    double sumAttempts = 0.0;
    int evaluatedSesiCount = 0;

    for (final s in sesiList) {
      final list = perSesi[s.id] ?? [];
      if (list.isEmpty) continue;
      evaluatedSesiCount++;
      list.sort((a, b) => a.attempt.compareTo(b.attempt));
      if (k.aggregationRule == AggregationRule.average) {
        sumSesiScore += list.fold(0.0, (s, n) => s + n.nilai) / list.length;
      } else if (k.aggregationRule == AggregationRule.min) {
        sumSesiScore += list.map((e) => e.nilai).reduce(min);
      } else {
        sumSesiScore += list.map((e) => e.nilai).reduce(max);
      }
      final maxAtt = list.map((e) => e.attempt).reduce(max);
      sumAttempts += maxAtt;
    }

    final avgScore = evaluatedSesiCount > 0 ? sumSesiScore / evaluatedSesiCount : 0.0;
    final avgAttempt =
        evaluatedSesiCount > 0 ? sumAttempts / evaluatedSesiCount : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kriteria
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              k.nama,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'By Product',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0369A1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              'Benefit ↑',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bobot AHP: ${(k.bobot * 100).toStringAsFixed(1)}% • Sifat: Benefit (Menguntungkan) • Aturan: ${k.aggregationRule.label}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // List Sesi
          if (sesiList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Belum ada sesi tugas/ujian untuk kriteria ini.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...sesiList.map((s) {
              final entries = perSesi[s.id] ?? [];
              entries.sort((a, b) => a.attempt.compareTo(b.attempt));

              final double resolvedNilai;
              if (entries.isEmpty) {
                resolvedNilai = 0.0;
              } else if (k.aggregationRule == AggregationRule.average) {
                resolvedNilai =
                    entries.fold(0.0, (sum, n) => sum + n.nilai) /
                    entries.length;
              } else if (k.aggregationRule == AggregationRule.min) {
                resolvedNilai = entries.map((e) => e.nilai).reduce(min);
              } else {
                resolvedNilai = entries.map((e) => e.nilai).reduce(max);
              }

              final maxAtt = entries.isNotEmpty
                  ? entries.map((e) => e.attempt).reduce(max)
                  : 1;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s.nama,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (entries.isEmpty)
                          Text(
                            'Belum dinilai',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Text(
                            resolvedNilai.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    if (entries.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (maxAtt <= 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Text(
                                '✓ 1x Attempt (Tuntas langsung)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            )
                          else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFED7AA),
                                ),
                              ),
                              child: Text(
                                '🔄 ${maxAtt}x Attempt (Ada Remedial)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFC2410C),
                                ),
                              ),
                            ),
                            ...entries.map((e) {
                              final isBest = e.nilai == resolvedNilai;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isBest
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isBest
                                        ? const Color(0xFFBFDBFE)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  'Att ${e.attempt}: ${e.nilai.toStringAsFixed(0)}${isBest ? " ★" : ""}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: isBest
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isBest
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),

          // Footer Rata-rata Kriteria
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rata-rata Nilai (${sesiList.length} sesi):',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    Text(
                      avgScore.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rerata Percobaan (Attempt):',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: avgAttempt > 1.0 ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: avgAttempt > 1.0 ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Text(
                        '${avgAttempt.toStringAsFixed(1)}x Attempt ${avgAttempt > 1.0 ? "(Ada Remedial)" : "(Tuntas Langsung)"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: avgAttempt > 1.0 ? const Color(0xFFC2410C) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                if (avgAttempt > 1.0) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calculate_outlined,
                              size: 15,
                              color: Color(0xFFC2410C),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Rincian Penalti Remedial (Metode SAW):',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC2410C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• Nilai Asli (Murni): ${avgScore.toStringAsFixed(1)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '• Pengali Remedial: 1.0 ÷ ${avgAttempt.toStringAsFixed(1)} = ${(1.0 / avgAttempt).toStringAsFixed(2)} (${((1.0 / avgAttempt) * 100).toStringAsFixed(0)}%)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nilai Efektif Setelah Penalti:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB91C1C),
                                ),
                              ),
                              Text(
                                '${(avgScore * (1.0 / avgAttempt)).toStringAsFixed(1)} Poin',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Keterangan: Nilai tugas yang diperhitungkan ke dalam Skor Final setara dengan ${(avgScore * (1.0 / avgAttempt)).toStringAsFixed(1)} (terpotong ${(avgScore - (avgScore * (1.0 / avgAttempt))).toStringAsFixed(1)} poin karena remedi).',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      '✓ Tuntas sekali coba (1.0x attempt): Meraih preferensi tugas penuh (100% tanpa penalti remedial).',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nilai Normalisasi (r_ij):',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showDetailNormalisasiDialog(
                        context: context,
                        k: k,
                        rij: rij,
                        nilaiSiswa: avgScore,
                        attemptSiswa: avgAttempt,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rij.toStringAsFixed(3),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.help_outline_rounded, size: 13, color: Color(0xFF15803D)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildByProcessBreakdown(BuildContext context, Kriteria k, double rij) {
    final semuaNilai = murid.getNilaiByKriteria(k.id);
    final frek = semuaNilai.where((n) => n.nilai > 0).length;

    final isCost = k.arah == ArahKriteria.cost ||
        k.nama.toLowerCase().contains('langgar') ||
        k.nama.toLowerCase().contains('disiplin');

    final isAttendance = k.inputType == InputType.attendance ||
        k.nama.toLowerCase().contains('hadir') ||
        k.nama.toLowerCase().contains('absen');
    double poinAgregasi = 0.0;
    if (semuaNilai.isNotEmpty) {
      if (k.aggregationRule == AggregationRule.average) {
        final active = semuaNilai.where((n) => n.nilai > 0).toList();
        poinAgregasi = active.isEmpty
            ? 0.0
            : active.fold(0.0, (sum, n) => sum + n.nilai) / active.length;
      } else if (k.aggregationRule == AggregationRule.min) {
        final active = semuaNilai.where((n) => n.nilai > 0).toList();
        poinAgregasi = active.isEmpty
            ? 0.0
            : active.map((n) => n.nilai).reduce(min);
      } else {
        poinAgregasi = semuaNilai.map((n) => n.nilai).reduce(max);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              k.nama,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Proses KBM',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCost ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCost ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Text(
                              isCost ? 'Cost (Merugikan / Deduksi) ↓' : 'Benefit (Menguntungkan) ↑',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isCost ? const Color(0xFFDC2626) : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bobot AHP: ${(k.bobot * 100).toStringAsFixed(1)}% • Sifat: ${isCost ? "Cost (Penalti Deduksi)" : "Benefit (Menguntungkan)"} • Aturan: ${k.aggregationRule.label}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCost) ...[
                        Text(
                          'Catatan ${k.nama}: ${poinAgregasi.toStringAsFixed(1)} Poin',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: poinAgregasi > 0 ? const Color(0xFFB91C1C) : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          frek > 0
                              ? 'Tercatat $frek kali • Sifat Cost: Poin catatan ini menjadi deduksi penalti yang menurunkan skor perankingan.'
                              : '0 kali tercatat • Bersih dari catatan ${k.nama}, mendapatkan preferensi maksimal (tanpa deduksi).',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: frek > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          isAttendance
                              ? 'Total Presensi: ${semuaNilai.fold(0.0, (s, n) => s + n.nilai).toStringAsFixed(0)}'
                              : 'Catatan ${k.nama}: ${poinAgregasi.toStringAsFixed(1)} Poin',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAttendance
                              ? 'Presensi kehadiran selama proses KBM berjalan'
                              : 'Tercatat $frek kali • Sifat Benefit: Poin catatan ini menambah preferensi skor perankingan (${k.aggregationRule.label}).',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF059669),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isCost
                        ? (poinAgregasi > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5))
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCost
                          ? (poinAgregasi > 0 ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0))
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Text(
                    isCost
                        ? (poinAgregasi > 0
                            ? '-${poinAgregasi.toStringAsFixed(1)} Poin'
                            : '0 Poin (Aman)')
                        : (isAttendance
                            ? '+${semuaNilai.fold(0.0, (s, n) => s + n.nilai).toStringAsFixed(0)}'
                            : '+${poinAgregasi.toStringAsFixed(1)} Poin'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isCost
                          ? (poinAgregasi > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669))
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nilai Normalisasi (r_ij):',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                InkWell(
                  onTap: () => _showDetailNormalisasiDialog(
                    context: context,
                    k: k,
                    rij: rij,
                    nilaiSiswa: poinAgregasi,
                    attemptSiswa: 1.0,
                    frekSiswa: frek,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rij.toStringAsFixed(3),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.help_outline_rounded, size: 13, color: Color(0xFF15803D)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailNormalisasiDialog({
    required BuildContext context,
    required Kriteria k,
    required double rij,
    required double nilaiSiswa,
    required double attemptSiswa,
    int frekSiswa = 0,
  }) {
    final isCost = k.arah == ArahKriteria.cost ||
        k.nama.toLowerCase().contains('langgar') ||
        k.nama.toLowerCase().contains('disiplin');
    final isProduct = k.jenis == JenisKriteria.byProduct;

    // Hitung pembanding kelas
    double maxKelas = 0.0;
    if (isProduct) {
      for (final m in kelas.muridList) {
        final entries = m.getNilaiByKriteria(k.id);
        if (entries.isNotEmpty) {
          final avg = entries.fold(0.0, (s, n) => s + n.nilai) / entries.length;
          if (avg > maxKelas) maxKelas = avg;
        }
      }
    } else {
      for (final m in kelas.muridList) {
        final entries = m.getNilaiByKriteria(k.id);
        if (entries.isNotEmpty) {
          final p = entries.map((e) => e.nilai).reduce(max);
          if (p > maxKelas) maxKelas = p;
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asal Nilai Normalisasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    k.nama,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Data Siswa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Data Performa ${murid.nama}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _dialogRow('Nilai Capaian Siswa', '${nilaiSiswa.toStringAsFixed(1)} Poin'),
                      if (isProduct && attemptSiswa > 1.0)
                        _dialogRow('Percobaan (Attempt)', '${attemptSiswa.toStringAsFixed(1)}x (Ada Remedial)'),
                      if (!isProduct && frekSiswa > 0)
                        _dialogRow('Frekuensi Tercatat', '$frekSiswa kali'),
                      _dialogRow('Nilai Tertinggi Kelas', '${maxKelas > 0 ? maxKelas.toStringAsFixed(1) : "-"} Poin'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Rumus Normalisasi SAW
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Cara Menghitung Normalisasi (SAW)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCost
                            ? 'Karena sifat kriteria ini adalah Cost (Merugikan), siswa yang paling sedikit/nol pelanggaran akan meraih nilai normalisasi tertinggi (1.000 / tanpa potongan).'
                            : (isProduct && attemptSiswa > 1.0
                                ? 'Rumus Benefit dengan Penalti Remedial: Nilai siswa (${nilaiSiswa.toStringAsFixed(1)}) dibanding nilai tertinggi kelas (${maxKelas.toStringAsFixed(1)}) disesuaikan dengan faktor percobaan attempt.'
                                : (frekSiswa > 0
                                    ? 'Rumus Benefit Partisipasi: Menggabungkan Normalisasi Poin (${nilaiSiswa.toStringAsFixed(1)} dibanding maks ${maxKelas.toStringAsFixed(1)}) dan Normalisasi Frekuensi ($frekSiswa kali aktif). Siswa yang lebih sering aktif mendapat apresiasi tambahan dari frekuensi.'
                                    : 'Rumus Benefit: Nilai siswa (${nilaiSiswa.toStringAsFixed(1)}) dibagi dengan Nilai Tertinggi di kelas (${maxKelas.toStringAsFixed(1)}).')),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF166534),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hasil Normalisasi (r_ij):',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF166534),
                              ),
                            ),
                            Text(
                              rij.toStringAsFixed(3),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Kontribusi ke Skor Akhir
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sumbangan ke Skor Akhir:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Bobot ${(k.bobot * 100).toStringAsFixed(1)}% × ${rij.toStringAsFixed(3)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '+${(k.bobot * rij * 100).toStringAsFixed(2)} Poin',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Tutup',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}