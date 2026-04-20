import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

const _uuid = Uuid();

class BuatKelasScreen extends StatefulWidget {
  final Kelas? existingKelas; // null = buat baru, non-null = edit

  const BuatKelasScreen({super.key, this.existingKelas});

  @override
  State<BuatKelasScreen> createState() => _BuatKelasScreenState();
}

class _BuatKelasScreenState extends State<BuatKelasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaKelasCtrl = TextEditingController();
  final _namaKriteriaCtrl = TextEditingController();

  JenisKriteria _jenisSelected = JenisKriteria.benefit;
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
    _namaKriteriaCtrl.dispose();
    super.dispose();
  }

  void _tambahKriteria() {
    final nama = _namaKriteriaCtrl.text.trim();
    if (nama.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nama kriteria tidak boleh kosong')));
      return;
    }
    if (_kriteriaList.length >= _maxKriteria) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Maksimal 7 kriteria')));
      return;
    }
    setState(() {
      _kriteriaList.add(Kriteria(
        id: _uuid.v4(),
        nama: nama,
        jenis: _jenisSelected,
      ));
      _namaKriteriaCtrl.clear();
    });
  }

  void _hapusKriteria(int idx) {
    setState(() => _kriteriaList.removeAt(idx));
  }

  void _toggleJenis(int idx) {
    setState(() {
      final k = _kriteriaList[idx];
      _kriteriaList[idx] = k.copyWith(
        jenis: k.jenis == JenisKriteria.benefit
            ? JenisKriteria.cost
            : JenisKriteria.benefit,
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
                const SectionLabel('Nama Kelas :'),
                TextFormField(
                  controller: _namaKelasCtrl,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama kelas',
                    suffixIcon: Icon(Icons.edit_outlined,
                        color: AppColors.textHint, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama kelas wajib diisi' : null,
                ),
                const SizedBox(height: 24),

                // ── Input Tambah Kriteria ──
                SectionLabel(
                  'Masukkan Kriteria :',
                  subtitle:
                      '(Min. $_minKriteria kriteria, maks. $_maxKriteria kriteria)',
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _namaKriteriaCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Masukkan kriteria baru'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dropdown Jenis
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<JenisKriteria>(
                            value: _jenisSelected,
                            isExpanded: true,
                            style: Theme.of(context).textTheme.bodyLarge,
                            items: const [
                              DropdownMenuItem(
                                  value: JenisKriteria.benefit,
                                  child: Text('Benefit')),
                              DropdownMenuItem(
                                  value: JenisKriteria.cost,
                                  child: Text('Cost')),
                            ],
                            onChanged: (v) =>
                                setState(() => _jenisSelected = v!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol +
                    GestureDetector(
                      onTap: _tambahKriteria,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),

                // ── Kriteria Counter ──
                const SizedBox(height: 12),
                _KriteriaCounter(
                    current: _kriteriaList.length,
                    min: _minKriteria,
                    max: _maxKriteria),

                // ── Daftar Kriteria Tersimpan ──
                if (_kriteriaList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Kriteria yang tersimpan:',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...List.generate(
                    _kriteriaList.length,
                    (i) => KriteriaRow(
                      kriteria: _kriteriaList[i],
                      onDelete: () => _hapusKriteria(i),
                      onToggleJenis: () => _toggleJenis(i),
                      showEdit: false,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text('Belum ada kriteria ditambahkan',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                BottomSaveButton(
                  label: isEdit ? 'Simpan Perubahan' : 'Simpan Kriteria',
                  onPressed: _kriteriaList.length >= _minKriteria ? _simpan : null,
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

class _KriteriaCounter extends StatelessWidget {
  final int current, min, max;

  const _KriteriaCounter(
      {required this.current, required this.min, required this.max});

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
