// ─── Kriteria ────────────────────────────────────────────────────────────────

enum JenisKriteria { benefit, cost }

class Kriteria {
  final String id;
  String nama;
  JenisKriteria jenis;
  double bobot; // hasil AHP, 0.0 sebelum dihitung

  Kriteria({
    required this.id,
    required this.nama,
    required this.jenis,
    this.bobot = 0.0,
  });

  Kriteria copyWith({String? nama, JenisKriteria? jenis, double? bobot}) {
    return Kriteria(
      id: id,
      nama: nama ?? this.nama,
      jenis: jenis ?? this.jenis,
      bobot: bobot ?? this.bobot,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'jenis': jenis.name,
    'bobot': bobot,
  };

  factory Kriteria.fromJson(Map<String, dynamic> json) => Kriteria(
    id: json['id'],
    nama: json['nama'],
    jenis: JenisKriteria.values.firstWhere((e) => e.name == json['jenis']),
    bobot: (json['bobot'] as num).toDouble(),
  );
}

// ─── Nilai Murid per Kriteria ─────────────────────────────────────────────────

class NilaiKriteria {
  final String kriteriaId;
  double nilai;

  NilaiKriteria({required this.kriteriaId, required this.nilai});

  Map<String, dynamic> toJson() => {'kriteriaId': kriteriaId, 'nilai': nilai};

  factory NilaiKriteria.fromJson(Map<String, dynamic> json) => NilaiKriteria(
    kriteriaId: json['kriteriaId'],
    nilai: (json['nilai'] as num).toDouble(),
  );
}

// ─── Murid ────────────────────────────────────────────────────────────────────

class Murid {
  final String id;
  String nama;
  List<NilaiKriteria> nilaiList;
  double? skorFinal; // null sebelum kalkulasi

  Murid({
    required this.id,
    required this.nama,
    required this.nilaiList,
    this.skorFinal,
  });

  /// Ambil nilai untuk kriteria tertentu
  double getNilai(String kriteriaId) {
    final found = nilaiList.where((n) => n.kriteriaId == kriteriaId);
    return found.isNotEmpty ? found.first.nilai : 0.0;
  }

  Murid copyWith({String? nama, List<NilaiKriteria>? nilaiList, double? skorFinal}) {
    return Murid(
      id: id,
      nama: nama ?? this.nama,
      nilaiList: nilaiList ?? this.nilaiList,
      skorFinal: skorFinal ?? this.skorFinal,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'nilaiList': nilaiList.map((n) => n.toJson()).toList(),
    'skorFinal': skorFinal,
  };

  factory Murid.fromJson(Map<String, dynamic> json) => Murid(
    id: json['id'],
    nama: json['nama'],
    nilaiList: (json['nilaiList'] as List)
        .map((n) => NilaiKriteria.fromJson(n))
        .toList(),
    skorFinal: json['skorFinal'] != null
        ? (json['skorFinal'] as num).toDouble()
        : null,
  );
}

// ─── Kelas ────────────────────────────────────────────────────────────────────

class Kelas {
  final String id;
  String nama;
  List<Kriteria> kriteria;
  List<Murid> muridList;
  bool sudahKalkulasi;

  // Matriks AHP [n x n] — disimpan sebagai flat list row-major
  List<List<double>> matriksAHP;

  Kelas({
    required this.id,
    required this.nama,
    required this.kriteria,
    required this.muridList,
    this.sudahKalkulasi = false,
    List<List<double>>? matriksAHP,
  }) : matriksAHP = matriksAHP ?? [];

  int get jumlahSiswa => muridList.length;
  int get jumlahKriteria => kriteria.length;

  Kelas copyWith({
    String? nama,
    List<Kriteria>? kriteria,
    List<Murid>? muridList,
    bool? sudahKalkulasi,
    List<List<double>>? matriksAHP,
  }) {
    return Kelas(
      id: id,
      nama: nama ?? this.nama,
      kriteria: kriteria ?? this.kriteria,
      muridList: muridList ?? this.muridList,
      sudahKalkulasi: sudahKalkulasi ?? this.sudahKalkulasi,
      matriksAHP: matriksAHP ?? this.matriksAHP,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'kriteria': kriteria.map((k) => k.toJson()).toList(),
    'muridList': muridList.map((m) => m.toJson()).toList(),
    'sudahKalkulasi': sudahKalkulasi,
    'matriksAHP': matriksAHP,
  };

  factory Kelas.fromJson(Map<String, dynamic> json) => Kelas(
    id: json['id'],
    nama: json['nama'],
    kriteria: (json['kriteria'] as List).map((k) => Kriteria.fromJson(k)).toList(),
    muridList: (json['muridList'] as List).map((m) => Murid.fromJson(m)).toList(),
    sudahKalkulasi: json['sudahKalkulasi'] ?? false,
    matriksAHP: json['matriksAHP'] != null
        ? (json['matriksAHP'] as List)
            .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
            .toList()
        : [],
  );
}
