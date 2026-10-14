import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../tutorial_screen.dart';

const _uuid = Uuid();

class BuatKelasScreen extends StatefulWidget {
  final Kelas? existingKelas;

  const BuatKelasScreen({super.key, this.existingKelas});

  @override
  State<BuatKelasScreen> createState() => _BuatKelasScreenState();
}

class _BuatKelasScreenState extends State<BuatKelasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaKelasCtrl = TextEditingController();

  List<Kriteria> _kriteriaList = [];
  bool _saving = false;

  bool get isEdit => widget.existingKelas != null;
  static const int _minKriteria = 3;
  static const int _maxKriteria = 7;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _namaKelasCtrl.text = widget.existingKelas!.nama;
      _kriteriaList = List.from(widget.existingKelas!.kriteria);
    } else {
      // Inisialisasi kriteria default yang lazim untuk penilaian sekolah (Kurikulum Merdeka)
      final tugasId = _uuid.v4();
      _kriteriaList = [
        Kriteria(
          id: _uuid.v4(),
          nama: 'Kehadiran',
          jenis: JenisKriteria.byProcess,
          inputType: InputType.attendance,
          arah: ArahKriteria.benefit,
          subKriteria: Kriteria.defaultPresensiSubKriteria,
        ),
        Kriteria(
          id: _uuid.v4(),
          nama: 'Keaktifan',
          jenis: JenisKriteria.byProcess,
          inputType: InputType.counter,
          arah: ArahKriteria.benefit,
        ),
        Kriteria(
          id: tugasId,
          nama: 'Tugas',
          jenis: JenisKriteria.byProduct,
          perSesi: true,
          arah: ArahKriteria.benefit,
          aggregationRule: AggregationRule.max,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _namaKelasCtrl.dispose();
    super.dispose();
  }

  // Buka dialog tambah kriteria
  void _tambahKriteria() async {
    if (_kriteriaList.length >= _maxKriteria) {
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
        existingCriteria: _kriteriaList,
        onAdd: (kriteria) {
          setState(() => _kriteriaList.add(kriteria));
        },
      ),
    );
  }

  // Buka dialog edit kriteria
  void _editKriteria(int idx) {
    showDialog(
      context: context,
      builder: (context) => AddCriterionDialog(
        criterion: _kriteriaList[idx],
        existingCriteria: _kriteriaList,
        onAdd: (updated) {
          setState(() => _kriteriaList[idx] = updated);
        },
      ),
    );
  }

  void _hapusKriteria(int idx) {
    setState(() => _kriteriaList.removeAt(idx));
  }

  void _toggleArah(int idx) {
    setState(() {
      final k = _kriteriaList[idx];
      _kriteriaList[idx] = k.copyWith(
        arah: k.arah == ArahKriteria.benefit
            ? ArahKriteria.cost
            : ArahKriteria.benefit,
      );
    });
  }



  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kriteriaList.length < _minKriteria) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 3 kriteria harus ditambahkan')),
      );
      return;
    }

    // Cek apakah ada perubahan kriteria saat edit
    bool kriteriaBerubah = false;
    if (isEdit) {
      final idLama = widget.existingKelas!.kriteria.map((e) => e.id).toSet();
      final idBaru = _kriteriaList.map((e) => e.id).toSet();
      kriteriaBerubah = idLama.length != idBaru.length || !idLama.containsAll(idBaru);

      if (kriteriaBerubah) {
        final setuju = await AppFeedback.showConfirmDialog(
          context,
          title: 'Perubahan Kriteria',
          message:
              'Menambah atau mengubah kriteria penilaian akan mereset bobot AHP kelas ini.\n\n'
              'Anda perlu menghitung ulang (re-calculate) bobot AHP agar proses perankingan SAW tetap valid. Lanjutkan?',
          confirmText: 'Ya, Lanjutkan',
          cancelText: 'Batal',
          isDanger: true,
          icon: Icons.warning_amber_rounded,
        );
        if (setuju != true) return;
      }
    }

    if (!mounted) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();

    try {
      if (isEdit) {
        await provider.editKelas(
          widget.existingKelas!.id,
          nama: _namaKelasCtrl.text.trim(),
          kriteria: _kriteriaList,
        );
      } else {
        await provider.tambahKelas(
          nama: _namaKelasCtrl.text.trim(),
          kriteria: _kriteriaList,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        if (isEdit && kriteriaBerubah) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kriteria diperbarui. Harap hitung ulang (re-calculate) bobot AHP!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan kelas: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildHeader(BuildContext context) {
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
                              isEdit ? 'Edit Kelas & Kriteria' : 'Buat Kelas dan Konfigurasi Kriteria',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEdit
                                  ? 'Perbarui data kelas & konfigurasi kriteria'
                                  : 'Konfigurasi nama kelas & parameter penilaian',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                children: [
                  // ── Card 1: Nama Kelas ──
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Nama Kelas',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _namaKelasCtrl,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Contoh: Kelas XII IPA 1',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                            ),
                            prefixIcon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama kelas wajib diisi'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Card 2: Kriteria Penilaian ──
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kriteria Penilaian',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Min. $_minKriteria, maks. $_maxKriteria kriteria',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kriteriaList.length >= _minKriteria
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${_kriteriaList.length}/$_maxKriteria kriteria',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kriteriaList.length >= _minKriteria
                                      ? const Color(0xFF059669)
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Action button: Tambah Kriteria
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _tambahKriteria,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: Text(
                              'Tambah Kriteria',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Kriteria list
                        if (_kriteriaList.isNotEmpty) ...[
                          Text(
                            'Daftar Kriteria Terpilih (${_kriteriaList.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(
                            _kriteriaList.length,
                            (i) => KriteriaRow(
                              kriteria: _kriteriaList[i],
                              onDelete: () => _hapusKriteria(i),
                              onToggleArah: () => _toggleArah(i),
                              onEdit: () => _editKriteria(i),
                              showEdit: true,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: EmptyState(
                              icon: '📋',
                              title: 'Belum ada kriteria',
                              subtitle: 'Tap tombol di atas untuk menambahkan',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simpan Button
                  ElevatedButton(
                    onPressed: _kriteriaList.length >= _minKriteria && !_saving
                        ? _simpan
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: AppColors.primary.withValues(alpha: 0.35),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isEdit ? 'Simpan Perubahan' : 'Simpan Kelas',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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
}



// ─── Dialog Tambah/Edit Kriteria ──────────────────────────────────────────────

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

  int _currentStep = 0;

  JenisKriteria _jenis = JenisKriteria.byProcess;
  InputType _inputType = InputType.number;
  ArahKriteria _arah = ArahKriteria.benefit;
  bool _isPenilaianBerulang = false;
  AggregationRule _aggregationRule = AggregationRule.max;
  bool _hasSubKriteria = false;
  List<SubKriteria> _subKriteriaList = [];
  bool _showFrekuensiHelp = false;
  bool _showFormatHelp = false;

  @override
  void initState() {
    super.initState();
    final c = widget.criterion;
    if (c != null) {
      _nameController.text = c.nama;
      _jenis = c.jenis;
      _inputType = c.inputType == InputType.counter ? InputType.counter : InputType.number;
      _arah = c.arah;
      _isPenilaianBerulang = c.isPenilaianBerulang;
      _aggregationRule = c.aggregationRule == AggregationRule.min
          ? AggregationRule.max
          : c.aggregationRule;
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
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    final nama = _nameController.text.trim();
    InputType? finalInputType;
    if (_jenis == JenisKriteria.byProcess) {
      final lower = nama.toLowerCase();
      final isPresensi = lower.contains('hadir') || lower.contains('presensi') || lower.contains('absen');
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

    widget.onAdd(
      Kriteria(
        id: widget.criterion?.id ?? _uuid.v4(),
        nama: nama,
        jenis: _jenis,
        inputType: finalInputType,
        arah: _arah,
        bobot: widget.criterion?.bobot ?? 0.0,
        perSesi: isProduct ? true : _isPenilaianBerulang,
        isPenilaianBerulang: isProduct ? true : _isPenilaianBerulang,
        isPenaltiPercobaan: isProduct,
        aggregationRule: _aggregationRule,
        subKriteria: _hasSubKriteria && validSubList.isNotEmpty ? validSubList : null,
      ),
    );
    Navigator.of(context).pop();
  }

  void _showMetodeRekapInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
            Expanded(
              child: Text(
                'Metode Rekap Nilai Akhir',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
                  Text(
                    'Bagaimana sistem mengambil 1 angka nilai skor jika siswa memiliki beberapa catatan pengulangan/remedial:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opsi 1: Nilai Tertinggi
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
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 18, color: Color(0xFFEAB308)),
                            const SizedBox(width: 6),
                            Text(
                              '1. Nilai Tertinggi (Max)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sistem mengambil skor tertinggi yang diperoleh siswa dari seluruh sesi perbaikan remedial.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contoh: Percobaan 1 = 60, Remedial = 85 -> Nilai yang dipakai: 85.',
                          style: GoogleFonts.plusJakartaSans(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calculate_rounded, size: 18, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 6),
                            Text(
                              '2. Rata-rata (Average)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sistem merata-ratakan seluruh nilai dari setiap sesi atau percobaan remedial siswa.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contoh: Percobaan 1 = 60, Remedial = 80 -> Nilai yang dipakai: 70.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
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
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Keadilan Sistem Otomatis (By Code): Jumlah percobaan siswa secara otomatis dihitung dengan normalisasi Cost (min/x) di backend. Siswa yang tuntas dengan percobaan lebih sedikit tetap memperoleh prioritas peringkat yang lebih tinggi secara adil.',
                            style: GoogleFonts.plusJakartaSans(
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
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TutorialScreen(initialCategoryIndex: 2),
                ),
              );
            },
            child: Text(
              'Buka Halaman Tutorial 📖',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
            child: Text(
              'Mengerti',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBadge(String number) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Text(
        '($number)',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String stepNumber,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepBadge(stepNumber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
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
            _stepBadge('6'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Metode Rekap Nilai Akhir',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _SegmentedRow<AggregationRule>(
          options: const [
            (AggregationRule.max, 'Nilai Max'),
            (AggregationRule.average, 'Rata-rata'),
          ],
          selected: _aggregationRule == AggregationRule.min ? AggregationRule.max : _aggregationRule,
          onChanged: (v) => setState(
            () => _aggregationRule = v ?? AggregationRule.max,
          ),
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
              const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _aggregationRule == AggregationRule.max
                      ? (_jenis == JenisKriteria.byProcess
                          ? 'Nilai Tertinggi (Max): Jika ada banyak catatan keaktifan/partisipasi, skor tertinggi yang diambil (cth: aktif 10x skor 30–60, nilai yang diambil 60).'
                          : 'Nilai Tertinggi (Max): Jika ada pengulangan/remedial, skor tertinggi yang diambil. Pengurangan akibat jumlah remedial diproses otomatis di latar belakang.')
                      : (_jenis == JenisKriteria.byProcess
                          ? 'Rata-rata (Average): Poin akhir dihitung dari rata-rata seluruh catatan keaktifan/partisipasi siswa.'
                          : 'Rata-rata (Average): Nilai akhir dihitung dari rata-rata seluruh catatan percobaan siswa.'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
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
    return _buildSectionCard(
      stepNumber: '4',
      title: 'Format Penugasan Produk',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SegmentedRow<bool>(
            options: const [
              (false, '1 Tugas Tunggal (0–100)'),
              (true, 'Beberapa Tugas Bertahap'),
            ],
            selected: _hasSubKriteria,
            onChanged: (val) {
              setState(() {
                _hasSubKriteria = val ?? false;
                if (_hasSubKriteria && _subKriteriaList.isEmpty) {
                  _subKriteriaList = [
                    SubKriteria(id: _uuid.v4(), nama: 'Tugas 1', nilai: 100),
                    SubKriteria(id: _uuid.v4(), nama: 'Tugas 2', nilai: 100),
                  ];
                }
              });
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    !_hasSubKriteria
                        ? '1 Tugas Tunggal: Guru memberikan 1 nilai tugas/proyek utuh untuk siswa (skala 0–100).'
                        : 'Beberapa Tugas Bertahap: Kriteria terdiri dari beberapa sesi tugas sejenis (cth: Tugas 1, Tugas 2).',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showSubKriteriaProductInfo(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      'Panduan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasSubKriteria) ...[
            const SizedBox(height: 14),
            ..._subKriteriaList.asMap().entries.map((entry) {
              final idx = entry.key;
              final sub = entry.value;
              return Padding(
                key: ValueKey('prod_${sub.id}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextFormField(
                          key: ValueKey('nama_prod_${sub.id}'),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
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
                      id: _uuid.v4(),
                      nama: 'Tugas ${_subKriteriaList.length + 1}',
                      nilai: 100,
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Tambah Penugasan',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubKriteriaProcessSection() {
    return _buildSectionCard(
      stepNumber: '5',
      title: 'Bentuk Nilai yang Diisi',
      trailing: InkWell(
        onTap: () => setState(() => _showFormatHelp = !_showFormatHelp),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _showFormatHelp ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _showFormatHelp ? Icons.info_rounded : Icons.info_outline_rounded,
            size: 18,
            color: _showFormatHelp ? AppColors.primary : const Color(0xFF94A3B8),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SegmentedRow<bool>(
            options: const [
              (false, 'Ketik Angka (0–100)'),
              (true, 'Pilihan Kategori Cepat'),
            ],
            selected: _hasSubKriteria,
            onChanged: (val) {
              setState(() {
                _hasSubKriteria = val ?? false;
                if (_hasSubKriteria) {
                  if (_subKriteriaList.isEmpty) {
                    final lower = _nameController.text.toLowerCase();
                    if (lower.contains('hadir') ||
                        lower.contains('presensi') ||
                        lower.contains('absen')) {
                      _subKriteriaList = Kriteria.defaultPresensiSubKriteria
                          .map((s) => s.copyWith(id: _uuid.v4()))
                          .toList();
                    } else {
                      _subKriteriaList = [
                        SubKriteria(id: _uuid.v4(), nama: 'Baik', nilai: 100),
                        SubKriteria(id: _uuid.v4(), nama: 'Cukup', nilai: 75),
                        SubKriteria(id: _uuid.v4(), nama: 'Kurang', nilai: 50),
                      ];
                    }
                  }
                } else {
                  _inputType = _isPenilaianBerulang ? InputType.counter : InputType.number;
                }
              });
            },
          ),
          if (_showFormatHelp) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !_hasSubKriteria
                          ? 'Ketik Angka (0–100): Guru memasukkan nilai angka mentah secara langsung untuk siswa (contoh: 80, 85, 100).'
                          : 'Pilihan Kategori: Guru cukup menekan tombol kategori yang disiapkan saat menilai di kelas (contoh: Hadir, Izin, Sakit atau Sangat Baik, Baik). Setiap kategori otomatis memiliki skor nilai.',
                      style: GoogleFonts.plusJakartaSans(
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
          if (_hasSubKriteria) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Daftar Opsi Kategori:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showSubKriteriaInfo(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.help_outline_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Panduan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._subKriteriaList.asMap().entries.map((entry) {
              final idx = entry.key;
              final sub = entry.value;
              return Padding(
                key: ValueKey('sub_${sub.id}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 38,
                        child: TextFormField(
                          key: ValueKey('nama_${sub.id}'),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
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
                          key: ValueKey('nilai_${sub.id}'),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (v) => sub.nilai = double.tryParse(v) ?? 0.0,
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
                      id: _uuid.v4(),
                      nama: '',
                      nilai: 0.0,
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Tambah Opsi Kategori',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
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
        surfaceTintColor: Colors.transparent,
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
            Expanded(
              child: Text(
                'Panduan Sub-Kriteria Penugasan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
                  Text(
                    'Sub-kriteria jenis Hasil / Produk digunakan untuk memecah instrumen evaluasi utama ke dalam beberapa sesi penilaian yang sejenis (satu domain).',
                    style: GoogleFonts.plusJakartaSans(
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prinsip Wajib: Harus Sejenis (Homogen)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kriteria Induk adalah instrumen utama (Tugas, UTS, atau UAS). Sub-kriteria di dalamnya wajib berupa sesi sejenis dari instrumen tersebut.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: const Color(0xFF166534),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚠️ Larangan Mencampur Tugas & Ujian',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB91C1C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Jangan memasukkan UTS atau UAS sebagai sub-kriteria di dalam Tugas. Ujian memiliki bobot AHP tersendiri, sehingga WAJIB dibuat sebagai Kriteria Induk mandiri (contoh: Kriteria Induk "UTS" atau "UAS").',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: const Color(0xFF991B1B),
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

                  Text(
                    'Contoh Penerapan yang Benar:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
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
            child: Text(
              'Buka Halaman Tutorial 📖',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
            child: Text(
              'Mengerti',
              style: GoogleFonts.plusJakartaSans(
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
        surfaceTintColor: Colors.transparent,
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
            Expanded(
              child: Text(
                'Panduan Kategori & Sub-Kriteria',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
              Text(
                'Kategori nilai digunakan sebagai pilihan cepat (rubrik standar) saat guru mencatat performa siswa selama proses KBM tanpa perlu mengetik angka manual.',
                style: GoogleFonts.plusJakartaSans(
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apakah Kategori Punya Arah Sendiri?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tidak perlu pusing! Kategori nilai TIDAK memiliki arah Cost/Benefit terpisah. Arah optimasi (Benefit/Cost) cukup diatur satu kali pada Kriteria Induknya.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: const Color(0xFF166534),
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

              Text(
                'Contoh Skenario Penggunaan:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Skenario 1: Presensi
              _buildSkenarioCard(
                title: '1. Presensi / Kehadiran Harian',
                desc: 'Opsi cepat absensi kehadiran di setiap sesi pertemuan.',
                chips: [
                  'Hadir: 100',
                  'Izin: 75',
                  'Sakit: 50',
                  'Alpha: 0',
                ],
              ),
              const SizedBox(height: 8),

              // Skenario 2: Sikap / Kerjasama
              _buildSkenarioCard(
                title: '2. Sikap / Kerjasama Kelompok',
                desc: 'Penilaian rubrik kualitatif saat diskusi atau praktikum tim.',
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
                desc: 'Penilaian kepatuhan terhadap deadline penyerahan tugas.',
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
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ingin panduan lengkap beserta rumus SAW & AHP? Akses menu Pusat Bantuan & Tutorial.',
                        style: GoogleFonts.plusJakartaSans(
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
            child: Text(
              'Buka Halaman Tutorial 📖',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Mengerti',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
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

  Widget _buildStepIndicator() {
    final steps = ['Identitas & Sifat', 'Skema Penilaian', 'Metode Rekap'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int index = 0; index < steps.length; index++) ...[
            Expanded(
              flex: _currentStep == index ? 5 : 2,
              child: InkWell(
                onTap: () {
                  if (index < _currentStep) {
                    setState(() => _currentStep = index);
                  } else if (index > _currentStep) {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() => _currentStep = index);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.symmetric(
                    horizontal: _currentStep == index ? 8 : 0,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: _currentStep == index
                        ? const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _currentStep == index
                        ? [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _currentStep == index
                              ? Colors.white
                              : (_currentStep > index
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFCBD5E1)),
                          shape: BoxShape.circle,
                          boxShadow: _currentStep > index
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: _currentStep > index
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _currentStep == index
                                      ? const Color(0xFF0F766E)
                                      : (_currentStep > index ? Colors.white : const Color(0xFF64748B)),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      if (_currentStep == index) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            steps[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (index < steps.length - 1)
              Container(
                width: 8,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentStep > index ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // (1) Nama Kriteria Card
        _buildSectionCard(
          stepNumber: '1',
          title: 'Nama Kriteria',
          child: TextFormField(
            controller: _nameController,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'cth: Keaktifan, Nilai Tugas, Presensi',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textHint,
              ),
              errorMaxLines: 3,
              errorStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nama kriteria wajib diisi';
              final trimmed = v.trim().toLowerCase();
              final isDuplicate = widget.existingCriteria.any((c) {
                if (widget.criterion != null && c.id == widget.criterion!.id) return false;
                return c.nama.trim().toLowerCase() == trimmed;
              });
              if (isDuplicate) {
                return 'Nama kriteria "$trimmed" sudah ada, gunakan nama lain';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 18),

        // (2) Kategori Penilaian Card
        _buildSectionCard(
          stepNumber: '2',
          title: 'Kategori Penilaian',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SegmentedRow<JenisKriteria>(
                options: const [
                  (JenisKriteria.byProcess, 'Nilai Proses'),
                  (JenisKriteria.byProduct, 'Nilai Produk'),
                ],
                selected: _jenis,
                onChanged: _onJenisChanged,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _jenis == JenisKriteria.byProcess
                            ? 'Nilai Proses: Dinilai selama KBM berlangsung (cth: Keaktifan, Presensi, Partisipasi).'
                            : 'Nilai Produk: Dinilai berbasis hasil/luaran karya siswa (cth: Tugas, Proyek, UTS, UAS).',
                        style: GoogleFonts.plusJakartaSans(
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
          ),
        ),
        const SizedBox(height: 18),

        // (3) Sifat Kriteria Card
        _buildSectionCard(
          stepNumber: '3',
          title: 'Sifat Kriteria',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SegmentedRow<ArahKriteria>(
                options: const [
                  (ArahKriteria.benefit, 'Menguntungkan (Benefit) ↑'),
                  (ArahKriteria.cost, 'Merugikan (Cost) ↓'),
                ],
                selected: _arah,
                onChanged: (v) => setState(() => _arah = v ?? _arah),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _arah == ArahKriteria.benefit
                            ? 'Menguntungkan (Benefit): Semakin tinggi nilai siswa (0–100), semakin menguntungkan untuk peringkat.'
                            : 'Merugikan (Cost): Semakin rendah nilai siswa, semakin menguntungkan untuk peringkat (cth: poin pelanggaran).',
                        style: GoogleFonts.plusJakartaSans(
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
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    if (_jenis == JenisKriteria.byProduct) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubKriteriaProductSection(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // (4) Cara Mencatat Nilai
        _buildSectionCard(
          stepNumber: '4',
          title: 'Cara Mencatat Nilai',
          trailing: InkWell(
            onTap: () => setState(() => _showFrekuensiHelp = !_showFrekuensiHelp),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _showFrekuensiHelp ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showFrekuensiHelp ? Icons.info_rounded : Icons.info_outline_rounded,
                size: 18,
                color: _showFrekuensiHelp ? AppColors.primary : const Color(0xFF94A3B8),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SegmentedRow<bool>(
                options: const [
                  (false, 'Sekali per Pertemuan'),
                  (true, 'Bisa Berkali-kali (Keaktifan)'),
                ],
                selected: _isPenilaianBerulang,
                onChanged: (v) {
                  setState(() {
                    _isPenilaianBerulang = v ?? false;
                    if (!_hasSubKriteria) {
                      _inputType = _isPenilaianBerulang ? InputType.counter : InputType.number;
                    }
                  });
                },
              ),
              if (_showFrekuensiHelp) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          !_isPenilaianBerulang
                              ? 'Sekali per Pertemuan: Nilai dicatat satu kali saja pada tiap sesi pertemuan (contoh: absensi/kehadiran atau ceklis harian).'
                              : 'Bisa Berkali-kali (Keaktifan): Guru dapat menekan tombol tambah berulang kali untuk mencatat poin keaktifan siswa selama jam pelajaran (contoh: keaktifan bertanya, menjawab pertanyaan).',
                          style: GoogleFonts.plusJakartaSans(
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
            ],
          ),
        ),
        const SizedBox(height: 18),

        // (5) Format Nilai Siswa
        _buildSubKriteriaProcessSection(),
      ],
    );
  }

  Widget _buildStep3Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildRekapNilaiContent(),
        ),
        const SizedBox(height: 18),
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final jenisLabel = _jenis == JenisKriteria.byProcess ? 'Nilai Proses' : 'Nilai Produk';
    final arahLabel = _arah == ArahKriteria.benefit
        ? 'Benefit (Makin tinggi makin baik)'
        : 'Cost (Makin rendah makin baik)';
    final rekapLabel = switch (_aggregationRule) {
      AggregationRule.max => 'Nilai Tertinggi (Max)',
      AggregationRule.average => 'Rata-rata (Avg)',
      AggregationRule.min => 'Nilai Tertinggi (Max)',
    };

    return Container(
      padding: const EdgeInsets.all(13),
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
              const Icon(Icons.fact_check_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Ringkasan Kriteria',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _summaryRow('Nama', _nameController.text.trim().isEmpty ? '-' : _nameController.text.trim()),
          _summaryRow('Kategori', jenisLabel),
          _summaryRow('Sifat Nilai', arahLabel),
          if (_jenis == JenisKriteria.byProcess) ...[
            _summaryRow(
              'Cara Catat',
              _isPenilaianBerulang ? 'Bisa Berkali-kali (Keaktifan)' : 'Sekali per Pertemuan',
            ),
            _summaryRow(
              'Bentuk Nilai',
              _hasSubKriteria
                  ? 'Pilihan Kategori (${_subKriteriaList.length} opsi)'
                  : 'Ketik Angka (0–100)',
            ),
          ] else ...[
            _summaryRow(
              'Format Penugasan',
              _hasSubKriteria
                  ? 'Tugas Bertahap (${_subKriteriaList.length} tugas)'
                  : '1 Tugas Tunggal (0–100)',
            ),
          ],
          _summaryRow('Metode Rekap', rekapLabel),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final isLastStep = _currentStep == 2;
    return Row(
      children: [
        if (_currentStep == 0)
          Expanded(
            child: Material(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  alignment: Alignment.center,
                  child: Text(
                    'Batal',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Material(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _currentStep--),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Kembali',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_currentStep == 0) {
                if (!_formKey.currentState!.validate()) return;
                setState(() => _currentStep = 1);
              } else if (_currentStep == 1) {
                setState(() => _currentStep = 2);
              } else {
                _submit();
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: AppColors.primary.withValues(alpha: 0.35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLastStep
                      ? (widget.criterion == null ? 'Tambah Kriteria' : 'Simpan Kriteria')
                      : 'Lanjut',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (!isLastStep) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ] else ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_rounded, size: 17),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepSubtitles = [
      'Langkah 1/3: Identitas & Sifat Kriteria',
      'Langkah 2/3: Skema Penginputan Nilai',
      'Langkah 3/3: Rekapitulasi & Konfirmasi',
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
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
                              widget.criterion == null ? 'Tambah Kriteria' : 'Edit Kriteria',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stepSubtitles[_currentStep],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Step Indicator
                  _buildStepIndicator(),

                  // Step Content
                  if (_currentStep == 0)
                    _buildStep1Content()
                  else if (_currentStep == 1)
                    _buildStep2Content()
                  else
                    _buildStep3Content(),

                  const SizedBox(height: 22),

                  // Bottom Action Buttons
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Segmented Row ────────────────────────────────────────────────────────────

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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
