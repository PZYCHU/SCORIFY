import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _selectedCategoryIndex = 0;
  final Set<int> _expandedQnaIndices = {0};

  final List<String> _categories = [
    'Semua',
    'Alur KBM',
    'Kriteria',
    'AHP Saaty',
    'Input Nilai',
    'Excel',
    'Tanya Jawab (Q&A)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F1), // Sage surface Scorify
      body: Column(
        children: [
          _buildHeroHeader(context),
          _buildCategoryFilter(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Alur Kerja Utama (Workflow)
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 1) ...[
                    _buildSectionHeader(
                      badgeNumber: '01',
                      title: 'Alur Kerja Aplikasi (Workflow)',
                      subtitle: '4 tahapan utama penilaian dari awal hingga perankingan',
                      icon: Icons.alt_route_rounded,
                      accentColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 12),
                    _buildWorkflowCard(),
                    const SizedBox(height: 24),
                  ],

                  // 2. Kriteria & Karakteristiknya
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 2) ...[
                    _buildSectionHeader(
                      badgeNumber: '02',
                      title: 'Memahami Jenis Kriteria',
                      subtitle: 'Kategori kriteria performa, sesi hasil, dan remedial',
                      icon: Icons.tune_rounded,
                      accentColor: const Color(0xFF0D9488),
                    ),
                    const SizedBox(height: 12),
                    _buildKriteriaGuideCard(),
                    const SizedBox(height: 24),
                  ],

                  // 3. Pembobotan AHP Model Vertikal
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 3) ...[
                    _buildSectionHeader(
                      badgeNumber: '03',
                      title: 'Pembobotan AHP Vertikal (Saaty)',
                      subtitle: 'Perbandingan kriteria berpasangan tanpa matriks tabel lebar',
                      icon: Icons.balance_rounded,
                      accentColor: const Color(0xFFD97706),
                    ),
                    const SizedBox(height: 12),
                    _buildAhpGuideCard(),
                    const SizedBox(height: 24),
                  ],

                  // 4. Fitur Input Kolektif & Deteksi Presensi
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 4) ...[
                    _buildSectionHeader(
                      badgeNumber: '04',
                      title: 'Input Kolektif & Pengaman Presensi',
                      subtitle: 'Beri nilai ke banyak siswa sekaligus dan proteksi jam presensi',
                      icon: Icons.checklist_rounded,
                      accentColor: const Color(0xFF16A34A),
                    ),
                    const SizedBox(height: 12),
                    _buildInputKolektifGuideCard(),
                    const SizedBox(height: 24),
                  ],

                  // 5. Panduan Import & Export Excel
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 5) ...[
                    _buildSectionHeader(
                      badgeNumber: '05',
                      title: 'Import & Unduh File Excel',
                      subtitle: 'Template data siswa dan ekspor laporan nilai akhir',
                      icon: Icons.table_chart_outlined,
                      accentColor: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    _buildExcelGuideCard(),
                    const SizedBox(height: 24),
                  ],

                  // 6. Tanya Jawab & Mekanisme Penilaian (Q&A)
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 6) ...[
                    _buildSectionHeader(
                      badgeNumber: '06',
                      title: 'Tanya Jawab & Mekanisme (Q&A)',
                      subtitle: 'Pertanyaan umum seputar mekanisme kehadiran, benefit/cost, dan pembobotan',
                      icon: Icons.help_outline_rounded,
                      accentColor: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(height: 12),
                    _buildQnAGuideCard(),
                    const SizedBox(height: 24),
                  ],

                  // Help Footer Banner
                  _buildHelpFooterBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO HEADER ─────────────────────────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D252B), Color(0xFF163842), Color(0xFF1B4B5A)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Ambient Glow Orbs
          Positioned(
            top: -35,
            right: -25,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Top Bar
                  Row(
                    children: [
                      // Back Button Frosted Glass
                      Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PANDUAN PENGGUNA',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              'Tutorial & Petunjuk KBM',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_stories_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '6 Topik',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hero Intro Banner Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sistem Penilaian SPK Modern',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kombinasi Pembobotan AHP vertikal dan Perankingan SAW otomatis untuk hasil yang objektif.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // ─── CATEGORY FILTER BAR ───────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_categories.length, (index) {
            final isSelected = _selectedCategoryIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedCategoryIndex = index),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF163842) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isSelected ? 0.12 : 0.03,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _categories[index],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── SECTION HEADER ────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String badgeNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(icon, size: 20, color: accentColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MODUL $badgeNumber',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 1. WORKFLOW CARD ──────────────────────────────────────────────────────

  Widget _buildWorkflowCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStepRow(
            stepNumber: '1',
            stepColor: const Color(0xFF0D9488),
            title: 'Buat Kelas & Kriteria Penilaian',
            desc:
                'Buat kelas baru dan tentukan 3–7 kriteria penilaian. Anda dapat menekan "Muat Default" untuk langsung mengisi 4 kriteria baku sekolah.',
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: '2',
            stepColor: const Color(0xFFD97706),
            title: 'Tentukan Bobot via AHP Vertikal',
            desc:
                'Bandingkan kriteria secara berpasangan dari atas ke bawah menggunakan kalimat verbal Saaty. Pastikan Rasio Konsistensi (CR) < 0.10.',
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: '3',
            stepColor: const Color(0xFF2563EB),
            title: 'Input Nilai Siswa (Harian & Tugas)',
            desc:
                'Catat nilai harian (presensi & keaktifan) atau buat sesi tugas/ujian. Gunakan fitur "Nilai Sekaligus" untuk memberi nilai ke banyak siswa sekaligus.',
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: '4',
            stepColor: const Color(0xFF10B981),
            title: 'Perankingan Otomatis Metode SAW',
            desc:
                'Tekan "Hitung Nilai Akhir" untuk melihat perankingan otomatis SAW, podium 3 besar, matriks normalisasi, serta ekspor ke file Excel.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required Color stepColor,
    required String title,
    required String desc,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: stepColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  stepNumber,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      stepColor.withValues(alpha: 0.5),
                      stepColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── 2. KRITERIA GUIDE CARD ────────────────────────────────────────────────

  Widget _buildKriteriaGuideCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildKriteriaPillItem(
            badge: 'Performa Harian',
            badgeColor: const Color(0xFF0D9488),
            title: 'Presensi & Keaktifan',
            desc:
                'Penilaian rutin kelas. Dapat berupa "Nilai Angka" (0–100 seperti kehadiran) atau "Poin Tambahan" (counter poin seperti +1, +5).',
            icon: Icons.event_available_rounded,
          ),
          const SizedBox(height: 10),
          _buildKriteriaPillItem(
            badge: 'Hasil (Sesi)',
            badgeColor: const Color(0xFF4F46E5),
            title: 'Tugas, Kuis, & Ujian',
            desc:
                'Kriteria penugasan dinamis. Guru bisa membuat banyak sesi (Tugas 1, Tugas 2, UTS). Tiap sesi tugas akan dirata-rata otomatis.',
            icon: Icons.assignment_rounded,
          ),
          const SizedBox(height: 10),
          _buildKriteriaPillItem(
            badge: 'Perhitungan Otomatis',
            badgeColor: const Color(0xFFD97706),
            title: 'Frekuensi Remedial (Cost)',
            desc:
                'Dihitung otomatis oleh sistem jika siswa mengulang tugas. Tidak perlu input manual. Semakin sering remedi, semakin rendah skornya.',
            icon: Icons.replay_rounded,
          ),
          const SizedBox(height: 12),
          // Direction Guide: Benefit vs Cost
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.swap_vert_rounded,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Arah Penilaian (Benefit vs Cost):',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '📈 BENEFIT\nNilai tinggi = Lebih Bagus\n(cth: Kehadiran, Nilai Ujian)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF065F46),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '📉 COST\nNilai rendah = Lebih Bagus\n(cth: Frekuensi Remedial)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                            height: 1.3,
                          ),
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

  Widget _buildKriteriaPillItem({
    required String badge,
    required Color badgeColor,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. AHP GUIDE CARD ─────────────────────────────────────────────────────

  Widget _buildAhpGuideCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Format Pairwise Comparison Vertikal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scorify merombak matriks horizontal AHP yang biasanya lebar menjadi kartu perbandingan vertikal ke bawah, sehingga sangat nyaman digunakan di layar smartphone.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Skala Saaty Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFCD34D).withValues(alpha: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_rounded,
                      size: 16,
                      color: Color(0xFF92400E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Skala Verbal Saaty (1 – 9):',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSaatyScaleRow('1', 'Sama Penting (Setara)'),
                _buildSaatyScaleRow('3', 'Sedikit Lebih Penting'),
                _buildSaatyScaleRow('5', 'Lebih Penting / Kuat'),
                _buildSaatyScaleRow('7', 'Sangat Lebih Penting'),
                _buildSaatyScaleRow('9', 'Mutlak Lebih Penting'),
                const SizedBox(height: 4),
                Text(
                  '*Nilai 2, 4, 6, 8 adalah nilai kompromi di antaranya.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF92400E).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // CR Warning Note
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 17,
                  color: Color(0xFF0F766E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Uji Konsistensi: Rasio Konsistensi (CR) harus ≤ 0.10. Jika CR > 0.10, Scorify akan memberi peringatan agar Anda meninjau kembali perbandingan yang kurang logis.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF334155),
                      height: 1.35,
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

  Widget _buildSaatyScaleRow(String score, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF92400E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                score,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. INPUT KOLEKTIF & DETEKSI PRESENSI ───────────────────────────────────

  Widget _buildInputKolektifGuideCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFeatureCardItem(
            icon: Icons.checklist_rtl_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            title: 'Bilah Nilai Sekaligus & Search',
            desc:
                'Pilih beberapa siswa sekaligus atau gunakan "Pilih Semua", lalu beri nilai harian atau nilai tugas dalam satu kali klik konfirmasi.',
          ),
          const SizedBox(height: 12),
          _buildFeatureCardItem(
            icon: Icons.history_toggle_off_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            title: 'Deteksi Presensi Dobel dengan Jam',
            desc:
                'Jika presensi siswa sudah pernah dicatat pada hari ini, sistem otomatis menampilkan dialog konfirmasi lengkap dengan waktu pencatatan (mis. 07:45 WIB) agar data tidak tertimpa tanpa sengaja.',
          ),
          const SizedBox(height: 12),
          _buildFeatureCardItem(
            icon: Icons.touch_app_rounded,
            iconBg: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF4F46E5),
            title: 'Quick Input Tag di Kartu Siswa',
            desc:
                'Pada kartu siswa di halaman Detail Kelas, sentuh langsung tag kriteria apa pun untuk membuka modal quick input instan tanpa pindah halaman.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCardItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 5. EXCEL GUIDE CARD ───────────────────────────────────────────────────

  Widget _buildExcelGuideCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFeatureCardItem(
            icon: Icons.file_download_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            title: 'Unduh Template Siswa (.xlsx)',
            desc:
                'Gunakan tombol "Unduh Template" di halaman Import Siswa. Cukup isi Kolom A dengan NIS dan Kolom B dengan Nama Siswa.',
          ),
          const SizedBox(height: 12),
          _buildFeatureCardItem(
            icon: Icons.share_rounded,
            iconBg: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF16A34A),
            title: 'Ekspor Hasil & Bagikan Langsung',
            desc:
                'Hasil perankingan SAW dan rekap nilai per siswa dapat diekspor ke Excel dan langsung dibagikan ke WhatsApp, Google Drive, atau email via sheet sistem.',
          ),
        ],
      ),
    );
  }

  // ─── Q&A SECTION (MEKANISME PENILAIAN & KEHADIRAN) ─────────────────────────

  Widget _buildQnAGuideCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Q&A
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.question_answer_rounded,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanya Jawab Seputar Penilaian',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ketuk pertanyaan untuk melihat penjelasan lengkap',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Q1: Kehadiran
          _buildQnaItem(
            index: 0,
            tag: 'Kehadiran & Absensi',
            tagColor: const Color(0xFF10B981),
            question: 'Bagaimana mekanisme & format pengisian nilai kriteria Kehadiran?',
            answer:
                'Scorify tidak membatasi format kehadiran dengan preset kaku, karena setiap guru dan sekolah memiliki kalender dan kebijakan akademik yang berbeda.\n\nAnda bebas menggunakan format apapun yang paling nyaman bagi Anda:\n• Format Persentase (0–100%): Misalnya hadir penuh diinput 100, atau persentase kehadiran riil semester (contoh: 95, 80).\n• Format Akumulasi Hari: Misalnya siswa hadir 18 kali pertemuan diinput angka 18.\n• Format Poin Guru: Anda bebas menentukan sistem skor sendiri (misal hadir = 100, izin = 75, dsb).\n\nYang paling penting adalah KONSISTENSI: gunakan skala/format yang sama untuk seluruh siswa di kelas tersebut agar perhitungannya adil.',
          ),

          // Q2: Benefit vs Cost Kehadiran
          _buildQnaItem(
            index: 1,
            tag: 'Sifat Kriteria',
            tagColor: const Color(0xFF0D9488),
            question: 'Apakah kriteria Kehadiran bertipe Benefit atau Cost?',
            answer:
                'Kriteria Kehadiran bertipe BENEFIT (Keuntungan).\n\nArtinya, semakin tinggi nilai atau persentase yang Anda berikan kepada siswa, semakin besar kontribusinya dalam menaikkan posisi ranking siswa tersebut.\n\nSebaliknya, kriteria bertipe COST (seperti Frekuensi Remedial) memiliki aturan terbalik: semakin sering siswa remedial, semakin berkurang perolehan skor akhirnya.',
          ),

          // Q3: Sesi Tugas Majemuk
          _buildQnaItem(
            index: 2,
            tag: 'Tugas & Ulangan',
            tagColor: const Color(0xFF2563EB),
            question: 'Bagaimana jika ada banyak tugas atau ulangan dalam satu mata pelajaran?',
            answer:
                'Anda dapat membuat sesi tugas sebanyak yang dibutuhkan di dalam kriteria jenis "Hasil". Misalnya:\n• Sesi "Tugas 1: Aljabar"\n• Sesi "Tugas 2: Geometri"\n• Sesi "Ulangan Tengah Semester"\n\nSistem Scorify akan secara otomatis menghitung rata-rata dari seluruh sesi tugas tersebut menjadi satu nilai agregat kriteria saat perankingan dijalankan.',
          ),

          // Q4: Remedial Otomatis
          _buildQnaItem(
            index: 3,
            tag: 'Remedial Otomatis',
            tagColor: const Color(0xFFD97706),
            question: 'Bagaimana cara kerja kriteria Frekuensi Remedial yang otomatis?',
            answer:
                'Anda tidak perlu menghitung atau menginput frekuensi remedial secara manual!\n\nSetiap kali Anda memberikan nilai remedial kepada seorang siswa pada sesi tugas apapun, Scorify otomatis mencatat frekuensi remedial siswa tersebut. Sistem kemudian menghitungnya secara matematis sebagai kriteria Cost pada matriks perankingan.',
          ),

          // Q5: Kapan Pembobotan AHP Dilakukan?
          _buildQnaItem(
            index: 4,
            tag: 'Pembobotan AHP',
            tagColor: const Color(0xFF8B5CF6),
            question: 'Kapan waktu terbaik untuk melakukan perbandingan kriteria AHP?',
            answer:
                'Pembobotan AHP Saaty bersifat independen dari nilai siswa, sehingga Anda dapat melakukannya KAPAN SAJA:\n• Di awal semester saat menyusun silabus dan kontrak belajar.\n• Di tengah semester saat menambahkan kriteria baru.\n• Di akhir semester sebelum mencetak laporan ranking.\n\nPastikan nilai Consistency Ratio (CR) bernilai Konsisten (CR < 0.1) agar bobot penilaian Anda logis secara matematis.',
          ),

          // Q6: Koreksi Nilai
          _buildQnaItem(
            index: 5,
            tag: 'Koreksi Nilai',
            tagColor: const Color(0xFFEC4899),
            question: 'Apakah nilai yang sudah tersimpan bisa diubah jika terjadi kesalahan input?',
            answer:
                'Bisa, nilai siswa sangat fleksibel dan dapat diubah kapan saja:\n• Melalui kartu siswa di halaman Detail Kelas (ketuk nilai atau tombol edit).\n• Melalui fitur Input Kolektif.\n• Melalui halaman Detail Sesi Tugas.\n\nSetiap kali ada nilai yang diperbarui, Anda cukup menekan tombol "Hitung Perangkingan" untuk mendapatkan hasil kalkulasi terbaru secara instan.',
          ),
        ],
      ),
    );
  }

  Widget _buildQnaItem({
    required int index,
    required String tag,
    required Color tagColor,
    required String question,
    required String answer,
  }) {
    final isExpanded = _expandedQnaIndices.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFFF8FAF9) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedQnaIndices.add(index);
              } else {
                _expandedQnaIndices.remove(index);
              }
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: tagColor,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                question,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                answer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF334155),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpFooterBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163842), Color(0xFF1B4B5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163842).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siap Memulai KBM?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kembali ke dashboard untuk membuat kelas baru dan mulai menginput nilai siswa.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
