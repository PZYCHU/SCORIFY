import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/calculate_service.dart';

const _uuid = Uuid();
const _prefsKey = 'kelas_data';

class AppProvider extends ChangeNotifier {
  List<Kelas> _kelasList = [];
  bool _loading = false;

  List<Kelas> get kelasList => _kelasList;
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

  Future<Kelas> tambahKelas({required String nama, required List<Kriteria> kriteria}) async {
    final kelas = Kelas(
      id: _uuid.v4(),
      nama: nama,
      kriteria: kriteria,
      muridList: [],
      matriksAHP: KalkulasiService.matriksAwal(kriteria.length),
    );
    _kelasList.add(kelas);
    await _saveToPrefs();
    notifyListeners();
    return kelas;
  }

  Future<void> editKelas(String kelasId, {String? nama, List<Kriteria>? kriteria}) async {
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
      return _kelasList.firstWhere((k) => k.id == kelasId);
    } catch (_) {
      return null;
    }
  }

  // ─── Murid CRUD ───────────────────────────────────────────────────────────────

  Future<void> tambahMurid(String kelasId, {
    required String nama,
    required List<NilaiKriteria> nilaiList,
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

  Future<void> editMurid(String kelasId, String muridId, {
    String? nama,
    List<NilaiKriteria>? nilaiList,
  }) async {
    final kIdx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (kIdx < 0) return;
    final kelas = _kelasList[kIdx];
    final mIdx = kelas.muridList.indexWhere((m) => m.id == muridId);
    if (mIdx < 0) return;
    final updatedMurid = kelas.muridList[mIdx].copyWith(nama: nama, nilaiList: nilaiList);
    final newList = List<Murid>.from(kelas.muridList);
    newList[mIdx] = updatedMurid;
    _kelasList[kIdx] = kelas.copyWith(muridList: newList, sudahKalkulasi: false);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> hapusMurid(String kelasId, String muridId) async {
    final kIdx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (kIdx < 0) return;
    final kelas = _kelasList[kIdx];
    final newList = kelas.muridList.where((m) => m.id != muridId).toList();
    _kelasList[kIdx] = kelas.copyWith(muridList: newList, sudahKalkulasi: false);
    await _saveToPrefs();
    notifyListeners();
  }

  // ─── AHP ─────────────────────────────────────────────────────────────────────

  Future<HasilAHP?> simpanMatriksAHP(String kelasId, List<List<double>> matriks) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return null;

    final hasil = KalkulasiService.hitungAHP(matriks);
    if (!hasil.konsisten) return hasil; // kembalikan hasil tapi jangan simpan bobot

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
