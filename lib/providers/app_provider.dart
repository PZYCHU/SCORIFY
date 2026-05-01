import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../utils/calculate_service.dart';

const _uuid = Uuid();
const _prefsKey = 'kelas_data';

class AppProvider extends ChangeNotifier {
  List<Kelas> _kelasList = [];
  bool _loading = false;

  List<Kelas> get kelasList {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    return _kelasList.where((k) => k.userId == uid).toList();
  }
  bool get loading => _loading;

  AppProvider() {
    _loadFromPrefs();
  }

  // ─── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _kelasList = list.map((k) => Kelas.fromJson(k)).toList();

        // Migrate legacy data (jika ada kelas tanpa userId, jadikan milik current user)
        final uid = FirebaseAuth.instance.currentUser?.uid;
        bool migrated = false;
        if (uid != null) {
          for (int i = 0; i < _kelasList.length; i++) {
            if (_kelasList[i].userId.isEmpty) {
              _kelasList[i] = _kelasList[i].copyWith(userId: uid);
              migrated = true;
            }
          }
          if (migrated) _saveToPrefs();
        }
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_kelasList.map((k) => k.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  // ─── Kelas CRUD ───────────────────────────────────────────────────────────────

  Future<Kelas> tambahKelas({
    required String nama,
    required List<Kriteria> kriteria,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final kelas = Kelas(
      id: _uuid.v4(),
      userId: uid,
      nama: nama,
      kriteria: kriteria,
      muridList: [],
      sesiList: [],
      matriksAHP: KalkulasiService.matriksAwal(kriteria.length),
    );
    _kelasList.add(kelas);
    await _saveToPrefs();
    notifyListeners();
    return kelas;
  }

  Future<void> editKelas(
    String kelasId, {
    String? nama,
    List<Kriteria>? kriteria,
  }) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return;
    final kelas = _kelasList[idx];
    final newKelas = kelas.copyWith(
      nama: nama,
      kriteria: kriteria,
      sudahKalkulasi: false, // reset kalkulasi jika kriteria berubah
      matriksAHP: kriteria != null
          ? KalkulasiService.matriksAwal(kriteria.length)
          : null,
    );
    _kelasList[idx] = newKelas;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> hapusKelas(String kelasId) async {
    _kelasList.removeWhere((k) => k.id == kelasId);
    await _saveToPrefs();
    notifyListeners();
  }

  Kelas? getKelas(String kelasId) {
    try {
      return kelasList.firstWhere((k) => k.id == kelasId);
    } catch (_) {
      return null;
    }
  }

  // ─── Murid CRUD ───────────────────────────────────────────────────────────────

  Future<void> tambahMurid(
    String kelasId, {
    required String nama,
    required List<Nilai> nilaiList,
  }) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return;
    final murid = Murid(id: _uuid.v4(), nama: nama, nilaiList: nilaiList);
    final updated = _kelasList[idx].copyWith(
      muridList: [..._kelasList[idx].muridList, murid],
      sudahKalkulasi: false,
    );
    _kelasList[idx] = updated;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> editMurid(
    String kelasId,
    String muridId, {
    String? nama,
    List<Nilai>? nilaiList,
  }) async {
    final kIdx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (kIdx < 0) return;
    final kelas = _kelasList[kIdx];
    final mIdx = kelas.muridList.indexWhere((m) => m.id == muridId);
    if (mIdx < 0) return;
    final updatedMurid = kelas.muridList[mIdx].copyWith(
      nama: nama,
      nilaiList: nilaiList,
    );
    final newList = List<Murid>.from(kelas.muridList);
    newList[mIdx] = updatedMurid;
    _kelasList[kIdx] = kelas.copyWith(
      muridList: newList,
      sudahKalkulasi: false,
    );
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> hapusMurid(String kelasId, String muridId) async {
    final kIdx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (kIdx < 0) return;
    final kelas = _kelasList[kIdx];
    final newList = kelas.muridList.where((m) => m.id != muridId).toList();
    _kelasList[kIdx] = kelas.copyWith(
      muridList: newList,
      sudahKalkulasi: false,
    );
    await _saveToPrefs();
    notifyListeners();
  }
  // ─── Input Nilai Performa (saat KBM) ─────────────────────────────────────────
  // Tambahkan method ini di AppProvider, setelah method hapusMurid

  Future<void> inputNilaiPerforma({
    required String kelasId,
    required String muridId,
    required String kriteriaId,
    required double nilai,
    required DateTime tanggal,
  }) async {
    final kIdx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (kIdx < 0) return;
    final kelas = _kelasList[kIdx];

    final mIdx = kelas.muridList.indexWhere((m) => m.id == muridId);
    if (mIdx < 0) return;
    final murid = kelas.muridList[mIdx];

    // Cari nilai yang sudah ada untuk kriteria ini di tanggal yang sama
    // (biar tidak dobel entry untuk satu hari)
    final todayStr = '${tanggal.year}-${tanggal.month}-${tanggal.day}';
    final existingIdx = murid.nilaiList.indexWhere((n) {
      final nStr = '${n.tanggal.year}-${n.tanggal.month}-${n.tanggal.day}';
      return n.kriteriaId == kriteriaId && nStr == todayStr;
    });

    List<Nilai> updatedNilaiList = List.from(murid.nilaiList);

    if (existingIdx >= 0) {
      // Update nilai yang sudah ada hari ini
      updatedNilaiList[existingIdx] = Nilai(
        id: updatedNilaiList[existingIdx].id,
        siswaId: muridId,
        kriteriaId: kriteriaId,
        nilai: nilai,
        attempt: 1,
        tanggal: tanggal,
      );
    } else {
      // Tambah entry baru
      updatedNilaiList.add(Nilai(
        id: '${muridId}_${kriteriaId}_$todayStr',
        siswaId: muridId,
        kriteriaId: kriteriaId,
        nilai: nilai,
        attempt: 1,
        tanggal: tanggal,
      ));
    }

    final updatedMurid = murid.copyWith(nilaiList: updatedNilaiList);
    final newMuridList = List<Murid>.from(kelas.muridList);
    newMuridList[mIdx] = updatedMurid;

    _kelasList[kIdx] = kelas.copyWith(
      muridList: newMuridList,
      sudahKalkulasi: false,
    );

    await _saveToPrefs();
    notifyListeners();
  }
  // ─── Sesi CRUD ───────────────────────────────────────────────────────────

  Future<Sesi> tambahSesi(
    String kelasId,
    String kriteriaId,
    String nama,
  ) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) throw Exception('Kelas tidak ditemukan');

    final kelas = _kelasList[idx];
    final existing = kelas.getSesiByKriteria(kriteriaId);

    final sesi = Sesi(
      id: _uuid.v4(),
      kriteriaId: kriteriaId,
      nama: nama,
      urutan: existing.length + 1,
      tanggal: DateTime.now(),
    );

    _kelasList[idx] = kelas.copyWith(
      sesiList: [...kelas.sesiList, sesi],
      sudahKalkulasi: false,
    );
    await _saveToPrefs();
    notifyListeners();
    return sesi;
  }

  Future<void> hapusSesi(String kelasId, String sesiId) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return;
    final kelas = _kelasList[idx];
    _kelasList[idx] = kelas.copyWith(
      sesiList: kelas.sesiList.where((s) => s.id != sesiId).toList(),
      sudahKalkulasi: false,
    );
    await _saveToPrefs();
    notifyListeners();
  }

  // ─── Input Nilai Hasil (per sesi) ────────────────────────────────────────

  /// Input nilai tugas/tes per murid per sesi.
  /// Jika murid sudah punya nilai untuk sesi ini → attempt naik (retake).
  /// Jika belum → attempt = 1.
  Future<void> inputNilaiHasil({
    required String kelasId,
    required String muridId,
    required String kriteriaId,
    required String sesiId,
    required double nilai,
  }) async {
    final kIdx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (kIdx < 0) return;
    final kelas = _kelasList[kIdx];

    final mIdx = kelas.muridList.indexWhere((m) => m.id == muridId);
    if (mIdx < 0) return;
    final murid = kelas.muridList[mIdx];

    // Cari nilai sebelumnya untuk sesi ini
    final existing = murid.nilaiList
        .where((n) => n.kriteriaId == kriteriaId && n.sesiId == sesiId)
        .toList();

    final attempt = existing.isEmpty ? 1 : existing.length + 1;

    final newNilai = Nilai(
      id: '${muridId}_${kriteriaId}_${sesiId}_$attempt',
      siswaId: muridId,
      kriteriaId: kriteriaId,
      sesiId: sesiId,
      nilai: nilai,
      attempt: attempt,
      tanggal: DateTime.now(),
    );

    final updatedNilaiList = [...murid.nilaiList, newNilai];
    final updatedMurid = murid.copyWith(nilaiList: updatedNilaiList);
    final newMuridList = List<Murid>.from(kelas.muridList);
    newMuridList[mIdx] = updatedMurid;

    _kelasList[kIdx] = kelas.copyWith(
      muridList: newMuridList,
      sudahKalkulasi: false,
    );
    await _saveToPrefs();
    notifyListeners();
  }

  // ─── AHP ─────────────────────────────────────────────────────────────────────

  Future<HasilAHP?> simpanMatriksAHP(
    String kelasId,
    List<List<double>> matriks,
  ) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return null;

    final hasil = KalkulasiService.hitungAHP(matriks);
    if (!hasil.konsisten) {
      return hasil; // kembalikan hasil tapi jangan simpan bobot
    }

    // Update bobot di kriteria
    final kelas = _kelasList[idx];
    final updatedKriteria = kelas.kriteria.asMap().entries.map((e) {
      return e.value.copyWith(bobot: hasil.bobot[e.key]);
    }).toList();

    _kelasList[idx] = kelas.copyWith(
      kriteria: updatedKriteria,
      matriksAHP: matriks,
      sudahKalkulasi: false,
    );
    await _saveToPrefs();
    notifyListeners();
    return hasil;
  }

  // ─── Kalkulasi SAW ───────────────────────────────────────────────────────────

  /// Cek apakah data cukup untuk kalkulasi.
  /// Returns: {namaMurid: [namaKriteria yang belum ada nilainya]}
  /// Map kosong = siap kalkulasi.
  Map<String, List<String>> cekKesiapanKalkulasi(String kelasId) {
    final kelas = getKelas(kelasId);
    if (kelas == null) return {};

    // Hanya kriteria 'hasil' yang SUDAH ADA SESINYA yang wajib diisi.
    // Kriteria hasil tanpa sesi (misal UTS/UAS belum terjadi) dilewati.
    final kriteriaWajib = kelas.kriteria
        .where((k) => k.jenis == JenisKriteria.hasil)
        .where((k) => kelas.sesiList.any((s) => s.kriteriaId == k.id))
        .toList();

    // Tidak ada kriteria hasil yang aktif → langsung bisa kalkulasi
    if (kriteriaWajib.isEmpty) return {};

    final missing = <String, List<String>>{};
    for (final murid in kelas.muridList) {
      final belumAda = <String>[];
      for (final k in kriteriaWajib) {
        final punya = murid.getNilaiByKriteria(k.id).isNotEmpty;
        if (!punya) belumAda.add(k.nama);
      }
      if (belumAda.isNotEmpty) missing[murid.nama] = belumAda;
    }
    return missing;
  }

  Future<HasilSAW?> jalankanKalkulasi(String kelasId) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return null;
    final kelas = _kelasList[idx];

    // Pastikan semua bobot sudah diisi
    final bobotBelumDiisi = kelas.kriteria.any((k) => k.bobot == 0.0);
    if (bobotBelumDiisi) return null;

    final hasil = KalkulasiService.hitungSAW(kelas.muridList, kelas.kriteria);

    // Update murid dengan skor
    _kelasList[idx] = kelas.copyWith(
      muridList: hasil.muridTerurut,
      sudahKalkulasi: true,
    );
    await _saveToPrefs();
    notifyListeners();
    return hasil;
  }
}
