class AssistantMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestions;

  AssistantMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.suggestions,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AssistantService {
  /// Topik cepat awal yang disarankan untuk guru
  static const List<String> initialSuggestions = [
    '🔢 Cara Hitung AHP Saaty',
    '🏆 Perangkingan SAW',
    '🔄 Aturan Remedial Otomatis',
    '⏱️ Presensi & Kehadiran',
    '📊 Format Template Excel',
    '🔑 Login Google & Kata Sandi',
    '📝 Cara Input Nilai Siswa',
    '⚖️ Kriteria Benefit vs Cost',
  ];

  /// Basis data pengetahuan offline Scorify (Knowledge Base)
  static final List<_KnowledgeItem> _knowledgeBase = [
    // ─── 1. AHP (Analytic Hierarchy Process) ─────────────────────────────────
    _KnowledgeItem(
      keywords: [
        'ahp', 'saaty', 'bobot', 'pembobotan', 'perbandingan', 'matriks',
        'konsistensi', 'cr', 'ci', 'ri', 'vertikal'
      ],
      response:
          '📌 Mekanisme Pembobotan AHP Saaty di Scorify:\n\n'
          '1. Perbandingan Berpasangan: Guru membandingkan kepentingan antar kriteria menggunakan skala 1–9 Saaty (1 = Sama penting, 3 = Sedikit lebih penting, 5 = Lebih penting, hingga 9 = Mutlak lebih penting).\n'
          '2. Model Vertikal: Scorify menyederhanakan input matriks menjadi kartu perbandingan vertikal agar mudah diisi di layar HP tanpa tabel lebar.\n'
          '3. Uji Konsistensi (CR): Sistem otomatis menghitung Consistency Ratio (CR):\n'
          '   • CR < 0.1 (≤ 10%): Pembobotan dianggap KONSISTEN dan valid digunakan.\n'
          '   • CR ≥ 0.1: Tidak konsisten secara logika penilaian, sistem akan meminta guru meninjau ulang perbandingan.\n'
          '4. Kapan Dilakukan? Pembobotan dapat dilakukan kapan saja (di awal atau di akhir semester) karena nilai bobot bersifat independen.',
      suggestions: ['🏆 Perangkingan SAW', '⚖️ Kriteria Benefit vs Cost'],
    ),

    // ─── 2. SAW (Simple Additive Weighting) ──────────────────────────────────
    _KnowledgeItem(
      keywords: [
        'saw', 'perangkingan', 'ranking', 'skor akhir', 'kalkulasi', 'hitung ranking',
        'normalisasi', 'bobot akhir', 'peringkat'
      ],
      response:
          '🏆 Mekanisme Perangkingan SAW (Simple Additive Weighting):\n\n'
          'Metode SAW mencari penjumlahan terbobot dari kinerja setiap siswa pada seluruh kriteria:\n\n'
          '1. Normalisasi Nilai (Matriks R):\n'
          '   • Kriteria Benefit: Nilai siswa dibagi nilai maksimum kelas (x / x_max).\n'
          '   • Kriteria Cost: Nilai minimum kelas dibagi nilai siswa (x_min / x).\n'
          '2. Perkalian Bobot AHP: Nilai ternormalisasi dikalikan dengan bobot kriteria (W) hasil AHP Saaty.\n'
          '3. Penjumlahan Skor Akhir (V): Seluruh perkalian bobot dijumlahkan menghasilkan Skor Akhir (0.00 – 1.00).\n'
          '4. Perankingan: Siswa diurutkan secara otomatis dari skor tertinggi (Ranking 1) ke terendah.',
      suggestions: ['🔢 Cara Hitung AHP Saaty', '🔄 Aturan Remedial Otomatis'],
    ),

    // ─── 3. Benefit vs Cost ──────────────────────────────────────────────────
    _KnowledgeItem(
      keywords: [
        'benefit', 'cost', 'sifat kriteria', 'jenis kriteria', 'biaya', 'keuntungan'
      ],
      response:
          '⚖️ Perbedaan Kriteria Benefit vs Cost di Scorify:\n\n'
          '• BENEFIT (Keuntungan):\n'
          '  Semakin tinggi nilai siswa, semakin menguntungkan dan menaikkan ranking siswa.\n'
          '  Contoh: Nilai Ujian, Kehadiran, Sikap, Tugas Harian.\n\n'
          '• COST (Biaya/Beban):\n'
          '  Semakin tinggi nilai siswa, justru semakin mengurangi perolehan skor akhir dan menurunkan ranking.\n'
          '  Contoh: Frekuensi Remedial (semakin sering remedial, skor SAW semakin berkurang).\n\n'
          '💡 Pada metode SAW, kriteria Cost dinormalisasi secara terbalik (x_min / x).',
      suggestions: ['🔄 Aturan Remedial Otomatis', '⏱️ Presensi & Kehadiran'],
    ),

    // ─── 4. Kriteria Remedial Otomatis ────────────────────────────────────────
    _KnowledgeItem(
      keywords: [
        'remedial', 'remidi', 'ngulang', 'attempt', 'derived', 'frekuensi remedial',
        'tuntas', 'perbaikan'
      ],
      response:
          '🔄 Aturan Kriteria Frekuensi Remedial di Scorify:\n\n'
          '1. Otomatis Dihitung: Guru tidak perlu menginput angka remedial secara manual.\n'
          '2. Pencatatan Attempt: Setiap kali guru menambahkan nilai perbaikan (Attempt 2, 3, dst.) pada sesi tugas manapun, Scorify otomatis mencatat 1 frekuensi remedial untuk siswa tersebut.\n'
          '3. Nilai yang Diambil: Nilai akhir siswa pada sesi tersebut adalah nilai tertinggi/terbaru yang diperolehnya, namun frekuensi remedialnya tetap tercatat.\n'
          '4. Sifat Cost: Kriteria remedial otomatis diperlakukan sebagai kriteria Cost, sehingga frekuensi remedial yang tinggi secara adil mempengaruhi skor SAW siswa.',
      suggestions: ['🏆 Perangkingan SAW', '📝 Cara Input Nilai Siswa'],
    ),

    // ─── 5. Presensi / Kehadiran ─────────────────────────────────────────────
    _KnowledgeItem(
      keywords: [
        'presensi', 'absen', 'kehadiran', 'jam presensi', 'waktu presensi',
        'proteksi presensi', 'attendance', 'format hadir'
      ],
      response:
          '⏱️ Fitur & Mekanisme Kriteria Kehadiran (Presensi):\n\n'
          '1. Format Fleksibel: Scorify tidak membatasi format presensi secara kaku. Anda bebas memilih:\n'
          '   • Format Persentase (0–100%)\n'
          '   • Format Akumulasi Hari (misal 18 kali pertemuan)\n'
          '   • Format Poin Guru (Hadir = 100, Izin = 75, Sakit = 50)\n'
          '   Paling penting: Gunakan format yang sama untuk seluruh siswa di kelas.\n'
          '2. Proteksi Jam & Tanggal KBM:\n'
          '   Presensi hanya dapat diisi pada hari ini dan sesuai jadwal jam KBM kelas untuk mencegah manipulasi absensi siswa di luar jam belajar.',
      suggestions: ['⚖️ Kriteria Benefit vs Cost', '📝 Cara Input Nilai Siswa'],
    ),

    // ─── 6. Template & File Excel ────────────────────────────────────────────
    _KnowledgeItem(
      keywords: [
        'excel', 'import', 'template', 'unduh template', 'download template',
        'ekspor', 'export', 'xlsx', 'laporan excel', 'folder unduhan', 'file'
      ],
      response:
          '📊 Panduan Pengelolaan File Excel di Scorify:\n\n'
          '• Format Template Import Siswa:\n'
          '  File Excel hanya membutuhkan 2 kolom:\n'
          '  • Kolom A: NIS (Nomor Induk Siswa)\n'
          '  • Kolom B: Nama Lengkap Siswa\n'
          '  (Baris 1 adalah Header, baris 2 dst adalah data siswa)\n\n'
          '• Unduh Template:\n'
          '  Gunakan tombol "Unduh Template" di halaman Import Siswa. File akan tersimpan ke folder Download/Dokumen perangkat.\n\n'
          '• Ekspor Rekap Laporan Nilai:\n'
          '  Di halaman Detail Kelas, tekan tombol "Ekspor Excel". File yang diunduh mencakup:\n'
          '  - Sheet 1: Rekap nilai seluruh kriteria, skor SAW, & ranking.\n'
          '  - Sheet 2: Riwayat attempt remedial detail per siswa.\n'
          '  - Sheet 3: Catatan kriteria kelas.',
      suggestions: ['📝 Cara Input Nilai Siswa', '🔑 Login Google & Kata Sandi'],
    ),

    // ─── 7. Akun, Google Login, & Sandi ──────────────────────────────────────
    _KnowledgeItem(
      keywords: [
        'google', 'login google', 'ganti email', 'ubah email', 'sandi', 'password',
        'buat sandi', 'forgot password', 'lupa kata sandi', 'spam', 'akun'
      ],
      response:
          '🔑 Pengelolaan Akun & Kata Sandi di Scorify:\n\n'
          '1. Login dengan Google:\n'
          '   Akun yang dibuat lewat tombol "Login with Google" pada awalnya belum memiliki kata sandi di aplikasi Scorify.\n\n'
          '2. Cara Membuat Kata Sandi (Account Linking):\n'
          '   • Masuk menggunakan tombol "Login with Google".\n'
          '   • Buka menu Profil di pojok atas.\n'
          '   • Pada bagian "Buat Kata Sandi Akun", masukkan kata sandi baru Anda.\n'
          '   • Selesai! Akun kini bisa login instan lewat tombol Google ataupun diketik manual.\n\n'
          '3. Mengapa Email Reset Masuk ke Spam?\n'
          '   Email reset otomatis dari Firebase (firebaseapp.com) sering diklasifikasikan sebagai Spam oleh filter Gmail. Silakan periksa folder Spam Gmail Anda.\n\n'
          '4. Ganti Email:\n'
          '   Setelah akun memiliki kata sandi, email dapat diganti di menu Profil tanpa menghilangkan data kelas Anda (karena data terikat pada ID Pengguna).',
      suggestions: ['📊 Format Template Excel', '🔢 Cara Hitung AHP Saaty'],
    ),

    // ─── 8. Input Nilai Siswa ────────────────────────────────────────────────
    _KnowledgeItem(
      keywords: [
        'input nilai', 'isi nilai', 'kolektif', 'input kolektif', 'tambah nilai',
        'sesi', 'tugas', 'koreksi nilai', 'edit nilai'
      ],
      response:
          '📝 Cara Mengisi & Mengoreksi Nilai Siswa:\n\n'
          '1. Input Individual:\n'
          '   Ketuk nama siswa pada kartu kelas, pilih kriteria yang ingin dinilai, lalu simpan.\n'
          '2. Input Kolektif (Massal):\n'
          '   Gunakan tombol "Input Kolektif" di halaman Detail Kelas untuk mengisi nilai seluruh siswa dalam satu tampilan sekaligus (sangat menghemat waktu).\n'
          '3. Sesi Tugas Banyak:\n'
          '   Untuk kriteria jenis Hasil (UTS, UAS, Tugas 1, Tugas 2), Anda dapat membuat banyak sesi. Scorify otomatis menghitung rata-rata seluruh sesi tersebut.\n'
          '4. Koreksi Nilai:\n'
          '   Nilai dapat diubah kapan saja. Cukup ketuk kembali tombol "Hitung Perangkingan" untuk memperbarui hasil kalkulasi seketika.',
      suggestions: ['🔄 Aturan Remedial Otomatis', '⏱️ Presensi & Kehadiran'],
    ),
  ];

  /// Menjawab pertanyaan pengguna secara cerdas dan offline
  static AssistantMessage answerQuery(String query) {
    final cleanQuery = query.toLowerCase().trim();

    if (cleanQuery.isEmpty) {
      return AssistantMessage(
        text: 'Silakan ketik pertanyaan seputar aplikasi Scorify, atau pilih topik cepat di bawah ya!',
        isUser: false,
        suggestions: initialSuggestions.take(4).toList(),
      );
    }

    // Sambutan / Greetings
    if (RegExp(r'^(halo|hai|hi|hello|selamat|assalamu|pagi|siang|sore|malam)').hasMatch(cleanQuery)) {
      return AssistantMessage(
        text:
            'Halo Bapak/Ibu Guru! 👋 Ada yang bisa saya bantu terkait mekanisme pembobotan AHP, perangkingan SAW, input nilai, presensi, atau template Excel di Scorify?',
        isUser: false,
        suggestions: initialSuggestions.take(4).toList(),
      );
    }

    // Skor kecocokan untuk setiap item di knowledge base
    _KnowledgeItem? bestMatch;
    int highestScore = 0;

    for (final item in _knowledgeBase) {
      int score = 0;
      for (final kw in item.keywords) {
        if (cleanQuery.contains(kw)) {
          score += (kw.length > 4 ? 3 : 2);
        }
      }
      if (score > highestScore) {
        highestScore = score;
        bestMatch = item;
      }
    }

    // Jika ada kecocokan topik Scorify
    if (bestMatch != null && highestScore >= 2) {
      return AssistantMessage(
        text: bestMatch.response,
        isUser: false,
        suggestions: bestMatch.suggestions,
      );
    }

    // Guardrail: Jika di luar konteks sistem Scorify
    return AssistantMessage(
      text:
          'Maaf Bapak/Ibu Guru, saya dirancang khusus untuk memandu sistem dan mekanisme aplikasi Scorify saja.\n\n'
          'Saya dapat membantu menjelaskan:\n'
          '• Pembobotan AHP Saaty & Uji Konsistensi (CR)\n'
          '• Perangkingan SAW & Matriks Normalisasi\n'
          '• Kriteria Benefit vs Cost & Remedial Otomatis\n'
          '• Input Presensi & Jadwal KBM\n'
          '• Template & Rekap Laporan Excel\n'
          '• Pengelolaan Akun & Kata Sandi\n\n'
          'Silakan tanyakan topik di atas ya! 😊',
      isUser: false,
      suggestions: initialSuggestions.take(4).toList(),
    );
  }
}

class _KnowledgeItem {
  final List<String> keywords;
  final String response;
  final List<String> suggestions;

  _KnowledgeItem({
    required this.keywords,
    required this.response,
    required this.suggestions,
  });
}
