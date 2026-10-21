import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/excel_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../ahp/ahp_screen.dart';
import '../student/add_student.dart';
import '../student/import_siswa_screen.dart';
import '../class/create_class.dart';
import '../class/input_nilai_screen.dart';
import '../class/input_nilai_hasil_screen.dart';
import '../kalkulasi/calculate_result.dart';

class DetailKelasScreen extends StatefulWidget {
  final String kelasId;

  const DetailKelasScreen({super.key, required this.kelasId});

  @override
  State<DetailKelasScreen> createState() => _DetailKelasScreenState();
}

class _DetailKelasScreenState extends State<DetailKelasScreen> {
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
        if (kelas == null) {
          return const Scaffold(
            body: Center(child: Text('Kelas tidak ditemukan')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F5F1),
          body: Column(
            children: [
              _buildHeader(context, kelas, provider),
              if (kelas.kriteria.any((k) => k.bobot == 0.0))
                _buildAhpWarningBanner(context, kelas),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: kelas.muridList.isEmpty
                          ? RefreshIndicator(
                              onRefresh: () => provider.refresh(),
                              child: _buildEmptyMuridState(
                                context,
                                kelas,
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => provider.refresh(),
                              child: _buildMuridList(context, kelas),
                            ),
                    ),
                    _buildBottomBar(context, kelas, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAhpWarningBanner(BuildContext context, Kelas kelas) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warningBorder.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warningDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bobot AHP Perlu Dihitung',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.warningDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ada kriteria baru atau bobot belum diisi. Hitung ulang bobot AHP agar perankingan valid.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AhpScreen(kelasId: widget.kelasId),
              ),
            ),
            child: Text(
              'Hitung',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMuridState(BuildContext context, Kelas kelas) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primaryLight.withValues(alpha: 0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Belum Ada Siswa di Kelas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan data siswa untuk mulai melakukan penilaian kriteria harian, rekap tugas/sesi, dan perankingan otomatis.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showTambahSiswaOptions(context, kelas),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(
                    'Tambah Siswa Sekarang',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Kelas kelas, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D252B), // Deep teal dark
            Color(0xFF163842),
            Color(0xFF1B4B5A), // AppColors.primary
          ],
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
          // Ambient Glowing Circles untuk kedalaman visual
          Positioned(
            top: -30,
            right: -25,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            bottom: -25,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Circle Back Button with frosted glass
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
                      const SizedBox(width: 10),

                      // Centered Class Title and Subtitle
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              kelas.nama.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${kelas.muridList.length} Siswa',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.88,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${kelas.kriteria.length} Kriteria',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.88,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kelas.sudahKalkulasi
                                          ? const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.22)
                                          : const Color(
                                              0xFFF59E0B,
                                            ).withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: kelas.sudahKalkulasi
                                            ? const Color(
                                                0xFF34D399,
                                              ).withValues(alpha: 0.45)
                                            : const Color(
                                                0xFFFCD34D,
                                              ).withValues(alpha: 0.45),
                                        width: 0.7,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          kelas.sudahKalkulasi
                                              ? Icons.check_circle_rounded
                                              : Icons.pending_rounded,
                                          size: 12,
                                          color: kelas.sudahKalkulasi
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFFFCD34D),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          kelas.sudahKalkulasi
                                              ? 'Sudah Dihitung'
                                              : 'Belum Dihitung',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: kelas.sudahKalkulasi
                                                ? const Color(0xFF34D399)
                                                : const Color(0xFFFCD34D),
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
                      const SizedBox(width: 10),

                      // Circle Options / Settings Button with frosted glass
                      Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: const CircleBorder(),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (val) async {
                            if (val == 'export') {
                              if (kelas.muridList.isEmpty) {
                                AppFeedback.showWarning(
                                  context,
                                  'Belum ada data siswa untuk diekspor',
                                );
                                return;
                              }
                              _exportExcel(context, kelas);
                            } else if (val == 'edit') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BuatKelasScreen(existingKelas: kelas),
                                ),
                              );
                            } else if (val == 'hapus') {
                              final confirm = await showConfirmDialog(
                                context,
                                title: 'Hapus Kelas',
                                content:
                                    'Yakin ingin menghapus kelas ini?\nSemua data murid dan nilai di kelas ini akan ikut terhapus secara permanen.',
                              );
                              if (confirm && context.mounted) {
                                await provider.hapusKelas(widget.kelasId);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'export',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_chart_outlined,
                                    color: Color(0xFF217346),
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Export ke Excel'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Edit Kelas'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'hapus',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Hapus Kelas',
                                    style: TextStyle(color: AppColors.danger),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuridList(BuildContext context, Kelas kelas) {
    List<Murid> list = List<Murid>.from(kelas.muridList);
    if (kelas.sudahKalkulasi) {
      list.sort((a, b) => (b.skorFinal ?? 0).compareTo(a.skorFinal ?? 0));
    } else {
      list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) {
        final matchNama = m.nama.toLowerCase().contains(q);
        final matchNis = m.nis != null && m.nis!.toLowerCase().contains(q);
        return matchNama || matchNis;
      }).toList();
    }

    return Column(
      children: [
        // Toolbar: Search Field & Action Buttons (Tambah Siswa + Nilai Sekaligus)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Search Input Bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari nama siswa atau NIS...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: Color(0xFF163842),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Baris Tombol Aksi: Tambah Siswa & Nilai Sekaligus (50/50 split)
              Row(
                children: [
                  // Tombol Tambah Siswa (Primary Deep Teal)
                  Expanded(
                    child: InkWell(
                      onTap: () => _showTambahSiswaOptions(context, kelas),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.5,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF163842),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF163842,
                              ).withValues(alpha: 0.22),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_add_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tambah Siswa',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tombol Nilai Sekaligus (Soft Emerald)
                  Expanded(
                    child: InkWell(
                      onTap: () => _showIsiMassalDialog(context, kelas),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.5,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.checklist_rtl_rounded,
                              size: 18,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nilai Sekaligus',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada siswa yang cocok dengan "$_searchQuery"'
                          : 'Belum ada siswa',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final murid = list[i];
                    return _MuridCard(
                      murid: murid,
                      kelas: kelas,
                      rank: kelas.sudahKalkulasi ? i + 1 : null,
                      onTapNilai: () => showInputNilaiSheet(
                        context,
                        kelas: kelas,
                        murid: murid,
                      ),
                      onTapKriteria: (kriteria) =>
                          _showQuickInputKriteriaDialog(
                            context,
                            kelas,
                            murid,
                            kriteria,
                          ),
                      onTapProductSesi: (kriteria, sesiId) =>
                          _showQuickInputKriteriaDialog(
                            context,
                            kelas,
                            murid,
                            kriteria,
                            initialSesiId: sesiId,
                          ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Kelas kelas,
    AppProvider provider,
  ) {
    final bobotBelumDiisi = kelas.kriteria.any((k) => k.bobot == 0.0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D252B), Color(0xFF163842), Color(0xFF1B4B5A)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D252B).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: kelas.muridList.isEmpty
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AhpScreen(kelasId: widget.kelasId),
                          ),
                        ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(
                    Icons.balance,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    bobotBelumDiisi ? 'Isi Bobot & Parameter' : 'Konfigurasi Parameter Penilaian',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (kelas.sudahKalkulasi) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HasilKalkulasiScreen(kelasId: widget.kelasId),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(
                          Icons.bar_chart_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Lihat Hasil',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (kelas.muridList.isEmpty || bobotBelumDiisi)
                            ? null
                            : () =>
                                  _jalankanKalkulasi(context, provider, kelas),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.15,
                          ),
                          disabledForegroundColor: Colors.white38,
                          elevation: 3,
                          shadowColor: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          'Hitung Ulang',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (kelas.muridList.isEmpty || bobotBelumDiisi)
                        ? null
                        : () => _jalankanKalkulasi(context, provider, kelas),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.15,
                      ),
                      disabledForegroundColor: Colors.white38,
                      elevation: 3,
                      shadowColor: const Color(
                        0xFF10B981,
                      ).withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.calculate_outlined, size: 20),
                    label: Text(
                      'Hitung Nilai Akhir',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _jalankanKalkulasi(
    BuildContext context,
    AppProvider provider,
    Kelas kelas,
  ) async {
    final missing = provider.cekKesiapanKalkulasi(widget.kelasId);
    if (missing.isNotEmpty && context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 22,
              ),
              SizedBox(width: 8),
              Text('Data Belum Lengkap', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nilai hasil belum dimasukkan untuk:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView(
                    shrinkWrap: true,
                    children: missing.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.costChip,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                e.value.map((k) => '• $k').join('\n'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.costChipText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final hasil = await provider.jalankanKalkulasi(widget.kelasId);
    if (context.mounted) Navigator.of(context).pop();

    if (hasil == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal: pastikan bobot AHP sudah diisi'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HasilKalkulasiScreen(kelasId: widget.kelasId),
        ),
      );
    }
  }

  Future<void> _exportExcel(BuildContext context, Kelas kelas) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Mengekspor Data Siswa ke Excel...',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final path = await ExcelService.exportSiswa(kelas);
      if (context.mounted) Navigator.of(context).pop();

      if (path != null && context.mounted) {
        await AppFeedback.showDownloadSuccessSheet(
          context,
          filePath: path,
          title: 'Export Excel Berhasil',
          message: 'Data rekap kelas "${kelas.nama}" siap dibagikan.',
        );
      } else if (context.mounted) {
        AppFeedback.showError(context, 'Gagal mengekspor data siswa');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        AppFeedback.showError(context, 'Terjadi kesalahan export: $e');
      }
    }
  }

  void _showTambahTugasDialog(
    BuildContext context,
    Kelas kelas, {
    String? defaultKriteriaId,
  }) {
    final kriteriaHasil = kelas.kriteria
        .where((k) => k.jenis == JenisKriteria.byProduct)
        .toList();
    if (kriteriaHasil.isEmpty) {
      AppFeedback.showWarning(
        context,
        'Kelas ini belum memiliki kriteria jenis By Product (Tugas/Ujian)',
      );
      return;
    }

    String selectedKriteriaId = defaultKriteriaId ?? kriteriaHasil.first.id;
    final namaCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.6),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Sesi Tugas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Buat sesi penilaian baru untuk tugas atau ujian',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(sheetCtx),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 20,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kriteriaHasil.length > 1) ...[
                        Text(
                          'Kategori Kriteria',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAF9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedKriteriaId,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              items: kriteriaHasil.map((k) {
                                return DropdownMenuItem(
                                  value: k.id,
                                  child: Text(
                                    k.nama,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() => selectedKriteriaId = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        'Nama Sesi Tugas / Ujian',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: namaCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Tugas Bab 1, Quiz 2, UTS',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAF9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) async {
                          final nama = namaCtrl.text.trim();
                          if (nama.isEmpty) return;
                          Navigator.pop(sheetCtx);
                          await context.read<AppProvider>().tambahSesi(
                            kelas.id,
                            selectedKriteriaId,
                            nama,
                          );
                          if (context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              'Tugas "$nama" berhasil ditambahkan!',
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final nama = namaCtrl.text.trim();
                            if (nama.isEmpty) {
                              AppFeedback.showWarning(
                                context,
                                'Nama tugas tidak boleh kosong',
                              );
                              return;
                            }
                            Navigator.pop(sheetCtx);
                            await context.read<AppProvider>().tambahSesi(
                              kelas.id,
                              selectedKriteriaId,
                              nama,
                            );
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                'Tugas "$nama" berhasil ditambahkan!',
                              );
                            }
                          },
                          child: Text(
                            'Tambah Tugas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(sheetCtx).padding.bottom + 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showIsiMassalDialog(BuildContext context, Kelas kelas) {
    if (kelas.muridList.isEmpty) {
      AppFeedback.showWarning(context, 'Belum ada siswa di kelas ini');
      return;
    }

    final actionableKriteria = kelas.kriteria;

    if (actionableKriteria.isEmpty) {
      AppFeedback.showWarning(
        context,
        'Tidak ada kriteria penilaian untuk diisi massal',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.6),
      builder: (_) => _InputKolektifSheet(
        kelas: kelas,
        actionableKriteria: actionableKriteria,
        onShowTambahTugas: (defaultKriteriaId) => _showTambahTugasDialog(
          context,
          kelas,
          defaultKriteriaId: defaultKriteriaId,
        ),
      ),
    );
  }

  void _showQuickInputProductDialog(
    BuildContext context,
    Kelas kelas,
    Murid murid,
    Kriteria kriteria, {
    String? initialSesiId,
  }) {
    final sesiList = kelas.getSesiByKriteria(kriteria.id);

    if (sesiList.isEmpty) {
      final namaSesiCtrl = TextEditingController(text: '${kriteria.nama} 1');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (sheetCtx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_task_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buat Sesi / Sub-Kriteria Baru',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kriteria: ${kriteria.nama}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kriteria "${kriteria.nama}" belum memiliki sesi/tugas. Tambahkan sesi pertama untuk mulai memberi nilai.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nama Sesi / Sub-Kriteria',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: namaSesiCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: ${kriteria.nama} 1, Ulangan Harian 1',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAF9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final nama = namaSesiCtrl.text.trim();
                      if (nama.isEmpty) return;
                      Navigator.pop(sheetCtx);
                      final provider = context.read<AppProvider>();
                      await provider.tambahSesi(kelas.id, kriteria.id, nama);
                      if (context.mounted) {
                        AppFeedback.showSuccess(
                          context,
                          'Sesi "$nama" berhasil dibuat!',
                        );
                        final kBaru = provider.getKelas(kelas.id);
                        final mBaru = kBaru?.muridList
                            .firstWhere((m) => m.id == murid.id, orElse: () => murid);
                        if (kBaru != null && mBaru != null) {
                          _showQuickInputProductDialog(
                              context, kBaru, mBaru, kriteria);
                        }
                      }
                    },
                    child: Text(
                      'Buat Sesi & Lanjut Input Nilai',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    String selectedSesiId = (initialSesiId != null &&
            sesiList.any((s) => s.id == initialSesiId))
        ? initialSesiId
        : sesiList.first.id;
    bool isKoreksi = false;
    final ctrl = TextEditingController();

    void updateControllerForSesi(String sId, bool koreksi, StateSetter setSheetState) {
      final existing = murid.nilaiList
          .where((n) => n.kriteriaId == kriteria.id && n.sesiId == sId)
          .toList()
        ..sort((a, b) => b.attempt.compareTo(a.attempt));

      if (koreksi && existing.isNotEmpty) {
        final last = existing.first.nilai;
        ctrl.text = last % 1 == 0 ? '${last.toInt()}' : '$last';
      } else {
        ctrl.clear();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final existing = murid.nilaiList
              .where((n) => n.kriteriaId == kriteria.id && n.sesiId == selectedSesiId)
              .toList()
            ..sort((a, b) => b.attempt.compareTo(a.attempt));

          final hasHistory = existing.isNotEmpty;
          final lastAttempt = hasHistory ? existing.first.attempt : 0;
          final lastScore = hasHistory ? existing.first.nilai : null;
          final nextAttempt = lastAttempt + 1;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Student Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            murid.nama.isNotEmpty ? murid.nama[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                murid.nama,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'NIS: ${murid.nis ?? '-'} • Kelas ${kelas.nama}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(sheetCtx),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Kriteria Highlight Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.assignment_turned_in_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kriteria.nama,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Kriteria Hasil (Tugas, Quiz, Ujian)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Combobox Sesi / Sub-Kriteria Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Sesi / Sub-Kriteria:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            _showTambahTugasDialog(
                              context,
                              kelas,
                              defaultKriteriaId: kriteria.id,
                            );
                          },
                          child: Text(
                            '+ Tambah Baru',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSesiId,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          items: sesiList.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.nama,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedSesiId = val;
                                isKoreksi = false;
                                updateControllerForSesi(val, false, setSheetState);
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Status Nilai & Attempt
                    if (hasHistory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nilai Saat Ini: ${lastScore! % 1 == 0 ? lastScore.toInt() : lastScore} (Percobaan ke-$lastAttempt)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF065F46),
                                    ),
                                  ),
                                  Text(
                                    existing.length > 1
                                        ? 'Total riwayat attempt: ${existing.length} kali'
                                        : 'Nilai dari percobaan pertama.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 2, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Belum ada nilai yang dicatat untuk sesi ini.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Pilihan Mode (Koreksi vs Attempt Baru / Remedial) jika sudah ada nilai
                    if (hasHistory) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                 isKoreksi = false;
                                  ctrl.clear();
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: !isKoreksi ? const Color(0xFFEFF6FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: !isKoreksi ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                    width: !isKoreksi ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Remedial / Retake',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: !isKoreksi ? const Color(0xFF2563EB) : AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Attempt #$nextAttempt',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: !isKoreksi ? const Color(0xFF1D4ED8) : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  isKoreksi = true;
                                  final val = lastScore!;
                                  ctrl.text = val % 1 == 0 ? '${val.toInt()}' : '$val';
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isKoreksi ? const Color(0xFFEFF6FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isKoreksi ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                    width: isKoreksi ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Koreksi Nilai',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isKoreksi ? const Color(0xFF2563EB) : AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Ubah Attempt #$lastAttempt',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: isKoreksi ? const Color(0xFF1D4ED8) : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Input Field Nilai
                    TextField(
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: isKoreksi
                            ? 'Koreksi Nilai Percobaan ke-$lastAttempt (0–100)'
                            : (hasHistory
                                ? 'Nilai Percobaan ke-$nextAttempt / Remedial (0–100)'
                                : 'Masukkan Nilai (0–100)'),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        hintText: 'Misal: 85',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAF9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final text = ctrl.text.trim().replaceAll(',', '.');
                          final val = double.tryParse(text);
                          if (val == null || val < 0 || val > 100) {
                            AppFeedback.showError(
                              context,
                              'Masukkan nilai yang valid antara 0 sampai 100',
                            );
                            return;
                          }

                          if (!sheetCtx.mounted) return;
                          Navigator.pop(sheetCtx);

                          final provider = context.read<AppProvider>();
                          await provider.inputNilaiHasil(
                            kelasId: kelas.id,
                            muridId: murid.id,
                            kriteriaId: kriteria.id,
                            sesiId: selectedSesiId,
                            nilai: val,
                            isKoreksi: isKoreksi,
                          );

                          if (context.mounted) {
                            final sesiNama = sesiList
                                .firstWhere((s) => s.id == selectedSesiId,
                                    orElse: () => sesiList.first)
                                .nama;
                            final valStr = val % 1 == 0 ? '${val.toInt()}' : '$val';
                            if (isKoreksi) {
                              AppFeedback.showSuccess(
                                context,
                                'Nilai $sesiNama untuk ${murid.nama} berhasil dikoreksi menjadi $valStr',
                              );
                            } else if (hasHistory) {
                              AppFeedback.showSuccess(
                                context,
                                'Percobaan ke-$nextAttempt (Remedial) untuk ${murid.nama} pada $sesiNama berhasil dicatat: $valStr',
                              );
                            } else {
                              AppFeedback.showSuccess(
                                context,
                                'Nilai $sesiNama untuk ${murid.nama} berhasil disimpan: $valStr',
                              );
                            }
                          }
                        },
                        child: Text(
                          isKoreksi
                              ? 'Simpan Perubahan Nilai'
                              : (hasHistory
                                  ? 'Simpan Nilai Attempt #$nextAttempt'
                                  : 'Simpan Nilai'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Link ke Tabel Rekap Lengkap
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InputNilaiHasilScreen(kelasId: kelas.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.grid_view_rounded, size: 16),
                        label: Text(
                          'Buka Tabel Rekap Nilai Seluruh Kelas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showQuickInputKriteriaDialog(
    BuildContext context,
    Kelas kelas,
    Murid murid,
    Kriteria kriteria, {
    String? initialSesiId,
  }) {
    if (kriteria.jenis == JenisKriteria.byProduct) {
      _showQuickInputProductDialog(
        context,
        kelas,
        murid,
        kriteria,
        initialSesiId: initialSesiId,
      );
      return;
    }

    final existingList = murid.getNilaiByKriteria(kriteria.id);
    double currentVal = 0;
    if (existingList.isNotEmpty) {
      existingList.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      currentVal = existingList.first.nilai;
    }

    final isCounter = kriteria.inputType == InputType.counter ||
        kriteria.nama.toLowerCase().contains('aktif');

    final double totalPoin = isCounter
        ? existingList.fold(0.0, (s, n) => s + n.nilai)
        : currentVal;
    final int frekuensiAktif = isCounter
        ? existingList.where((n) => n.nilai > 0).length
        : 0;
    final double? latestPoin = (isCounter && existingList.isNotEmpty)
        ? existingList.first.nilai
        : null;

    final isAttendance =
        kriteria.inputType == InputType.attendance ||
        kriteria.nama.toLowerCase().contains('hadir') ||
        kriteria.nama.toLowerCase().contains('presensi') ||
        kriteria.nama.toLowerCase().contains('absen');

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final nilaiHariIni = existingList.where((n) {
      final nStr = '${n.tanggal.year}-${n.tanggal.month}-${n.tanggal.day}';
      return nStr == todayStr;
    }).toList();

    final sudahDiisiHariIni = isAttendance && nilaiHariIni.isNotEmpty;
    final prevDate = sudahDiisiHariIni ? nilaiHariIni.first.tanggal : null;
    final jam = prevDate != null
        ? prevDate.hour.toString().padLeft(2, '0')
        : '';
    final mnt = prevDate != null
        ? prevDate.minute.toString().padLeft(2, '0')
        : '';

    final ctrl = TextEditingController(
      text: isCounter
          ? ''
          : (sudahDiisiHariIni
              ? (nilaiHariIni.first.nilai % 1 == 0
                    ? '${nilaiHariIni.first.nilai.toInt()}'
                    : '${nilaiHariIni.first.nilai}')
              : (currentVal > 0
                    ? (currentVal % 1 == 0
                          ? '${currentVal.toInt()}'
                          : '$currentVal')
                    : '')),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          murid.nama.isNotEmpty
                              ? murid.nama[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              murid.nama,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NIS: ${murid.nis ?? '-'} • Kelas ${kelas.nama}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(sheetCtx),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Kriteria Highlight Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isAttendance
                                ? const Color(0xFFECFDF5)
                                : (isCounter
                                    ? const Color(0xFFEFF6FF)
                                    : AppColors.primary.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isAttendance
                                ? Icons.how_to_reg_rounded
                                : (isCounter
                                    ? (kriteria.nama.toLowerCase().contains('aktif')
                                        ? Icons.pan_tool_rounded
                                        : Icons.stars_rounded)
                                    : Icons.assignment_rounded),
                            color: isAttendance
                                ? const Color(0xFF059669)
                                : (isCounter
                                    ? const Color(0xFF2563EB)
                                    : AppColors.primary),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kriteria.nama,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAttendance
                                    ? 'Presensi / Kehadiran Harian'
                                    : (isCounter
                                        ? (kriteria.nama.toLowerCase().contains('aktif')
                                            ? 'Nilai Kumulatif & Keaktifan'
                                            : 'Nilai Kumulatif & Catatan Proses')
                                        : 'Nilai Sekali Catat'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isCounter ? 'Total Skor' : 'Nilai Saat Ini',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isCounter
                                    ? (frekuensiAktif > 0
                                          ? (totalPoin % 1 == 0
                                                ? '${totalPoin.toInt()}'
                                                : totalPoin.toStringAsFixed(1))
                                          : '0')
                                    : (currentVal % 1 == 0
                                          ? '${currentVal.toInt()}'
                                          : '$currentVal'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isCounter
                                      ? const Color(0xFF2563EB)
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Detail Iterasi & Skor Terakhir (Khusus Keaktifan / Multi-entry)
                  if (isCounter) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              kriteria.nama.toLowerCase().contains('aktif')
                                  ? Icons.front_hand_rounded
                                  : Icons.fact_check_rounded,
                              size: 15,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (kriteria.nama.toLowerCase().contains('aktif')
                                      ? 'Sudah $frekuensiAktif kali aktif di kelas'
                                      : 'Sudah $frekuensiAktif kali catatan ${kriteria.nama}') +
                                  (latestPoin != null
                                      ? ' • Nilai Terakhir: ${latestPoin % 1 == 0 ? latestPoin.toInt() : latestPoin}'
                                      : ''),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Label / Banner Status Presensi Hari Ini (Khusus Kriteria Kehadiran)
                  if (isAttendance) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sudahDiisiHariIni
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sudahDiisiHariIni
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sudahDiisiHariIni
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 18,
                            color: sudahDiisiHariIni
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sudahDiisiHariIni
                                      ? 'Presensi Hari Ini: Tercatat ($jam:$mnt WIB • Nilai: ${nilaiHariIni.first.nilai % 1 == 0 ? nilaiHariIni.first.nilai.toInt() : nilaiHariIni.first.nilai})'
                                      : 'Presensi Hari Ini: Belum Tercatat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: sudahDiisiHariIni
                                        ? const Color(0xFF047857)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                                if (sudahDiisiHariIni) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    'Pilih status di bawah jika ingin mengubah data hari ini.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: const Color(0xFF065F46),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              kriteria.hasSubKriteria
                                  ? 'Pilih salah satu status di bawah ini untuk mencatat presensi.'
                                  : 'Masukkan angka nilai kehadiran sesuai standar Anda (misal persentase 0–100 atau akumulasi kehadiran).',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  if (kriteria.hasSubKriteria) ...[
                    Center(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: kriteria.subKriteria!.map((sub) {
                          final valStr = sub.nilai % 1 == 0
                              ? sub.nilai.toInt().toString()
                              : sub.nilai.toString();
                          final isSelected = ctrl.text == valStr;
                          return ChoiceChip(
                            label: Text(
                              '${sub.nama} ($valStr)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() {
                                  ctrl.text = valStr;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Input Textfield hanya ditampilkan JIKA TIDAK ADA sub-kriteria (Skema Angka Bulat)
                  if (!kriteria.hasSubKriteria) ...[
                    TextField(
                      controller: ctrl,
                      autofocus: isCounter || (!sudahDiisiHariIni && ctrl.text.isEmpty),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: isCounter
                            ? 'Skor keaktifan (misal: 80, 85, 90)'
                            : (isAttendance
                                ? 'Nilai kehadiran (misal: 100, 85, dll)'
                                : 'Ketik skor angka bulat (0 - 100)'),
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAF9),
                        prefixIcon: Icon(
                          isAttendance
                              ? Icons.tag_rounded
                              : (isCounter
                                  ? Icons.front_hand_rounded
                                  : Icons.numbers_rounded),
                          color: isCounter ? const Color(0xFF2563EB) : AppColors.primary,
                          size: 20,
                        ),
                        suffixIcon: ctrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () =>
                                    setSheetState(() => ctrl.clear()),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isCounter ? const Color(0xFF2563EB) : AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCounter ? const Color(0xFF2563EB) : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final text = ctrl.text.trim().replaceAll(',', '.');
                        final val = double.tryParse(text);
                        if (val == null || val <= 0 || val > 100) {
                          AppFeedback.showError(
                            context,
                            kriteria.hasSubKriteria
                                ? 'Silakan pilih salah satu opsi kategori di atas'
                                : 'Masukkan nilai angka bulat yang valid antara 0 - 100',
                          );
                          return;
                        }

                        if (!sheetCtx.mounted) return;
                        Navigator.pop(sheetCtx);

                        final provider = context.read<AppProvider>();
                        if (isCounter) {
                          await provider.tambahNilaiKeaktifan(
                            kelasId: kelas.id,
                            muridId: murid.id,
                            kriteriaId: kriteria.id,
                            poin: val,
                          );
                          if (context.mounted) {
                            final newCount = frekuensiAktif + 1;
                            final labelKriteria = kriteria.nama.toLowerCase().contains('aktif')
                                ? 'keaktifan'
                                : kriteria.nama;
                            final valStr = val % 1 == 0 ? '${val.toInt()}' : '$val';
                            AppFeedback.showSuccess(
                              context,
                              'Nilai $labelKriteria ($valStr) untuk ${murid.nama} berhasil dicatat (Total: $newCount kali aktif)',
                            );
                          }
                        } else {
                          await provider.inputNilaiPerforma(
                            kelasId: kelas.id,
                            muridId: murid.id,
                            kriteriaId: kriteria.id,
                            nilai: val,
                            tanggal: DateTime.now(),
                          );

                          if (context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              isAttendance
                                  ? (sudahDiisiHariIni
                                        ? 'Presensi ${murid.nama} diperbarui: ${val % 1 == 0 ? val.toInt() : val}'
                                        : 'Presensi ${murid.nama} tersimpan: ${val % 1 == 0 ? val.toInt() : val}')
                                  : 'Nilai ${kriteria.nama} untuk ${murid.nama} tersimpan: ${val % 1 == 0 ? val.toInt() : val}',
                            );
                          }
                        }
                      },
                      child: Text(
                        isCounter
                            ? 'Simpan Nilai Keaktifan (Catatan ke-${frekuensiAktif + 1})'
                            : (isAttendance
                                  ? (sudahDiisiHariIni
                                        ? 'Perbarui Nilai Presensi'
                                        : 'Simpan Nilai Presensi')
                                  : 'Simpan Nilai'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(sheetCtx).padding.bottom + 6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTambahSiswaOptions(BuildContext context, Kelas kelas) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Siswa',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Pilih metode penambahan data murid',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildAddStudentOptionCard(
                icon: Icons.edit_note_rounded,
                iconColor: AppColors.primary,
                title: 'Tambah Manual',
                subtitle: 'Input NIS dan Nama siswa satu per satu',
                badgeText: 'Formulir',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TambahMuridScreen(
                        kelasId: widget.kelasId,
                        kelas: kelas,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildAddStudentOptionCard(
                icon: Icons.table_chart_rounded,
                iconColor: const Color(0xFF107C41),
                title: 'Import Excel (.xlsx)',
                subtitle: 'Unggah file spreadsheet template daftar siswa',
                badgeText: 'Cepat & Massal',
                badgeColor: const Color(0xFFE8F5E9),
                badgeTextColor: const Color(0xFF2E7D32),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImportSiswaScreen(
                        kelasId: widget.kelasId,
                        kelas: kelas,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddStudentOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              badgeColor ??
                              AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor ?? AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _MuridCard extends StatefulWidget {
  final Murid murid;
  final Kelas kelas;
  final int? rank;
  final VoidCallback onTapNilai;
  final ValueChanged<Kriteria> onTapKriteria;
  final void Function(Kriteria, String sesiId)? onTapProductSesi;

  const _MuridCard({
    required this.murid,
    required this.kelas,
    required this.onTapNilai,
    required this.onTapKriteria,
    this.onTapProductSesi,
    this.rank,
  });

  @override
  State<_MuridCard> createState() => _MuridCardState();
}

class _MuridCardState extends State<_MuridCard> {
  bool _isExpanded = false;

  BoxDecoration get _rankDecoration {
    final rank = widget.rank;
    if (rank == 1) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x40F59E0B),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      );
    }
    if (rank == 2) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x2564748B),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );
    }
    if (rank == 3) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFF92400E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x2592400E),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: const Color(0xFFF1F5F9),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kriteriaProses = widget.kelas.kriteria
        .where((k) => k.jenis == JenisKriteria.byProcess)
        .toList();
    final kriteriaProduk = widget.kelas.kriteria
        .where((k) => k.jenis == JenisKriteria.byProduct)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
          width: _isExpanded ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: _isExpanded ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.rank != null) ...[
                      Container(
                        width: 30,
                        height: 30,
                        decoration: _rankDecoration,
                        child: Center(
                          child: Text(
                            '${widget.rank}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: (widget.rank != null && widget.rank! <= 3)
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.murid.nis != null && widget.murid.nis!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'NIS ${widget.murid.nis}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            widget.murid.nama,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Chevron Expand/Collapse (Indikator Swipe Down / Buka)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: _isExpanded
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TambahMuridScreen(
                                kelasId: widget.kelas.id,
                                kelas: widget.kelas,
                                existingMurid: widget.murid,
                              ),
                            ),
                          );
                        } else if (val == 'hapus') {
                          _hapusMurid(context);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Siswa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'hapus',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: AppColors.danger,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hapus',
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Bagian yang Tersembunyi (Muncul saat card di-tap / swipe down)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),
                      // ── Seksi 1: Nilai Proses (KBM Harian) ──
                      if (kriteriaProses.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nilai Proses (KBM Harian)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1D4ED8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Tap untuk ubah cepat',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: kriteriaProses.map((k) {
                            final nilaiStr = _formatNilaiKriteria(k, widget.murid);
                            return _InteractiveKriteriaTag(
                              nama: k.nama,
                              nilaiStr: nilaiStr,
                              onTap: () => widget.onTapKriteria(k),
                            );
                          }).toList(),
                        ),
                        if (kriteriaProduk.isNotEmpty) const SizedBox(height: 14),
                      ],

                      // ── Seksi 2: Daftar Tugas & Ujian (By Product) - Sketsa Dosen ──
                      if (kriteriaProduk.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daftar Tugas & Ujian',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Tap kotak untuk edit / remidi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...kriteriaProduk.expand((k) {
                          final sesiList = widget.kelas.getSesiByKriteria(k.id);
                          if (sesiList.isEmpty) {
                            return [
                              InkWell(
                                onTap: () => widget.onTapKriteria(k),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${k.nama} (Belum ada sesi/tugas)',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.add_circle_outline_rounded,
                                          size: 16, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tambah Sesi',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ];
                          }
                          return sesiList.map((sesi) {
                            final nList = widget.murid.nilaiList
                                .where((n) => n.kriteriaId == k.id && n.sesiId == sesi.id)
                                .toList()
                              ..sort((a, b) => b.attempt.compareTo(a.attempt));
                            final hasScore = nList.isNotEmpty;
                            final lastScore = hasScore ? nList.first.nilai : null;
                            final attempt = hasScore ? nList.first.attempt : 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: hasScore ? const Color(0xFFF8FAF9) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasScore ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sesi.nama,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          k.nama,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Kotak Nilai & Attempt persis sketsa notebook: [ 80 | 2x ]
                                  InkWell(
                                    onTap: () => widget.onTapProductSesi != null
                                        ? widget.onTapProductSesi!(k, sesi.id)
                                        : widget.onTapKriteria(k),
                                    borderRadius: BorderRadius.circular(9),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: hasScore ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            hasScore
                                                ? '${lastScore! % 1 == 0 ? lastScore.toInt() : lastScore}'
                                                : '-',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: hasScore ? const Color(0xFF15803D) : AppColors.textHint,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 1,
                                            height: 16,
                                            color: const Color(0xFFCBD5E1),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            hasScore ? '${attempt}x' : 'Input',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: hasScore
                                                  ? (attempt > 1 ? const Color(0xFFD97706) : const Color(0xFF64748B))
                                                  : AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.edit_rounded,
                                            size: 13,
                                            color: hasScore ? const Color(0xFF94A3B8) : AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          });
                        }),
                      ],
                      if (kriteriaProses.isEmpty && kriteriaProduk.isEmpty)
                        Text(
                          'Belum ada kriteria di kelas ini.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onTapNilai,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Input / Ubah Nilai Lengkap Siswa Ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNilaiKriteria(Kriteria k, Murid murid) {
    final list = murid.getNilaiByKriteria(k.id);
    if (list.isEmpty) return '-';

    if (k.jenis == JenisKriteria.byProduct) {
      final Map<String, List<Nilai>> perSesi = {};
      for (final n in list) {
        final key = n.sesiId ?? 'no_sesi';
        perSesi.putIfAbsent(key, () => []).add(n);
      }
      if (perSesi.isEmpty) return '-';

      double totalSesi = 0.0;
      for (final sList in perSesi.values) {
        if (k.aggregationRule == AggregationRule.average) {
          totalSesi += sList.fold(0.0, (s, n) => s + n.nilai) / sList.length;
        } else {
          totalSesi +=
              sList.map((e) => e.nilai).reduce((a, b) => a > b ? a : b);
        }
      }
      final val = totalSesi / perSesi.length;
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
    } else {
      final isCounter = k.inputType == InputType.counter ||
          k.nama.toLowerCase().contains('aktif');
      if (isCounter) {
        double poinAgregasi = 0.0;
        final count = list.where((n) => n.nilai > 0).length;
        if (k.aggregationRule == AggregationRule.average) {
          final active = list.where((n) => n.nilai > 0).toList();
          poinAgregasi = active.isEmpty
              ? 0.0
              : active.fold(0.0, (sum, n) => sum + n.nilai) / active.length;
        } else {
          poinAgregasi = list.map((n) => n.nilai).reduce((a, b) => a > b ? a : b);
        }
        final poinStr = poinAgregasi % 1 == 0
            ? poinAgregasi.toInt().toString()
            : poinAgregasi.toStringAsFixed(1);
        return count > 0 ? '$poinStr (${count}x)' : poinStr;
      } else {
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month}-${today.day}';
        final nilaiHariIni = list.where((n) {
          final nStr = '${n.tanggal.year}-${n.tanggal.month}-${n.tanggal.day}';
          return nStr == todayStr;
        }).toList();

        final val = nilaiHariIni.isNotEmpty
            ? nilaiHariIni.first.nilai
            : list.last.nilai;
        return val % 1 == 0 ? val.toInt().toString() : val.toString();
      }
    }
  }

  Future<void> _hapusMurid(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Hapus Murid',
      content:
          'Yakin ingin menghapus murid ini?\nData ${widget.murid.nama} akan dihapus secara permanen.',
    );
    if (confirm && context.mounted) {
      await context.read<AppProvider>().hapusMurid(widget.kelas.id, widget.murid.id);
    }
  }
}

// ─── Interactive Kriteria Tag & Skor Badge ─────────────────────────────────────

class _InteractiveKriteriaTag extends StatelessWidget {
  final String nama;
  final String nilaiStr;
  final VoidCallback onTap;

  const _InteractiveKriteriaTag({
    required this.nama,
    required this.nilaiStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFilled = nilaiStr != '-';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isFilled ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFilled
                ? const Color(0xFF86EFAC).withValues(alpha: 0.7)
                : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nama,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: isFilled ? FontWeight.w700 : FontWeight.w500,
                color: isFilled
                    ? const Color(0xFF166534)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: isFilled
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                nilaiStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modal Nilai Sekaligus ───────────────────────────────────────────────────

class _InputKolektifSheet extends StatefulWidget {
  final Kelas kelas;
  final List<Kriteria> actionableKriteria;
  final void Function(String defaultKriteriaId) onShowTambahTugas;

  const _InputKolektifSheet({
    required this.kelas,
    required this.actionableKriteria,
    required this.onShowTambahTugas,
  });

  @override
  State<_InputKolektifSheet> createState() => _InputKolektifSheetState();
}

class _InputKolektifSheetState extends State<_InputKolektifSheet> {
  late String _selectedKriteriaId;
  late String _selectedDropdownKey;
  late TextEditingController _nilaiCtrl;
  late TextEditingController _searchCtrl;
  String? _selectedSesiId;
  String _searchQuery = '';
  late Set<String> _selectedMuridIds;
  bool _isSaving = false;

  List<({String key, String kriteriaId, String? sesiId, String label})> _getDropdownOptions() {
    final list = <({String key, String kriteriaId, String? sesiId, String label})>[];
    for (final k in widget.actionableKriteria) {
      if (k.jenis == JenisKriteria.byProduct) {
        final sesis = widget.kelas.getSesiByKriteria(k.id);
        if (sesis.isEmpty) {
          list.add((
            key: '${k.id}::none',
            kriteriaId: k.id,
            sesiId: null,
            label: '${k.nama} (Belum ada sesi/tugas)',
          ));
        } else {
          for (final s in sesis) {
            list.add((
              key: '${k.id}::${s.id}',
              kriteriaId: k.id,
              sesiId: s.id,
              label: '${k.nama}: ${s.nama}',
            ));
          }
        }
      } else {
        list.add((
          key: k.id,
          kriteriaId: k.id,
          sesiId: null,
          label: '${k.nama} (Harian)',
        ));
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _nilaiCtrl = TextEditingController(text: '100');
    _searchCtrl = TextEditingController();
    _selectedMuridIds = widget.kelas.muridList.map((m) => m.id).toSet();

    final options = _getDropdownOptions();
    if (options.isNotEmpty) {
      final firstOpt = options.first;
      _selectedDropdownKey = firstOpt.key;
      _selectedKriteriaId = firstOpt.kriteriaId;
      _selectedSesiId = firstOpt.sesiId;
    } else {
      _selectedDropdownKey = widget.actionableKriteria.first.id;
      _selectedKriteriaId = widget.actionableKriteria.first.id;
    }
  }

  @override
  void dispose() {
    _nilaiCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  Future<void> _terapkanNilai() async {
    if (_selectedMuridIds.isEmpty) {
      AppFeedback.showWarning(
        context,
        'Pilih minimal satu siswa untuk dinilai',
      );
      return;
    }

    final selectedKriteria = widget.actionableKriteria.firstWhere(
      (k) => k.id == _selectedKriteriaId,
    );
    final isHasil = selectedKriteria.jenis == JenisKriteria.byProduct;

    if (isHasil && _selectedSesiId == null) {
      AppFeedback.showWarning(
        context,
        'Pilih atau buat sesi tugas terlebih dahulu',
      );
      return;
    }

    final parsed = double.tryParse(_nilaiCtrl.text.replaceAll(',', '.'));
    if (parsed == null) {
      AppFeedback.showError(context, 'Masukkan angka nilai yang valid');
      return;
    }

    // Cek konfirmasi absensi hari ini jika kriteria presensi
    final isAbsensi =
        selectedKriteria.nama.toLowerCase().contains('hadir') ||
        selectedKriteria.nama.toLowerCase().contains('absen');
    if (isAbsensi) {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      int sudahAbsenCount = 0;
      DateTime? latestAbsenTime;

      for (final mid in _selectedMuridIds) {
        final m = widget.kelas.muridList.firstWhere((elem) => elem.id == mid);
        final existing = m.nilaiList.where((n) {
          final nStr = '${n.tanggal.year}-${n.tanggal.month}-${n.tanggal.day}';
          return n.kriteriaId == selectedKriteria.id && nStr == todayStr;
        }).toList();

        if (existing.isNotEmpty) {
          sudahAbsenCount++;
          if (latestAbsenTime == null ||
              existing.first.tanggal.isAfter(latestAbsenTime)) {
            latestAbsenTime = existing.first.tanggal;
          }
        }
      }

      if (sudahAbsenCount > 0 && latestAbsenTime != null) {
        final jam = latestAbsenTime.hour.toString().padLeft(2, '0');
        final menit = latestAbsenTime.minute.toString().padLeft(2, '0');
        final confirm = await AppFeedback.showConfirmDialog(
          context,
          title: 'Konfirmasi Pembaruan Absensi',
          content:
              '$sudahAbsenCount siswa terpilih sudah tercatat absensinya hari ini (terakhir pukul $jam:$menit).\n\nApakah Anda yakin ingin memperbarui nilai absensi mereka?',
          confirmLabel: 'Perbarui Absensi',
          cancelLabel: 'Batal',
        );
        if (!confirm) return;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final provider = context.read<AppProvider>();
    await provider.inputNilaiMassal(
      kelasId: widget.kelas.id,
      kriteriaId: _selectedKriteriaId,
      nilai: parsed,
      sesiId: _selectedSesiId,
      targetMuridIds: _selectedMuridIds.toList(),
      hanyaYangKosong: false,
    );

    if (mounted) {
      Navigator.pop(context);
      final sesiName = _selectedSesiId != null
          ? widget.kelas.sesiList
              .firstWhere(
                (s) => s.id == _selectedSesiId,
                orElse: () => Sesi(
                  id: '',
                  kriteriaId: '',
                  nama: '',
                  urutan: 0,
                  tanggal: DateTime.now(),
                ),
              )
              .nama
          : '';
      final labelTarget = sesiName.isNotEmpty
          ? '${selectedKriteria.nama} ($sesiName)'
          : selectedKriteria.nama;

      AppFeedback.showSuccess(
        context,
        'Berhasil memberi nilai sekaligus ke ${_selectedMuridIds.length} siswa untuk "$labelTarget"',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedKriteria = widget.actionableKriteria.firstWhere(
      (k) => k.id == _selectedKriteriaId,
    );

    final filteredMuridList = widget.kelas.muridList.where((m) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final matchNama = m.nama.toLowerCase().contains(q);
      final matchNis = m.nis != null && m.nis!.toLowerCase().contains(q);
      return matchNama || matchNis;
    }).toList();

    final isAllFilteredSelected =
        filteredMuridList.isNotEmpty &&
        filteredMuridList.every((m) => _selectedMuridIds.contains(m.id));

    final dateText = widget.kelas.createdAt != null
        ? 'Dibuat: ${_formatDate(widget.kelas.createdAt!)}'
        : 'Dibuat: ${_formatDate(DateTime.now())}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Top Section: Title, timestamp, close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nilai Sekaligus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2-Column Horizontal Layout: Kriteria & Nilai (Poin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kolom Kriteria (Sleek dropdown)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kriteria',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.8),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDropdownKey,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                items: _getDropdownOptions().map((opt) {
                                  return DropdownMenuItem(
                                    value: opt.key,
                                    child: Text(
                                      opt.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final options = _getDropdownOptions();
                                    final opt = options.firstWhere(
                                      (o) => o.key == val,
                                      orElse: () => options.first,
                                    );
                                    setState(() {
                                      _selectedDropdownKey = val;
                                      _selectedKriteriaId = opt.kriteriaId;
                                      _selectedSesiId = opt.sesiId;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Kolom Nilai (Poin) (Minimal numeric field)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nilai',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            height: 46,
                            child: TextField(
                              controller: _nilaiCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Contoh: 100',
                                hintStyle: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textHint,
                                  fontWeight: FontWeight.normal,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceWhite,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.border.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.border.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Rubrik opsi poin cepat (Hanya untuk kriteria By Process yang memiliki rubrik)
                if (selectedKriteria.hasSubKriteria && selectedKriteria.jenis == JenisKriteria.byProcess) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: selectedKriteria.subKriteria!.map((sub) {
                      final valStr = sub.nilai % 1 == 0
                          ? sub.nilai.toInt().toString()
                          : sub.nilai.toString();
                      final isSelected = _nilaiCtrl.text == valStr;
                      return ChoiceChip(
                        label: Text('${sub.nama} ($valStr)'),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _nilaiCtrl.text = valStr;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 4),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau NIS siswa...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Siswa (${_selectedMuridIds.length}/${widget.kelas.muridList.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isAllFilteredSelected) {
                            for (final m in filteredMuridList) {
                              _selectedMuridIds.remove(m.id);
                            }
                          } else {
                            for (final m in filteredMuridList) {
                              _selectedMuridIds.add(m.id);
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          isAllFilteredSelected ? 'Batal Semua' : 'Pilih Semua',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Expanded(
            child: filteredMuridList.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Siswa tidak ditemukan',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filteredMuridList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final murid = filteredMuridList[i];
                      final isSelected = _selectedMuridIds.contains(murid.id);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMuridIds.remove(murid.id);
                            } else {
                              _selectedMuridIds.add(murid.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFF8FAF9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Circular avatar initial
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(
                                          alpha: 0.15,
                                        )
                                      : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  murid.nama.isNotEmpty
                                      ? murid.nama[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      murid.nama,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'NIS: ${murid.nis != null && murid.nis!.isNotEmpty ? murid.nis : '-'}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Circular toggle checkmark on right edge
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFFCBD5E1),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Section: Sticky footer with full-width pill-shaped primary action button
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                onPressed: _isSaving ? null : _terapkanNilai,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Terapkan (${_selectedMuridIds.length} Siswa)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
