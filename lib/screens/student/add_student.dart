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
  bool _saving = false;

  bool get isEdit => widget.existingMurid != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _namaCtrl.text = widget.existingMurid!.nama;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<AppProvider>();
    try {
      if (isEdit) {
        await provider.editMurid(
          widget.kelasId,
          widget.existingMurid!.id,
          nama: _namaCtrl.text.trim(),
        );
      } else {
        await provider.tambahMurid(
          widget.kelasId,
          nama: _namaCtrl.text.trim(),
          nilaiList: [], // nilai diinput saat KBM, bukan di sini
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
        title: Text(isEdit ? 'Edit Murid' : 'Tambah Murid'),
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
                const SectionLabel('Nama Murid :'),
                TextFormField(
                  controller: _namaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama murid',
                    suffixIcon: Icon(
                      Icons.edit_outlined,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 24),

                // Info: nilai diinput saat KBM
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nilai akan diinput saat KBM berlangsung atau setelah koreksi tugas.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                BottomSaveButton(
                  label: isEdit ? 'Simpan Perubahan' : 'Tambah Murid',
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
