<div align="center">

# 📊 SCORIFY
### Sistem Pendukung Keputusan (SPK) Penilaian & Perangkingan Siswa berbasis AHP & SAW

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android-green?style=for-the-badge&logo=android)](https://www.android.com)

<p align="center">
  Aplikasi mobile modern untuk membantu guru dan pendidik dalam mengevaluasi, membobot kriteria penilaian, dan meranking prestasi belajar siswa secara objektif, akuntabel, dan transparan.
</p>

</div>

---

## 🌟 Fitur Utama

### 1. 🎯 Fleksibilitas Kategori Kriteria Penilaian
Mendukung 3 jenis kriteria penilaian terpadu:
* 🟢 **Kriteria Performa:** Dinilai langsung saat KBM (*on-the-spot*), mencakup **Poin Tambahan (+)** untuk keaktifan/sikap atau **Nilai Angka (0–100)** untuk unjuk kerja/praktik/presentasi.
* 🔵 **Kriteria Hasil:** Dinilai setelah evaluasi terstruktur per sesi (Tugas, Kuis, UTS, UAS) dengan dukungan pencatatan remedial/retake.
* 🟠 **Kriteria Perhitungan Remedi (*Derived Cost Criteria*):** Dihitung otomatis oleh sistem dari frekuensi pengulangan ujian (*attempt > 1*) pada kriteria tugas/ujian yang dipilih oleh guru.

### 2. ⚖️ Pembobotan Kriteria dengan AHP (*Analytical Hierarchy Process*)
* **Matriks Perbandingan Berpasangan:** Menggunakan skala preferensi Saaty 1–9.
* **Uji Konsistensi Otomatis:** Menghitung nilai $\lambda_{\max}$, *Consistency Index* (CI), dan *Consistency Ratio* (CR).
* **Smart Inconsistency Advisor:** Memberikan rekomendasi revisi nilai sel perbandingan secara otomatis jika matriks inkonsisten ($CR \ge 0.1$).

### 3. 🏆 Perangkingan Alternatif dengan SAW (*Simple Additive Weighting*)
* Normalisasi matriks keputusan terintegrasi untuk kriteria **Benefit** ($\uparrow$) dan **Cost** ($\downarrow$).
* Agregasi bobot AHP dengan nilai ternormalisasi untuk menghasilkan skor akhir presisi dan pemeringkatan siswa.

### 4. 📊 Manajemen Data & Ekspor Excel Multi-Sheet
* **Import Data Siswa:** Unggah daftar siswa secara instan dari file Excel (`.xlsx` / `.csv`) lengkap dengan template siap pakai.
* **Laporan Excel Komprehensif (2 Sheet):**
  * 📄 **Sheet 1 (*Rekap & Ranking*):** NIS, Nama Siswa, seluruh kolom nilai kriteria dinamis, Skor SAW, dan Ranking.
  * 📄 **Sheet 2 (*Riwayat Remedial*):** Log audit jejak perbaikan nilai siswa per sesi (Attempt 1 vs Attempt 2, tanggal, dan status kelulusan).

### 5. 🔐 Keamanan & Sinkronisasi Cloud
* Autentikasi aman berbasis **Firebase Authentication** (Email & Password serta Google Sign-In).
* Sinkronisasi data real-time menggunakan **Cloud Firestore**.

---

## 📐 Metodologi SPK

### 1. Analytical Hierarchy Process (AHP)
1. **Normalisasi Matriks:**
   $$r_{ij} = \frac{a_{ij}}{\sum_{k=1}^{n} a_{kj}}$$
2. **Perhitungan Vektor Bobot ($w_i$):**
   $$w_i = \frac{1}{n} \sum_{j=1}^{n} r_{ij}$$
3. **Consistency Index & Ratio:**
   $$CI = \frac{\lambda_{\max} - n}{n - 1}, \quad CR = \frac{CI}{RI}$$
   *(Konsisten jika $CR < 0.1$)*

### 2. Simple Additive Weighting (SAW)
1. **Normalisasi Matriks Keputusan ($R_{ij}$):**
   * Kriteria **Benefit**: $R_{ij} = \frac{x_{ij}}{\max_k(x_{kj})}$
   * Kriteria **Cost**: $R_{ij} = \frac{\min_k(x_{kj})}{x_{ij}}$
2. **Perhitungan Nilai Preferensi / Skor Akhir ($V_i$):**
   $$V_i = \sum_{j=1}^{m} w_j \cdot R_{ij}$$

---

## 🛠️ Tech Stack & Dependencies

* **Framework:** [Flutter](https://flutter.dev/) (Channel Stable, Dart SDK ^3.11.5)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Database & Auth:** [Firebase Auth](https://pub.dev/packages/firebase_auth), [Cloud Firestore](https://pub.dev/packages/cloud_firestore), [Google Sign-In](https://pub.dev/packages/google_sign_in)
* **Spreadsheet Engine:** [Excel](https://pub.dev/packages/excel), [CSV](https://pub.dev/packages/csv), [File Picker](https://pub.dev/packages/file_picker)
* **Typography & UI:** [Google Fonts](https://pub.dev/packages/google_fonts), [Cupertino Icons](https://pub.dev/packages/cupertino_icons)

---

## 🚀 Memulai (Getting Started)

### Prasyarat
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.19 ke atas disarankan)
* Android Studio / VS Code dengan ekstensi Flutter & Dart
* Perangkat Android fisik atau Emulator

### Instalasi & Menjalankan Aplikasi

1. **Clone Repositori:**
   ```bash
   git clone https://github.com/PZYCHU/SCORIFY.git
   cd scorify
   ```

2. **Pasang Dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan Aplikasi (Mode Debug):**
   ```bash
   flutter run
   ```

4. **Build APK Release:**
   ```bash
   flutter build apk --release
   ```
   *File output APK akan tersedia di: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 📁 Struktur Direktori Proyek

```text
scorify/
├── android/                   # Konfigurasi native Android & Gradle
├── assets/                    # Gambar, ikon, dan template
├── lib/
│   ├── models/                # Data model (Kelas, Kriteria, Murid, Nilai, Sesi)
│   ├── providers/             # State management (AppProvider)
│   ├── screens/
│   │   ├── ahp/               # Antarmuka matriks perbandingan & AHP
│   │   ├── class/             # Manajemen kelas, sesi, & input nilai
│   │   ├── kalkulasi/         # Tampilan hasil SAW & perangkingan
│   │   ├── login_regist/      # Autentikasi & pendaftaran guru
│   │   └── student/           # Import & kelola murid
│   ├── services/              # Firestore, Auth, Excel, & Kalkulasi SPK
│   ├── theme/                 # Tema warna dan gaya UI aplikasi
│   ├── utils/                 # Algoritma perhitungan AHP & SAW
│   ├── widgets/               # Komponen UI reusable (Chip, Card, Button)
│   └── main.dart              # Entry point aplikasi
└── pubspec.yaml               # Konfigurasi paket & aset
```

---

## 👨‍💻 Pengembang

* **Malika Pradnya** ([@PZYCHU](https://github.com/PZYCHU))  
  *Program Studi Sistem Informasi / Ilmu Komputer — Skripsi / Tugas Akhir*

---

<div align="center">
  <sub>Dibangun dengan ❤️ menggunakan Flutter & Firebase</sub>
</div>
