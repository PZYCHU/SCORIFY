import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

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
      // Inisialisasi kriteria default yang lazim untuk penilaian sekolah
      final tugasId = _uuid.v4();
      _kriteriaList = [
        Kriteria(
          id: _uuid.v4(),
          nama: 'Kehadiran',
          jenis: JenisKriteria.performa,
          inputType: InputType.attendance,
          arah: ArahKriteria.benefit,
        ),
        Kriteria(
          id: _uuid.v4(),
          nama: 'Keaktifan',
          jenis: JenisKriteria.performa,
          inputType: InputType.counter,
          arah: ArahKriteria.benefit,
        ),
        Kriteria(
          id: tugasId,
          nama: 'Nilai Tugas',
          jenis: JenisKriteria.hasil,
          perSesi: true,
          arah: ArahKriteria.benefit,
        ),
        Kriteria(
          id: _uuid.v4(),
          nama: 'Frekuensi Remedial',
          jenis: JenisKriteria.derived,
          arah: ArahKriteria.cost,
          targetKriteriaIds: [tugasId],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 7 kriteria')));
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
      // Derived selalu cost, tidak bisa di-toggle
      if (k.jenis == JenisKriteria.derived) return;
      _kriteriaList[idx] = k.copyWith(
        arah: k.arah == ArahKriteria.benefit
            ? ArahKriteria.cost
            : ArahKriteria.benefit,
      );
    });
  }

  void _muatKriteriaDefault() async {
    if (_kriteriaList.isNotEmpty) {
      final confirm = await AppFeedback.showConfirmDialog(
        context,
        title: 'Muat Kriteria Default',
        message:
            'Daftar kriteria saat ini akan digantikan dengan 4 kriteria standar sekolah (Kehadiran, Keaktifan, Nilai Tugas, Frekuensi Remedial). Lanjutkan?',
        confirmText: 'Ya, Muat',
        cancelText: 'Batal',
      );
      if (!confirm) return;
    }

    final tugasId = _uuid.v4();
    setState(() {
      _kriteriaList = [
        Kriteria(
          id: _uuid.v4(),
          nama: 'Kehadiran',
          jenis: JenisKriteria.performa,
          inputType: InputType.attendance,
          arah: ArahKriteria.benefit,
        ),
        Kriteria(
          id: _uuid.v4(),
          nama: 'Keaktifan',
          jenis: JenisKriteria.performa,
          inputType: InputType.counter,
          arah: ArahKriteria.benefit,
        ),
        Kriteria(
          id: tugasId,
          nama: 'Nilai Tugas',
          jenis: JenisKriteria.hasil,
          perSesi: true,
          arah: ArahKriteria.benefit,
        ),
        Kriteria(
          id: _uuid.v4(),
          nama: 'Frekuensi Remedial',
          jenis: JenisKriteria.derived,
          arah: ArahKriteria.cost,
          targetKriteriaIds: [tugasId],
        ),
      ];
    });

    if (mounted) {
      AppFeedback.showSuccess(context, '4 Kriteria default berhasil dimuat');
    }
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
                              isEdit ? 'Edit Kelas' : 'Buat Kelas Baru',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEdit
                                  ? 'Perbarui data kelas & konfigurasi kriteria SPK'
                                  : 'Konfigurasi parameter penilaian AHP-SAW',
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
                                '${_kriteriaList.length}/$_minKriteria kriteria',
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

                        // Action buttons: Tambah Manual & Muat Default
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _tambahKriteria,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: const Color(0xFFF8FAFC),
                                ),
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                label: Text(
                                  'Tambah Manual',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _muatKriteriaDefault,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                                label: Text(
                                  'Muat Default',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  JenisKriteria _jenis = JenisKriteria.performa;
  InputType? _inputType = InputType.counter;
  ArahKriteria _arah = ArahKriteria.benefit;
  List<String> _targetKriteriaIds = [];

  List<InputType> get _availableInputTypes => switch (_jenis) {
    JenisKriteria.performa => [
      InputType.counter,
      InputType.number,
    ],
    JenisKriteria.hasil => [InputType.number],
    JenisKriteria.derived => [],
  };

  @override
  void initState() {
    super.initState();
    final c = widget.criterion;
    if (c != null) {
      _nameController.text = c.nama;
      _jenis = c.jenis;
      _inputType = c.inputType;
      _arah = c.arah;
      _targetKriteriaIds = List.from(c.targetKriteriaIds);
    }
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    // Tipe input tetap pada apa yang dipilih user (Counter / Number)
    // Fitur 'Kehadiran' akan diaktifkan secara otomatis (Auto-Magic) 
    // oleh sistem di halaman detail berdasarkan deteksi kata kunci.
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onJenisChanged(JenisKriteria? val) {
    if (val == null) return;
    setState(() {
      _jenis = val;
      _inputType = switch (val) {
        JenisKriteria.performa => InputType.counter,
        JenisKriteria.hasil => InputType.number,
        JenisKriteria.derived => null,
      };
      if (val == JenisKriteria.derived) {
        _arah = ArahKriteria.cost;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = 'Frekuensi Remedial';
        }
        if (_targetKriteriaIds.isEmpty) {
          final kandidatList = widget.existingCriteria
              .where((k) =>
                  (k.inputType == InputType.number || k.jenis == JenisKriteria.hasil) &&
                  k.jenis != JenisKriteria.derived &&
                  k.id != widget.criterion?.id)
              .map((k) => k.id)
              .toList();
          _targetKriteriaIds = kandidatList;
        }
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_jenis == JenisKriteria.derived) {
      final availableKandidat = widget.existingCriteria
          .where((k) =>
              (k.inputType == InputType.number || k.jenis == JenisKriteria.hasil) &&
              k.jenis != JenisKriteria.derived &&
              k.id != widget.criterion?.id)
          .toList();
      if (availableKandidat.isNotEmpty && _targetKriteriaIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih minimal satu kriteria nilai untuk dihitung remedinya'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    widget.onAdd(
      Kriteria(
        id: widget.criterion?.id ?? _uuid.v4(),
        nama: _nameController.text.trim(),
        jenis: _jenis,
        inputType: _inputType,
        arah: _arah,
        bobot: widget.criterion?.bobot ?? 0.0,
        perSesi: _jenis == JenisKriteria.hasil,
        targetKriteriaIds: _jenis == JenisKriteria.derived ? _targetKriteriaIds : const [],
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDerived = _jenis == JenisKriteria.derived;
    final kandidatList = widget.existingCriteria
        .where((k) =>
            (k.inputType == InputType.number || k.jenis == JenisKriteria.hasil) &&
            k.jenis != JenisKriteria.derived &&
            k.id != widget.criterion?.id)
        .toList();

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
                              'Konfigurasi parameter penilaian',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
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
                  const SizedBox(height: 18),

                  // Nama
                  Text(
                    'Nama Kriteria',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'cth: Keaktifan, Nilai Tugas',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
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
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),

                  // Banner Text Hint Petunjuk Kehadiran
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                height: 1.45,
                                color: AppColors.textPrimary,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Petunjuk: ',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                                TextSpan(
                                  text: 'Sertakan kata ',
                                ),
                                TextSpan(
                                  text: '"Kehadiran"',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: ' atau ',
                                ),
                                TextSpan(
                                  text: '"Presensi"',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: ' pada nama kriteria agar otomatis mengaktifkan pencatatan presensi harian (Maks 100).',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Jenis
                  Text(
                    'Jenis Kriteria',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SegmentedRow<JenisKriteria>(
                    options: const [
                      (JenisKriteria.performa, 'Performa'),
                      (JenisKriteria.hasil, 'Hasil'),
                      (JenisKriteria.derived, 'Perhitungan Remedi'),
                    ],
                    selected: _jenis,
                    onChanged: _onJenisChanged,
                  ),
                  const SizedBox(height: 8),
                  _JenisHint(jenis: _jenis),
                  const SizedBox(height: 18),

                  // Checklist kriteria sumber jika derived
                  if (isDerived) ...[
                    Text(
                      'Hitung remedi dari kriteria nilai:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (kandidatList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Belum ada kriteria bertipe Nilai Angka (Tugas/Ujian). Kriteria ini akan memantau nilai yang ditambahkan nanti.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: kandidatList.map((k) {
                          final isSelected = _targetKriteriaIds.contains(k.id);
                          return FilterChip(
                            label: Text(k.nama),
                            selected: isSelected,
                            selectedColor: Colors.orange.shade100,
                            checkmarkColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? Colors.deepOrange : AppColors.border,
                              ),
                            ),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isSelected ? Colors.deepOrange.shade900 : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _targetKriteriaIds.add(k.id);
                                } else {
                                  _targetKriteriaIds.remove(k.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 18),
                  ],

                  // Input Type
                  if (!isDerived) ...[
                    Text(
                      'Cara Input',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SegmentedRow<InputType>(
                      options: _availableInputTypes
                          .map((t) => (t, _inputLabel(t)))
                          .toList(),
                      selected: _inputType,
                      onChanged: (v) => setState(() => _inputType = v),
                    ),
                    const SizedBox(height: 18),

                    // Arah
                    Text(
                      'Arah Optimasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SegmentedRow<ArahKriteria>(
                      options: const [
                        (ArahKriteria.benefit, 'Benefit ↑'),
                        (ArahKriteria.cost, 'Cost ↓'),
                      ],
                      selected: _arah,
                      onChanged: (v) => setState(() => _arah = v ?? _arah),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _arah == ArahKriteria.benefit
                          ? 'Semakin besar nilainya, semakin baik peringkatnya'
                          : 'Semakin kecil nilainya, semakin baik peringkatnya',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ] else ...[
                    Text(
                      'Arah: Cost ↓ (otomatis — semakin banyak remedi, semakin berkurang skornya)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
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
                          child: Text(
                            widget.criterion == null ? 'Tambah Kriteria' : 'Simpan Perubahan',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _inputLabel(InputType t) => switch (t) {
    InputType.counter => '➕ Poin Tambahan (+)',
    InputType.attendance => '📅 Presensi/Kehadiran (0–100)',
    InputType.number => '📝 Nilai Angka (0–100)',
  };
}

// ─── Jenis Hint ───────────────────────────────────────────────────────────────

class _JenisHint extends StatelessWidget {
  const _JenisHint({required this.jenis});
  final JenisKriteria jenis;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (jenis) {
      JenisKriteria.performa => (
        'Dinilai langsung saat KBM berlangsung (keaktifan, sikap)',
        AppColors.primary,
      ),
      JenisKriteria.hasil => (
        'Diinput setelah koreksi. Setiap tugas/tes punya sesi tersendiri',
        AppColors.primaryLight,
      ),
      JenisKriteria.derived => (
        'Dihitung otomatis dari frekuensi remedial siswa pada tugas/ujian pilihan',
        AppColors.warningDark,
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
