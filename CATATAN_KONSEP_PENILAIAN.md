# CATATAN KONSEP PENILAIAN SCORIFY (SPK AHP + SAW)

Dokumen ini mencatat rangkuman konsep, arsitektur data, dan perbedaan jenis kriteria penilaian pada aplikasi Scorify sebagai referensi penulisan skripsi dan presentasi sidang.

---

## 1. Tiga Jenis Kriteria Penilaian di Scorify

| Jenis Kriteria | Objek yang Dinilai | Cara Input | Sifat Penilaian | Contoh Kriteria | Kemungkinan Remedial? |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **1. Performa** | Aktivitas, sikap, & unjuk kerja langsung saat jam KBM | ➕ **Poin Tambahan (+)** ATAU <br> 📝 **Nilai Angka (0–100)** | Dinilai *on-the-spot* di kelas saat aksi berlangsung | Keaktifan, Kedisiplinan, Presentasi, Praktik Lab, Olahraga | ❌ Tidak ada (observasi langsung) |
| **2. Hasil** | Penguasaan akademik dari evaluasi terstruktur | 📝 **Nilai Angka (0–100)** | Diinput per sesi setelah koreksi lembar kerja/ujian | Tugas 1, Kuis Harian, UTS, UAS | ✅ **Bisa ada remedial / retake** |
| **3. Perhitungan Remedi** *(Derived)* | Efisiensi belajar / frekuensi pengulangan ujian | ⚙️ **Otomatis oleh Sistem** (dari log attempt > 1 pada kriteria Hasil terpilih) | Kriteria *Cost* ($\downarrow$): Semakin sedikit remedial, semakin baik skornya | Frekuensi Remedial Ujian | 🔄 Dihitung otomatis dari riwayat nilai |

---

## 2. Perbedaan Mendalam: "Poin" vs "Nilai Angka" pada Kriteria Performa

Meskipun sama-sama berada di kategori **Performa** (dinilai saat jam pelajaran berlangsung tanpa sesi ujian tertulis), keduanya memiliki perbedaan mendasar:

### A. Poin Tambahan (Counter / Akumulasi `+`)
* **Sifat Data:** Bersifat **aditif (bertambah terus)** dari $0$ ke atas setiap kali siswa melakukan aksi positif.
* **Tujuan Pengukuran:** Mengukur **kuantitas / frekuensi partisipasi** siswa selama proses belajar.
* **Contoh Pemakaian:**
  * Siswa berani bertanya di kelas $\rightarrow$ klik $+1$ poin.
  * Siswa berhasil menjawab soal kuis lisan di papan tulis $\rightarrow$ klik $+2$ poin.
  * Di akhir semester, siswa A mengumpulkan $15$ poin, siswa B mengumpulkan $8$ poin.
* **Dalam Perhitungan SAW:** Poin tertinggi di kelas ($x_{\max}$) menjadi standar pembanding normalisasi benefit ($\frac{x_{ij}}{x_{\max}}$).

---

### B. Nilai Angka (Skala Mutu `0–100`)
* **Sifat Data:** Bersifat **absolut / skala baku 0–100** berdasarkan rubrik observasi mutu saat itu.
* **Tujuan Pengukuran:** Mengukur **kualitas keterampilan / kinerja langsung** siswa pada saat jam pelajaran.
* **Contoh Pemakaian:**
  * **Ujian Praktik PJOK / Olahraga:** Guru mengamati teknik *lay-up shoot* bola basket siswa langsung di lapangan dan memberi nilai **85**.
  * **Praktikum Sains / Lab:** Guru mengamati cara siswa merangkai alat listrik di laboratorium dan memberi nilai **90**.
  * **Presentasi Kelompok:** Guru mengamati penyampaian materi kelompok di depan kelas dan memberi nilai **88**.
* **Kenapa Masuk Performa?** Karena dinilai langsung saat proses berlangsung (*live observation*), bukan lembar tugas yang dikumpulkan untuk dikoreksi belakangan di rumah/ruang guru.

---

## 3. Rangkuman Perbandingan Poin vs Nilai Performa

| Aspek Pembanding | ➕ Poin Tambahan (+) | 📝 Nilai Angka (0–100) di Performa |
| :--- | :--- | :--- |
| **Bentuk Nilai** | Akumulasi angka bulat ($+1, +2, +3, \dots$) | Angka absolut skala $0$ s.d. $100$ |
| **Metode Input** | Tombol cepat tap/klik $(+)$ di samping nama siswa | Input angka manual |
| **Fokus Evaluasi** | Keaktifan, frekuensi bertanya, partisipasi | Kualitas unjuk kerja / psikomotorik langsung |
| **Karakteristik** | Bertambah seiring berjalannya waktu kelas | Menggantikan / merefleksikan nilai unjuk kerja hari itu |

---

## 4. Mengapa Tugas & Ujian Masuk ke Kategori "Hasil"?

Tugas (PR/Latihan) dan Ujian (UTS/UAS) dikelompokkan ke dalam jenis **Hasil** karena:
1. **Memiliki Sesi:** Memiliki penamaan sesi terstruktur (Tugas 1, Tugas 2, UTS, UAS).
2. **Koreksi Terpisah:** Lembar jawaban dikoreksi setelah KBM selesai.
3. **Mendukung Remedial / Retake:** Sistem mencatat riwayat perbaikan nilai (*attempt 1, attempt 2*), yang kemudian menjadi sumber data otomatis untuk kriteria **Perhitungan Remedi**.
