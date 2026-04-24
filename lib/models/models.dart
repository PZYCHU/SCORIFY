// ─── Enums ────────────────────────────────────────────────────────────────────

enum JenisKriteria {
  performa, // diinput saat KBM (counter, toggle, stopwatch)
  hasil,    // diinput setelah koreksi, punya sesi (nilai tugas, UTS, UAS)
  derived,  // otomatis dihitung sistem (frekuensi ngulang = count attempt > 1)
}

enum InputType {
  counter,   // tombol +, cocok untuk keaktifan
  number,    // input angka manual, cocok untuk nilai tugas
  stopwatch, // durasi pengerjaan
  toggle,    // ya/tidak, cocok untuk sikap
}

enum ArahKriteria {
  benefit, // semakin besar semakin baik
  cost,    // semakin besar semakin buruk
}

// ─── Kriteria ─────────────────────────────────────────────────────────────────

class Kriteria {
  final String id;
  String nama;
  JenisKriteria jenis;
  InputType? inputType; // null jika derived (tidak perlu input)
  ArahKriteria arah;
  double bobot; // hasil AHP, 0.0 sebelum dihitung
  bool perSesi; // true jika butuh sesi (hanya jenis: hasil)

  Kriteria({
    required this.id,
    required this.nama,
    required this.jenis,
    this.inputType,
    this.arah = ArahKriteria.benefit,
    this.bobot = 0.0,
    this.perSesi = false,
  });

  Kriteria copyWith({
    String? nama,
    JenisKriteria? jenis,
    InputType? inputType,
    ArahKriteria? arah,
    double? bobot,
    bool? perSesi,
  }) {
    return Kriteria(
      id: id,
      nama: nama ?? this.nama,
      jenis: jenis ?? this.jenis,
      inputType: inputType ?? this.inputType,
      arah: arah ?? this.arah,
      bobot: bobot ?? this.bobot,
      perSesi: perSesi ?? this.perSesi,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'jenis': jenis.name,
    'inputType': inputType?.name,
    'arah': arah.name,
    'bobot': bobot,
    'perSesi': perSesi,
  };

  factory Kriteria.fromJson(Map<String, dynamic> json) => Kriteria(
    id: json['id'],
    nama: json['nama'],
    jenis: JenisKriteria.values.firstWhere((e) => e.name == json['jenis']),
    inputType: json['inputType'] != null
        ? InputType.values.firstWhere((e) => e.name == json['inputType'])
        : null,
    arah: ArahKriteria.values.firstWhere(
      (e) => e.name == (json['arah'] ?? 'benefit'),
    ),
    bobot: (json['bobot'] as num).toDouble(),
    perSesi: json['perSesi'] ?? false,
  );
}

// ─── Sesi ─────────────────────────────────────────────────────────────────────
// Hanya dipakai untuk kriteria jenis: hasil

class Sesi {
  final String id;
  final String kriteriaId;
  String nama;
  int urutan;
  DateTime tanggal;

  Sesi({
    required this.id,
    required this.kriteriaId,
    required this.nama,
    required this.urutan,
    required this.tanggal,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kriteriaId': kriteriaId,
    'nama': nama,
    'urutan': urutan,
    'tanggal': tanggal.toIso8601String(),
  };

  factory Sesi.fromJson(Map<String, dynamic> json) => Sesi(
    id: json['id'],
    kriteriaId: json['kriteriaId'],
    nama: json['nama'],
    urutan: json['urutan'],
    tanggal: DateTime.parse(json['tanggal']),
  );
}

// ─── Nilai ────────────────────────────────────────────────────────────────────

class Nilai {
  final String id;
  final String siswaId;
  final String kriteriaId;
  String? sesiId;   // null jika kriteria jenis: performa
  double nilai;
  int attempt;      // 1 = pertama kali, >1 = ngulang
  DateTime tanggal;

  Nilai({
    required this.id,
    required this.siswaId,
    required this.kriteriaId,
    this.sesiId,
    required this.nilai,
    this.attempt = 1,
    required this.tanggal,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'siswaId': siswaId,
    'kriteriaId': kriteriaId,
    'sesiId': sesiId,
    'nilai': nilai,
    'attempt': attempt,
    'tanggal': tanggal.toIso8601String(),
  };

  factory Nilai.fromJson(Map<String, dynamic> json) => Nilai(
    id: json['id'],
    siswaId: json['siswaId'],
    kriteriaId: json['kriteriaId'],
    sesiId: json['sesiId'],
    nilai: (json['nilai'] as num).toDouble(),
    attempt: json['attempt'] ?? 1,
    tanggal: DateTime.parse(json['tanggal']),
  );
}

// ─── Murid ────────────────────────────────────────────────────────────────────

class Murid {
  final String id;
  String nama;
  List<Nilai> nilaiList;
  double? skorFinal;

  Murid({
    required this.id,
    required this.nama,
    required this.nilaiList,
    this.skorFinal,
  });

  /// Ambil semua nilai untuk kriteria tertentu
  List<Nilai> getNilaiByKriteria(String kriteriaId) =>
      nilaiList.where((n) => n.kriteriaId == kriteriaId).toList();

  /// Ambil nilai terbaik (attempt tertinggi) untuk kriteria + sesi tertentu
  Nilai? getNilaiBySesi(String kriteriaId, String sesiId) {
    final filtered = nilaiList.where(
      (n) => n.kriteriaId == kriteriaId && n.sesiId == sesiId,
    ).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.attempt.compareTo(a.attempt));
    return filtered.first;
  }

  /// Hitung frekuensi ngulang untuk kriteria derived
  int getFrekuensiNgulang(String kriteriaId) {
    return nilaiList
        .where((n) => n.kriteriaId == kriteriaId && n.attempt > 1)
        .length;
  }

  Murid copyWith({
    String? nama,
    List<Nilai>? nilaiList,
    double? skorFinal,
  }) {
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
        .map((n) => Nilai.fromJson(n))
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
  List<Sesi> sesiList;
  bool sudahKalkulasi;
  List<List<double>> matriksAHP;

  Kelas({
    required this.id,
    required this.nama,
    required this.kriteria,
    required this.muridList,
    List<Sesi>? sesiList,
    this.sudahKalkulasi = false,
    List<List<double>>? matriksAHP,
  }) : sesiList = sesiList ?? [],
       matriksAHP = matriksAHP ?? [];

  int get jumlahSiswa => muridList.length;
  int get jumlahKriteria => kriteria.length;

  /// Ambil sesi untuk kriteria tertentu, urut by urutan
  List<Sesi> getSesiByKriteria(String kriteriaId) {
    final list = sesiList.where((s) => s.kriteriaId == kriteriaId).toList();
    list.sort((a, b) => a.urutan.compareTo(b.urutan));
    return list;
  }

  Kelas copyWith({
    String? nama,
    List<Kriteria>? kriteria,
    List<Murid>? muridList,
    List<Sesi>? sesiList,
    bool? sudahKalkulasi,
    List<List<double>>? matriksAHP,
  }) {
    return Kelas(
      id: id,
      nama: nama ?? this.nama,
      kriteria: kriteria ?? this.kriteria,
      muridList: muridList ?? this.muridList,
      sesiList: sesiList ?? this.sesiList,
      sudahKalkulasi: sudahKalkulasi ?? this.sudahKalkulasi,
      matriksAHP: matriksAHP ?? this.matriksAHP,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'kriteria': kriteria.map((k) => k.toJson()).toList(),
    'muridList': muridList.map((m) => m.toJson()).toList(),
    'sesiList': sesiList.map((s) => s.toJson()).toList(),
    'sudahKalkulasi': sudahKalkulasi,
    'matriksAHP': matriksAHP,
  };

  factory Kelas.fromJson(Map<String, dynamic> json) => Kelas(
    id: json['id'],
    nama: json['nama'],
    kriteria: (json['kriteria'] as List)
        .map((k) => Kriteria.fromJson(k))
        .toList(),
    muridList: (json['muridList'] as List)
        .map((m) => Murid.fromJson(m))
        .toList(),
    sesiList: json['sesiList'] != null
        ? (json['sesiList'] as List)
            .map((s) => Sesi.fromJson(s))
            .toList()
        : [],
    sudahKalkulasi: json['sudahKalkulasi'] ?? false,
    matriksAHP: json['matriksAHP'] != null
        ? (json['matriksAHP'] as List)
            .map((row) => (row as List)
                .map((v) => (v as num).toDouble())
                .toList())
            .toList()
        : [],
  );
}