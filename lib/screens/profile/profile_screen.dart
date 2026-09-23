import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  // Controllers Edit Nama
  late TextEditingController _nameController;
  bool _isSavingName = false;

  // Controllers Ganti Email
  final _emailFormKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  bool _isSavingEmail = false;
  bool _obscureEmailPassword = true;

  // Controllers Ganti Password
  final _pwdFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSavingPassword = false;
  bool _obscureCurrentPwd = true;
  bool _obscureNewPwd = true;
  bool _obscureConfirmPwd = true;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    // Reload user di background agar jika user sudah klik link verifikasi email, emailnya langsung ter-update
    _reloadUser();
  }

  Future<void> _reloadUser() async {
    try {
      await _authService.currentUser?.reload();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newEmailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isGoogleUser {
    final user = _authService.currentUser;
    return user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      AppFeedback.showError(context, message);
    } else {
      AppFeedback.showSuccess(context, message);
    }
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar('Nama tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _authService.updateDisplayName(newName);
      _showSnackBar('Nama berhasil diperbarui!');
      setState(() {});
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _updateEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final newEmail = _newEmailController.text.trim();
    final currentPassword = _emailPasswordController.text;

    final confirm = await showConfirmDialog(
      context,
      title: 'Ubah Email',
      content:
          'Tautan verifikasi akan dikirim ke email baru ($newEmail). Anda harus memverifikasinya untuk menyelesaikan pembaruan email.',
      confirmLabel: 'Kirim Verifikasi',
    );

    if (!confirm || !mounted) return;

    setState(() => _isSavingEmail = true);
    try {
      await _authService.updateEmail(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );
      _newEmailController.clear();
      _emailPasswordController.clear();
      _showSnackBar('Tautan verifikasi telah dikirim ke email baru. Silakan cek inbox Anda!');
      setState(() {});
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingEmail = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_pwdFormKey.currentState!.validate()) return;

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    setState(() => _isSavingPassword = true);
    try {
      await _authService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSnackBar('Kata sandi berhasil diubah!');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final user = _authService.currentUser;
    final userEmail = user?.email;
    if (userEmail == null || userEmail.isEmpty) return;

    setState(() => _isSavingPassword = true);
    try {
      await _authService.sendPasswordReset(userEmail);
      _showSnackBar('Tautan reset kata sandi telah dikirim ke $userEmail');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Guru');
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;
    final isGoogle = _isGoogleUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F1),
      appBar: AppBar(
        title: Text(
          'Profil Guru',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // ── Avatar & Info Ringkas ──
            _buildProfileHeader(displayName, email, photoUrl, isGoogle),
            const SizedBox(height: 24),

            // ── Bagian 1: Ubah Nama ──
            _buildSectionCard(
              title: 'Nama Guru',
              subtitle: 'Nama ini ditampilkan di dasbor penilaian',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Nama Lengkap Guru',
                      prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSavingName ? null : _updateName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: _isSavingName
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Simpan Nama',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Bagian 2: Ubah Email ──
            if (!isGoogle) ...[
              _buildSectionCard(
                title: 'Ganti Email Akun',
                subtitle: 'Email baru memerlukan verifikasi sebelum aktif',
                icon: Icons.email_outlined,
                child: Form(
                  key: _emailFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _newEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email Baru',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primary, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email baru wajib diisi';
                          if (!v.contains('@')) return 'Format email tidak valid';
                          if (v.trim().toLowerCase() == email.toLowerCase()) {
                            return 'Email baru tidak boleh sama dengan email lama';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailPasswordController,
                        obscureText: _obscureEmailPassword,
                        decoration: InputDecoration(
                          hintText: 'Konfirmasi Sandi Saat Ini',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureEmailPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureEmailPassword = !_obscureEmailPassword),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Kata sandi saat ini diperlukan';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isSavingEmail ? null : _updateEmail,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: _isSavingEmail
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, color: AppColors.primary, size: 18),
                          label: const Text(
                            'Kirim Verifikasi Email Baru',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Bagian 3: Ganti Password ──
              _buildSectionCard(
                title: 'Ganti Kata Sandi',
                subtitle: 'Pastikan kata sandi baru minimal 6 karakter',
                icon: Icons.security_rounded,
                child: Form(
                  key: _pwdFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPwd,
                        decoration: InputDecoration(
                          hintText: 'Kata Sandi Saat Ini',
                          prefixIcon: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureCurrentPwd = !_obscureCurrentPwd),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Kata sandi saat ini wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPwd,
                        decoration: InputDecoration(
                          hintText: 'Kata Sandi Baru (min. 6 karakter)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureNewPwd = !_obscureNewPwd),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Kata sandi baru wajib diisi';
                          if (v.length < 6) return 'Kata sandi minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPwd,
                        decoration: InputDecoration(
                          hintText: 'Ulangi Kata Sandi Baru',
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPwd = !_obscureConfirmPwd),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                          if (v != _newPasswordController.text) return 'Kata sandi baru tidak cocok';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSavingPassword ? null : _updatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: _isSavingPassword
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'Ubah Kata Sandi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Card Informasi Keamanan & Opsi Reset Password untuk Pengguna Google (Point 6)
              _buildSectionCard(
                title: 'Email, Sandi & Keamanan',
                subtitle: 'Informasi kredensial login Google OAuth',
                icon: Icons.security_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kotak Penjelasan Resmi Google Auth
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Terkoneksi Akun Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Akun Anda terotentikasi secara aman melalui Google Sign-In ($email). '
                                  'Oleh karena itu, pengelolaan alamat email utama dan kata sandi dilindungi langsung oleh Google sehingga tidak dapat diubah dari dalam aplikasi Scorify.',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.45,
                                    color: Color(0xFF14532D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '💡 Untuk mengganti email atau sandi akun Google Anda, silakan buka menu keamanan di myaccount.google.com.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ingin bisa login dengan kata sandi manual juga? Anda dapat menyetel kata sandi lokal untuk akun ini via email pemulihan:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isSavingPassword ? null : _sendPasswordResetEmail,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: _isSavingPassword
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                              )
                            : const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 20),
                        label: const Text(
                          'Kirim Tautan Setel Kata Sandi Baru',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    String displayName,
    String email,
    String? photoUrl,
    bool isGoogle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D252B), // Deep teal dark
            Color(0xFF163842),
            Color(0xFF1B4B5A), // AppColors.primary
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryLight,
              backgroundImage:
                  photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, size: 14, color: AppColors.accent),
                    SizedBox(width: 5),
                    Text(
                      'Guru',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGoogle ? Icons.g_mobiledata_rounded : Icons.email_rounded,
                      size: isGoogle ? 18 : 13,
                      color: isGoogle ? const Color(0xFF93C5FD) : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGoogle ? 'Google' : 'Email/Password',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.02),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
