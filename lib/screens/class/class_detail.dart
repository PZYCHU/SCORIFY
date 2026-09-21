import 'dart:math' as math;
import 'package:flutter/material.dart';
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

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, kelas, provider),
                  if (kelas.kriteria.any((k) => k.bobot == 0.0))
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warningBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warningDark,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bobot AHP Perlu Dihitung',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.warningDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ada kriteria baru atau bobot belum diisi. Hitung ulang bobot AHP agar perankingan valid.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warningDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AhpScreen(kelasId: widget.kelasId),
                              ),
                            ),
                            child: const Text(
                              'Hitung',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Daftar Murid
                        Column(
                          children: [
                            Expanded(
                              child: kelas.muridList.isEmpty
                                  ? RefreshIndicator(
                                      onRefresh: () => provider.refresh(),
                                      child: ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          const SizedBox(height: 60),
                                          const EmptyState(
                                            icon: '👨‍🎓',
                                            title: 'Belum ada murid',
                                            subtitle:
                                                'Tambahkan murid secara manual atau import dari file Excel/CSV',
                                          ),
                                          const SizedBox(height: 24),
                                          Center(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.person_add_alt_1,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Tambah Siswa',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _showTambahSiswaOptions(
                                                    context,
                                                    kelas,
                                                  ),
                                            ),
                                          ),
                                        ],
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
                        // Tab 2: Tugas & Penilaian Sesi
                        InputNilaiHasilScreen(
                          kelasId: widget.kelasId,
                          isEmbedded: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  Widget _buildHeader(BuildContext context, Kelas kelas, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
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
              const SizedBox(width: 4),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kelas.nama,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HeaderChip(
                        icon: Icons.people_outline,
                        label: '${kelas.jumlahSiswa}',
                      ),
                      const SizedBox(width: 4),
                      _HeaderChip(
                        icon: Icons.tune,
                        label: '${kelas.jumlahKriteria}',
                      ),
                      const SizedBox(width: 4),
                      if (kelas.sudahKalkulasi)
                        _HeaderChip(
                          icon: Icons.check_circle_outline,
                          label: 'Terhitung',
                          color: const Color(0xFF34D399),
                          backgroundColor: const Color(
                            0xFF064E3B,
                          ).withValues(alpha: 0.6),
                        )
                      else
                        _HeaderChip(
                          icon: Icons.cancel_outlined,
                          label: 'Belum',
                          color: const Color(0xFFF87171),
                          backgroundColor: const Color(
                            0xFF7F1D1D,
                          ).withValues(alpha: 0.6),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, color: Colors.white),
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
                        builder: (_) => BuatKelasScreen(existingKelas: kelas),
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
            ],
          ),
          if (kelas.createdAt != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Dibuat ${_formatDate(kelas.createdAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(
                text: 'Daftar Murid',
                icon: Icon(Icons.people_outline, size: 18),
              ),
              Tab(
                text: 'Tugas & Sesi',
                icon: Icon(Icons.assignment_outlined, size: 18),
              ),
            ],
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIS siswa...',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchCtrl.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  fillColor: AppColors.surfaceWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Daftar Murid (${list.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () =>
                                _showTambahSiswaOptions(context, kelas),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '+ Siswa',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _showIsiMassalDialog(context, kelas),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.checklist_rtl_rounded,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Input Kolektif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
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
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.balance, size: 16),
              label: Text(
                bobotBelumDiisi ? 'Isi Bobot AHP' : 'Edit Bobot AHP',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.bar_chart_rounded, size: 16),
                    label: const Text(
                      'Lihat Hasil',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (kelas.muridList.isEmpty || bobotBelumDiisi)
                        ? null
                        : () => _jalankanKalkulasi(context, provider, kelas),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Hitung Ulang',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text(
                  'Hitung Nilai Akhir',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
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
                                e.key, // nama murid
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
      return; // batalkan kalkulasi
    }

    // ─ Semua data lengkap — jalankan kalkulasi ─
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Mengekspor Data Siswa ke Excel...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
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
        .where((k) => k.jenis == JenisKriteria.hasil)
        .toList();
    if (kriteriaHasil.isEmpty) {
      AppFeedback.showWarning(
        context,
        'Kelas ini belum memiliki kriteria dengan jenis hasil/tugas',
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
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Sesi Tugas',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Buat sesi penilaian baru untuk tugas atau ujian',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
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

                const Divider(height: 16, thickness: 0.8, indent: 20, endIndent: 20),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kriteriaHasil.length > 1) ...[
                        const Text(
                          'Kategori Kriteria',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                                    style: const TextStyle(
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
                      const Text(
                        'Nama Sesi Tugas / Ujian',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: namaCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Tugas Bab 1, Quiz 2, UTS',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
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
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
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
                          child: const Text(
                            'Tambah Tugas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(sheetCtx).padding.bottom),
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

    final actionableKriteria = kelas.kriteria
        .where((k) => k.jenis != JenisKriteria.derived)
        .toList();

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

  void _showQuickInputKriteriaDialog(
    BuildContext context,
    Kelas kelas,
    Murid murid,
    Kriteria kriteria,
  ) {
    if (kriteria.jenis == JenisKriteria.hasil) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InputNilaiHasilScreen(kelasId: kelas.id),
        ),
      );
      return;
    }

    if (kriteria.jenis == JenisKriteria.derived) {
      AppFeedback.showInfo(
        context,
        'Kriteria ini dihitung otomatis dari riwayat remedial.',
      );
      return;
    }

    final existingList = murid.getNilaiByKriteria(kriteria.id);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final nilaiHariIni = existingList.where((n) {
      final nStr = '${n.tanggal.year}-${n.tanggal.month}-${n.tanggal.day}';
      return nStr == todayStr;
    }).toList();

    final isCounter = kriteria.inputType == InputType.counter;

    double currentVal = 0;
    if (isCounter) {
      currentVal = existingList.fold(0.0, (sum, n) => sum + n.nilai);
    } else {
      if (nilaiHariIni.isNotEmpty) {
        currentVal = nilaiHariIni.first.nilai;
      } else if (existingList.isNotEmpty) {
        existingList.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        currentVal = existingList.first.nilai;
      }
    }

    final todayVal = nilaiHariIni.isNotEmpty ? nilaiHariIni.first.nilai : 0.0;
    final nameLower = kriteria.nama.toLowerCase();
    final isAttendance =
        kriteria.inputType == InputType.attendance ||
        nameLower.contains('hadir') ||
        nameLower.contains('kehadiran') ||
        nameLower.contains('absen') ||
        nameLower.contains('absensi') ||
        nameLower.contains('presensi') ||
        nameLower.contains('attendance');

    final ctrl =
        TextEditingController(); // Selalu kosongkan field awal agar guru mengetik nilai baru

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header Card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCounter
                          ? Icons.add_circle_outline
                          : Icons.edit_note_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kriteria.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          murid.nama,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Status Timestamp Pengisian Hari Ini
              Builder(
                builder: (ctx) {
                  if (!isAttendance) return const SizedBox();

                  final sudahDiisiHariIni = nilaiHariIni.isNotEmpty;
                  final prevDate = sudahDiisiHariIni
                      ? nilaiHariIni.first.tanggal
                      : null;
                  final jam = prevDate != null
                      ? prevDate.hour.toString().padLeft(2, '0')
                      : '';
                  final mnt = prevDate != null
                      ? prevDate.minute.toString().padLeft(2, '0')
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: sudahDiisiHariIni
                          ? AppColors.benefitChip
                          : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sudahDiisiHariIni
                            ? AppColors.benefitChipText.withValues(alpha: 0.3)
                            : AppColors.warningBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sudahDiisiHariIni
                              ? Icons.check_circle
                              : Icons.info_outline,
                          size: 18,
                          color: sudahDiisiHariIni
                              ? AppColors.benefitChipText
                              : AppColors.warningDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sudahDiisiHariIni
                                ? 'Status Hari Ini: Sudah dicatat ($jam:$mnt WIB • ${nilaiHariIni.first.nilai.toInt()} poin)'
                                : 'Status Hari Ini: Belum dicatat',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: sudahDiisiHariIni
                                  ? AppColors.benefitChipText
                                  : AppColors.warningDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Nilai Saat Ini Info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCounter ? 'Total poin saat ini:' : 'Nilai saat ini:',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currentVal % 1 == 0
                          ? '${currentVal.toInt()}'
                          : '$currentVal',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (isAttendance && currentVal >= 100) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MAX 100',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Input Field
              Text(
                isCounter ? 'Tambah Poin (+):' : 'Masukkan Nilai Baru:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final disableInput = isAttendance && nilaiHariIni.isNotEmpty;
                  return TextField(
                    controller: ctrl,
                    autofocus: !disableInput,
                    enabled: !disableInput,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: disableInput
                          ? AppColors.textHint
                          : AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: disableInput
                          ? 'Sudah diisi hari ini'
                          : (isCounter
                                ? 'Ketik poin tambahan (cth: 1, 2, 5)'
                                : 'Contoh: 85, 100'),
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: Icon(
                        isCounter ? Icons.add : Icons.pin,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                      suffixIcon: ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => ctrl.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              // Tombol Simpan
              Builder(
                builder: (context) {
                  final disableInput = isAttendance && nilaiHariIni.isNotEmpty;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: disableInput
                            ? Colors.grey.shade400
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        disableInput
                            ? 'Sudah Diisi'
                            : (isCounter ? 'Tambahkan Poin' : 'Simpan Nilai'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: disableInput
                          ? null
                          : () async {
                              final text = ctrl.text.trim().replaceAll(
                                ',',
                                '.',
                              );
                              final val = double.tryParse(text);
                              if (val == null) {
                                AppFeedback.showError(
                                  context,
                                  'Masukkan angka nilai yang valid',
                                );
                                return;
                              }

                              if (isAttendance &&
                                  currentVal >= 100 &&
                                  val > 0) {
                                AppFeedback.showWarning(
                                  context,
                                  'Poin ${kriteria.nama} ${murid.nama} sudah mencapai batas maksimal (100)',
                                );
                                return;
                              }

                              if (!sheetCtx.mounted) return;
                              Navigator.pop(sheetCtx);

                              final rawVal = isCounter ? (todayVal + val) : val;
                              final totalResult = isCounter
                                  ? (currentVal + val)
                                  : val;
                              // Cap / Batasi maksimal 100 poin hanya untuk kriteria presensi/kehadiran
                              final finalVal = isAttendance
                                  ? math.min(100.0, math.max(0.0, rawVal))
                                  : rawVal;

                              final provider = context.read<AppProvider>();
                              await provider.inputNilaiPerforma(
                                kelasId: kelas.id,
                                muridId: murid.id,
                                kriteriaId: kriteria.id,
                                nilai: finalVal,
                                tanggal: DateTime.now(),
                              );

                              if (context.mounted) {
                                final capInfo = isAttendance && rawVal > 100.0
                                    ? ' (Dibatasi maks 100)'
                                    : '';
                                final msg = isCounter
                                    ? 'Poin ${kriteria.nama} (+${val % 1 == 0 ? val.toInt() : val}) ditambahkan. Total: ${totalResult % 1 == 0 ? totalResult.toInt() : totalResult}$capInfo'
                                    : 'Nilai ${kriteria.nama} untuk ${murid.nama} tersimpan: ${finalVal % 1 == 0 ? finalVal.toInt() : finalVal}$capInfo';
                                AppFeedback.showSuccess(context, msg);
                              }
                            },
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

  void _showTambahSiswaOptions(BuildContext context, Kelas kelas) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surfaceWhite,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Tambah Siswa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Tambah Manual',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Input NIS dan Nama satu per satu'),
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
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_file_outlined,
                    color: AppColors.accent,
                  ),
                ),
                title: const Text(
                  'Import dari Excel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Unggah daftar siswa sekaligus via file Excel',
                ),
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
}

// ─── Murid Card ───────────────────────────────────────────────────────────────

class _MuridCard extends StatelessWidget {
  final Murid murid;
  final Kelas kelas;
  final int? rank;
  final VoidCallback onTapNilai;
  final ValueChanged<Kriteria> onTapKriteria;

  const _MuridCard({
    required this.murid,
    required this.kelas,
    required this.onTapNilai,
    required this.onTapKriteria,
    this.rank,
  });

  BoxDecoration get _rankDecoration {
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
            blurRadius: 4,
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
      );
    }
    return BoxDecoration(
      color: AppColors.surface,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter kriteria agar hanya kriteria Performa harian & Derived yang tampil di chip murid.
    // Kriteria Hasil (Tugas/Ujian berbasis sesi) dipisahkan ke tombol khusus "Daftar Tugas & Sesi".
    final displayKriteria = kelas.kriteria
        .where((k) => k.jenis != JenisKriteria.hasil)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rank != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: _rankDecoration,
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: (rank != null && rank! <= 3)
                            ? Colors.white
                            : AppColors.textSecondary,
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
                    if (murid.nis != null && murid.nis!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NIS ${murid.nis}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      murid.nama,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (murid.skorFinal != null)
                _SkorBadge(skor: murid.skorFinal!)
              else
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
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
            ],
          ),
          if (displayKriteria.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayKriteria.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (ctx, idx) {
                  final k = displayKriteria[idx];
                  final nilaiStr = _formatNilaiKriteria(k, murid);
                  return _InteractiveKriteriaTag(
                    nama: k.nama,
                    nilaiStr: nilaiStr,
                    onTap: () => onTapKriteria(k),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNilaiKriteria(Kriteria k, Murid murid) {
    if (k.jenis == JenisKriteria.derived) {
      final freq = murid.getFrekuensiNgulang(
        k.targetKriteriaIds.isNotEmpty ? k.targetKriteriaIds : null,
      );
      return '$freq';
    }

    final list = murid.getNilaiByKriteria(k.id);
    if (list.isEmpty) return '-';

    if (k.jenis == JenisKriteria.hasil) {
      // Nilai rata-rata / terakhir sesi
      list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      final val = list.first.nilai;
      return val % 1 == 0 ? val.toInt().toString() : val.toString();
    } else {
      if (k.inputType == InputType.counter) {
        // Counter / Akumulasi Poin: tampilkan total dari semua tanggal
        final total = list.fold(0.0, (sum, n) => sum + n.nilai);
        return total % 1 == 0 ? total.toInt().toString() : total.toString();
      } else {
        // Performa non-counter (misal nilai harian): ambil nilai hari ini atau terakhir
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
      content: 'Data ${murid.nama} akan dihapus. Lanjutkan?',
    );
    if (confirm && context.mounted) {
      await context.read<AppProvider>().hapusMurid(kelas.id, murid.id);
    }
  }
}

// ─── Widget kecil ─────────────────────────────────────────────────────────────

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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isFilled
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFilled
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nama,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isFilled ? FontWeight.w600 : FontWeight.w500,
                color: isFilled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isFilled ? AppColors.primary : Colors.black12,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                nilaiStr,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isFilled ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'SKOR FINAL',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            skor.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
  final Color? backgroundColor;

  const _HeaderChip({
    required this.icon,
    required this.label,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Colors.white;
    final bg = backgroundColor ?? Colors.white.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: color != null
            ? Border.all(color: color!.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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
  late TextEditingController _nilaiCtrl;
  late TextEditingController _searchCtrl;
  String? _selectedSesiId;
  String _searchQuery = '';
  late Set<String> _selectedMuridIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedKriteriaId = widget.actionableKriteria.first.id;
    _nilaiCtrl = TextEditingController(text: '100');
    _searchCtrl = TextEditingController();
    _selectedMuridIds = widget.kelas.muridList.map((m) => m.id).toSet();

    final firstK = widget.actionableKriteria.first;
    if (firstK.jenis == JenisKriteria.hasil) {
      final sesis = widget.kelas.getSesiByKriteria(firstK.id);
      if (sesis.isNotEmpty) {
        _selectedSesiId = sesis.first.id;
      }
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
    final isHasil = selectedKriteria.jenis == JenisKriteria.hasil;

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
      sesiId: isHasil ? _selectedSesiId : null,
      targetMuridIds: _selectedMuridIds.toList(),
      hanyaYangKosong: false,
    );

    if (mounted) {
      Navigator.pop(context);
      AppFeedback.showSuccess(
        context,
        'Berhasil memberi nilai kolektif ke ${_selectedMuridIds.length} siswa untuk kriteria "${selectedKriteria.nama}"',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedKriteria = widget.actionableKriteria.firstWhere(
      (k) => k.id == _selectedKriteriaId,
    );
    final isHasil = selectedKriteria.jenis == JenisKriteria.hasil;
    final sesis = isHasil
        ? widget.kelas.getSesiByKriteria(selectedKriteria.id)
        : <Sesi>[];

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
                        'Input Kolektif Siswa',
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
                                value: _selectedKriteriaId,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                items: widget.actionableKriteria.map((k) {
                                  final jenisLabel =
                                      k.jenis == JenisKriteria.hasil
                                      ? ' (Tugas/Tes)'
                                      : ' (Harian)';
                                  return DropdownMenuItem(
                                    value: k.id,
                                    child: Text(
                                      '${k.nama}$jenisLabel',
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
                                    setState(() {
                                      _selectedKriteriaId = val;
                                      final newK = widget.actionableKriteria
                                          .firstWhere((k) => k.id == val);
                                      if (newK.jenis == JenisKriteria.hasil) {
                                        final newSesis = widget.kelas
                                            .getSesiByKriteria(newK.id);
                                        _selectedSesiId = newSesis.isNotEmpty
                                            ? newSesis.first.id
                                            : null;
                                      } else {
                                        _selectedSesiId = null;
                                      }
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
                            'Nilai (Poin)',
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

                if (isHasil) ...[
                  const SizedBox(height: 10),
                  if (sesis.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warningBorder),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Belum ada sesi tugas untuk kriteria ini.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onShowTambahTugas(selectedKriteria.id);
                            },
                            child: const Text(
                              '+ Buat Sesi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      height: 44,
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
                          value: _selectedSesiId ?? sesis.first.id,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          items: sesis.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                'Sesi: ${s.nama}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSesiId = val);
                            }
                          },
                        ),
                      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredMuridList.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppColors.border.withValues(alpha: 0.4),
                      indent: 52,
                      endIndent: 4,
                    ),
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
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // Circular avatar initial
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.border.withValues(alpha: 0.3),
                                child: Text(
                                  murid.nama.isNotEmpty
                                      ? murid.nama[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Bold student name & muted NIS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      murid.nama,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'NIS: ${murid.nis != null && murid.nis!.isNotEmpty ? murid.nis : '-'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Circular mint-green checkmark toggle on right edge
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.accent
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent
                                        : AppColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
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
