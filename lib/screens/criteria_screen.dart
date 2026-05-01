import 'package:flutter/material.dart';
import '../models/models.dart';

class CriteriaScreen extends StatefulWidget {
  const CriteriaScreen({super.key});

  @override
  State<CriteriaScreen> createState() => _CriteriaScreenState();
}

class _CriteriaScreenState extends State<CriteriaScreen> {
  final List<Kriteria> _criteria = [];

  void _addCriterion() {
    showDialog(
      context: context,
      builder: (context) => AddCriterionDialog(
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
  String _jenisLabel(JenisKriteria jenis) => switch (jenis) {
    JenisKriteria.performa => 'Performa',
    JenisKriteria.hasil => 'Hasil',
    JenisKriteria.derived => 'Otomatis',
  };

  String _inputTypeLabel(InputType? t) => switch (t) {
    InputType.counter => 'Akumulasi Poin',
    InputType.number => 'Angka',
    InputType.toggle => 'Toggle',
    null => '—',
  };

  Color _jenisColor(JenisKriteria jenis) => switch (jenis) {
    JenisKriteria.performa => Colors.teal,
    JenisKriteria.hasil => Colors.indigo,
    JenisKriteria.derived => Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        _Chip(
                          label: _jenisLabel(c.jenis),
                          color: _jenisColor(c.jenis),
                        ),
                        const SizedBox(width: 6),
                        if (c.inputType != null)
                          _Chip(
                            label: _inputTypeLabel(c.inputType),
                            color: Colors.grey,
                          ),
                        const SizedBox(width: 6),
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
        color: color.withOpacity(0.12),
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

  // Input type yang tersedia per jenis
  List<InputType> get _availableInputTypes => switch (_jenis) {
    JenisKriteria.performa => [
      InputType.counter,
      InputType.toggle,
      InputType.number,
    ],
    JenisKriteria.hasil => [InputType.number],
    JenisKriteria.derived => [], // tidak perlu input type
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
      // Reset input type ke default sesuai jenis
      _inputType = switch (val) {
        JenisKriteria.performa => InputType.counter,
        JenisKriteria.hasil => InputType.number,
        JenisKriteria.derived => null,
      };
      // Derived selalu cost
      if (val == JenisKriteria.derived) _arah = ArahKriteria.cost;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final criterion = Kriteria(
      id:
          widget.criterion?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nama: _nameController.text.trim(),
      jenis: _jenis,
      inputType: _inputType,
      arah: _arah,
      bobot: widget.criterion?.bobot ?? 0.0,
      perSesi: _jenis == JenisKriteria.hasil,
    );
    widget.onAdd(criterion);
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
              const SizedBox(height: 4),
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

              // Input Type — sembunyikan jika derived
              if (!isDerived) ...[
                const Text(
                  'Cara input',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                _SegmentedRow<InputType>(
                  options: _availableInputTypes
                      .map((t) => (t, _inputTypeShortLabel(t)))
                      .toList(),
                  selected: _inputType,
                  onChanged: (v) => setState(() => _inputType = v),
                ),
                const SizedBox(height: 20),
              ],

              // Arah — derived selalu cost, tidak perlu pilih
              if (!isDerived) ...[
                const Text(
                  'Arah',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
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
                  'Arah: Cost (otomatis — semakin sering ngulang, semakin buruk)',
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

  String _inputTypeShortLabel(InputType t) => switch (t) {
    InputType.counter => 'Akumulasi Poin',
    InputType.number => 'Angka',
    InputType.toggle => 'Toggle',
  };
}

// ─── Hint teks per jenis ──────────────────────────────────────────────────────

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
