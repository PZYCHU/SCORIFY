import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class TambahMuridScreen extends StatefulWidget {
  final String kelasId;
  final Kelas kelas;
  final Murid? existingMurid;

  const TambahMuridScreen({
    super.key,
    required this.kelasId,
    required this.kelas,
    this.existingMurid,
  });

  @override
  State<TambahMuridScreen> createState() => _TambahMuridScreenState();
}

class _TambahMuridScreenState extends State<TambahMuridScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  late Map<String, TextEditingController> _nilaiCtrl;
  bool _saving = false;

  bool get isEdit => widget.existingMurid != null;

  @override
  void initState() {
    super.initState();
    _nilaiCtrl = {
      for (final k in widget.kelas.kriteria) k.id: TextEditingController()
    };

    if (isEdit) {
      _namaCtrl.text = widget.existingMurid!.nama;
      for (final k in widget.kelas.kriteria) {
        final v = widget.existingMurid!.getNilai(k.id);
        if (v > 0) _nilaiCtrl[k.id]!.text = v.toString();
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    for (final c in _nilaiCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final nilaiList = widget.kelas.kriteria.map((k) {
      return NilaiKriteria(
        kriteriaId: k.id,
        nilai: double.tryParse(_nilaiCtrl[k.id]!.text) ?? 0,
      );
    }).toList();

    final provider = context.read<AppProvider>();
    try {
      if (isEdit) {
        await provider.editMurid(
          widget.kelasId,
          widget.existingMurid!.id,
          nama: _namaCtrl.text.trim(),
          nilaiList: nilaiList,
        );
      } else {
        await provider.tambahMurid(
          widget.kelasId,
          nama: _namaCtrl.text.trim(),
          nilaiList: nilaiList,
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
        title: Text(isEdit ? 'Edit Murid' : 'Tambah Murid Baru'),
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
                // ── Nama ──
                const SectionLabel('Nama Anggota :'),
                TextFormField(
                  controller: _namaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama anggota',
                    suffixIcon: Icon(Icons.edit_outlined,
                        color: AppColors.textHint, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),

                const SizedBox(height: 24),

                // ── Nilai per Kriteria ──
                SectionLabel(
                  'Pilih Kriteria Tersedia :',
                  subtitle:
                      '(Min. 3 kriteria, maks. 7 kriteria)',
                ),

                ...widget.kelas.kriteria.map((k) => NilaiInputRow(
                      kriteria: k,
                      controller: _nilaiCtrl[k.id]!,
                    )),

                const SizedBox(height: 8),
                BottomSaveButton(
                  label: 'Simpan Data',
                  onPressed: _simpan,
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
