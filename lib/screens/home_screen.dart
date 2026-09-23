import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'class/create_class.dart';
import 'class/class_detail.dart';
import '../services/auth_service.dart';
import '../screens/login_regist/login_screen.dart';
import 'profile/profile_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = AuthService().currentUser?.uid;
      final provider = context.read<AppProvider>();
      if (uid != null && provider.kelasList.isEmpty && !provider.loading) {
        provider.listenToUser(uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
    if (_isSearching) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Filter daftar kelas sesuai kata kunci pencarian
        final filteredKelas = provider.kelasList.where((k) {
          if (_searchQuery.trim().isEmpty) return true;
          return k.nama.toLowerCase().contains(
            _searchQuery.trim().toLowerCase(),
          );
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF3F5F1), // Soft modern sage surface
          body: Column(
            children: [
              _buildHeroHeader(context),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final uid = AuthService().currentUser?.uid;
                    context.read<AppProvider>().listenToUser(uid);
                  },
                  child: _buildBody(context, provider, filteredKelas),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BuatKelasScreen()),
              );
            },
            backgroundColor: AppColors.primary,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            label: Text(
              'Kelas Baru',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final user = AuthService().currentUser;

    final rawName = user?.displayName?.trim();
    String displayName = 'Guru';
    if (rawName != null && rawName.isNotEmpty) {
      final parts = rawName.split(RegExp(r'\s+'));
      displayName = parts.first;
      if (displayName.length > 12) {
        displayName = '${displayName.substring(0, 11)}…';
      }
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      final emailPrefix = user.email!.split('@').first;
      displayName = emailPrefix.length > 12
          ? '${emailPrefix.substring(0, 11)}…'
          : emailPrefix;
    }

    final photoUrl = user?.photoURL;
    final email = user?.email ?? '';

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
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                color: AppColors.primaryLight.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Baris Atas: Identitas Pengguna & Tombol Aksi ──
                  Row(
                    children: [
                      // Avatar Profil
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 21,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage:
                                photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'G',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Sapaan & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Halo, $displayName 👋',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16.5,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email.isNotEmpty
                                  ? email
                                  : 'Sistem Penilaian Siswa',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Kaca Pembesar (Search)
                      _buildHeaderIconButton(
                        icon: _isSearching
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                        tooltip: _isSearching
                            ? 'Tutup Pencarian'
                            : 'Cari Kelas',
                        isActive: _isSearching,
                        onTap: _toggleSearch,
                      ),
                      const SizedBox(width: 6),

                      // Tombol Panduan & Tutorial
                      _buildHeaderIconButton(
                        icon: Icons.help_outline_rounded,
                        tooltip: 'Panduan & Tutorial',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TutorialScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),

                      // Tombol Keluar Akun
                      _buildHeaderIconButton(
                        icon: Icons.logout_rounded,
                        tooltip: 'Keluar Akun',
                        iconColor: const Color(0xFFFCA5A5),
                        onTap: () async {
                          final confirm = await showConfirmDialog(
                            context,
                            title: 'Keluar Akun',
                            content:
                                'Yakin ingin keluar dari akun ini?\nAnda harus masuk kembali untuk mengelola kelas dan data penilaian.',
                          );
                          if (confirm && context.mounted) {
                            context.read<AppProvider>().listenToUser(null);
                            await AuthService().signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),

                  // ── Posisi Search Bar: Muncul di bawah sapaan menggantikan badge metrik ──
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _isSearching
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite, // Pure white surface
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors
                                .textPrimary, // Slate dark, 100% visible
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceWhite,
                            hintText: 'Cari nama kelas...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: AppColors.textHint,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.primaryLight,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchQuery.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: AppColors.textHint,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.danger,
                                    size: 18,
                                  ),
                                  tooltip: 'Tutup',
                                  onPressed: _stopSearch,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol icon frosted glass transparan untuk di header
  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    bool isActive = false,
  }) {
    return Material(
      color: isActive
          ? Colors.white.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.16),
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.accent : iconColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppProvider provider,
    List<Kelas> kelasList,
  ) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Jika database kosong sama sekali (belum ada kelas dibuat)
    if (provider.kelasList.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: _buildEmptyStateCard(context),
      );
    }

    // Jika sedang mencari namun tidak ada kelas yang cocok
    if (kelasList.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Kelas Tidak Ditemukan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tidak ada kelas dengan nama "$_searchQuery". Coba gunakan kata kunci lainnya.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset Pencarian'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      itemCount: kelasList.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          final isFilterActive = _searchQuery.trim().isNotEmpty;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text(
                  isFilterActive ? 'Hasil Pencarian' : 'Daftar Kelas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFilterActive
                        ? '${kelasList.length} Ditemukan'
                        : '${provider.kelasList.length} Kelas Tersimpan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final kelas = kelasList[i - 1];
        return _KelasCard(
          kelas: kelas,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailKelasScreen(kelasId: kelas.id),
            ),
          ),
        );
      },
    );
  }

  /// Empty state berbentuk Floating Card (Anti-gravity aesthetic & selaras Landing Page)
  Widget _buildEmptyStateCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Glowing icon container ──
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE6F4F7), Color(0xFFE8F5E9)],
              ),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Belum Ada Kelas Terdaftar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai buat kelas pertamamu untuk mengelola data murid, menetapkan kriteria evaluasi, dan menghitung pembobotan AHP-SAW secara otomatis.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // ── Feature Highlights (Pills) ──
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeaturePill(Icons.tune_rounded, 'Pembobotan AHP'),
              _buildFeaturePill(Icons.compare_arrows_rounded, 'Pairwise Card'),
              _buildFeaturePill(Icons.leaderboard_rounded, 'Perankingan SAW'),
            ],
          ),
          const SizedBox(height: 26),

          // ── CTA Button (+ Buat Kelas Sekarang) ──
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuatKelasScreen()),
                );
              },
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                'Buat Kelas Sekarang',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF1F5F9,
        ), // Pale grey soft surface selaras Pairwise
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryLight),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu Kelas yang telah diselaraskan penuh dengan gaya Pairwise Card (`ahp_screen.dart`):
/// - Radius 20px
/// - Soft shadow blurRadius 14 tanpa outline kasar
/// - Top status indicator chip
/// - Floating pill badges (Color(0xFFF1F5F9))
class _KelasCard extends StatelessWidget {
  final Kelas kelas;
  final VoidCallback onTap;

  const _KelasCard({required this.kelas, required this.onTap});

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20), // Selaras dengan Pairwise Card
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ), // Selaras Pairwise Card
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Kartu: Status Indikator (Selaras Pairwise Card) ──
                Row(
                  children: [
                    if (kelas.createdAt != null) ...[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 11.5,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Dibuat ${_formatDate(kelas.createdAt!)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                    ] else
                      Text(
                        'Kelas Aktif',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                    const Spacer(),

                    // Status Chip Terhitung / Belum Dihitung
                    if (kelas.sudahKalkulasi)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.benefitChip,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: AppColors.benefitChipText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Terhitung AHP',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.benefitChipText,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hourglass_empty_rounded,
                              size: 12,
                              color: AppColors.warningDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Belum Dihitung',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Info Utama: Icon, Nama Kelas, & Panah Indikator ──
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kelas.nama,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF1F5F9),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Floating Pills Row (Gaya identik _buildFloatingPill di Pairwise AhpScreen) ──
                Row(
                  children: [
                    _buildFloatingPill(
                      icon: Icons.people_alt_rounded,
                      label: '${kelas.jumlahSiswa} Siswa',
                    ),
                    const SizedBox(width: 8),
                    _buildFloatingPill(
                      icon: Icons.tune_rounded,
                      label: '${kelas.jumlahKriteria} Kriteria',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Floating pill badge (selaras dengan Pairwise Card di AhpScreen)
  Widget _buildFloatingPill({required IconData icon, required String label}) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF1F5F9,
        ), // Pale gray soft surface seragam Pairwise
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
