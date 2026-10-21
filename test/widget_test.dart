import 'package:flutter_test/flutter_test.dart';
import 'package:scorify/models/models.dart';

void main() {
  group('Scorify Model Tests', () {
    test('SubKriteria serialization and deserialization', () {
      final sub = SubKriteria(id: 'sub_1', nama: 'Hadir', nilai: 100.0);
      final json = sub.toJson();
      expect(json['id'], 'sub_1');
      expect(json['nama'], 'Hadir');
      expect(json['nilai'], 100.0);

      final fromJson = SubKriteria.fromJson(json);
      expect(fromJson.id, 'sub_1');
      expect(fromJson.nama, 'Hadir');
      expect(fromJson.nilai, 100.0);
    });

    test('JenisKriteria label evaluation', () {
      expect(JenisKriteria.byProcess.label, 'Proses KBM');
      expect(JenisKriteria.byProduct.label, 'Hasil / Produk');
    });

    test('AggregationRule label evaluation', () {
      expect(AggregationRule.max.label, 'Nilai Maksimum');
      expect(AggregationRule.average.label, 'Rata-rata');
    });

    test('ArahKriteria label evaluation', () {
      expect(ArahKriteria.benefit.label, 'Menguntungkan (Benefit)');
      expect(ArahKriteria.cost.label, 'Merugikan (Cost)');
    });
  });
}
