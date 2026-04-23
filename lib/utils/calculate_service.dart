import '../models/models.dart';
import 'dart:math';

/// Hasil kalkulasi AHP
class HasilAHP {
  final List<double> bobot;       // bobot per kriteria (sum = 1)
  final double lambdaMax;
  final double ci;                // Consistency Index
  final double cr;                // Consistency Ratio
  final bool konsisten;           // CR <= 0.10

  const HasilAHP({
    required this.bobot,
    required this.lambdaMax,
    required this.ci,
    required this.cr,
    required this.konsisten,
  });
}

/// Hasil kalkulasi SAW
class HasilSAW {
  final List<Murid> muridTerurut; // diurutkan dari skor tertinggi
  final Map<String, double> skorMap; // muridId -> skor

  const HasilSAW({required this.muridTerurut, required this.skorMap});
}

class KalkulasiService {
  // Random Index Saaty (n = 1..10)
  static const List<double> _ri = [0, 0, 0.58, 0.90, 1.12, 1.24, 1.32, 1.41, 1.45, 1.49];

  // ─── AHP ────────────────────────────────────────────────────────────────────

  /// Hitung bobot + CR dari matriks perbandingan berpasangan [n x n]
  static HasilAHP hitungAHP(List<List<double>> matriks) {
    final n = matriks.length;
    assert(n >= 2, 'Minimal 2 kriteria');

    // 1. Jumlah tiap kolom
    final sumKolom = List.filled(n, 0.0);
    for (int j = 0; j < n; j++) {
      for (int i = 0; i < n; i++) {
        sumKolom[j] += matriks[i][j];
      }
    }

    // 2. Normalisasi & hitung bobot (rata-rata baris)
    final normalisasi = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        normalisasi[i][j] = matriks[i][j] / sumKolom[j];
      }
    }

    final bobot = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      double sum = 0;
      for (int j = 0; j < n; j++) {
        sum += normalisasi[i][j];
      }
      bobot[i] = sum / n;
    }

    // 3. λmax
    double lambdaMax = 0;
    for (int j = 0; j < n; j++) {
      lambdaMax += sumKolom[j] * bobot[j];
    }

    // 4. CI & CR
    final ci = (lambdaMax - n) / (n - 1);
    final riVal = n <= _ri.length ? _ri[n - 1] : 1.49;
    final cr = riVal == 0 ? 0.0 : ci / riVal;

    return HasilAHP(
      bobot: bobot,
      lambdaMax: lambdaMax,
      ci: ci,
      cr: cr,
      konsisten: cr <= 0.10,
    );
  }

  /// Buat matriks awal (semua 1.0 = sama penting)
  static List<List<double>> matriksAwal(int n) {
    return List.generate(n, (i) => List.generate(n, (j) => 1.0));
  }

  /// Set nilai matriks secara resiprokal: M[i][j] = val, M[j][i] = 1/val
  static void setNilaiMatriks(List<List<double>> matriks, int i, int j, double val) {
    matriks[i][j] = val;
    matriks[j][i] = 1 / val;
  }

  // ─── SAW ────────────────────────────────────────────────────────────────────

  /// Hitung skor SAW untuk semua murid berdasarkan kriteria + bobot
  static HasilSAW hitungSAW(List<Murid> muridList, List<Kriteria> kriteria) {
    if (muridList.isEmpty || kriteria.isEmpty) {
      return HasilSAW(muridTerurut: muridList, skorMap: {});
    }

    // 1. Kumpulkan nilai per kriteria
    final nilaiPerKriteria = <String, List<double>>{};
    for (final k in kriteria) {
      nilaiPerKriteria[k.id] = muridList.map((m) => m.getNilai(k.id)).toList();
    }

    // 2. Hitung min/max per kriteria untuk normalisasi
    final maxNilai = <String, double>{};
    final minNilai = <String, double>{};
    for (final k in kriteria) {
      final vals = nilaiPerKriteria[k.id]!;
      maxNilai[k.id] = vals.reduce(max);
      minNilai[k.id] = vals.reduce(min);
    }

    // 3. Normalisasi & hitung skor
    final skorMap = <String, double>{};
    for (int idx = 0; idx < muridList.length; idx++) {
      final murid = muridList[idx];
      double skor = 0;

      for (final k in kriteria) {
        final xij = murid.getNilai(k.id);
        final maxV = maxNilai[k.id]!;
        final minV = minNilai[k.id]!;

        double rij;
        if (k.jenis == JenisKriteria.benefit) {
          rij = maxV == 0 ? 0 : xij / maxV;
        } else {
          // cost: min / xij
          rij = xij == 0 ? 0 : minV / xij;
        }

        skor += k.bobot * rij;
      }

      skorMap[murid.id] = double.parse((skor * 100).toStringAsFixed(2));
    }

    // 4. Update murid dengan skor & urutkan
    final muridDenganSkor = muridList
        .map((m) => m.copyWith(skorFinal: skorMap[m.id]))
        .toList();
    muridDenganSkor.sort((a, b) => (b.skorFinal ?? 0).compareTo(a.skorFinal ?? 0));

    return HasilSAW(muridTerurut: muridDenganSkor, skorMap: skorMap);
  }

  // ─── Skala AHP ───────────────────────────────────────────────────────────────

  static const Map<int, String> labelSkala = {
    1: 'Sama penting',
    2: 'Antara sama & sedikit lebih penting',
    3: 'Sedikit lebih penting',
    4: 'Antara sedikit & cukup lebih penting',
    5: 'Cukup lebih penting',
    6: 'Antara cukup & sangat lebih penting',
    7: 'Sangat lebih penting',
    8: 'Antara sangat & mutlak lebih penting',
    9: 'Mutlak lebih penting',
  };

  static String getLabel(double val) {
    if (val < 1) {
      // resiprokal
      final inv = 1 / val;
      return labelSkala[inv.round()] ?? val.toStringAsFixed(2);
    }
    return labelSkala[val.round()] ?? val.toStringAsFixed(2);
  }
}
