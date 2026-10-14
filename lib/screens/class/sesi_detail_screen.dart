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
            jenis: JenisKriteria.byProduct,
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
        int muridRemedial = 0;
        double totalNilai = 0;

        for (final m in kelas.muridList) {
          final existing = m.nilaiList.where(
            (n) => n.kriteriaId == kriteria.id && n.sesiId == sesi.id,
          ).toList();

          if (existing.isNotEmpty) {
            existing.sort((a, b) => b.attempt.compareTo(a.attempt));
            muridTerisi++;
            totalNilai += existing.first.nilai;
            if (existing.length > 1) {
              muridRemedial++;
            }
          }
        }

        final double avgNilai = muridTerisi > 0 ? totalNilai / muridTerisi : 0.0;
        final bool semuaSelesai = muridTerisi == kelas.muridList.length && kelas.muridList.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          body: Column(
            children: [
              _buildHeroHeader(context, kelas, kriteria, sesi, provider),
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
                      muridRemedial,
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
                                ).toList()
                                  ..sort((a, b) => a.attempt.compareTo(b.attempt));

                                final Nilai? bestNilai = existing.isNotEmpty ? existing.last : null;

                                return _MuridNilaiCard(
                                  index: index + 1,
                                  murid: murid,
                                  nilaiHasil: bestNilai,
                                  riwayatNilai: existing,
                                  onTapAddRemedial: () => _showSingleNilaiDialog(
                                    context,
                                    kelas,
                                    kriteria,
                                    sesi,
                                    murid,
                                    existing,
                                    initialKoreksi: false,
                                  ),
                                  onTapEdit: () => _showSingleNilaiDialog(
                                    context,
                                    kelas,
                                    kriteria,
                                    sesi,
                                    murid,
                                    existing,
                                    initialKoreksi: existing.isNotEmpty,
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
  Widget _buildHeroHeader(BuildContext context, Kelas kelas, Kriteria kriteria, Sesi sesi, AppProvider provider) {
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
    int muridRemedial,
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
              // Edit Name Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showEditNamaSesiDialog(context, provider, sesi),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                Container(width: 1, height: 28, color: const Color(0xFFCBD5E1)),
                _buildStatItem(
                  'Remedial',
                  '$muridRemedial Murid',
                  valueColor: muridRemedial > 0 ? const Color(0xFFD97706) : AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showEditNamaSesiDialog(
    BuildContext context,
    AppProvider provider,
    Sesi sesi,
  ) {
    final ctrl = TextEditingController(text: sesi.nama);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Ubah Nama Sesi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nama atau judul tugas baru:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'cth: Tugas 1: Algoritma / PR Bab 3',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              await provider.updateSesiNama(widget.kelasId, sesi.id, newName);
              if (context.mounted) {
                AppFeedback.showSuccess(
                  context,
                  'Nama sesi berhasil diperbarui menjadi "$newName"',
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ─── Modal Dialog Input Nilai Tunggal ─────────────────────────────────────
  void _showSingleNilaiDialog(
    BuildContext context,
    Kelas kelas,
    Kriteria kriteria,
    Sesi sesi,
    Murid murid,
    List<Nilai> existingNilaiList, {
    bool initialKoreksi = false,
  }) {
    final latestNilai = existingNilaiList.isNotEmpty ? existingNilaiList.last : null;
    final ctrl = TextEditingController(
      text: latestNilai != null ? latestNilai.nilai.toStringAsFixed(0) : '',
    );
    bool isKoreksi = initialKoreksi && existingNilaiList.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final int attemptBerikutnya = existingNilaiList.length + 1;
          final bool hasRiwayat = existingNilaiList.isNotEmpty;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
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

                  const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Riwayat Attempt Percobaan
                        if (hasRiwayat) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAF9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.history_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Riwayat Percobaan (${existingNilaiList.length} Attempt)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...existingNilaiList.asMap().entries.map((entry) {
                                  final n = entry.value;
                                  final isLast = n.id == existingNilaiList.last.id;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: n.attempt == 1
                                                ? AppColors.primary.withValues(alpha: 0.1)
                                                : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Attempt ${n.attempt}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: n.attempt == 1
                                                  ? AppColors.primary
                                                  : const Color(0xFF92400E),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Nilai: ${n.nilai.toStringAsFixed(0)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          n.attempt == 1 ? '(Awal)' : '(Remedial)',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (isLast) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Aktif',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF047857),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        if (existingNilaiList.length > 1)
                                          InkWell(
                                            onTap: () async {
                                              await context
                                                  .read<AppProvider>()
                                                  .hapusNilaiAttempt(
                                                    kelasId: kelas.id,
                                                    muridId: murid.id,
                                                    nilaiId: n.id,
                                                  );
                                              if (ctx.mounted) Navigator.of(ctx).pop();
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.delete_outline_rounded,
                                                size: 16,
                                                color: Color(0xFFEF4444),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          // Toggle Mode Remedial vs Mode Koreksi
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isKoreksi
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isKoreksi
                                    ? const Color(0xFFBFDBFE)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isKoreksi
                                      ? Icons.edit_note_rounded
                                      : Icons.replay_rounded,
                                  size: 18,
                                  color: isKoreksi
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isKoreksi
                                            ? 'Mode Koreksi (Tetap Attempt ${existingNilaiList.length})'
                                            : 'Mode Remedial (Menjadi Attempt $attemptBerikutnya)',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isKoreksi
                                              ? const Color(0xFF1E40AF)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                      Text(
                                        isKoreksi
                                            ? 'Memperbaiki salah input tanpa menambah attempt.'
                                            : 'Menambah riwayat attempt remedial siswa.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isKoreksi,
                                  activeTrackColor: const Color(0xFF2563EB),
                                  onChanged: (val) => setSheetState(() => isKoreksi = val),
                                ),
                              ],
                            ),
                          ),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isKoreksi
                                  ? 'Koreksi Nilai Murid (0 - 100)'
                                  : (hasRiwayat
                                      ? 'Input Nilai Remedial (Attempt $attemptBerikutnya)'
                                      : 'Nilai Murid (0 - 100)'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (latestNilai != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Terakhir: ${latestNilai.nilai.toStringAsFixed(0)}',
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
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
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
                                        isKoreksi: isKoreksi,
                                      );
                                  if (ctx.mounted) {
                                    AppFeedback.showSuccess(
                                      context,
                                      isKoreksi
                                          ? 'Nilai berhasil dikoreksi!'
                                          : (hasRiwayat
                                              ? 'Remedial (Attempt $attemptBerikutnya) tersimpan!'
                                              : 'Nilai berhasil disimpan!'),
                                    );
                                  }
                                }
                              }
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                            child: Text(
                              isKoreksi
                                  ? 'Simpan Koreksi Nilai'
                                  : (hasRiwayat
                                      ? 'Simpan Remedial (Attempt $attemptBerikutnya)'
                                      : 'Simpan Nilai'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
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
  final List<Nilai> riwayatNilai;
  final VoidCallback onTapAddRemedial;
  final VoidCallback onTapEdit;

  const _MuridNilaiCard({
    required this.index,
    required this.murid,
    required this.nilaiHasil,
    required this.riwayatNilai,
    required this.onTapAddRemedial,
    required this.onTapEdit,
  });

  String _formatRiwayatText(List<Nilai> riwayat) {
    if (riwayat.isEmpty) return 'Belum ada percobaan';
    return riwayat.asMap().entries.map((entry) {
      final idx = entry.key;
      final n = entry.value;
      final label = idx == 0 ? 'Tes 1' : 'Remedial $idx';
      return '$label (${n.nilai.toStringAsFixed(0)})';
    }).join(' ➔ ');
  }

  @override
  Widget build(BuildContext context) {
    final hasNilai = nilaiHasil != null;
    final hasRemedial = riwayatNilai.length > 1;
    final attemptCount = riwayatNilai.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasRemedial
              ? const Color(0xFFFCD34D)
              : (hasNilai ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
          width: hasRemedial ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Header: Avatar/Ikon + Budi Pratama (NIS: 1024) + Tag Status
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasRemedial
                        ? const Color(0xFFFEF3C7)
                        : (hasNilai
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    murid.nama.isNotEmpty ? murid.nama[0].toUpperCase() : '$index',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: hasRemedial
                          ? const Color(0xFF92400E)
                          : (hasNilai ? AppColors.primary : AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              murid.nama,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(NIS: ${murid.nis ?? '-'})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge Kanan Atas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: hasRemedial
                        ? const Color(0xFFFFFBEB)
                        : (hasNilai ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasRemedial
                          ? const Color(0xFFFCD34D)
                          : (hasNilai ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    hasRemedial
                        ? 'Remedial'
                        : (hasNilai ? 'Tuntas' : 'Belum Dinilai'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: hasRemedial
                          ? const Color(0xFFB45309)
                          : (hasNilai ? const Color(0xFF059669) : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Baris Metrik: Nilai [ 85 ] (Benefit) & Percobaan [ 2x ] (Cost)
            Row(
              children: [
                // Kotak Nilai (Benefit)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasNilai
                          ? (hasRemedial ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4))
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasNilai
                            ? (hasRemedial ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0))
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nilai',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Benefit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasNilai ? nilaiHasil!.nilai.toStringAsFixed(0) : '-',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: hasNilai
                                ? (hasRemedial ? const Color(0xFF92400E) : const Color(0xFF166534))
                                : AppColors.textSecondary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Kotak Percobaan (Cost)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasRemedial ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasRemedial ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Percobaan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Cost',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          attemptCount > 0 ? '${attemptCount}x' : '0x',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: hasRemedial
                                ? const Color(0xFF92400E)
                                : (attemptCount > 0 ? AppColors.textPrimary : AppColors.textSecondary),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Baris Riwayat: Riwayat: Tes 1 (70) ➔ Remedial 1 (85)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: hasRemedial
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasRemedial ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: hasRemedial ? const Color(0xFFB45309) : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Riwayat: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: hasRemedial ? const Color(0xFF92400E) : AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: _formatRiwayatText(riwayatNilai),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasRemedial ? const Color(0xFFB45309) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tombol Aksi: [ + Tambah Nilai Remedial ]    [ ✏️ Edit Nilai ]
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTapAddRemedial,
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Input Nilai',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (hasNilai) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTapEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                      label: Text(
                        'Edit / Koreksi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
  late TextEditingController _nilaiCtrl;
  late TextEditingController _searchCtrl;
  String _searchQuery = '';
  late Set<String> _selectedMuridIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nilaiCtrl = TextEditingController(text: '100');
    _searchCtrl = TextEditingController();
    _selectedMuridIds = widget.kelas.muridList.map((m) => m.id).toSet();
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

    final parsed = double.tryParse(_nilaiCtrl.text.replaceAll(',', '.'));
    if (parsed == null || parsed < 0 || parsed > 100) {
      AppFeedback.showError(context, 'Masukkan nilai valid antara 0 - 100');
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();

    for (final muridId in _selectedMuridIds) {
      final murid = widget.kelas.muridList.firstWhere((m) => m.id == muridId);
      final existing = murid.nilaiList
          .where((n) => n.kriteriaId == widget.kriteria.id && n.sesiId == widget.sesi.id)
          .toList();

      await provider.inputNilaiHasil(
        kelasId: widget.kelasId,
        muridId: murid.id,
        kriteriaId: widget.kriteria.id,
        sesiId: widget.sesi.id,
        nilai: parsed,
        isKoreksi: existing.isNotEmpty,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      final valStr = parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
      AppFeedback.showSuccess(
        context,
        'Berhasil menerapkan nilai $valStr untuk ${_selectedMuridIds.length} siswa pada ${widget.sesi.nama}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMuridList = widget.kelas.muridList.where((m) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final matchNama = m.nama.toLowerCase().contains(q);
      final matchNis = m.nis != null && m.nis!.toLowerCase().contains(q);
      return matchNama || matchNis;
    }).toList();

    final isAllFilteredSelected = filteredMuridList.isNotEmpty &&
        filteredMuridList.every((m) => _selectedMuridIds.contains(m.id));

    final dateText = 'Dibuat: ${_formatDate(widget.sesi.tanggal)}';

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

          // Header
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
                        '${widget.sesi.nama} • ${widget.kriteria.nama} ($dateText)',
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

          // Nilai Target & Quick Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nilai yang Diterapkan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Berlaku untuk semua siswa yang dicentang',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      height: 46,
                      child: TextField(
                        controller: _nilaiCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0-100',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.8),
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
                const SizedBox(height: 10),
                // Quick chips
                if (widget.kriteria.hasSubKriteria)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.kriteria.subKriteria!.map((sub) {
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
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _nilaiCtrl.text = valStr);
                          }
                        },
                      );
                    }).toList(),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['100', '95', '90', '85', '80', '75', '70'].map((preset) {
                        final isSelected = _nilaiCtrl.text == preset;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _nilaiCtrl.text = preset),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                preset,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Search & Selection Bar
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

          // Student List
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
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final murid = filteredMuridList[i];
                      final isSelected = _selectedMuridIds.contains(murid.id);

                      final existing = murid.nilaiList
                          .where((n) =>
                              n.kriteriaId == widget.kriteria.id &&
                              n.sesiId == widget.sesi.id)
                          .toList()
                        ..sort((a, b) => b.attempt.compareTo(a.attempt));

                      final hasNilai = existing.isNotEmpty;
                      final latestNilai = hasNilai ? existing.first : null;

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
                                      ? AppColors.primary.withValues(alpha: 0.15)
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
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            murid.nama,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (existing.length > 1) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFFDE68A),
                                              ),
                                            ),
                                            child: Text(
                                              'Attempt ${existing.length}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasNilai
                                          ? 'NIS: ${murid.nis ?? '-'} • Nilai saat ini: ${latestNilai!.nilai.toStringAsFixed(0)}'
                                          : 'NIS: ${murid.nis ?? '-'} • Belum dinilai',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: hasNilai ? FontWeight.w600 : FontWeight.w500,
                                        color: hasNilai
                                            ? const Color(0xFF047857)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Circular toggle checkmark
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

          // Bottom Action Button
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
                onPressed: _isSaving ? null : _terapkanNilai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
