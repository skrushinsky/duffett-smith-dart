import 'package:test/test.dart';
import 'package:duffett_smith/ephemeris.dart';

const DELTA = 1E-4; // result precision

final cases = [
  {
    'djd': 30916.5, // 24 Aug 1984 00:00
    'l': 151.01309547440778,
    'r': 1.010993800005251,
    'ap': 151.0035132296576,
  },
  {
    'djd': 30819.10833333333, // 18 May 1984 14:36
    'l': 57.83143688493146,
    'r': 1.011718488789592,
    'ap': 57.82109236581925,
  },
  {
    'djd': 28804.5, // 12 Nov 1978 00:00
    'l': 229.2517039627867,
    'r': 0.9898375,
    'ap': 229.2450957063683,
  },
  {
    'djd': 33888.5, // 1992, Oct. 13 0h
    'l': 199.90600618015975,
    'r': .9975999344847888,
    'ap': 199.9047664927989, // Meeus: 199.90734722222223
  }
];

void main() {
  group('Sun Geocentric position', () {
    for (var c in cases) {
      final t = c['djd'] / 36525;
      trueGeocentric(t, callback: (lsn, rsn) {
        test('longitude for djd ${c['djd']}',
            () => expect(lsn, closeTo(c['l'], DELTA)));
        test('R-vector for djd ${c['djd']}',
            () => expect(rsn, closeTo(rsn, DELTA)));
      });
    }
  });
}
