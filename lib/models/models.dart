// ─── Enums ────────────────────────────────────────────────────────────────────

enum JenisKriteria {
  byProcess, // diinput saat proses KBM berlangsung (Presensi, Keaktifan)
  byProduct; // diinput di akhir unit pembelajaran (Tugas, UTS, UAS)

  String get label => switch (this) {
    JenisKriteria.byProcess => 'Proses KBM',
    JenisKriteria.byProduct => 'Hasil / Produk',
  };
}

enum AggregationRule {
  max,      // Nilai Tertinggi
  average,  // Rata-rata Nilai
  min;      // Nilai Terendah

  String get label => switch (this) {
    AggregationRule.max => 'Nilai Tertinggi (Max)',
    AggregationRule.average => 'Rata-rata (Average)',
    AggregationRule.min => 'Nilai Terendah (Min)',
  };
}

enum InputType {
  counter,    // poin tambahan / akumulasi (+), cocok untuk keaktifan
  attendance, // presensi / kehadiran (dibatasi maks 100)
  number,     // input angka manual, cocok untuk nilai tugas / ujian
}

enum ArahKriteria {
  benefit, // semakin besar semakin baik (Menguntungkan)
  cost;    // semakin besar semakin buruk (Merugikan)

  String get label => switch (this) {
    ArahKriteria.benefit => 'Menguntungkan (Benefit)',
    ArahKriteria.cost => 'Merugikan (Cost)',
  };
}

// ─── Sub-Kriteria (Skala / Opsi Nilai Terstandar) ──────────────────────────────

class SubKriteria {
  final String id;
  String nama;
  double nilai;

  SubKriteria({
    required this.id,
    required this.nama,
    required this.nilai,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'nilai': nilai,
  };

  factory SubKriteria.fromJson(Map<String, dynamic> json) => SubKriteria(
    id: json['id']?.toString() ?? '',
    nama: json['nama']?.toString() ?? '',
    nilai: (json['nilai'] as num?)?.toDouble() ?? 0.0,
  );

  SubKriteria copyWith({String? id, String? nama, double? nilai}) => SubKriteria(
    id: id ?? this.id,
    nama: nama ?? this.nama,
    nilai: nilai ?? this.nilai,
  );
}

// ─── Kriteria ─────────────────────────────────────────────────────────────────

class Kriteria {
  final String id;
  String nama;
  JenisKriteria jenis;
  InputType? inputType; // null jika tidak membutuhkan input type khusus
  ArahKriteria arah;
  double bobot; // hasil AHP, 0.0 sebelum dihitung
  bool perSesi; // true jika kriteria memiliki penilaian berulang / per sesi
  bool isPenaltiPercobaan; // true jika iterasi/percobaan dihitung sebagai Cost (penalti)
  AggregationRule aggregationRule; // aturan agregasi attempt (max / average / min)
  List<SubKriteria>? subKriteria; // opsi pilihan nilai diskrit (cth: Hadir=100, Izin=75)
  List<String> targetKriteriaIds; // backward-compatibility

  bool get isPenilaianBerulang => perSesi;
  set isPenilaianBerulang(bool val) => perSesi = val;

  bool get hasSubKriteria => subKriteria != null && subKriteria!.isNotEmpty;

  static List<SubKriteria> get defaultPresensiSubKriteria => [
    SubKriteria(id: 'hadir', nama: 'Hadir', nilai: 100),
    SubKriteria(id: 'izin', nama: 'Izin', nilai: 75),
    SubKriteria(id: 'sakit', nama: 'Sakit', nilai: 50),
    SubKriteria(id: 'alpha', nama: 'Alpha', nilai: 0),
  ];

  static List<SubKriteria> get defaultLikertSubKriteria => [
    SubKriteria(id: 'sb', nama: 'Sangat Baik', nilai: 100),
    SubKriteria(id: 'b', nama: 'Baik', nilai: 80),
    SubKriteria(id: 'c', nama: 'Cukup', nilai: 60),
    SubKriteria(id: 'k', nama: 'Kurang', nilai: 40),
  ];

  Kriteria({
    required this.id,
    required this.nama,
    required this.jenis,
    this.inputType,
    this.arah = ArahKriteria.benefit,
    this.bobot = 0.0,
    bool perSesi = false,
    bool? isPenilaianBerulang,
    this.isPenaltiPercobaan = false,
    this.aggregationRule = AggregationRule.max,
    this.subKriteria,
    this.targetKriteriaIds = const [],
  }) : perSesi = isPenilaianBerulang ?? perSesi;

  Kriteria copyWith({
    String? nama,
    JenisKriteria? jenis,
    InputType? inputType,
    ArahKriteria? arah,
    double? bobot,
    bool? perSesi,
    bool? isPenilaianBerulang,
    bool? isPenaltiPercobaan,
    AggregationRule? aggregationRule,
    List<SubKriteria>? subKriteria,
    List<String>? targetKriteriaIds,
  }) {
    return Kriteria(
      id: id,
      nama: nama ?? this.nama,
      jenis: jenis ?? this.jenis,
      inputType: inputType ?? this.inputType,
      arah: arah ?? this.arah,
      bobot: bobot ?? this.bobot,
      perSesi: isPenilaianBerulang ?? perSesi ?? this.perSesi,
      isPenaltiPercobaan: isPenaltiPercobaan ?? this.isPenaltiPercobaan,
      aggregationRule: aggregationRule ?? this.aggregationRule,
      subKriteria: subKriteria ?? this.subKriteria,
      targetKriteriaIds: targetKriteriaIds ?? this.targetKriteriaIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'jenis': jenis == JenisKriteria.byProcess ? 'by_process' : 'by_product',
    'inputType': inputType?.name,
    'arah': arah.name,
    'bobot': bobot,
    'perSesi': perSesi,
    'is_penilaian_berulang': perSesi,
    'is_penalti_percobaan': isPenaltiPercobaan,
    'aggregation_rule': aggregationRule.name,
    'sub_kriteria_config': {
      'aggregation_rule': aggregationRule.name,
      'options': subKriteria?.map((s) => s.toJson()).toList(),
    },
    if (subKriteria != null)
      'sub_kriteria': subKriteria!.map((s) => s.toJson()).toList(),
    'targetKriteriaIds': targetKriteriaIds,
  };

  factory Kriteria.fromJson(Map<String, dynamic> json) {
    JenisKriteria parseJenis(dynamic val) {
      final str = val?.toString().toLowerCase();
      if (str == 'by_process' || str == 'byprocess' || str == 'performa') {
        return JenisKriteria.byProcess;
      }
      return JenisKriteria.byProduct;
    }

    AggregationRule parseAggregationRule(dynamic val) {
      final str = val?.toString().toLowerCase();
      if (str == 'average' || str == 'avg') {
        return AggregationRule.average;
      }
      if (str == 'min' || str == 'minimum') {
        return AggregationRule.min;
      }
      return AggregationRule.max;
    }

    final parsedJenis = parseJenis(json['jenis']);

    final subConfig = json['sub_kriteria_config'];
    final rawSubList = json['sub_kriteria'] ??
        (subConfig is Map<String, dynamic> ? subConfig['options'] : null);

    final rawAgg = json['aggregation_rule'] ??
        json['aggregationRule'] ??
        (subConfig is Map<String, dynamic> ? subConfig['aggregation_rule'] : null);

    return Kriteria(
      id: json['id'],
      nama: json['nama'],
      jenis: parsedJenis,
      inputType: json['inputType'] != null
          ? InputType.values.firstWhere(
              (e) => e.name == json['inputType'],
              orElse: () => InputType.number,
            )
          : (parsedJenis == JenisKriteria.byProcess ? InputType.number : null),
      arah: ArahKriteria.values.firstWhere(
        (e) => e.name == (json['arah'] ?? 'benefit'),
        orElse: () => ArahKriteria.benefit,
      ),
      bobot: (json['bobot'] as num?)?.toDouble() ?? 0.0,
      perSesi: json['is_penilaian_berulang'] ??
          json['isPenilaianBerulang'] ??
          json['perSesi'] ??
          (parsedJenis == JenisKriteria.byProduct),
      isPenaltiPercobaan: json['is_penalti_percobaan'] ??
          json['isPenaltiPercobaan'] ??
          (parsedJenis == JenisKriteria.byProduct && (json['is_penilaian_berulang'] ?? json['perSesi'] ?? true)),
      aggregationRule: parseAggregationRule(rawAgg),
      subKriteria: (rawSubList as List<dynamic>?)
          ?.map((e) => SubKriteria.fromJson(e as Map<String, dynamic>))
          .toList(),
      targetKriteriaIds: (json['targetKriteriaIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
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

  Nilai copyWith({
    String? id,
    String? siswaId,
    String? kriteriaId,
    String? sesiId,
    double? nilai,
    int? attempt,
    DateTime? tanggal,
  }) {
    return Nilai(
      id: id ?? this.id,
      siswaId: siswaId ?? this.siswaId,
      kriteriaId: kriteriaId ?? this.kriteriaId,
      sesiId: sesiId ?? this.sesiId,
      nilai: nilai ?? this.nilai,
      attempt: attempt ?? this.attempt,
      tanggal: tanggal ?? this.tanggal,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'siswa_id': siswaId,
    'kriteria_id': kriteriaId,
    'sesi_id': sesiId,
    'score': nilai,
    'attempt': attempt,
    'tanggal': tanggal.toIso8601String(),
  };

  factory Nilai.fromJson(Map<String, dynamic> json) => Nilai(
    id: json['id'] ?? '',
    siswaId: json['siswa_id'] ?? json['siswaId'] ?? '',
    kriteriaId: json['kriteria_id'] ?? json['kriteriaId'] ?? '',
    sesiId: json['sesi_id'] ?? json['sesiId'],
    nilai: ((json['score'] ?? json['nilai']) as num?)?.toDouble() ?? 0.0,
    attempt: json['attempt'] ?? 1,
    tanggal: json['tanggal'] != null
        ? DateTime.tryParse(json['tanggal']) ?? DateTime.now()
        : DateTime.now(),
  );
}

// ─── Murid ────────────────────────────────────────────────────────────────────

class Murid {
  final String id;
  String nama;
  String? nis;          // Nomor Induk Siswa (opsional)
  List<Nilai> nilaiList;
  double? skorFinal;

  Murid({
    required this.id,
    required this.nama,
    this.nis,
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

  /// Hitung frekuensi ngulang (remedial).
  /// Jika targetKriteriaIds disediakan, hanya hitung pengulangan pada kriteria hasil tersebut.
  /// Return: jumlah sesi unik di mana siswa pernah ngulang.
  int getFrekuensiNgulang([List<String>? targetKriteriaIds]) {
    // Grup nilai per (kriteriaId, sesiId / id)
    final Map<String, int> maxAttemptPerSesi = {};
    for (final n in nilaiList) {
      if (targetKriteriaIds != null &&
          targetKriteriaIds.isNotEmpty &&
          !targetKriteriaIds.contains(n.kriteriaId)) {
        continue;
      }
      final key = '${n.kriteriaId}_${n.sesiId ?? n.id}';
      if (!maxAttemptPerSesi.containsKey(key) ||
          n.attempt > maxAttemptPerSesi[key]!) {
        maxAttemptPerSesi[key] = n.attempt;
      }
    }
    // Hitung sesi/evaluasi yang punya attempt > 1
    return maxAttemptPerSesi.values.where((a) => a > 1).length;
  }

  Murid copyWith({
    String? nama,
    String? nis,
    List<Nilai>? nilaiList,
    double? skorFinal,
  }) {
    return Murid(
      id: id,
      nama: nama ?? this.nama,
      nis: nis ?? this.nis,
      nilaiList: nilaiList ?? this.nilaiList,
      skorFinal: skorFinal ?? this.skorFinal,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'nis': nis,
    'nilaiList': nilaiList.map((n) => n.toJson()).toList(),
    'skorFinal': skorFinal,
  };

  factory Murid.fromJson(Map<String, dynamic> json) => Murid(
    id: json['id'],
    nama: json['nama'],
    nis: json['nis'] as String?,
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
  final String userId;
  String nama;
  List<Kriteria> kriteria;
  List<Murid> muridList;
  List<Sesi> sesiList;
  bool sudahKalkulasi;
  List<List<double>> matriksAHP;
  final DateTime? createdAt;

  Kelas({
    required this.id,
    required this.userId,
    required this.nama,
    required this.kriteria,
    required this.muridList,
    List<Sesi>? sesiList,
    this.sudahKalkulasi = false,
    List<List<double>>? matriksAHP,
    this.createdAt,
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
    String? userId,
    String? nama,
    List<Kriteria>? kriteria,
    List<Murid>? muridList,
    List<Sesi>? sesiList,
    bool? sudahKalkulasi,
    List<List<double>>? matriksAHP,
    DateTime? createdAt,
  }) {
    return Kelas(
      id: id,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      kriteria: kriteria ?? this.kriteria,
      muridList: muridList ?? this.muridList,
      sesiList: sesiList ?? this.sesiList,
      sudahKalkulasi: sudahKalkulasi ?? this.sudahKalkulasi,
      matriksAHP: matriksAHP ?? this.matriksAHP,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'nama': nama,
    'kriteria': kriteria.map((k) => k.toJson()).toList(),
    'muridList': muridList.map((m) => m.toJson()).toList(),
    'sesiList': sesiList.map((s) => s.toJson()).toList(),
    'sudah_kalkulasi': sudahKalkulasi,
    'matriks_ahp': matriksAHP.expand((row) => row).toList(),
    'matriks_n': matriksAHP.isNotEmpty ? matriksAHP.length : 0,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory Kelas.fromJson(Map<String, dynamic> json) {
    // Reconstruct matriksAHP from 1D array
    final flat = List<double>.from(
      (json['matriks_ahp'] as List? ?? []).map((e) => (e as num).toDouble())
    );
    final n = json['matriks_n'] as int? ?? 0;
    List<List<double>> matriks = [];
    if (n > 0 && flat.length == n * n) {
      for (int i = 0; i < n; i++) {
        matriks.add(flat.sublist(i * n, (i + 1) * n));
      }
    } else if (json['matriksAHP'] != null) {
      // Fallback for older local data (2D array)
      matriks = (json['matriksAHP'] as List)
          .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
          .toList();
    }

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdAt = DateTime.tryParse(json['createdAt']);
      } else {
        try {
          createdAt = (json['createdAt'] as dynamic).toDate();
        } catch (_) {}
      }
    }

    return Kelas(
      id: json['id'],
      userId: json['userId'] ?? '',
      nama: json['nama'],
      kriteria: (json['kriteria'] as List? ?? [])
          .map((k) => Kriteria.fromJson(k))
          .toList(),
      muridList: (json['muridList'] as List? ?? [])
          .map((m) => Murid.fromJson(m))
          .toList(),
      sesiList: (json['sesiList'] as List? ?? [])
          .map((s) => Sesi.fromJson(s))
          .toList(),
      sudahKalkulasi: json['sudah_kalkulasi'] ?? json['sudahKalkulasi'] ?? false,
      matriksAHP: matriks,
      createdAt: createdAt,
    );
  }
}