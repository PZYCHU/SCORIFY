import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TutorialScreen extends StatefulWidget {
  final int initialCategoryIndex;
  const TutorialScreen({super.key, this.initialCategoryIndex = 0});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late int _selectedCategoryIndex;
  final Set<int> _expandedQnaIndices = <int>{};
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F1), // Sage surface Scorify
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _TutorialHeaderDelegate(
              topPadding: topPadding,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Alur Kerja Utama (Workflow)
                if (_selectedCategoryIndex == 0 ||
                    _selectedCategoryIndex == 1) ...[
                  _buildSectionHeader(
                    badgeNumber: '01',
                    title: 'Alur Kerja Utama (Workflow)',
                    subtitle: '4 tahapan utama penilaian dari awal hingga perankingan',
                    icon: Icons.alt_route_rounded,
                    accentColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  _buildWorkflowCard(),
                  const SizedBox(height: 36),
                ],

                // 2. Kriteria & Karakteristiknya
                if (_selectedCategoryIndex == 0 ||
                    _selectedCategoryIndex == 2) ...[
                  _buildSectionHeader(
                    badgeNumber: '02',
                    title: 'Jenis Kriteria & Remedial',
                    subtitle: 'Kategori kriteria proses KBM, tugas/ujian, dan aturan nilai remedial',
                    icon: Icons.tune_rounded,
                    accentColor: const Color(0xFF0D9488),
                  ),
                  const SizedBox(height: 16),
                  _buildKriteriaGuideCard(),
                  const SizedBox(height: 36),
                ],

                // 3. Pembobotan Model Vertikal
                if (_selectedCategoryIndex == 0 ||
                    _selectedCategoryIndex == 3) ...[
                  _buildSectionHeader(
                    badgeNumber: '03',
                    title: 'Pembobotan Prioritas (AHP)',
                    subtitle: 'Penentuan tingkat kepentingan antar-kriteria secara berpasangan dari atas ke bawah',
                    icon: Icons.balance_rounded,
                    accentColor: const Color(0xFFD97706),
                  ),
                  const SizedBox(height: 16),
                  _buildAhpGuideCard(),
                  const SizedBox(height: 36),
                ],

                // 4. Fitur Input Kolektif & Deteksi Presensi
                if (_selectedCategoryIndex == 0 ||
                    _selectedCategoryIndex == 4) ...[
                  _buildSectionHeader(
                    badgeNumber: '04',
                    title: 'Input Kolektif & Presensi',
                    subtitle: 'Beri nilai ke banyak siswa sekaligus dan proteksi jam presensi',
                    icon: Icons.groups_rounded,
                    accentColor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 16),
                  _buildInputKolektifGuideCard(),
                  const SizedBox(height: 36),
                ],

                // 5. Panduan Import & Export Excel
                if (_selectedCategoryIndex == 0 ||
                    _selectedCategoryIndex == 5) ...[
                  _buildSectionHeader(
                    badgeNumber: '05',
                    title: 'Import & Unduh File Excel',
                    subtitle: 'Template data siswa dan ekspor laporan nilai akhir',
                    icon: Icons.table_chart_rounded,
                    accentColor: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 16),
                  _buildExcelGuideCard(),
                  const SizedBox(height: 36),
                ],

                // 6. Tanya Jawab & FAQ
                if (_selectedCategoryIndex == 0 ||
                    _selectedCategoryIndex == 6) ...[
                  _buildSectionHeader(
                    badgeNumber: '06',
                    title: 'Tanya Jawab & FAQ',
                    subtitle: 'Pertanyaan umum mekanisme penilaian. Ketuk pertanyaan untuk melihat penjelasan lengkap',
                    icon: Icons.help_center_rounded,
                    accentColor: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 16),
                  _buildQnAGuideCard(),
                  const SizedBox(height: 36),
                ],

                // Help Footer Banner
                _buildHelpFooterBanner(),
              ]),
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
                onTap: () {
                  setState(() => _selectedCategoryIndex = index);
                  if (_scrollController.hasClients && _scrollController.offset > 0) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
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
                      fontSize: 14.5,
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
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(icon, size: 21, color: accentColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'MODUL $badgeNumber',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
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
      padding: const EdgeInsets.all(20),
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
              width: 36,
              height: 36,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: 64,
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
            padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.55,
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
    return Column(
      children: [
        // ── Card 1: Kategori & Sifat Kriteria ──
        Container(
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Keaktifan Siswa
              _buildKriteriaPillItem(
                badge: 'Proses KBM',
                badgeColor: const Color(0xFF0D9488),
                title: 'Keaktifan Siswa',
                desc:
                    'Penilaian keikutsertaan siswa di kelas (bertanya, menjawab, diskusi). Poin dapat diakumulasikan setiap kali siswa berpartisipasi aktif.',
                icon: Icons.sentiment_satisfied_alt_rounded,
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),

              // 2. Presensi / Kehadiran
              _buildKriteriaPillItem(
                badge: 'Proses KBM',
                badgeColor: const Color(0xFF2563EB),
                title: 'Presensi / Kehadiran',
                desc:
                    'Pencatatan kehadiran harian dengan opsi cepat terstandar (contoh bawaan: Hadir = 100, Izin = 75, Sakit = 50, Alpha = 0) untuk kemudahan guru.',
                icon: Icons.calendar_month_rounded,
                disclaimer:
                    'Catatan: Skor tiap status kehadiran di atas dapat Anda ubah bebas sesuai kebijakan sekolah (misal Hadir tidak wajib 100, dsb.) saat membuat kriteria kelas.',
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),

              // 3. Tugas, Kuis, UTS, & UAS
              _buildKriteriaPillItem(
                badge: 'Hasil / Produk',
                badgeColor: const Color(0xFF7C3AED),
                title: 'Tugas, Kuis, UTS, & UAS',
                desc:
                    'Penilaian berbasis hasil luaran belajar. Setiap tugas atau ujian dapat dibuatkan sesinya dan mendukung pencatatan nilai perbaikan (remedial).',
                icon: Icons.assignment_rounded,
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),

              // 4. Sifat Kriteria (Menguntungkan & Merugikan)
              _buildKriteriaBenefitCostItem(),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Card 2: Mekanisme Remedial & Aturan Nilai (Kotak Max & Rata-rata) ──
        _buildRemedialGuideCard(),

        const SizedBox(height: 18),

        // ── Card 3: Otomatisasi Remedial (Section Khusus Bertema Hijau) ──
        _buildOtomatisRemedialCard(),
      ],
    );
  }

  Widget _buildRemedialGuideCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.published_with_changes_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Mekanisme Remedial',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aturan Nilai Remedial & Percobaan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ketika siswa memiliki catatan nilai pengulangan (remedial pada tugas atau ujian), Scorify menyediakan 2 pilihan aturan penentuan skor:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: const Color(0xFF78350F),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Kotak 1: Max (Tertinggi) - FULL WIDTH ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFDE68A),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Nilai Maksimum',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Skor tertinggi yang diperoleh siswa yang akan diambil sistem (contoh: nilai awal 50, remedi 85 → nilai akhir 85).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Kotak 2: Rata-rata - FULL WIDTH ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFDE68A),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Rata-rata',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rerata dari seluruh percobaan siswa (contoh: nilai awal 50, remedi 80 → nilai akhir 65).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtomatisRemedialCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Otomatisasi Sistem',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pencatatan Remedial Otomatis & Penalti Efisiensi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Variabel pengulangan (attempt) otomatis dicatat sistem di latar belakang sebagai penalti efisiensi (kriteria merugikan).',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: const Color(0xFF166534),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFBBF7D0),
                width: 1.2,
              ),
            ),
            child: Text(
              'Siswa yang langsung tuntas pada percobaan pertama tanpa remedial tetap diapresiasi dengan peringkat yang lebih optimal secara adil. Anda tidak perlu menghitung penalti remedial secara manual.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                color: const Color(0xFF14532D),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKriteriaBenefitCostItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFF475569),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sifat Kriteria',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sifat Kriteria (Menguntungkan & Merugikan)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Setiap kriteria memiliki arah penilaian yang berbeda terhadap perankingan siswa:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Kotak 1: Menguntungkan - FULL WIDTH ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFBBF7D0),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kriteria Menguntungkan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Semakin tinggi nilai siswa, semakin baik untuk mendongkrak peringkat (contoh: nilai tugas, kuis, ujian, kehadiran, dan keaktifan).',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Kotak 2: Merugikan - FULL WIDTH ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFECDD3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.arrow_downward_rounded,
                    size: 18,
                    color: Color(0xFFE11D48),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kriteria Merugikan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF9F1239),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Semakin kecil angkanya, semakin baik bagi siswa (contoh: frekuensi remedial atau jumlah pengulangan ujian).',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKriteriaPillItem({
    required String badge,
    required Color badgeColor,
    required String title,
    required String desc,
    required IconData icon,
    String? disclaimer,
  }) {
    final topContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(icon, color: badgeColor, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (disclaimer == null) {
      return topContent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        topContent,
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  disclaimer,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Format Pairwise Vertikal
          _buildKriteriaPillItem(
            badge: 'Format Vertikal',
            badgeColor: const Color(0xFF0D9488),
            title: 'Format Pairwise Matriks',
            desc:
                'Scorify merombak matriks horizontal AHP yang biasanya lebar menjadi kartu perbandingan vertikal ke bawah, sehingga sangat nyaman digunakan langsung di layar smartphone.',
            icon: Icons.compare_arrows_rounded,
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),

          // 2. Tingkat Prioritas (Skala Saaty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.tune_rounded,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Skala Saaty 1-9',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tingkat Skala Perbandingan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sistem menggunakan tingkatan pilihan yang ramah untuk memudahkan Anda membandingkan kepentingan antar-kriteria:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSaatyScaleRow(
                    number: '1',
                    title: 'Sama pentingnya',
                    desc: 'Kedua kriteria memiliki prioritas seimbang.',
                  ),
                  _buildSaatyScaleRow(
                    number: '3',
                    title: 'Cukup lebih penting',
                    desc: 'Sedikit lebih condong ke salah satu kriteria.',
                  ),
                  _buildSaatyScaleRow(
                    number: '5',
                    title: 'Jauh lebih penting',
                    desc: 'Perbedaan prioritas sudah terasa jelas.',
                  ),
                  _buildSaatyScaleRow(
                    number: '7',
                    title: 'Sangat jauh lebih penting',
                    desc: 'Sangat diutamakan dibanding kriteria lawannya.',
                  ),
                  _buildSaatyScaleRow(
                    number: '9',
                    title: 'Mutlak paling penting',
                    desc: 'Prioritas tertinggi dan mutlak menentukan.',
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),

          // 3. Penyelarasan Logika Nilai (Konsistensi)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.balance_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Konsistensi Logika',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Penyelarasan Nilai Bobot',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pilihan bobot harus konsisten dan masuk akal secara matematis agar perankingan akurat:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Kotak 1: Selaras (Aman) - Full width, clean spacing
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBBF7D0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Contoh Selaras (Aman)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jika UAS > UTS dan UTS > Tugas, maka wajarnya UAS jauh lebih penting dari Tugas. Sistem langsung memproses bobot ini tanpa kendala.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Kotak 2: Peringatan Merah - Full width, clean spacing
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFECDD3),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Color(0xFFE11D48),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Peringatan Merah',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF9F1239),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Muncul jika pilihan bertabrakan melingkar seperti batu-gunting-kertas (misal: Keaktifan > Presensi, Presensi > Tugas, tapi Tugas > Keaktifan). Cukup ikuti saran perbaikan advisor.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),

          // 4. Tips Cepat Pengisian
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.tips_and_updates_rounded,
                        color: Color(0xFF0F766E),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Tips Penilaian',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tips Cepat Pengisian',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNumberedTipCard(
                number: '1',
                title: 'Tentukan Patokan (Anchor)',
                desc:
                    'Pilih satu kriteria utama (misal: Ujian) sebagai patokan pembanding dengan kriteria lainnya.',
              ),
              const SizedBox(height: 12),
              _buildNumberedTipCard(
                number: '2',
                title: 'Jaga Urutan',
                desc:
                    'Pastikan arah pilihan Anda konsisten dari awal hingga akhir perbandingan.',
              ),
              const SizedBox(height: 12),
              _buildNumberedTipCard(
                number: '3',
                title: 'Pilihan "Mutlak" Secara Bijak',
                desc:
                    'Gunakan skala 9 hanya jika kriteria tersebut benar-benar dominan tanpa kompromi.',
              ),
            ],
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),

          // 5. Smart Inconsistency Advisor
          _buildKriteriaPillItem(
            badge: 'Fitur Otomatis',
            badgeColor: const Color(0xFF7C3AED),
            title: 'Smart Inconsistency Advisor',
            desc:
                'Scorify membaca keseluruhan pola jawaban Anda. Jika ada peringatan merah, sistem otomatis mendeteksi bagian yang melenceng dan merekomendasikan saran perbaikan yang paling mendekati niat awal Anda.',
            icon: Icons.psychology_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSaatyScaleRow({
    required String number,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB45309),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedTipCard({
    required String number,
    required String title,
    required String desc,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF0F766E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
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
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureRowItem(
            icon: Icons.checklist_rtl_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            badge: 'Input Cepat',
            title: 'Bilah Nilai Sekaligus & Search',
            desc:
                'Pilih beberapa siswa sekaligus atau gunakan "Pilih Semua", lalu beri nilai harian atau nilai tugas dalam satu kali klik konfirmasi.',
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),
          _buildFeatureRowItem(
            icon: Icons.history_toggle_off_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            badge: 'Proteksi Waktu',
            title: 'Deteksi Presensi Dobel & Jam',
            desc:
                'Jika presensi siswa sudah pernah dicatat pada hari yang sama, sistem otomatis menampilkan dialog konfirmasi lengkap dengan riwayat waktu pencatatan (mis. 07:45 WIB) agar data tidak tertimpa tanpa sengaja.',
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),
          _buildFeatureRowItem(
            icon: Icons.touch_app_rounded,
            iconBg: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF4F46E5),
            badge: 'Akses Langsung',
            title: 'Quick Input Tag di Kartu Siswa',
            desc:
                'Pada kartu siswa di halaman Detail Kelas, sentuh langsung tag kriteria apa pun untuk membuka modal quick input instan tanpa pindah halaman.',
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureRowItem(
            icon: Icons.file_download_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            badge: 'Format Standar',
            title: 'Unduh Template Siswa (.xlsx)',
            desc:
                'Gunakan tombol "Unduh Template" di halaman Import Siswa. Cukup isi Kolom A dengan NIS dan Kolom B dengan Nama Siswa.',
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 36, thickness: 1.2),
          _buildFeatureRowItem(
            icon: Icons.share_rounded,
            iconBg: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF16A34A),
            badge: 'Multi-platform',
            title: 'Ekspor Hasil & Bagikan Langsung',
            desc:
                'Hasil perankingan SAW dan rekap nilai per siswa dapat diekspor ke Excel dan langsung dibagikan ke WhatsApp, Google Drive, atau email via sheet sistem.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRowItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String badge,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Q&A SECTION (MEKANISME PENILAIAN & KEHADIRAN) ─────────────────────────

  Widget _buildQnAGuideCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Q1: Kehadiran & Kategori Nilai
        _buildQnaItem(
          index: 0,
          tag: 'Kehadiran & Absensi',
          tagColor: const Color(0xFF10B981),
          question: 'Bagaimana mekanisme & format pengisian nilai kriteria Kehadiran?',
          answer:
              'Scorify menyediakan fitur Kategori Pilihan Cepat (Hadir, Izin, Sakit, Alpha) untuk mencegah salah ketik manual saat input harian:\n\n'
              '1. Standar Fleksibel: Guru bebas menentukan skor untuk setiap status (misal Hadir = 100, Izin = 75, Sakit = 50, Alpha = 0) saat pembuatan kriteria kelas.\n\n'
              '2. Input Sekali Ketuk: Saat presensi, guru cukup mengetuk chip opsi status kehadiran tanpa perlu mengetik angka manual di setiap pertemuan.\n\n'
              '3. Konsistensi Data: Nilai kehadiran otomatis terstandar dan aman diproses dalam normalisasi perankingan SAW.\n\n'
              'Catatan Tambahan: Jika kriteria tidak menggunakan kategori status, guru tetap dapat memasukkan persentase angka (0–100) atau akumulasi hari secara manual.',
        ),

        // Q2: Sifat Kriteria Kehadiran
        _buildQnaItem(
          index: 1,
          tag: 'Sifat Kriteria',
          tagColor: const Color(0xFF0D9488),
          question: 'Apakah kriteria Kehadiran bersifat Menguntungkan atau Merugikan?',
          answer:
              'Kriteria Kehadiran bersifat MENGUNTUNGKAN (Benefit).\n\nArtinya, semakin tinggi nilai atau persentase yang Anda berikan kepada siswa, semakin besar kontribusinya dalam menaikkan posisi ranking siswa tersebut.\n\nSebaliknya, kriteria yang bersifat MERUGIKAN (Cost, seperti Frekuensi Remedial) memiliki aturan terbalik: semakin sering siswa remedial, semakin berkurang perolehan skor akhirnya.',
        ),

        // Q3: Aturan Kriteria Induk vs Sub-Kriteria (Tugas, UTS, UAS)
        _buildQnaItem(
          index: 2,
          tag: 'Tugas, UTS & UAS',
          tagColor: const Color(0xFF2563EB),
          question: 'Bagaimana aturan menyusun Kriteria Induk dan Sub-Kriteria (Tugas, UTS, UAS)?',
          answer:
              'Dalam metode SPK (AHP & SAW), Kriteria Induk dan Sub-Kriteria memiliki fungsi berjenjang yang wajib sejenis (satu domain):\n\n'
              '1. Kriteria Induk Wajib Mandiri (Tugas, UTS, UAS):\n'
              'Setiap instrumen evaluasi utama memiliki bobot dan tingkat kesulitan yang berbeda, sehingga masing-masing wajib dijadikan Kriteria Induk terpisah agar dapat dibobotkan secara adil melalui perbandingan berpasangan AHP.\n\n'
              '2. Sub-Kriteria Wajib Sejenis dengan Kriteria Induknya:\n'
              'Sub-kriteria digunakan untuk merinci sesi pelaksanaan di dalam kriteria induk tersebut.\n'
              '- Untuk Kriteria Induk TUGAS: sub-kriterianya berupa Tugas 1, Tugas 2, Tugas Individu, atau Tugas Kelompok.\n'
              '- Untuk Kriteria Induk UTS: sub-kriterianya berupa UTS Teori atau UTS Praktik.\n'
              '- Untuk Kriteria Induk UAS: sub-kriterianya berupa UAS Individu atau UAS Proyek.\n\n'
              '3. Peringatan Pencampuran:\n'
              'Jangan mencampur ujian ke dalam sub-kriteria tugas (contoh keliru: Kriteria Induk "TUGAS" diisi sub-kriteria UTS dan UAS). Jika ada ujian, buatlah kriteria induk "UTS" atau "UAS" secara terpisah.',
        ),

        // Q4: Remedial Otomatis
        _buildQnaItem(
          index: 3,
          tag: 'Remedial Otomatis',
          tagColor: const Color(0xFF16A34A),
          question: 'Bagaimana cara kerja kriteria Frekuensi Remedial yang otomatis?',
          answer:
              'Anda tidak perlu membuat kriteria remedial terpisah saat pembobotan!\n\nRemedial dicatat langsung melalui variabel attempt pada setiap sesi tugas atau ujian. Siswa yang tuntas pada percobaan pertama memperoleh nilai utuh, sedangkan siswa yang berkali-kali remedial otomatis dikenakan penalti efisiensi (kriteria merugikan) di latar belakang secara sistem.',
        ),

        // Q5: Kapan Pembobotan AHP Dilakukan?
        _buildQnaItem(
          index: 4,
          tag: 'Pembobotan AHP',
          tagColor: const Color(0xFF8B5CF6),
          question: 'Kapan waktu terbaik untuk melakukan perbandingan kriteria AHP?',
          answer:
              'Pembobotan AHP Saaty bersifat independen dari nilai siswa, sehingga Anda dapat melakukannya kapan saja:\n\n'
              '1. Di awal semester saat menyusun silabus dan kontrak belajar.\n\n'
              '2. Di tengah semester saat menambahkan kriteria baru.\n\n'
              '3. Di akhir semester sebelum mencetak laporan perankingan akhir.\n\n'
              'Pastikan nilai Consistency Ratio (CR) bernilai Konsisten (CR < 0.1) agar bobot penilaian Anda logis secara matematis.',
        ),

        // Q6: Koreksi Nilai
        _buildQnaItem(
          index: 5,
          tag: 'Koreksi Nilai',
          tagColor: const Color(0xFFEC4899),
          question: 'Apakah nilai yang sudah tersimpan bisa diubah jika terjadi kesalahan input?',
          answer:
              'Bisa! Nilai siswa sangat fleksibel dan dapat diubah kapan saja:\n\n'
              '1. Melalui kartu siswa di halaman Detail Kelas (ketuk nilai atau tombol edit).\n\n'
              '2. Melalui fitur Input Kolektif untuk memperbarui nilai banyak siswa sekaligus.\n\n'
              '3. Melalui tab Tugas & Tes (By Product).\n\n'
              'Setiap kali ada nilai yang diperbarui, Anda cukup menekan tombol "Hitung Perangkingan" untuk mendapatkan hasil kalkulasi terbaru secara instan.',
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
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: isExpanded ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('qna_$index'),
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
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                question,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
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
              margin: const EdgeInsets.only(top: 6, bottom: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
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
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kembali ke dashboard untuk membuat kelas baru dan mulai menginput nilai siswa.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
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

// ─── ACCORDION COLLAPSIBLE HEADER DELEGATE ────────────────────────────────────

class _TutorialHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final VoidCallback onBack;

  _TutorialHeaderDelegate({
    required this.topPadding,
    required this.onBack,
  });

  @override
  double get minExtent => topPadding + 68;

  @override
  double get maxExtent => topPadding + 225;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double collapseRatio =
        ((shrinkOffset) / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final double bannerOpacity =
        (1.0 - collapseRatio * 1.6).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D252B), Color(0xFF163842), Color(0xFF1B4B5A)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(collapseRatio == 1.0 ? 16 : 26),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 5),
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

          // Pinned Top Bar (Back button + "PANDUAN PENGGUNA" + "Tutorial & Petunjuk KBM")
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            height: 68,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onBack,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PANDUAN PENGGUNA',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF34D399),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tutorial & Petunjuk KBM',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Accordion Intro Banner (Slides / Folds away)
          if (bannerOpacity > 0.0)
            Positioned(
              top: topPadding + 68,
              left: 16,
              right: 16,
              bottom: 14,
              child: Opacity(
                opacity: bannerOpacity,
                child: ClipRect(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
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
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sistem Penilaian & Perankingan Cerdas',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kombinasi pembobotan prioritas kriteria dan perankingan otomatis untuk evaluasi siswa yang adil dan objektif.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TutorialHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding;
  }
}
