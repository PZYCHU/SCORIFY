import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            appBar: AppBar(
              title: Text(
                'Sesi Tidak Ditemukan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
            body: Center(
              child: Text(
                'Sesi telah dihapus atau tidak ditemukan.',
                style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
              ),
            ),
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
          backgroundColor: const Color(0xFFF8FAF9),
          body: Column(
            children: [
              _buildHeroHeader(context, kelas, kriteria, sesi),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau NIS siswa...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: AppColors.textHint,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // List Murid & Nilai
                    Expanded(
                      child: filteredMuridList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada siswa yang cocok dengan "$_searchQuery"'
                                        : 'Belum ada data siswa di kelas ini.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showInputAllSheet(context, kelas, kriteria, sesi),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            icon: const Icon(Icons.edit_note_rounded, size: 22),
            label: Text(
              semuaSelesai ? 'Edit Nilai Sekaligus' : 'Input Nilai Sekaligus',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Hero Header Scorify ──────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context, Kelas kelas, Kriteria kriteria, Sesi sesi) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D252B),
            Color(0xFF163842),
            Color(0xFF1B4B5A),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Ambient Glow Circle
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button & Navigation
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sesi.nama,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${kriteria.nama} • ${kelas.nama}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Card Sesi ────────────────────────────────────────────────────
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.primary,
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
                        Flexible(
                          child: Text(
                            sesi.nama,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: semuaSelesai
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: semuaSelesai
                                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            semuaSelesai ? 'Selesai' : 'Belum Lengkap',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: semuaSelesai
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Kategori: ${kriteria.nama}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete Button with Centered Reaffirmation Dialog
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final confirm = await showConfirmDialog(
                      context,
                      title: 'Hapus Sesi Penilaian',
                      content:
                          'Yakin ingin menghapus sesi "${sesi.nama}"?\nSeluruh riwayat nilai tugas pada sesi ini akan ikut terhapus secara permanen.',
                    );
                    if (confirm && context.mounted) {
                      await provider.hapusSesi(widget.kelasId, sesi.id);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Progres Nilai', '$muridTerisi / $totalMurid Murid'),
                Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                _buildStatItem(
                  'Rata-Rata Nilai',
                  muridTerisi > 0 ? avgNilai.toStringAsFixed(1) : '-',
                ),
              ],
            ),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── Modal Dialog Input Nilai Tunggal ─────────────────────────────────────
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Info Siswa
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          murid.nama.isNotEmpty ? murid.nama[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NIS: ${murid.nis ?? '-'} • Sesi: ${sesi.nama}',
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
                        onTap: () => Navigator.of(ctx).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
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

                const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nilai Murid (0 - 100)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (existing != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Saat ini: ${existing.nilai.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0 - 100',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAF9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
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
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick preset buttons for convenience
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [70, 75, 80, 85, 90, 100].map((val) {
                          return InkWell(
                            onTap: () {
                              ctrl.text = val.toString();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                '$val',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
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
                          child: Text(
                            'Simpan Nilai',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasNilai ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          murid.nama,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'NIS: ${murid.nis ?? '-'}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasNilai
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasNilai
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                hasNilai ? nilaiHasil!.nilai.toStringAsFixed(0) : 'Belum dinilai',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: hasNilai ? const Color(0xFF047857) : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                onPressed: onTapEdit,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: EdgeInsets.zero,
              ),
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
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Input Nilai Sekaligus',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.sesi.nama} • ${widget.kriteria.nama}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saving ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Simpan Semua',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: widget.kelas.muridList.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final murid = widget.kelas.muridList[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
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
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'NIS: ${murid.nis ?? '-'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 85,
                          child: TextField(
                            controller: _ctrls[murid.id],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0-100',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.normal,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
