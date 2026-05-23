import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Semua operasi Firestore untuk data kelas & murid.
/// Gunakan dari [AppProvider], bukan langsung dari screen.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Referensi koleksi ──────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _kelasCol =>
      _db.collection('kelas');

  CollectionReference<Map<String, dynamic>> _muridCol(String kelasId) =>
      _kelasCol.doc(kelasId).collection('murid');

  // ── Stream real-time kelas milik userId ───────────────────────────────────

  /// Menghasilkan stream [List<Kelas>] yang selalu up-to-date dari Firestore.
  /// Murid di-load secara terpisah via subcollection lalu digabungkan.
  Stream<List<Kelas>> streamKelas(String userId) {
    return _kelasCol
        .where('userId', isEqualTo: userId)
        // Tidak pakai orderBy di query agar tidak butuh composite index.
        // Sorting dilakukan di Dart setelah data diterima.
        .snapshots()
        .asyncMap((snap) async {
      final List<Kelas> kelasList = [];

      for (final doc in snap.docs) {
        final data = doc.data();
        // Load subcollection murid
        final muridSnap = await _muridCol(doc.id).get();
        final muridList = muridSnap.docs
            .map((m) => Murid.fromJson(m.data()))
            .toList();

        // Gabungkan data kelas + murid
        final kelas = Kelas.fromJson({
          ...data,
          'muridList': muridList.map((m) => m.toJson()).toList(),
        });
        kelasList.add(kelas);
      }

      // Sort by updatedAt descending (null-safe, terbaru di atas)
      kelasList.sort((a, b) {
        final aTs = snap.docs
            .firstWhere((d) => d.id == a.id)
            .data()['updatedAt'];
        final bTs = snap.docs
            .firstWhere((d) => d.id == b.id)
            .data()['updatedAt'];
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return (bTs as dynamic).compareTo(aTs as dynamic);
      });

      return kelasList;
    });
  }

  // ── CRUD Kelas ─────────────────────────────────────────────────────────────

  /// Buat atau update dokumen kelas (tanpa murid — murid ada di subcollection).
  Future<void> upsertKelas(Kelas kelas) async {
    final data = _kelasToFirestore(kelas);
    await _kelasCol.doc(kelas.id).set(data, SetOptions(merge: true));
  }

  /// Hapus kelas beserta semua dokumen murid di subcollection-nya.
  Future<void> hapusKelas(String kelasId) async {
    // Hapus semua murid dulu (Firestore tidak otomatis hapus subcollection)
    final muridSnap = await _muridCol(kelasId).get();
    final batch = _db.batch();
    for (final doc in muridSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_kelasCol.doc(kelasId));
    await batch.commit();
  }

  // ── CRUD Murid ─────────────────────────────────────────────────────────────

  /// Buat atau update dokumen murid di subcollection kelas.
  Future<void> upsertMurid(String kelasId, Murid murid) async {
    await _muridCol(kelasId).doc(murid.id).set(murid.toJson());
  }

  /// Hapus dokumen murid dari subcollection.
  Future<void> hapusMurid(String kelasId, String muridId) async {
    await _muridCol(kelasId).doc(muridId).delete();
  }

  /// Update banyak murid sekaligus (dipakai saat import CSV atau kalkulasi SAW).
  Future<void> batchUpsertMurid(String kelasId, List<Murid> muridList) async {
    final batch = _db.batch();
    for (final murid in muridList) {
      batch.set(_muridCol(kelasId).doc(murid.id), murid.toJson());
    }
    await batch.commit();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Konversi [Kelas] ke Map untuk Firestore.
  /// Murid TIDAK disertakan — tersimpan di subcollection.
  Map<String, dynamic> _kelasToFirestore(Kelas kelas) {
    final json = kelas.toJson();
    // Hapus muridList dari dokumen induk (ada di subcollection)
    json.remove('muridList');
    // Tambah timestamp
    json['updatedAt'] = FieldValue.serverTimestamp();
    return json;
  }
}
