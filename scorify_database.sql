-- ==============================================================================
-- SCORIFY: SISTEM PENDUKUNG KEPUTUSAN PENILAIAN SISWA (AHP + SAW)
-- DATABASE SCHEMA, DUMMY DATA (5 SISWA), & VERIFIKASI KALKULASI SQL
-- ==============================================================================
-- Penulis   : Malika Pradnya
-- Skripsi   : Sistem Pendukung Keputusan Penilaian Prestasi Siswa berbasis AHP & SAW
-- Catatan   : Skrip ini dirancang kompatibel dengan MySQL, PostgreSQL, & SQLite.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. DROP EXISTING TABLES (Urutan child -> parent untuk menjaga foreign key)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS nilai;
DROP TABLE IF EXISTS sesi;
DROP TABLE IF EXISTS kriteria_target_remedi;
DROP TABLE IF EXISTS matriks_ahp;
DROP TABLE IF EXISTS murid;
DROP TABLE IF EXISTS kriteria;
DROP TABLE IF EXISTS kelas;
DROP TABLE IF EXISTS users;

-- ------------------------------------------------------------------------------
-- 2. DDL: SKEMA DATABASE RELASIONAL
-- ------------------------------------------------------------------------------

-- Tabel 1: USERS (Guru / Tenaga Pendidik)
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel 2: KELAS (Kelompok Belajar / Mata Pelajaran)
CREATE TABLE kelas (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    nama VARCHAR(100) NOT NULL,
    sudah_kalkulasi BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_kelas_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE
);

-- Tabel 3: KRITERIA (Parameter Penilaian SPK)
-- Mendukung 3 jenis:
--  - performa : dinilai saat KBM langsung (counter / nilai 0-100)
--  - hasil    : dinilai setelah koreksi tugas/ujian, memiliki sesi & remedial
--  - derived  : dihitung otomatis oleh sistem (contoh: frekuensi remedial)
CREATE TABLE kriteria (
    id VARCHAR(50) PRIMARY KEY,
    kelas_id VARCHAR(50) NOT NULL,
    kode VARCHAR(10) NOT NULL,
    nama VARCHAR(100) NOT NULL,
    jenis VARCHAR(20) NOT NULL CHECK (jenis IN ('performa', 'hasil', 'derived')),
    input_type VARCHAR(20) CHECK (input_type IN ('counter', 'attendance', 'number')),
    arah VARCHAR(10) NOT NULL CHECK (arah IN ('benefit', 'cost')),
    bobot DECIMAL(8, 4) DEFAULT 0.0000,
    per_sesi BOOLEAN DEFAULT 0,
    urutan INT NOT NULL,
    CONSTRAINT fk_kriteria_kelas FOREIGN KEY (kelas_id) 
        REFERENCES kelas(id) ON DELETE CASCADE
);

-- Tabel 4: KRITERIA_TARGET_REMEDI (Relasi M-to-N Kriteria Derived ke Kriteria Hasil)
-- Menentukan kriteria tugas/ujian mana saja yang dipantau pengulangannya
CREATE TABLE kriteria_target_remedi (
    kriteria_id VARCHAR(50) NOT NULL,
    target_kriteria_id VARCHAR(50) NOT NULL,
    PRIMARY KEY (kriteria_id, target_kriteria_id),
    CONSTRAINT fk_ktr_derived FOREIGN KEY (kriteria_id) 
        REFERENCES kriteria(id) ON DELETE CASCADE,
    CONSTRAINT fk_ktr_target FOREIGN KEY (target_kriteria_id) 
        REFERENCES kriteria(id) ON DELETE CASCADE
);

-- Tabel 5: SESI (Pertemuan / Sesi Ujian untuk Kriteria Jenis 'Hasil')
CREATE TABLE sesi (
    id VARCHAR(50) PRIMARY KEY,
    kriteria_id VARCHAR(50) NOT NULL,
    nama VARCHAR(100) NOT NULL,
    urutan INT NOT NULL,
    tanggal DATE NOT NULL,
    CONSTRAINT fk_sesi_kriteria FOREIGN KEY (kriteria_id) 
        REFERENCES kriteria(id) ON DELETE CASCADE
);

-- Tabel 6: MURID (Entitas Siswa / Alternatif SPK)
CREATE TABLE murid (
    id VARCHAR(50) PRIMARY KEY,
    kelas_id VARCHAR(50) NOT NULL,
    nis VARCHAR(30),
    nama VARCHAR(100) NOT NULL,
    skor_final DECIMAL(6, 2) DEFAULT NULL,
    CONSTRAINT fk_murid_kelas FOREIGN KEY (kelas_id) 
        REFERENCES kelas(id) ON DELETE CASCADE
);

-- Tabel 7: NILAI (Fakta Transaksional Penilaian & Audit Log Remedial)
-- attempt = 1 (ujian pertama), attempt > 1 (remedial/retake)
CREATE TABLE nilai (
    id VARCHAR(50) PRIMARY KEY,
    murid_id VARCHAR(50) NOT NULL,
    kriteria_id VARCHAR(50) NOT NULL,
    sesi_id VARCHAR(50) DEFAULT NULL,
    nilai DECIMAL(6, 2) NOT NULL,
    attempt INT NOT NULL DEFAULT 1,
    tanggal TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_nilai_murid FOREIGN KEY (murid_id) 
        REFERENCES murid(id) ON DELETE CASCADE,
    CONSTRAINT fk_nilai_kriteria FOREIGN KEY (kriteria_id) 
        REFERENCES kriteria(id) ON DELETE CASCADE,
    CONSTRAINT fk_nilai_sesi FOREIGN KEY (sesi_id) 
        REFERENCES sesi(id) ON DELETE SET NULL
);

-- Tabel 8: MATRIKS_AHP (Penyimpanan Matriks Perbandingan Berpasangan Saaty 1-9)
CREATE TABLE matriks_ahp (
    kelas_id VARCHAR(50) NOT NULL,
    kriteria_i VARCHAR(50) NOT NULL,
    kriteria_j VARCHAR(50) NOT NULL,
    nilai DECIMAL(10, 4) NOT NULL,
    PRIMARY KEY (kelas_id, kriteria_i, kriteria_j),
    CONSTRAINT fk_ahp_kelas FOREIGN KEY (kelas_id) 
        REFERENCES kelas(id) ON DELETE CASCADE,
    CONSTRAINT fk_ahp_ki FOREIGN KEY (kriteria_i) 
        REFERENCES kriteria(id) ON DELETE CASCADE,
    CONSTRAINT fk_ahp_kj FOREIGN KEY (kriteria_j) 
        REFERENCES kriteria(id) ON DELETE CASCADE
);

-- ------------------------------------------------------------------------------
-- 3. DML: DATA MASTER, SKENARIO 5 KRITERIA & 5 SISWA
-- ------------------------------------------------------------------------------

-- Insert User & Kelas
INSERT INTO users (id, nama, email) 
VALUES ('USR_001', 'Dosen Pembimbing Database', 'dosen.db@kampus.ac.id');

INSERT INTO kelas (id, user_id, nama, sudah_kalkulasi) 
VALUES ('KLS_TI01', 'USR_001', 'Praktikum Basis Data Kelas A', 1);

-- Insert 5 Kriteria Penilaian
-- Bobot dihasilkan dari kalkulasi AHP Matriks 5x5 dengan CR = 0.0202 <= 0.10 (Konsisten)
INSERT INTO kriteria (id, kelas_id, kode, nama, jenis, input_type, arah, bobot, per_sesi, urutan) VALUES
('CRT_C1', 'KLS_TI01', 'C1', 'Keaktifan Bertanya & Diskusi', 'performa', 'counter', 'benefit', 0.0986, 0, 1),
('CRT_C2', 'KLS_TI01', 'C2', 'Keterampilan Praktik Lab',    'performa', 'number',  'benefit', 0.1611, 0, 2),
('CRT_C3', 'KLS_TI01', 'C3', 'Rata-rata Tugas & Latihan',    'hasil',    'number',  'benefit', 0.2618, 1, 3),
('CRT_C4', 'KLS_TI01', 'C4', 'Ujian Tengah Semester (UTS)',  'hasil',    'number',  'benefit', 0.4162, 1, 4),
('CRT_C5', 'KLS_TI01', 'C5', 'Frekuensi Remedial Siswa',     'derived',  NULL,      'cost',    0.0624, 0, 5);

-- Konfigurasi Kriteria Derived C5 (Memantau Remedial pada Tugas CRT_C3 dan UTS CRT_C4)
INSERT INTO kriteria_target_remedi (kriteria_id, target_kriteria_id) VALUES
('CRT_C5', 'CRT_C3'),
('CRT_C5', 'CRT_C4');

-- Sesi Penilaian untuk Kriteria Hasil
INSERT INTO sesi (id, kriteria_id, nama, urutan, tanggal) VALUES
('SES_T1', 'CRT_C3', 'Tugas 1: Normalisasi & DDL', 1, '2026-03-01'),
('SES_T2', 'CRT_C3', 'Tugas 2: DML & Query SQL',   2, '2026-03-15'),
('SES_UTS', 'CRT_C4', 'UTS Praktik Database',       1, '2026-04-10');

-- Matriks Perbandingan Berpasangan AHP (5x5)
-- Skala Saaty: 1=Sama, 2=Sedang, 3=Sedikit Lebih, 4=Cukup Lebih, 5=Sangat Lebih penting
INSERT INTO matriks_ahp (kelas_id, kriteria_i, kriteria_j, nilai) VALUES
('KLS_TI01', 'CRT_C1', 'CRT_C1', 1.0000), ('KLS_TI01', 'CRT_C1', 'CRT_C2', 0.5000), ('KLS_TI01', 'CRT_C1', 'CRT_C3', 0.3333), ('KLS_TI01', 'CRT_C1', 'CRT_C4', 0.2500), ('KLS_TI01', 'CRT_C1', 'CRT_C5', 2.0000),
('KLS_TI01', 'CRT_C2', 'CRT_C1', 2.0000), ('KLS_TI01', 'CRT_C2', 'CRT_C2', 1.0000), ('KLS_TI01', 'CRT_C2', 'CRT_C3', 0.5000), ('KLS_TI01', 'CRT_C2', 'CRT_C4', 0.3333), ('KLS_TI01', 'CRT_C2', 'CRT_C5', 3.0000),
('KLS_TI01', 'CRT_C3', 'CRT_C1', 3.0000), ('KLS_TI01', 'CRT_C3', 'CRT_C2', 2.0000), ('KLS_TI01', 'CRT_C3', 'CRT_C3', 1.0000), ('KLS_TI01', 'CRT_C3', 'CRT_C4', 0.5000), ('KLS_TI01', 'CRT_C3', 'CRT_C5', 4.0000),
('KLS_TI01', 'CRT_C4', 'CRT_C1', 4.0000), ('KLS_TI01', 'CRT_C4', 'CRT_C2', 3.0000), ('KLS_TI01', 'CRT_C4', 'CRT_C3', 2.0000), ('KLS_TI01', 'CRT_C4', 'CRT_C4', 1.0000), ('KLS_TI01', 'CRT_C4', 'CRT_C5', 5.0000),
('KLS_TI01', 'CRT_C5', 'CRT_C1', 0.5000), ('KLS_TI01', 'CRT_C5', 'CRT_C2', 0.3333), ('KLS_TI01', 'CRT_C5', 'CRT_C3', 0.2500), ('KLS_TI01', 'CRT_C5', 'CRT_C4', 0.2000), ('KLS_TI01', 'CRT_C5', 'CRT_C5', 1.0000);

-- Insert 5 Orang Siswa (Alternatif)
INSERT INTO murid (id, kelas_id, nis, nama) VALUES
('MRD_01', 'KLS_TI01', '2024001', 'Ahmad Fauzi'),
('MRD_02', 'KLS_TI01', '2024002', 'Budi Santoso'),
('MRD_03', 'KLS_TI01', '2024003', 'Citra Lestari'),
('MRD_04', 'KLS_TI01', '2024004', 'Dedi Pratama'),
('MRD_05', 'KLS_TI01', '2024005', 'Eka Rahmawati');

-- ------------------------------------------------------------------------------
-- INSERT FAKTA NILAI & JEJAK REMEDIAL UNTUK 5 SISWA
-- ------------------------------------------------------------------------------

-- 1. Kriteria C1: Keaktifan (Counter/Poin Tambahan selama KBM)
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_C1_M1', 'MRD_01', 'CRT_C1', NULL, 15.0, 1, '2026-04-10'),
('N_C1_M2', 'MRD_02', 'CRT_C1', NULL, 18.0, 1, '2026-04-10'),
('N_C1_M3', 'MRD_03', 'CRT_C1', NULL,  6.0, 1, '2026-04-10'),
('N_C1_M4', 'MRD_04', 'CRT_C1', NULL, 14.0, 1, '2026-04-10'),
('N_C1_M5', 'MRD_05', 'CRT_C1', NULL,  5.0, 1, '2026-04-10');

-- 2. Kriteria C2: Praktik Lab (Skala 0-100 Psikomotorik)
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_C2_M1', 'MRD_01', 'CRT_C2', NULL, 88.0, 1, '2026-04-10'),
('N_C2_M2', 'MRD_02', 'CRT_C2', NULL, 82.0, 1, '2026-04-10'),
('N_C2_M3', 'MRD_03', 'CRT_C2', NULL, 85.0, 1, '2026-04-10'),
('N_C2_M4', 'MRD_04', 'CRT_C2', NULL, 78.0, 1, '2026-04-10'),
('N_C2_M5', 'MRD_05', 'CRT_C2', NULL, 70.0, 1, '2026-04-10');

-- 3. Kriteria C3: Tugas (Sesi SES_T1 & SES_T2)
-- Ahmad (T1=85, T2=90) -> Rata-rata = 87.5
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_T1_M1', 'MRD_01', 'CRT_C3', 'SES_T1', 85.0, 1, '2026-03-01'),
('N_T2_M1', 'MRD_01', 'CRT_C3', 'SES_T2', 90.0, 1, '2026-03-15');

-- Budi (T1=75, T2=80) -> Rata-rata = 77.5
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_T1_M2', 'MRD_02', 'CRT_C3', 'SES_T1', 75.0, 1, '2026-03-01'),
('N_T2_M2', 'MRD_02', 'CRT_C3', 'SES_T2', 80.0, 1, '2026-03-15');

-- Citra (T1=95, T2=90) -> Rata-rata = 92.5
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_T1_M3', 'MRD_03', 'CRT_C3', 'SES_T1', 95.0, 1, '2026-03-01'),
('N_T2_M3', 'MRD_03', 'CRT_C3', 'SES_T2', 90.0, 1, '2026-03-15');

-- Dedi (T1=70, T2=70) -> Rata-rata = 70.0
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_T1_M4', 'MRD_04', 'CRT_C3', 'SES_T1', 70.0, 1, '2026-03-01'),
('N_T2_M4', 'MRD_04', 'CRT_C3', 'SES_T2', 70.0, 1, '2026-03-15');

-- Eka (T1: Attempt 1=50, Attempt 2=60 [Remedi!]; T2=65) -> Rata-rata = 62.5
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_T1_M5_A1', 'MRD_05', 'CRT_C3', 'SES_T1', 50.0, 1, '2026-03-01'),
('N_T1_M5_A2', 'MRD_05', 'CRT_C3', 'SES_T1', 60.0, 2, '2026-03-05'),
('N_T2_M5',    'MRD_05', 'CRT_C3', 'SES_T2', 65.0, 1, '2026-03-15');

-- 4. Kriteria C4: UTS (Sesi SES_UTS dengan Jejak Riwayat Remedial / Retake)
-- Ahmad: Attempt 1 = 90 (Lulus langsung, Remedi = 0)
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_UTS_M1', 'MRD_01', 'CRT_C4', 'SES_UTS', 90.0, 1, '2026-04-10');

-- Budi: Attempt 1 = 65, Attempt 2 = 85 (Ada 1 sesi remedi)
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_UTS_M2_A1', 'MRD_02', 'CRT_C4', 'SES_UTS', 65.0, 1, '2026-04-10'),
('N_UTS_M2_A2', 'MRD_02', 'CRT_C4', 'SES_UTS', 85.0, 2, '2026-04-17');

-- Citra: Attempt 1 = 88 (Lulus langsung, Remedi = 0)
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_UTS_M3', 'MRD_03', 'CRT_C4', 'SES_UTS', 88.0, 1, '2026-04-10');

-- Dedi: Attempt 1 = 55, Attempt 2 = 75 (Ada 1 sesi remedi)
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_UTS_M4_A1', 'MRD_04', 'CRT_C4', 'SES_UTS', 55.0, 1, '2026-04-10'),
('N_UTS_M4_A2', 'MRD_04', 'CRT_C4', 'SES_UTS', 75.0, 2, '2026-04-17');

-- Eka: Attempt 1 = 50, Attempt 2 = 60, Attempt 3 = 70 (Remedi UTS)
INSERT INTO nilai (id, murid_id, kriteria_id, sesi_id, nilai, attempt, tanggal) VALUES
('N_UTS_M5_A1', 'MRD_05', 'CRT_C4', 'SES_UTS', 50.0, 1, '2026-04-10'),
('N_UTS_M5_A2', 'MRD_05', 'CRT_C4', 'SES_UTS', 60.0, 2, '2026-04-17'),
('N_UTS_M5_A3', 'MRD_05', 'CRT_C4', 'SES_UTS', 70.0, 3, '2026-04-24');

-- ------------------------------------------------------------------------------
-- 4. QUERY VERIFIKASI UNTUK DOSEN DATABASE (MURNI SQL)
-- ------------------------------------------------------------------------------

-- ==============================================================================
-- QUERY 1: REKAPITULASI NILAI RINGKASAN TIAP ALTERNATIF (MATRIKS KEPUTUSAN X)
-- Menghitung agregasi counter (SUM), performa (AVG), hasil terbaik sesi, dan derived remedi
-- ==============================================================================
WITH best_hasil_sesi AS (
    SELECT 
        n.murid_id,
        n.kriteria_id,
        n.sesi_id,
        MAX(n.nilai) as nilai_terbaik
    FROM nilai n
    JOIN kriteria k ON n.kriteria_id = k.id
    WHERE k.jenis = 'hasil'
    GROUP BY n.murid_id, n.kriteria_id, n.sesi_id
),
ringkasan_hasil AS (
    SELECT 
        murid_id,
        kriteria_id,
        AVG(nilai_terbaik) as nilai_ringkas
    FROM best_hasil_sesi
    GROUP BY murid_id, kriteria_id
),
ringkasan_performa AS (
    SELECT 
        n.murid_id,
        n.kriteria_id,
        CASE 
            WHEN k.input_type = 'counter' THEN SUM(n.nilai)
            ELSE AVG(n.nilai)
        END as nilai_ringkas
    FROM nilai n
    JOIN kriteria k ON n.kriteria_id = k.id
    WHERE k.jenis = 'performa'
    GROUP BY n.murid_id, n.kriteria_id, k.input_type
),
remedial_count AS (
    SELECT 
        n.murid_id,
        'CRT_C5' as kriteria_id,
        COUNT(DISTINCT n.sesi_id) as nilai_ringkas
    FROM nilai n
    JOIN kriteria_target_remedi tr ON n.kriteria_id = tr.target_kriteria_id
    WHERE n.attempt > 1
    GROUP BY n.murid_id
),
semua_nilai AS (
    SELECT murid_id, kriteria_id, nilai_ringkas FROM ringkasan_hasil
    UNION ALL
    SELECT murid_id, kriteria_id, nilai_ringkas FROM ringkasan_performa
    UNION ALL
    SELECT m.id as murid_id, 'CRT_C5' as kriteria_id, COALESCE(rc.nilai_ringkas, 0.0) as nilai_ringkas
    FROM murid m
    LEFT JOIN remedial_count rc ON m.id = rc.murid_id
)
SELECT 
    m.nis,
    m.nama,
    k.kode as kriteria,
    k.nama as nama_kriteria,
    k.arah,
    sn.nilai_ringkas as x_ij
FROM semua_nilai sn
JOIN murid m ON sn.murid_id = m.id
JOIN kriteria k ON sn.kriteria_id = k.id
ORDER BY m.nis, k.urutan;


-- ==============================================================================
-- QUERY 2: KALKULASI NORMALISASI SAW (R_ij) DAN SKOR PREFERENSI AKHIR (V_i)
-- Termasuk Penentuan Ranking Menggunakan Window Function DENSE_RANK()
-- ==============================================================================
WITH best_hasil_sesi AS (
    SELECT 
        n.murid_id,
        n.kriteria_id,
        n.sesi_id,
        MAX(n.nilai) as nilai_terbaik
    FROM nilai n
    JOIN kriteria k ON n.kriteria_id = k.id
    WHERE k.jenis = 'hasil'
    GROUP BY n.murid_id, n.kriteria_id, n.sesi_id
),
ringkasan_hasil AS (
    SELECT 
        murid_id,
        kriteria_id,
        AVG(nilai_terbaik) as nilai_ringkas
    FROM best_hasil_sesi
    GROUP BY murid_id, kriteria_id
),
ringkasan_performa AS (
    SELECT 
        n.murid_id,
        n.kriteria_id,
        CASE 
            WHEN k.input_type = 'counter' THEN SUM(n.nilai)
            ELSE AVG(n.nilai)
        END as nilai_ringkas
    FROM nilai n
    JOIN kriteria k ON n.kriteria_id = k.id
    WHERE k.jenis = 'performa'
    GROUP BY n.murid_id, n.kriteria_id, k.input_type
),
remedial_count AS (
    SELECT 
        n.murid_id,
        'CRT_C5' as kriteria_id,
        COUNT(DISTINCT n.sesi_id) as nilai_ringkas
    FROM nilai n
    JOIN kriteria_target_remedi tr ON n.kriteria_id = tr.target_kriteria_id
    WHERE n.attempt > 1
    GROUP BY n.murid_id
),
semua_nilai AS (
    SELECT murid_id, kriteria_id, nilai_ringkas FROM ringkasan_hasil
    UNION ALL
    SELECT murid_id, kriteria_id, nilai_ringkas FROM ringkasan_performa
    UNION ALL
    SELECT m.id as murid_id, 'CRT_C5' as kriteria_id, COALESCE(rc.nilai_ringkas, 0.0) as nilai_ringkas
    FROM murid m
    LEFT JOIN remedial_count rc ON m.id = rc.murid_id
),
min_max_kriteria AS (
    SELECT 
        kriteria_id,
        MAX(nilai_ringkas) as max_val,
        MIN(nilai_ringkas) as min_val
    FROM semua_nilai
    GROUP BY kriteria_id
),
normalisasi_saw AS (
    SELECT 
        sn.murid_id,
        sn.kriteria_id,
        sn.nilai_ringkas,
        k.arah,
        k.bobot,
        mm.max_val,
        mm.min_val,
        CASE 
            WHEN mm.max_val = mm.min_val THEN 1.0
            WHEN k.arah = 'benefit' THEN 
                CASE WHEN mm.max_val = 0 THEN 0.0 ELSE CAST(sn.nilai_ringkas AS FLOAT) / mm.max_val END
            ELSE 
                -- Cost criteria (semakin kecil frekuensi remedial semakin baik)
                CASE WHEN sn.nilai_ringkas = 0 THEN 1.0 ELSE CAST(mm.min_val AS FLOAT) / sn.nilai_ringkas END
        END as r_ij
    FROM semua_nilai sn
    JOIN kriteria k ON sn.kriteria_id = k.id
    JOIN min_max_kriteria mm ON sn.kriteria_id = mm.kriteria_id
),
skor_akhir AS (
    SELECT 
        murid_id,
        ROUND(SUM(bobot * r_ij) * 100, 2) as skor_total
    FROM normalisasi_saw
    GROUP BY murid_id
)
SELECT 
    DENSE_RANK() OVER (ORDER BY sa.skor_total DESC) as ranking,
    m.nis,
    m.nama,
    sa.skor_total as skor_saw,
    CASE 
        WHEN sa.skor_total >= 85.0 THEN 'Sangat Memuaskan (A)'
        WHEN sa.skor_total >= 75.0 THEN 'Memuaskan (B)'
        ELSE 'Cukup / Butuh Bimbingan (C)'
    END as predikat
FROM skor_akhir sa
JOIN murid m ON sa.murid_id = m.id
ORDER BY ranking;

-- ==============================================================================
-- QUERY 3: AUDIT TRAIL LOG REMEDIAL SISWA (SHEET 2 LAPORAN EXCEL)
-- Menampilkan siswa yang mengambil ujian ulang untuk akuntabilitas dosen/guru
-- ==============================================================================
SELECT 
    m.nis,
    m.nama as nama_siswa,
    k.nama as kriteria,
    s.nama as sesi_evaluasi,
    n.attempt as ke_attempt,
    n.nilai as nilai_diperoleh,
    n.tanggal as tanggal_input
FROM nilai n
JOIN murid m ON n.murid_id = m.id
JOIN kriteria k ON n.kriteria_id = k.id
LEFT JOIN sesi s ON n.sesi_id = s.id
WHERE n.murid_id IN (
    SELECT DISTINCT murid_id FROM nilai WHERE attempt > 1
)
ORDER BY m.nis, k.urutan, s.urutan, n.attempt;
