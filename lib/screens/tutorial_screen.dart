import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Panduan & Tutorial Scorify',
          style: TextStyle(
            fontWeight: FontWeight.w700,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Selamat Datang
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buku Panduan Guru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pelajari alur penilaian KBM, pembobotan AHP vertikal, hingga perangkingan SAW otomatis.',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Alur Kerja Utama
            _buildSection(
              title: '1. Alur Kerja Aplikasi (Workflow)',
              icon: Icons.alt_route_rounded,
              color: const Color(0xFF2563EB),
              children: [
                _buildStepItem(
                  step: '1',
                  title: 'Buat Kelas & Kriteria',
                  desc: 'Buat kelas baru dan tentukan 3–7 kriteria penilaian. Anda bisa klik "Muat Default" untuk langsung mengisi 4 kriteria baku sekolah.',
                ),
                _buildStepItem(
                  step: '2',
                  title: 'Isi Bobot AHP',
                  desc: 'Bandingkan kriteria secara berpasangan dari atas ke bawah menggunakan kalimat verbal Saaty. Pastikan Rasio Konsistensi (CR) < 0.10.',
                ),
                _buildStepItem(
                  step: '3',
                  title: 'Input Nilai Siswa',
                  desc: 'Catat nilai harian (presensi & keaktifan) atau buat sesi tugas/ujian. Gunakan fitur "Input Kolektif" untuk memberi nilai ke banyak siswa sekaligus.',
                ),
                _buildStepItem(
                  step: '4',
                  title: 'Lihat Hasil Ranking SAW',
                  desc: 'Tekan "Lihat Hasil" untuk melihat skor gabungan SAW beserta rincian matriks normalisasi, peringkat 1–3, dan ekspor file Excel.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Kriteria & Karakteristiknya
            _buildSection(
              title: '2. Memahami Jenis Kriteria',
              icon: Icons.tune_rounded,
              color: const Color(0xFF0D9488),
              children: [
                _buildInfoCard(
                  badge: 'Performa Harian',
                  badgeColor: Colors.teal,
                  title: 'Presensi & Keaktifan',
                  desc: 'Penilaian rutin tatap muka di kelas. Dapat berupa "Nilai Angka" (0–100 seperti kehadiran) atau "Poin Tambahan" (counter akumulasi poin keaktifan seperti +1, +5).',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  badge: 'Hasil (Sesi)',
                  badgeColor: Colors.indigo,
                  title: 'Tugas, Kuis, & Ulangan',
                  desc: 'Kriteria berbasis penugasan dinamis. Anda bisa membuat banyak sesi (Tugas 1, Tugas 2, UTS). Jika siswa mengulang tugas, sistem otomatis mencatat attempt remedial.',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  badge: 'Perhitungan Remedi',
                  badgeColor: Colors.orange,
                  title: 'Frekuensi Remedial (Cost)',
                  desc: 'Dihitung secara otomatis oleh sistem tanpa perlu input manual. Semakin sering siswa mengulang tugas (cost), semakin rendah skor prioritasnya.',
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  badge: 'Benefit vs Cost',
                  badgeColor: Colors.deepPurple,
                  title: 'Arah Penilaian Kriteria',
                  desc: '• Benefit: Semakin tinggi nilai, semakin bagus (cth: Kehadiran, Nilai Tugas).\n• Cost: Semakin rendah nilai, semakin bagus (cth: Frekuensi Remedial).',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Pembobotan AHP Model Vertikal
            _buildSection(
              title: '3. Pembobotan AHP Vertikal (Saaty)',
              icon: Icons.balance_rounded,
              color: const Color(0xFFD97706),
              children: [
                const Text(
                  'Format Pairwise Comparison Scorify telah dirombak menjadi kartu perbandingan vertikal ke bawah (bukan matriks lebar), sehingga tidak terpotong di layar ponsel.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Skala Verbal Saaty (1 – 9):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• 1 = Sama Penting (Kedua kriteria setara)\n'
                        '• 3 = Sedikit Lebih Penting\n'
                        '• 5 = Lebih Penting / Kuat\n'
                        '• 7 = Sangat Lebih Penting\n'
                        '• 9 = Mutlak Lebih Penting (Paling dominan)\n'
                        '• Nilai 2, 4, 6, 8 = Nilai antara di antaranya',
                        style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Catatan Konsistensi: Nilai Rasio Konsistensi (CR) harus ≤ 0.10. Jika CR > 0.10, aplikasi akan memunculkan peringatan kontras tinggi agar guru menyesuaikan kembali pertimbangan kepentingannya.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Fitur Input Kolektif & Deteksi Presensi
            _buildSection(
              title: '4. Input Kolektif & Pengaman Presensi',
              icon: Icons.checklist_rounded,
              color: const Color(0xFF10B981),
              children: [
                _buildFeatureBullet(
                  icon: Icons.check_box_outlined,
                  title: 'Checklist Siswa & Search Bar',
                  desc: 'Dalam menu "Input Kolektif", guru dapat menggunakan Search Bar untuk mencari siswa, memilih seluruh siswa ("Pilih Semua"), atau menghapus centang pada siswa tertentu saja.',
                ),
                const SizedBox(height: 10),
                _buildFeatureBullet(
                  icon: Icons.history_rounded,
                  title: 'Deteksi Presensi Dobel dengan Jam',
                  desc: 'Jika presensi siswa sudah pernah dicatat hari ini, dialog konfirmasi otomatis muncul lengkap dengan waktu pencatatan sebelumnya (mis. 07:45 WIB) untuk mencegah salah timpa.',
                ),
                const SizedBox(height: 10),
                _buildFeatureBullet(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Input Kolektif untuk Tugas',
                  desc: 'Fitur "Input Kolektif" juga mendukung penilaian sesi tugas/ulangan, memudahkan guru memberi nilai default untuk satu kelas dalam 1 klik.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Panduan Import & Export Excel
            _buildSection(
              title: '5. Import & Unduh File Excel',
              icon: Icons.file_download_outlined,
              color: const Color(0xFF6366F1),
              children: [
                _buildFeatureBullet(
                  icon: Icons.download_for_offline_outlined,
                  title: 'Template Excel Resmi (.xlsx)',
                  desc: 'Unduh template resmi siswa dari tombol aksi mandiri di layar Import Siswa. Kolom A adalah NIS dan Kolom B adalah Nama Siswa.',
                ),
                const SizedBox(height: 10),
                _buildFeatureBullet(
                  icon: Icons.share_rounded,
                  title: 'Ekspor Hasil & Bagikan Langsung',
                  desc: 'File rekap penilaian dan ranking SAW dapat diunduh dalam sekejap dan langsung dibagikan ke aplikasi WhatsApp, Telegram, Google Drive, atau email via lembar aksi sistem.',
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStepItem({required String step, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String badge,
    required Color badgeColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
