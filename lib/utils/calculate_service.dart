import '../models/models.dart';
import 'dart:math';

/// Saran perbaikan nilai untuk perbandingan yang inkonsisten
class SaranInkonsistensi {
  final int i;
  final int j;
  final double nilaiSaatIni;
  final int nilaiSaran;
  final double nilaiMatriksSaran;
  final bool lebihPentingA;
  final double deviasi;
  final double crSetelahGanti;

  const SaranInkonsistensi({
    required this.i,
    required this.j,
    required this.nilaiSaatIni,
    required this.nilaiSaran,
    required this.nilaiMatriksSaran,
    required this.lebihPentingA,
    required this.deviasi,
    required this.crSetelahGanti,
  });
}

/// Hasil kalkulasi AHP
class HasilAHP {
  final List<double> bobot;
  final double lambdaMax;
  final double ci;
  final double cr;
  final bool konsisten;
  final List<SaranInkonsistensi> saranList;

  const HasilAHP({
    required this.bobot,
    required this.lambdaMax,
    required this.ci,
    required this.cr,
    required this.konsisten,
    this.saranList = const [],
  });
}

/// Hasil kalkulasi SAW
class HasilSAW {
  final List<Murid> muridTerurut;
  final Map<String, double> skorMap;
  final Map<String, Map<String, double>>? rMatrix;

  const HasilSAW({
    required this.muridTerurut,
    required this.skorMap,
    this.rMatrix,
  });
}

class KalkulasiService {
  static const List<double> _ri = [
    0,
    0,
    0.58,
    0.90,
    1.12,
    1.24,
    1.32,
    1.41,
    1.45,
    1.49,
  ];

  // ─── AHP ──────────────────────────────────────────────────────────────────

  static HasilAHP hitungAHP(List<List<double>> matriks) {
    final base = _hitungAHPInternal(matriks);
    if (base.konsisten) {
      return base;
    }

    // Jika inkonsisten, cari saran perbaikan sel
    final saran = cariSaranInkonsistensi(matriks, base.bobot);
    return HasilAHP(
      bobot: base.bobot,
      lambdaMax: base.lambdaMax,
      ci: base.ci,
      cr: base.cr,
      konsisten: base.konsisten,
      saranList: saran,
    );
  }

  static HasilAHP _hitungAHPInternal(List<List<double>> matriks) {
    final n = matriks.length;
    assert(n >= 2, 'Minimal 2 kriteria');

    final sumKolom = List.filled(n, 0.0);
    for (int j = 0; j < n; j++) {
      for (int i = 0; i < n; i++) {
        sumKolom[j] += matriks[i][j];
      }
    }

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

    double lambdaMax = 0;
    for (int j = 0; j < n; j++) {
      lambdaMax += sumKolom[j] * bobot[j];
    }

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

  static List<SaranInkonsistensi> cariSaranInkonsistensi(
    List<List<double>> matriks,
    List<double> bobot,
  ) {
    final n = matriks.length;
    final List<SaranInkonsistensi> hasil = [];

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final wI = bobot[i];
        final wJ = bobot[j];
        if (wJ <= 0) continue;

        final rasioIdeal = wI / wJ;
        int saatySaran = 1;
        double nilaiMatriksSaran = 1.0;
        bool lebihPentingA = true;

        if (rasioIdeal >= 1.0) {
          int s = rasioIdeal.round().clamp(1, 9);
          if (s > 1 && s.isEven) {
            s = (rasioIdeal - s >= 0) ? (s + 1).clamp(1, 9) : (s - 1).clamp(1, 9);
          }
          saatySaran = s;
          nilaiMatriksSaran = saatySaran.toDouble();
          lebihPentingA = true;
        } else {
          final kebalikan = wJ / wI;
          int s = kebalikan.round().clamp(1, 9);
          if (s > 1 && s.isEven) {
            s = (kebalikan - s >= 0) ? (s + 1).clamp(1, 9) : (s - 1).clamp(1, 9);
          }
          saatySaran = s;
          nilaiMatriksSaran = 1.0 / saatySaran;
          lebihPentingA = false;
        }

        final valSaatIni = matriks[i][j];
        if ((valSaatIni - nilaiMatriksSaran).abs() > 0.05) {
          final matriksTest = matriks
              .map((row) => List<double>.from(row))
              .toList();
          setNilaiMatriks(matriksTest, i, j, nilaiMatriksSaran);
          final testHasil = _hitungAHPInternal(matriksTest);

          final deviasi = (valSaatIni - rasioIdeal).abs();
          hasil.add(
            SaranInkonsistensi(
              i: i,
              j: j,
              nilaiSaatIni: valSaatIni,
              nilaiSaran: saatySaran,
              nilaiMatriksSaran: nilaiMatriksSaran,
              lebihPentingA: lebihPentingA,
              deviasi: deviasi,
              crSetelahGanti: testHasil.cr,
            ),
          );
        }
      }
    }

    // Urutkan: yang paling menurunkan CR lebih dulu
    hasil.sort((a, b) => a.crSetelahGanti.compareTo(b.crSetelahGanti));
    return hasil;
  }

  static List<List<double>> matriksAwal(int n) {
    return List.generate(n, (i) => List.generate(n, (j) => 1.0));
  }

  static void setNilaiMatriks(
    List<List<double>> matriks,
    int i,
    int j,
    double val,
  ) {
    matriks[i][j] = val;
    matriks[j][i] = 1 / val;
  }

  // ─── SAW ──────────────────────────────────────────────────────────────────

  static HasilSAW hitungSAW(List<Murid> muridList, List<Kriteria> kriteria) {
    if (muridList.isEmpty || kriteria.isEmpty) {
      return HasilSAW(muridTerurut: muridList, skorMap: {});
    }

    // Matriks normalisasi r_ij: [muridId][kriteriaId] -> r_ij
    final rMatrix = <String, Map<String, double>>{};

    for (final k in kriteria) {
      final isCost = k.arah == ArahKriteria.cost ||
          k.nama.toLowerCase().contains('langgar') ||
          k.nama.toLowerCase().contains('disiplin');

      final isCounter = k.jenis == JenisKriteria.byProcess &&
          (k.inputType == InputType.counter ||
              k.nama.toLowerCase().contains('aktif') ||
              isCost);

      if (isCounter) {
        // 🔵 Model 2: Counter / Keaktifan / Pelanggaran (2 indikator: Nilai Poin Agregasi dan Frekuensi)
        final poinList = <double>[];
        final frekList = <double>[];

        for (final m in muridList) {
          final entries = m.getNilaiByKriteria(k.id);
          final frek = entries.where((n) => n.nilai > 0).length.toDouble();
          double poin = 0.0;
          if (entries.isNotEmpty) {
            if (k.aggregationRule == AggregationRule.average) {
              final active = entries.where((n) => n.nilai > 0).toList();
              poin = active.isEmpty
                  ? 0.0
                  : active.fold(0.0, (sum, n) => sum + n.nilai) / active.length;
            } else if (k.aggregationRule == AggregationRule.min) {
              final active = entries.where((n) => n.nilai > 0).toList();
              poin = active.isEmpty
                  ? 0.0
                  : active.map((n) => n.nilai).reduce(min);
            } else {
              poin = entries.map((n) => n.nilai).reduce(max);
            }
          }
          poinList.add(poin);
          frekList.add(frek);
        }

        final maxP = poinList.reduce(max);
        final minP = poinList.reduce(min);
        final maxF = frekList.reduce(max);
        final minF = frekList.reduce(min);

        for (int i = 0; i < muridList.length; i++) {
          final mId = muridList[i].id;
          final p = poinList[i];
          final f = frekList[i];

          double rP;
          double rF;

          if (isCost) {
            // Sifat COST (Pelanggaran / Deduksi): Semakin kecil poin & frekuensi, semakin tinggi skornya (bebas deduksi)
            rP = (maxP == minP) ? 1.0 : (maxP - p) / (maxP - minP);
            rF = (maxF == minF) ? 1.0 : (maxF - f) / (maxF - minF);
          } else {
            // Sifat BENEFIT: Semakin besar poin & frekuensi keaktifan, semakin tinggi skornya
            rP = maxP == 0 ? 0.0 : (maxP == minP ? 1.0 : p / maxP);
            rF = maxF == 0 ? 0.0 : (maxF == minF ? 1.0 : f / maxF);
          }

          final rij = ((rP + rF) / 2.0).clamp(0.0, 1.0);
          rMatrix.putIfAbsent(mId, () => {})[k.id] = rij;
        }
      } else if (k.jenis == JenisKriteria.byProduct) {
        // 🔴 Model 3: Kriteria Hasil / Product (Nilai Hasil + Penalti Attempt/Remedial)
        final scoreList = <double>[];
        final attemptList = <double>[];

        for (final m in muridList) {
          final entries = m.getNilaiByKriteria(k.id);
          if (entries.isEmpty) {
            scoreList.add(0.0);
            attemptList.add(1.0);
          } else {
            // Kelompokkan nilai per sesi (hanya sesi yang valid, abaikan null jika ada sesi)
            final Map<String, List<Nilai>> perSesi = {};
            for (final n in entries) {
              if (n.sesiId != null && n.sesiId!.isNotEmpty) {
                perSesi.putIfAbsent(n.sesiId!, () => []).add(n);
              }
            }
            if (perSesi.isEmpty) {
              for (final n in entries) {
                perSesi.putIfAbsent(n.sesiId ?? 'default', () => []).add(n);
              }
            }

            double sumSesiScore = 0.0;
            double sumSesiAttempt = 0.0;

            for (final sesiEntries in perSesi.values) {
              if (k.aggregationRule == AggregationRule.average) {
                final avgScore = sesiEntries.fold(0.0, (s, n) => s + n.nilai) /
                    sesiEntries.length;
                sumSesiScore += avgScore;
              } else if (k.aggregationRule == AggregationRule.min) {
                final minScore =
                    sesiEntries.map((e) => e.nilai).reduce(min);
                sumSesiScore += minScore;
              } else {
                // Max
                final maxScore =
                    sesiEntries.map((e) => e.nilai).reduce(max);
                sumSesiScore += maxScore;
              }
              final maxAtt = sesiEntries.map((e) => e.attempt).reduce(max);
              sumSesiAttempt += maxAtt.clamp(1, 99).toDouble();
            }

            final count = perSesi.length;
            scoreList.add(count > 0 ? sumSesiScore / count : 0.0);
            attemptList.add(count > 0 ? sumSesiAttempt / count : 1.0);
          }
        }

        final maxScore = scoreList.reduce(max);
        final minScore = scoreList.reduce(min);
        final minAttempt = attemptList.reduce(min);
        final maxAttempt = attemptList.reduce(max);

        for (int i = 0; i < muridList.length; i++) {
          final mId = muridList[i].id;
          final s = scoreList[i];
          final a = attemptList[i];

          // 1. Poin Nilai Hasil: BENEFIT (r_ij = x / max)
          double rScore;
          if (maxScore == minScore) {
            rScore = 1.0;
          } else if (!isCost) {
            rScore = maxScore == 0 ? 0.0 : s / maxScore;
          } else {
            rScore = (maxScore == minScore) ? 1.0 : (maxScore - s) / (maxScore - minScore);
          }

          // 2. Jumlah Attempt / Percobaan (Otomatis COST: min(x) / x)
          double rAttempt = 1.0;
          if (maxAttempt == minAttempt) {
            rAttempt = 1.0;
          } else {
            // COST: Semakin sedikit percobaan untuk selesai, semakin bagus (r_ij = min / x)
            rAttempt = a == 0 ? 1.0 : (minAttempt / a).clamp(0.0, 1.0);
          }

          // Nilai normalisasi preferensi kriteria hasil gabungan (r_score * r_attempt)
          final rij = (rScore * rAttempt).clamp(0.0, 1.0);
          rMatrix.putIfAbsent(mId, () => {})[k.id] = rij;
        }
      } else {
        // 🟢 Model 1: Presensi / By Process Standar
        final valList = muridList.map((m) => _nilaiRingkasan(m, k)).toList();
        final maxV = valList.reduce(max);
        final minV = valList.reduce(min);

        for (int i = 0; i < muridList.length; i++) {
          final mId = muridList[i].id;
          final x = valList[i];

          double rij;
          if (maxV == minV) {
            rij = 1.0;
          } else if (!isCost) {
            rij = maxV == 0 ? 0.0 : x / maxV;
          } else {
            // COST: Linear min-max (semakin kecil x semakin tinggi preferensi nilainya)
            rij = (maxV - x) / (maxV - minV);
          }

          rMatrix.putIfAbsent(mId, () => {})[k.id] = rij.clamp(0.0, 1.0);
        }
      }
    }

    // 3. Hitung preferensi akhir SAW: V_i = sum(w_j * r_ij)
    final skorMap = <String, double>{};
    for (final murid in muridList) {
      double skor = 0;
      for (final k in kriteria) {
        final rij = rMatrix[murid.id]?[k.id] ?? 0.0;
        skor += k.bobot * rij;
      }
      skorMap[murid.id] = double.parse((skor * 100).toStringAsFixed(2));
    }

    // 4. Update murid dengan skor & urutkan
    final muridDenganSkor = muridList
        .map((m) => m.copyWith(skorFinal: skorMap[m.id]))
        .toList();
    muridDenganSkor.sort(
      (a, b) => (b.skorFinal ?? 0).compareTo(a.skorFinal ?? 0),
    );

    return HasilSAW(
      muridTerurut: muridDenganSkor,
      skorMap: skorMap,
      rMatrix: rMatrix,
    );
  }

  /// Hitung nilai ringkasan satu murid untuk satu kriteria:
  /// - byProduct: nilai per sesi sesuai aggregationRule (max/average/min), dirata-ratakan
  /// - byProcess (keaktifan): sesuai aggregationRule (max/average/min)
  /// - byProcess (attendance): SUM catatan kehadiran
  /// - byProcess (number / default): rata-rata / aturan agregasi
  static double _nilaiRingkasan(Murid murid, Kriteria k) {
    final semuaNilai = murid.getNilaiByKriteria(k.id);
    if (semuaNilai.isEmpty) return 0;

    final isKeaktifan = k.jenis == JenisKriteria.byProcess &&
        (k.inputType == InputType.counter ||
            k.nama.toLowerCase().contains('aktif'));

    if (isKeaktifan) {
      if (k.aggregationRule == AggregationRule.average) {
        final active = semuaNilai.where((n) => n.nilai > 0).toList();
        return active.isEmpty
            ? 0.0
            : active.fold(0.0, (sum, n) => sum + n.nilai) / active.length;
      } else if (k.aggregationRule == AggregationRule.min) {
        final active = semuaNilai.where((n) => n.nilai > 0).toList();
        return active.isEmpty
            ? 0.0
            : active.map((n) => n.nilai).reduce(min);
      } else {
        return semuaNilai.map((n) => n.nilai).reduce(max);
      }
    }

    if (k.jenis == JenisKriteria.byProduct) {
      final Map<String, List<Nilai>> perSesi = {};
      for (final n in semuaNilai) {
        if (n.sesiId != null && n.sesiId!.isNotEmpty) {
          perSesi.putIfAbsent(n.sesiId!, () => []).add(n);
        }
      }
      if (perSesi.isEmpty) {
        for (final n in semuaNilai) {
          perSesi.putIfAbsent(n.sesiId ?? 'default', () => []).add(n);
        }
      }
      if (perSesi.isEmpty) return 0;

      double totalSesi = 0.0;
      for (final list in perSesi.values) {
        if (k.aggregationRule == AggregationRule.average) {
          totalSesi += list.fold(0.0, (s, n) => s + n.nilai) / list.length;
        } else if (k.aggregationRule == AggregationRule.min) {
          totalSesi += list.map((e) => e.nilai).reduce(min);
        } else {
          totalSesi += list.map((e) => e.nilai).reduce(max);
        }
      }
      return totalSesi / perSesi.length;
    }

    // byProcess (attendance): SUM semua catatan kehadiran
    if (k.jenis == JenisKriteria.byProcess &&
        k.inputType == InputType.attendance) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai);
    }

    // Default: evaluasi sesuai aturan agregasi
    if (k.aggregationRule == AggregationRule.average) {
      return semuaNilai.fold(0.0, (sum, n) => sum + n.nilai) / semuaNilai.length;
    } else if (k.aggregationRule == AggregationRule.min) {
      return semuaNilai.map((n) => n.nilai).reduce(min);
    }
    return semuaNilai.map((n) => n.nilai).reduce(max);
  }

  // ─── Skala AHP ────────────────────────────────────────────────────────────

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
      final inv = 1 / val;
      return labelSkala[inv.round()] ?? val.toStringAsFixed(2);
    }
    return labelSkala[val.round()] ?? val.toStringAsFixed(2);
  }
}
