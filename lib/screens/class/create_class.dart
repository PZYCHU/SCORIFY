import 'package:flutter/material.dart';
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

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kriteriaList.length < _minKriteria) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 3 kriteria harus ditambahkan')),
      );
      return;
    }

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
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: const AppBackButton(),
        ),
        title: Text(isEdit ? 'Edit Kelas' : 'Buat Kelas Baru'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nama Kelas ──
                const SectionLabel('Nama Kelas :'),
                TextFormField(
                  controller: _namaKelasCtrl,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama kelas',
                    suffixIcon: Icon(
                      Icons.edit_outlined,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama kelas wajib diisi'
                      : null,
                ),
                const SizedBox(height: 24),

                // ── Tambah Kriteria ──
                SectionLabel(
                  'Kriteria Penilaian :',
                  subtitle: '(Min. $_minKriteria, maks. $_maxKriteria)',
                ),
                _KriteriaCounter(
                  current: _kriteriaList.length,
                  min: _minKriteria,
                  max: _maxKriteria,
                ),
                const SizedBox(height: 12),

                // Tombol tambah kriteria
                GestureDetector(
                  onTap: _tambahKriteria,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.5),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tambah Kriteria',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Daftar Kriteria ──
                if (_kriteriaList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Kriteria yang tersimpan:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 32),
                  const Center(
                    child: EmptyState(
                      icon: '📋',
                      title: 'Belum ada kriteria',
                      subtitle: 'Tap tombol di atas untuk menambahkan',
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                BottomSaveButton(
                  label: isEdit ? 'Simpan Perubahan' : 'Simpan Kelas',
                  onPressed: _kriteriaList.length >= _minKriteria
                      ? _simpan
                      : null,
                  isLoading: _saving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Kriteria Counter ─────────────────────────────────────────────────────────

class _KriteriaCounter extends StatelessWidget {
  final int current, min, max;

  const _KriteriaCounter({
    required this.current,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final cukup = current >= min;
    return Row(
      children: [
        Icon(
          cukup ? Icons.check_circle : Icons.info_outline,
          size: 14,
          color: cukup ? AppColors.accent : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$current/$min kriteria minimum${current >= min ? " ✓" : ""}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cukup ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Dialog Tambah/Edit Kriteria ──────────────────────────────────────────────

class AddCriterionDialog extends StatefulWidget {
  final Kriteria? criterion;
  final Function(Kriteria) onAdd;

  const AddCriterionDialog({super.key, this.criterion, required this.onAdd});

  @override
  State<AddCriterionDialog> createState() => _AddCriterionDialogState();
}

class _AddCriterionDialogState extends State<AddCriterionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  JenisKriteria _jenis = JenisKriteria.performa;
  InputType? _inputType = InputType.counter;
  ArahKriteria _arah = ArahKriteria.benefit;

  List<InputType> get _availableInputTypes => switch (_jenis) {
    JenisKriteria.performa => [
      InputType.counter,
      InputType.stopwatch,
      InputType.toggle,
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
      _inputType = switch (val) {
        JenisKriteria.performa => InputType.counter,
        JenisKriteria.hasil => InputType.number,
        JenisKriteria.derived => null,
      };
      if (val == JenisKriteria.derived) _arah = ArahKriteria.cost;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onAdd(
      Kriteria(
        id: widget.criterion?.id ?? _uuid.v4(),
        nama: _nameController.text.trim(),
        jenis: _jenis,
        inputType: _inputType,
        arah: _arah,
        bobot: widget.criterion?.bobot ?? 0.0,
        perSesi: _jenis == JenisKriteria.hasil,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDerived = _jenis == JenisKriteria.derived;

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
                decoration: const InputDecoration(
                  labelText: 'Nama kriteria',
                  hintText: 'cth: Keaktifan, Nilai Tugas',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // Jenis
              const Text(
                'Jenis',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _SegmentedRow<JenisKriteria>(
                options: const [
                  (JenisKriteria.performa, 'Performa'),
                  (JenisKriteria.hasil, 'Hasil'),
                  (JenisKriteria.derived, 'Otomatis'),
                ],
                selected: _jenis,
                onChanged: _onJenisChanged,
              ),
              const SizedBox(height: 6),
              _JenisHint(jenis: _jenis),
              const SizedBox(height: 20),

              // Input Type
              if (!isDerived) ...[
                const Text(
                  'Cara input',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _SegmentedRow<InputType>(
                  options: _availableInputTypes
                      .map((t) => (t, _inputLabel(t)))
                      .toList(),
                  selected: _inputType,
                  onChanged: (v) => setState(() => _inputType = v),
                ),
                const SizedBox(height: 20),

                // Arah
                const Text(
                  'Arah',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                const SizedBox(height: 4),
                Text(
                  _arah == ArahKriteria.benefit
                      ? 'Semakin besar nilainya, semakin baik'
                      : 'Semakin kecil nilainya, semakin baik',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ] else ...[
                Text(
                  'Arah: Cost — dihitung otomatis dari frekuensi pengulangan',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
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

  String _inputLabel(InputType t) => switch (t) {
    InputType.counter => 'Counter',
    InputType.number => 'Angka',
    InputType.stopwatch => 'Stopwatch',
    InputType.toggle => 'Toggle',
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
        'Dinilai langsung saat KBM berlangsung',
        Colors.teal,
      ),
      JenisKriteria.hasil => (
        'Diinput setelah koreksi. Setiap tugas/tes punya sesi tersendiri',
        Colors.indigo,
      ),
      JenisKriteria.derived => (
        'Dihitung otomatis dari jumlah pengulangan nilai',
        Colors.orange,
      ),
    };
    return Text(text, style: TextStyle(fontSize: 12, color: color));
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
    final color = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey.withOpacity(0.4),
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
