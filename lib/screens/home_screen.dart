import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _buildHeader(context),
              const SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final uid = AuthService().currentUser?.uid;
                    context.read<AppProvider>().listenToUser(uid);
                  },
                  child: _buildBody(context),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BuatKelasScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Kelas Baru',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  

  Widget _buildHeader(BuildContext context) {
    final user = AuthService().currentUser;
    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'Guru');
    final photoUrl = user?.photoURL;
    final email = user?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar Profil (bisa di-tap untuk ke profil)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                setState(() {});
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                backgroundImage:
                    photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $displayName 👋',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.isNotEmpty ? email : 'Sistem Penilaian Kinerja Siswa',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Panduan & Tutorial',
              icon: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TutorialScreen()),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) async {
                if (val == 'tutorial') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TutorialScreen()),
                  );
                } else if (val == 'profile') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  setState(() {});
                } else if (val == 'logout') {
                  final confirm = await showConfirmDialog(
                    context,
                    title: 'Keluar Akun',
                    content: 'Apakah Anda yakin ingin keluar dari akun ini?',
                  );
                  if (confirm && context.mounted) {
                    context.read<AppProvider>().listenToUser(null);
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tutorial',
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Panduan & Tutorial',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Profil Saya',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.danger, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Keluar',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.kelasList.isEmpty) {
          return const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 450,
              child: EmptyState(
                icon: '📚',
                title: 'Belum ada kelas',
                subtitle: 'Tap tombol "Kelas Baru" untuk\nmembuat kelas pertamamu',
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daftar Kelas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text('${provider.kelasList.length} kelas tersimpan',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: provider.kelasList.length,
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailKelasScreen(
                        kelasId: provider.kelasList[i].id,
                      ),
                    ),
                  ),
                  child: _KelasCard(kelas: provider.kelasList[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KelasCard extends StatelessWidget {
  final Kelas kelas;

  const _KelasCard({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_outlined,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kelas.nama,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoPill(
                          icon: Icons.people_outline,
                          label: '${kelas.jumlahSiswa} Siswa'),
                      const SizedBox(width: 8),
                      _InfoPill(
                          icon: Icons.tune,
                          label: '${kelas.jumlahKriteria} Kriteria'),
                      if (kelas.sudahKalkulasi) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.benefitChip,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('✓ Terhitung',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.benefitChipText,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
      ],
    );
  }
}
