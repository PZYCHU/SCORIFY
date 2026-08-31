import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../utils/calculate_service.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Kelas> _kelasList = [];
  bool _loading = false;
  StreamSubscription<List<Kelas>>? _kelajsub;

  List<Kelas> get kelasList => _kelasList;
  bool get loading => _loading;

  // ─── Auth listener ────────────────────────────────────────────────────────

  /// Dipanggil dari [main.dart] setiap kali auth state berubah.
  /// - [uid] != null → subscribe stream Firestore untuk user tersebut.
  /// - [uid] == null → batalkan subscription & kosongkan data.
  void listenToUser(String? uid) {
    _kelajsub?.cancel();
    _kelajsub = null;

    if (uid == null) {
      _kelasList = [];
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _kelajsub = _firestore.streamKelas(uid).listen(
      (list) {
        _kelasList = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) debugPrint('🔥 Firestore stream error: $e');
        _loading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _kelajsub?.cancel();
    super.dispose();
  }

  // ─── Kelas CRUD ───────────────────────────────────────────────────────────

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
    await _firestore.upsertKelas(kelas);
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
      sudahKalkulasi: false,
      matriksAHP: kriteria != null
          ? KalkulasiService.matriksAwal(kriteria.length)
          : null,
    );
    await _firestore.upsertKelas(newKelas);
    // Stream Firestore akan update _kelasList otomatis
  }

  Future<void> hapusKelas(String kelasId) async {
    await _firestore.hapusKelas(kelasId);
  }

  Kelas? getKelas(String kelasId) {
    try {
      return _kelasList.firstWhere((k) => k.id == kelasId);
    } catch (_) {
      return null;
    }
  }

  // ─── Murid CRUD ───────────────────────────────────────────────────────────

  Future<void> tambahMurid(
    String kelasId, {
    required String nama,
    String? nis,
    required List<Nilai> nilaiList,
  }) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return;
    final murid = Murid(id: _uuid.v4(), nama: nama, nis: nis, nilaiList: nilaiList);
    await _firestore.upsertMurid(kelasId, murid);

    // Update sudahKalkulasi = false di kelas
    final updated = _kelasList[idx].copyWith(sudahKalkulasi: false);
    await _firestore.upsertKelas(updated);
  }

  Future<void> editMurid(
    String kelasId,
    String muridId, {
    String? nama,
    String? nis,
    List<Nilai>? nilaiList,
  }) async {
    final kIdx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (kIdx < 0) return;
    final kelas = _kelasList[kIdx];
    final mIdx = kelas.muridList.indexWhere((m) => m.id == muridId);
    if (mIdx < 0) return;

    final updatedMurid = kelas.muridList[mIdx].copyWith(
      nama: nama,
      nis: nis,
      nilaiList: nilaiList,
    );
    await _firestore.upsertMurid(kelasId, updatedMurid);

    final updatedKelas = kelas.copyWith(sudahKalkulasi: false);
    await _firestore.upsertKelas(updatedKelas);
  }

  Future<void> hapusMurid(String kelasId, String muridId) async {
    final kIdx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (kIdx < 0) return;

    await _firestore.hapusMurid(kelasId, muridId);

    final updatedKelas = _kelasList[kIdx].copyWith(sudahKalkulasi: false);
    await _firestore.upsertKelas(updatedKelas);
  }

  // ─── Input Nilai Performa (saat KBM) ────────────────────────────────────

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

    final todayStr = '${tanggal.year}-${tanggal.month}-${tanggal.day}';
    final existingIdx = murid.nilaiList.indexWhere((n) {
      final nStr = '${n.tanggal.year}-${n.tanggal.month}-${n.tanggal.day}';
      return n.kriteriaId == kriteriaId && nStr == todayStr;
    });

    List<Nilai> updatedNilaiList = List.from(murid.nilaiList);

    if (existingIdx >= 0) {
      updatedNilaiList[existingIdx] = Nilai(
        id: updatedNilaiList[existingIdx].id,
        siswaId: muridId,
        kriteriaId: kriteriaId,
        nilai: nilai,
        attempt: 1,
        tanggal: tanggal,
      );
    } else {
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
    await _firestore.upsertMurid(kelasId, updatedMurid);
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

    final updated = kelas.copyWith(
      sesiList: [...kelas.sesiList, sesi],
      sudahKalkulasi: false,
    );
    await _firestore.upsertKelas(updated);
    return sesi;
  }

  Future<void> hapusSesi(String kelasId, String sesiId) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return;
    final kelas = _kelasList[idx];
    final updated = kelas.copyWith(
      sesiList: kelas.sesiList.where((s) => s.id != sesiId).toList(),
      sudahKalkulasi: false,
    );
    await _firestore.upsertKelas(updated);
  }

  // ─── Input Nilai Hasil (per sesi) ────────────────────────────────────────

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

    final updatedMurid = murid.copyWith(
      nilaiList: [...murid.nilaiList, newNilai],
    );
    await _firestore.upsertMurid(kelasId, updatedMurid);

    final updatedKelas = kelas.copyWith(sudahKalkulasi: false);
    await _firestore.upsertKelas(updatedKelas);
  }

  // ─── AHP ────────────────────────────────────────────────────────────────

  Future<HasilAHP?> simpanMatriksAHP(
    String kelasId,
    List<List<double>> matriks,
  ) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return null;

    final hasil = KalkulasiService.hitungAHP(matriks);
    if (!hasil.konsisten) return hasil;

    final kelas = _kelasList[idx];
    final updatedKriteria = kelas.kriteria.asMap().entries.map((e) {
      return e.value.copyWith(bobot: hasil.bobot[e.key]);
    }).toList();

    final updated = kelas.copyWith(
      kriteria: updatedKriteria,
      matriksAHP: matriks,
      sudahKalkulasi: false,
    );
    await _firestore.upsertKelas(updated);
    return hasil;
  }

  // ─── Kalkulasi SAW ───────────────────────────────────────────────────────

  Map<String, List<String>> cekKesiapanKalkulasi(String kelasId) {
    final kelas = getKelas(kelasId);
    if (kelas == null) return {};

    final kriteriaWajib = kelas.kriteria
        .where((k) => k.jenis == JenisKriteria.hasil)
        .where((k) => kelas.sesiList.any((s) => s.kriteriaId == k.id))
        .toList();

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

    final bobotBelumDiisi = kelas.kriteria.any((k) => k.bobot == 0.0);
    if (bobotBelumDiisi) return null;

    final hasil = KalkulasiService.hitungSAW(kelas.muridList, kelas.kriteria);

    // Simpan skor final ke setiap murid di Firestore
    await _firestore.batchUpsertMurid(kelasId, hasil.muridTerurut);

    // Update flag sudahKalkulasi di kelas
    final updated = kelas.copyWith(
      muridList: hasil.muridTerurut,
      sudahKalkulasi: true,
    );
    await _firestore.upsertKelas(updated);

    return hasil;
  }

  // ─── Import CSV (batch tambah murid) ─────────────────────────────────────

  Future<void> importMuridBatch(String kelasId, List<Murid> muridList) async {
    final idx = _kelasList.indexWhere((k) => k.id == kelasId);
    if (idx < 0) return;

    await _firestore.batchUpsertMurid(kelasId, muridList);

    final updated = _kelasList[idx].copyWith(sudahKalkulasi: false);
    await _firestore.upsertKelas(updated);
  }
}
