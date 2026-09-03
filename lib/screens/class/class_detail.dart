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

class DetailKelasScreen extends StatelessWidget {
  final String kelasId;

  const DetailKelasScreen({super.key, required this.kelasId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final kelas = provider.getKelas(kelasId);
        if (kelas == null) {
          return const Scaffold(
            body: Center(child: Text('Kelas tidak ditemukan')),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, kelas, provider),
                Expanded(
                  child: kelas.muridList.isEmpty
                      ? RefreshIndicator(
                          onRefresh: () => provider.refresh(),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                icon: '👨‍🎓',
                                title: 'Belum ada murid',
                                subtitle:
                                    'Tap tombol + Tambah Siswa di bawah untuk menambahkan\nmurid ke kelas ini',
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
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Kelas kelas, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kelas.nama,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (val) async {
                  if (val == 'export') {
                    if (kelas.muridList.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Belum ada data siswa untuk diekspor'),
                          backgroundColor: AppColors.warning,
                        ),
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
                      await provider.hapusKelas(kelasId);
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
          const SizedBox(height: 14),
          Row(
            children: [
              _HeaderChip(
                icon: Icons.people_outline,
                label: '${kelas.jumlahSiswa} Siswa',
              ),
              const SizedBox(width: 10),
              _HeaderChip(
                icon: Icons.tune,
                label: '${kelas.jumlahKriteria} Kriteria',
              ),
              if (kelas.sudahKalkulasi) ...[
                const SizedBox(width: 10),
                _HeaderChip(
                  icon: Icons.check_circle_outline,
                  label: 'Terhitung',
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuridList(BuildContext context, Kelas kelas) {
    final list = List<Murid>.from(kelas.muridList);
    if (kelas.sudahKalkulasi) {
      list.sort((a, b) => (b.skorFinal ?? 0).compareTo(a.skorFinal ?? 0));
    } else {
      list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    }

    return Column(
      children: [
        // Sub-bar di atas list: Daftar Murid + Action Buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              Text(
                'Daftar Murid (${list.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Tombol Tambah Siswa
              InkWell(
                onTap: () => _showTambahSiswaOptions(context, kelas),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Isi Massal
              InkWell(
                onTap: () => _showIsiMassalDialog(context, kelas),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 14, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'Isi Massal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final murid = list[i];
              return _MuridCard(
                murid: murid,
                kelas: kelas,
                rank: kelas.sudahKalkulasi ? i + 1 : null,
                onTapNilai: () =>
                    showInputNilaiSheet(context, kelas: kelas, murid: murid),
                onTapKriteria: (kriteria) =>
                    _showQuickInputKriteriaDialog(context, kelas, murid, kriteria),
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
    final adaKriteriaHasil = kelas.kriteria.any(
      (k) => k.jenis == JenisKriteria.hasil,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris 1: AHP + Nilai Tugas
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: kelas.muridList.isEmpty
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AhpScreen(kelasId: kelasId),
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
                    bobotBelumDiisi ? 'Isi Bobot AHP' : 'Edit AHP',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (adaKriteriaHasil) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: kelas.muridList.isEmpty
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  InputNilaiHasilScreen(kelasId: kelasId),
                            ),
                          ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_outlined, size: 16),
                    label: const Text(
                      'Nilai Tugas',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Baris 2: Kalkulasi — pisah "Lihat Hasil" & "Hitung Ulang" jika sudah pernah dihitung
          if (kelas.sudahKalkulasi) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HasilKalkulasiScreen(kelasId: kelasId),
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
    // ─ Readiness check: semua nilai hasil harus ada ─
    final missing = provider.cekKesiapanKalkulasi(kelasId);
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

    final hasil = await provider.jalankanKalkulasi(kelasId);
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
          builder: (_) => HasilKalkulasiScreen(kelasId: kelasId),
        ),
      );
    }
  }

  Future<void> _exportExcel(BuildContext context, Kelas kelas) async {
    // Tampilkan loading
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Membuat file Excel...'),
          ],
        ),
        duration: Duration(seconds: 10),
        backgroundColor: Color(0xFF217346),
      ),
    );

    final path = await ExcelService.exportSiswa(kelas);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null
              ? 'File Excel disimpan:\n$path'
              : 'Gagal mengekspor data siswa',
        ),
        backgroundColor: path != null
            ? const Color(0xFF217346)
            : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showIsiMassalDialog(BuildContext context, Kelas kelas) {
    if (kelas.muridList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada siswa di kelas ini'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final kriteriaPerforma = kelas.kriteria
        .where((k) => k.jenis == JenisKriteria.performa)
        .toList();

    if (kriteriaPerforma.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada kriteria performa harian untuk diisi massal'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    String selectedKriteriaId = kriteriaPerforma.first.id;
    final nilaiCtrl = TextEditingController(text: '100');
    bool hanyaYangKosong = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectedKriteria =
              kriteriaPerforma.firstWhere((k) => k.id == selectedKriteriaId);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(Icons.bolt, color: AppColors.accent, size: 24),
                SizedBox(width: 8),
                Text(
                  'Isi Nilai Massal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Kriteria:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedKriteriaId,
                        isExpanded: true,
                        items: kriteriaPerforma.map((k) {
                          return DropdownMenuItem(
                            value: k.id,
                            child: Text(
                              k.nama,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedKriteriaId = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nilai / Poin yang Diterapkan:',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nilaiCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 100, 75, 1',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: hanyaYangKosong,
                    title: const Text(
                      'Hanya untuk siswa yang belum dinilai',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        hanyaYangKosong = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Akan diterapkan ke ${kelas.muridList.length} siswa untuk kriteria "${selectedKriteria.nama}".',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final parsed = double.tryParse(
                    nilaiCtrl.text.replaceAll(',', '.'),
                  );
                  if (parsed == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Masukkan angka nilai yang valid'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  final provider = context.read<AppProvider>();
                  await provider.inputNilaiMassal(
                    kelasId: kelas.id,
                    kriteriaId: selectedKriteriaId,
                    nilai: parsed,
                    hanyaYangKosong: hanyaYangKosong,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Berhasil mengisi nilai massal untuk ${selectedKriteria.nama}',
                        ),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kriteria ini dihitung otomatis dari riwayat remedial.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
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

    double currentVal = 0;
    if (nilaiHariIni.isNotEmpty) {
      currentVal = nilaiHariIni.first.nilai;
    } else if (existingList.isNotEmpty) {
      existingList.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      currentVal = existingList.first.nilai;
    }

    final isCounter = kriteria.inputType == InputType.counter;

    final ctrl = TextEditingController(); // Selalu kosongkan field awal agar guru mengetik nilai baru

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
                      isCounter ? Icons.add_circle_outline : Icons.edit_note_rounded,
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
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Nilai Saat Ini Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      isCounter ? 'Total poin saat ini:' : 'Nilai saat ini:',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      currentVal % 1 == 0 ? '${currentVal.toInt()}' : '$currentVal',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
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
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: isCounter ? 'Ketik poin tambahan (cth: 1, 2, 5)' : 'Contoh: 85, 100',
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    isCounter ? 'Tambahkan Poin' : 'Simpan Nilai',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () async {
                    final text = ctrl.text.trim().replaceAll(',', '.');
                    final val = double.tryParse(text);
                    if (val == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Masukkan angka nilai yang valid'),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(sheetCtx);

                    final finalVal = isCounter ? (currentVal + val) : val;

                    final provider = context.read<AppProvider>();
                    await provider.inputNilaiPerforma(
                      kelasId: kelas.id,
                      muridId: murid.id,
                      kriteriaId: kriteria.id,
                      nilai: finalVal,
                      tanggal: DateTime.now(),
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isCounter
                                      ? 'Poin ${kriteria.nama} (+${val % 1 == 0 ? val.toInt() : val}) ditambahkan. Total: ${finalVal % 1 == 0 ? finalVal.toInt() : finalVal}'
                                      : 'Nilai ${kriteria.nama} untuk ${murid.nama} tersimpan: ${finalVal % 1 == 0 ? finalVal.toInt() : finalVal}',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.accent,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
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
                      builder: (_) =>
                          TambahMuridScreen(kelasId: kelasId, kelas: kelas),
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
                      builder: (_) =>
                          ImportSiswaScreen(kelasId: kelasId, kelas: kelas),
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

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFF9A825);
    if (rank == 2) return const Color(0xFF9E9E9E);
    if (rank == 3) return const Color(0xFF8D6E63);
    return AppColors.primary.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rank != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: rank! <= 3
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NIS (jika ada)
                    if (murid.nis != null && murid.nis!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'NIS ${murid.nis}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    Text(
                      murid.nama,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
                    size: 18,
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
          const SizedBox(height: 10),
          // Baris tag kriteria yang bisa di-scroll ke samping
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kelas.kriteria.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (ctx, idx) {
                final k = kelas.kriteria[idx];
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

        final val = nilaiHariIni.isNotEmpty ? nilaiHariIni.first.nilai : list.last.nilai;
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isFilled
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFilled
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nama,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isFilled ? FontWeight.w600 : FontWeight.w500,
                color: isFilled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isFilled ? AppColors.accent : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                nilaiStr,
                style: TextStyle(
                  fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.scoreCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'Skor Final',
            style: TextStyle(fontSize: 9, color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            skor.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
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

  const _HeaderChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
