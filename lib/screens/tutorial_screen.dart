import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'assistant/scorify_assistant_screen.dart';

class TutorialScreen extends StatefulWidget {
  final int initialCategoryIndex;
  const TutorialScreen({super.key, this.initialCategoryIndex = 0});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late int _selectedCategoryIndex;
  final Set<int> _expandedQnaIndices = {0};

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex;
  }

  final List<String> _categories = [
    'Semua',
    'Alur KBM',
    'Kriteria',
    'Pembobotan Kriteria',
    'Input Nilai',
    'Excel',
    'FAQ (Tanya Jawab)',
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 48),
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
                      const SizedBox(height: 14),
                      _buildWorkflowCard(),
                      const SizedBox(height: 28),
                    ],

                    // 2. Kriteria & Karakteristiknya
                    if (_selectedCategoryIndex == 0 ||
                        _selectedCategoryIndex == 2) ...[
                      _buildSectionHeader(
                        badgeNumber: '02',
                        title: 'Memahami Jenis Kriteria & Remedial',
                        subtitle: 'Kategori kriteria proses KBM, tugas/ujian, dan aturan nilai remedial',
                        icon: Icons.tune_rounded,
                        accentColor: const Color(0xFF0D9488),
                      ),
                      const SizedBox(height: 14),
                      _buildKriteriaGuideCard(),
                      const SizedBox(height: 28),
                    ],

                    // 3. Pembobotan Model Vertikal
                    if (_selectedCategoryIndex == 0 ||
                        _selectedCategoryIndex == 3) ...[
                      _buildSectionHeader(
                        badgeNumber: '03',
                        title: 'Pembobotan Prioritas Kriteria',
                        subtitle: 'Penentuan tingkat kepentingan antar-kriteria secara berpasangan dari atas ke bawah',
                        icon: Icons.balance_rounded,
                        accentColor: const Color(0xFFD97706),
                      ),
                    const SizedBox(height: 14),
                    _buildAhpGuideCard(),
                    const SizedBox(height: 28),
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
                    const SizedBox(height: 14),
                    _buildInputKolektifGuideCard(),
                    const SizedBox(height: 28),
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
                    const SizedBox(height: 14),
                    _buildExcelGuideCard(),
                    const SizedBox(height: 28),
                  ],

                  // 6. Tanya Jawab & Mekanisme Penilaian (FAQ)
                  if (_selectedCategoryIndex == 0 ||
                      _selectedCategoryIndex == 6) ...[
                    _buildSectionHeader(
                      badgeNumber: '06',
                      title: 'Tanya Jawab & Mekanisme (FAQ)',
                      subtitle: 'Pertanyaan umum mekanisme penilaian. Ketuk pertanyaan untuk melihat penjelasan lengkap',
                      icon: Icons.question_answer_rounded,
                      accentColor: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(height: 14),
                    _buildQnAGuideCard(),
                    const SizedBox(height: 28),
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              'Tutorial & Petunjuk KBM',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
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
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '6 Topik',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
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
                    padding: const EdgeInsets.all(16),
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
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
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
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sistem Penilaian & Perankingan Cerdas',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kombinasi pembobotan prioritas kriteria dan perankingan otomatis untuk evaluasi siswa yang adil dan objektif.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13.5,
                                  height: 1.45,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                    horizontal: 16,
                    vertical: 8.5,
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
                      fontSize: 13.5,
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(icon, size: 23, color: accentColor),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'MODUL $badgeNumber',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _buildStepRow(
            stepNumber: '1',
            stepColor: const Color(0xFF0D9488),
            title: 'Buat Kelas & Kriteria Penilaian',
            desc:
                'Buat kelas baru dan tentukan 3–7 kriteria penilaian. Anda dapat menekan "Muat Kriteria Bawaan" untuk langsung mengisi 3 kriteria awal (Kehadiran, Keaktifan, Tugas).',
            isLast: false,
          ),
          _buildStepRow(
            stepNumber: '2',
            stepColor: const Color(0xFFD97706),
            title: 'Tentukan Prioritas & Bobot Kriteria',
            desc:
                'Bandingkan kriteria secara berpasangan dari atas ke bawah menggunakan kalimat pembanding yang mudah dipahami. Pastikan indikator konsistensi berwarna hijau.',
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
            title: 'Perankingan Otomatis',
            desc:
                'Tekan "Hitung Nilai Akhir" untuk melihat perankingan otomatis siswa yang objektif, podium 3 besar, rincian evaluasi, serta ekspor ke file Excel.',
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
              width: 34,
              height: 34,
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: 56,
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
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.48,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // 1. Range Nilai (0-100) Friendly Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mengapa Menggunakan Skala 0–100?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Semua penilaian di Scorify distandardisasi ke skala puluhan (0–100) agar perbandingan antar-kriteria tetap seimbang, adil, dan akurat saat digabungkan. Standar umum: 100 = Sempurna, 75 = Tuntas / Cukup, 0 = Belum Ada Poin.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF14532D),
                          height: 1.48,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildKriteriaPillItem(
            badge: 'Proses KBM',
            badgeColor: const Color(0xFF0D9488),
            title: 'Keaktifan Siswa',
            desc:
                'Penilaian keikutsertaan siswa di kelas (bertanya, menjawab, diskusi). Poin dapat diakumulasikan setiap kali siswa berpartisipasi aktif.',
            icon: Icons.add_reaction_rounded,
          ),
          const SizedBox(height: 12),
          _buildKriteriaPillItem(
            badge: 'Proses KBM',
            badgeColor: const Color(0xFF2563EB),
            title: 'Presensi / Kehadiran',
            desc:
                'Pencatatan kehadiran harian dengan opsi cepat terstandar (Hadir = 100, Izin = 75, Sakit = 50, Alpha = 0) untuk kemudahan guru.',
            icon: Icons.event_available_rounded,
          ),
          const SizedBox(height: 12),
          _buildKriteriaPillItem(
            badge: 'Hasil / Produk',
            badgeColor: const Color(0xFF4F46E5),
            title: 'Tugas, Kuis, UTS, & UAS',
            desc:
                'Penilaian berbasis hasil luaran belajar. Setiap tugas atau ujian dapat dibuatkan sesinya dan mendukung pencatatan nilai perbaikan (remedial).',
            icon: Icons.assignment_rounded,
          ),
          const SizedBox(height: 14),

          // 4. Mekanisme & Aturan Remedial (Yang Ditanyakan Guru)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Mekanisme Remedial',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aturan Nilai Remedial & Percobaan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ketika siswa memiliki beberapa catatan nilai (pengulangan/remedial pada kriteria Produk atau catatan keaktifan pada kriteria Proses), Scorify menyediakan 3 pilihan aturan penentuan skor:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF78350F),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Banner Otomatisasi Remedial Aktif (By Code)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 21,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Otomatisasi Remedial Aktif (By Code)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF166534),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Guru tidak perlu mengeset tombol atau kriteria remedial terpisah. Setiap kali siswa mengulang/memperbaiki tugas pada kriteria By Product, sistem otomatis menghitung variabel percobaan (attempt) sebagai penalti efisiensi di latar belakang.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF14532D),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Tiga Opsi: Max vs Average vs Min
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⭐ Max',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Skor tertinggi siswa (Cth: awal 50, remedi 85 → 85).',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📊 Rata-rata',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rerata seluruh attempt (Cth: awal 50, remedi 80 → 65).',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📉 Min',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Skor terendah siswa yang diambil sistem.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Catatan Keadilan Percobaan (Attempt)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 18, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keadilan Sistem: Berapa kali siswa menempuh remedial (attempt) otomatis dicatat. Siswa yang langsung tuntas pada tes pertama tetap mendapat apresiasi peringkat lebih unggul secara adil.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                            height: 1.42,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Direction Guide: Benefit vs Cost
          Container(
            padding: const EdgeInsets.all(14),
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
                      size: 20,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sifat Kriteria (Benefit vs Cost):',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '📈 BENEFIT\nNilai tinggi = Makin Bagus\n(Semua Kriteria di atas)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF065F46),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '📉 COST\nNilai rendah = Makin Bagus\n(Cth: Frekuensi Remedial)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                            height: 1.4,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 22),
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
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Format Pairwise Comparison Vertikal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Scorify merombak matriks horizontal AHP yang biasanya lebar menjadi kartu perbandingan vertikal ke bawah, sehingga sangat nyaman digunakan di layar smartphone.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.48,
            ),
          ),
          const SizedBox(height: 16),

          // Skala Saaty Card (Kuning)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
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
                      size: 20,
                      color: Color(0xFF92400E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tingkat Prioritas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistem Scorify menggunakan tingkatan pilihan yang ramah untuk memudahkan Anda membandingkan antar kriteria:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF78350F),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Sama pentingnya: Keduanya seimbang (1).', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF78350F), height: 1.45)),
                      const SizedBox(height: 5),
                      Text('• Cukup lebih penting: Sedikit condong ke satu sisi (3).', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF78350F), height: 1.45)),
                      const SizedBox(height: 5),
                      Text('• Jauh lebih penting: Prioritasnya sudah terasa bedanya (5).', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF78350F), height: 1.45)),
                      const SizedBox(height: 5),
                      Text('• Sangat jauh lebih penting: Sangat diutamakan dibanding lawannya (7).', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF78350F), height: 1.45)),
                      const SizedBox(height: 5),
                      Text('• Mutlak paling penting: Prioritas tertinggi, mutlak dibanding lawannya (9).', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF78350F), height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Skenario Konsisten (Hijau)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 21,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contoh Penilaian yang Selaras (Aman)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Misalkan Anda menilai prioritas antara Tugas, UTS, dan UAS.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF14532D),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Jika UAS lebih penting dari UTS...', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF14532D), height: 1.45)),
                      const SizedBox(height: 5),
                      Text('• Dan UTS lebih penting dari Tugas...', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF14532D), height: 1.45)),
                      const SizedBox(height: 5),
                      Text('• Maka wajarnya, UAS harus jauh lebih penting dari Tugas.', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF14532D), height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hasil yang selaras dan masuk akal ini akan langsung diproses oleh sistem untuk menentukan ranking.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: const Color(0xFF14532D),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Skenario Inkonsistensi (Merah)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      size: 21,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kenapa Muncul Peringatan Merah?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Peringatan merah muncul jika pilihan Anda berputar dan saling bertabrakan seperti permainan batu-gunting-kertas.\nContoh logika yang salah:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF991B1B),
                    height: 1.48,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Anda menilai Keaktifan lebih penting dari Kehadiran.', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B), height: 1.45)),
                      const SizedBox(height: 5),
                      Text('2. Anda menilai Kehadiran lebih penting dari Tugas.', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B), height: 1.45)),
                      const SizedBox(height: 5),
                      Text('3. Tapi anehnya, Anda malah menilai Tugas jauh lebih penting dari Keaktifan!', style: GoogleFonts.plusJakartaSans(fontSize: 13.8, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C), height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Logika yang membingungkan ini membuat sistem tidak bisa menghitung, sehingga Anda akan diminta untuk menyelaraskan ulang pilihan tersebut.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: const Color(0xFF7F1D1D),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tips Praktis Pengisian Bobot yang Bagus (Warna Netral)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      size: 21,
                      color: Color(0xFF0F766E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tips Cepat Mengisi Penilaian',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '• Tentukan Patokan (Anchor): Sebelum mulai memilih, tentukan satu kriteria yang paling Anda utamakan (misal: Ujian). Gunakan kriteria itu sebagai acuan saat membandingkannya dengan yang lain.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.8, color: const Color(0xFF334155), height: 1.48),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Jaga Urutan: Pastikan pilihan Anda sejurus dari awal sampai akhir.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.8, color: const Color(0xFF334155), height: 1.48),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Hati-hati dengan Pilihan "Mutlak": Gunakan pilihan "Mutlak lebih penting" hanya jika kriteria tersebut benar-benar tidak tertandingi oleh lawannya. Untuk perbandingan biasa, gunakan tingkat prioritas di bawahnya.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.8, color: const Color(0xFF334155), height: 1.48),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Penjelasan Sistem Saran (Biru)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_rounded,
                      size: 21,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dari Mana Datangnya Fitur Saran?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistem Scorify tidak menebak secara acak. Jika ada peringatan merah, sistem akan membaca keseluruhan pola jawaban Anda sebelumnya. Dari situ, sistem mendeteksi bagian mana yang paling melenceng dan memberikan saran perbaikan yang paling mendekati niat awal Anda.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF1E3A8A),
                    height: 1.48,
                  ),
                ),
              ],
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
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
          _buildFeatureCardItem(
            icon: Icons.history_toggle_off_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            title: 'Deteksi Presensi Dobel dengan Jam',
            desc:
                'Jika presensi siswa sudah pernah dicatat pada hari ini, sistem otomatis menampilkan dialog konfirmasi lengkap dengan waktu pencatatan (mis. 07:45 WIB) agar data tidak tertimpa tanpa sengaja.',
          ),
          const SizedBox(height: 14),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.48,
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
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
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
          // Banner Chatbot Asisten Scorify (Offline)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Punya Pertanyaan Lain?',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tanya langsung ke Asisten Scorify (Offline & Cepat)',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScorifyAssistantScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Text(
                    'Tanya Bot',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Q1: Kehadiran & Kategori Nilai
          _buildQnaItem(
            index: 0,
            tag: 'Kehadiran & Absensi',
            tagColor: const Color(0xFF10B981),
            question: 'Bagaimana mekanisme & format pengisian nilai kriteria Kehadiran?',
            answer:
                'Scorify kini menyediakan fitur Kategori Pilihan Cepat (Hadir, Izin, Sakit, Alpha) untuk mencegah salah ketik manual saat input harian:\n\n'
                '• Pilihan Standar Fleksibel: Guru bebas menentukan skor untuk setiap status (misal Hadir = 100, Izin = 75, Sakit = 50, Alpha = 0) saat pembuatan kriteria kelas.\n'
                '• Input Sekali Ketuk: Saat presensi, guru cukup mengetuk chip opsi (misal Hadir) tanpa perlu mengetik angka manual di setiap pertemuan, meminimalkan risiko human error.\n'
                '• Konsistensi Data: Nilai kehadiran otomatis terstandar dan aman diproses dalam normalisasi SAW.\n'
                '• Tetap Fleksibel: Jika kriteria tidak menggunakan kategori, guru tetap dapat memasukkan persentase (0–100) atau akumulasi hari secara manual.',
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

          // Q3: Aturan Kriteria Induk vs Sub-Kriteria (Tugas, UTS, UAS)
          _buildQnaItem(
            index: 2,
            tag: 'Tugas, UTS & UAS',
            tagColor: const Color(0xFF2563EB),
            question: 'Bagaimana aturan menyusun Kriteria Induk dan Sub-Kriteria (Tugas, UTS, UAS)?',
            answer:
                'Dalam metode SPK (AHP & SAW), Kriteria Induk dan Sub-Kriteria memiliki fungsi berjenjang yang WAJIB sejenis (satu domain):\n\n'
                '1. Kriteria Induk Wajib Mandiri (TUGAS, UTS, UAS):\n'
                '   Setiap instrumen evaluasi utama (seperti TUGAS, UTS, dan UAS) memiliki bobot dan tingkat kesulitan yang berbeda. Oleh karena itu, masing-masing wajib dijadikan Kriteria Induk terpisah agar dapat dibobotkan secara adil melalui perbandingan berpasangan AHP.\n\n'
                '2. Sub-Kriteria Wajib Sejenis dengan Kriteria Induknya:\n'
                '   Sub-kriteria digunakan untuk merinci pelaksanaan atau sesi di dalam kriteria induk tersebut, contohnya:\n'
                '   • Jika Kriteria Induk = TUGAS: Sub-kriterianya bisa berupa "Tugas 1", "Tugas 2", "Tugas Individu", atau "Tugas Kelompok".\n'
                '   • Jika Kriteria Induk = UTS: Sub-kriterianya bisa berupa "UTS Individu", "UTS Kelompok", atau "UTS Bab 1", "UTS Bab 2".\n'
                '   • Jika Kriteria Induk = UAS: Sub-kriterianya bisa berupa "UAS Individu", "UAS Kelompok", atau "UAS Teori", "UAS Proyek".\n\n'
                '3. ⚠️ Larangan Pencampuran:\n'
                '   TIDAK DIPERBOLEHKAN mencampur ujian ke dalam sub-kriteria tugas (contoh keliru: Kriteria Induk "TUGAS" diisi sub-kriteria "Tugas 1, Tugas 2, UTS, UAS"). Jika ada ujian, buatlah kriteria induk "UTS" atau "UAS" secara terpisah.',
          ),

          // Q4: Remedial Otomatis
          _buildQnaItem(
            index: 3,
            tag: 'Remedial Otomatis',
            tagColor: const Color(0xFFD97706),
            question: 'Bagaimana cara kerja kriteria Frekuensi Remedial yang otomatis?',
            answer:
                'Anda tidak perlu membuat kriteria remedial terpisah di AHP!\n\nRemedial dicatat langsung melalui variabel attempt pada setiap kriteria By Product. Siswa yang tuntas pada percobaan pertama (attempt = 1) memperoleh nilai utuh (1.0), sedangkan siswa yang berkali-kali remedial otomatis dikenakan penalti Cost secara matematis.',
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
                'Bisa, nilai siswa sangat fleksibel dan dapat diubah kapan saja:\n• Melalui kartu siswa di halaman Detail Kelas (ketuk nilai atau tombol edit).\n• Melalui fitur Input Kolektif.\n• Melalui tab Tugas & Tes (By Product).\n\nSetiap kali ada nilai yang diperbarui, Anda cukup menekan tombol "Hitung Perangkingan" untuk mendapatkan hasil kalkulasi terbaru secara instan.',
          ),

          // Q7: Login Google vs Password Manual
          _buildQnaItem(
            index: 6,
            tag: 'Akun & Password',
            tagColor: const Color(0xFF4F46E5),
            question:
                'Saya mendaftar via tombol "Login with Google", apakah bisa masuk manual lewat Email & Kata Sandi?',
            answer:
                'Bisa! Akun Anda dapat ditautkan dengan kata sandi secara instan tanpa merusak data akun:\n\n'
                '1. Masuk ke aplikasi menggunakan tombol "Login with Google" (sekali klik).\n'
                '2. Buka menu Profil di pojok atas, lalu gulir ke bagian "Buat Kata Sandi Akun".\n'
                '3. Masukkan kata sandi baru Anda dan ketuk "Simpan & Buat Kata Sandi".\n\n'
                'Setelah selesai, akun Anda memiliki 2 pintu masuk: Anda bisa masuk instan lewat tombol "Login with Google", ataupun mengetikkan email & kata sandi secara manual.',
          ),

          // Q8: Keamanan Data saat Ganti Email
          _buildQnaItem(
            index: 7,
            tag: 'Keamanan Data Akun',
            tagColor: const Color(0xFF0284C7),
            question:
                'Apakah data kelas, siswa, dan nilai saya tetap aman jika email akun diubah?',
            answer:
                'Ya, 100% aman!\n\n'
                'Seluruh data kelas, kriteria bobot, murid, dan riwayat nilai Anda di Scorify tersimpan berdasarkan ID Pengguna (User ID) unik akun Anda, bukan semata-mata pada teks emailnya.\n\n'
                'Saat Anda memperbarui email atau menambahkan kata sandi pada akun yang sama, ID Pengguna Anda tidak berubah sama sekali. Seluruh data kelas dan nilai tetap utuh dan langsung muncul seperti semula.',
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
      margin: const EdgeInsets.only(bottom: 12),
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
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: tagColor,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                question,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                answer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  color: const Color(0xFF334155),
                  height: 1.6,
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
      padding: const EdgeInsets.all(18),
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
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siap Memulai KBM?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kembali ke dashboard untuk membuat kelas baru dan mulai menginput nilai siswa.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.45,
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
