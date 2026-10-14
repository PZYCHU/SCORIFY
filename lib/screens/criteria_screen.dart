import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'tutorial_screen.dart';

class CriteriaScreen extends StatefulWidget {
  const CriteriaScreen({super.key});

  @override
  State<CriteriaScreen> createState() => _CriteriaScreenState();
}

class _CriteriaScreenState extends State<CriteriaScreen> {
  final List<Kriteria> _criteria = [];

  void _loadDefaultCriteria() async {
    if (_criteria.isNotEmpty) {
      final confirm = await AppFeedback.showConfirmDialog(
        context,
        title: 'Muat Kriteria Bawaan',
        message:
            'Daftar kriteria saat ini akan diatur ulang ke 3 komponen umum penilaian kelas:\n\n'
            '• Kehadiran (Aspek Proses / Presensi)\n'
            '• Keaktifan (Aspek Proses / Partisipasi)\n'
            '• Tugas (Aspek Hasil / Penugasan)\n\n'
            'Catatan: Merupakan template awal praktik umum penilaian kelas (kombinasi aspek proses & hasil) yang dapat Anda ubah, tambah, atau hapus sesuai kebutuhan.\n\n'
            'Lanjutkan?',
        confirmText: 'Ya, Muat',
        cancelText: 'Batal',
      );
      if (!confirm) return;
    }

    const uuid = Uuid();
    setState(() {
      _criteria.clear();
      _criteria.addAll([
        Kriteria(
          id: uuid.v4(),
          nama: 'Kehadiran',
          jenis: JenisKriteria.byProcess,
          inputType: InputType.attendance,
          arah: ArahKriteria.benefit,
          subKriteria: Kriteria.defaultPresensiSubKriteria,
        ),
        Kriteria(
          id: uuid.v4(),
          nama: 'Keaktifan',
          jenis: JenisKriteria.byProcess,
          inputType: InputType.counter,
          arah: ArahKriteria.benefit,
        ),
        Kriteria(
          id: uuid.v4(),
          nama: 'Tugas',
          jenis: JenisKriteria.byProduct,
          perSesi: true,
          arah: ArahKriteria.benefit,
          aggregationRule: AggregationRule.max,
        ),
      ]);
    });

    if (mounted) {
      AppFeedback.showSuccess(
        context,
        '3 Kriteria bawaan berhasil dimuat (Kehadiran, Keaktifan, Tugas)',
      );
    }
  }

  void _addCriterion() {
    if (_criteria.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maksimal 7 kriteria per kelas sesuai batasan rasio konsistensi AHP (Saaty CR ≤ 0.10).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AddCriterionDialog(
        existingCriteria: _criteria,
        onAdd: (criterion) {
          setState(() {
            _criteria.add(criterion);
          });
        },
      ),
    );
  }

  void _editCriterion(Kriteria criterion) {
    showDialog(
      context: context,
      builder: (context) => AddCriterionDialog(
        criterion: criterion,
        existingCriteria: _criteria,
        onAdd: (updatedCriterion) {
          setState(() {
            final index = _criteria.indexWhere((c) => c.id == criterion.id);
            if (index != -1) {
              _criteria[index] = updatedCriterion;
            }
          });
        },
      ),
    );
  }

  void _deleteCriterion(Kriteria criterion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kriteria'),
        content: Text('Yakin hapus "${criterion.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _criteria.remove(criterion));
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Label & icon helper
  String _inputTypeLabel(InputType? t) => switch (t) {
    InputType.counter => 'Penilaian Berulang',
    InputType.attendance => 'Presensi / Kehadiran',
    InputType.number => 'Sekali Catat',
    null => '—',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kriteria Penilaian'),
        actions: [
          IconButton(
            tooltip: 'Muat Kriteria Default',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _loadDefaultCriteria,
          ),
        ],
      ),
      body: _criteria.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kriteria',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan kriteria penilaian untuk kelas ini',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _criteria.length,
              itemBuilder: (context, index) {
                final c = _criteria[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(c.nama),
                    subtitle: Row(
                      children: [
                        if (c.inputType != null) ...[
                          _Chip(
                            label: _inputTypeLabel(c.inputType),
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                        ],
                        _Chip(
                          label: c.arah == ArahKriteria.benefit
                              ? 'Benefit'
                              : 'Cost',
                          color: c.arah == ArahKriteria.benefit
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCriterion(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCriterion(c),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCriterion,
        tooltip: 'Tambah Kriteria',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Chip kecil untuk label ───────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Dialog tambah/edit kriteria ─────────────────────────────────────────────

class AddCriterionDialog extends StatefulWidget {
  final Kriteria? criterion;
  final List<Kriteria> existingCriteria;
  final Function(Kriteria) onAdd;

  const AddCriterionDialog({
    super.key,
    this.criterion,
    this.existingCriteria = const [],
    required this.onAdd,
  });

  @override
  State<AddCriterionDialog> createState() => _AddCriterionDialogState();
}

class _AddCriterionDialogState extends State<AddCriterionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  JenisKriteria _jenis = JenisKriteria.byProcess;
  InputType _inputType = InputType.number;
  ArahKriteria _arah = ArahKriteria.benefit;
  bool _isPenilaianBerulang = false;
  AggregationRule _aggregationRule = AggregationRule.max;
  bool _hasSubKriteria = false;
  List<SubKriteria> _subKriteriaList = [];

  @override
  void initState() {
    super.initState();
    final c = widget.criterion;
    if (c != null) {
      _nameController.text = c.nama;
      _jenis = c.jenis;
      _inputType = c.inputType == InputType.counter
          ? InputType.counter
          : InputType.number;
      _arah = c.arah;
      _isPenilaianBerulang = c.isPenilaianBerulang;
      _aggregationRule = c.aggregationRule;
      _hasSubKriteria = c.hasSubKriteria;
      _subKriteriaList = c.hasSubKriteria
          ? c.subKriteria!.map((s) => s.copyWith()).toList()
          : [];
    } else {
      _jenis = JenisKriteria.byProcess;
      _isPenilaianBerulang = false;
      _inputType = InputType.number;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onJenisChanged(JenisKriteria? val) {
    if (val == null) return;
    setState(() {
      _jenis = val;
      _inputType = InputType.number;
      _isPenilaianBerulang = val == JenisKriteria.byProduct;
      _arah = ArahKriteria.benefit;
      _aggregationRule = AggregationRule.max;
      _hasSubKriteria = false;
      _subKriteriaList = [];
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final nama = _nameController.text.trim();
    InputType? finalInputType;
    if (_jenis == JenisKriteria.byProcess) {
      final lower = nama.toLowerCase();
      final isPresensi =
          lower.contains('hadir') ||
          lower.contains('presensi') ||
          lower.contains('absen');
      if (isPresensi) {
        finalInputType = InputType.attendance;
      } else if (_inputType == InputType.counter || _isPenilaianBerulang) {
        finalInputType = InputType.counter;
      } else {
        finalInputType = InputType.number;
      }
    } else {
      finalInputType = InputType.number;
    }

    final isProduct = _jenis == JenisKriteria.byProduct;
    final validSubList = _subKriteriaList
        .where((s) => s.nama.trim().isNotEmpty)
        .toList();

    final criterion = Kriteria(
      id:
          widget.criterion?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nama: nama,
      jenis: _jenis,
      inputType: finalInputType,
      arah: _arah,
      bobot: widget.criterion?.bobot ?? 0.0,
      perSesi: isProduct ? true : _isPenilaianBerulang,
      isPenilaianBerulang: isProduct ? true : _isPenilaianBerulang,
      isPenaltiPercobaan: isProduct,
      aggregationRule: _aggregationRule,
      subKriteria: _hasSubKriteria && validSubList.isNotEmpty
          ? validSubList
          : null,
    );
    widget.onAdd(criterion);
    Navigator.of(context).pop();
  }

  void _showMetodeRekapInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        actionsOverflowButtonSpacing: 8,
        actionsAlignment: MainAxisAlignment.end,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Panduan Rekap Nilai & Percobaan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.65,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aturan bagaimana sistem mengambil 1 angka nilai jika siswa memiliki beberapa kali catatan nilai atau pengulangan (remedial):',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Opsi 1: Nilai Tertinggi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFEAB308),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '1. Nilai Tertinggi (Max)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sistem mengambil skor tertinggi yang diperoleh siswa dari seluruh sesi/percobaan.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Contoh: Percobaan 1 = 70, Percobaan 2 = 85 → Nilai yang dipakai: 85.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Opsi 2: Rata-rata
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calculate_rounded,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '2. Rata-rata (Average)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sistem merata-ratakan seluruh nilai dari setiap sesi atau percobaan siswa.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Contoh: Percobaan 1 = 70, Percobaan 2 = 90 → Nilai yang dipakai: 80 ((70 + 90) / 2).',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Opsi 3: Nilai Terendah
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_down_rounded,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '3. Nilai Terendah (Min)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sistem mengambil skor terkecil dari seluruh catatan nilai siswa (berguna untuk baseline kompetensi).',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Catatan Keadilan Sistem Otomatis
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Keadilan Sistem Otomatis (By Code): Jumlah percobaan siswa secara otomatis dihitung dengan normalisasi Cost (min/x) di backend. Siswa yang tuntas dengan percobaan lebih sedikit tetap memperoleh prioritas peringkat yang lebih tinggi secara adil.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: AppColors.textPrimary,
                            ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Mengerti',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubKriteriaProductInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        actionsOverflowButtonSpacing: 8,
        actionsAlignment: MainAxisAlignment.end,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Panduan Sub-Kriteria Penugasan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sub-kriteria jenis Hasil / Produk digunakan untuk memecah instrumen evaluasi utama ke dalam beberapa sesi penilaian yang sejenis (satu domain).',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Prinsip 1: Homogenitas
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prinsip Wajib: Harus Sejenis (Homogen)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Kriteria Induk adalah instrumen utama (Tugas, UTS, atau UAS). Sub-kriteria di dalamnya wajib berupa sesi sejenis dari instrumen tersebut.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF166534),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Prinsip 2: Larangan Pencampuran
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚠️ Larangan Mencampur Tugas & Ujian',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Jangan memasukkan UTS atau UAS sebagai sub-kriteria di dalam Tugas. Ujian memiliki bobot AHP tersendiri, sehingga WAJIB dibuat sebagai Kriteria Induk mandiri (contoh: Kriteria Induk "UTS" atau "UAS").',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF991B1B),
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

                  const Text(
                    'Contoh Penerapan yang Benar:',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  _buildSkenarioCard(
                    title: '1. Kriteria Induk: TUGAS',
                    desc: 'Rincian tugas harian atau proyek siswa:',
                    chips: [
                      'Tugas 1 (Individu)',
                      'Tugas 2 (Kelompok)',
                      'Tugas 3 (Presentasi)',
                    ],
                  ),
                  const SizedBox(height: 6),

                  _buildSkenarioCard(
                    title: '2. Kriteria Induk: UTS / UAS',
                    desc: 'Pembagian sesi atau materi ujian:',
                    chips: [
                      'UTS Individu',
                      'UTS Kelompok',
                      'UTS Bab 1 / Bab 2',
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TutorialScreen(initialCategoryIndex: 2),
                ),
              );
            },
            child: const Text(
              'Buka Halaman Tutorial 📖',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Mengerti',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubKriteriaInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        actionsOverflowButtonSpacing: 8,
        actionsAlignment: MainAxisAlignment.end,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Panduan Kategori & Sub-Kriteria',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori nilai digunakan sebagai pilihan cepat (rubrik standar) saat guru mencatat performa siswa selama proses KBM tanpa perlu mengetik angka manual.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Penjelasan Arah (Cost / Benefit)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apakah Kategori Punya Arah Sendiri?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tidak perlu pusing! Kategori nilai TIDAK memiliki arah Cost/Benefit terpisah. Arah optimasi (Benefit/Cost) cukup diatur satu kali pada Kriteria Induknya.',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF166534),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Contoh Skenario Penggunaan:',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Skenario 1: Presensi
                  _buildSkenarioCard(
                    title: '1. Presensi / Kehadiran Harian',
                    desc:
                        'Opsi cepat absensi kehadiran di setiap sesi pertemuan.',
                    chips: ['Hadir: 100', 'Izin: 75', 'Sakit: 50', 'Alpha: 0'],
                  ),
                  const SizedBox(height: 8),

                  // Skenario 2: Sikap / Kerjasama
                  _buildSkenarioCard(
                    title: '2. Sikap / Kerjasama Kelompok',
                    desc:
                        'Penilaian rubrik kualitatif saat diskusi atau praktikum tim.',
                    chips: [
                      'Sangat Baik: 100',
                      'Baik: 80',
                      'Cukup: 60',
                      'Kurang: 40',
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Skenario 3: Kedisiplinan Tugas
                  _buildSkenarioCard(
                    title: '3. Ketepatan Waktu Pengumpulan',
                    desc:
                        'Penilaian kepatuhan terhadap deadline penyerahan tugas.',
                    chips: [
                      'Tepat Waktu: 100',
                      'Telat 1 Hari: 80',
                      'Telat >2 Hari: 50',
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Info Pusat Bantuan
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ingin panduan lengkap beserta rumus SAW & AHP? Akses menu Pusat Bantuan & Tutorial.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TutorialScreen(initialCategoryIndex: 2),
                ),
              );
            },
            child: const Text(
              'Buka Halaman Tutorial 📖',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Mengerti',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekapNilaiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Metode Rekap Nilai Akhir',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            InkWell(
              onTap: () => _showMetodeRekapInfo(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _jenis == JenisKriteria.byProcess
              ? 'Cara sistem mengambil skor jika siswa memiliki banyak catatan/keaktifan:'
              : 'Cara sistem mengambil skor jika siswa memiliki pengulangan/remedial:',
          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        _SegmentedRow<AggregationRule>(
          options: const [
            (AggregationRule.max, 'Nilai Max'),
            (AggregationRule.average, 'Rata-rata'),
            (AggregationRule.min, 'Nilai Min'),
          ],
          selected: _aggregationRule,
          onChanged: (v) =>
              setState(() => _aggregationRule = v ?? AggregationRule.max),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _aggregationRule == AggregationRule.max
                      ? (_jenis == JenisKriteria.byProcess
                          ? 'Nilai Tertinggi (Max): Jika ada banyak catatan keaktifan/partisipasi, skor tertinggi yang diambil (cth: aktif 10x skor 30–60, nilai yang diambil 60).'
                          : 'Nilai Tertinggi (Max): Jika ada pengulangan/remedial, skor tertinggi yang diambil. Pengurangan akibat jumlah remedial diproses otomatis di latar belakang.')
                      : (_aggregationRule == AggregationRule.average
                            ? (_jenis == JenisKriteria.byProcess
                                ? 'Rata-rata (Average): Poin akhir dihitung dari rata-rata seluruh catatan keaktifan/partisipasi siswa.'
                                : 'Rata-rata (Average): Nilai akhir dihitung dari rata-rata seluruh catatan percobaan siswa.')
                            : (_jenis == JenisKriteria.byProcess
                                ? 'Nilai Terendah (Min): Nilai terendah dari seluruh catatan keaktifan siswa yang diambil.'
                                : 'Nilai Terendah (Min): Nilai terendah dari seluruh sesi/percobaan yang diambil sebagai skor dasar.')),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubKriteriaProductSection() {
    return Container(
      decoration: BoxDecoration(
        color: _hasSubKriteria ? const Color(0xFFF8FAFC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasSubKriteria
              ? const Color(0xFFCBD5E1)
              : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sub-Kriteria / Daftar Penugasan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showSubKriteriaProductInfo(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'Rincian sesi sejenis dari kriteria induk (cth: Tugas 1, 2, Individu, Kelompok, Bab 1/2). Jangan mencampur tugas dengan ujian.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            value: _hasSubKriteria,
            onChanged: (val) {
              setState(() {
                _hasSubKriteria = val;
                if (val && _subKriteriaList.isEmpty) {
                  _subKriteriaList = [
                    SubKriteria(id: const Uuid().v4(), nama: 'Tugas 1', nilai: 100),
                    SubKriteria(id: const Uuid().v4(), nama: 'Tugas 2', nilai: 100),
                    SubKriteria(id: const Uuid().v4(), nama: 'Tugas 3', nilai: 100),
                  ];
                }
              });
            },
          ),
          if (_hasSubKriteria) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._subKriteriaList.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final sub = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextFormField(
                                initialValue: sub.nama,
                                decoration: InputDecoration(
                                  hintText: 'Nama Penugasan (cth: Tugas ${idx + 1})',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12.5),
                                onChanged: (v) => sub.nama = v,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            onPressed: () {
                              setState(() {
                                _subKriteriaList.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _subKriteriaList.add(
                          SubKriteria(
                            id: const Uuid().v4(),
                            nama: 'Tugas ${_subKriteriaList.length + 1}',
                            nilai: 100,
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Tambah Penugasan',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubKriteriaProcessSection() {
    return Container(
      decoration: BoxDecoration(
        color: _hasSubKriteria ? const Color(0xFFF8FAFC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasSubKriteria
              ? const Color(0xFFCBD5E1)
              : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kategori (Opsi Nilai)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _showSubKriteriaInfo(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'Pilihan kategori cepat rubrik nilai (cth: Hadir, Izin, Sakit)',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            value: _hasSubKriteria,
            onChanged: (val) {
              setState(() {
                _hasSubKriteria = val;
                if (val && _subKriteriaList.isEmpty) {
                  final lower = _nameController.text.toLowerCase();
                  if (lower.contains('hadir') ||
                      lower.contains('presensi') ||
                      lower.contains('absen')) {
                    _subKriteriaList = Kriteria.defaultPresensiSubKriteria
                        .map((s) => s.copyWith(id: const Uuid().v4()))
                        .toList();
                  } else {
                    _subKriteriaList = [
                      SubKriteria(id: const Uuid().v4(), nama: 'Baik', nilai: 100),
                      SubKriteria(id: const Uuid().v4(), nama: 'Cukup', nilai: 75),
                      SubKriteria(id: const Uuid().v4(), nama: 'Kurang', nilai: 50),
                    ];
                  }
                }
              });
            },
          ),
          if (_hasSubKriteria) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._subKriteriaList.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final sub = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 38,
                              child: TextFormField(
                                initialValue: sub.nama,
                                decoration: InputDecoration(
                                  hintText: 'Label (cth: Hadir)',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(fontSize: 12.5),
                                onChanged: (v) => sub.nama = v,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 38,
                              child: TextFormField(
                                initialValue: sub.nilai % 1 == 0
                                    ? sub.nilai.toInt().toString()
                                    : sub.nilai.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Nilai (cth: 100)',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                onChanged: (v) =>
                                    sub.nilai = double.tryParse(v) ?? 0.0,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            onPressed: () {
                              setState(() {
                                _subKriteriaList.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _subKriteriaList.add(
                          SubKriteria(
                            id: const Uuid().v4(),
                            nama: '',
                            nilai: 0.0,
                          ),
                        );
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Tambah Kategori',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkenarioCard({
    required String title,
    required String desc,
    required List<String> chips,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: chips.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.criterion == null ? 'Tambah Kriteria' : 'Edit Kriteria',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nama kriteria',
                  hintText: 'cth: Keaktifan, Nilai Tugas',
                  errorMaxLines: 3,
                  errorStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                  final trimmed = v.trim().toLowerCase();
                  final isDuplicate = widget.existingCriteria.any((c) {
                    if (widget.criterion != null &&
                        c.id == widget.criterion!.id) {
                      return false;
                    }
                    return c.nama.trim().toLowerCase() == trimmed;
                  });
                  if (isDuplicate) {
                    return 'Nama kriteria "$trimmed" sudah ada, gunakan nama lain';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),



              // Jenis
              // Kategori Penilaian
              const Text(
                'Kategori Penilaian',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              _SegmentedRow<JenisKriteria>(
                options: const [
                  (JenisKriteria.byProcess, 'Nilai Proses'),
                  (JenisKriteria.byProduct, 'Nilai Produk'),
                ],
                selected: _jenis,
                onChanged: _onJenisChanged,
              ),
              const SizedBox(height: 6),
              _JenisHint(jenis: _jenis),
              const SizedBox(height: 20),

              // Sifat Kriteria (Arah Optimasi Nilai Skor)
              const Text(
                'Sifat Kriteria',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              _SegmentedRow<ArahKriteria>(
                options: const [
                  (ArahKriteria.benefit, 'Menguntungkan (Benefit) ↑'),
                  (ArahKriteria.cost, 'Merugikan (Cost) ↓'),
                ],
                selected: _arah,
                onChanged: (v) => setState(() => _arah = v ?? _arah),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _arah == ArahKriteria.benefit
                            ? 'Menguntungkan (Benefit): Semakin tinggi nilai siswa (0–100), semakin menguntungkan untuk peringkat.'
                            : 'Merugikan (Cost): Semakin rendah nilai siswa, semakin menguntungkan untuk peringkat (cth: pelanggaran).',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Cabang Konfigurasi Khusus Berdasarkan Kategori ───────────
              if (_jenis == JenisKriteria.byProduct) ...[
                // Sub-Kriteria / Daftar Penugasan (Ditukar: di atas metode rekap nilai)
                _buildSubKriteriaProductSection(),
                const SizedBox(height: 16),

                // Metode Rekap Nilai
                _buildRekapNilaiContent(),
                const SizedBox(height: 8),
              ] else ...[
                // Skema Input Nilai By Process
                const Text(
                  'Skema Input Nilai',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                _SegmentedRow<bool>(
                  options: const [
                    (false, 'Sekali Catat (0–100)'),
                    (true, 'Penilaian Berulang / Partisipasi'),
                  ],
                  selected: _isPenilaianBerulang,
                  onChanged: (v) {
                    setState(() {
                      _isPenilaianBerulang = v ?? false;
                      _inputType = _isPenilaianBerulang
                          ? InputType.counter
                          : InputType.number;
                    });
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  !_isPenilaianBerulang
                      ? 'Sekali Catat: Guru menginput nilai 1 kali per pertemuan (0–100).'
                      : 'Penilaian Berulang / Partisipasi: Poin dan frekuensi dicatat berkali-kali sepanjang sesi (cth: Keaktifan).',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Sub-Kriteria Rubrik Skala By Process
                _buildSubKriteriaProcessSection(),
                const SizedBox(height: 16),

                // Metode Rekap Nilai By Process
                _buildRekapNilaiContent(),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.criterion == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }
}

// ─── Hint teks per jenis ──────────────────────────────────────────────────────

class _JenisHint extends StatelessWidget {
  const _JenisHint({required this.jenis});
  final JenisKriteria jenis;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (jenis) {
      JenisKriteria.byProcess => (
        'Dinilai selama proses KBM berlangsung (Presensi, Keaktifan, Sikap)',
        AppColors.primary,
      ),
      JenisKriteria.byProduct => (
        'Dinilai berbasis luaran/hasil belajar (Tugas, Proyek, UTS, UAS)',
        AppColors.primaryLight,
      ),
    };
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

// ─── Segmented button row sederhana ──────────────────────────────────────────

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 6,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey.withValues(alpha: 0.4),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? color : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
