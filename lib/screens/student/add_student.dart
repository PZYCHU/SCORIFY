import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

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
  final _nisCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  bool _saving = false;

  bool get isEdit => widget.existingMurid != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nisCtrl.text = widget.existingMurid!.nis ?? '';
      _namaCtrl.text = widget.existingMurid!.nama;
    }
  }

  @override
  void dispose() {
    _nisCtrl.dispose();
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<AppProvider>();
    final nis = _nisCtrl.text.trim().isEmpty ? null : _nisCtrl.text.trim();

    try {
      if (isEdit) {
        await provider.editMurid(
          widget.kelasId,
          widget.existingMurid!.id,
          nama: _namaCtrl.text.trim(),
          nis: nis,
        );
      } else {
        await provider.tambahMurid(
          widget.kelasId,
          nama: _namaCtrl.text.trim(),
          nis: nis,
          nilaiList: [],
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isEdit ? 'Edit Siswa' : 'Tambah Siswa';
    final initial = isEdit && widget.existingMurid!.nama.isNotEmpty
        ? widget.existingMurid!.nama[0].toUpperCase()
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F1), // Sage surface Scorify
      body: Column(
        children: [
          // ── Hero Header ──────────────────────────────────────────────
          _buildHeroHeader(context, title),

          // ── Form Area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Form Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student Avatar / Icon Preview
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.15),
                                    AppColors.accent.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: initial != null
                                  ? Text(
                                      initial,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_add_rounded,
                                      color: AppColors.primary,
                                      size: 30,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              isEdit ? 'Ubah Informasi Siswa' : 'Identitas Siswa Baru',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── NIS ───────────────────────────────────────
                          Row(
                            children: [
                              Text(
                                'NIS (Nomor Induk Siswa)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Opsional',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nisCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nomor induk (contoh: 21081)',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAF9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Nama ──────────────────────────────────────
                          Row(
                            children: [
                              Text(
                                'Nama Lengkap Siswa',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '*',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _namaCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama lengkap siswa',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.normal,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAF9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.6,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Nama siswa wajib diisi' : null,
                          ),
                          const SizedBox(height: 22),

                          // Info Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Nilai siswa dapat diinput nanti sewaktu KBM berlangsung, input kolektif, atau melalui sesi tugas di kelas.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF15803D),
                                      fontSize: 12,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _saving ? null : _simpan,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEdit ? Icons.check_circle_outline_rounded : Icons.person_add_alt_1_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEdit ? 'Simpan Perubahan' : 'Tambah Siswa',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D252B), Color(0xFF163842), Color(0xFF1B4B5A)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Ambient Glow
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.22),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
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
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kelas ${widget.kelas.nama}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
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
